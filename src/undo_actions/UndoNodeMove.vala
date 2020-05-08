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

public class UndoNodeMove : UndoItem {

  private Node     _n;
  private NodeSide _old_side;
  private int      _old_index;
  private NodeSide _new_side;
  private int      _new_index;

  /* Default constructor */
  public UndoNodeMove( Node n, NodeSide old_side, int old_index ) {
    base( _( "move node" ) );
    _n         = n;
    _old_side  = old_side;
    _old_index = old_index;
    _new_side  = n.side;
    _new_index = n.index();
  }

  /* Perform the node move change */
  public void change( DrawArea da, NodeSide old_side, NodeSide new_side, int new_index ) {
    Node parent = _n.parent;
    da.animator.add_nodes( da.get_nodes(), "undo move" );
    _n.detach( old_side );
    _n.side = new_side;
    _n.layout.propagate_side( _n, new_side );
    _n.attach( parent, new_index, null, false );
    da.animator.animate();
  }

  /* Performs an undo operation for this data */
  public override void undo( DrawArea da ) {
    change( da, _new_side, _old_side, _old_index );
  }

  /* Performs a redo operation */
  public override void redo( DrawArea da ) {
    change( da, _old_side, _new_side, _new_index );
  }

}
