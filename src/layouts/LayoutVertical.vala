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

public class LayoutVertical : Layout {

  /* Default constructor */
  public LayoutVertical() {
    name        = _( "Vertical" );
    light_icon  = "minder-layout-vertical-light-symbolic";
    dark_icon   = "minder-layout-vertical-dark-symbolic";
    balanceable = true;
  }

  /* Maps the given side to the appropriate side for this layout */
  public override NodeSide side_mapping( NodeSide side ) {
    switch( side ) {
      case NodeSide.LEFT   :  return( NodeSide.TOP );
      case NodeSide.RIGHT  :  return( NodeSide.BOTTOM );
      case NodeSide.TOP    :  return( NodeSide.TOP );
      case NodeSide.BOTTOM :  return( NodeSide.BOTTOM );
    }
    return( NodeSide.BOTTOM );
  }

}
