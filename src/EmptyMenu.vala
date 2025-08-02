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

public class EmptyMenu : BaseMenu {

  /* Default constructor */
  public EmptyMenu( Gtk.Application app, DrawArea da ) {

    base( app, da, "empty" );

    var edit_menu = new GLib.Menu();
    append_menu_item( edit_menu, KeyCommand.EDIT_PASTE, _( "Paste" ) );

    var add_menu = new GLib.Menu();
    append_menu_item( add_menu, KeyCommand.NODE_ADD_SIBLING_AFTER, _( "Add Root Node" ) );
    append_menu_item( add_menu, KeyCommand.NODE_QUICK_ENTRY_INSERT, _( "Add Nodes With Quick Entry" ) );

    var sel_menu = new GLib.Menu();
    append_menu_item( sel_menu, KeyCommand.NODE_SELECT_ROOT, _( "Select First Root Node" ) );

    menu.append_section( null, edit_menu );
    menu.append_section( null, add_menu );
    menu.append_section( null, sel_menu );

  }

  /* Called when the menu is popped up */
  protected override void on_popup() {

    set_enabled( KeyCommand.EDIT_PASTE,             map.model.node_pasteable() );
    set_enabled( KeyCommand.NODE_ADD_SIBLING_AFTER, (map.get_current_connection() == null) );
    set_enabled( KeyCommand.NODE_SELECT_ROOT,       map.root_selectable() );

  }

}
