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

public class UndoTextDelete : UndoTextItem {

  public string             text  { private set; get; }
  public int                start { private set; get; }
  public Array<UndoTagInfo> tags  { private set; get; }

  /* Default constructor */
  public UndoTextDelete( string text, int start, Array<UndoTagInfo> tags, int start_cursor, int end_cursor ) {
    base( _( "text deletion" ), UndoTextOp.DELETE, start_cursor, end_cursor );
    this.text  = text;
    this.start = start;
    this.tags  = tags;
  }

  /* Causes the stored item to be put into the before state */
  public override void undo_text( MindMap map, CanvasText ct ) {
    ct.text.insert_text( start, text );
    ct.text.apply_tags( tags, start );
    ct.set_cursor_only( start_cursor );
    map.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo_text( MindMap map, CanvasText ct ) {
    ct.text.remove_text( start, text.length );
    ct.set_cursor_only( end_cursor );
    map.queue_draw();
  }

  /* Merges the given text item with the current only */
  public override bool merge( CanvasText ct, UndoTextItem item ) {
    if( (end_cursor == item.start_cursor) && (item.op == UndoTextOp.DELETE) ) {
      var delete = item as UndoTextDelete;
      end_cursor = delete.end_cursor;
      text       = delete.text + text;
      start      = delete.start;
      return( true );
    }
    return( false );
  }

}
