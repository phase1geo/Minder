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

public class LayoutDown : Layout {

  /* Default constructor */
  public LayoutDown() {
    name = _( "Downwards" );
    icon = "minder-layout-down-symbolic";
    balanceable = false;
  }

  /* Maps the given side to the new side */
  public override NodeSide side_mapping( NodeSide side ) {
    return( NodeSide.BOTTOM );
  }

  /* The side should always be set to bottom */
  public override void set_side( Node current ) {
    current.side = NodeSide.BOTTOM;
  }

}
