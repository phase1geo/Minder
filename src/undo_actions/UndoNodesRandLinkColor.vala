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

public class UndoNodesRandLinkColor : UndoItem {

  Array<Node>  _nodes;
  Array<RGBA?> _old_colors;
  Array<RGBA?> _new_colors;

  /* Constructor for a node name change */
  public UndoNodesRandLinkColor( Array<Node> nodes, Array<RGBA?> old_colors ) {
    base( _( "random node link color changes" ) );
    _nodes      = new Array<Node>();
    _old_colors = new Array<RGBA?>();
    _new_colors = new Array<RGBA?>();
    for( int i=0; i<nodes.length; i++ ) {
      _nodes.append_val( nodes.index( i ) );
      _old_colors.append_val( old_colors.index( i ) );
      _new_colors.append_val( nodes.index( i ).link_color );
    }
  }

  private void change( DrawArea da, Array<RGBA?> colors ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).link_color = colors.index( i );
    }
    da.queue_draw();
    da.changed();
  }

  /* Undoes a node link color change */
  public override void undo( DrawArea da ) {
    change( da, _old_colors );
  }

  /* Redoes a node link color change */
  public override void redo( DrawArea da ) {
    change( da, _new_colors );
  }

}
