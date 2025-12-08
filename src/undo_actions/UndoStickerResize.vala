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

public class UndoStickerResize : UndoItem {

  private Sticker _sticker;
  private int     _width;

  //-------------------------------------------------------------
  // Default constructor.
  public UndoStickerResize( Sticker sticker, int orig_width ) {
    base( _( "resize sticker" ) );
    _sticker = sticker;
    _width   = orig_width;
  }

  private void toggle( MindMap map ) {
    var width = (int)_sticker.width;
    _sticker.set_pixbuf( _width );
    _width = width;
    map.set_current_sticker( _sticker );
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
