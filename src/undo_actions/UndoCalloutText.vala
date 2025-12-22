/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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

public class UndoCalloutText : UndoItem {

  private Callout    _callout;
  private CanvasText _text;
  private CanvasText _orig_text;

  /* Constructor for a node name change */
  public UndoCalloutText( MindMap map, Callout callout, CanvasText orig_text ) {
    base( _( "callout text change" ) );
    _callout   = callout;
    _text      = new CanvasText( map );
    _orig_text = new CanvasText( map );
    _text.copy( callout.text );
    _orig_text.copy( orig_text );
  }

  /* Undoes a node name change */
  public override void undo( MindMap map ) {
    _callout.text.copy( _orig_text );
    map.queue_draw();
    map.current_changed( map );
    map.auto_save();
  }

  /* Redoes a node name change */
  public override void redo( MindMap map ) {
    _callout.text.copy( _text );
    map.queue_draw();
    map.current_changed( map );
    map.auto_save();
  }

}
