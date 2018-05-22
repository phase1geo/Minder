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

public class UndoNodeMove : UndoItem {

  private DrawArea _da;
  private Node     _n;
  private NodeSide _old_side;
  private int      _old_index;
  private NodeSide _new_side;
  private int      _new_index;
  private Layout?  _layout;

  /* Default constructor */
  public UndoNodeMove( DrawArea da, Node n, NodeSide old_side, int old_index, Layout l ) {
    base( _( "move node" ) );
    _da        = da;
    _n         = n;
    _old_side  = old_side;
    _old_index = old_index;
    _new_side  = n.side;
    _new_index = n.index();
    _layout    = l;
  }

  /* Performs an undo operation for this data */
  public override void undo() {
    Node parent = _n.parent;
    _n.detach( _new_side, _layout );
    _n.attach( parent, _old_index, _layout );
    _da.queue_draw();
    _da.changed();
  }

  /* Performs a redo operation */
  public override void redo() {
    Node parent = _n.parent;
    _n.detach( _old_side, _layout );
    _n.attach( parent, _new_index, _layout );
    _da.queue_draw();
    _da.changed();
  }

}
