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

public class UndoConnectionChange : UndoItem {

  Connection? _old_connection;
  Connection? _new_connection;

  /* Constructor for adding/removing/changing a connection */
  public UndoConnectionChange( string name, Connection? old_connection, Connection? new_connection ) {
    base( name );
    _old_connection = old_connection;
    _new_connection = new_connection;
  }

  /* Undoes a connection change */
  public override void undo( MindMap map ) {
    if( _old_connection == null ) {
      map.model.get_connections().remove_connection( _new_connection, true );
    }
    map.set_current_connection( _old_connection );
    map.queue_draw();
    map.auto_save();
  }

  /* Redoes a connection change */
  public override void redo( MindMap map ) {
    if( _new_connection == null ) {
      map.model.get_connections().remove_connection( _old_connection, true );
    }
    map.set_current_connection( _new_connection );
    map.queue_draw();
    map.auto_save();
  }

}
