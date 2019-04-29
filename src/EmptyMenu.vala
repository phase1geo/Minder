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

public class EmptyMenu : Gtk.Menu {

  DrawArea     _da;
  Gtk.MenuItem _root;
  Gtk.MenuItem _selroot;

  /* Default constructor */
  public EmptyMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    _root = new Gtk.MenuItem.with_label( _( "Add Root Node" ) );
    _root.activate.connect( add_root_node );

    var selnode = new Gtk.MenuItem.with_label( _( "Select Node" ) );
    var selmenu = new Gtk.Menu();
    selnode.set_submenu( selmenu );

    _selroot = new Gtk.MenuItem.with_label( _( "Root" ) );
    _selroot.activate.connect( select_root_node );
    Utils.add_accel_label( _selroot, 'm', 0 );

    /* Add the menu items to the menu */
    add( _root );
    add( new SeparatorMenuItem() );
    add( selnode );

    /* Add the items to the selection menu */
    selmenu.add( _selroot );

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  /* Returns true if there is a currently selected connection */
  private bool connection_selected() {
    return( _da.get_current_connection() != null );
  }

  /* Called when the menu is popped up */
  private void on_popup() {

    /* Set the menu sensitivity */
    _root.set_sensitive( !connection_selected() );
    _selroot.set_sensitive( _da.root_selectable() );

  }

  /* Creates a new root node */
  private void add_root_node() {
    _da.add_root_node();
  }

  /* Selects the current root node */
  private void select_root_node() {
    _da.select_root_node();
  }

}
