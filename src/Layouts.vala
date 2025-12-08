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

using GLib;

public class Layouts : Object {

  private Array<Layout> _layouts;

  /* Default constructor */
  public Layouts() {

    /* Create the list of available layouts */
    _layouts = new Array<Layout>();

    /* Create the layouts */
    var manual     = new LayoutManual();
    var vertical   = new LayoutVertical();
    var horizontal = new LayoutHorizontal();
    var left       = new LayoutLeft();
    var right      = new LayoutRight();
    var up         = new LayoutUp();
    var down       = new LayoutDown();

    /* Add the create layouts to the list */
    _layouts.append_val( manual );
    _layouts.append_val( vertical );
    _layouts.append_val( horizontal );
    _layouts.append_val( left );
    _layouts.append_val( right );
    _layouts.append_val( up );
    _layouts.append_val( down );

  }

  /* Populates the given array with a list of layout names */
  public void get_names( ref Array<string> names ) {
    for( int i=0; i<_layouts.length; i++ ) {
      names.append_val( _layouts.index( i ).name );
    }
  }

  /* Populates the given array with a list of layout icon filenames */
  public void get_icons( ref Array<string> light_icons, ref Array<string> dark_icons ) {
    for( int i=0; i<_layouts.length; i++ ) {
      light_icons.append_val( _layouts.index( i ).light_icon );
      dark_icons.append_val( _layouts.index( i ).dark_icon );
    }
  }

  /* Display the available layouts */
  public Layout get_layout( string name ) {
    for( int i=0; i<_layouts.length; i++ ) {
      if( name == _layouts.index( i ).name ) {
        return( _layouts.index( i ) );
      }
    }
    return( _layouts.index( 2 ) );
  }

  /* Returns the default layout (we are going to use 'horizontal') */
  public Layout get_default() {
    return( _layouts.index( 2 ) );
  }

}
