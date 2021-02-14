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

public class UndoStickerAdd : UndoItem {

  private Sticker _sticker;

  /* Default constructor */
  public UndoStickerAdd( Sticker sticker ) {
    base( _( "add sticker" ) );
    _sticker = sticker;
  }

  /* Performs an undo operation for this data */
  public override void undo( DrawArea da ) {
    da.stickers.remove_sticker( _sticker );
    da.queue_draw();
    da.auto_save();
  }

  /* Performs a redo operation */
  public override void redo( DrawArea da ) {
    da.stickers.add_sticker( _sticker );
    da.set_current_sticker( _sticker );
    da.queue_draw();
    da.auto_save();
  }

}
