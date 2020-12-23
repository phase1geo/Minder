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

  Node _current;
  Node _node;
  Node _last;

  /* Default constructor */
  public UndoNodeReveal( DrawArea da, Node n, Node last ) {
    base( _( "node reveal" ) );
    _current = da.get_current_node();
    _node    = n;
    _last    = last;
  }

  /* Performs the reveal/unreveal operation */
  private void set_folds( DrawArea da, bool value ) {
    var tmp = _node.parent;
    while( tmp != _last ) {
      tmp.set_fold_only( value );
      tmp = tmp.parent;
    }
  }

  /* Undoes a node reveal operation */
  public override void undo( DrawArea da ) {
    set_folds( da, true );
    da.set_current_node( _current );
    da.queue_draw();
    da.changed();
  }

  /* Redoes a node reveal operation */
  public override void redo( DrawArea da ) {
    set_folds( da, false );
    da.set_current_node( _node );
    da.queue_draw();
    da.changed();
  }

}
