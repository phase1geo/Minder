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

public class ConnectionMenu {

  private DrawArea     _da;
  private PopoverMenu  _popover;

  private const GLib.ActionEntry action_entries[] = {
    { "action_delete",                 action_delete },
    { "action_edit_title",             action_edit_title },
    { "action_edit_note",              action_edit_note },
    { "action_remove_sticker",         action_remove_sticker },
    { "action_select_start_node",      action_select_start_node },
    { "action_select_end_node",        action_select_end_node },
    { "action_select_next_connection", action_select_next_connection },
    { "action_select_prev_connection", action_select_prev_connection },
  };

  /* Default constructor */
  public ConnectionMenu( Gtk.Application app, DrawArea da ) {

    _da = da;

    // Create the menu
    var del_menu = new GLib.Menu();
    del_menu.append( _( "Delete" ), "conn.action_delete" );

    var edit_menu = new GLib.Menu();
    edit_menu.append( _( "Edit Title…" ),    "conn.action_edit_title" );
    edit_menu.append( _( "Edit Note" ),      "conn.action_edit_note" );
    edit_menu.append( _( "Remove Sticker" ), "conn.action_remove_sticker" );

    var sel_node_menu = new GLib.Menu();
    sel_node_menu.append( _( "Start Node" ), "conn.action_select_start_node" );
    sel_node_menu.append( _( "End Node" ),   "conn.action_select_end_node" );

    var sel_conn_menu = new GLib.Menu();
    sel_conn_menu.append( _( "Next Connection"),     "conn.action_select_next_connection" );
    sel_conn_menu.append( _( "Previous Connection"), "conn.action_select_prev_connection" );

    var sel_submenu = new GLib.Menu();
    sel_submenu.append_section( null, sel_node_menu );
    sel_submenu.append_section( null, sel_conn_menu );

    var sel_menu = new GLib.Menu();
    sel_menu.append_submenu( _( "Select" ), sel_submenu );

    var menu = new GLib.Menu();
    menu.append_section( null, del_menu );
    menu.append_section( null, edit_menu );
    menu.append_section( null, sel_menu );

    _popover = new PopoverMenu.from_model( menu );
    _popover.set_parent( _da );

    // Add the menu actions
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    _da.insert_action_group( "conn", actions );

    app.set_accels_for_action( "conn.action_delete",                 { "Delete" } );
    app.set_accels_for_action( "conn.action_edit_title",             { "e" } );
    app.set_accels_for_action( "conn.action_edit_note",              { "<Shift>e" } );
    app.set_accels_for_action( "conn.action_select_start_node",      { "f" } );
    app.set_accels_for_action( "conn.action_select_end_node",        { "t" } );
    app.set_accels_for_action( "conn.action_select_next_connection", { "Right" } );
    app.set_accels_for_action( "conn.action_select_prev_connection", { "Left" } );

  }

  /* Called when the menu is popped up */
  public void show( double x, double y ) {

    _da.action_set_enabled( "conn.action_edit_sticker", (_da.get_current_connection().sticker != null) );

    // Display the popover at the given location
    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    _popover.pointing_to = rect;
    _popover.popup();

  }

  /* Deletes the current node */
  private void action_delete() {
    _da.delete_connection();
  }

  /* Displays the sidebar to edit the node properties */
  private void action_edit_title() {
    Connection conn = _da.get_current_connection();
    if( conn.title == null ) {
      conn.change_title( _da, "", true );
    }
    _da.set_connection_mode( conn, ConnMode.EDITABLE );
  }

  /* Changes the note status of the currently selected node */
  private void action_edit_note() {
    _da.show_properties( "current", PropertyGrab.NOTE );
  }

  /* Removes the sticker attached to the connection */
  private void action_remove_sticker() {
    var current = _da.get_current_connection();
    _da.undo_buffer.add_item( new UndoConnectionStickerRemove( current ) );
    current.sticker = null;
    _da.queue_draw();
    _da.auto_save();
  }

  /* Selects the next sibling node of the current node */
  private void action_select_start_node() {
    _da.select_connection_node( true );
  }

  /* Selects the previous sibling node of the current node */
  private void action_select_end_node() {
    _da.select_connection_node( false );
  }

  /* Selects the next connection in the mind map */
  private void action_select_next_connection() {
    _da.select_connection( 1 );
  }

  /* Selects the previous connection in the mind map */
  private void action_select_prev_connection() {
    _da.select_connection( -1 );
  }

}
