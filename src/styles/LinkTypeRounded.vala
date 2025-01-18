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

public class LinkTypeRounded : Object, LinkType {

  /* Default constructor */
  public LinkTypeRounded() {}

  /* Returns the search name */
  public string name() {
    return( "rounded" );
  }

  /* Returns the name of the link type */
  public string display_name() {
    return( _( "Rounded" ) );
  }

  /* Returns the name of the light-mode icon */
  public string light_icon_name() {
    return( "minder-link-rounded-light-symbolic" );
  }

  /* Returns the name of the dark-mode icon */
  public string dark_icon_name() {
    return( "minder-link-rounded-dark-symbolic" );
  }

  private void adjust_mid( Node parent, NodeSide child_side, double from_a, double to_a, double from_b, double to_b, double radius, out double mid, out double rnd_a, out double rnd_b ) {
    mid   = ((from_a + to_a) / 2) + adjust_mid_by( parent, child_side );
    rnd_a = (from_a < to_a) ? (mid + radius) : (mid - radius);
    rnd_b = (from_b < to_b) ? (((to_b - radius) < from_b) ? from_b : (to_b - radius)) :
                              (((to_b + radius) > from_b) ? from_b : (to_b + radius));
  }

  /* Draw method for the link */
  public void draw( Cairo.Context ctx, Node from_node, Node to_node,
                    double from_x, double from_y, double to_x, double to_y,
                    out double tailx, out double taily, out double tipx, out double tipy ) {

    var side       = to_node.side;
    var horizontal = side.horizontal();
    var fstyle     = from_node.style;
    var tstyle     = to_node.style;
    var adj_a      = adjust_a( tstyle );
    var adj_t      = adjust_tip( tstyle );
    var radius     = from_node.style.branch_radius;

    tipx = tipy = 0;

    switch( side ) {
      case NodeSide.LEFT   :  to_x += adj_a;  tipx = to_x - adj_t;  tipy = to_y;  break;
      case NodeSide.RIGHT  :  to_x -= adj_a;  tipx = to_x + adj_t;  tipy = to_y;  break;
      case NodeSide.TOP    :  to_y += adj_a;  tipy = to_y - adj_t;  tipx = to_x;  break;
      case NodeSide.BOTTOM :  to_y -= adj_a;  tipy = to_y + adj_t;  tipx = to_x;  break;
    }

    ctx.move_to( from_x, from_y );
    if( horizontal ) {
      double mid_x, rnd_x, rnd_y;
      adjust_mid( from_node, side, from_x, to_x, from_y, to_y, radius, out mid_x, out rnd_x, out rnd_y );
      tailx = mid_x;
      taily = to_y;
      ctx.line_to( mid_x, from_y );
      ctx.line_to( mid_x, rnd_y );
      ctx.curve_to( mid_x, rnd_y, mid_x, to_y, rnd_x, to_y );
      ctx.line_to( to_x,  to_y );
    } else {
      double mid_y, rnd_y, rnd_x;
      adjust_mid( from_node, side, from_y, to_y, from_x, to_x, radius, out mid_y, out rnd_y, out rnd_x );
      tailx = to_x;
      taily = mid_y;
      ctx.line_to( from_x, mid_y );
      ctx.line_to( rnd_x,   mid_y );
      ctx.curve_to( rnd_x, mid_y, to_x, mid_y, to_x, rnd_y );
      ctx.line_to( to_x,   to_y );
    }
    ctx.stroke();

  }

}

