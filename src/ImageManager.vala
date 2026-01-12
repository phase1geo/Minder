/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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
using Gee;

public delegate void ImageIdFunc( int id );

public class ImageManager {

  //-------------------------------------------------------------
  // Private class used by the image manager to store image information
  private class ImageItem {

    private ImageManager _manager;

    public int    id    { set; get; default = -1; }
    public string uri   { set; get; default = ""; }
    public string ext   { set; get; default = ""; }
    public bool   valid { set; get; default = false; }

    //-------------------------------------------------------------
    // Default constructor
    public ImageItem( ImageManager manager, string uri ) {
      _manager   = manager;
      this.id    = Minder.settings.get_int( "image-id" );
      this.uri   = uri;
      this.ext   = get_extension();
      this.valid = true;
      Minder.settings.set_int( "image-id", (this.id + 1) );
    }

    //-------------------------------------------------------------
    // Loads the item information from given XML node
    public ImageItem.from_xml( ImageManager manager, Xml.Node* n ) {
      _manager = manager;
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

    //-------------------------------------------------------------
    // Saves the given image item to the specified XML node
    public void save( Xml.Node* parent ) {
      Xml.Node* n = new Xml.Node( null, "image" );
      n->new_prop( "id",  id.to_string() );
      n->new_prop( "uri", uri );
      n->new_prop( "ext", ext );
      parent->add_child( n );
    }

    //-------------------------------------------------------------
    // Returns true if the file exists
    public bool exists() {
      return( FileUtils.test( get_path(), FileTest.EXISTS ) );
    }

    //-------------------------------------------------------------
    // Returns the extension associated with the filename
    public string get_extension() {
      if( uri != "" ) {
        var parts = uri.split( "." );
        var ext   = parts[parts.length - 1].split( "?" )[0];
        if( (ext == "bmp") || (ext == "png") || (ext == "jpg") || (ext == "jpeg") || (ext == "svg") ) {
          return( "." + ext );
        }
      } else {
        return( ".png" );
      }
      return( "" );
    }

    //-------------------------------------------------------------
    // Returns the full pathname to the given fname
    public string get_path() {
      var basename = "img%06x%s".printf( id, ext );
      return( GLib.Path.build_filename( _manager.get_image_dir(), basename ) );
    }

    //-------------------------------------------------------------
    // Copies the given URI to the given filename in the storage
    // directory
    public bool copy_file() {
      var rfile = File.new_for_uri( uri );
      var lfile = File.new_for_path( get_path() );
      try {
        rfile.copy( lfile, FileCopyFlags.OVERWRITE );
      } catch( Error e ) {
        stdout.printf( "Error: %s\n", e.message );
        return( false );
      }
      return( true );
    }

    //-------------------------------------------------------------
    // If the current item is no longer valid, remove it from the
    // file system
    public void cleanup() {
      if( !valid && exists() ) {
        FileUtils.unlink( get_path() );
      }
    }

  }

  private Array<ImageItem> _images;
  private HashMap<int,int> _id_map;
  private string?          _image_dir = null;

  //-------------------------------------------------------------
  // Default constructor
  public ImageManager() {

    // Create the images directory if it does not exist
    set_image_dir( get_image_dir() );

    // Allocate the images array
    _images = new Array<ImageItem>();
    _id_map = new HashMap<int,int>();

  }

  //-------------------------------------------------------------
  // Returns the web pathname used to store downloaded images
  public string? get_image_dir() {
    return( _image_dir );
  }

  //-------------------------------------------------------------
  // Sets the image dir to the specified path (pass null to use
  // the default system path)
  public void set_image_dir( string? image_dir ) {

    _image_dir = image_dir ?? GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "images" );

    // Create the images directory if it does not exist
    DirUtils.create_with_parents( _image_dir, 0775 );

  }

