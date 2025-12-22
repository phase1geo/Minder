/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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

public class UndoNodeSummaryDelete : UndoItem {

  SummaryNode       _node;
  Array<Connection> _conns;
  UndoNodeGroups?   _groups;

  /* Default constructor */
  public UndoNodeSummaryDelete( SummaryNode n, Array<Connection> conns, UndoNodeGroups? groups ) {
    base( _( "delete summary node" ) );
    _node   = n;
    _conns  = conns;
    _groups = groups;
  }

  /* Undoes a node deletion */
  public override void undo( MindMap map ) {
    _node.attach_all();
    map.set_current_node( _node );
    for( int i=0; i<_conns.length; i++ ) {
      map.connections.add_connection( _conns.index( i ) );
    }
    map.groups.apply_undo( _groups );
    map.queue_draw();
    map.auto_save();
  }

  /* Redoes a node deletion */
  public override void redo( MindMap map ) {
    UndoNodeGroups? tmp_groups = null;
    _node.detach_all();
    map.set_current_node( null );
    for( int i=0; i<_conns.length; i++ ) {
      map.connections.remove_connection( _conns.index( i ), false );
    }
    map.groups.remove_node( _node, ref tmp_groups );
    map.queue_draw();
    map.auto_save();
  }

}
