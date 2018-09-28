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
  public void draw( Cairo.Context ctx, double from_x, double from_y, double to_x, double to_y, bool horizontal,
                    out double fx, out double fy, out double tx, out double ty ) {
    ctx.move_to( from_x, from_y );
    if( horizontal ) {
      var x_adjust = (to_x - from_x) * 0.5;
      fx = to_x - x_adjust;
      fy = from_y;
      tx = from_x + x_adjust;
      ty = to_y;
      ctx.curve_to( fx, fy, tx, ty, to_x, to_y );
    } else {
      var y_adjust = (to_y - from_y) * 0.5;
      fx = from_x;
      fy = to_y - y_adjust;
      tx = to_x;
      ty = from_y + y_adjust;
      ctx.curve_to( fx, fy, tx, ty, to_x, to_y );
    }
    ctx.stroke();
  }

}

