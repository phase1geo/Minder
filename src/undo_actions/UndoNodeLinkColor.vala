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

using Gtk;
using Gdk;

public class UndoNodeLinkColor : UndoItem {

  Node  _node;
  RGBA? _old_color;
  RGBA? _new_color;

  /* Constructor for a node name change */
  public UndoNodeLinkColor( Node n, RGBA? old_color ) {
    base( _( "link color change" ) );
    _node      = n;
    _old_color = old_color;
    _new_color = n.link_color;
  }

  /* Undoes a node name change */
  public override void undo( MindMap map ) {
    _node.link_color = _old_color;
    map.queue_draw();
    map.current_changed( map );
    map.auto_save();
  }

  /* Redoes a node name change */
  public override void redo( MindMap map ) {
    _node.link_color = _new_color;
    map.queue_draw();
    map.current_changed( map );
    map.auto_save();
  }

}
