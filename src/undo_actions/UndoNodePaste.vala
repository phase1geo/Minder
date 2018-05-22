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

public class UndoNodePaste : UndoItem {

  private DrawArea _da;
  private Node?    _parent;
  private Node     _n;
  private int      _index;
  private Layout?  _layout;

  /* Default constructor */
  public UndoNodePaste( DrawArea da, Node n, Layout l ) {
    base( _( "paste node" ) );
    _da     = da;
    _n      = n;
    _index  = n.index();
    _parent = n.parent;
    _layout = l;
  }

  /* Performs an undo operation for this data */
  public override void undo() {
    _n.detach( _n.side, _layout );
    _da.queue_draw();
    _da.changed();
  }

  /* Performs a redo operation */
  public override void redo() {
    _n.attach( _parent, _index, _layout );
    _da.queue_draw();
    _da.changed();
  }

}
