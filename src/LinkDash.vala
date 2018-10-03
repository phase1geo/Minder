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

public class LinkDash : Object {

  public string   name;
  public string   display_name;
  public double[] pattern;

  /* Default constructor */
  public LinkDash( string name, string display_name, double[] pattern ) {

    this.name         = name;
    this.display_name = display_name;
    this.pattern      = pattern;

  }
 
  /* Makes an icon for the given dash */
  public Cairo.Surface make_icon() {

    Cairo.ImageSurface surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, 100, 20 );
    Cairo.Context      ctx     = new Cairo.Context( surface );

    ctx.set_source_rgba( 0.5, 0.5, 0.5, 1 );
    ctx.set_dash( pattern, 0 );
    ctx.set_line_width( 4 );
    ctx.set_line_cap( LineCap.ROUND );
    ctx.move_to( 10, 10 );
    ctx.line_to( 90, 10 );
    ctx.stroke();

    return( surface );

  }

  /* Sets the given context for the dash information */
  public void set_context( Cairo.Context ctx, int line_width ) {

    double[] adjusted_pattern = {};
    int      i                = 0;

    foreach( double val in pattern ) {
      if( i == 0 ) {
        adjusted_pattern += val;
      } else {
        adjusted_pattern += (line_width + val);
      }
      i++;
    }

    ctx.set_dash( adjusted_pattern, 0 );

  }

}

