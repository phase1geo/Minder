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

public class UndoNodeReplace : UndoItem {

  private Node _orig_node;
  private Node _new_node;

  /* Default constructor */
  public UndoNodeReplace( Node new_node, Node orig_node ) {
    base( _( "replace node" ) );
    _orig_node = orig_node;
    _new_node  = new_node;
  }

  /* Performs an undo operation for this data */
  public override void undo( MindMap map ) {
    map.replace_node( _new_node, _orig_node );
    map.set_current_node( _orig_node );
    map.queue_draw();
    map.auto_save();
  }

  //-------------------------------------------------------------
  // Performs a redo operation.
  public override void redo( MindMap map ) {
    map.replace_node( _orig_node, _new_node );
    map.set_current_node( _new_node );
    map.queue_draw();
    map.auto_save();
  }

}
