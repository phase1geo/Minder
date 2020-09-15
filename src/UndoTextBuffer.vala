/*
* Copyright (c) 2020 (https://github.com/phase1geo/Outliner)
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

using GLib;

public class UndoTextBuffer : UndoBuffer {

  public CanvasText? ct        { set; get; default = null; }
  public CanvasText  orig      { private set; get; }
  public bool        mergeable { set; get; default = true; }
  public bool        do_undo   { set; get; default = true; }

  /* Default constructor */
  public UndoTextBuffer( DrawArea da ) {
    base( da );
    orig = new CanvasText( da );
  }

  /*
   Checks to see if the given item is mergeable with the last item in the buffer.
   If it is mergeable, merge it and return true; otherwise, return false.
  */
  private bool merge_with_last( UndoTextItem item ) {
    if( (_undo_buffer.length > 0) && (_redo_buffer.length == 0) && mergeable ) {
      return( (_undo_buffer.index( _undo_buffer.length - 1 ) as UndoTextItem).merge( ct, item ) );
    }
    mergeable = true;
    return( false );
  }

  /* Call after text has been inserted */
  public void add_insert( int start, string text, int start_cursor ) {
    var item = new UndoTextInsert( text, start, start_cursor, ct.cursor );
    if( !merge_with_last( item ) ) {
      add_item( item );
    }
  }

  /* Call after multiple pieces of text have been inserted */
  public void add_inserts( Array<InsertText?> its, int start_cursor ) {
    var item = new UndoTextMultiInsert( its, start_cursor, ct.cursor );
    if( !merge_with_last( item ) ) {
      add_item( item );
    }
  }

  /* Call after text has been deleted */
  public void add_delete( int start, string orig_text, Array<UndoTagInfo>? tags, int start_cursor ) {
    var item = new UndoTextDelete( orig_text, start, tags, start_cursor, ct.cursor );
    if( !merge_with_last( item ) ) {
      add_item( item );
    }
  }

  /* Call after text has been replaced */
  public void add_replace( int start, string orig_text, string text, Array<UndoTagInfo>? tags, int start_cursor ) {
    var item = new UndoTextReplace( orig_text, text, start, tags, start_cursor, ct.cursor );
    if( !merge_with_last( item ) ) {
      add_item( item );
    }
  }

  /* Call after tag has been applied to text */
  public void add_tag_add( int start, int end, FormatTag tag, string? extra, int cursor ) {
    var item = new UndoTextTagAdd( start, end, tag, extra, cursor );
    add_item( item );
  }

  /* Call after tag has been removed from text */
  public void add_tag_remove( int start, int end, FormatTag tag, string? extra, int cursor ) {
    var item = new UndoTextTagRemove( start, end, tag, extra, cursor );
    add_item( item );
  }

  public void add_tag_clear( int start, int end, Array<UndoTagInfo> tags, int cursor ) {
    var item = new UndoTextClearTags( start, end, tags, cursor );
    add_item( item );
  }

  /* Performs the next undo action in the buffer */
  public override void undo() {
    if( undoable() ) {
      UndoItem item = _undo_buffer.index( _undo_buffer.length - 1 );
      (item as UndoTextItem).undo_text( _da, ct );
      _undo_buffer.remove_index( _undo_buffer.length - 1 );
      _redo_buffer.append_val( item );
      mergeable = false;
      buffer_changed( this );
    }
  }

  /* Performs the next redo action in the buffer */
  public override void redo() {
    if( redoable() ) {
      UndoItem item = _redo_buffer.index( _redo_buffer.length - 1 );
      (item as UndoTextItem).redo_text( _da, ct );
      _redo_buffer.remove_index( _redo_buffer.length - 1 );
      _undo_buffer.append_val( item );
      mergeable = false;
      buffer_changed( this );
    }
  }
}
