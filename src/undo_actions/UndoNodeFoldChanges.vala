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

  private DrawArea    _da;
  private Array<Node> _changes;
  private bool        _folded;

  /* Default constructor */
  public UndoNodeFoldChanges( DrawArea da, string msg, Array<Node> changes, bool folded ) {
    base( msg );
    _da      = da;
    _changes = changes;
    _folded  = folded;
  }

  /* Change the fold states of the changed list of nodes to the given value */
  private void change_folds( bool value ) {
    for( int i=0; i<_changes.length; i++ ) {
      _changes.index( i ).folded = value;
      _da.get_layout().handle_update_by_fold( _changes.index( i ) );
    }
    _da.queue_draw();
    _da.changed();
  }

  /* Undoes a node fold operation */
  public override void undo() {
    change_folds( !_folded );
  }

  /* Redoes a node fold operation */
  public override void redo() {
    change_folds( _folded );
  }

}
