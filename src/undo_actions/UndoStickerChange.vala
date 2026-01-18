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

public class UndoStickerChange : UndoItem {

  private Sticker _old_sticker;
  private Sticker _new_sticker;

  /* Default constructor */
  public UndoStickerChange( Sticker old_sticker, Sticker new_sticker ) {
    base( _( "change sticker" ) );
    _old_sticker = old_sticker;
    _new_sticker = new_sticker;
  }

  /* Changes out the stickers */
  private void change( MindMap map, Sticker prev, Sticker next ) {
    map.stickers.remove_sticker( prev );
    map.stickers.add_sticker( next );
    map.queue_draw();
    map.auto_save();
  }

  /* Performs an undo operation for this data */
  public override void undo( MindMap map ) {
    change( map, _new_sticker, _old_sticker );
  }

  /* Performs a redo operation */
  public override void redo( MindMap map ) {
    change( map, _old_sticker, _new_sticker );
  }

}
