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

using Gtk;

public class UndoNodeDetach : UndoItem {

  private Node     _n;
  private Node     _old_parent;
  private NodeSide _old_side;
  private int      _old_index;
  private int      _root_index;

  /* Default constructor */
  public UndoNodeDetach( Node n, int root_index, Node old_parent, NodeSide old_side, int old_index ) {
    base( _( "detach node" ) );
    _n          = n;
    _root_index = root_index;
    _old_parent = old_parent;
    _old_side   = old_side;
    _old_index  = old_index;
  }

  /* Performs an undo operation for this data */
  public override void undo( DrawArea da ) {
    da.animator.add_nodes( "undo detach" );
    da.remove_root( _root_index );
    _old_parent.layout.propagate_side( _n, _old_side );
    _n.attach( _old_parent, _old_index, null, false );
    da.set_current_node( _n );
    da.animator.animate();
    da.queue_draw();
    da.node_changed();
    da.changed();
  }

  /* Performs a redo operation */
  public override void redo( DrawArea da ) {
    da.animator.add_nodes( "redo detach" );
    _n.detach( _old_side );
    da.add_root( _n, _root_index );
    da.set_current_node( _n );
    da.animator.animate();
    da.node_changed();
    da.changed();
  }

}
