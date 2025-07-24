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
    } else if( map.is_node_editable() || map.is_connection_editable() || map.is_callout_editable() ) {
      return( EDITING );
    } else {
      return( NONE );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the given state matches that required for the
  // given command.
  public static bool matches( MapState state, string command ) {
    var any = command.has_prefix( "any-" );
    if( (state == MapState.NODE) && (command.has_prefix( "node-" ) || any) ) {
      return( true );
    } else if( (state == MapState.CONNECTION) && (command.has_prefix( "connection-" ) || any) ) {
      return( true );
    } else if( (state == MapState.CALLOUT) && (command.has_prefix( "callout-" ) || any) ) {
      return( true );
    } else if( (state == MapState.EDITING) && command.has_prefix( "edit-" ) ) {
      return( true );
    } else if( state == MapState.NONE ) {
      return( true );
    } else {
      return( false );
    }
  }

}

public class Shortcuts {

  private class Shortcut {

    public uint   keycode { get; private set; default = Key.a; }
    public bool   control { get; private set; default = false; }
    public bool   shift   { get; private set; default = false; }
    public bool   alt     { get; private set; default = false; }
    public string command { get; private set; default = "none"; }

    //-------------------------------------------------------------
    // Default constructor.
    public Shortcut( uint keycode, bool control, bool shift, bool alt, string command ) {
      this.keycode = keycode;
      this.control = control;
      this.shift   = shift;
      this.alt     = alt;
      this.command = command;
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
        if( kv == this.keycode ) return( true );
      }
      return( false );
    }

    //-------------------------------------------------------------
    // Returns true if this shortcut matches the given values exactly.
    // TODO - The command should only compare the prefixes.
    public bool equals( uint keycode, bool control, bool shift, bool alt, string command ) {
      return( (keycode == this.keycode) &&
              (control == this.control) &&
              (shift   == this.shift)   &&
              (alt     == this.alt)     &&
              (command == this.command) );
    }

    //-------------------------------------------------------------
    // Returns true if this shortcut matches the given match values
    public bool matches( uint[] kvs, ModifierType mods, MapState state ) {
      return( (this.control == (bool)(mods & ModifierType.CONTROL_MASK)) &&
              (this.shift   == (bool)(mods & ModifierType.SHIFT_MASK))   &&
              (this.alt     == (bool)(mods & ModifierType.ALT_MASK))     &&
              has_key( kvs ) &&
              MapState.matches( state, this.command ) );
    }

    //-------------------------------------------------------------
    // Saves the contents of this shortcut to an XML node and returns
    // it.
    public Xml.Node* save() {
      Xml.Node* node = new Xml.Node( null, "shortcut" );
      node->set_prop( "key",     keycode.to_string() );
      node->set_prop( "control", control.to_string() );
      node->set_prop( "shift",   shift.to_string() );
      node->set_prop( "alt",     alt.to_string() );
      node->set_prop( "command", command );
      return( node );
    }

