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

public class NodeBorderRounded : Object, NodeBorder {

  /* Default constructor */
  public NodeBorderRounded() {}

  /* Returns the searchable name of the node border */
  public string name() {
    return( "rounded" );
  }

  /* Returns the name of the node border to display (should be translatable) */
  public string display_name() {
    return( _( "Rounded Rectangle" ) );
  }

  /* Returns the name of the light-mode icon */
  public string light_icon_name() {
    return( "minder-node-border-rounded-light-symbolic" );
  }

  /* Returns the name of the dark-mode icon */
  public string? dark_icon_name() {
    return( "minder-node-border-rounded-dark-symbolic" );
  }

  /* Indicate that this node is fillable */
  public bool is_fillable() {
    return( true );
  }

  /* Draw method for the node border */
  public void draw_border( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s, int padding ) {
    Utils.draw_rounded_rectangle( ctx, x, y, w, h, padding );
    ctx.stroke();
  }

  /* Draw method for the node fill */
  public void draw_fill( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s, int padding ) {
    Utils.draw_rounded_rectangle( ctx, x, y, w, h, padding );
    ctx.fill();
  }

}

