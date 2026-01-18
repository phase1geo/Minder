/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

public class ConnectionMenu : BaseMenu {

  //-------------------------------------------------------------
  // Default constructor
  public ConnectionMenu( Gtk.Application app, DrawArea da ) {

    base( app, da, "conn" );

    // Create the menu
    var del_menu = new GLib.Menu();
    append_menu_item( del_menu, KeyCommand.CONNECTION_REMOVE, _( "Delete" ) );

    var edit_menu = new GLib.Menu();
    append_menu_item( edit_menu, KeyCommand.EDIT_SELECTED,           _( "Edit Title…" ) );
    append_menu_item( edit_menu, KeyCommand.EDIT_NOTE,               _( "Edit Note" ) );
    append_menu_item( edit_menu, KeyCommand.REMOVE_STICKER_SELECTED, _( "Remove Sticker" ) );

    var sel_node_menu = new GLib.Menu();
    append_menu_item( sel_node_menu, KeyCommand.CONNECTION_SELECT_FROM, _( "Start Node" ) );
    append_menu_item( sel_node_menu, KeyCommand.CONNECTION_SELECT_TO,   _( "End Node" ) );

    var sel_conn_menu = new GLib.Menu();
    append_menu_item( sel_conn_menu, KeyCommand.CONNECTION_SELECT_NEXT, _( "Next Connection" ) );
    append_menu_item( sel_conn_menu, KeyCommand.CONNECTION_SELECT_PREV, _( "Previous Connection" ) );

    var sel_submenu = new GLib.Menu();
    sel_submenu.append_section( null, sel_node_menu );
    sel_submenu.append_section( null, sel_conn_menu );

    var sel_menu = new GLib.Menu();
    sel_menu.append_submenu( _( "Select" ), sel_submenu );

    menu.append_section( null, del_menu );
    menu.append_section( null, edit_menu );
    menu.append_section( null, sel_menu );

  }

  protected override void on_popup() {
    var current = map.get_current_connection();
    set_enabled( KeyCommand.CONNECTION_REMOVE,       map.editable );
    set_enabled( KeyCommand.EDIT_SELECTED,           map.editable );
    set_enabled( KeyCommand.EDIT_NOTE,               map.editable );
    set_enabled( KeyCommand.REMOVE_STICKER_SELECTED, ((current != null) && (current.sticker != null) && map.editable) );
  }

}
