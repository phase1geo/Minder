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

public class LayoutManual : Layout {

  /* Default constructor */
  public LayoutManual() {
    name = _( "Manual" );
    icon = "minder-layout-manual-symbolic";
    balanceable = false;
  }

  /* Initializes this layout */
  public override void initialize( Node parent ) {}

  /* Maps the given side to the appropriate side for this layout */
  public override NodeSide side_mapping( NodeSide side ) {
    return( side );
  }

  /* Adjusts the given tree by the given amount */
  public override void adjust_tree( Node parent, int child_index, int side_mask, double amount ) {}

  /* Adjust the entire tree */
  public override void adjust_tree_all( Node n, double amount ) {}

  /* Updates the layout when necessary when a node is edited */
  public override void handle_update_by_edit( Node n ) {}

  /* Called when a node's fold indicator changes */
  public override void handle_update_by_fold( Node n ) {}

  /* Called when we are inserting a node within a parent */
  // public override void handle_update_by_insert( Node parent, Node child, int pos ) {}

  /* Called to layout the leftover children of a parent node when a node is deleted */
  public override void handle_update_by_delete( Node parent, int index, NodeSide side, double size ) {}

}
