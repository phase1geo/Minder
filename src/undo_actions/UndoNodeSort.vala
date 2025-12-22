/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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

public class UndoNodeSort : UndoItem {

  private class SortNodes {

    private Array<Node> _nodes;

    /* Stores the given node into this class */
    public SortNodes( Node n ) {
      _nodes = new Array<Node>();
      for( int i=0; i<n.children().length; i++ ) {
        _nodes.append_val( n.children().index( i ) );
      }
    }

    /* Performs an undo operation for the stored nodes */
    public void change( Node parent ) {
      for( int i=0; i<_nodes.length; i++ ) {
        Node n = _nodes.index( i );
        n.detach( n.side );
      }
      for( int i=0; i<_nodes.length; i++ ) {
        Node n = _nodes.index( i );
        n.attach( parent, -1, null );
      }
    }

  }

  private SortNodes  _old;
  private SortNodes? _new    = null;
  private Node       _parent;

  //-------------------------------------------------------------
  // Default constructor
  public UndoNodeSort( Node parent ) {
    base( _( "sort nodes" ) );
    _parent = parent;
    _old    = new SortNodes( parent );
  }

  //-------------------------------------------------------------
  // Perform the swap.
  private void change( MindMap map, SortNodes nodes ) {
    map.animator.add_nodes( map.get_nodes(), false, "undo sorted nodes" );
    nodes.change( _parent );
    map.animator.animate();
  }

  //-------------------------------------------------------------
  // Performs an undo operation for this data.
  public override void undo( MindMap map ) {
    if( _new == null ) {
      _new = new SortNodes( _parent );
    }
    change( map, _old );
  }

  //-------------------------------------------------------------
  // Performs a redo operation.
  public override void redo( MindMap map ) {
    change( map, _new );
  }

}
