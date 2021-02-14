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

public class UndoNodesLink : UndoItem {

  Array<Node>  _nodes;
  Array<Node?> _linked;

  /* Constructor for a node name change */
  public UndoNodesLink( Array<Node> nodes ) {
    base( _( "node link changes" ) );
    _nodes  = new Array<Node>();
    _linked = new Array<Node>();
    for( int i=0; i<nodes.length; i++ ) {
      _nodes.append_val( nodes.index( i ) );
      _linked.append_val( nodes.index( i ).linked_node );
    }
  }

  /* Undoes a node image change */
  public override void undo( DrawArea da ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).linked_node = _linked.index( i );
    }
    da.queue_draw();
    da.auto_save();
  }

  /* Redoes a node image change */
  public override void redo( DrawArea da ) {
    for( int i=0; i<(_nodes.length - 1); i++ ) {
      _nodes.index( i ).linked_node = _nodes.index( i + 1 );
    }
    da.queue_draw();
    da.auto_save();
  }

}
