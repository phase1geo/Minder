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

public class UndoNodeFoldChanges : UndoItem {

  private Array<Node> _changes;
  private bool        _folded;

  /* Default constructor */
  public UndoNodeFoldChanges( string msg, Array<Node> changes, bool folded ) {
    base( msg );
    _changes = changes;
    _folded  = folded;
  }

  /* Change the fold states of the changed list of nodes to the given value */
  private void change_folds( DrawArea da, bool value ) {
    for( int i=0; i<_changes.length; i++ ) {
      _changes.index( i ).folded = value;
      da.get_layout().handle_update_by_fold( _changes.index( i ) );
    }
    da.queue_draw();
    da.changed();
  }

  /* Undoes a node fold operation */
  public override void undo( DrawArea da ) {
    change_folds( da, !_folded );
  }

  /* Redoes a node fold operation */
  public override void redo( DrawArea da ) {
    change_folds( da, _folded );
  }

}
