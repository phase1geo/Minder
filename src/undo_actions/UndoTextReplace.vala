/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/Outliner)
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

public class UndoTextReplace : UndoTextItem {

  public string             orig_text { private set; get; }
  public string             new_text  { private set; get; }
  public int                start     { private set; get; }
  public Array<UndoTagInfo> tags      { private set; get; }

  /* Default constructor */
  public UndoTextReplace( string orig_text, string new_text, int start, Array<UndoTagInfo> tags, int start_cursor, int end_cursor ) {
    base( _( "text replacement" ), UndoTextOp.REPLACE, start_cursor, end_cursor );
    this.orig_text = orig_text;
    this.new_text  = new_text;
    this.start     = start;
    this.tags      = tags;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo_text( MindMap map, CanvasText ct ) {
    ct.text.replace_text( start, new_text.length, orig_text );
    ct.text.apply_tags( tags, start );
    ct.set_cursor_only( start_cursor );
    map.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo_text( MindMap map, CanvasText ct ) {
    ct.text.replace_text( start, orig_text.length, new_text );
    ct.set_cursor_only( end_cursor );
    map.queue_draw();
  }

  /* Merges the given item with this item, if possible */
  public override bool merge( CanvasText ct, UndoTextItem item ) {
    if( (end_cursor == item.start_cursor) && (item.op == UndoTextOp.INSERT) ) {
      var insert = item as UndoTextInsert;
      new_text  += insert.text;
      end_cursor = insert.end_cursor;
      return( true );
    }
    return( false );
  }

}
