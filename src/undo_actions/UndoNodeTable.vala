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

public class UndoNodeTable : UndoItem {

  private Node _node;
  private NodeTable? _old_table;
  private NodeTable? _new_table;

  //-------------------------------------------------------------
  // Stores snapshots before and after a node table edit.
  public UndoNodeTable( MindMap map, Node node, NodeTable? old_table ) {
    base( _( "node table change" ) );
    _node = node;
    _old_table = (old_table == null) ? null : new NodeTable.copy( map, old_table );
    _new_table = (node.table == null) ? null : new NodeTable.copy( map, node.table );
  }

  //-------------------------------------------------------------
  // Applies a table snapshot to the edited node.
  private void change( MindMap map, NodeTable? table ) {
    _node.set_table( (table == null) ? null : new NodeTable.copy( map, table ) );
    map.queue_draw();
    map.current_changed( map );
    map.auto_save();
  }

  //-------------------------------------------------------------
  // Restores the table state from before the edit.
  public override void undo( MindMap map ) {
    change( map, _old_table );
  }

  //-------------------------------------------------------------
  // Restores the table state from after the edit.
  public override void redo( MindMap map ) {
    change( map, _new_table );
  }

}
