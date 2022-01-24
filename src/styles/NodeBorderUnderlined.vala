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

public class NodeBorderUnderlined : Object, NodeBorder {

  /* Default constructor */
  public NodeBorderUnderlined() {}

  /* Search name of this instance */
  public string name() {
    return( "underlined" );
  }

  /* Returns the name of the link type */
  public string display_name() {
    return( _( "Underlined" ) );
  }

  /* Returns the name of the icon */
  public string icon_name() {
    return( "minder-node-border-underlined-symbolic" );
  }

  /* Indicate that this border is not fillable */
  public bool is_fillable() {
    return( false );
  }

  /* Draw method for the link */
  public void draw_border( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s, int padding ) {
    ctx.move_to( x, (y + h) );
    ctx.line_to( (x + w), (y + h) );
    ctx.stroke();
  }

  /* Draw method for the fill */
  public void draw_fill( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s, int padding ) {
    ctx.rectangle( x, y, w, h );
    ctx.fill();
  }

}

