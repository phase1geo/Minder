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

public class UndoNodeInsert : UndoItem {

  private Node? _parent;
  private Node  _n;
  private int   _index;
  private bool  _parent_folded;

  /* Default constructor */
  public UndoNodeInsert( Node n, int index ) {
    base( _( "insert node" ) );
    _n             = n;
    _index         = index;
    _parent        = n.parent;
    _parent_folded = (_parent == null) ? false : _parent.folded;
  }

  /* Performs an undo operation for this data */
  public override void undo( MindMap map ) {
    if( _parent == null ) {
      map.remove_root( _index );
    } else {
      if( _parent_folded ) {
        _parent.folded = true;
      }
      _n.detach( _n.side );
    }
    if( map.get_current_node() == _n ) {
      map.set_current_node( null );
    }
    map.queue_draw();
    map.auto_save();
  }

  /* Performs a redo operation */
  public override void redo( MindMap map ) {
    if( _parent == null ) {
      map.add_root( _n, _index );
    } else {
      _parent.folded = _parent_folded;
      _n.attach( _parent, _index, null );
    }
    map.set_current_node( _n );
    map.queue_draw();
    map.auto_save();
  }

}
