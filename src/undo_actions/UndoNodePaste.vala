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
using Gee;

public class UndoNodePaste : UndoItem {

  private Array<Node?>      _parents;
  private Array<Node>       _nodes;
  private Array<int>        _indices;
  private Array<Connection> _conns;
  private Array<NodeGroup>  _groups;

  //-------------------------------------------------------------
  // Default constructor.
  public UndoNodePaste( Array<Node> nodes, Array<Connection> conns, Array<NodeGroup> groups ) {
    base( _( "paste node" ) );
    _nodes   = nodes;
    _conns   = conns;
    _groups  = groups;
    _indices = new Array<int>();
    _parents = new Array<Node?>();
    for( int i=0; i<nodes.length; i++ ) {
      int index = nodes.index( i ).index();
      _indices.append_val( index );
      _parents.append_val( nodes.index( i ).parent );
    }
  }

  //-------------------------------------------------------------
  // Performs an undo operation for this data.
  public override void undo( MindMap map ) {
    map.animator.add_nodes( map.get_nodes(), false, "undo node paste" );
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).detach( _nodes.index( i ).side );
    }
    for( int i=0; i<_conns.length; i++ ) {
      map.connections.remove_connection( _conns.index( i ), false );
    }
    for( int i=0; i<_groups.length; i++ ) {
      map.groups.remove_group( _groups.index( i ) );
    }
    map.set_current_node( null );
    map.animator.animate();
    map.auto_save();
  }

  //-------------------------------------------------------------
  // Performs a redo operation.
  public override void redo( MindMap map ) {
    map.animator.add_nodes( map.get_nodes(), false, "redo node paste" );
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).attach( _parents.index( i ), _indices.index( i ), null );
    }
    for( int i=0; i<_conns.length; i++ ) {
      map.connections.add_connection( _conns.index( i ) );
    }
    for( int i=0; i<_groups.length; i++ ) {
      map.groups.add_group( _groups.index( i ) );
    }
    map.set_current_node( _nodes.index( 0 ) );
    map.animator.animate();
    map.auto_save();
  }

}
