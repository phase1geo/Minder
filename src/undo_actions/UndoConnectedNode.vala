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

public class UndoConnectedNode : UndoItem {

  private Node       _node;
  private Connection _conn;
  private int        _index;

  public UndoConnectedNode( Node node, int index, Connection conn ) {
    base( _( "connected node" ) );
    _node  = node;
    _conn  = conn;
    _index = index;
  }

  public override void undo( DrawArea da ) {
    da.remove_root( _index );
    da.get_connections().remove_connection( _conn, false );
    if( da.get_current_node() == _node ) {
      da.set_current_node( null );
    }
    da.queue_draw();
    da.changed();
  }

  public override void redo( DrawArea da ) {
    da.get_nodes().insert_val( _index, _node );
    da.get_connections().add_connection( _conn );
    da.set_current_node( _node );
    da.queue_draw();
    da.changed();
  }

}
