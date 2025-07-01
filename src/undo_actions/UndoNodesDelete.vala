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

public class UndoNodesDelete : UndoItem {

  private class NodeInfo {
    public Node  node;
    public Node? parent;
    public int   index;
    public NodeInfo( Node n ) {
      node   = n;
      parent = n.parent;
      index  = n.index();
    }
  }

  Array<NodeInfo>        _nodes;
  Array<Connection>      _conns;
  Array<UndoNodeGroups?> _groups;

  /* Default constructor */
  public UndoNodesDelete( Array<Node> nodes, Array<Connection> conns, Array<UndoNodeGroups?> groups ) {
    base( _( "delete nodes" ) );
    _nodes = new Array<NodeInfo>();
    for( int i=0; i<nodes.length; i++ ) {
      _nodes.append_val( new NodeInfo( nodes.index( i ) ) );
    }
    _conns  = conns;
    _groups = groups;
  }

  /* Undoes a node deletion */
  public override void undo( MindMap map ) {
    map.selected.clear();
    for( int i=0; i<_nodes.length; i++ ) {
      var ni = _nodes.index( i );
      ni.node.attach_only( ni.parent, ni.index );
      map.selected.add_node( ni.node );
    }
    for( int i=0; i<_conns.length; i++ ) {
      map.get_connections().add_connection( _conns.index( i ) );
    }
    map.groups.apply_undos( _groups );
    map.queue_draw();
    map.auto_save();
  }

  /* Redoes a node deletion */
  public override void redo( MindMap map ) {
    map.selected.clear();
    for( int i=0; i<_nodes.length; i++ ) {
      UndoNodeGroups? tmp_group = null;
      _nodes.index( i ).node.delete_only();
      map.groups.remove_node( _nodes.index( i ).node, ref tmp_group );
    }
    for( int i=0; i<_conns.length; i++ ) {
      map.get_connections().remove_connection( _conns.index( i ), false );
    }
    map.queue_draw();
    map.auto_save();
  }

}
