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

public class UndoGroupNote : UndoItem {

  NodeGroup _group;
  string    _old_note;
  string    _new_note;

  /* Constructor for a node name change */
  public UndoGroupNote( NodeGroup g, string old_note ) {
    base( _( "node group note change" ) );
    _group    = g;
    _old_note = old_note;
    _new_note = g.note;
  }

  /* Undoes a node name change */
  public override void undo( DrawArea da ) {
    _group.note = _old_note;
    da.current_changed( da );
    da.auto_save();
  }

  /* Redoes a node name change */
  public override void redo( DrawArea da ) {
    _group.note = _new_note;
    da.current_changed( da );
    da.auto_save();
  }

}
