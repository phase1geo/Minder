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

public class GroupsMenu {

  private DrawArea    _da;
  private PopoverMenu _popover;

  private const GLib.ActionEntry action_entries[] = {
    { "action_delete_groups", action_delete_groups },
    { "action_edit_node",     action_edit_node },
    { "action_change_color",  action_change_color },
    { "action_merge_groups",  action_merge_groups },
    { "action_select_main",   action_select_main },
    { "action_select_all",    action_select_all },
  };

  /* Default constructor */
  public GroupsMenu( Gtk.Application app, DrawArea da ) {

    _da = da;

    add( select );

    var del_menu = new GLib.Menu();
    del_menu.append( _( "Delete" ), "groups.action_delete_groups" );

    var change_menu = new GLib.Menu();
    change_menu.append( _( "Edit Note" ),     "groups.action_edit_node" );
    change_menu.append( _( "Change color…" ), "groups.action_change_color" ); 
    change_menu.append( _( "Merge" ),         "groups.action_merge_groups" );

    var sel_submenu = new GLib.Menu();
    sel_submenu.append( _( "Top Nodes" ),         "groups.action_select_main" );
    sel_submenu.append( _( "All Grouped Nodes" ), "groups.action_select_all" );

    var sel_menu = new GLib.Menu();
    sel_menu.append_submenu( _( "Select" ), sel_submenu );

    var menu = new GLib.Menu();
    menu.append_section( null, del_menu );
    menu.append_section( null, change_menu );
    menu.append_section( null, sel_menu );

    _popover = new PopoverMenu.with_model( menu );

    // Add the menu actions
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    _da.insert_action_group( "groups", actions );

    // Add keyboard shortcuts
    app.set_accels_for_action( "groups.action_delete_groups", { "Delete" } );
    app.set_accels_for_action( "groups.action_edit_note",     { "<Shift>e" } );

  }

  //-------------------------------------------------------------
  // Displays this menu.
  public void show( double x, double y ) {

    // Update menu state
    on_popup();

    /* Display the popover at the given location */
    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    _popover.pointing_to = rect;
    _popover.popup();

  }

  /* Called when the menu is popped up */
  private void on_popup() {

    var groups = _da.get_selected_groups();
    var num    = groups.length;

    /* Set the menu sensitivity */
    _da.set_action_enabled( "groups.action_merge_groups", (num > 1) );

  }

  /* Deletes the current group */
  private void action_delete_groups() {
    _da.remove_groups();
  }

  /* Merges two or more groups into a single group */
  private void action_merge_groups() {
    _da.add_group();
  }

  /* Edits the group note */
  private void action_edit_note() {
    _da.show_properties( "current", PropertyGrab.NOTE );
  }

  /* Allows the user to change the color of the selected groups */
  private void action_change_color() {
    var color_picker = new ColorChooserDialog( _( "Select a link color" ), _da.win );
    if( color_picker.run() == ResponseType.OK ) {
      _da.change_group_color( color_picker.get_rgba() );
    }
    color_picker.close();
  }

  /* Selects the top-most nodes in each selected node group */
  private void action_select_main() {
    var groups   = _da.get_selected_groups();
    var selected = _da.get_selections();
    for( int i=0; i<groups.length; i++ ) {
      var nodes = groups.index( i ).nodes;
      for( int j=0; j<nodes.length; j++ ) {
        selected.add_node( nodes.index( j ), false );
      }
    }
    selected.clear_groups();
  }

  /* Selects all of the nodes within the group */
  private void action_select_all() {
    var groups   = _da.get_selected_groups();
    var selected = _da.get_selections();
    for( int i=0; i<groups.length; i++ ) {
      var nodes = groups.index( i ).nodes;
      for( int j=0; j<nodes.length; j++ ) {
        selected.add_node_tree( nodes.index( j ), false );
      }
    }
    selected.clear_groups();
  }

}
