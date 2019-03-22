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

public class UndoNodeDelete : UndoItem {

  Node  _node;
  Node? _parent;
  int   _index;

  /* Default constructor */
  public UndoNodeDelete( Node n ) {
    base( _( "delete node" ) );
    _node   = n;
    _parent = n.parent;
    _index  = n.index();
  }

  /* Undoes a node deletion */
  public override void undo( DrawArea da ) {
    if( _parent == null ) {
      da.add_root( _node, _index );
    } else {
      _node.attached = true;
      _node.attach( _parent, _index, null );
    }
    da.set_current_node( _node );
    da.queue_draw();
    da.node_changed();
    da.changed();
  }

  /* Redoes a node deletion */
  public override void redo( DrawArea da ) {
    if( _parent == null ) {
      da.remove_root( _index );
    } else {
      _node.detach( _node.side );
    }
    da.set_current_node( null );
    da.queue_draw();
    da.node_changed();
    da.changed();
  }

}
