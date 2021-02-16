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

using Cairo;
using Gtk;
using GLib;
using Archive;

public class Document : Object {

  private DrawArea _da;
  private string   _filename;
  private string   _temp_dir;
  private bool     _from_user;  // Set to true if _filename was set by the user

  /* Properties */
  public string filename {
    set {
      if( _filename != value ) {
        if( !_from_user ) {
          FileUtils.unlink( _filename );
        }
        _filename  = value;
        _from_user = true;
      }
    }
    get {
      return( _filename );
    }
  }
  public string label {
    owned get {
      return( GLib.Path.get_basename( _filename ) );
    }
  }
  public bool save_needed { private set; get; default = false; }

  /* Default constructor */
  public Document( DrawArea da ) {

    _da = da;

    /* Create the temporary file */
    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder" );
    if( DirUtils.create_with_parents( dir, 0775 ) == 0 ) {
      int i = 1;
      do {
        _filename = GLib.Path.build_filename( dir, _( "unnamed" ) + "%d.minder".printf( i++ ) );
      } while( GLib.FileUtils.test( _filename, FileTest.EXISTS ) );
      _from_user = false;
    }

    /* Create the temporary directory to store the mind map */
    make_temp_dir();

    /* Listen for any changes from the canvas */
    _da.changed.connect( canvas_changed );

  }

  /* Called whenever the canvas changes such that a save will be needed */
  private void canvas_changed() {
    save_needed = true;
    auto_save();
  }

  /* Called when a document filename is loaded from the tab state file */
  public void load_filename( string fname, bool saved ) {
    filename   = fname;
    _from_user = saved;
  }

  /* Returns true if the stored filename came from the user */
  public bool is_saved() {
    return( _from_user );
  }


  /* Saves the given node information to the specified file */
  private bool save_xml() {

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "minder" );
    root->set_prop( "version", Minder.version );
    doc->set_root_element( root );
    _da.save( root );
    doc->save_format_file( get_map_file(), 1 );
    delete doc;

