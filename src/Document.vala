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

  private DrawArea      _da;
  private string        _filename;
  private bool          _from_user;  // Set to true if _filename was set by the user
  private ImageManager  _image_manager;
  private string        _etag;

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

    /* Generate unique Etag */
    _etag = generate_etag();

    /* Create the temporary file */
    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder" );
    if( DirUtils.create_with_parents( dir, 0775 ) == 0 ) {
      int i = 1;
      do {
        _filename = GLib.Path.build_filename( dir, _( "unnamed" ) + "%d.minder".printf( i++ ) );
      } while( GLib.FileUtils.test( _filename, FileTest.EXISTS ) );
      _from_user = false;
    }

    /* Create the image manager */
    _image_manager = new ImageManager();

    /* Listen for any changes from the canvas */
    _da.changed.connect( canvas_changed );

  }

  /* Generate new "random" etag */
  private string generate_etag() {
    return GLib.Random.next_int().to_string();
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
      return Xml.Parser.read_file( filename, null, Xml.ParserOption.HUGE );
  }

  private string get_etag(Xml.Doc* doc) {
    for (Xml.Attr* prop = doc->get_root_element()->properties; prop != null; prop = prop->next) {
      string attr_name = prop->name;
      if ( attr_name != "etag" ) {
        continue;
      }

      return prop->children->content;
    }
    return generate_etag();
  }

  /* Opens the given filename */
  public bool load() {
    Xml.Doc* doc = load_raw();
    if( doc == null ) {
      return( false );
    }

    /* Load Etag */
    _etag = get_etag(doc);

    _da.load( doc->get_root_element() );
    delete doc;
    return( true );
  }

  /* Saves the given node information to the specified file */
  public bool save() {
    Xml.Doc* doc = load_raw();
    if( doc != null ) {
      /* Load Etag */
      string file_etag = get_etag(doc);
      if( _etag != file_etag ) {
        /* File was modified! Warn the user */
        if( _da.win.ask_modified_overwrite(_da) ) {
          doc->save_format_file( filename.replace(".mind", "-backup-%s-%s.mind".printf(new DateTime.now_local().to_string(), file_etag)), 1 );
        } else {
          save_internal(filename.replace(".mind", "-backup-%s-%s.mind".printf(new DateTime.now_local().to_string(), _etag)), false);
          load();
          return false;
        }
      }
    }

    return save_internal(filename, true);
  }

  private bool save_internal(string dest_filename, bool bump_etag) {
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "minder" );
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
    doc->save_format_file( dest_filename, 1 );
    delete doc;
    save_needed = false;
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
    if( save_needed ) {
      save();
    }
  }

}
