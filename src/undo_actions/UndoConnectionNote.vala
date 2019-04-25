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

public class UndoConnectionNote : UndoItem {

  Connection _conn;
  string     _old_note;
  string     _new_note;

  /* Constructor for a node name change */
  public UndoConnectionNote( Connection c, string old_note ) {
    base( _( "connection note change" ) );
    _conn     = c;
    _old_note = old_note;
    _new_note = c.note;
  }

  /* Undoes a node name change */
  public override void undo( DrawArea da ) {
    _conn.note = _old_note;
    da.queue_draw();
    da.connection_changed();
    da.changed();
  }

  /* Redoes a node name change */
  public override void redo( DrawArea da ) {
    _conn.note = _new_note;
    da.queue_draw();
    da.connection_changed();
    da.changed();
  }

}
