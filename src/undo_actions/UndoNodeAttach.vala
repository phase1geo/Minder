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

public class UndoNodeAttach : UndoItem {

  private DrawArea _da;
  private Node     _n;
  private Node?    _old_parent;
  private NodeSide _old_side;
  private int      _old_index;
  private RGBA     _old_link;
  private Node     _new_parent;
  private NodeSide _new_side;
  private int      _new_index;
  private Layout?  _layout;

  /* Default constructor */
  public UndoNodeAttach( DrawArea da, Node n, Node? old_parent, NodeSide old_side, int old_index, RGBA old_link, Layout l ) {
    base( _( "attach node" ) );
    _da         = da;
    _n          = n;
    _old_parent = old_parent;
    _old_side   = old_side;
    _old_index  = old_index;
    _old_link   = old_link;
    _new_parent = n.parent;
    _new_side   = n.side;
    _new_index  = n.index();
    _layout     = l;
  }

  /* Performs an undo operation for this data */
  public override void undo() {
    _da.animator.add_nodes( "undo attach" );
    _n.detach( _new_side, _layout );
    if( _old_parent == null ) {
      _da.add_root( _n, _old_index );
    } else {
      _n.link_color  = _old_link;
      _n.side        = _old_side;
      _layout.propagate_side( _n, _old_side );
      _n.attach( _old_parent, _old_index, _da.get_theme(), _layout );
    }
    _da.set_current_node( _n );
    _da.animator.animate();
    _da.node_changed();
    _da.changed();
  }

  /* Performs a redo operation */
  public override void redo() {
    _da.animator.add_nodes( "redo attach" );
    if( _old_parent == null ) {
      _da.remove_root( _old_index );
    } else {
      _n.detach( _old_side, _layout );
    }
    _n.side = _new_side;
    _layout.propagate_side( _n, _new_side );
    _n.attach( _new_parent, _new_index, _da.get_theme(), _layout );
    _da.set_current_node( _n );
    _da.animator.animate();
    _da.node_changed();
    _da.changed();
  }

}
