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

public class UndoConnectionsDelete : UndoItem {

  Array<Connection> _conns;

  //-------------------------------------------------------------
  // Constructor for deleting connections.
  public UndoConnectionsDelete( Array<Connection> conns ) {
    base( _( "delete connections" ) );
    _conns = new Array<Connection>();
    for( int i=0; i<conns.length; i++ ) {
      _conns.append_val( conns.index( i ) );
    }
  }

  //-------------------------------------------------------------
  // Undoes connection deletions.
  public override void undo( MindMap map ) {
    var selected = map.selected;
    selected.clear();
    map.connections.add_connections( _conns );
    selected.add_connections( _conns );
    map.queue_draw();
    map.auto_save();
  }

  //-------------------------------------------------------------
  // Redoes connection deletions.
  public override void redo( MindMap map ) {
    map.connections.remove_connections( _conns, false );
    map.selected.clear_connections();
    map.queue_draw();
    map.auto_save();
  }

}
