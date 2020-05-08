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

public enum NodeAlignType {
  TOP = 0,
  BOTTOM,
  LEFT,
  RIGHT,
  HCENTER,
  VCENTER
}

public class NodeAlign {

  /* Aligns all of the given nodes to the top of the first node */
  public static void align_top( DrawArea da, Array<Node> nodes ) {
    var top = nodes.index( 0 ).posy;
    for( int i=1; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      da.animator.add_node( node, "align_top" );
      node.posy = top;
    }
    da.animator.animate();
    da.changed();
  }

  /* Aligns all of the given nodes to the bottom of the first node */
  public static void align_bottom( DrawArea da, Array<Node> nodes ) {
    var bot = nodes.index( 0 ).posy + nodes.index( 0 ).height;
    for( int i=1; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      da.animator.add_node( node, "align_bottom" );
      node.posy = bot - node.height;
    }
    da.animator.animate();
    da.changed();
  }

  /* Aligns all of the given nodes to the left side of the first node */
  public static void align_left( DrawArea da, Array<Node> nodes ) {
    var left = nodes.index( 0 ).posx;
    for( int i=1; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      da.animator.add_node( node, "align_left" );
      node.posx = left;
    }
    da.animator.animate();
    da.changed();
  }

  /* Aligns all of the given nodes to the right side of the first node */
  public static void align_right( DrawArea da, Array<Node> nodes ) {
    var right = nodes.index( 0 ).posx + nodes.index( 0 ).width;
    for( int i=1; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      da.animator.add_node( node, "align_right" );
      node.posx = right - node.width;
    }
    da.animator.animate();
    da.changed();
  }

  /* Aligns all of the given nodes to the center of the first node horizontally */
  public static void align_hcenter( DrawArea da, Array<Node> nodes ) {
    var center = nodes.index( 0 ).posy + (nodes.index( 0 ).height / 2);
    for( int i=1; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      da.animator.add_node( node, "align_hcenter" );
      node.posy = center - (node.height / 2);
    }
    da.animator.animate();
    da.changed();
  }

  /* Aligns all of the given nodes to the center of the first node vertically */
  public static void align_vcenter( DrawArea da, Array<Node> nodes ) {
    var center = nodes.index( 0 ).posx + (nodes.index( 0 ).width / 2);
    for( int i=1; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      da.animator.add_node( node, "align_vcenter" );
      node.posx = center - (node.width / 2);
    }
    da.animator.animate();
    da.changed();
  }

}
