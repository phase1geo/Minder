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

public class UndoTagsRemove : UndoItem {

  private Tag         _tag;
  private int         _index;
  private Array<Node> _nodes;

  //-------------------------------------------------------------
  // Constructor for a tag removal from MindMap tag list. 
  public UndoTagsRemove( Tag tag, int index, Array<Node> nodes ) {
    base( _( "mindmap tag remove" ) );
    _tag   = tag;
    _index = index;
    _nodes = new Array<Node>();
    for( int i=0; i<nodes.length; i++ ) {
      _nodes.append_val( nodes.index( i ) );
    }
  }

  //-------------------------------------------------------------
  // Undoes a tag remove operation
  public override void undo( MindMap map ) {
    map.model.tags.add_tag( _tag, _index );
    if( _nodes.length > 0 ) {
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).add_tag( _tag );
      }
      map.queue_draw();
    }
    map.auto_save();
    map.reload_tags();
  }

  //-------------------------------------------------------------
  // Redoes a tag remove operations
  public override void redo( MindMap map ) {
    map.model.tags.remove_tag( _index );
    if( _nodes.length > 0 ) {
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).remove_tag( _tag );
      }
      map.queue_draw();
    }
    map.auto_save();
    map.reload_tags();
  }


}
