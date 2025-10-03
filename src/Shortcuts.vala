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
    if( map.is_node_editable() || map.is_connection_editable() || map.is_callout_editable() ) {
      return( EDITING );
    } else if( map.selected.num_nodes() > 0 ) {
      return( NODE );
    } else if( map.selected.num_connections() > 0 ) {
      return( CONNECTION );
    } else if( map.selected.num_callouts() > 0 ) {
      return( CALLOUT );
    } else if( map.selected.num_stickers() > 0 ) {
      return( STICKER );
    } else if( map.selected.num_groups() > 0 ) {
      return( GROUP );
    } else {
      return( NONE );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the given state matches that required for the
  // given command.
  public static bool matches( MapState state, KeyCommand command ) {
    var for_node = command.for_node();
    var for_conn = command.for_connection();
    var for_call = command.for_callout();
    var for_stkr = command.for_sticker();
    var for_grp  = command.for_group();
    var for_edit = command.for_editing();
    var for_none = command.for_none();
    var for_any  = !for_node && !for_conn && !for_call && !for_stkr && !for_grp && !for_edit && !for_none;
    return(
      (for_node && (state == MapState.NODE))       ||
      (for_conn && (state == MapState.CONNECTION)) ||
      (for_call && (state == MapState.CALLOUT))    ||
      (for_stkr && (state == MapState.STICKER))    ||
      (for_grp  && (state == MapState.GROUP))      ||
      (for_edit && (state == MapState.EDITING))    ||
      (for_none && (state == MapState.NONE))       ||
      for_any
    );
  }

}

public class Shortcut {

  private uint           _keycode;
  private bool           _control;
  private bool           _shift;
  private bool           _alt;
  private KeyCommand     _command;
  private KeyCommandFunc _func;

