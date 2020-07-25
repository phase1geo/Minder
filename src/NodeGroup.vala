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

using Cairo;
using Gdk;

public struct NodePoint {
  double x;
  double y;
  public NodePoint( double x, double y ) {
    this.x = x;
    this.y = y;
  }
}

public class NodeGroup {

  public static void draw_cloud( Context ctx, RGBA color, double alpha, Array<NodePoint?> hull ) {
    Utils.set_context_color_with_alpha( ctx, color, ((alpha == 1.0) ? 0.3 : alpha) );
    ctx.move_to( hull.index( 0 ).x, hull.index( 0 ).y );
    for( int i=0; i<hull.length; i++ ) {
      ctx.line_to( hull.index( i ).x, hull.index( i ).y );
    }
    ctx.close_path();
    ctx.fill();
  }

  public static void draw_tight( Context ctx, Node node ) {
    var points = new Array<NodePoint?>();
    var hull   = new Array<NodePoint?>();
    get_points( node, points );
    get_convex_hull( points, hull );
    draw_cloud( ctx, node.link_color, node.alpha, hull );
  }

  public static void get_points( Node node, Array<NodePoint?> points ) {

    var pad = 0;
    var x1 = node.posx - pad;
    var y1 = node.posy - pad;
    var x2 = node.posx + node.width + pad;
    var y2 = node.posy + node.height + pad;

    points.append_val( new NodePoint( x1, y1 ) );
    points.append_val( new NodePoint( x2, y1 ) );
    points.append_val( new NodePoint( x1, y2 ) );
    points.append_val( new NodePoint( x2, y2 ) );

    for( int i=0; i<node.children().length; i++ ) {
      get_points( node.children().index( i ), points );
    }

  }

  public static void get_convex_hull( Array<NodePoint?> points, Array<NodePoint?> hull ) {

    var n = (int)points.length;

    /* Get the left-most point */
    var l = 0;
    for( int i=1; i<n; i++ ) {
      if( points.index( i ).x < points.index( l ).x ) l = i;
    }

    var p = l;

    do {
      hull.append_val( points.index( p ) );
      var q = (p + 1) % n;
      for( int i=0; i<n; i++ ) {
        if( calc_orientation( points.index( p ), points.index( i ), points.index( q ) ) == 2 ) q = i;
      }
      p = q;
    } while( p != l );

  }

  public static int calc_orientation( NodePoint p, NodePoint q, NodePoint r ) {
    var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
    if( val == 0 ) return( 0 );
    return( (val > 0) ? 1 : 2 );
  }

}
