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

public class UndoNodesReplace : UndoItem {

  private Node        _orig_node;
  private Array<Node> _new_nodes;

  /* Default constructor */
  public UndoNodesReplace( DrawArea da, Node? orig_node, Array<Node> new_nodes ) {
    base( _( "replace nodes" ) );
    _orig_node = orig_node;
    _new_nodes = new Array<Node>();
    for( int i=0; i<new_nodes.length; i++ ) {
      _new_nodes.append_val( new_nodes.index( i ) );
    }
  }

  /* Performs an undo operation for this data */
  public override void undo( DrawArea da ) {
    var first_node  = _new_nodes.index( 0 );
    var first_index = (first_node.parent == null) ? da.root_index( first_node ) : first_node.index();
    for( int i=0; i<_new_nodes.length; i++ ) {
      var node = _new_nodes.index( i );
      if( node.parent == null ) {
        da.remove_root_node( node );
      } else {
        node.detach( node.side );
      }
    }
    if( first_node.parent == null ) {
      da.add_root( _orig_node, first_index );
    } else {
      _orig_node.attach( first_node.parent, first_index, null );
    }
    da.queue_draw();
    da.changed();
  }

  /* Performs a redo operation */
  public override void redo( DrawArea da ) {
    var parent = _orig_node.parent;
    var index  = _orig_node.index();
    _orig_node.detach( _orig_node.side );
    _new_nodes.index( 0 ).attach( parent, index, null );
    for( int i=1; i<_new_nodes.length; i++ ) {
      da.add_root( _new_nodes.index( i ), -1 );
    }
    da.queue_draw();
    da.changed();
  }

}
