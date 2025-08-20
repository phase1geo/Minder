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

  private Gtk.Application   _app;
  private MindMap           _map;
  private string            _group_name;
  private SimpleActionGroup _group;
  private Gtk.PopoverMenu   _popover;
  private GLib.Menu         _menu;

  public MindMap map {
    get {
      return( _map );
    }
  }
  protected GLib.Menu menu {
    get {
      return( _menu );
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public BaseMenu( Gtk.Application app, DrawArea canvas, string group ) {

    _map        = canvas.map;
    _app        = app;
    _group_name = group;

    // Handle any updates to shortcuts in the menu
    map.win.shortcuts.shortcut_changed.connect( handle_shortcut_change );

    // Create and add the action group to the mindmap canvas
    _group = new SimpleActionGroup();
    canvas.insert_action_group( _group_name, _group );

    // Create the main menu
    _menu = new GLib.Menu();

    // Create the popover for the menu
    _popover = new Gtk.PopoverMenu.from_model( _menu );
    _popover.set_parent( canvas );
    _popover.closed.connect( on_popdown );

  }

  //-------------------------------------------------------------
  // Called when the menu is just about to be shown.  Use this
  // to set the enabled values of menu items.
  protected virtual void on_popup() {}

  //-------------------------------------------------------------
  // Called when the menu is being hidden.
  protected virtual void on_popdown() {}

  //-------------------------------------------------------------
  // Shows the menu at the given location.
  public void show( double x, double y ) {

    // Set the menu state
    on_popup();

    // Display the popover at the given location
    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    _popover.pointing_to = rect;
    _popover.popup();

  }

  //-------------------------------------------------------------
  // Hides the menu.
  public void hide() {
    _popover.popdown();
  }

  //-------------------------------------------------------------
  // Returns the detailed action name for the given command.
  private string detailed_name( KeyCommand command ) {
    return( "%s.%s".printf( _group_name, command.to_string() ) );
  }

  //-------------------------------------------------------------
  // Appends a command with the given command to the specified menu.
  protected void append_menu_item( GLib.Menu menu, KeyCommand command, string label ) {

    menu.append( label, detailed_name( command ) );
 
    // Create action to execute
    var action = new SimpleAction( command.to_string(), null );
    action.activate.connect((v) => {
      var func = command.get_func();
      func( map );
      map.canvas.grab_focus();
    });
    _group.add_action( action );

    var shortcut = _map.win.shortcuts.get_shortcut( command );
    if( shortcut != null ) {
      _app.set_accels_for_action( detailed_name( command ), { shortcut.get_accelerator() } );
    }

  }

  //-------------------------------------------------------------
  // Changes the menu label to the given string for the given command.
  protected void change_menu_item_label( GLib.Menu menu, KeyCommand command, string label ) {
    var detailed_action = detailed_name( command );
    for( int i=0; i<menu.get_n_items(); i++ ) {
      var variant = menu.get_item_attribute_value( i, GLib.Menu.ATTRIBUTE_ACTION, null );
      if( (variant != null) && (variant.get_string() == detailed_action) ) {
        menu.remove( i );
        menu.insert( i, label, detailed_name( command ) );
        return;
      }
    }
  }

  //-------------------------------------------------------------
  // Sets the action enable for the given command to the given value.
  protected void set_enabled( KeyCommand command, bool enable ) {
    var action = _group.lookup_action( command.to_string() );
    if( action != null ) {
      (action as SimpleAction).set_enabled( enable );
    }
  }

  //-------------------------------------------------------------
  // Handles any changes to the shortcuts manager and updates the
  // affected accelerator.
  private void handle_shortcut_change( KeyCommand command, Shortcut? shortcut ) {
    var action = _group.lookup_action( command.to_string() );
    if( action != null ) {
      if( shortcut == null ) {
        shortcut_removed( command );
      } else {
        shortcut_added( shortcut );
      }
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

}
