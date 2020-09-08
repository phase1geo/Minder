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

public class ConnectionsMenu : Gtk.Menu {

  DrawArea     _da;
  Gtk.MenuItem _delete;

  /* Default constructor */
  public ConnectionsMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    _delete = new Gtk.MenuItem();
    _delete.add( new Granite.AccelLabel( _( "Delete" ), "Delete" ) );
    _delete.activate.connect( delete_connections );

    /* Add the menu items to the menu */
    add( _delete );

    /* Make the menu visible */
    show_all();

  }

  /* Deletes the current node */
  private void delete_connections() {
    _da.delete_connections();
  }

}
