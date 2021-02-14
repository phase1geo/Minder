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

public class UndoConnectionAdd : UndoItem {

  Connection _connection;

  /* Constructor for adding a connection */
  public UndoConnectionAdd( Connection connection ) {
    base( _( "add connection" ) );
    _connection = connection;
  }

  /* Undoes a connection change */
  public override void undo( DrawArea da ) {
    da.get_connections().remove_connection( _connection, false );
    da.set_current_connection( null );
    da.queue_draw();
    da.auto_save();
  }

  /* Redoes a connection change */
  public override void redo( DrawArea da ) {
    da.get_connections().add_connection( _connection );
    da.set_current_connection( _connection );
    da.queue_draw();
    da.auto_save();
  }

}
