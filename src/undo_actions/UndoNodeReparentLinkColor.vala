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
using Gdk;

public class UndoNodeReparentLinkColor : UndoItem {

  Node _node;
  RGBA _old_color;

  /* Constructor for a node name change */
  public UndoNodeReparentLinkColor( Node node ) {
    base( _( "node link color reparent" ) );
    _node      = node;
    _old_color = node.link_color;
  }

  /* Undoes a node link color change */
  public override void undo( DrawArea da ) {
    _node.link_color_root = true;
    _node.link_color      = _old_color;
    da.queue_draw();
    da.auto_save();
  }

  /* Redoes a node link color change */
  public override void redo( DrawArea da ) {
    _node.link_color_root = false;
    da.queue_draw();
    da.auto_save();
  }

}
