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

  private Node             _n;
  private Node?            _old_parent;
  private NodeSide         _old_side;
  private int              _old_index;
  private Array<NodeInfo?> _old_info;
  private SummaryNode?     _old_summary;
  private Node             _new_parent;
  private NodeSide         _new_side;
  private int              _new_index;
  private Array<NodeInfo?> _new_info;
  private SummaryNode?     _new_summary;

  /* Default constructor */
  public UndoNodeAttach( Node n, Node? old_parent, NodeSide old_side, int old_index, Array<NodeInfo?> old_info, SummaryNode? old_summary, int old_summary_index ) {
    base( _( "attach node" ) );
    _n           = n;
    _old_parent  = old_parent;
    _old_side    = old_side;
    _old_index   = old_index;
    _old_info    = old_info;
    _old_summary = old_summary;
    _new_parent  = n.parent;
    _new_side    = n.side;
    _new_index   = n.index();
    _new_info    = new Array<NodeInfo?>();
    _n.get_node_info( ref _new_info );
    _new_summary = n.summary_node();
  }

  /* Constructor for root nodes */
  public UndoNodeAttach.for_root( Node n, int old_index, Array<NodeInfo?> old_info ) {
    base( _( "attach node" ) );
    _n           = n;
    _old_parent  = null;
    _old_index   = old_index;
    _old_info    = old_info;
    _old_summary = null;
    _new_parent  = n.parent;
    _new_side    = n.side;
    _new_index   = n.index();
    _new_info    = new Array<NodeInfo?>();
    _n.get_node_info( ref _new_info );
    _new_summary = n.summary_node();
  }

  /* Performs an undo operation for this data */
  public override void undo( MindMap map ) {
    int index = 0;
    map.da.animator.add_nodes( map.get_nodes(), "undo attach" );
    if( _new_summary != null ) {
      _new_summary.remove_node( _n );
    }
    _n.detach( _new_side );
    if( _old_parent == null ) {
      map.add_root( _n, _old_index );
      _n.set_node_info( _old_info, ref index );
    } else {
      _n.set_node_info( _old_info, ref index );
      _n.side = _old_side;
      _n.layout.propagate_side( _n, _old_side );
      _n.attach_init( _old_parent, _old_index );
      if( _old_summary != null ) {
        _old_summary.add_node( _n );
      }
    }
    map.set_current_node( _n );
    map.da.animator.animate();
    map.auto_save();
  }

  /* Performs a redo operation */
  public override void redo( MindMap map ) {
    int index = 0;
    map.da.animator.add_nodes( map.get_nodes(), "redo attach" );
    if( _old_summary != null ) {
      _old_summary.remove_node( _n );
    }
    if( _old_parent == null ) {
      map.remove_root( _old_index );
    } else {
      _n.detach( _old_side );
    }
    _n.side = _new_side;
    _n.layout.propagate_side( _n, _new_side );
    if( _old_parent == null ) {
      _n.attach( _new_parent, -1, map.get_theme() );
      _n.set_node_info( _new_info, ref index );
    } else {
      _n.set_node_info( _new_info, ref index );
      _n.attach_init( _new_parent, _new_index );
      if( _new_summary != null ) {
        _new_summary.add_node( _n );
      }
    }
    map.set_current_node( _n );
    map.da.animator.animate();
    map.auto_save();
  }

}
