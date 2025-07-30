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

public class BaseMenu {

  private Gtk.Application _app;
  private MindMap         _map;
  private string          _group_name;
  private const GLib.ActionEntry _action_entries[] = {
    { "action_run_command", action_run_command, "i" }
  };

  public MindMap map {
    get {
      return( _map );
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public BaseMenu( Gtk.Application app, DrawArea canvas, string group ) {

    _map        = canvas.map;
    _app        = app;
    _group_name = group;

    map.win.shortcuts.shortcut_changed.connect( handle_shortcut_change );

    // Create and add the action group to the mindmap canvas
    var actions = new SimpleActionGroup();
    actions.add_action_entries( _action_entries, this );
    canvas.insert_action_group( _group_name, actions );

  }

  //-------------------------------------------------------------
  // Returns the detailed action name for the given command.
  private string detailed_name( KeyCommand command ) {
    return( "%s.action_run_command(%d)".printf( _group_name, (int)command ) );
  }

  //-------------------------------------------------------------
  // Appends a command with the given command to the specified menu.
  protected void append_menu_item( GLib.Menu menu, KeyCommand command, string label ) {

    menu.append( label, detailed_name( command ) );

    var shortcut = _map.win.shortcuts.get_shortcut( command );
    if( shortcut != null ) {
      _app.set_accels_for_action( detailed_name( command ), { shortcut.get_accelerator() } );
    }

  }

  //-------------------------------------------------------------
  // Sets the action enable for the given command to the given value.
  protected void set_enabled( KeyCommand command, bool enable ) {
    map.canvas.action_set_enabled( detailed_name( command ), enable );
  }

  //-------------------------------------------------------------
  // Handles any changes to the shortcuts manager and updates the
  // affected accelerator.
  private void handle_shortcut_change( KeyCommand command, Shortcut? shortcut ) {
    if( shortcut == null ) {
      shortcut_removed( command );
    } else {
      shortcut_added( shortcut );
    }
  }

  //-------------------------------------------------------------
  // Removes the accelerator for the given shortcut command.
  private void shortcut_removed( KeyCommand command ) {
    _app.set_accels_for_action( detailed_name( command ), {} );
  }

  //-------------------------------------------------------------
  // Adds the accelerator for the given shortcut.
  private void shortcut_added( Shortcut shortcut ) {
    _app.set_accels_for_action( detailed_name( shortcut.command ), { shortcut.get_accelerator() } );

  }

  //-------------------------------------------------------------
  // Runs the keycommand function associated with the given variant.
  private void action_run_command( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var command = (KeyCommand)variant.get_int32();
      var func    = command.get_func();
      func( _map );
    }
  }

}
