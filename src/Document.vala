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

public enum UpgradeAction {
  OVERRIDE,
  SAVE_AS,
  READ_ONLY,
  NUM;

  //-------------------------------------------------------------
  // Returns the label to display to the user for this option.
  public string? label() {
    switch( this ) {
      case OVERRIDE  :  return( _( "Upgrade older Minder file to new version" ) );
      case SAVE_AS   :  return( _( "Upgrade older Minder file to new with different filename" ) );
      case READ_ONLY :  return( _( "Do not upgrade older Minder file but view it as read-only" ) );
      default        :  return( null );
    }
  }

  //-------------------------------------------------------------
  // Returns an array of labels for upgrade action DropDown list.
  public static string[] labels() {
    string[] lbls = {};
    for( int i=0; i<NUM; i++ ) {
      var action = (UpgradeAction)i;
      if( action.label() != null ) {
        lbls += action.label();
      }
    }
    return( lbls );
  }

}

public delegate void AfterLoadFunc( bool loaded, string msg );

public class Document : Object {

  private MindMap _map;
  private string  _filename;
  private string  _temp_dir;
  private bool    _from_user;  // Set to true if _filename was set by the user
  private string  _etag;
  private bool    _upgrade_ro = false;
  private bool    _read_only  = false;

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
  public bool read_only {
    get {
      var prev_read_only = _read_only;
      _read_only = Utils.is_read_only( _filename );
      if( save_needed && prev_read_only && !_read_only && !_upgrade_ro ) {
        save();
      }
      return( _read_only || _upgrade_ro );
    }
  }

  public signal void read_only_changed();

  //-------------------------------------------------------------
  // Default constructor
  public Document( MindMap map ) {

    _map = map;

    // Generate unique Etag
    _etag = generate_etag();

    // Create the temporary file
    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder" );
    if( DirUtils.create_with_parents( dir, 0775 ) == 0 ) {
      int i = 1;
      do {
        _filename = GLib.Path.build_filename( dir, _( "unnamed" ) + "%d.minder".printf( i++ ) );
      } while( GLib.FileUtils.test( _filename, FileTest.EXISTS ) );
      _from_user = false;
    }

    // Create the temporary directory to store the mind map
    make_temp_dir();

    /* Listen for any changes from the canvas */
    map.changed.connect( canvas_changed );

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
    _from_user = saved;
  }

  //-------------------------------------------------------------
  // Returns the name of the backup file to use for the stored
  // filename.
  private string get_bak_file() {

    var file = GLib.File.new_for_path( filename );

    // Get parent directory
    var parent = file.get_parent ();
    var dir    = (parent != null) ? parent.get_path () : ".";
    var bak_basename = "." + file.get_basename() + ".bak";

    // Join dir + new basename
    return( GLib.Path.build_filename( dir, bak_basename ) );

  }

  //-------------------------------------------------------------
  // Returns true if the stored filename came from the user
  public bool is_saved() {
    return( _from_user );
  }

  //-------------------------------------------------------------
  // Searches the given file for a node with the given ID.  If
  // found, returns true along with the title of the node.
  public static bool xml_find( string fname, int id, ref string name ) {

    var found = false;

    Archive.Read archive = new Archive.Read();
    archive.support_filter_gzip();
    archive.support_format_all();

    /* Open the portable Minder file for reading */
    if( archive.open_filename( fname, 16384 ) != Archive.Result.OK ) {
      Xml.Doc* doc = Xml.Parser.read_file( fname, null, Xml.ParserOption.HUGE );
      if( doc != null ) {
        found = MapModel.xml_find( doc->get_root_element(), id, ref name );
        delete doc;
      }
      return( found );
    }

    unowned Archive.Entry entry;

    while( archive.next_header( out entry ) == Archive.Result.OK ) {
      if( entry.pathname() == "map.xml" ) {
        uint8[] data = new uint8[entry.size()];
        if( archive.read_data( data ) > 0 ) {
          var memory = (string)data;
          Xml.Doc* doc = Xml.Parser.read_memory( memory, memory.length, null, null, Xml.ParserOption.HUGE );
          if( doc != null ) {
            found = MapModel.xml_find( doc->get_root_element(), id, ref name );
            delete doc;
            break;
          }
        }
      }
    }

    archive.close();

    return( found );

  }

