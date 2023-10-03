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

public class CalloutMenu : Gtk.Menu {

  DrawArea _da;

  /* Default constructor */
  public CalloutMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    var del = new Gtk.MenuItem();
    del.add( new Granite.AccelLabel( _( "Delete" ), "Delete" ) );
    del.activate.connect( delete_callout );

    var selnode = new Gtk.MenuItem();
    selnode.add( new Granite.AccelLabel( _( "Select Node" ), "<Shift>o" ) );
    selnode.activate.connect( select_node );

    /* Add the menu items to the menu */
    add( del );
    add( new SeparatorMenuItem() );
    add( selnode );

    /* Make the menu visible */
    show_all();

  }

  /* Deletes the current group */
  private void delete_callout() {
    _da.remove_callout();
  }

  /* Selects the top-most nodes in each selected node group */
  private void select_node() {
    _da.select_callout_node();
  }

}
