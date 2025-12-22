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

public class UndoStyleConnectionTitleWidth : UndoStyleChange {

  GenericArray<int> _values;

  /* Constructor for a node name change */
  public UndoStyleConnectionTitleWidth( StyleAffects affects, int title_width, MindMap map ) {
    base( affects, map );
    _values = new GenericArray<int>();
    _values.add( title_width );
    load_styles( map );
  }

  protected override void load_style_value( Style style ) {
    _values.add( style.connection_title_width );
  }

  protected override void store_style_value( Style style, int index ) {
    style.connection_title_width = _values.get( index );
  }

  protected override void replace_with_item( UndoItem item ) {
    _values.set( 0, ((UndoStyleConnectionTitleWidth)item)._values.get( 0 ) );
  }

}
