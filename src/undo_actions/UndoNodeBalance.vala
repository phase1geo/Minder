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

public class UndoNodeBalance : UndoItem {

  private class BalanceNodes {

    private Array<Node>     _nodes;
    private Array<NodeSide> _sides;

    //-------------------------------------------------------------
    // Stores the given node into this class.
    public BalanceNodes( Node n ) {
      _nodes = new Array<Node>();
      _sides = new Array<NodeSide>();
      for( int i=0; i<n.children().length; i++ ) {
        _nodes.append_val( n.children().index( i ) );
        _sides.append_val( n.children().index( i ).side );
      }
    }

    //-------------------------------------------------------------
    // Performs an undo operation for the stored nodes.
    public void change( Node parent ) {
      for( int i=0; i<_nodes.length; i++ ) {
        Node n = _nodes.index( i );
        n.detach( n.side );
      }
      for( int i=0; i<_nodes.length; i++ ) {
        Node n = _nodes.index( i );
        n.side = _sides.index( i );
        n.layout.propagate_side( n, n.side );
        n.attach_init( parent, -1 );
      }
    }

  }

  private Array<BalanceNodes>  _old;
  private Array<BalanceNodes>? _new  = null;
  private Node?                _root = null;

  //-------------------------------------------------------------
  // Default constructor.
  public UndoNodeBalance( MindMap map, Node? root_node ) {
    base( _( "balance nodes" ) );
    _root = root_node;
    _old  = new Array<BalanceNodes>();
    if( root_node == null ) {
      for( int i=0; i<map.get_nodes().length; i++ ) {
        _old.append_val( new BalanceNodes( map.get_nodes().index( i ) ) );
      }
    } else {
      _old.append_val( new BalanceNodes( root_node ) );
    }
  }

  //-------------------------------------------------------------
  // Perform the swap.
  private void change( MindMap map, Array<BalanceNodes> nodes ) {
    map.canvas.animator.add_nodes( map.get_nodes(), "undo balance nodes" );
    if( _root == null ) {
      for( int i=0; i<map.get_nodes().length; i++ ) {
        nodes.index( i ).change( map.get_nodes().index( i ) );
      }
    } else {
      nodes.index( 0 ).change( _root );
    }
    map.canvas.animator.animate();
  }

  //-------------------------------------------------------------
  // Performs an undo operation for this data.
  public override void undo( MindMap map ) {
    if( _new == null ) {
      _new = new Array<BalanceNodes>();
      for( int i=0; i<map.get_nodes().length; i++ ) {
        _new.append_val( new BalanceNodes( map.get_nodes().index( i ) ) );
      }
    }
    change( map, _old );
  }

  //-------------------------------------------------------------
  // Performs a redo operation.
  public override void redo( MindMap map ) {
    change( map, _new );
  }

}
