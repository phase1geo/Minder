/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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

public class UndoNodeUnclify : UndoItem {

  private Node _node;
  private Node _parent;
  private int  _index;

  //-------------------------------------------------------------
  // Default constructor.
  public UndoNodeUnclify( Node node ) {
    base( _( "reparent node" ) );
    _node   = node;
    _parent = node.parent;
    _index  = node.index();
  }

  //-------------------------------------------------------------
  // Performs an undo operation for this data.
  public override void undo( MindMap map ) {
    map.animator.add_nodes( map.get_nodes(), false, "undo_make_parent_sibling" );
    _node.detach( _node.side );
    _node.attach( _parent, _index, null );
    map.animator.animate();
    map.auto_save();
  }

  //-------------------------------------------------------------
  // Performs a redo operation.
  public override void redo( MindMap map ) {
    map.animator.add_nodes( map.get_nodes(), false, "redo_make_parent_sibling" );
    _node.make_parent_sibling();
    map.animator.animate();
    map.auto_save();
  }

}