    return( true );

  }

  /*
   Archives the contents of the opened Minder directory.
  */
  public bool save() {

    /* Create the tar.gz archive named according the the first argument */
    Archive.Write archive = new Archive.Write ();
    archive.add_filter_gzip();
    archive.set_format_pax_restricted();
    archive.open_filename( filename );

    /* Add the Minder file to the archive */
    archive_file( archive, get_map_file() );

    stdout.printf( "Saving: %s\n", filename );

    /* Add the images */
    var image_ids = _da.image_manager.get_ids();
    for( int i=0; i<image_ids.length; i++ ) {
      var id = image_ids.index( i );
      archive_file( archive, _da.image_manager.get_file( id ), id );
    }

    /* Close the archive */
    if( archive.close() != Archive.Result.OK ) {
      error( "Error : %s (%d)", archive.error_string(), archive.errno() );
    }

    /* Indicate that a save is no longer needed */
    save_needed = false;

    return( true );

  }

  /* Adds the given file to the archive */
  public bool archive_file( Archive.Write archive, string fname, int? image_id = null ) {

    stdout.printf( "Archiving file: %s\n", fname );

    try {

      var file              = GLib.File.new_for_path( fname );
      var file_info         = file.query_info( GLib.FileAttribute.STANDARD_SIZE, GLib.FileQueryInfoFlags.NONE );
      var input_stream      = file.read();
      var data_input_stream = new DataInputStream( input_stream );

      /* Add an entry to the archive */
      var entry = new Archive.Entry();
      entry.set_pathname( file.get_basename() );
#if VALAC048
      entry.set_size( (Archive.int64_t)file_info.get_size() );
      entry.set_filetype( Archive.FileType.IFREG );
      entry.set_perm( (Archive.FileMode)0644 );
#else
      entry.set_size( file_info.get_size() );
      entry.set_filetype( (uint)Posix.S_IFREG );
      entry.set_perm( 0644 );
#endif

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
#if VALAC048
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

  /* Creates a temporary directory containing the unarchived Minder files */
  private void make_temp_dir() {
    try {
      _temp_dir = DirUtils.make_tmp( "minder-XXXXXX" );
      DirUtils.create( get_image_dir(), 0755 );
    } catch( Error e ) {
      critical( e.message );
    }
  }

  /* Copies a file from one location to another */
  private void move_file( string from, string to ) {
    var from_file = File.new_for_path( from );
    var to_file   = File.new_for_path( to );
    try {
      from_file.move( to_file, FileCopyFlags.OVERWRITE );
    } catch( Error e ) {
      critical( e.message );
    }
  }

  /* Copies a file from one location to another */
  private void copy_file( string from, string to ) {
    var from_file = File.new_for_path( from );
    var to_file   = File.new_for_path( to );
    try {
      from_file.copy( to_file, FileCopyFlags.OVERWRITE );
    } catch( Error e ) {
      critical( e.message );
    }
  }

  /* Returns the name of the map file to save to */
  private string get_map_file() {
    return( GLib.Path.build_filename( _temp_dir, "map.xml" ) );
  }

  /* Returns the name of the image directory within the temp directory */
  private string get_image_dir() {
    return( GLib.Path.build_filename( _temp_dir, "images" ) );
  }

  /*
   Upgrades the existing XML Minder file to the new Minder archive format, moving stored
   images to the new archive.
  */
  private bool upgrade() {

    stdout.printf( "In upgrading %s\n", filename );

    /* Move the Minder XML file to the temporary directory */
    move_file( filename, get_map_file() );

    /* Load the XML file */
    load_xml();

    /* Move all image files that are related to the temp images directory */
    var image_ids = _da.image_manager.get_ids();
    for( int i=0; i<image_ids.length; i++ ) {
      var id       = image_ids.index( i );
      var img_file = _da.image_manager.get_file( id );
      stdout.printf( "img_file: %s, basename: %s\n", img_file, GLib.Path.get_basename( img_file ) );
      copy_file( img_file, GLib.Path.build_filename( get_image_dir(), GLib.Path.get_basename( img_file ) ) );
    }

    /* Set the image directory in the image manager */
    _da.image_manager.set_image_dir( get_image_dir() );

    /* Finally, create the new .minder file (it will act as a backup) */
    save();

    return( true );

  }

  /* Opens the given filename */
  private bool load_xml() {

    stdout.printf( "Loading XML: %s\n", get_map_file() );

    Xml.Doc* doc = Xml.Parser.read_file( get_map_file(), null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return( false );
    }

    _da.load( doc->get_root_element() );

    delete doc;

    return( true );

  }

  /*
   Converts the portable Minder file into the Minder document and moves all
   stored images to the ImageManager on the local computer.
  */
  public bool load() {

    stdout.printf( "In load, filename: %s\n", filename );

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

    /* Open the portable Minder file for reading */
    if( archive.open_filename( filename, 16384 ) != Archive.Result.OK ) {
      return( upgrade() );
    }

    unowned Archive.Entry entry;

    while( archive.next_header( out entry ) == Archive.Result.OK ) {

      /*
       We will need to modify the entry pathname so the file is written to the
       proper location.
      */
      if( entry.pathname() == "map.xml" ) {
        entry.set_pathname( GLib.Path.build_filename( _temp_dir, entry.pathname() ) );
      } else {
        entry.set_pathname( GLib.Path.build_filename( get_image_dir(), entry.pathname() ) );
      }

      /* Read from the archive and write the files to disk */
      if( extractor.write_header( entry ) != Archive.Result.OK ) {
        continue;
      }
#if VALAC048
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
          stdout.printf( "document.load: %x\n", *id );
          _da.image_manager.add_image( "file://" + entry.pathname(), *id );
        }
      }

    }

    /* Close the archive */
    if( archive.close () != Archive.Result.OK) {
      error( "Error: %s (%d)", archive.error_string(), archive.errno() );
    }

    /* Set the image directory in the image manager */
    _da.image_manager.set_image_dir( get_image_dir() );

    /* Finally, load the minder file and re-save it */
    load_xml();
    _da.changed();

    return( true );

  }

  /* Deletes the given unnamed file when called */
  public bool remove() {
    if( !_from_user ) {
      FileUtils.unlink( _filename );
    }
    return( true );
  }

  /* Auto-saves the document */
  public void auto_save() {
    save_xml();
  }

  /*
   This should be called when the application is closing.  This will cause the
   document to be stored in .minder format and will clean up tmp space.
  */
  public void cleanup() {

    /* Force the save to occur */
    if( save_needed ) {
      save();
    }

    /* Delete the temporary directory */
    DirUtils.remove( _temp_dir );

  }

}
