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

public class LinkSquared : Object, Link {

  /* Default constructor */
  public LinkSquared() {}

  /* Returns the name of the link type */
  public string name() {
    return( _( "Squared" ) );
  }

  /* Returns the name of the icon */
  public string icon_name() {
    return( "minder-link-squared-symbolic" );
  }

  /* Draw method for the link */
  public void draw( Cairo.Context ctx, double from_x, double from_y, double to_x, double to_y, bool horizontal ) {
    ctx.move_to( from_x, from_y );
    if( horizontal ) {
      var mid_x = (from_x + to_x) / 2;
      ctx.line_to( mid_x, from_y );
      ctx.line_to( mid_x, to_y );
      ctx.line_to( to_x,  to_y );
    } else {
      var mid_y = (from_y + to_y) / 2;
      ctx.line_to( from_x, mid_y );
      ctx.line_to( to_x,   mid_y );
      ctx.line_to( to_x,   to_y );
    }
    ctx.stroke();
  }

}

