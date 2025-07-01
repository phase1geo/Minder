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

public class UndoNodeResize : UndoItem {

  Node _node;
  int  _old_width;
  int  _new_width;
  bool _old_resizable;
  bool _new_resizable;

  /* Constructor for a node name change */
  public UndoNodeResize( Node n, int old_width, bool old_resizable ) {
    base( _( "node resize" ) );
    _node          = n;
    _old_width     = old_width;
    _old_resizable = old_resizable;
    _new_width     = n.style.node_width;
    _new_resizable = n.image_resizable;
  }

  /* Undoes a node name change */
  public override void undo( MindMap map ) {
    _node.image_resizable = _old_resizable;
    _node.resize( _old_width - _new_width );
    map.queue_draw();
    map.auto_save();
  }

  /* Redoes a node name change */
  public override void redo( MindMap map ) {
    _node.image_resizable = _new_resizable;
    _node.resize( _new_width - _old_width );
    map.queue_draw();
    map.auto_save();
  }

}
