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

public class UndoNodeLinkAdd : UndoItem {

  Node      _node;
  NodeLink? _added_link;

  /* Constructor for a node name change */
  public UndoNodeLinkAdd( Node n ) {
    base( _( "node link add" ) );
    _node       = n;
    _added_link = _node.get_node_link( _node.num_node_links() - 1 );
  }

  /* Undoes a node image change */
  public override void undo( DrawArea da ) {
    _node.remove_node_link( _node.num_node_links() - 1 );
    da.queue_draw();
    da.auto_save();
  }

  /* Redoes a node image change */
  public override void redo( DrawArea da ) {
    _node.add_node_link( _added_link );
    da.queue_draw();
    da.auto_save();
  }

}
