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

public class UndoNodeLink : UndoItem {

  Node  _node;
  Node? _old_link;
  Node? _new_link;

  /* Constructor for a node name change */
  public UndoNodeLink( Node n, Node? old_link ) {
    base( _( "node link change" ) );
    _node     = n;
    _old_link = old_link;
    _new_link = _node.linked_node;
  }

  /* Undoes a node image change */
  public override void undo( DrawArea da ) {
    _node.linked_node = _old_link;
    da.queue_draw();
    da.auto_save();
  }

  /* Redoes a node image change */
  public override void redo( DrawArea da ) {
    _node.linked_node = _new_link;
    da.queue_draw();
    da.auto_save();
  }

}
