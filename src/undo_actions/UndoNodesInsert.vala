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

public class UndoNodesInsert : UndoItem {

  struct InsertedNode {
    Node? parent;
    Node  n;
    int   index;
    bool  parent_folded;
  }

  private Array<InsertedNode?> _nodes;

  /* Default constructor */
  public UndoNodesInsert( DrawArea da, Array<Node> nodes ) {
    base( _( "insert nodes" ) );
    _nodes = new Array<InsertedNode?>();
    for( int i=0; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      if( node.parent == null ) {
        _nodes.append_val( { null, node, da.root_index( node ), false } );
      } else {
        _nodes.append_val( { node.parent, node, node.index(), node.parent.folded } );
      }
    }
  }

  /* Performs an undo operation for this data */
  public override void undo( DrawArea da ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      if( node.parent == null ) {
        da.remove_root( node.index );
      } else {
        if( node.parent_folded ) {
          node.parent.folded = true;
        }
        node.n.detach( node.n.side );
      }
    }
    da.queue_draw();
    da.changed();
  }

  /* Performs a redo operation */
  public override void redo( DrawArea da ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      if( node.parent == null ) {
        da.add_root( node.n, node.index );
      } else {
        node.parent.folded = node.parent_folded;
        node.n.attach( node.parent, node.index, null );
      }
    }
    da.queue_draw();
    da.changed();
  }

}
