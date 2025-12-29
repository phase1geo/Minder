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

public enum NodeAlignType {
  TOP = 0,
  BOTTOM,
  LEFT,
  RIGHT,
  HCENTER,
  VCENTER
}

public class NodeAlign {

  delegate void NodeAlignFunc( Node first, Node node );

  private static void align_to( MindMap map, Array<Node> nodes, NodeAlignFunc align_func ) {
    map.undo_buffer.add_item( new UndoNodesAlign( nodes ) );
    map.animator.add_nodes( nodes, false, "align_to" );
    var first = nodes.index( 0 );
    for( int i=1; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      align_func( first, node );
      if( node.side != first.side ) {
        node.side = first.side;
        node.layout.propagate_side( node, first.side );
      }
    }
    map.animator.animate();
    map.auto_save();
  }

  /* Aligns all of the given nodes to the top of the first node */
  public static void align_top( MindMap map, Array<Node> nodes ) {
    align_to( map, nodes, (first, node) => { node.posy = first.posy; } );
  }

  /* Aligns all of the given nodes to the bottom of the first node */
  public static void align_bottom( MindMap map, Array<Node> nodes ) {
    align_to( map, nodes, (first, node) => { node.posy = ((first.posy + first.height) - node.height); } );
  }

  /* Aligns all of the given nodes to the left side of the first node */
  public static void align_left( MindMap map, Array<Node> nodes ) {
    align_to( map, nodes, (first, node) => { node.posx = first.posx; } );
  }

  /* Aligns all of the given nodes to the right side of the first node */
  public static void align_right( MindMap map, Array<Node> nodes ) {
    align_to( map, nodes, (first, node) => { node.posx = ((first.posx + first.width) - node.width); } );
  }

  /* Aligns all of the given nodes to the center of the first node horizontally */
  public static void align_hcenter( MindMap map, Array<Node> nodes ) {
    align_to( map, nodes, (first, node) => { node.posx = ((first.posx + (first.width / 2)) - (node.width / 2)); } );
  }

  /* Aligns all of the given nodes to the center of the first node vertically */
  public static void align_vcenter( MindMap map, Array<Node> nodes ) {
    align_to( map, nodes, (first, node) => { node.posy = ((first.posy + (first.height / 2)) - (node.height / 2)); } );
  }

}
