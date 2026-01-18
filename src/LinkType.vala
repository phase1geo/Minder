/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

public interface LinkType : Object {

  /* Returns the name of the link type */
  public abstract string name();

  /* Returns the display name of the link type (should be a translatable string) */
  public abstract string display_name();

  /* Returns the name of the light-mode link icon */
  public abstract string light_icon_name();

  /* Returns the name of the dark-mode link icon */
  public abstract string dark_icon_name();

  protected double adjust_a( Style style ) {
    return( style.link_arrow ? ((style.link_width / 2) + ((style.node_borderwidth / 2) + 2)) : 0 );
  }

  protected double adjust_tip( Style style ) {
    return( (style.link_width / 2) + 1 );
  }

  /* Provides the midx or midy adjust value */
  protected double adjust_mid_by( Node parent, NodeSide child_side ) {
    if( parent.is_root() ) {
      switch( child_side ) {
        case LEFT   :  return( 0 - (parent.width / 4) );
        case RIGHT  :  return( parent.width / 4 );
        case TOP    :  return( 0 - (parent.height / 4) );
        case BOTTOM :  return( parent.height / 4 );
      }
    }
    return( 0 );
  }

  /* Draw method for the link */
  public abstract void draw( Cairo.Context ctx, Node from_node, Node to_node,
                             double from_x, double from_y, double to_x, double to_y,
                             out double fx, out double fy, out double tx, out double ty );

}

