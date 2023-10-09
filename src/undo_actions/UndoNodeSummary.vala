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

public class UndoNodeSummary : UndoItem {

  private SummaryNode _n;
  private Node        _first;
  private Node        _last;

  /* Default constructor */
  public UndoNodeSummary( SummaryNode n ) {
    base( _( "insert summary node" ) );
    _n     = n;
    _first = n.first_node();
    _last  = n.last_node();
  }

  /* Performs an undo operation for this data */
  public override void undo( DrawArea da ) {
    // _n.detach( _n.side );
    if( da.get_current_node() == _n ) {
      da.set_current_node( null );
    }
    da.queue_draw();
    da.auto_save();
  }

  /* Performs a redo operation */
  public override void redo( DrawArea da ) {
    // _n.attach( _first, -1, null );
    da.set_current_node( _n );
    da.queue_draw();
    da.auto_save();
  }

}
