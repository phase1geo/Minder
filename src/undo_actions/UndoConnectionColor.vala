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
using Gdk;

public class UndoConnectionColor : UndoItem {

  Connection _conn;
  RGBA?      _old_color;
  RGBA?      _new_color;

  /* Constructor for a node name change */
  public UndoConnectionColor( Connection c, RGBA? old_color ) {
    base( _( "connection color change" ) );
    _conn      = c;
    _old_color = old_color;
    _new_color = c.color;
  }

  /* Undoes a node name change */
  public override void undo( DrawArea da ) {
    _conn.color = _old_color;
    da.queue_draw();
    da.current_changed( da );
    da.auto_save();
  }

  /* Redoes a node name change */
  public override void redo( DrawArea da ) {
    _conn.color = _new_color;
    da.queue_draw();
    da.current_changed( da );
    da.auto_save();
  }

}
