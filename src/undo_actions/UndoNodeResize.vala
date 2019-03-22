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

public class UndoNodeResize : UndoItem {

  Node _node;
  int  _old_width;
  int  _new_width;

  /* Constructor for a node name change */
  public UndoNodeResize( Node n, int old_width ) {
    base( _( "node resize" ) );
    _node      = n;
    _old_width = old_width;
    _new_width = n.max_width();
  }

  /* Undoes a node name change */
  public override void undo( DrawArea da ) {
    _node.resize( _old_width - _new_width );
    da.queue_draw();
    da.changed();
  }

  /* Redoes a node name change */
  public override void redo( DrawArea da ) {
    _node.resize( _new_width - _old_width );
    da.queue_draw();
    da.changed();
  }

}
