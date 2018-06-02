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

    /* Stores the given node into this class */
    public BalanceNodes( Node n ) {
      _nodes = new Array<Node>();
      _sides = new Array<NodeSide>();
      for( int i=0; i<n.children().length; i++ ) {
        _nodes.append_val( n.children().index( i ) );
        _sides.append_val( n.children().index( i ).side );
      }
    }

    /* Performs an undo operation for the stored nodes */
    public void change( DrawArea da, Layout l, Node parent ) {
      for( int i=0; i<_nodes.length; i++ ) {
        Node n = _nodes.index( i );
        n.detach( n.side, l );
      }
      for( int i=0; i<_nodes.length; i++ ) {
        Node n = _nodes.index( i );
        n.side = _sides.index( i );
        l.propagate_side( n, n.side );
        n.attach( parent, i, l );
      }
    }

  }

  private DrawArea             _da;
  private Array<BalanceNodes>  _old;
  private Array<BalanceNodes>? _new;
  private Layout?              _layout;

  /* Default constructor */
  public UndoNodeBalance( DrawArea da, Layout l ) {
    base( _( "balance nodes" ) );
    _da     = da;
    _layout = l;
    _old    = new Array<BalanceNodes>();
    for( int i=0; i<da.get_nodes().length; i++ ) {
      _old.append_val( new BalanceNodes( da.get_nodes().index( i ) ) );
    }
  }

  /* Perform the swap */
  private void change( Array<BalanceNodes> nodes ) {
    _da.animator.add_nodes( "undo balance nodes" );
    for( int i=0; i<_da.get_nodes().length; i++ ) {
      nodes.index( i ).change( _da, _layout, _da.get_nodes().index( i ) );
    }
    _da.animator.animate();
  }

  /* Performs an undo operation for this data */
  public override void undo() {
    if( _new == null ) {
      _new = new Array<BalanceNodes>();
      for( int i=0; i<_da.get_nodes().length; i++ ) {
        _new.append_val( new BalanceNodes( _da.get_nodes().index( i ) ) );
      }
    }
    change( _old );
  }

  /* Performs a redo operation */
  public override void redo() {
    change( _new );
  }

}
