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

public class UndoNodesReplace : UndoItem {

  private Node        _orig_node;
  private Array<Node> _new_nodes;

  /* Default constructor */
  public UndoNodesReplace( Node? orig_node, Array<Node> new_nodes ) {
    base( _( "replace nodes" ) );
    _orig_node = orig_node;
    _new_nodes = new Array<Node>();
    for( int i=0; i<new_nodes.length; i++ ) {
      _new_nodes.append_val( new_nodes.index( i ) );
    }
  }

  /* Performs an undo operation for this data */
  public override void undo( DrawArea da ) {
    da.replace_node( _new_nodes.index( 0 ), _orig_node );
    for( int i=1; i<_new_nodes.length; i++ ) {
      da.remove_root_node( _new_nodes.index( i ) );
    }
    da.set_current_node( _orig_node );
    da.queue_draw();
    da.current_changed( da );
    da.changed();
  }

  /* Performs a redo operation */
  public override void redo( DrawArea da ) {
    da.replace_node( _orig_node, _new_nodes.index( 0 ) );
    for( int i=1; i<_new_nodes.length; i++ ) {
      da.add_root( _new_nodes.index( i ), -1 );
    }
    da.set_current_node( _new_nodes.index( 0 ) );
    da.queue_draw();
    da.current_changed( da );
    da.changed();
  }

}
