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

public class UndoNodeTask : UndoItem {

  Node _node;
  bool _old_enable;
  bool _old_done;
  bool _new_enable;
  bool _new_done;

  /* Constructor for a node name change */
  public UndoNodeTask( Node n, bool new_enable, bool new_done ) {
    base( _( "node task change" ) );
    _node       = n;
    _old_enable = n.task_enabled();
    _old_done   = n.task_done();
    _new_enable = new_enable;
    _new_done   = new_done;
  }

  /* Undoes a node name change */
  public override void undo( DrawArea da ) {
    if( _old_enable != _new_enable ) {
      _node.enable_task( _old_enable );
    } else {
      _node.set_task_done( _old_done );
    }
    da.queue_draw();
    da.current_changed( da );
    da.auto_save();
  }

  /* Redoes a node name change */
  public override void redo( DrawArea da ) {
    if( _old_enable != _new_enable ) {
      _node.enable_task( _new_enable );
    } else {
      _node.set_task_done( _new_done );
    }
    da.queue_draw();
    da.current_changed( da );
    da.auto_save();
  }

}
