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

  private DrawArea         _da;
  private Node             _n;
  private Node?            _old_parent;
  private NodeSide         _old_side;
  private int              _old_index;
  private Array<NodeInfo?> _old_info;
  private Node             _new_parent;
  private NodeSide         _new_side;
  private int              _new_index;
  private Array<NodeInfo?> _new_info;
  private Layout?          _layout;

  /* Default constructor */
  public UndoNodeAttach( DrawArea da, Node n, Node? old_parent, NodeSide old_side, int old_index, Array<NodeInfo?> old_info, Layout l ) {
    base( _( "attach node" ) );
    _da         = da;
    _n          = n;
    _old_parent = old_parent;
    _old_side   = old_side;
    _old_index  = old_index;
    _old_info   = old_info;
    _new_parent = n.parent;
    _new_side   = n.side;
    _new_index  = n.index();
    _new_info   = new Array<NodeInfo?>();
    _n.get_node_info( ref _new_info );
    _layout     = l;
  }

  /* Constructor for root nodes */
  public UndoNodeAttach.for_root( DrawArea da, Node n, int old_index, Array<NodeInfo?> old_info, Layout l ) {
    base( _( "attach node" ) );
    _da         = da;
    _n          = n;
    _old_parent = null;
    _old_index  = old_index;
    _old_info   = old_info;
    _new_parent = n.parent;
    _new_side   = n.side;
    _new_index  = n.index();
    _new_info   = new Array<NodeInfo?>();
    _n.get_node_info( ref _new_info );
    _layout     = l;
  }

  /* Performs an undo operation for this data */
  public override void undo() {
    int index = 0;
    _da.animator.add_nodes( "undo attach" );
    _n.detach( _new_side, _layout );
    if( _old_parent == null ) {
      _da.add_root( _n, _old_index );
      _n.set_node_info( _old_info, ref index );
    } else {
      _n.set_node_info( _old_info, ref index );
      _n.side = _old_side;
      _layout.propagate_side( _n, _old_side );
      _n.attach_nonroot( _old_parent, _old_index, _da.get_theme(), _layout );
    }
    _da.set_current_node( _n );
    _da.animator.animate();
    _da.node_changed();
    _da.changed();
  }

  /* Performs a redo operation */
  public override void redo() {
    int index = 0;
    _da.animator.add_nodes( "redo attach" );
    if( _old_parent == null ) {
      _da.remove_root( _old_index );
    } else {
      _n.detach( _old_side, _layout );
    }
    _n.side = _new_side;
    _layout.propagate_side( _n, _new_side );
    if( _old_parent == null ) {
      _n.attach_root( _new_parent, _da.get_theme(), _layout );
      _n.set_node_info( _new_info, ref index );
    } else {
      _n.set_node_info( _new_info, ref index );
      _n.attach_nonroot( _new_parent, _new_index, _da.get_theme(), _layout );
    }
    _da.set_current_node( _n );
    _da.animator.animate();
    _da.node_changed();
    _da.changed();
  }

}
