/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using GLib;
using Gtk;

public class ImageManager {

  /* Returns the web pathname used to store downloaded images */
  private static string get_storage_path() {
    return( GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "images" ) );
  }

  /* Returns the full pathname to the given fname */
  private static string get_path( string fname ) {
    return( GLib.Path.build_filename( get_storage_path(), fname ) );
  }

  /* Private class used by the image manager to store image information */
  private class ImageItem {

    public string fname { set; get; default = ""; }
    public string uri   { set; get; default = ""; }
    public bool   valid { set; get; default = false; }

    /* Default constructor */
    public ImageItem( string fname, string uri ) {
      this.fname = fname;
      this.uri   = uri;
      this.valid = true;
    }

    /* Loads the item information from given XML node */
    public ImageItem.from_xml( Xml.Node* n ) {
      string? f = n->get_prop( "fname" );
      if( f != null ) {
        fname = f;
      }
      string? u = n->get_prop( "uri" );
      if( u != null ) {
        uri = u;
      }
      valid = true;
    }

    /* Saves the given image item to the specified XML node */
    public void save( Xml.Node* parent ) {
      Xml.Node* n = new Xml.Node( null, "imageitem" );
      n->new_prop( "fname", fname );
      n->new_prop( "uri",   uri );
      parent->add_child( n );
    }

    /* Returns true if the file exists */
    public bool exists() {
      return( FileUtils.test( ImageManager.get_path( fname ), FileTest.EXISTS ) );
    }

    /* If the current item is no longer valid, remove it from the file system */
    public void cleanup() {
      if( !valid && exists() ) {
        // FileUtils.unlink( ImageManager.get_path( fname ) );
        stdout.printf( "Removing fname: %s\n", ImageManager.get_path( fname ) );
      }
    }

  }

  private Array<ImageItem> _images;
  private bool             _available = true;

  /* Default constructor */
  public ImageManager() {

    /* Create the images directory if it does not exist */
    if( DirUtils.create_with_parents( get_storage_path(), 0775 ) == 0 ) {
      _available = true;
    }

    /* Allocate the images array */
    _images = new Array<ImageItem>();

  }

  /* Destructor */
  ~ImageManager() {
    cleanup();
  }

  /* Returns the next unique image ID */
  private int get_image_id() {
    var image_id = Minder.settings.get_int( "image-id" );
    Minder.settings.set_int( "image-id", (image_id + 1) );
    return( image_id );
  }

  /* Loads the image manager information from the specified XML node */
  public void load( Xml.Node* n ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "image" ) {
          _images.append_val( new ImageItem.from_xml( it ) );
        }
      }
    }
  }

  /* Saves the image manager information to the file */
  public void save( Xml.Node* n ) {
    for( int i=0; i<_images.length; i++ ) {
      _images.index( i ).save( n );
    }
  }

  /*
   Searches the list of stored image items, returning the array index
   of the item that matches.  If no match is found, a value of -1 is
   returned.
  */
  private int find_match( string uri ) {
    for( int i=0; i<_images.length; i++ ) {
      if( _images.index( i ).uri == uri ) {
        return( i );
      }
    }
    return( -1 );
  }

  /*
   Adds the given image information to the stored list.  Returns the path to the
   filename to use if the image was successfully retrieved; otherwise, returns null.
  */
  public string? add_image( string uri ) {
    var match = find_match( uri );
    if( match == -1 ) {
      var fname = uri_to_fname( uri );
      if( !copy_uri_to_fname( uri, fname ) ) {
        return( null );
      }
      match = (int)_images.length;
      stdout.printf( "1 add, fname: %s, uri: %s\n", fname, uri );
      _images.append_val( new ImageItem( fname, uri ) );
    } else if( !_images.index( match ).exists() ) {
      if( !copy_uri_to_fname( uri, _images.index( match ).fname ) ) {
        return( null );
      }
    }
    return( get_path( _images.index( match ).fname ) );
  }

  /* Add the node image to the list.  Called when a node is read from XML. */
  public void add_node_image( NodeImage ni ) {
    var match = find_match( ni.uri );
    if( match == -1 ) {
      var item = new ImageItem( ni.fname, ni.uri );
      if( item.exists() ) {
        stdout.printf( "2 add, fname: %s, uri: %s\n", ni.fname, ni.uri );
        _images.append_val( new ImageItem( ni.fname, ni.uri ) );
      }
    }
  }

  /* Returns the full pathname of the stored file for the given URI */
  public string? get_path_for_uri( string uri ) {
    var match = find_match( uri );
    if( match != -1 ) {
      return( get_path( _images.index( match ).fname ) );
    }
    return( null );
  }

  /*
   Sets the validity of the given URI to the the specified value.  When an image
   is no longer needed, this method should be called with a value of false.  When
   an image is needed again, this method should be called with a value of true.
  */
  public void set_valid_for_uri( string uri, bool value ) {
    var match = find_match( uri );
    if( match != -1 ) {
      _images.index( match ).valid = value;
    }
  }

  /* Returns the filename associated with the given URI */
  private string uri_to_fname( string uri ) {
    var parts = uri.split( "." );
    var ext   = parts[parts.length - 1].split( "?" )[0];
    if( (ext == "bmp") || (ext == "png") || (ext == "jpg") || (ext == "jpeg") ) {
      ext = "." + ext;
    } else {
      ext = "";
    }
    return( "img%06d%s".printf( get_image_id(), ext ) );
  }

  /* Copies the given URI to the given filename in the storage directory */
  private bool copy_uri_to_fname( string uri, string fname ) {
    var rfile = File.new_for_uri( uri );
    var lfile = File.new_for_path( get_path( fname ) );
    try {
      stdout.printf( "Copying file %s to %s\n", rfile.get_path(), lfile.get_path() );
      rfile.copy( lfile, FileCopyFlags.OVERWRITE );
    } catch( Error e ) {
      return( false );
    }
    return( true );
  }

  /* Cleans up the contents of the stored images */
  private void cleanup() {
    for( int i=0; i<_images.length; i++ ) {
      _images.index( i ).cleanup();
    }
  }

  /*
   Allows the user to choose an image file.  If the user selects an existing file, 
   a NodeImage will be created and returned to the calling function.
  */
  public NodeImage? choose_node_image( Gtk.Window parent, int width ) {

    NodeImage? ni = null;

    FileChooserDialog dialog = new FileChooserDialog(
      _( "Select Image" ), parent, FileChooserAction.OPEN,
      _( "Cancel" ), ResponseType.CANCEL,
      _( "Select" ), ResponseType.ACCEPT
    );

    /* Allow pixbuf image types */
    FileFilter filter = new FileFilter();
    filter.set_filter_name( _( "Images" ) );
    filter.add_pattern( "*.bmp" );
    filter.add_pattern( "*.png" );
    filter.add_pattern( "*.jpg" );
    filter.add_pattern( "*.jpeg" );
    dialog.add_filter( filter );

    if( dialog.run() == ResponseType.ACCEPT ) {
      var uri   = dialog.get_uri();
      var fname = add_image( dialog.get_uri() );
      ni        = new NodeImage( fname, uri, width );
    }

    /* Close the dialog */
    dialog.destroy();

    return( ni );

  }

}

