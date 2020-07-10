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

public class UndoConnectionTitle : UndoItem {

  Connection _conn;
  string?    _old_title;
  string?    _new_title;

  /* Constructor for a connection title change */
  public UndoConnectionTitle( Connection c, string? old_title ) {
    base( _( "connection title change" ) );
    _conn      = c;
    _old_title = old_title;
    _new_title = (c.title == null) ? null : c.title.text.text;
  }

  private void change( DrawArea da, string? title ) {
    _conn.change_title( da, title );
    da.queue_draw();
    da.current_changed( da );
    da.changed();
  }

  /* Undoes a connection title change */
  public override void undo( DrawArea da ) {
    change( da, _old_title );
  }

  /* Redoes a connection title change */
  public override void redo( DrawArea da ) {
    change( da, _new_title );
  }

}
