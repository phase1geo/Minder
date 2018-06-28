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

public class UndoNodeLayout : UndoItem {

  private class LayoutNodes {

    private Array<Node>     _nodes;
    private Array<NodeSide> _sides;

    /* Stores the given node into this class */
    public LayoutNodes( Node n ) {
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
        n.attach( parent, i, null, l );
      }
    }

  }

  private DrawArea            _da;
  private Array<LayoutNodes>  _old;
  private Array<LayoutNodes>? _new = null;
  private Layout              _old_layout;
  private Layout              _new_layout;

  /* Default constructor */
  public UndoNodeLayout( DrawArea da, Layout old_layout, Layout new_layout ) {
    base( _( "change layout" ) );
    _da         = da;
    _old_layout = old_layout;
    _new_layout = new_layout;
    _old        = new Array<LayoutNodes>();
    for( int i=0; i<da.get_nodes().length; i++ ) {
      _old.append_val( new LayoutNodes( da.get_nodes().index( i ) ) );
    }
  }

  /* Perform the swap */
  private void change( Array<LayoutNodes> nodes, Layout layout ) {
    _da.animator.add_nodes( "undo layout change" );
    for( int i=0; i<_da.get_nodes().length; i++ ) {
      nodes.index( i ).change( _da, layout, _da.get_nodes().index( i ) );
    }
    _da.animator.animate();
    _da.set_layout( layout.name );
    _da.loaded();
  }

  /* Performs an undo operation for this data */
  public override void undo() {
    if( _new == null ) {
      _new = new Array<LayoutNodes>();
      for( int i=0; i<_da.get_nodes().length; i++ ) {
        _new.append_val( new LayoutNodes( _da.get_nodes().index( i ) ) );
      }
    }
    change( _old, _old_layout );
  }

  /* Performs a redo operation */
  public override void redo() {
    change( _new, _new_layout );
  }

}
