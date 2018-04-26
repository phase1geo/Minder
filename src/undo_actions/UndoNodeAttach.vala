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

public class UndoNodeAttach : UndoItem {

  private DrawArea _da;
  private Node     _n;
  private Node     _old_parent;
  private NodeSide _old_side;
  private int      _old_index;
  private Node     _new_parent;
  private NodeSide _new_side;
  private int      _new_index;
  private Layout?  _layout;

  /* Default constructor */
  public UndoNodeAttach( DrawArea da, Node n, Node old_parent, NodeSide old_side, int old_index, Layout l ) {
    base( _( "attach node" ) );
    _da         = da;
    _n          = n;
    _old_parent = old_parent;
    _old_side   = old_side;
    _old_index  = old_index;
    _new_parent = n.parent;
    _new_side   = n.side;
    _new_index  = n.index();
    _layout     = l;
  }

  /* Performs an undo operation for this data */
  public override void undo() {
    _n.detach( _new_side, _layout );
    _n.attach( _old_parent, _old_index, _layout );
    _da.queue_draw();
  }

  /* Performs a redo operation */
  public override void redo() {
    _n.detach( _old_side, _layout );
    _n.attach( _new_parent, _new_index, _layout );
    _da.queue_draw();
  }

}
