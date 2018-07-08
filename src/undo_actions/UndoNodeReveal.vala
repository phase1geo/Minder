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

public class UndoNodeReveal : UndoItem {

  DrawArea _da;
  Node     _current;
  Node     _node;
  Node     _last;

  /* Default constructor */
  public UndoNodeReveal( DrawArea da, Node n, Node last ) {
    base( _( "node reveal" ) );
    _da      = da;
    _current = _da.get_current_node();
    _node    = n;
    _last    = last;
  }

  /* Performs the reveal/unreveal operation */
  private void set_folds( bool value ) {
    var tmp    = _node.parent;
    var layout = _da.get_layout();
    while( tmp != _last ) {
      tmp.folded = value;
      layout.handle_update_by_fold( tmp );
      tmp = tmp.parent;
    }
  }

  /* Undoes a node reveal operation */
  public override void undo() {
    set_folds( true );
    _da.set_current_node( _current );
    _da.queue_draw();
    _da.changed();
  }

  /* Redoes a node reveal operation */
  public override void redo() {
    set_folds( false );
    _da.set_current_node( _node );
    _da.queue_draw();
    _da.changed();
  }

}
