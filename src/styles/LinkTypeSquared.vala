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

public class LinkTypeSquared : Object, LinkType {

  /* Default constructor */
  public LinkTypeSquared() {}

  /* Returns the search name */
  public string name() {
    return( "squared" );
  }

  /* Returns the name of the link type */
  public string display_name() {
    return( _( "Squared" ) );
  }

  /* Returns the name of the light-mode icon */
  public string light_icon_name() {
    return( "minder-link-squared-light-symbolic" );
  }

  /* Returns the name of the dark-mode icon */
  public string dark_icon_name() {
    return( "minder-link-squared-dark-symbolic" );
  }

  /* Draw method for the link */
  public void draw( Cairo.Context ctx, Node from_node, Node to_node,
                    double from_x, double from_y, double to_x, double to_y,
                    out double tailx, out double taily, out double tipx, out double tipy ) {

    var side  = to_node.side;
    var style = to_node.style;
    var adj_a = adjust_a( style );
    var adj_t = adjust_tip( style );

    tipx = tipy = 0;

    switch( side ) {
      case NodeSide.LEFT   :  to_x += adj_a;  tipx = to_x - adj_t;  tipy = to_y;  break;
      case NodeSide.RIGHT  :  to_x -= adj_a;  tipx = to_x + adj_t;  tipy = to_y;  break;
      case NodeSide.TOP    :  to_y += adj_a;  tipy = to_y - adj_t;  tipx = to_x;  break;
      case NodeSide.BOTTOM :  to_y -= adj_a;  tipy = to_y + adj_t;  tipx = to_x;  break;
    }

    ctx.move_to( from_x, from_y );
    if( side.horizontal() ) {
      var mid_x = ((from_x + to_x) / 2) + adjust_mid_by( from_node, side );
      tailx = mid_x;
      taily = to_y;
      ctx.line_to( mid_x, from_y );
      ctx.line_to( mid_x, to_y );
      ctx.line_to( to_x,  to_y );
    } else {
      var mid_y = ((from_y + to_y) / 2) + adjust_mid_by( from_node, side );
      tailx = to_x;
      taily = mid_y;
      ctx.line_to( from_x, mid_y );
      ctx.line_to( to_x,   mid_y );
      ctx.line_to( to_x,   to_y );
    }
    ctx.stroke();

  }

}

