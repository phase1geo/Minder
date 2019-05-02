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

public class UndoConnectionDelete : UndoItem {

  Connection _connection;
  Node       _from_node;
  Node       _to_node;

  /* Constructor for deleting a connection */
  public UndoConnectionDelete( Connection connection ) {
    base( _( "delete connection" ) );
    _connection = connection;
    _from_node  = connection.from_node;
    _to_node    = connection.to_node;
  }

  /* Undoes a connection change */
  public override void undo( DrawArea da ) {
    _connection.from_node = _from_node;
    _connection.to_node   = _to_node;
    _connection.connect_node( _from_node );
    _connection.connect_node( _to_node );
    da.get_connections().add_connection( _connection );
    da.set_current_connection( _connection );
    da.queue_draw();
    da.changed();
  }

  /* Redoes a connection change */
  public override void redo( DrawArea da ) {
    da.get_connections().remove_connection( _connection );
    da.set_current_connection( null );
    da.queue_draw();
    da.changed();
  }

}
