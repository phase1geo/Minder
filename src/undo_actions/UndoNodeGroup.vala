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

public class UndoNodeGroup : UndoItem {

  Node _node;

  /* Constructor for a node group change */
  public UndoNodeGroup( Node n ) {
    base( _( "node group change" ) );
    _node = n;
  }

  public void toggle( MindMap map ) {
    _node.group = !_node.group;
    map.queue_draw();
    map.changed();
  }
  
  /* Undoes a node name change */
  public override void undo( MindMap map ) {
    toggle( map );
  }

  /* Redoes a node name change */
  public override void redo( MindMap map ) {
    toggle( map );
  }

}
