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

public class Style {

  public LinkType   link_type        { get; set; default = new LinkTypeStraight() };
  public int        link_width       { get; set; default = 4 };
  public NodeBorder node_border      { get; set; default = new NodeBorderSquared() };
  public int        node_width       { get; set; default = 200 };
  public int        node_borderwidth { get; set; default = 4; };

  public Style() {
    // Not sure what there is to do
  }

  /* Draws the link with the given information, applying the stored styling */
  public void draw_link( Cairo.Context ctx, double fx, double fy, double tx, double ty, bool horizontal ) {
    ctx.set_line_width( link_width );
    link_type.draw( ctx, fx, fy, tx, ty, horizontal );
  }

  /* Draws the border around a node with the given dimensions and stored styling */
  public void draw_background( Cairo.Context ctx, double x, double y, double w, double h, bool horizontal, bool motion ) {
    ctx.set_line_width( node_borderwidth );
    node_border.draw( ctx, x, y, w, h, horizontal );
  }

}
