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

public class GroupsMenu : BaseMenu {

  //-------------------------------------------------------------
  // Default constructor
  public GroupsMenu( Gtk.Application app, DrawArea da ) {

    base( app, da, "groups" );

    var del_menu = new GLib.Menu();
    append_menu_item( del_menu, KeyCommand.GROUP_REMOVE, _( "Delete" ) );

    var change_menu = new GLib.Menu();
    append_menu_item( change_menu, KeyCommand.EDIT_NOTE, _( "Edit Note" ) );
    append_menu_item( change_menu, KeyCommand.GROUP_CHANGE_COLOR, _( "Change color…" ) );
    append_menu_item( change_menu, KeyCommand.GROUP_MERGE,        _( "Merge" ) );

    var sel_submenu = new GLib.Menu();
    append_menu_item( sel_submenu, KeyCommand.GROUP_SELECT_MAIN, _( "Top Nodes" ) );
    append_menu_item( sel_submenu, KeyCommand.GROUP_SELECT_ALL,  _( "All Grouped Nodes" ) );

    var sel_menu = new GLib.Menu();
    sel_menu.append_submenu( _( "Select" ), sel_submenu );

    menu.append_section( null, del_menu );
    menu.append_section( null, change_menu );
    menu.append_section( null, sel_menu );

  }

  //-------------------------------------------------------------
  // Called when the menu is popped up.
  protected override void on_popup() {

    var groups = map.get_selected_groups();
    var num    = groups.length;

    /* Set the menu sensitivity */
    set_enabled( KeyCommand.GROUP_MERGE, (num > 1) );

  }

}
