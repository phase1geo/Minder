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

public class UndoNodeFolds : UndoItem {

  Array<Node> _nodes;

  /* Default constructor */
  public UndoNodeFolds( Array<Node> nodes ) {
    base( _( "node fold changes" ) );
    _nodes = nodes;
  }

  public UndoNodeFolds.single( Node node ) {
    base( _( "node fold changes" ) );
    _nodes = new Array<Node>();
    _nodes.append_val( node );
  }

  /* Toggles the fold indicators */
  private void change( DrawArea da ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      node.set_fold_only( !node.folded );
    }
    da.queue_draw();
    da.current_changed( da );
    da.auto_save();
  }

  /* Undoes a node fold operation */
  public override void undo( DrawArea da ) {
    change( da );
  }

  /* Redoes a node fold operation */
  public override void redo( DrawArea da ) {
    change( da );
  }

}
