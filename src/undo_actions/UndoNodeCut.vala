/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder) *
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

public class UndoNodeCut : UndoItem {

  Node              _node;
  Node?             _parent;
  int               _index;
  Array<Connection> _conns;
  UndoNodeGroups?   _groups;

  /* Default constructor */
  public UndoNodeCut( Node n, int index, Array<Connection> conns, UndoNodeGroups? groups ) {
    base( _( "cut node" ) );
    _node   = n;
    _parent = n.parent;
    _index  = index;
    _conns  = conns;
    _groups = groups;
  }

  /* Undoes a node deletion */
  public override void undo( MindMap map ) {
    map.animator.add_nodes( map.get_nodes(), false, "UndoNodeCut undo" );
    if( _parent == null ) {
      map.model.add_root( _node, _index );
    } else {
      _node.attached = true;
      _node.attach_init( _parent, _index );
    }
    map.set_current_node( _node );
    for( int i=0; i<_conns.length; i++ ) {
      map.model.connections.add_connection( _conns.index( i ) );
    }
    map.groups.apply_undo( _groups );
    map.animator.animate();
    map.auto_save();
  }

  /* Redoes a node deletion */
  public override void redo( MindMap map ) {
    UndoNodeGroups? tmp_groups = null;
    map.animator.add_nodes( map.get_nodes(), true, "undo node redo cut" );
    MinderClipboard.copy_nodes( map );
    if( _parent == null ) {
      map.model.remove_root( _index );
    } else {
      _node.detach( _node.side );
    }
    map.set_current_node( null );
    for( int i=0; i<_conns.length; i++ ) {
      map.connections.remove_connection( _conns.index( i ), false );
    }
    map.groups.remove_node( _node, ref tmp_groups );
    map.animator.animate();
    map.auto_save();
  }

}
