/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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

public class ConnectionsMenu : BaseMenu {

  //-------------------------------------------------------------
  // Default constructor.
  public ConnectionsMenu( Gtk.Application app, DrawArea da ) {

    base( app, da, "conns" );

    var del_menu = new GLib.Menu();
    append_menu_item( del_menu, KeyCommand.CONNECTION_REMOVE, _( "Delete" ) );

    menu.append_section( null, del_menu );

  }

  //-------------------------------------------------------------
  // Update state of menu items based on the current state of the
  // mind map.
  protected override void on_popup() {
    set_enabled( KeyCommand.CONNECTION_REMOVE, map.editable );
  }

}
