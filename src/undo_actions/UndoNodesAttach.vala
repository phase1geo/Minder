/*
* Copyright (c) 2025 (https://github.com/phase1geo/Minder)
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

public class UndoNodesAttach : UndoItem {

  private Array<Node>  _nodes;
  private Array<int>   _indices;
  private Array<Node?> _parents;
  private Array<int>   _children;
  private Node         _parent;

  //-------------------------------------------------------------
  // Constructor
  public UndoNodesAttach( Array<Node> nodes, Node parent ) {
    base( _( "nodes attach" ) );
    _nodes    = new Array<Node>();
    _indices  = new Array<int>();
    _parents  = new Array<Node?>();
    _children = new Array<int>();
    _parent = parent;
    for( int i=0; i<nodes.length; i++ ) {
      var node  = nodes.index( i );
      var index = node.index();
      var par   = node.parent;
      var children = (int)node.children().length;
      _nodes.append_val( node );
      _indices.append_val( index );
      _parents.append_val( par );
      _children.append_val( children );
    }
  }

  //-------------------------------------------------------------
  // Undo operation.
  public override void undo( MindMap map ) {
    map.animator.add_nodes( map.get_nodes(), false, "attach_nodes_undo" );
    for( int i=0; i<_nodes.length; i++ ) {
      var node   = _nodes.index( i );
      var index  = _indices.index( i );
      var parent = _parents.index( i );
      node.detach( node.side );
      node.attach( parent, index, null );
      for( int j=0; j<_children.index( i ); j++ ) {
        var child = parent.children().index( index + 1 );
        child.detach( child.side );
        child.attach( node, -1, null );
      }
    }
    map.animator.animate();
    map.auto_save();
  }

  //-------------------------------------------------------------
  // Redo operation
  public override void redo( MindMap map ) {
    map.animator.add_nodes( map.get_nodes(), false, "attach_nodes_redo" );
    map.model.attach_nodes( _nodes, _parent );
    map.animator.animate();
    map.auto_save();
  }

}
