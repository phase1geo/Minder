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

public class UndoStickerMove : UndoItem {

  private Sticker _sticker;
  private double  _posx;
  private double  _posy;

  /* Default constructor */
  public UndoStickerMove( Sticker sticker, double orig_posx, double orig_posy ) {
    base( _( "add sticker" ) );
    _sticker = sticker;
    _posx    = orig_posx;
    _posy    = orig_posy;
  }

  private void toggle( DrawArea da ) {
    var posx = _sticker.posx;
    var posy = _sticker.posy;
    _sticker.posx = _posx;
    _sticker.posy = _posy;
    _posx = posx;
    _posy = posy;
    da.set_current_sticker( _sticker );
    da.queue_draw();
    da.changed();
  }

  /* Performs an undo operation for this data */
  public override void undo( DrawArea da ) {
    toggle( da );
  }

  /* Performs a redo operation */
  public override void redo( DrawArea da ) {
    toggle( da );
  }

}
