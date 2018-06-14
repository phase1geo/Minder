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

  private DrawArea _da;
  private Node     _n;
  private Node     _old_parent;
  private NodeSide _old_side;
  private int      _old_index;
  private int      _root_index;
  private Layout?  _layout;

  /* Default constructor */
  public UndoNodeDetach( DrawArea da, Node n, int root_index, Node old_parent, NodeSide old_side, int old_index, Layout l ) {
    base( _( "detach node" ) );
    _da         = da;
    _n          = n;
    _root_index = root_index;
    _old_parent = old_parent;
    _old_side   = old_side;
    _old_index  = old_index;
    _layout     = l;
  }

  /* Performs an undo operation for this data */
  public override void undo() {
    _da.animator.add_nodes( "undo detach" );
    _da.remove_root( _root_index );
    _n.attach( _old_parent, _old_index, null, _layout );
    _da.set_current_node( _n );
    _da.animator.animate();
    _da.queue_draw();
    _da.node_changed();
    _da.changed();
  }

  /* Performs a redo operation */
  public override void redo() {
    _da.animator.add_nodes( "redo detach" );
    _n.detach( _old_side, _layout );
    _da.add_root( _n, _root_index );
    _da.set_current_node( _n );
    _da.animator.animate();
    _da.node_changed();
    _da.changed();
  }

}
