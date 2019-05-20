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

public class UndoStyleAffectChange : UndoStyleChange {

  private GenericArray<Style> _styles;

  /* Constructor for a style affect change */
  public UndoStyleAffectChange( StyleAffects affects, Style style, DrawArea da ) {
    base( affects, da );
    _styles = new GenericArray<Style>();
    _styles.add( style );
    load_styles( da );
  }

  protected override void load_style_value( Style style ) {
    Style new_style = new Style();
    new_style.copy( style );
    _styles.add( new_style );
  }

  protected override void store_style_value( Style style, int index ) {
    style.copy( _styles.get( index ) );
  }

  protected override void replace_with_item( UndoItem item ) {
    _styles.set( 0, ((UndoStyleAffectChange)item)._styles.get( 0 ) );
  }

  protected override string to_string() {
    return( base.to_string() + ", style: " + _styles.get( 0 ).to_string() );
  }

}
