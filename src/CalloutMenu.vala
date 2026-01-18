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

public class CalloutMenu : BaseMenu {

  //-------------------------------------------------------------
  // Default constructor
  public CalloutMenu( Gtk.Application app, DrawArea da ) {

    base( app, da, "callout" );

    var del_menu = new GLib.Menu();
    append_menu_item( del_menu, KeyCommand.EDIT_DELETE, _( "Delete" ) );

    var sel_menu = new GLib.Menu();
    append_menu_item( sel_menu, KeyCommand.CALLOUT_SELECT_NODE, _( "Select Node" ) );

    menu.append_section( null, del_menu );
    menu.append_section( null, sel_menu );

  }

  //-------------------------------------------------------------
  // Update the enable status for menu items that need to be disabled
  // based on the current state.
  protected override void on_popup() {
    set_enabled( KeyCommand.EDIT_DELETE, map.editable );
  }

}
