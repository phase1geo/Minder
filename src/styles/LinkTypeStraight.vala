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

  /* Draw method for the link */
  public void draw( Cairo.Context ctx, double from_x, double from_y, double to_x, double to_y, bool horizontal,
                    out double fx, out double fy, out double tx, out double ty ) {
    fx = from_x;
    fy = from_y;
    tx = to_x;
    ty = to_y;
    ctx.move_to( from_x, from_y );
    ctx.line_to( to_x,   to_y );
    ctx.stroke();
  }

}

