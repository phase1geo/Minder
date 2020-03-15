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
using Archive;

public class ExportPortableMinder : Object {

  /*
   Exports the current mindmap along with all images to a single file that can
   be imported in a different computer/location.
  */
  public static bool export( string fname, DrawArea da ) {

    /* Create the tar.gz archive named according the the first argument */
    Archive.Write archive = new Archive.Write ();
    archive.add_filter_gzip();
    archive.set_format_pax_restricted();
    archive.open_filename( fname );

    /* Add the Minder file to the archive */
    archive_file( archive, da.get_doc().filename );

    /* Add the images */
    Array<string> files;
    da.image_manager.get_files( out files );
    for( int i=0; i<files.length; i++ ) {
      archive_file( archive, files.index( i ) );
    }

    /* Close the archive */
    if( archive.close() != Archive.Result.OK ) {
      error( "Error : %s (%d)", archive.error_string(), archive.errno() );
    }

    return( true );

  }

  /* Adds the given file to the archive */
  public static bool archive_file( Archive.Write archive, string fname ) {

    try {

      var file              = GLib.File.new_for_path( fname );
      var file_info         = file.query_info( GLib.FileAttribute.STANDARD_SIZE, GLib.FileQueryInfoFlags.NONE );
      var input_stream      = file.read ();
      var data_input_stream = new DataInputStream( input_stream );

      /* Add an entry to the archive */
      var entry = new Archive.Entry();
      entry.set_pathname( file.get_basename() );
      entry.set_size( file_info.get_size() );
      entry.set_filetype( (uint)Posix.S_IFREG );
      entry.set_perm( 0644 );
      if( archive.write_header( entry ) != Archive.Result.OK ) {
        critical ("Error writing '%s': %s (%d)", file.get_path (), archive.error_string (), archive.errno ());
        return( false );
      }

      /* Add the actual content of the file */
      size_t bytes_read;
      uint8[] buffer = new uint8[64];
      while( data_input_stream.read_all( buffer, out bytes_read ) ) {
        if( bytes_read <= 0 ) {
          break;
        }
        archive.write_data( buffer, bytes_read );
      }

    } catch( Error e ) {
      critical( e.message );
      return( false );
    }

    return( true );

  }

  //----------------------------------------------------------------------------

  /*
   Converts the portable Minder file into the Minder document and moves all
   stored images to the ImageManager on the local computer.
  */
  public static bool import( string fname, DrawArea da ) {

    Archive.Read archive = new Archive.Read();
    archive.support_filter_gzip();
    archive.support_format_all();

    if( archive.open_filename( fname, 16384 ) != Archive.Result.OK ) {
      error ("Error: %s (%d)", archive.error_string (), archive.errno () );
    }

    /* Create the image directory */
    string img_dir = ".";
    try {
      img_dir = DirUtils.make_tmp( "minder-images-XXXXXX" );
    } catch( Error e ) {
      critical( e.message );
    }

    int8[]                buffer      = null;
    unowned Archive.Entry entry;
    ssize_t               size;
    string?               minder_path = null;

    while( archive.next_header( out entry ) == Archive.Result.OK ) {
      File file;
      stdout.printf( "entry.pathname: %s\n", entry.pathname() );
      /*
      if( entry.pathname().has_suffix( ".minder" ) ) {
        minder_path = fname.substring( 0, (fname.length - 8) ) + ".minder";
        file        = File.new_for_path( minder_path );
        stdout.printf( "minder_path: %s\n", minder_path );
      } else {
        file = File.new_build_filename( img_dir, entry.pathname() );
      }
      try {
        var os = file.create( FileCreateFlags.PRIVATE );
        while( (size = archive.read_data( buffer, buffer.length )) > 0 ) {
          if( buffer != null ) {
            os.write( (uint8[])buffer );
          }
        }
        os.close();
      } catch( Error e ) {
        critical( e.message );
        return( false );
      }
      if( file.get_parent().get_path() == img_dir ) {
        da.image_manager.add_image( file.get_path() );
      }
      */
    }

    /* Close the archive */
    if( archive.close () != Archive.Result.OK) {
      error ("Error: %s (%d)", archive.error_string (), archive.errno ());
    }

    /* Delete the image directory */
    DirUtils.remove( img_dir );

    /* Finally, load the minder file */
    // da.win.open_file( minder_path );

    return( true );

  }

}
