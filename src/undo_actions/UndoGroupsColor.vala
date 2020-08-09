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

public class UndoGroupsColor : UndoItem {

  private Array<NodeGroup> _groups;
  private Array<RGBA?>     _old_colors;
  private RGBA             _new_color;

  /* Constructor for removing a group */
  public UndoGroupsColor( Array<NodeGroup> groups, RGBA new_color ) {
    base( _( "group color change" ) );
    _groups     = new Array<NodeGroup>();
    _old_colors = new Array<RGBA?>();
    _new_color  = new_color;
    for( int i=0; i<groups.length; i++ ) {
      _groups.append_val( groups.index( i ) );
      _old_colors.append_val( groups.index( i ).color );
    }
  }

  /* Undoes a connection change */
  public override void undo( DrawArea da ) {
    for( int i=0; i<_groups.length; i++ ) {
      _groups.index( i ).color = _old_colors.index( i );
    }
    da.queue_draw();
    da.changed();
  }

  /* Redoes a connection change */
  public override void redo( DrawArea da ) {
    for( int i=0; i<_groups.length; i++ ) {
      _groups.index( i ).color = _new_color;
    }
    da.queue_draw();
    da.changed();
  }

}
