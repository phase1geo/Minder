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
using Gdk;

public class UndoNodesAttach : UndoItem {

  private Array<Node>      _nodes;
  private Node             _attach_node;
  private Array<Node>      _parents;
  private Array<int>       _indices;
  private Array<NodeInfo?> _info;

  /* Default constructor */
  public UndoNodesAttach( DrawArea da, Array<Node> nodes, Node attach_node ) {
    base( _( "attach nodes" ) );

    _nodes       = nodes;
    _attach_node = attach_node;
    _parents     = new Array<Node>();
    _indices     = new Array<int>();
    _info        = new Array<NodeInfo?>();

    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      _parents.append_val( node.parent );
      if( node.parent == null ) {
        var roots = da.get_nodes();
        for( int j=0; j<roots.length; j++ ) {
          if( node == roots.index( j ) ) {
            _indices.append_val( j );
            break;
          }
        }
      } else {
        var index = node.index();
        _indices.append_val( index );
      }
      _nodes.index( i ).gather_info( _info );
    }

  }

  /* Performs an undo operation for this data */
  public override void undo( DrawArea da ) {
    var index = 0;
    da.animator.add_nodes( da.get_nodes(), "undo attach" );
    da.selected.clear( false );
    for( int i=0; i<_nodes.length; i++ ) {
      da.selected.add_node( _nodes.index( i ), ((i + 1) == _nodes.length) );
    }
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      node.detach( node.info.side );
      if( _parents.index( i ) == null ) {
        da.add_root( node, _indices.index( i ) );
        node.return_info( _info, ref index );
      } else {
        node.return_info( _info, ref index );
        node.layout.propagate_side( node, node.info.side );
        node.attach_init( _parents.index( i ), _indices.index( i ) );
      }
    }
    da.animator.animate();
    da.changed();
  }

  /* Performs a redo operation */
  public override void redo( DrawArea da ) {
    da.animator.add_nodes( da.get_nodes(), "redo attach" );
    da.selected.clear( false );
    for( int i=0; i<_nodes.length; i++ ) {
      da.attach_node( _nodes.index( i ) );
      da.selected.add_node( _nodes.index( i ), ((i + 1) == _nodes.length) );
    }
    da.animator.animate();
    da.changed();
  }

}
