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

public class UndoNodeLinkColor : UndoItem {

  DrawArea  _da;
  Node      _node;
  int       _old_color_index;
  int       _new_color_index;

  /* Constructor for a node name change */
  public UndoNodeLinkColor( DrawArea da, Node n, int old_color_index ) {
    base( _( "link color change" ) );
    _da              = da;
    _node            = n;
    _old_color_index = old_color_index;
    _new_color_index = n.color_index;
  }

  /* Undoes a node name change */
  public override void undo() {
    _node.color_index = _old_color_index;
    _node.propagate_color();
    _da.queue_draw();
    _da.node_changed();
    _da.changed();
  }

  /* Redoes a node name change */
  public override void redo() {
    _node.color_index = _new_color_index;
    _node.propagate_color();
    _da.queue_draw();
    _da.node_changed();
    _da.changed();
  }

}
