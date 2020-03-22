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
    var image_ids = da.image_manager.get_ids();
    for( int i=0; i<image_ids.length; i++ ) {
      var id = image_ids.index( i );
      archive_file( archive, da.image_manager.get_file( id ), id );
    }

    /* Close the archive */
    if( archive.close() != Archive.Result.OK ) {
      error( "Error : %s (%d)", archive.error_string(), archive.errno() );
    }

    return( true );

  }

  /* Adds the given file to the archive */
  public static bool archive_file( Archive.Write archive, string fname, int? image_id = null ) {

    try {

      var file              = GLib.File.new_for_path( fname );
      var file_info         = file.query_info( GLib.FileAttribute.STANDARD_SIZE, GLib.FileQueryInfoFlags.NONE );
      var input_stream      = file.read();
      var data_input_stream = new DataInputStream( input_stream );

      /* Add an entry to the archive */
      var entry = new Archive.Entry();
      entry.set_pathname( file.get_basename() );
#if LIBARCHIVE340
      entry.set_size( (Archive.int64_t)file_info.get_size() );
      entry.set_filetype( Archive.FileType.IFREG );
#else
      entry.set_size( file_info.get_size() );
      entry.set_filetype( (uint)Posix.S_IFREG );
#endif
      entry.set_perm( 0644 );

      if( image_id != null ) {
        entry.xattr_add_entry( "image_id", (void*)image_id, sizeof( int ) );
      }

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
#if LIBARCHIVE340
        archive.write_data( buffer );
#else
        archive.write_data( buffer, bytes_read );
#endif
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

    Archive.ExtractFlags flags;
    flags  = Archive.ExtractFlags.TIME;
    flags |= Archive.ExtractFlags.PERM;
    flags |= Archive.ExtractFlags.ACL;
    flags |= Archive.ExtractFlags.FFLAGS;

    Archive.WriteDisk extractor = new Archive.WriteDisk();
    extractor.set_options( flags );
    extractor.set_standard_lookup();

    /* Create the image directory */
    string img_dir = ".";
    try {
      img_dir = DirUtils.make_tmp( "minder-images-XXXXXX" );
    } catch( Error e ) {
      critical( e.message );
    }

    /* Open the portable Minder file for reading */
    if( archive.open_filename( fname, 16384 ) != Archive.Result.OK ) {
      error( "Error: %s (%d)", archive.error_string(), archive.errno() );
    }

    string?               minder_path = null;
    unowned Archive.Entry entry;

    while( archive.next_header( out entry ) == Archive.Result.OK ) {

      /*
       We will need to modify the entry pathname so the file is written to the
       proper location.
      */
      if( entry.pathname().has_suffix( ".minder" ) ) {
        entry.set_pathname( fname.substring( 0, (fname.length - 8) ) + ".minder" );
        minder_path = entry.pathname();
      } else {
        var file = File.new_build_filename( img_dir, entry.pathname() );
        entry.set_pathname( file.get_path() );
      }

      /* Read from the archive and write the files to disk */
      if( extractor.write_header( entry ) != Archive.Result.OK ) {
        continue;
      }
#if LIBARCHIVE340
      uint8[]         buffer;
      Archive.int64_t offset;

      while( archive.read_data_block( out buffer, out offset ) == Archive.Result.OK ) {
        if( extractor.write_data_block( buffer, offset ) != Archive.Result.OK ) {
          break;
        }
      }
#else
      void*       buffer = null;
      size_t      buffer_length;
      Posix.off_t offset;

      while( archive.read_data_block( out buffer, out buffer_length, out offset ) == Archive.Result.OK ) {
        if( extractor.write_data_block( buffer, buffer_length, offset ) != Archive.Result.OK ) {
          break;
        }
      }
#endif

      /* If the file was an image file, make sure it gets added to the image manager */
      if( !entry.pathname().has_suffix( ".minder" ) ) {
        string name;
        void*  value;
        size_t size;
        entry.xattr_reset();
        if( (entry.xattr_next( out name, out value, out size ) == Archive.Result.OK) && (name == "image_id") ) {
          int* id = (int*)value;
          da.image_manager.add_image( "file://" + entry.pathname(), *id );
        }
      }

    }

    /* Close the archive */
    if( archive.close () != Archive.Result.OK) {
      error( "Error: %s (%d)", archive.error_string(), archive.errno() );
    }

    /* Delete the image directory */
    DirUtils.remove( img_dir );

    /* Finally, load the minder file and re-save it */
    da.get_doc().load();
    da.changed();

    return( true );

  }

}
