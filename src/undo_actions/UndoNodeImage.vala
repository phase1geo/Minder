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

public class UndoNodeImage : UndoItem {

  Node       _node;
  NodeImage? _old_image;
  NodeImage? _new_image;

  /* Constructor for a node name change */
  public UndoNodeImage( Node n, NodeImage? old_image ) {
    base( _( "node image change" ) );
    _node      = n;
    _old_image = old_image;
    _new_image = n.image;
  }

  /* Changes the node image, adjusts the layout and updates the UI */
  private void change( DrawArea da, NodeImage? img ) {
    _node.image = img;
    da.get_layout().handle_update_by_edit( _node );
    da.queue_draw();
    da.node_changed();
    da.changed();
  }

  /* Undoes a node image change */
  public override void undo( DrawArea da ) {
    change( da, _old_image );
  }

  /* Redoes a node image change */
  public override void redo( DrawArea da ) {
    change( da, _new_image );
  }

}
