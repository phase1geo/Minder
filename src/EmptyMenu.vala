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

using Gtk;

public class EmptyMenu {

  private DrawArea    _da;
  private PopoverMenu _popover;

  private const GLib.ActionEntry action_entries[] = {
    { "action_paste",            action_paste },
    { "action_add_root_node",    action_add_root_node },
    { "action_add_quick_entry",  action_add_quick_entry },
    { "action_select_root_node", action_select_root_node },
  };

  /* Default constructor */
  public EmptyMenu( Gtk.Application app, DrawArea da ) {

    _da = da;

    var edit_menu = new GLib.Menu();
    edit_menu.append( _( "Paste" ), "empty.action_paste" );

    var add_menu = new GLib.Menu();
    add_menu.append( _( "Add Root Node" ),              "empty.action_add_root_node" );
    add_menu.append( _( "Add Nodes With Quick Entry" ), "empty.action_add_quick_entry" );

    var sel_menu = new GLib.Menu();
    sel_menu.append( _( "Select First Root Node" ), "empty.action_select_root_node" );

    var menu = new GLib.Menu();
    menu.append_section( null, edit_menu );
    menu.append_section( null, add_menu );
    menu.append_section( null, sel_menu );

    // Add the menu actions
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    _da.insert_action_group( "paste", actions );

    // Add keyboard shortcuts
    app.set_accels_for_action( "empty.action_paste",            { "<Control>y" } );
    app.set_accels_for_action( "empty.action_add_root_node",    { "Return" } );
    app.set_accels_for_action( "empty.action_add_quick_entry",  { "<Control<Shift>e" } );
    app.set_accels_for_action( "empty.action_select_root_node", { "m" } );

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  public void show( double x, double y ) {

    // Handle action state
    on_popup();

    // Display the popover at the given location
    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    _popover.pointing_to = rect;
    _popover.popup();

  }

  /* Returns true if there is a currently selected connection */
  private bool connection_selected() {
    return( _da.get_current_connection() != null );
  }

  /* Called when the menu is popped up */
  private void on_popup() {

    _da.set_action_enabled( "empty.action_paste",            _da.node_pasteable() );
    _da.set_action_enabled( "empty.action_add_root_node",    !connection_selected() );
    _da.set_action_enabled( "empty.action_select_root_node", _da.root_selectable() );

  }

  /* Pastes node tree as root from clipboard */
  private void action_paste() {
    _da.do_paste( false );
  }

  /* Creates a new root node */
  private void action_add_root_node() {
    _da.add_root_node();
  }

  /* Adds top-level nodes via the quick entry facility */
  private void action_add_quick_entry() {
    _da.handle_control_E();
  }

  /* Selects the current root node */
  private void action_select_root_node() {
    _da.select_root_node();
  }

}
