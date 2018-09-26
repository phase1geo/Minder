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

public class NodeBorderPill : Object, NodeBorder {

  /* Default constructor */
  public NodeBorderPill() {}

  /* Returns the searchable name of the node border */
  public string name() {
    return( "pilled" );
  }

  /* Returns the name of the node border to display (should be translatable) */
  public string display_name() {
    return( _( "Pill-shaped" ) );
  }

  /* Returns the name of the icon */
  public string icon_name() {
    return( "minder-node-border-pill-symbolic" );
  }

  private void draw_common( Cairo.Context ctx, double x, double y, double w, double h ) {
    var d = 5;
    ctx.move_to( (x + d), y );
    ctx.line_to( (x + w - d), y );
    ctx.curve_to( (x + w - d), y, (x + w + d), (y + (h / 2)), (x + w - d), (y + h) );
    ctx.line_to( (x + d), (y + h) );
    ctx.curve_to( (x + d), (y + h), (x - d), (y + (h / 2)), (x + d), y );
  }

  /* Draw method for the node border */
  public void draw_border( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s ) {
    draw_common( ctx, x, y, w, h );
    ctx.stroke();
  }

  /* Draw method for the node fill */
  public void draw_fill( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s ) {
    draw_common( ctx, x, y, w, h );
    ctx.fill();
  }

}

