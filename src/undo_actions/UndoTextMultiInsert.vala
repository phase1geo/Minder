/*
* Copyright (c) 2020-2025 (https://github.com/phase1geo/Outliner)
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

public struct InsertText {
  int    start;
  string text;
}

public class UndoTextMultiInsert : UndoTextItem {

  private Array<InsertText?> _inserts;

  /* Default constructor */
  public UndoTextMultiInsert( Array<InsertText?> inserts, int start_cursor, int end_cursor ) {
    base( _( "text insertion" ), UndoTextOp.INSERT, start_cursor, end_cursor );
    _inserts = inserts;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo_text( MindMap map, CanvasText ct ) {
    for( int i=0; i<_inserts.length; i++ ) {
      var insert = _inserts.index( i );
      ct.text.remove_text( insert.start, insert.text.length );
    }
    ct.set_cursor_only( start_cursor );
    map.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo_text( MindMap map, CanvasText ct ) {
    for( int i=(int)(_inserts.length - 1); i>=0; i-- ) {
      var insert = _inserts.index( i );
      ct.text.insert_text( insert.start, insert.text );
    }
    ct.set_cursor_only( end_cursor );
    map.queue_draw();
  }

}
