/*
* Copyright (c) 2025 (https://github.com/phase1geo/Minder)
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

using Gdk;

public enum MapState {
  NONE,
  NODE,
  CONNECTION,
  CALLOUT,
  STICKER,
  GROUP,
  EDITING;

  //-------------------------------------------------------------
  // Returns the state from the given MindMap
  public static MapState get_state( MindMap map ) {
    if( map.is_node_selected() ) {
      return( NODE );
    } else if( map.is_connection_selected() ) {
      return( CONNECTION );
    } else if( map.is_callout_selected() ) {
      return( CALLOUT );
    } else if( map.is_sticker_selected() ) {
      return( STICKER );
    } else if( map.is_group_selected() ) {
      return( GROUP );
    } else if( map.is_node_editable() || map.is_connection_editable() || map.is_callout_editable() ) {
      return( EDITING );
    } else {
      return( NONE );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the given state matches that required for the
  // given command.
  public static bool matches( MapState state, KeyCommand command ) {
    if( (state == MapState.NODE) && command.for_node() ) {
      return( true );
    } else if( (state == MapState.CONNECTION) && command.for_connection() ) {
      return( true );
    } else if( (state == MapState.CALLOUT) && command.for_callout() ) {
      return( true );
    } else if( (state == MapState.STICKER) && command.for_sticker() ) {
      return( true );
    } else if( (state == MapState.GROUP) && command.for_group() ) {
      return( true );
    } else if( (state == MapState.EDITING) && command.for_editing() ) {
      return( true );
    } else if( (state == MapState.NONE) && command.for_none() ) {
      return( true );
    } else {
      return( false );
    }
  }

}

public class Shortcut {

  private uint           _keycode;
  private bool           _control;
  private bool           _shift;
  private bool           _alt;
  private KeyCommand     _command;
  private KeyCommandFunc _func;

  //-------------------------------------------------------------
  // Default constructor.
  public Shortcut( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    _keycode = keycode;
    _control = control;
    _shift   = shift;
    _alt     = alt;
    _command = command;
    _func    = command.get_func();
  }

  //-------------------------------------------------------------
  // Constructor from XML.
  public Shortcut.from_xml( Xml.Node* node ) {
    load( node );
  }

  //-------------------------------------------------------------
  // Returns true if our keycode matches the input keycode from
  // the user.
  private bool has_key( uint[] kvs ) {
    foreach( uint kv in kvs ) {
      if( kv == _keycode ) return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut matches the given values exactly.
  // TODO - The command should only compare the prefixes.
  public bool equals( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    return( (_keycode == keycode) &&
            (_control == control) &&
            (_shift   == shift)   &&
            (_alt     == alt)     &&
            (_command == command) );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut matches the given command.
  public bool matches_command( KeyCommand command ) {
    return( _command == command );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut matches the given match values
  public bool matches_keypress( bool control, bool shift, bool alt, uint[] kvs, MapState state ) {
    return( (_control == control) &&
            (_shift   == shift)   &&
            (_alt     == alt)     &&
            has_key( kvs )        &&
            MapState.matches( state, _command ) );
  }

  //-------------------------------------------------------------
  // Executes the stored function with the given map.
  public void execute( MindMap map ) {
    _func( map );
  }

  //-------------------------------------------------------------
  // Returns the Gtk4 accelerator for this shortcut.
  public string get_accelerator() {
    var accel = "";
    if( _control ) {
      accel += "<Control>";
    }
    if( _shift ) {
      accel += "<Shift>";
    }
    if( _alt ) {
      accel += "<Alt>";
    }
    accel += keyval_name( _keycode );
    return( accel );
  }

  //-------------------------------------------------------------
  // Saves the contents of this shortcut to an XML node and returns
  // it.
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "shortcut" );
    node->set_prop( "key",     _keycode.to_string() );
    node->set_prop( "control", _control.to_string() );
    node->set_prop( "shift",   _shift.to_string() );
    node->set_prop( "alt",     _alt.to_string() );
    node->set_prop( "command", _command.to_string() );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads this shortcut from an XML node.
  private void load( Xml.Node* node ) {
    var k = node->get_prop( "key" );
    if( k != null ) {
      _keycode = uint.parse( k );
    }
    var c = node->get_prop( "control" );
    if( c != null ) {
      _control = bool.parse( c );
    }
    var s = node->get_prop( "shift" );
    if( s != null ) {
      _shift = bool.parse( s );
    }
    var a = node->get_prop( "alt" );
    if( a != null ) {
      _alt = bool.parse( a );
    }
    var cmd = node->get_prop( "command" );
    if( cmd != null ) {
      _command = KeyCommand.parse( cmd );
      _func    = _command.get_func();
    }
  }

}


public class Shortcuts {

  private Array<Shortcut> _shortcuts;

  //-------------------------------------------------------------
  // Default constructor
  public Shortcuts() {

    _shortcuts = new Array<Shortcut>();

    load();

  }

  //-------------------------------------------------------------
  // Clears the shortcut for the given command, if it exists.
  // Called by the shortcut preferences class.
  public void clear_shortcut( KeyCommand command, bool auto_save = true ) {
    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).matches_command( command ) ) {
        _shortcuts.remove_index( i );
        if( auto_save ) {
          save();
        }
        return;
      }
    }
  }

  //-------------------------------------------------------------
  // Sets the shortcut for the given command.  Called by the
  // shortcut preferences class.
  public void set_shortcut( KeyCommand command, uint keycode, bool control, bool shift, bool alt ) {
    clear_shortcut( command, false );  // TODO - This is probably not going to be necessary
    add_shortcut( keycode, control, shift, alt, command );
    save();
  }

  //-------------------------------------------------------------
  // Returns the shortcut associated with the given command in the
  // current map state.  If none is found, returns null.
  public Shortcut? get_shortcut( MindMap map, KeyCommand command ) {
    var map_state = MapState.get_state( map );
    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).matches_command( command ) && MapState.matches( map_state, command ) ) {
        return( _shortcuts.index( i ) );
      }
    }
    return( null ); 
  }

  //-------------------------------------------------------------
  // Checks to see if the given shortcut is already mapped.
  public bool shortcut_exists( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).equals( keycode, control, shift, alt, command ) ) {
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Executes the command associated with the given keypress
  // information.  If no shortcut exists, return false to indicate
  // that the calling code should insert the character if we are
  // editing an element in the map.
  public bool execute( MindMap map, uint keyval, uint keycode, ModifierType mods ) {

    KeymapKey[] ks      = {};
    uint[]      kvs     = {};
    var         state   = MapState.get_state( map );
    var         control = (mods & ModifierType.CONTROL_MASK) == ModifierType.CONTROL_MASK;
    var         shift   = (mods & ModifierType.SHIFT_MASK)   == ModifierType.SHIFT_MASK;
    var         alt     = (mods & ModifierType.ALT_MASK)     == ModifierType.ALT_MASK;

    Display.get_default().map_keycode( keycode, out ks, out kvs );

    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).matches_keypress( control, shift, alt, kvs, state ) ) {
        _shortcuts.index( i ).execute( map );
        return( true );
      }
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Returns the path of the shortcuts file.
  private string shortcuts_path() {
    return( GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "shortcuts.xml" ) );
  }

  //-------------------------------------------------------------
  // Saves the shortcuts to the shortcuts XML file.
  public void save() {

    Xml.Doc*  doc   = new Xml.Doc( "1.0" );
    Xml.Node* root  = new Xml.Node( null, "shortcuts" );

    doc->set_root_element( root );

    for( int i=0; i<_shortcuts.length; i++ ) {
      var shortcut = _shortcuts.index( i );
      root->add_child( shortcut.save() );
    }

    /* Save the file */
    doc->save_format_file( shortcuts_path(), 1 );

    delete doc;

  }

  //-------------------------------------------------------------
  // Loads the shortcuts from the shortcuts XML file.
  private void load() {

    create_builtin_shortcuts();

    Xml.Doc* doc = Xml.Parser.parse_file( shortcuts_path() );

    if( doc == null ) {
      create_default_shortcuts();
      return;
    }

    var root = doc->get_root_element();

    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "shortcut") ) {
        var shortcut = new Shortcut.from_xml( it );
        _shortcuts.append_val( shortcut );
      }
    }

    delete doc;

  }

  //-------------------------------------------------------------
  // Adds a single shortcut to the list of shortcuts.
  private void add_shortcut( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    var shortcut = new Shortcut( keycode, control, shift, alt, command );
    _shortcuts.append_val( shortcut );
  }

  //-------------------------------------------------------------
  // Creates the built-in shortcuts (these are not stored in the
  // shortcuts.xml file)
  private void create_builtin_shortcuts() {

    add_shortcut( Key.BackSpace,    false, false, false, KeyCommand.EDIT_BACKSPACE );
    add_shortcut( Key.BackSpace,    false, false, false, KeyCommand.NODE_REMOVE );
    add_shortcut( Key.BackSpace,    false, false, false, KeyCommand.CONNECTION_REMOVE );
    add_shortcut( Key.BackSpace,    false, false, false, KeyCommand.CALLOUT_REMOVE );
    add_shortcut( Key.BackSpace,    false, false, false, KeyCommand.STICKER_REMOVE );
    add_shortcut( Key.BackSpace,    false, false, false, KeyCommand.GROUP_REMOVE );
    add_shortcut( Key.Delete,       false, false, false, KeyCommand.EDIT_DELETE );
    add_shortcut( Key.Delete,       false, false, false, KeyCommand.NODE_REMOVE );
    add_shortcut( Key.Delete,       false, false, false, KeyCommand.CONNECTION_REMOVE );
    add_shortcut( Key.Delete,       false, false, false, KeyCommand.CALLOUT_REMOVE );
    add_shortcut( Key.Delete,       false, false, false, KeyCommand.STICKER_REMOVE );
    add_shortcut( Key.Delete,       false, false, false, KeyCommand.GROUP_REMOVE );
    add_shortcut( Key.Escape,       false, false, false, KeyCommand.ESCAPE );
    add_shortcut( Key.Escape,       false, false, false, KeyCommand.EDIT_ESCAPE );

    add_shortcut( Key.Return,       false, false, false, KeyCommand.DO_NOTHING );  // "return" );
    add_shortcut( Key.Return,       false, true,  false, KeyCommand.DO_NOTHING );  // "shift-return" );
    add_shortcut( Key.Tab,          false, false, false, KeyCommand.DO_NOTHING );  // "tab" );
    add_shortcut( Key.Tab,          false, true,  false, KeyCommand.DO_NOTHING );  // "shift-tab" );
    add_shortcut( Key.Right,        false, false, false, KeyCommand.EDIT_CURSOR_CHAR_NEXT );
    add_shortcut( Key.Right,        false, false, false, KeyCommand.NODE_SELECT_RIGHT );
    add_shortcut( Key.Right,        false, true,  false, KeyCommand.EDIT_SELECT_CHAR_NEXT );
    add_shortcut( Key.Left,         false, false, false, KeyCommand.EDIT_CURSOR_CHAR_PREV );
    add_shortcut( Key.Left,         false, false, false, KeyCommand.NODE_SELECT_LEFT );
    add_shortcut( Key.Left,         false, true,  false, KeyCommand.EDIT_SELECT_CHAR_PREV );
    add_shortcut( Key.Up,           false, false, false, KeyCommand.EDIT_CURSOR_UP );
    add_shortcut( Key.Up,           false, false, false, KeyCommand.NODE_SELECT_UP );
    add_shortcut( Key.Up,           false, false, true,  KeyCommand.NODE_SWAP_UP );
    add_shortcut( Key.Up,           false, true,  false, KeyCommand.EDIT_SELECT_UP );
    add_shortcut( Key.Down,         false, false, false, KeyCommand.EDIT_CURSOR_DOWN );
    add_shortcut( Key.Down,         false, false, false, KeyCommand.NODE_SELECT_DOWN );
    add_shortcut( Key.Down,         false, false, true,  KeyCommand.NODE_SWAP_DOWN );
    add_shortcut( Key.Down,         false, true,  false, KeyCommand.EDIT_SELECT_DOWN );
    add_shortcut( Key.Page_Up,      false, false, false, KeyCommand.DO_NOTHING );  // "page-up" );
    add_shortcut( Key.Page_Down,    false, false, false, KeyCommand.DO_NOTHING );  // "page-down" );
    add_shortcut( Key.Control_L,    false, false, false, KeyCommand.CONTROL_PRESSED );
    add_shortcut( Key.Control_R,    false, false, false, KeyCommand.CONTROL_PRESSED );

  }

  //-------------------------------------------------------------
  // If the shortcuts file is missing, we will create the default
  // set of shortcuts and save them to the save file.
  private void create_default_shortcuts() {

    // TODO - Cleanup command names

    add_shortcut( Key.c,            true, false, false, KeyCommand.EDIT_COPY );
    add_shortcut( Key.x,            true, false, false, KeyCommand.EDIT_CUT );
    add_shortcut( Key.v,            true, false, false, KeyCommand.EDIT_PASTE );
    add_shortcut( Key.v,            true, true,  false, KeyCommand.NODE_PASTE_REPLACE );
    add_shortcut( Key.Return,       true, false, false, KeyCommand.EDIT_INSERT_NEWLINE );
    add_shortcut( Key.BackSpace,    true, false, false, KeyCommand.EDIT_REMOVE_WORD_PREV );
    add_shortcut( Key.Delete,       true, false, false, KeyCommand.EDIT_REMOVE_WORD_NEXT );
    add_shortcut( Key.Tab,          true, false, false, KeyCommand.EDIT_INSERT_TAB );
    add_shortcut( Key.Right,        true, true,  false, KeyCommand.EDIT_SELECT_WORD_NEXT );
    add_shortcut( Key.Right,        true, false, false, KeyCommand.EDIT_CURSOR_WORD_NEXT );
    add_shortcut( Key.Left,         true, true,  false, KeyCommand.EDIT_SELECT_WORD_PREV );
    add_shortcut( Key.Left,         true, false, false, KeyCommand.EDIT_CURSOR_WORD_PREV );
    add_shortcut( Key.Up,           true, true,  false, KeyCommand.EDIT_SELECT_START_UP );
    add_shortcut( Key.Up,           true, false, false, KeyCommand.EDIT_CURSOR_START );
    add_shortcut( Key.Down,         true, true,  false, KeyCommand.EDIT_SELECT_END_DOWN );
    add_shortcut( Key.Down,         true, false, false, KeyCommand.EDIT_CURSOR_END );
    add_shortcut( Key.Home,         true, true,  false, KeyCommand.EDIT_SELECT_START_HOME );
    add_shortcut( Key.Home,         true, false, false, KeyCommand.EDIT_CURSOR_LINESTART );
    add_shortcut( Key.End,          true, true,  false, KeyCommand.EDIT_SELECT_END_END );
    add_shortcut( Key.End,          true, false, false, KeyCommand.EDIT_CURSOR_LINEEND );
    add_shortcut( Key.a,            true, false, false, KeyCommand.EDIT_SELECT_ALL );
    add_shortcut( Key.a,            true, true,  false, KeyCommand.EDIT_SELECT_NONE );
    add_shortcut( Key.period,       true, false, false, KeyCommand.EDIT_INSERT_EMOJI );
    add_shortcut( Key.e,            true, true,  false, KeyCommand.NODE_QUICK_ENTRY_INSERT );
    add_shortcut( Key.k,            true, false, false, KeyCommand.EDIT_ADD_URL );
    add_shortcut( Key.k,            true, true,  false, KeyCommand.EDIT_REMOVE_URL );
    add_shortcut( Key.r,            true, true,  false, KeyCommand.NODE_QUICK_ENTRY_REPLACE );
    add_shortcut( Key.y,            true, false, false, KeyCommand.NODE_PASTE_NODE_LINK );

    add_shortcut( Key.F10,          false, true,  false, KeyCommand.SHOW_CONTEXTUAL_MENU );
    add_shortcut( Key.Menu,         false, false, false, KeyCommand.SHOW_CONTEXTUAL_MENU );

    add_shortcut( Key.minus,        false, false, false, KeyCommand.NODE_ALIGN_TOP );
    add_shortcut( Key.equal,        false, false, false, KeyCommand.NODE_ALIGN_VCENTER );
    add_shortcut( Key.z,            false, true,  false, KeyCommand.ZOOM_IN );
    add_shortcut( Key.bracketleft,  false, false, false, KeyCommand.NODE_ALIGN_LEFT );
    add_shortcut( Key.bracketright, false, false, false, KeyCommand.NODE_ALIGN_RIGHT );
    add_shortcut( Key.underscore,   false, true,  false, KeyCommand.NODE_ALIGN_BOTTOM );
    add_shortcut( Key.a,            false, false, false, KeyCommand.NODE_SELECT_PARENT );
    add_shortcut( Key.d,            false, false, false, KeyCommand.NODE_SELECT_CHILDREN );
    add_shortcut( Key.f,            false, false, false, KeyCommand.NODE_TOGGLE_FOLDS_SHALLOW );
    add_shortcut( Key.f,            false, true,  false, KeyCommand.NODE_TOGGLE_FOLDS_DEEP );
    add_shortcut( Key.g,            false, false, false, KeyCommand.NODE_ADD_GROUP );
    add_shortcut( Key.l,            false, true,  false, KeyCommand.NODE_CHANGE_LINK_COLOR );
    add_shortcut( Key.m,            false, false, false, KeyCommand.NODE_SELECT_ROOT );
    add_shortcut( Key.r,            false, false, false, KeyCommand.REDO_ACTION );
    add_shortcut( Key.t,            false, false, false, KeyCommand.NODE_CHANGE_TASK );
    add_shortcut( Key.u,            false, false, false, KeyCommand.UNDO_ACTION );
    add_shortcut( Key.z,            false, false, false, KeyCommand.ZOOM_OUT );
    add_shortcut( Key.bar,          false, true,  false, KeyCommand.NODE_ALIGN_HCENTER );
    add_shortcut( Key.numbersign,   false, true,  false, KeyCommand.NODE_TOGGLE_SEQUENCE );
    add_shortcut( Key.x,            false, false, false, KeyCommand.NODE_ADD_CONNECTION );
    add_shortcut( Key.y,            false, false, false, KeyCommand.NODE_TOGGLE_LINKS );
    add_shortcut( Key.e,            false, true,  false, KeyCommand.EDIT_NOTE );
    add_shortcut( Key.i,            false, false, false, KeyCommand.SHOW_CURRENT_SIDEBAR );
    add_shortcut( Key.e,            false, false, false, KeyCommand.EDIT_SELECTED );
    add_shortcut( Key.s,            false, false, false, KeyCommand.SHOW_SELECTED );

    add_shortcut( Key.o,            false, true,  false, KeyCommand.CALLOUT_SELECT_NODE );

    add_shortcut( Key.f,            false, false, false, KeyCommand.CONNECTION_SELECT_FROM );
    add_shortcut( Key.n,            false, false, false, KeyCommand.CONNECTION_SELECT_NEXT );
    add_shortcut( Key.p,            false, false, false, KeyCommand.CONNECTION_SELECT_PREV );
    add_shortcut( Key.t,            false, false, false, KeyCommand.CONNECTION_SELECT_TO );

    add_shortcut( Key.c,            false, true,  false, KeyCommand.NODE_CENTER );
    add_shortcut( Key.d,            false, true,  false, KeyCommand.NODE_SELECT_TREE );
    add_shortcut( Key.i,            false, true,  false, KeyCommand.NODE_ADD_IMAGE );
    add_shortcut( Key.o,            false, true,  false, KeyCommand.NODE_SELECT_CALLOUT );
    add_shortcut( Key.s,            false, true,  false, KeyCommand.NODE_SORT_ALPHABETICALLY );
    add_shortcut( Key.x,            false, true,  false, KeyCommand.NODE_SELECT_CONNECTION );
    add_shortcut( Key.y,            false, true,  false, KeyCommand.NODE_SELECT_LINKED );
    add_shortcut( Key.c,            false, false, false, KeyCommand.NODE_SELECT_CHILD );
    add_shortcut( Key.h,            false, false, false, KeyCommand.NODE_SELECT_LEFT );
    add_shortcut( Key.j,            false, false, false, KeyCommand.NODE_SELECT_DOWN );
    add_shortcut( Key.k,            false, false, false, KeyCommand.NODE_SELECT_UP );
    add_shortcut( Key.l,            false, false, false, KeyCommand.NODE_SELECT_RIGHT );
    add_shortcut( Key.n,            false, false, false, KeyCommand.NODE_SELECT_SIBLING_NEXT );
    add_shortcut( Key.o,            false, false, false, KeyCommand.NODE_ADD_CALLOUT );
    add_shortcut( Key.p,            false, false, false, KeyCommand.NODE_SELECT_SIBLING_PREV );
    add_shortcut( Key.x,            false, false, false, KeyCommand.NODE_ADD_CONNECTION );
    add_shortcut( Key.Left,         false, false, true,  KeyCommand.NODE_SWAP_LEFT );
    add_shortcut( Key.Right,        false, false, true,  KeyCommand.NODE_SWAP_RIGHT );
    add_shortcut( Key.Up,           false, false, true,  KeyCommand.NODE_SWAP_UP );
    add_shortcut( Key.Down,         false, false, true,  KeyCommand.NODE_SWAP_DOWN );

    // Save the shortcuts to the save file
    save();

  }

}
