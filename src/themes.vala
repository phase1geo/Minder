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
using GLib;

public class Themes : Object {

  private Array<Theme> _themes;

  /* Default constructor */
  public Themes() {
    _themes = new Array<Theme>();
    var theme = new ThemeDefault();
    _themes.append_val( theme );
  }

  /* Returns a list of theme names */
  public void names( out Array<string> names ) {
    for( int i=0; i<_themes.length; i++ ) {
      names.append_val( _themes.index( i ).name );
    }
  }

  /* Returns a list of icons associated with each of the loaded themes */
  public void icons( out Array<Image> icons ) {
    for( int i=0; i<_themes.length; i++ ) {
      icons.append_val( _themes.index( i ).icon );
    }
  }

  /* Returns the theme associated with the given name */
  public Theme get_theme( string name ) {
    for( int i=0; i<_themes.length; i++ ) {
      if( name == _themes.index( i ).name ) {
        return( _themes.index( i ) );
      }
    }
    return( _themes.index( 0 ) );
  }

}
