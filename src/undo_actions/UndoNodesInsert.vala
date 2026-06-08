/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

public class UndoNodesInsert : UndoItem {

  struct InsertedNode {
    BaseNode? parent;
    BaseNode  n;
    int       index;
    bool      parent_folded;
  }

  private Array<InsertedNode?> _nodes;

  //-------------------------------------------------------------
  // Default constructor
  public UndoNodesInsert( MindMap map, Array<BaseNode> nodes ) {
    base( _( "insert nodes" ) );
    _nodes = new Array<InsertedNode?>();
    for( int i=0; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      if( node.parent == null ) {
        _nodes.append_val( { null, node, map.model.root_index( (Node)node ), false } );
      } else {
        var pnode = (node.parent as Node);
        _nodes.append_val( { node.parent, node, node.index(), ((pnode != null) && pnode.folded) } );
      }
    }
  }

  //-------------------------------------------------------------
  // Performs an undo operation for this data
  public override void undo( MindMap map ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      if( node.parent == null ) {
        map.model.remove_root( node.index );
      } else {
        if( node.parent_folded ) {
          var pnode = (Node)node.parent;
          pnode.folded = true;
        }
        node.n.detach( node.n.side );
      }
    }
    map.set_current_node( null );
    map.queue_draw();
    map.auto_save();
  }

  //-------------------------------------------------------------
  // Performs a redo operation
  public override void redo( MindMap map ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      if( node.parent == null ) {
        map.model.add_root( (Node)node.n, node.index );
      } else {
        var pnode = (node.parent as Node);
        if( pnode != null ) {
          pnode.folded = node.parent_folded;
        }
        node.n.attach( node.parent, node.index, null );
      }
    }
    map.set_current_node( MapModel.basenode_to_node( _nodes.index( 0 ).n ) );
    map.queue_draw();
    map.auto_save();
  }

}
