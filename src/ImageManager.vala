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

public class ImageManager {

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

    /* Returns true if the file exists */
    public bool exists() {
      return( FileUtils.test( fname, FileTest.EXISTS ) );
    }

    /* If the current item is no longer valid, remove it from the file system */
    public void cleanup() {
      if( !valid && exists() ) {
        FileUtils.unlink( fname );
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
   Adds the given image information to the stored list.  Returns true if the image
   was successfully retrieved; otherwise, returns false.
  */
  public bool add_image( string uri ) {
    var match = find_match( uri );
    if( match == -1 ) {
      var fname = uri_to_fname( uri );
      if( !copy_uri_to_fname( uri, fname ) ) {
        return( false );
      }
      _images.append_val( new ImageItem( fname, uri ) );
    } else if( !_images.index( match ).exists() ) {
      if( !copy_uri_to_fname( uri, _images.index( match ).fname ) ) {
        return( false );
      }
    }
    return( true );
  }

  /* Returns the full pathname of the stored file for the given URI */
  public string? get_path( string uri ) {
    var match = find_match( uri );
    if( match != -1 ) {
      return( GLib.Path.build_filename( get_storage_path(), _images.index( match ).fname ) );
    }
    return( null );
  }

  /*
   Sets the validity of the given URI to the the specified value.  When an image
   is no longer needed, this method should be called with a value of false.  When
   an image is needed again, this method should be called with a value of true.
  */
  public void set_valid( string uri, bool value ) {
    var match = find_match( uri );
    if( match != -1 ) {
      _images.index( match ).valid = value;
    }
  }

  /* Returns the web pathname used to store downloaded images */
  private static string get_storage_path() {
    return( GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "images" ) );
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
    return( "img%06d%s".printf( Minder.get_image_id(), ext ) );
  }

  /* Copies the given URI to the given filename in the storage directory */
  private bool copy_uri_to_fname( string uri, string fname ) {
    var rfile = File.new_for_uri( uri );
    var lfile = File.new_for_path( GLib.Path.build_filename( get_storage_path(), fname ) );
    try {
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

}

