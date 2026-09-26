/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

public class UndoNodesPriority : UndoItem {

  private Array<Node> _nodes;
  private Array<int>  _old_priorities;
  private int         _new_priority;

  //-------------------------------------------------------------
  // Default constructor
  public UndoNodesPriority( Array<Node> nodes, Array<int> old_priorities, int new_priority ) {
    assert( nodes.length > 0 );
    assert( nodes.length == old_priorities.length );
    base( (new_priority == 0) ? _( "clear priority" ) : _( "set priority" ) );
    _nodes          = nodes;
    _old_priorities = old_priorities;
    _new_priority   = new_priority;
  }

  //-------------------------------------------------------------
  // Performs an undo operation for this data
  public override void undo( MindMap map ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      node.priority = _old_priorities.index( i );
    }
    map.queue_draw();
    map.auto_save();
  }

  //-------------------------------------------------------------
  // Performs a redo operation
  public override void redo( MindMap map ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      node.priority = _new_priority;
    }
    map.queue_draw();
    map.auto_save();
  }

}
