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
using Gdk;

public class UndoNodeAddParent : UndoItem {

  private Node _parent;
  private Node _child;

  /* Default constructor */
  public UndoNodeAddParent( Node parent, Node child ) {
    base( _( "add parent node" ) );
    _parent = parent;
    _child  = child;
  }

  /* Performs an undo operation for this data */
  public override void undo( DrawArea da ) {
    var parent = _parent.parent;
    var index  = _parent.index();
    _child.detach( _child.side );
    _parent.detach( _parent.side );
    _child.attach( parent, index, null );
    da.set_current_node( _child );
    da.queue_draw();
    da.changed();
  }

  /* Performs a redo operation */
  public override void redo( DrawArea da ) {
    var parent = _child.parent;
    var index  = _child.index();
    _child.detach( _child.side );
    _parent.attach( parent, index, null );
    _child.attach( _parent, -1, null );
    da.set_current_node( _parent );
    da.queue_draw();
    da.changed();
  }

}
