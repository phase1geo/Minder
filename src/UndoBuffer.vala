/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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

  protected MindMap         _map;
  protected Array<UndoItem> _undo_buffer;
  protected Array<UndoItem> _redo_buffer;
  private   bool            _debug = false;
  private   static int      _current_id = 0;

  public signal void buffer_changed( UndoBuffer buf );

  /* Default constructor */
  public UndoBuffer( MindMap map ) {
    _map         = map;
    _undo_buffer = new Array<UndoItem>();
    _redo_buffer = new Array<UndoItem>();
  }

  /* Clear the undo/redo buffers */
  public void clear() {
    _undo_buffer.remove_range( 0, _undo_buffer.length );
    _redo_buffer.remove_range( 0, _redo_buffer.length );
    buffer_changed( this );
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
  public virtual void undo() {
    if( undoable() ) {
      UndoItem item = _undo_buffer.index( _undo_buffer.length - 1 );
      item.undo( _map );
      _undo_buffer.remove_index( _undo_buffer.length - 1 );
      _redo_buffer.append_val( item );
      buffer_changed( this );
    }
    output( "AFTER UNDO" );
  }

  /* Performs the next redo action in the buffer */
  public virtual void redo() {
    if( redoable() ) {
      UndoItem item = _redo_buffer.index( _redo_buffer.length - 1 );
      item.redo( _map );
      _redo_buffer.remove_index( _redo_buffer.length - 1 );
      _undo_buffer.append_val( item );
      buffer_changed( this );
    }
    output( "AFTER REDO" );
  }

  /* Returns the undo tooltip */
  public string undo_tooltip() {
    if( _undo_buffer.length == 0 ) return( _( "Undo" ) );
    return( _( "Undo " ) + _undo_buffer.index( _undo_buffer.length - 1 ).name );
  }

  /* Returns the undo tooltip */
  public string redo_tooltip() {
    if( _redo_buffer.length == 0 ) return( _( "Redo" ) );
    return( _( "Redo " ) + _redo_buffer.index( _redo_buffer.length - 1 ).name );
  }

  /* Adds a new undo item to the undo buffer.  Clears the redo buffer. */
  public void add_item( UndoItem item ) {
    item.id = _current_id++;
    _undo_buffer.append_val( item );
    _redo_buffer.remove_range( 0, _redo_buffer.length );
    buffer_changed( this );
    output( "ITEM ADDED" );
  }

  /*
   Attempts to replace the last item in the undo buffer with the given item if both items are the same type;
   otherwise, the new item will just be added like any other item.
  */
  public void replace_item( UndoItem item ) {
    item.id = _current_id++;
    if( _undo_buffer.length > 0 ) {
      UndoItem last = _undo_buffer.index( _undo_buffer.length - 1 );
      if( (last.get_type() == item.get_type()) && last.matches( item ) ) {
        last.replace_with_item( item );
        buffer_changed( this );
        output( "ITEM REPLACED" );
        return;
      }
    }
    add_item( item );
  }

  /* Outputs the state of the undo and redo buffers to standard output */
  public void output( string msg = "BUFFER STATE" ) {
    if( _debug ) {
      stdout.printf( "%s\n  Undo Buffer\n-----------\n", msg );
      for( int i=0; i<_undo_buffer.length; i++ ) {
        stdout.printf( "    %s\n", _undo_buffer.index( i ).to_string() );
      }
      stdout.printf( "  Redo Buffer\n-----------\n" );
      for( int i=0; i<_redo_buffer.length; i++ ) {
        stdout.printf( "    %s\n", _redo_buffer.index( i ).to_string() );
      }
    }
  }

}
