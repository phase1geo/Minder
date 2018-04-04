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

using GLib;

public class UndoBuffer : Object {

  private Array<UndoItem> _undo_buffer;
  private Array<UndoItem> _redo_buffer;

  public signal void buffer_changed();

  /* Default constructor */
  public UndoBuffer() {
    _undo_buffer = new Array<UndoItem>();
    _redo_buffer = new Array<UndoItem>();
  }

  /* Clear the undo/redo buffers */
  public void clear() {
    _undo_buffer.remove_range( 0, _undo_buffer.length );
    _redo_buffer.remove_range( 0, _redo_buffer.length );
    buffer_changed();
  }

  /* Returns true if we can perform an undo action */
  public bool undoable() {
    return( _undo_buffer.length > 0 );
  }

  /* Returns true if we can perform a redo action */
  public bool redoable() {
    return( _redo_buffer.length > 0 );
  }

  /* Performs the next undo action in the buffer */
  public void undo() {
    if( undoable() ) {
      UndoItem item = _undo_buffer.index( _undo_buffer.length - 1 );
      item.undo();
      _undo_buffer.remove_index( _undo_buffer.length - 1 );
      _redo_buffer.append_val( item );
      buffer_changed();
    }
  }

  /* Performs the next redo action in the buffer */
  public void redo() {
    if( redoable() ) {
      UndoItem item = _redo_buffer.index( _redo_buffer.length - 1 );
      item.redo();
      _redo_buffer.remove_index( _redo_buffer.length - 1 );
      _undo_buffer.append_val( item );
      buffer_changed();
    }
  }

  /* Adds a new undo item to the undo buffer.  Clears the redo buffer. */
  public void add_item( UndoItem item ) {
    _undo_buffer.append_val( item );
    _redo_buffer.remove_range( 0, _redo_buffer.length );
    buffer_changed();
  }

}
