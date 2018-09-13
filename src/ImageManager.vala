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

class ImageManager {

  /* Private class used by the image manager to store image information */
  private class ImageItem {

    public string fname { set; get; default = ""; }
    public string uri   { set; get; default = ""; }
    public bool   valid { set; get; default = ""; }

    /* Default constructor */
    public ImageItem( string fname, string uri ) {
      this.fname = fname;
      this.uri   = uri;
      this valid = true;
    }

    /* Returns true if the file exists */
    public bool exists() {
      var file = File.new_from_path( fname );
      return( file.exists() );
    }

    /* If the current item is no longer valid, remove it from the file system */
    public void cleanup() {
      if( !valid && exists() ) {
        FileUtils.unlink( fname );
      }
    }

  }

  private Array<ImageItem> _images;
  private bool             _available;

  /* Default constructor */
  public ImageManager() {
    var dir = get_storage_path();
    if( DirUtils.create_with_parents( dir, 0775 ) == 0 ) {
  }

  /* Loads the stored images in the minder library */
  private void load() {
    // TBD
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

  /* Adds the given image information to the stored list */
  public void get_image( string uri ) {
    var match = find_match( uri );
    if( match == -1 ) {
      var item = new ImageItem( fname, uri );
      if( item.exists() ) {
        _images.append_val( item );
      }
    }
  }

  /* Returns the web pathname used to store downloaded images */
  private static string get_web_path() {
    return( GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "images" ) );
  }

  /* Returns the path for the file associated with the given URI */
  private string? get_fname_from_uri( string uri ) {
    var rfile = File.new_for_uri( uri );
    if( rfile.get_uri_scheme() == "file" ) {
      return( rfile.get_path() );
    } else {
        var parts = uri.split( "." );
        var ext   = parts[parts.length - 1];
        if( (ext == "bmp") || (ext == "png") || (ext == "jpg") || (ext == "jpeg") ) {
          ext = "." + ext;
        } else {
          ext = "";
        }
        var id    = Minder.get_image_id();
        var lfile = File.new_for_path( GLib.Path.build_filename( dir, "img%06d%s".printf( id, ext ) ) );
        try {
          rfile.copy( lfile, FileCopyFlags.OVERWRITE );
          return( lfile.get_path() );
        } catch( Error e ) {
          return( null );
        }
      }
      return( null );
    }
  }
  /* Cleans up the contents of the stored images */
  public void cleanup() {
    for( int i=0; i<_images.length; i++ ) {
      _images.index( i ).cleanup();
    }
  }

}

