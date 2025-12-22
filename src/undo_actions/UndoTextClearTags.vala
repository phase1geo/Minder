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

public class UndoTextClearTags : UndoTextItem {

  public int                start { private set; get; }
  public int                end   { private set; get; }
  public Array<UndoTagInfo> tags  { private set; get; }

  //-------------------------------------------------------------
  // Default constructor.
  public UndoTextClearTags( int start, int end, Array<UndoTagInfo> tags, int cursor ) {
    base( _( "clear formatting" ), UndoTextOp.TAGCLEAR, cursor, cursor );
    this.start = start;
    this.end   = end;
    this.tags  = tags;
  }

  //-------------------------------------------------------------
  // Causes the stored item to be put into the before state.
  public override void undo_text( MindMap map, CanvasText ct ) {
    ct.text.apply_tags( tags, start );
    map.queue_draw();
  }

  /* Causes the stored item to be put into the after state */
  public override void redo_text( MindMap map, CanvasText ct ) {
    ct.text.remove_all_tags( start, end );
    map.queue_draw();
  }

  /* Merges the given item with the current one */
  public override bool merge( CanvasText ct, UndoTextItem item ) {
    return( false );
  }

}
