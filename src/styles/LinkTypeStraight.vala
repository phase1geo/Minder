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

public class LinkTypeStraight : Object, LinkType {

  /* Default constructor */
  public LinkTypeStraight() {}

  /* Returns the search name */
  public string name() {
    return( "straight" );
  }

  /* Returns the name of the link type */
  public string display_name() {
    return( _( "Straight" ) );
  }

  /* Returns the name of the icon */
  public string icon_name() {
    return( "minder-link-straight-symbolic" );
  }

  private double adjust_b( NodeSide side, double adjust, double x, double y ) {
    switch( side ) {
      case NodeSide.LEFT   :  return( (adjust * y) / x );
      case NodeSide.RIGHT  :  return( (adjust * y) / x );
      case NodeSide.TOP    :  return( (adjust * x) / y );
      case NodeSide.BOTTOM :  return( (adjust * x) / y );
    }
    return( 0 );
  }

  private double calc_to_x( Node to_node, double from, double adjusted, double adjustA ) {
    if( from < adjusted ) {
      if( (to_node.posx - adjustA) >= adjusted ) {
        return( to_node.posx - adjustA );
      }
    } else if( (to_node.posx + to_node.width + adjustA) <= adjusted ) {
      return( to_node.posx + to_node.width + adjustA );
    }
    return( adjusted );
  }

  private double calc_to_y( Node to_node, double from, double adjusted, double adjustA ) {
    if( from < adjusted ) {
      if( (to_node.posy - adjustA) >= adjusted ) {
        return( to_node.posy - adjustA );
      }
    } else if( (to_node.posy + to_node.height + adjustA) <= adjusted ) {
      return( to_node.posy + to_node.height + adjustA );
    }
    return( adjusted );
  }

  /* Draw method for the link */
  public void draw( Cairo.Context ctx, Node to_node,
                    double from_x, double from_y, double to_x, double to_y,
                    out double tailx, out double taily, out double tipx, out double tipy ) {

    var style   = to_node.style;
    var side    = to_node.side;
    var x       = (to_x - from_x);
    var y       = (to_y - from_y);
    var adjustA = adjust_a( style );
    var adjustB = style.link_arrow ? adjust_b( side, adjustA, x, y ) : 0;
    var adjustT = adjust_tip( style );

    tipx = tipy = 0;

    switch( side ) {
      case NodeSide.LEFT   :  to_x += adjustA;  to_y = calc_to_y( to_node, from_y, (to_y + adjustB), adjustA );  tipx = to_x - adjustT;  tipy = calc_to_y( to_node, from_y, (to_y - adjust_b( side, adjustT, x, y )), adjustT );  break;
      case NodeSide.RIGHT  :  to_x -= adjustA;  to_y = calc_to_y( to_node, from_y, (to_y - adjustB), adjustA );  tipx = to_x + adjustT;  tipy = calc_to_y( to_node, from_y, (to_y + adjust_b( side, adjustT, x, y )), adjustT );  break;
      case NodeSide.TOP    :  to_y += adjustA;  to_x = calc_to_x( to_node, from_x, (to_x + adjustB), adjustA );  tipy = to_y - adjustT;  tipx = calc_to_x( to_node, from_x, (to_x - adjust_b( side, adjustT, x, y )), adjustT );  break;
      case NodeSide.BOTTOM :  to_y -= adjustA;  to_x = calc_to_x( to_node, from_x, (to_x - adjustB), adjustA );  tipy = to_y + adjustT;  tipx = calc_to_x( to_node, from_x, (to_x + adjust_b( side, adjustT, x, y )), adjustT );  break;
    }

    ctx.move_to( from_x, from_y );
    ctx.line_to( to_x,   to_y );
    ctx.stroke();

    tailx = from_x;
    taily = from_y;

  }

}

