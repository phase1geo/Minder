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

  /* Private class used by the image manager to store image information */
  private class ImageItem {

    public int    id    { set; get; default = -1; }
    public string uri   { set; get; default = ""; }
    public string ext   { set; get; default = ""; }
    public bool   valid { set; get; default = false; }

    /* Default constructor */
    public ImageItem( string uri ) {
      this.id    = Minder.settings.get_int( "image-id" );
      this.uri   = uri;
      this.ext   = get_extension();
      this.valid = true;
      Minder.settings.set_int( "image-id", (this.id + 1) );
    }

    /* Loads the item information from given XML node */
    public ImageItem.from_xml( Xml.Node* n ) {
      string? i = n->get_prop( "id" );
      if( i != null ) {
        id = int.parse( i );
      }
      string? u = n->get_prop( "uri" );
      if( u != null ) {
        uri = u;
      }
      string? e = n->get_prop( "ext" );
      if( e != null ) {
        ext = e;
      }
      valid = true;
    }

    /* Saves the given image item to the specified XML node */
    public void save( Xml.Node* parent ) {
      Xml.Node* n = new Xml.Node( null, "image" );
      n->new_prop( "id",  id.to_string() );
      n->new_prop( "uri", uri );
      n->new_prop( "ext", ext );
      parent->add_child( n );
    }

    /* Returns true if the file exists */
    public bool exists() {
      return( FileUtils.test( get_path(), FileTest.EXISTS ) );
    }

    /* Returns the extension associated with the filename */
    public string get_extension() {
      var parts = uri.split( "." );
      var ext   = parts[parts.length - 1].split( "?" )[0];
      if( (ext == "bmp") || (ext == "png") || (ext == "jpg") || (ext == "jpeg") || (ext == "svg") ) {
        return( "." + ext );
      }
      return( "" );
    }
   
    /* Returns the full pathname to the given fname */
    public string get_path() {
      var basename = "img%06x%s".printf( id, ext );
      return( GLib.Path.build_filename( get_storage_path(), basename ) );
    }

    /* Copies the given URI to the given filename in the storage directory */
    public bool copy_file() {
      var rfile = File.new_for_uri( uri );
      var lfile = File.new_for_path( get_path() );
      try {
        rfile.copy( lfile, FileCopyFlags.OVERWRITE );
      } catch( Error e ) {
        return( false );
      }
      return( true );
    }

    /* If the current item is no longer valid, remove it from the file system */
    public void cleanup() {
      if( !valid && exists() ) {
        FileUtils.unlink( get_path() );
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
      if( _images.index( i ).valid ) {
        _images.index( i ).save( n );
      }
    }
  }

  /*
   Searches the list of stored image items, returning the array index
   of the item that matches.  If no match is found, a value of -1 is
   returned.
  */
  private ImageItem? find_match( int id ) {
    for( int i=0; i<_images.length; i++ ) {
      if( _images.index( i ).id == id ) {
        return( _images.index( i ) );
      }
    }
    return( null );
  }

  /*
   Finds an image item that matches the given URI and returns the index of the
   matching item.
  */
  private ImageItem? find_uri_match( string uri ) {
    for( int i=0; i<_images.length; i++ ) {
      if( _images.index( i ).uri == uri ) {
        return( _images.index( i ) );
      }
    }
    return( null );
  }

  /*
   Adds the given image information to the stored list.  Returns the image ID that
   the NodeImage class will store to reference the image details.  If the image
   could not be added, returns a value of -1.
  */
  public int add_image( string uri ) {
    var item = find_uri_match( uri );
    if( item == null ) {
      item = new ImageItem( uri );
      if( !item.copy_file() ) return( -1 );
      _images.append_val( item );
    } else if( !item.exists() ) {
      if( !item.copy_file() ) return( -1 );
    }
    return( item.id );
  }

  /* Returns the full pathname of the stored file for the given image ID */
  public string? get_file( int id ) {
    var item = find_match( id );
    if( item != null ) {
      return( item.get_path() );
    }
    return( null );
  }

  /* Returns the stored URI for the given imaged ID */
  public string get_uri( int id ) {
    var item = find_match( id );
    if( item != null ) {
      return( item.uri );
    }
    return( "" );
  }

  /*
   Sets the validity of the given URI to the the specified value.  When an image
   is no longer needed, this method should be called with a value of false.  When
   an image is needed again, this method should be called with a value of true.
  */
  public void set_valid( int id, bool value ) {
    var item = find_match( id );
    if( item != null ) {
      item.valid = value;
    }
  }

  /* Cleans up the contents of the stored images */
  public void cleanup() {
    for( int i=0; i<_images.length; i++ ) {
      _images.index( i ).cleanup();
    }
  }

  /*
   Allows the user to choose an image file.  If the user selects an existing file, 
   adds the image to the manager and returns the image ID to the calling function.
   If no image was selected, a value of -1 will be returned.
  */
  public int choose_image( Gtk.Window parent ) {

    int id = -1;

    FileChooserNative dialog = new FileChooserNative( _( "Select Image" ), parent, FileChooserAction.OPEN, _( "Select" ), _( "Cancel" ) );

    /* Allow pixbuf image types */
    FileFilter filter = new FileFilter();
    filter.set_filter_name( _( "Images" ) );
    filter.add_pattern( "*.bmp" );
    filter.add_pattern( "*.png" );
    filter.add_pattern( "*.jpg" );
    filter.add_pattern( "*.jpeg" );
    filter.add_pattern( "*.svg" );
    dialog.add_filter( filter );

    if( dialog.run() == ResponseType.ACCEPT ) {
      id = add_image( dialog.get_uri() );
    }

    /* Close the dialog */
    dialog.destroy();

    return( id );

  }

}

