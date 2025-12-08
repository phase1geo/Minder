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

public class UndoGroupsMerge : UndoItem {

  private Array<NodeGroup> _groups;
  private NodeGroup        _merged;

  /* Constructor for removing a group */
  public UndoGroupsMerge( Array<NodeGroup> groups, NodeGroup merged ) {
    base( _( "group merge" ) );
    _groups = new Array<NodeGroup>();
    _merged = merged;
    for( int i=0; i<groups.length; i++ ) {
      _groups.append_val( groups.index( i ) );
    }
  }

  /* Undoes a connection change */
  public override void undo( MindMap map ) {
    map.selected.clear();
    map.groups.remove_group( _merged );
    for( int i=0; i<_groups.length; i++ ) {
      map.groups.add_group( _groups.index( i ) );
      map.selected.add_group( _groups.index( i ) );
    }
    map.queue_draw();
    map.auto_save();
  }

  /* Redoes a connection change */
  public override void redo( MindMap map ) {
    map.selected.clear();
    for( int i=0; i<_groups.length; i++ ) {
      map.groups.remove_group( _groups.index( i ) );
    }
    map.groups.add_group( _merged );
    map.selected.add_group( _merged );
    map.queue_draw();
    map.auto_save();
  }

}
