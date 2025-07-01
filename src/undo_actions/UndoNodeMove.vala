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

  private Node         _n;
  private NodeSide     _old_side;
  private int          _old_index;
  private SummaryNode? _old_summary;
  private NodeSide     _new_side;
  private int          _new_index;
  private SummaryNode? _new_summary;

  /* Default constructor */
  public UndoNodeMove( Node n, NodeSide old_side, int old_index, SummaryNode? old_summary ) {
    base( _( "move node" ) );
    _n           = n;
    _old_side    = old_side;
    _old_index   = old_index;
    _old_summary = old_summary;
    _new_side    = n.side;
    _new_index   = n.index();
    _new_summary = n.summary_node();
  }

  /* Perform the node move change */
  public void change( MindMap map, NodeSide old_side, SummaryNode? old_summary, NodeSide new_side, int new_index, SummaryNode? new_summary ) {
    Node parent = _n.parent;
    map.da.animator.add_nodes( da.get_nodes(), "undo move" );
    _n.detach( old_side );
    if( old_summary != null ) {
      old_summary.remove_node( _n );
    }
    _n.side = new_side;
    _n.layout.propagate_side( _n, new_side );
    _n.attach( parent, new_index, null, false );
    if( new_summary != null ) {
      new_summary.add_node( _n );
    }
    map.da.animator.animate();
    map.auto_save();
  }

  /* Performs an undo operation for this data */
  public override void undo( MindMap map ) {
    change( map, _new_side, _new_summary, _old_side, _old_index, _old_summary );
  }

  /* Performs a redo operation */
  public override void redo( MindMap map ) {
    change( map, _old_side, _old_summary, _new_side, _new_index, _new_summary );
  }

}
