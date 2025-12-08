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

public class UndoNodeReparent : UndoItem {

  private Node _node;
  private int  _first_index;
  private int  _last_index;

  //-------------------------------------------------------------
  // Default constructor.
  public UndoNodeReparent( Node node, int first_index, int last_index ) {
    base( _( "reparent children" ) );
    _node        = node;
    _first_index = first_index;
    _last_index  = last_index;
  }

  //-------------------------------------------------------------
  // Performs an undo operation for this data.
  public override void undo( MindMap map ) {
    map.animator.add_nodes( map.model.get_nodes(), false, "undo_make_children_siblings" );
    for( int i=(_last_index - 1); i>=_first_index; i-- ) {
      var child = _node.parent.children().index( i );
      child.detach( child.side );
      child.attach( _node, 0, null );
    }
    map.animator.animate();
    map.auto_save();
  }

  //-------------------------------------------------------------
  // Performs a redo operation.
  public override void redo( MindMap map ) {
    map.animator.add_nodes( map.model.get_nodes(), false, "redo_make_children_siblings" );
    _node.make_children_siblings();
    map.animator.animate();
    map.auto_save();
  }

}