  //-------------------------------------------------------------
  // Reads in the map.xml file and returns the XML document.
  private Xml.Doc* load_raw() {
    return Xml.Parser.read_file( get_map_file(), null, (Xml.ParserOption.HUGE | Xml.ParserOption.NOWARNING) );
  }

  //-------------------------------------------------------------
  // Reads the stored etag attribute from the given XML document
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
      return( false );
    }

    // Load Etag
    _etag = get_etag( doc );

    // Load document
    _map.model.load( doc->get_root_element() );

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
  public void load( bool force_v1_readonly, AfterLoadFunc? func = null ) {

    var bak_file = get_bak_file();
    var fname    = (FileUtils.test( bak_file, FileTest.EXISTS ) && !_map.settings.get_boolean( "keep-backup-after-save" )) ? bak_file : filename;

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
    if( archive.open_filename( fname, 16384 ) != Archive.Result.OK ) {
      var action = force_v1_readonly ? UpgradeAction.READ_ONLY : (UpgradeAction)_map.settings.get_int( "upgrade-action" );
      if( _map.settings.get_boolean( "ask-for-upgrade-action" ) ) {
        request_upgrade_action( func );
      } else {
        upgrade( action, func );
      }
      return;
    }

    unowned Archive.Entry entry;

    while( archive.next_header( out entry ) == Archive.Result.OK ) {

      // We will need to modify the entry pathname so the file is written to the
      // proper location.
      if( entry.pathname() == "map.xml" ) {
        entry.set_pathname( GLib.Path.build_filename( _temp_dir, entry.pathname() ) );
      } else {
        entry.set_pathname( GLib.Path.build_filename( get_image_dir(), entry.pathname() ) );
      }

      // Read from the archive and write the files to disk
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

    // Close the archive
    if( archive.close () != Archive.Result.OK) {
      error( "Error: %s (%d)", archive.error_string(), archive.errno() );
    }

    // Set the image directory in the image manager
    _map.image_manager.set_image_dir( get_image_dir() );

    // Finally, load the minder file
    var loaded = load_xml();

    if( func != null ) {
      func( loaded, "load" );
    }

  }

  //-------------------------------------------------------------
  // Saves the given node information to the specified file
  public bool save_xml() {

    Xml.Doc* doc = load_raw();

    if( doc != null ) {

      string file_etag = get_etag( doc );

      // File was modified! Warn the user
      if( _etag != file_etag ) {
        var now = new DateTime.now_local();
        _map.win.ask_modified_overwrite( _map, (overwrite) => {
          if( overwrite ) {
            var fname = filename.replace( ".mind", "-backup-%s-%s.mind".printf( now.to_string(), file_etag ) );
            doc->save_format_file( fname, 1 );
          } else {
            var fname = filename.replace( ".mind", "-backup-%s-%s.mind".printf( now.to_string(), _etag ) );
            save_xml_internal( fname, false );
            _map.initialize_for_open();
            load( false );
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
    _map.model.save( root );
    var res = doc->save_format_file( dest_filename, 1 );
    delete doc;

    /* If the save failed, restore the original etag and return false */
    if( res < 0 ) {
      _etag = orig_etag;
      return( false );
    }

    return( true );

  }

  //-------------------------------------------------------------
  // Archives the contents of the opened Minder directory.
  public bool save() {

    stdout.printf( "Saving...\n" );

    var bak_file = get_bak_file();
    var backed   = false;

    // Copy the file to a .bak file if it currently exists
    if( FileUtils.test( filename, FileTest.EXISTS ) ) {
      copy_file( filename, bak_file );
      backed = true;
    }

    // Create the tar.gz archive named according the the first argument
    Archive.Write archive = new Archive.Write ();
    archive.add_filter_gzip();
    archive.set_format_pax_restricted();
    archive.open_filename( filename );

    // Add the Minder file to the archive
    archive_file( archive, get_map_file() );

    // Add the images
    var image_ids = _map.image_manager.get_ids();
    for( int i=0; i<image_ids.length; i++ ) {
      var id = image_ids.index( i );
      archive_file( archive, _map.image_manager.get_file( id ), id );
    }

    // Close the archive
    if( archive.close() != Archive.Result.OK ) {
      error( "Error : %s (%d)", archive.error_string(), archive.errno() );
    }

    // Remove the bak file if the save went well
    if( backed && !_map.settings.get_boolean( "keep-backup-after-save" ) ) {
      FileUtils.unlink( bak_file );
    }

    var upgrade_ro = _upgrade_ro;

    // Indicate that a save is no longer needed
    save_needed = false;
    _upgrade_ro = false;
    read_only_changed();

    return( true );

  }

  //-------------------------------------------------------------
  // Adds the given file to the archive.
  public bool archive_file( Archive.Write archive, string fname, int? image_id = null ) {

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
  private bool move_file( string from, string to ) {
    var from_file = File.new_for_path( from );
    var to_file   = File.new_for_path( to );
    try {
      from_file.move( to_file, FileCopyFlags.OVERWRITE );
    } catch( Error e ) {
      critical( e.message );
      return( false );
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Copies a file from one location to another */
  private bool copy_file( string from, string to ) {
    var from_file = File.new_for_path( from );
    var to_file   = File.new_for_path( to );
    try {
      from_file.copy( to_file, FileCopyFlags.OVERWRITE );
    } catch( Error e ) {
      critical( e.message );
      return( false );
    }
    return( true );
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
  // Perform the upgrade and run the given function.
  private void upgrade( UpgradeAction action, AfterLoadFunc? func ) {

    // Move the Minder XML file to the temporary directory
    if( !copy_file( filename, get_map_file() ) ) {
      if( func != null ) {
        func( false, "upgrade A" );
      }
      return;
    }

    // Load the XML file
    if( !load_xml() ) {
      if( func != null ) {
        func( false, "upgrade B" );
      }
      return;
    }

    // Move all image files that are related to the temp images directory
    var image_ids = _map.image_manager.get_ids();
    for( int i=0; i<image_ids.length; i++ ) {
      var id       = image_ids.index( i );
      var img_file = _map.image_manager.get_file( id );
      copy_file( img_file, GLib.Path.build_filename( get_image_dir(), GLib.Path.get_basename( img_file ) ) );
    }

    // Set the image directory in the image manager
    _map.image_manager.set_image_dir( get_image_dir() );

    switch( action ) {
      case UpgradeAction.OVERRIDE  :  save();  break;
      case UpgradeAction.SAVE_AS   :  _map.win.save_file( _map, false );  break;
      case UpgradeAction.READ_ONLY :  _upgrade_ro = true;  _map.editable_changed( _map );  break;
    }

    if( func != null ) {
      func( true, "upgrade C" );
    }

  }

  //-------------------------------------------------------------
  // Displays a dialog to the user to request what to do when
  // upgrading.
  private void request_upgrade_action( AfterLoadFunc? func ) {

    var dialog = new Granite.MessageDialog.with_image_from_icon_name(
      _( "Upgrade?" ),
      _( "This file is a version 1 Minder file and needs to be upgraded to edit." ),
      "system-software-update",
      ButtonsType.NONE
    );

    var cancel = new Button.with_label( _( "Cancel" ) );
    dialog.add_action_widget( cancel, ResponseType.CANCEL );

    var apply = new Button.with_label( _( "Apply" ) );
    dialog.add_action_widget( apply, ResponseType.APPLY );

    var options = new DropDown.from_strings( UpgradeAction.labels() ) {
      halign = Align.START,
      margin_top = 10,
      margin_start = 20
    };

    var remember = new CheckButton.with_label( _( "Use this option for future upgrades (this can be changed in preferences)" ) ) {
      halign = Align.START,
      margin_top = 10,
      margin_start = 20
    };

    var box = dialog.get_content_area();
    box.append( options );
    box.append( remember );

    dialog.set_transient_for( _map.win );
    dialog.set_modal( true );
    dialog.set_default_response( ResponseType.APPLY );
    dialog.set_title( _( "Upgrade Needed" ) );

    dialog.response.connect((id) => {
      if( id == ResponseType.APPLY ) {
        var action = (UpgradeAction)options.selected;
        _map.settings.set_int( "upgrade-action", action );
        _map.settings.set_boolean( "ask-for-upgrade-action", !remember.active );
        upgrade( action, func );
      } else if( (id == ResponseType.CANCEL) && (func != null) ) {
        func( false, "request_upgrade_action" );
      }
      dialog.close();
    });

    dialog.present();

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
