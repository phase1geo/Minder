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

public class UndoNodesAlign : UndoItem {

  private class NodeAlignInfo {
    private double   _posx;
    private double   _posy;
    private NodeSide _side;
    public NodeAlignInfo( Node node ) {
      _posx = node.posx;
      _posy = node.posy;
      _side = node.side;
    }
    public void swap_with_node( Node node ) {
      var x = _posx;
      var y = _posy;
      var s = _side;
      _posx = node.posx;
      _posy = node.posy;
      _side = node.side;
      node.posx = x;
      node.posy = y;
      if( node.side != s ) {
        node.side = s;
        node.layout.propagate_side( node, s );
      }
    }
  }

  Array<Node>          _nodes;
  Array<NodeAlignInfo> _info;

  //-------------------------------------------------------------
  // Constructor for a node name change.
  public UndoNodesAlign( Array<Node> nodes ) {
    base( _( "node alignment" ) );
    _nodes = new Array<Node>();
    _info  = new Array<NodeAlignInfo>();
    for( int i=1; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      _nodes.append_val( node );
      _info.append_val( new NodeAlignInfo( node ) );
    }
  }

  //-------------------------------------------------------------
  // Perform the node alignment change with animation.
  private void change( MindMap map ) {
    map.animator.add_nodes( _nodes, false, "align change" );
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      _info.index( i ).swap_with_node( node );
    }
    map.animator.animate();
    map.auto_save();
  }

  //-------------------------------------------------------------
  // Undoes a node image change.
  public override void undo( MindMap map ) {
    change( map );
  }

  //-------------------------------------------------------------
  // Redoes a node image change.
  public override void redo( MindMap map ) {
    change( map );
  }

}
