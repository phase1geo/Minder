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

public class UndoNodesLinkColor : UndoItem {

  Array<Node>  _nodes;
  Array<RGBA?> _old_colors;
  RGBA         _new_color;

  /* Constructor for a node name change */
  public UndoNodesLinkColor( Array<Node> nodes, RGBA new_color ) {
    base( _( "node link color changes" ) );
    _nodes      = new Array<Node>();
    _old_colors = new Array<RGBA?>();
    for( int i=0; i<nodes.length; i++ ) {
      _nodes.append_val( nodes.index( i ) );
      _old_colors.append_val( nodes.index( i ).link_color );
    }
    _new_color = new_color;
  }

  /* Undoes a node link color change */
  public override void undo( MindMap map ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).link_color = _old_colors.index( i );
    }
    map.queue_draw();
    map.auto_save();
  }

  /* Redoes a node link color change */
  public override void redo( MindMap map ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).link_color = _new_color;
    }
    map.queue_draw();
    map.auto_save();
  }

}
