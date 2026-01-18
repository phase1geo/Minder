/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

public class UndoNodeSummaryFromNode : UndoItem {

  private Node        _n;
  private SummaryNode _sn;

  /* Default constructor */
  public UndoNodeSummaryFromNode( Node n, SummaryNode sn ) {
    base( _( "convert to summary node" ) );
    _n  = n;
    _sn = sn;
  }

  /* Performs an undo operation for this data */
  public override void undo( MindMap map ) {
    var parent = _sn.last_node().parent;
    var index  = _sn.last_node().index() + 1;
    _sn.detach_all();
    _n.attach( parent, index, null, false );
    map.set_current_node( _n );
    map.queue_draw();
    map.auto_save();
  }

  /* Performs a redo operation */
  public override void redo( MindMap map ) {
    _n.detach( _n.side );
    _sn.attach_all();
    map.set_current_node( _sn );
    map.queue_draw();
    map.auto_save();
  }

}
