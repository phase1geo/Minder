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

public class UndoNodeFold : UndoItem {

  Node _node;
  bool _old_fold;
  bool _new_fold;

  /* Default constructor */
  public UndoNodeFold( Node n, bool new_fold ) {
    base( _( "node change fold" ) );
    _node     = n;
    _old_fold = n.folded;
    _new_fold = new_fold;
  }

  /* Undoes a node fold operation */
  public override void undo( DrawArea da ) {
    _node.folded = _old_fold;
    _node.layout.handle_update_by_fold( _node );
    da.queue_draw();
    da.node_changed();
    da.changed();
  }

  /* Redoes a node fold operation */
  public override void redo( DrawArea da ) {
    _node.folded = _new_fold;
    _node.layout.handle_update_by_fold( _node );
    da.queue_draw();
    da.node_changed();
    da.changed();
  }

}
