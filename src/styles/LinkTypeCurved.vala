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

public class LinkTypeCurved : Object, LinkType {

  /* Default constructor */
  public LinkTypeCurved() {}

  /* Returns the search name */
  public string name() {
    return( "curved" );
  }

  /* Returns the name of the link type */
  public string display_name() {
    return( _( "Curved" ) );
  }

  /* Returns the name of the icon */
  public string icon_name() {
    return( "minder-link-curved-symbolic" );
  }

  /* Draw method for the link */
  public void draw( Cairo.Context ctx, Node to_node,
                    double from_x, double from_y, double to_x, double to_y,
                    out double tailx, out double taily, out double tipx, out double tipy ) {

    var side  = to_node.side;
    var style = to_node.style;

    tipx = tipy = 0;

    switch( side ) {
      case NodeSide.LEFT   :  to_x += adjust_a( style );  tipx = to_x - adjust_tip( style );  tipy = to_y;  break;
      case NodeSide.RIGHT  :  to_x -= adjust_a( style );  tipx = to_x + adjust_tip( style );  tipy = to_y;  break;
      case NodeSide.TOP    :  to_y += adjust_a( style );  tipx = to_x;  tipy = to_y - adjust_tip( style );  break;
      case NodeSide.BOTTOM :  to_y -= adjust_a( style );  tipx = to_x;  tipy = to_y + adjust_tip( style );  break;
    }

    ctx.move_to( from_x, from_y );
    if( (side & NodeSide.horizontal()) != 0 ) {
      var x_adjust = (to_x - from_x) * 0.5;
      tailx = from_x + x_adjust;
      taily = from_y + ((to_y - from_y) * 0.95);
      ctx.curve_to( (to_x - x_adjust), from_y, (from_x + x_adjust), to_y, to_x, to_y );
    } else {
      var y_adjust = (to_y - from_y) * 0.5;
      tailx = from_x + ((to_x - from_x) * 0.95);
      taily = from_y + y_adjust;
      ctx.curve_to( from_x, (to_y - y_adjust), to_x, (from_y + y_adjust), to_x, to_y );
    }
    ctx.stroke();

  }

}

