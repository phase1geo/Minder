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
    name        = _( "Manual" );
    light_icon  = "minder-layout-manual-light-symbolic";
    dark_icon   = "minder-layout-manual-dark-symbolic";
    balanceable = false;
  }

  /* Initializes this layout */
  public override void initialize( Node parent ) {}

  /* Maps the given side to the appropriate side for this layout */
  public override NodeSide side_mapping( NodeSide side ) {
    return( side );
  }

  /* Updates the tree boundaries */
  private void update_tree( Node n ) {
    update_tree_size( n );
    while( n.parent != null ) {
      update_tree_size( n.parent );
      n = n.parent;
    }
  }

  /* Updates the layout when necessary when a node is edited */
  public override void handle_update_by_edit( Node n, double diffw, double diffh ) {
    update_tree( n );
  }

  /* Called when a node's fold indicator changes */
  public override void handle_update_by_fold( Node n ) {
    update_tree( n );
  }

  /* Called when we are inserting a node within a parent */
  public override void handle_update_by_insert( Node parent, Node child, int pos ) {
    if( !child.attached ) {
      base.handle_update_by_insert( parent, child, pos );
    } else {
      update_tree( child );
    }
  }

  /* Called to layout the leftover children of a parent node when a node is deleted */
  public override void handle_update_by_delete( Node parent, int index, NodeSide side, double size ) {
    update_tree( parent );
  }

}
