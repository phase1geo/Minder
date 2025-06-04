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

public class Document : Object {

  private DrawArea _da;
  private string   _filename;
  private string   _temp_dir;
  private bool     _from_user;  // Set to true if _filename was set by the user
  private string   _etag;
  private bool     _read_only = false;

  /* Properties */
  public string filename {
    set {
      stdout.printf( "In set_filename, _filename: %s, value: %s\n", _filename, value );
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
  public bool readonly {
    get {
      var prev_read_only = _read_only;
      _read_only = Utils.is_read_only( _filename );
      if( save_needed && prev_read_only && !_read_only ) {
        save();
      }
      return( _read_only );
    }
  }

  public signal void save_state_changed();

  //-------------------------------------------------------------
  // Default constructor
  public Document( DrawArea da ) {

    _da = da;

    /* Generate unique Etag */
    _etag = generate_etag();

    /* Create the temporary file */
    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder" );
    if( DirUtils.create_with_parents( dir, 0775 ) == 0 ) {
      int i = 1;
      do {
        _filename = GLib.Path.build_filename( dir, _( "unnamed" ) + "%d.mindr".printf( i++ ) );
      } while( GLib.FileUtils.test( _filename, FileTest.EXISTS ) );
      _from_user = false;
    }

    // Create the temporary directory to store the mind map
    make_temp_dir();

    /* Listen for any changes from the canvas */
    _da.changed.connect( canvas_changed );

  }

  //-------------------------------------------------------------
  // Generate new "random" etag
  private string generate_etag() {
    return GLib.Random.next_int().to_string();
  }

  //-------------------------------------------------------------
  // Called whenever the canvas changes such that a save will be
  // needed
  private void canvas_changed() {
    save_needed = true;
    auto_save();
  }

  //-------------------------------------------------------------
  // Called when a document filename is loaded from the tab state
  // file
  public void load_filename( string fname, bool saved ) {
    filename   = fname;
    stdout.printf( "In load_filename, saved: %s\n", saved.to_string() );
    _from_user = saved;
  }

  //-------------------------------------------------------------
  // Returns true if the stored filename came from the user
  public bool is_saved() {
    return( _from_user );
  }

  /*
   Searches the given file for a node with the given ID.  If found, returns
   true along with the title of the node.
  */
  public static bool xml_find( string fname, int id, ref string name ) {
    Xml.Doc* doc = Xml.Parser.read_file( fname, null, Xml.ParserOption.HUGE );
    var      found = false;
    if( doc == null ) {
      return( false );
    }
    found = DrawArea.xml_find( doc->get_root_element(), id, ref name );
    delete doc;
    return( found );
  }

  private Xml.Doc* load_raw() {
    return Xml.Parser.read_file( get_map_file(), null, (Xml.ParserOption.HUGE | Xml.ParserOption.NOWARNING) );
  }

  private string get_etag( Xml.Doc* doc ) {
    for (Xml.Attr* prop = doc->get_root_element()->properties; prop != null; prop = prop->next) {
      string attr_name = prop->name;
      if( attr_name != "etag" ) {
        continue;
      }

      return prop->children->content;
    }
    return "";
  }

  //-------------------------------------------------------------
  // Opens the given filename
  private bool load_xml() {

    Xml.Doc* doc = load_raw();
    if( doc == null ) {
      stdout.printf( "  Well, that didn't work\n" );
      return( false );
    }

    // Load Etag
    _etag = get_etag( doc );

    // Load document
    _da.load( doc->get_root_element() );

    // Delete the XML document contents
    delete doc;

    /* If an etag was not found, generate one and save the updated map immediately */
    if( _etag == "" ) {
      _etag = generate_etag();
      save_xml_internal( filename, false );
    }

    return( true );

  }

  //-------------------------------------------------------------
  // Converts the Minder file into the Minder document and moves
  // all stored images to the ImageManager on the local computer
  public bool load() {

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
      uint8[]         buffer;
      Archive.int64_t offset;

      while( archive.read_data_block( out buffer, out offset ) == Archive.Result.OK ) {
        if( extractor.write_data_block( buffer, offset ) != Archive.Result.OK ) {
          break;
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

  //-------------------------------------------------------------
  // Saves the given node information to the specified file
  public bool save_xml() {

    stdout.printf( "In save_xml (%s)\n", get_map_file() );

    Xml.Doc* doc = load_raw();

    if( doc != null ) {

      string file_etag = get_etag( doc );

      /* File was modified! Warn the user */
      if( _etag != file_etag ) {
        var now = new DateTime.now_local();
        _da.win.ask_modified_overwrite( _da, (overwrite) => {
          if( overwrite ) {
            var fname = filename.replace( ".mind", "-backup-%s-%s.mind".printf( now.to_string(), file_etag ) );
            doc->save_format_file( fname, 1 );
          } else {
            var fname = filename.replace( ".mind", "-backup-%s-%s.mind".printf( now.to_string(), _etag ) );
            save_xml_internal( fname, false );
            _da.initialize_for_open();
            load();
          }
          delete doc;
        });
      }

    }

    return( save_xml_internal( get_map_file(), true ) );

  }

  //-------------------------------------------------------------
  // Saves the document to the given filename
  private bool save_xml_internal( string dest_filename, bool bump_etag ) {

    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "minder" );
    var orig_etag  = _etag;
    root->set_prop( "version", Minder.version );

    if ( bump_etag ) {
      /* Save previous Etag */
      root->set_prop( "parent-etag", _etag );

      /* Generate new unique Etag */
      _etag = generate_etag();
    }

    root->set_prop( "etag" , _etag );

    doc->set_root_element( root );
    _da.save( root );
    var res = doc->save_format_file( dest_filename, 1 );
    delete doc;

    /* If the save failed, restore the original etag and return false */
    if( res < 0 ) {
      _etag = orig_etag;
      return( false );
    }

    save_needed = false;

    return( true );

  }

  //-------------------------------------------------------------
  // Archives the contents of the opened Minder directory.
  public bool save() {

    stdout.printf( "Saving...\n" );

    // Create the tar.gz archive named according the the first argument
    Archive.Write archive = new Archive.Write ();
    archive.add_filter_gzip();
    archive.set_format_pax_restricted();
    archive.open_filename( filename );

    // Add the Minder file to the archive
    archive_file( archive, get_map_file() );

    // Add the images
    var image_ids = _da.image_manager.get_ids();
    for( int i=0; i<image_ids.length; i++ ) {
      var id = image_ids.index( i );
      archive_file( archive, _da.image_manager.get_file( id ), id );
    }

    // Close the archive
    if( archive.close() != Archive.Result.OK ) {
      error( "Error : %s (%d)", archive.error_string(), archive.errno() );
    }

    stdout.printf( "HERE!!!!\n" );

    // Indicate that a save is no longer needed
    save_needed = false;

    return( true );

  }

  //-------------------------------------------------------------
  // Adds the given file to the archive.
  public bool archive_file( Archive.Write archive, string fname, int? image_id = null ) {

    stdout.printf( "Attempting to archive, fname: %s\n", fname );

    try {

      var file              = GLib.File.new_for_path( fname );
      var file_info         = file.query_info( GLib.FileAttribute.STANDARD_SIZE, GLib.FileQueryInfoFlags.NONE );
      var input_stream      = file.read();
      var data_input_stream = new DataInputStream( input_stream );

      /* Add an entry to the archive */
      var entry = new Archive.Entry();
      entry.set_pathname( file.get_basename() );
      entry.set_size( (Archive.int64_t)file_info.get_size() );
      entry.set_filetype( Archive.FileType.IFREG );
      entry.set_perm( (Archive.FileMode)0644 );

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
        archive.write_data( buffer );
      }

    } catch( Error e ) {
      stdout.printf( "ERROR archiving: %s\n", e.message );
      critical( e.message );
      return( false );
    }

    return( true );

  }

  //-------------------------------------------------------------
  // Creates a temporary directory containing the unarchived
  // Minder files
  private void make_temp_dir() {
    try {
      _temp_dir = DirUtils.make_tmp( "minder-XXXXXX" );
      DirUtils.create( get_image_dir(), 0755 );
    } catch( Error e ) {
      critical( e.message );
    }
  }

  //-------------------------------------------------------------
  // Copies a file from one location to another
  private void move_file( string from, string to ) {
    var from_file = File.new_for_path( from );
    var to_file   = File.new_for_path( to );
    try {
      from_file.move( to_file, FileCopyFlags.OVERWRITE );
    } catch( Error e ) {
      critical( e.message );
    }
  }

  //-------------------------------------------------------------
  // Copies a file from one location to another */
  private void copy_file( string from, string to ) {
    var from_file = File.new_for_path( from );
    var to_file   = File.new_for_path( to );
    try {
      from_file.copy( to_file, FileCopyFlags.OVERWRITE );
    } catch( Error e ) {
      critical( e.message );
    }
  }

  //-------------------------------------------------------------
  // Returns the name of the map file to save to
  private string get_map_file() {
    return( GLib.Path.build_filename( _temp_dir, "map.xml" ) );
  }

  //-------------------------------------------------------------
  // Returns the name of the image directory within the temp
  // directory
  private string get_image_dir() {
    return( GLib.Path.build_filename( _temp_dir, "images" ) );
  }

  //-------------------------------------------------------------
  // Upgrades the existing XML Minder file to the new Minder
  // archive format, moving stored images to the new archive.
  private bool upgrade() {

    /* Move the Minder XML file to the temporary directory */
    move_file( filename, get_map_file() );

    /* Load the XML file */
    load_xml();

    /* Move all image files that are related to the temp images directory */
    var image_ids = _da.image_manager.get_ids();
    for( int i=0; i<image_ids.length; i++ ) {
      var id       = image_ids.index( i );
      var img_file = _da.image_manager.get_file( id );
      copy_file( img_file, GLib.Path.build_filename( get_image_dir(), GLib.Path.get_basename( img_file ) ) );
    }

    /* Set the image directory in the image manager */
    _da.image_manager.set_image_dir( get_image_dir() );

    /* Finally, create the new .minder file (it will act as a backup) */
    save();

    return( true );

  }

  //-------------------------------------------------------------
  // Deletes the given unnamed file when called
  public bool remove() {
    if( !_from_user ) {
      FileUtils.unlink( _filename );
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Auto-saves the document
  public void auto_save() {
    save_xml();
  }

  //-------------------------------------------------------------
  // This should be called when the application is closing.  This
  // will cause the document to be stored in .minder format and
  // will clean up tmp space.
  public void cleanup() {

    // Force the save to occur
    if( save_needed ) {
      save_xml();
      save();
    }

    // Delete the temporary directory
    DirUtils.remove( _temp_dir );

  }

}
