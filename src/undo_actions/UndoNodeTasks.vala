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

public class UndoNodeTasks : UndoItem {

  Array<NodeTaskInfo?> _task_info;

  /* Constructor for a node name change */
  public UndoNodeTasks( Array<NodeTaskInfo?> task_info ) {
    base( _( "node task changes" ) );
    _task_info = task_info;
  }

  private void update( MindMap map ) {
    map.animator.add_nodes( map.get_nodes(), false, "UndoNodeTasks update" );
    for( int i=0; i<_task_info.length; i++ ) {
      assert( _task_info.index( i ) != null );
      var node    = _task_info.index( i ).node;
      assert( node != null );
      var enabled = node.task_enabled();
      var done    = node.task_done();
      node.enable_task( _task_info.index( i ).enabled );
      node.set_task_done( _task_info.index( i ).done );
      _task_info.index( i ).enabled = enabled;
      _task_info.index( i ).done    = done;
    }
    map.current_changed( map );
    map.animator.animate();
    map.auto_save();
  }

  /* Undoes a node name change */
  public override void undo( MindMap map ) {
    update( map );
  }

  /* Redoes a node name change */
  public override void redo( MindMap map ) {
    update( map );
  }

}