  //-------------------------------------------------------------
  // Loads the image manager information from the specified XML node
  public void load( Xml.Node* n ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "image" ) {
          var ii = new ImageItem.from_xml( this, it );
          if( !_id_map.has_key( ii.id ) ) {
            _images.append_val( ii );
          }
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Saves the image manager information to the file
  public void save( Xml.Node* n ) {
    for( int i=0; i<_images.length; i++ ) {
      if( _images.index( i ).valid ) {
        _images.index( i ).save( n );
      }
    }
  }

  //-------------------------------------------------------------
  // Searches the list of stored image items, returning the array
  // index of the item that matches.  If no match is found, a
  // value of -1 is returned.
  private ImageItem? find_match( int id ) {
    for( int i=0; i<_images.length; i++ ) {
      if( _images.index( i ).id == id ) {
        return( _images.index( i ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Finds an image item that matches the given URI and returns
  // the index of the matching item.
  private ImageItem? find_uri_match( string uri ) {
    for( int i=0; i<_images.length; i++ ) {
      if( _images.index( i ).uri == uri ) {
        return( _images.index( i ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Adds the given image information to the stored list.  Returns
  // the image ID that the NodeImage class will store to reference
  // the image details.  If the image could not be added, returns
  // a value of -1.
  public int add_image( string uri, int? orig_id = null ) {
    var item = find_uri_match( uri );
    if( item == null ) {
      item = new ImageItem( this, uri );
      if( !item.copy_file() ) return( -1 );
      _images.append_val( item );
    } else if( !item.exists() ) {
      if( !item.copy_file() ) return( -1 );
    }
    if( orig_id != null ) {
      _id_map.set( orig_id, item.id );
    }
    return( item.id );
  }

  //-------------------------------------------------------------
  // Creates a file with the contents of the given pixbuf and
  // adds the file information to the manager list.  Returns the
  // image ID that the NodeImage class will store to reference
  // the image details.  If the image could not be added, returns
  // a value of -1.
  public int add_pixbuf( Gdk.Pixbuf buf, int? orig_id = null ) {
    var item = new ImageItem( this, "" );
    try {
      buf.save( item.get_path(), "png", null );
      _images.append_val( item );
    } catch( Error e ) {
      return( -1 );
    }
    return( item.id );
  }

  //-------------------------------------------------------------
  // Returns the full pathname of the stored file for the given
  // image ID
  public string? get_file( int id ) {
    var item = find_match( id );
    if( item != null ) {
      return( item.get_path() );
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the MIME type associated with the given image file
  public string? get_mime_type( int id ) {
    var item = find_match( id );
    if( item != null ) {
      return( "image/%s".printf( item.get_extension().substring( 1 ) ) );
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the list of stored files
  public Array<int> get_ids() {
    var ids = new Array<int>();
    for( int i=0; i<_images.length; i++ ) {
      ids.append_val( _images.index( i ).id );
    }
    return( ids );
  }

  //-------------------------------------------------------------
  // Returns the stored URI for the given imaged ID
  public string get_uri( int id ) {
    var item = find_match( id );
    if( item != null ) {
      return( item.uri );
    }
    return( "" );
  }

  //-------------------------------------------------------------
  // Sets the validity of the given URI to the the specified value.
  // When an image is no longer needed, this method should be
  // called with a value of false.  When an image is needed again,
  // this method should be called with a value of true.
  public void set_valid( int id, bool value ) {
    var item = find_match( id );
    if( item != null ) {
      item.valid = value;
    }
  }

  //-------------------------------------------------------------
  // Cleans up the contents of the stored images
  public void cleanup() {
    for( int i=0; i<_images.length; i++ ) {
      _images.index( i ).cleanup();
    }
  }

  //-------------------------------------------------------------
  // Returns the ID to use for the given ID
  public int get_id( int id ) {
    if( _id_map.has_key( id ) ) {
      return( _id_map.get( id ) );
    }
    return( id );
  }

  //-------------------------------------------------------------
  // Allows the user to choose an image file.  If the user selects
  // an existing file, adds the image to the manager and returns
  // the image ID to the calling function.  If no image was
  // selected, a value of -1 will be returned.
  public void choose_image( Gtk.Window parent, ImageIdFunc func ) {

    int id = -1;

    var dialog = Utils.make_file_chooser( _( "Select Image" ), _( "Select" ) );
    // Utils.set_chooser_folder( dialog );

    // Allow pixbuf image types
    var filter  = new FileFilter();
    filter.set_filter_name( _( "Images" ) );
    filter.add_pattern( "*.bmp" );
    filter.add_pattern( "*.png" );
    filter.add_pattern( "*.jpg" );
    filter.add_pattern( "*.jpeg" );
    filter.add_pattern( "*.svg" );

    var filters = new GLib.ListStore( typeof(FileFilter) );
    filters.append( filter );
    dialog.set_filters( filters );

    dialog.open.begin( parent, null, (obj, res) => {
      try {
        var file = dialog.open.end( res );
        if( file != null ) {
          id = add_image( file.get_uri() );
          func( id );
        }
      } catch( Error e ) {}
    });

  }

}