    //-------------------------------------------------------------
    // Loads this shortcut from an XML node.
    private void load( Xml.Node* node ) {
      var k = node->get_prop( "key" );
      if( k != null ) {
        keycode = uint.parse( k );
      }
      var c = node->get_prop( "control" );
      if( c != null ) {
        control = bool.parse( c );
      }
      var s = node->get_prop( "shift" );
      if( s != null ) {
        shift = bool.parse( s );
      }
      var a = node->get_prop( "alt" );
      if( a != null ) {
        alt = bool.parse( a );
      }
      var cmd = node->get_prop( "command" );
      if( cmd != null ) {
        command = cmd;
      }
    }

  }

  private Array<Shortcut> _shortcuts;
  private KeyCommands     _commands;

  //-------------------------------------------------------------
  // Default constructor
  public Shortcuts() {

    _shortcuts = new Array<Shortcut>();
    _commands  = new KeyCommands();

    load();

  }

  //-------------------------------------------------------------
  // Clears the shortcut for the given command, if it exists.
  // Called by the shortcut preferences class.
  public void clear_shortcut( string command ) {
    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).command == command ) {
        _shortcuts.remove_index( i );
        return;
      }
    }
  }

  //-------------------------------------------------------------
  // Sets the shortcut for the given command.  Called by the
  // shortcut preferences class.
  public void set_shortcut( string command, uint keycode, bool control, bool shift, bool alt ) {
    clear_shortcut( command );  // TODO - This is probably not going to be necessary
    add_shortcut( keycode, control, shift, alt, command );
  }

  //-------------------------------------------------------------
  // Checks to see if the given shortcut is already mapped.
  public bool shortcut_exists( uint keycode, bool control, bool shift, bool alt, string command ) {
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
  public bool execute( MindMap map, uint keycode, ModifierType mods ) {

    KeymapKey[] ks    = {};
    uint[]      kvs   = {};
    var         state = MapState.get_state( map );

    Display.get_default().map_keycode( keycode, out ks, out kvs );

    for( int i=0; i<_shortcuts.length; i++ ) {
      if( _shortcuts.index( i ).matches( kvs, mods, state ) ) {
        _commands.execute( map, _shortcuts.index( i ).command );
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
  private void add_shortcut( uint keycode, bool control, bool shift, bool alt, string command ) {
    var shortcut = new Shortcut( keycode, control, shift, alt, command );
    _shortcuts.append_val( shortcut );
  }

  //-------------------------------------------------------------
  // If the shortcuts file is missing, we will create the default
  // set of shortcuts and save them to the save file.
  private void create_default_shortcuts() {

    // TODO - Cleanup command names

    add_shortcut( Key.c,         true, false, false, "copy" );
    add_shortcut( Key.x,         true, false, false, "cut" );
    add_shortcut( Key.v,         true, false, false, "paste-insert" );
    add_shortcut( Key.v,         true, true,  false, "paste-replace" );
    add_shortcut( Key.Return,    true, false, false, "insert-newline" );
    add_shortcut( Key.BackSpace, true, false, false, "backspace-word" );
    add_shortcut( Key.Delete,    true, false, false, "delete-word" );
    add_shortcut( Key.Tab,       true, false, false, "insert-tab" );
    add_shortcut( Key.Right,     true, true,  false, "select-word-right" );
    add_shortcut( Key.Right,     true, false, false, "move-word-right" );
    add_shortcut( Key.Left,      true, true,  false, "select-word-left" );
    add_shortcut( Key.Left,      true, false, false, "move-word-left" );
    add_shortcut( Key.Up,        true, true,  false, "select-to-start" );
    add_shortcut( Key.Up,        true, false, false, "move-to-start" );
    add_shortcut( Key.Down,      true, true,  false, "select-to-end" );
    add_shortcut( Key.Down,      true, false, false, "move-to-end" );
    add_shortcut( Key.Home,      true, true,  false, "select-to-linestart" );
    add_shortcut( Key.Home,      true, false, false, "move-to-linestart" );
    add_shortcut( Key.End,       true, true,  false, "select-to-lineend" );
    add_shortcut( Key.End,       true, false, false, "move-to-lineend" );
    add_shortcut( Key.a,         true, false, false, "select-all" );
    add_shortcut( Key.a,         true, true,  false, "deselect-all" );
    add_shortcut( Key.period,    true, false, false, "insert-emoji" );
    add_shortcut( Key.e,         true, true,  false, "quick-entry-insert" );
    add_shortcut( Key.k,         true, false, false, "add-url" );
    add_shortcut( Key.k,         true, true,  false, "remove-url" );
    add_shortcut( Key.r,         true, true,  false, "quick-entry-replace" );
    add_shortcut( Key.w,         true, false, false, "close-map" );
    add_shortcut( Key.y,         true, false, false, "paste-node-link" );

    add_shortcut( Key.BackSpace, false, false, false, "backspace" );
    add_shortcut( Key.Delete,    false, false, false, "delete" );
    add_shortcut( Key.Escape,    false, false, false, "escape" );
    add_shortcut( Key.Return,    false, false, false, "return" );
    add_shortcut( Key.Return,    false, true,  false, "shift-return" );
    add_shortcut( Key.Tab,       false, false, false, "tab" );
    add_shortcut( Key.Tab,       false, true,  false, "shift-tab" );
    add_shortcut( Key.Right,     false, false, false, "right" );
    add_shortcut( Key.Right,     false, false, true,  "alt-right" );
    add_shortcut( Key.Right,     false, true,  false, "shift-right" );
    add_shortcut( Key.Right,     false, true,  true,  "shift-alt-right" );
    add_shortcut( Key.Left,      false, false, false, "left" );
    add_shortcut( Key.Left,      false, false, true,  "alt-left" );
    add_shortcut( Key.Left,      false, true,  false, "shift-left" );
    add_shortcut( Key.Left,      false, true,  true,  "shift-alt-left" );
    add_shortcut( Key.Up,        false, false, false, "up" );
    add_shortcut( Key.Up,        false, false, true,  "alt-up" );
    add_shortcut( Key.Up,        false, true,  false, "shift-up" );
    add_shortcut( Key.Up,        false, true,  true,  "shift-alt-up" );
    add_shortcut( Key.Down,      false, false, false, "down" );
    add_shortcut( Key.Down,      false, false, true,  "alt-down" );
    add_shortcut( Key.Down,      false, true,  false, "shift-down" );
    add_shortcut( Key.Down,      false, true,  true,  "shift-alt-down" );
    add_shortcut( Key.Page_Up,   false, false, false, "page-up" );
    add_shortcut( Key.Page_Down, false, false, false, "page-down" );
    add_shortcut( Key.Control_L, false, false, false, "control-pressed" );
    add_shortcut( Key.Control_R, false, false, false, "control-pressed" );
    add_shortcut( Key.F10,       false, true,  false, "show-contextual-menu" );
    add_shortcut( Key.Menu,      false, false, false, "show-contextual-menu" );

    add_shortcut( Key.minus,        false, false, false, "node-align-top" );
    add_shortcut( Key.equal,        false, false, false, "node-align-vcenter" );
    add_shortcut( Key.z,            false, true,  false, "zoom-in" );
    add_shortcut( Key.bracketleft,  false, false, false, "node-align-left" );
    add_shortcut( Key.bracketright, false, false, false, "node-align-right" );
    add_shortcut( Key.underscore,   false, true,  false, "node-align-bottom" );
    add_shortcut( Key.a,            false, false, false, "node-select-parent" );
    add_shortcut( Key.d,            false, false, false, "node-select-children" );
    add_shortcut( Key.f,            false, false, false, "node-toggle-folds-shallow" );
    add_shortcut( Key.f,            false, true,  false, "node-toggle-folds-deep" );
    add_shortcut( Key.g,            false, false, false, "node-add-group" );
    add_shortcut( Key.l,            false, true,  false, "node-change-link-color" );
    add_shortcut( Key.m,            false, false, false, "node-select-root" );
    add_shortcut( Key.r,            false, false, false, "redo-action" );
    add_shortcut( Key.t,            false, false, false, "node-change-task" );
    add_shortcut( Key.u,            false, false, false, "undo-action" );
    add_shortcut( Key.z,            false, false, false, "zoom-out" );
    add_shortcut( Key.bar,          false, true,  false, "node-align-hcenter" );
    add_shortcut( Key.numbersign,   false, true,  false, "node-toggle-sequence" );
    add_shortcut( Key.x,            false, false, false, "node-create-connection" );
    add_shortcut( Key.y,            false, false, false, "node-toggle-links" );
    add_shortcut( Key.e,            false, true,  false, "show-properties-note" );
    add_shortcut( Key.i,            false, false, false, "show-properties-first" );
    add_shortcut( Key.e,            false, false, false, "any-editable" );
    add_shortcut( Key.s,            false, false, false, "show-selected" );

    add_shortcut( Key.o,            false, true,  false, "callout-select-node" );

    add_shortcut( Key.f,            false, false, false, "connection-select-from-node" );
    add_shortcut( Key.n,            false, false, false, "connection-select-next" );
    add_shortcut( Key.p,            false, false, false, "connection-select-previous" );
    add_shortcut( Key.t,            false, false, false, "connection-select-to-node" );

    add_shortcut( Key.c,            false, true,  false, "node-center" );
    add_shortcut( Key.d,            false, true,  false, "node-select-tree" );
    add_shortcut( Key.i,            false, true,  false, "node-add-image" );
    add_shortcut( Key.o,            false, true,  false, "node-select-callout" );
    add_shortcut( Key.s,            false, true,  false, "node-sort-alphabetically" );
    add_shortcut( Key.x,            false, true,  false, "node-select-connection" );
    add_shortcut( Key.y,            false, true,  false, "node-select-linked-node" );
    add_shortcut( Key.c,            false, false, false, "node-select-child-node" );
    add_shortcut( Key.h,            false, false, false, "node-select-left" );
    add_shortcut( Key.j,            false, false, false, "node-select-down" );
    add_shortcut( Key.k,            false, false, false, "node-select-up" );
    add_shortcut( Key.l,            false, false, false, "node-select-right" );
    add_shortcut( Key.n,            false, false, false, "node-select-sibling-next" );
    add_shortcut( Key.o,            false, false, false, "node-add-callout" );
    add_shortcut( Key.p,            false, false, false, "node-select-sibling-previous" );
    add_shortcut( Key.x,            false, false, false, "node-start-connection" );

    // Save the shortcuts to the save file
    save();

  }

}
