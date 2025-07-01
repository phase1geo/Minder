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

public class UndoNodeStickerChange : UndoItem {

  private Node   _node;
  private string _name;

  /* Default constructor */
  public UndoNodeStickerChange( Node node, string orig_name ) {
    base( _( "change node sticker" ) );
    _node = node;
    _name = orig_name;
  }

  private void toggle( MindMap map ) {
    var name = _node.sticker;
    _node.sticker = _name;
    _name = name;
    map.queue_draw();
    map.auto_save();
  }

  /* Performs an undo operation for this data */
  public override void undo( MindMap map ) {
    toggle( map );
  }

  /* Performs a redo operation */
  public override void redo( MindMap map ) {
    toggle( map );
  }

}