  public KeyCommand command {
    get {
      return( _command );
    }
  }

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
  public bool conflicts_with( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    return(
      (_keycode == keycode) &&
      (_control == control) &&
      (_shift   == shift)   &&
      (_alt     == alt)     &&
      (_command != command) &&
      _command.target_matches( command )
    );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut matches the contents of the provided
  // shortcut.
  public bool matches_shortcut( Shortcut shortcut ) {
    return( (_keycode == shortcut._keycode) &&
            (_control == shortcut._control) &&
            (_shift   == shortcut._shift)   &&
            (_alt     == shortcut._alt)     &&
            (_command == shortcut._command) );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut matches the given command.
  public bool matches_command( KeyCommand command ) {
    return( _command == command );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut matches the given match values
  public bool matches_keypress( bool control, bool shift, bool alt, uint[] kvs, MapState state ) {
    return(
      (_control == control) &&
      (_shift   == shift)   &&
      (_alt     == alt)     &&
      has_key( kvs )        &&
      MapState.matches( state, _command )
    );
  }

  //-------------------------------------------------------------
  // Returns true if this shortcut can be edited by the user and
  // needs to be saved to the shortcuts.xml file.
  public bool editable() {
    return( _command.editable() );
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
    if( _shift &&
        (!keyval_is_lower( _keycode ) ||
         !keyval_is_upper( _keycode ) ||
         (_keycode == Key.Delete)     ||
         (_keycode == Key.BackSpace)  ||
         (_keycode == Key.Tab)        ||
         (_keycode == Key.Return))
    ) {
      accel += "<Shift>";
    }
    if( _alt ) {
      accel += "<Alt>";
    }
    accel += keyval_name( _keycode );
    return( accel );
  }

  //-------------------------------------------------------------
  // Returns a string with the shortcut string to display in the
  // preferences label.
  public string get_label() {
    string[] lbl = {};
    unichar  uc  = keyval_to_unicode( _keycode );
    string   str = "";
    if( _control ) {
      lbl += "Ctrl";
    }
    if( _shift ) {
      lbl += "Shift";
    }
    if( _alt ) {
      lbl += "Alt";
    }
    lbl += uc.isprint() ? uc.to_string().up() : keyval_name( _keycode );
    return( string.joinv( "+", lbl ) );
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
  private Array<Shortcut> _defaults;

  public signal void shortcut_changed( KeyCommand command, Shortcut? shortcut );

  //-------------------------------------------------------------
  // Default constructor
  public Shortcuts() {

    _shortcuts = new Array<Shortcut>();
    _defaults  = new Array<Shortcut>();

    create_default_shortcuts();

    add_builtin_shortcuts();
    load();

  }

  //-------------------------------------------------------------
  // Removes the shortcut associated with the given command.  Returns
  // true if the shortcut is found and removed.
  private bool remove_shortcut( KeyCommand command ) {
    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).matches_command( command ) ) {
        _shortcuts.remove_index( i );
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Clears the shortcut for the given command, if it exists.
  // Called by the shortcut preferences class.
  public void clear_shortcut( KeyCommand command ) {
    if( remove_shortcut( command ) ) {
      shortcut_changed( command, null );
      save();
    }
  }

  //-------------------------------------------------------------
  // Clears all of the shortcuts
  public void clear_all_shortcuts() {
    for( int i=0; i<KeyCommand.NUM; i++ ) {
      var command = (KeyCommand)i;
      if( remove_shortcut( command ) ) {
        shortcut_changed( command, null );
      }
    }
  }

  //-------------------------------------------------------------
  // Sets the shortcut for the given command.  Called by the
  // shortcut preferences class.
  public void set_shortcut( Shortcut shortcut ) {
    remove_shortcut( shortcut.command );
    _shortcuts.append_val( shortcut );
    shortcut_changed( shortcut.command, shortcut );
    save();
  }

  //-------------------------------------------------------------
  // Returns the shortcut associated with the given command in the
  // current map state.  If none is found, returns null.
  public Shortcut? get_shortcut( KeyCommand command ) {
    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).matches_command( command ) ) {
        return( _shortcuts.index( i ) );
      }
    }
    return( null ); 
  }

  //-------------------------------------------------------------
  // Returns the default shortcut associated with the given
  // keycommand and return it.  If it cannot be found, return
  // null.
  public Shortcut? get_default_shortcut( KeyCommand command ) {
    for( int i=0; i<_defaults.length; i++ ) {
      if( _defaults.index( i ).matches_command( command ) ) {
        return( _defaults.index( i ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Checks to see if the given shortcut is already mapped.
  public Shortcut? shortcut_conflicts_with( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).conflicts_with( keycode, control, shift, alt, command ) ) {
        return( _shortcuts.index( i ) );
      }
    }
    return( null );
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
      if( shortcut.editable() ) {
        root->add_child( shortcut.save() );
      }
    }

    /* Save the file */
    doc->save_format_file( shortcuts_path(), 1 );

    delete doc;

  }

  //-------------------------------------------------------------
  // Loads the shortcuts from the shortcuts XML file.
  private void load() {

    Xml.Doc* doc = Xml.Parser.parse_file( shortcuts_path() );

    if( doc == null ) {
      add_default_shortcuts();
      save();
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
  // Creates a shortcut from the given information and adds it to the
  // list of default shortcuts.
  private void add_default( uint keycode, bool control, bool shift, bool alt, KeyCommand command ) {
    var shortcut = new Shortcut( keycode, control, shift, alt, command );
    _defaults.append_val( shortcut );
  }

  //-------------------------------------------------------------
  // Adds all of the default shortcuts to the shortcuts array.
  // This will be called internally if the shortcuts.xml file
  // does not exist.
  public void add_default_shortcuts() {
    for( int i=0; i<_defaults.length; i++ ) {
      _shortcuts.append_val( _defaults.index( i ) );
    }
  }

  //-------------------------------------------------------------
  // Restores all of the default shortcuts
  public void restore_default_shortcuts() {
    clear_all_shortcuts();
    add_builtin_shortcuts();
    add_default_shortcuts();
    for( int i=0; i<_shortcuts.length; i++ ) {
      shortcut_changed( _shortcuts.index( i ).command, _shortcuts.index( i ) );
    }
  }

  //-------------------------------------------------------------
  // Creates the built-in shortcuts (these are not stored in the
  // shortcuts.xml file and therefore cannot be changed by the user)
  public void add_builtin_shortcuts() {

    add_shortcut( Key.Escape,    false, false, false, KeyCommand.ESCAPE );
    add_shortcut( Key.Escape,    false, false, false, KeyCommand.EDIT_ESCAPE );
    add_shortcut( Key.BackSpace, false, false, false, KeyCommand.EDIT_BACKSPACE );
    add_shortcut( Key.BackSpace, false, false, false, KeyCommand.NODE_REMOVE );
    add_shortcut( Key.BackSpace, false, true,  false, KeyCommand.NODE_REMOVE_ONLY );
    add_shortcut( Key.BackSpace, false, false, false, KeyCommand.CONNECTION_REMOVE );
    add_shortcut( Key.BackSpace, false, false, false, KeyCommand.CALLOUT_REMOVE );
    add_shortcut( Key.BackSpace, false, false, false, KeyCommand.STICKER_REMOVE );
    add_shortcut( Key.BackSpace, false, false, false, KeyCommand.GROUP_REMOVE );
    add_shortcut( Key.Delete,    false, false, false, KeyCommand.EDIT_DELETE );
    add_shortcut( Key.Delete,    false, false, false, KeyCommand.NODE_REMOVE );
    add_shortcut( Key.Delete,    false, true,  false, KeyCommand.NODE_REMOVE_ONLY );
    add_shortcut( Key.Delete,    false, false, false, KeyCommand.CONNECTION_REMOVE );
    add_shortcut( Key.Delete,    false, false, false, KeyCommand.CALLOUT_REMOVE );
    add_shortcut( Key.Delete,    false, false, false, KeyCommand.STICKER_REMOVE );
    add_shortcut( Key.Delete,    false, false, false, KeyCommand.GROUP_REMOVE );

    add_shortcut( Key.Return,    false, false, false, KeyCommand.EDIT_RETURN );
    add_shortcut( Key.Return,    false, false, false, KeyCommand.NODE_ADD_SIBLING_AFTER );
    add_shortcut( Key.Return,    false, true,  false, KeyCommand.EDIT_SHIFT_RETURN );
    add_shortcut( Key.Return,    false, true,  false, KeyCommand.NODE_ADD_SIBLING_BEFORE );
    add_shortcut( Key.Tab,       false, false, false, KeyCommand.EDIT_TAB );
    add_shortcut( Key.Tab,       false, false, false, KeyCommand.NODE_ADD_CHILD );
    add_shortcut( Key.Tab,       false, true,  false, KeyCommand.EDIT_SHIFT_TAB );
    add_shortcut( Key.Tab,       false, true,  false, KeyCommand.NODE_ADD_PARENT );
    add_shortcut( Key.Right,     false, false, false, KeyCommand.EDIT_CURSOR_CHAR_NEXT );
    add_shortcut( Key.Right,     false, false, false, KeyCommand.NODE_SELECT_RIGHT );
    add_shortcut( Key.Right,     false, true,  false, KeyCommand.EDIT_SELECT_CHAR_NEXT );
    add_shortcut( Key.Left,      false, false, false, KeyCommand.EDIT_CURSOR_CHAR_PREV );
    add_shortcut( Key.Left,      false, false, false, KeyCommand.NODE_SELECT_LEFT );
    add_shortcut( Key.Left,      false, true,  false, KeyCommand.EDIT_SELECT_CHAR_PREV );
    add_shortcut( Key.Up,        false, false, false, KeyCommand.EDIT_CURSOR_UP );
    add_shortcut( Key.Up,        false, false, false, KeyCommand.NODE_SELECT_UP );
    add_shortcut( Key.Up,        false, false, true,  KeyCommand.NODE_SWAP_UP );
    add_shortcut( Key.Up,        false, true,  false, KeyCommand.EDIT_SELECT_UP );
    add_shortcut( Key.Down,      false, false, false, KeyCommand.EDIT_CURSOR_DOWN );
    add_shortcut( Key.Down,      false, false, false, KeyCommand.NODE_SELECT_DOWN );
    add_shortcut( Key.Down,      false, false, true,  KeyCommand.NODE_SWAP_DOWN );
    add_shortcut( Key.Down,      false, true,  false, KeyCommand.EDIT_SELECT_DOWN );
    add_shortcut( Key.Page_Up,   false, false, false, KeyCommand.NODE_SELECT_SIBLING_PREV );
    add_shortcut( Key.Page_Down, false, false, false, KeyCommand.NODE_SELECT_SIBLING_NEXT );
    add_shortcut( Key.Control_L, false, false, false, KeyCommand.CONTROL_PRESSED );
    add_shortcut( Key.Control_R, false, false, false, KeyCommand.CONTROL_PRESSED );

  }

  //-------------------------------------------------------------
  // If the shortcuts file is missing, we will create the default
  // set of shortcuts and save them to the save file.
  private void create_default_shortcuts() {

    add_default( Key.n,            true, false, false, KeyCommand.FILE_NEW );
    add_default( Key.o,            true, false, false, KeyCommand.FILE_OPEN );
    add_default( Key.o,            true, true,  false, KeyCommand.FILE_OPEN_DIR );
    add_default( Key.s,            true, false, false, KeyCommand.FILE_SAVE );
    add_default( Key.s,            true, true,  false, KeyCommand.FILE_SAVE_AS );
    add_default( Key.q,            true, false, false, KeyCommand.QUIT );
    add_default( Key.z,            true, false, false, KeyCommand.UNDO_ACTION );
    add_default( Key.z,            true, true,  false, KeyCommand.REDO_ACTION );
    add_default( Key.@0,           true, false, false, KeyCommand.ZOOM_ACTUAL );
    add_default( Key.@1,           true, false, false, KeyCommand.ZOOM_FIT );
    add_default( Key.@2,           true, false, false, KeyCommand.ZOOM_SELECTED );
    add_default( Key.plus,         true, false, false, KeyCommand.ZOOM_IN );
    add_default( Key.equal,        true, false, false, KeyCommand.ZOOM_IN );
    add_default( Key.minus,        true, false, false, KeyCommand.ZOOM_OUT );
    add_default( Key.p,            true, false, false, KeyCommand.FILE_PRINT );
    add_default( Key.comma,        true, false, false, KeyCommand.SHOW_PREFERENCES );
    add_default( Key.question,     true, false, false, KeyCommand.SHOW_SHORTCUTS );
    add_default( Key.@5,           true, false, false, KeyCommand.SHOW_CURRENT_SIDEBAR );
    add_default( Key.@6,           true, false, false, KeyCommand.SHOW_STYLE_SIDEBAR );
    add_default( Key.@7,           true, false, false, KeyCommand.SHOW_TAG_SIDEBAR );
    add_default( Key.@8,           true, false, false, KeyCommand.SHOW_STICKER_SIDEBAR );
    add_default( Key.@9,           true, false, false, KeyCommand.SHOW_MAP_SIDEBAR );
    add_default( Key.Tab,          true, false, false, KeyCommand.TAB_GOTO_NEXT );
    add_default( Key.Tab,          true, true,  false, KeyCommand.TAB_GOTO_PREV );
    add_default( Key.b,            true, true,  false, KeyCommand.TOGGLE_BRAINDUMP );
    add_default( Key.f,            true, true,  false, KeyCommand.TOGGLE_FOCUS_MODE );
    add_default( Key.f,            true, false, false, KeyCommand.SHOW_FIND );
    add_default( Key.w,            true, false, false, KeyCommand.TAB_CLOSE_CURRENT );

    add_default( Key.c,            true, false, false, KeyCommand.EDIT_COPY );
    add_default( Key.x,            true, false, false, KeyCommand.EDIT_CUT );
    add_default( Key.v,            true, false, false, KeyCommand.EDIT_PASTE );
    add_default( Key.v,            true, true,  false, KeyCommand.NODE_PASTE_REPLACE );
    add_default( Key.Return,       true, false, false, KeyCommand.EDIT_INSERT_NEWLINE );
    add_default( Key.BackSpace,    true, false, false, KeyCommand.EDIT_REMOVE_WORD_PREV );
    add_default( Key.Delete,       true, false, false, KeyCommand.EDIT_REMOVE_WORD_NEXT );
    add_default( Key.Tab,          true, false, false, KeyCommand.EDIT_INSERT_TAB );
    add_default( Key.Right,        true, true,  false, KeyCommand.EDIT_SELECT_WORD_NEXT );
    add_default( Key.Right,        true, false, false, KeyCommand.EDIT_CURSOR_WORD_NEXT );
    add_default( Key.Left,         true, true,  false, KeyCommand.EDIT_SELECT_WORD_PREV );
    add_default( Key.Left,         true, false, false, KeyCommand.EDIT_CURSOR_WORD_PREV );
    add_default( Key.Up,           true, true,  false, KeyCommand.EDIT_SELECT_START_UP );
    add_default( Key.Up,           true, false, false, KeyCommand.EDIT_CURSOR_FIRST );
    add_default( Key.Down,         true, true,  false, KeyCommand.EDIT_SELECT_END_DOWN );
    add_default( Key.Down,         true, false, false, KeyCommand.EDIT_CURSOR_LAST );
    add_default( Key.Home,         true, true,  false, KeyCommand.EDIT_SELECT_START_HOME );
    add_default( Key.Home,         true, false, false, KeyCommand.EDIT_CURSOR_LINESTART );
    add_default( Key.End,          true, true,  false, KeyCommand.EDIT_SELECT_END_END );
    add_default( Key.End,          true, false, false, KeyCommand.EDIT_CURSOR_LINEEND );
    add_default( Key.a,            true, false, false, KeyCommand.EDIT_SELECT_ALL );
    add_default( Key.a,            true, true,  false, KeyCommand.EDIT_SELECT_NONE );
    add_default( Key.period,       true, false, false, KeyCommand.EDIT_INSERT_EMOJI );
    add_default( Key.e,            true, true,  false, KeyCommand.NODE_QUICK_ENTRY_INSERT );
    add_default( Key.k,            true, false, false, KeyCommand.EDIT_ADD_URL );
    add_default( Key.k,            true, true,  false, KeyCommand.EDIT_REMOVE_URL );
    add_default( Key.r,            true, true,  false, KeyCommand.NODE_QUICK_ENTRY_REPLACE );
    add_default( Key.y,            true, false, false, KeyCommand.NODE_PASTE_NODE_LINK );

    add_default( Key.F10,          false, true,  false, KeyCommand.SHOW_CONTEXTUAL_MENU );
    add_default( Key.Menu,         false, false, false, KeyCommand.SHOW_CONTEXTUAL_MENU );

    add_default( Key.minus,        false, false, false, KeyCommand.NODE_ALIGN_TOP );
    add_default( Key.equal,        false, false, false, KeyCommand.NODE_ALIGN_VCENTER );
    add_default( Key.bracketleft,  false, false, false, KeyCommand.NODE_ALIGN_LEFT );
    add_default( Key.bracketright, false, false, false, KeyCommand.NODE_ALIGN_RIGHT );
    add_default( Key.underscore,   false, true,  false, KeyCommand.NODE_ALIGN_BOTTOM );
    add_default( Key.a,            false, false, false, KeyCommand.NODE_SELECT_PARENT );
    add_default( Key.d,            false, false, false, KeyCommand.NODE_SELECT_CHILDREN );
    add_default( Key.f,            false, false, false, KeyCommand.NODE_TOGGLE_FOLDS_SHALLOW );
    add_default( Key.f,            false, true,  false, KeyCommand.NODE_TOGGLE_FOLDS_DEEP );
    add_default( Key.g,            false, false, false, KeyCommand.NODE_ADD_GROUP );
    add_default( Key.l,            false, true,  false, KeyCommand.NODE_CHANGE_LINK_COLOR );
    add_default( Key.m,            false, false, false, KeyCommand.NODE_SELECT_ROOT );
    add_default( Key.t,            false, false, false, KeyCommand.NODE_CHANGE_TASK );
    add_default( Key.bar,          false, true,  false, KeyCommand.NODE_ALIGN_HCENTER );
    add_default( Key.numbersign,   false, true,  false, KeyCommand.NODE_TOGGLE_SEQUENCE );
    add_default( Key.x,            false, false, false, KeyCommand.NODE_ADD_CONNECTION );
    add_default( Key.y,            false, false, false, KeyCommand.NODE_TOGGLE_LINKS );
    add_default( Key.e,            false, true,  false, KeyCommand.EDIT_NOTE );
    add_default( Key.i,            false, false, false, KeyCommand.SHOW_CURRENT_SIDEBAR );
    add_default( Key.e,            false, false, false, KeyCommand.EDIT_SELECTED );
    add_default( Key.s,            false, false, false, KeyCommand.SHOW_SELECTED );

    add_default( Key.o,            false, true,  false, KeyCommand.CALLOUT_SELECT_NODE );

    add_default( Key.f,            false, false, false, KeyCommand.CONNECTION_SELECT_FROM );
    add_default( Key.n,            false, false, false, KeyCommand.CONNECTION_SELECT_NEXT );
    add_default( Key.p,            false, false, false, KeyCommand.CONNECTION_SELECT_PREV );
    add_default( Key.t,            false, false, false, KeyCommand.CONNECTION_SELECT_TO );

    add_default( Key.c,            false, true,  false, KeyCommand.NODE_CENTER );
    add_default( Key.d,            false, true,  false, KeyCommand.NODE_SELECT_TREE );
    add_default( Key.i,            false, true,  false, KeyCommand.NODE_CHANGE_IMAGE );
    add_default( Key.o,            false, true,  false, KeyCommand.NODE_SELECT_CALLOUT );
    add_default( Key.s,            false, true,  false, KeyCommand.NODE_SORT_ALPHABETICALLY );
    add_default( Key.x,            false, true,  false, KeyCommand.NODE_SELECT_CONNECTION );
    add_default( Key.y,            false, true,  false, KeyCommand.NODE_SELECT_LINKED );
    add_default( Key.c,            false, false, false, KeyCommand.NODE_SELECT_CHILD );
    add_default( Key.h,            false, false, false, KeyCommand.NODE_SELECT_LEFT );
    add_default( Key.j,            false, false, false, KeyCommand.NODE_SELECT_DOWN );
    add_default( Key.k,            false, false, false, KeyCommand.NODE_SELECT_UP );
    add_default( Key.l,            false, false, false, KeyCommand.NODE_SELECT_RIGHT );
    add_default( Key.n,            false, false, false, KeyCommand.NODE_SELECT_SIBLING_NEXT );
    add_default( Key.o,            false, false, false, KeyCommand.NODE_TOGGLE_CALLOUT );
    add_default( Key.p,            false, false, false, KeyCommand.NODE_SELECT_SIBLING_PREV );
    add_default( Key.x,            false, false, false, KeyCommand.NODE_ADD_CONNECTION );
    add_default( Key.Left,         false, false, true,  KeyCommand.NODE_SWAP_LEFT );
    add_default( Key.Right,        false, false, true,  KeyCommand.NODE_SWAP_RIGHT );
    add_default( Key.Up,           false, false, true,  KeyCommand.NODE_SWAP_UP );
    add_default( Key.Down,         false, false, true,  KeyCommand.NODE_SWAP_DOWN );

  }

  private Xml.Node* make_property( string name, string value, string? translatable = null ) {
    Xml.Node* node = new Xml.Node( null, "property" );
    node->set_prop( "name", name );
    if( translatable != null ) {
      node->set_prop( "translatable", translatable );
    }
    node->set_content( value );
    return( node );
  }

  private Xml.Node* make_object( string klass, string? id = null ) {
    Xml.Node* node = new Xml.Node( null, "object" );
    node->set_prop( "class", klass );
    if( id != null ) {
      node->set_prop( "id", id );
    }
    return( node );
  }

  private Xml.Node* make_child() {
    Xml.Node* node = new Xml.Node( null, "child" );
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a section for the shortcuts UI output.
  private Xml.Node* make_base_section( string name, string title, out Xml.Node* obj ) {
    Xml.Node* node = make_child();
    obj = make_object( "GtkShortcutsSection" );
    obj->add_child( make_property( "section-name", name ) );
    obj->add_child( make_property( "title", title, "yes" ) );
    obj->add_child( make_property( "visible", "1" ) );
    node->add_child( obj );
    return( node );
  }

  private Xml.Node* make_section( KeyCommand command, out Xml.Node* obj ) {
    return( make_base_section( command.to_string(), command.shortcut_label(), out obj ) );
  }

  //-------------------------------------------------------------
  // Creates a group for the shortcuts UI output.
  private Xml.Node* make_base_group( string title, out Xml.Node* obj ) {
    Xml.Node* node = make_child();
    obj = make_object( "GtkShortcutsGroup" );
    obj->add_child( make_property( "title", title, "yes" ) );
    obj->add_child( make_property( "visible", "1" ) );
    node->add_child( obj );
    return( node );
  }

  private Xml.Node* make_group( KeyCommand command, out Xml.Node* obj ) {
    return( make_base_group( command.shortcut_label(), out obj ) );
  }

  //-------------------------------------------------------------
  // Creates a shortcut for the shortcuts UI output.
  private Xml.Node* make_shortcut( Shortcut shortcut ) {
    Xml.Node* node = make_child();
    Xml.Node* obj  = make_object( "GtkShortcutsShortcut" );
    obj->add_child( make_property( "title", shortcut.command.shortcut_label(), "yes" ) );
    obj->add_child( make_property( "accelerator", shortcut.get_accelerator() ) );
    obj->add_child( make_property( "visible", "1" ) );
    node->add_child( obj );
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a shortcut for a mouse event.
  private Xml.Node* make_mouse_shortcut( string title, string subtitle ) {
    Xml.Node* node = make_child();
    Xml.Node* obj  = make_object( "GtkShortcutsShortcut" );
    obj->add_child( make_property( "title", title, "yes" ) );
    obj->add_child( make_property( "subtitle", subtitle, "yes" ) );
    obj->add_child( make_property( "visible", "1" ) );
    node->add_child( obj );
    return( node );
  }

  //-------------------------------------------------------------
  // Generates the shortcuts UI string.
  public string get_ui_string() {

    Xml.Doc*  doc   = new Xml.Doc( "1.0" );
    Xml.Node* root  = new Xml.Node( null, "interface" );

    doc->set_root_element( root );

    root->set_prop( "domain", "com.github.phase1geo.minder" );

    var window = make_object( "GtkShortcutsWindow", "shortcuts" );
    root->add_child( window );

    window->add_child( make_property( "modal", "0" ) );
    window->add_child( make_property( "resizable", "0" ) );
    window->add_child( make_property( "title", "Minder Shortcuts", "yes" ) );
    window->add_child( make_property( "section-name", "global" ) );
    window->add_child( make_property( "view-name", "file" ) );

    Xml.Node* section  = null;
    Xml.Node* group    = null;
    var       commands = 0;

    for( int i=0; i<KeyCommand.NUM; i++ ) {
      var command = (KeyCommand)i;
      if( command.viewable() ) {
        if( command.is_section_start() ) {
          if( (group != null) && (commands == 0) ) {
            group->add_child( make_mouse_shortcut( _( "No Commands Listed" ), "" ) );
          }
          window->add_child( make_section( command, out section ) );
          group = null;
        } else if( command.is_group_start() ) {
          if( (group != null) && (commands == 0) ) {
            group->add_child( make_mouse_shortcut( _( "No Commands Listed" ), "" ) );
          }
          commands = 0;
          section->add_child( make_group( command, out group ) );
        } else if( !command.is_section_start() && !command.is_section_end() ) {
          var shortcut = get_shortcut( command );
          if( shortcut != null ) {
            group->add_child( make_shortcut( shortcut ) );
            commands++;
          }
        }
      }
    }

    // We will need to manually add the mouse events
    window->add_child( make_base_section( "mouse", _( "Mouse Events" ), out section ) );

    section->add_child( make_base_group( _( "General" ), out group ) );
    group->add_child( make_mouse_shortcut( _( "Show Contextual Menu" ), _( "[Right-click when item is selected]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Edit Image" ), _( "[Double left-click image]" ) ) );

    section->add_child( make_base_group( _( "Canvas Movement" ), out group ) );
    group->add_child( make_mouse_shortcut( _( "Pan Canvas" ), _( "[Middle-click + Drag / Alt + Motion]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Scroll Vertically" ), _( "[Scrollwheel up/down]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Scroll Horizontally" ), _( "[Scrollwhile left/right]" ) ) );

    section->add_child( make_base_group( _( "Item Selection" ), out group ) );
    group->add_child( make_mouse_shortcut( _( "Select Single Item" ), _( "[Left-click on item]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Select Child Nodes" ), _( "[Control + Left-click on parent node]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Select Node Tree/Subtree" ), _( "[Control + Double left-click on parent node" ) ) );
    group->add_child( make_mouse_shortcut( _( "Select All Nodes at Same Depth Level" ), _( "[Control + Triple left-click on node]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Block Selection" ), _( "[Left-click + Drag]" ) ) );

    section->add_child( make_base_group( _( "Item Selection Toggle" ), out group ) );
    group->add_child( make_mouse_shortcut( _( "Toggle Selection of Item" ), _( "[Shift + Left-click on item]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Toggle Selection of Child Nodes" ), _( "[Shift + Control + Left-click on item]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Toggle Selection of Node Tree/Subtree" ), _( "[Shift + Control + Double left-click on parent node]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Toggle Selection of All Nodes at Same Depth Level" ), _( "Shift + Control + Triple-click on node]" ) ) );

    section->add_child( make_base_group( _( "Text Selection" ), out group ) );
    group->add_child( make_mouse_shortcut( _( "Set Cursor Insert Point" ), _( "[Left-click in text]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Select Current Word" ), _( "[Double left-click on word]" ) ) );
    group->add_child( make_mouse_shortcut( _( "Select all text" ), _( "[Triple left-click text]" ) ) );

    var dump_str = "";
    doc->dump_memory_format( out dump_str );
    delete doc;

    return( dump_str );

  }

}
