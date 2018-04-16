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
using Gdk;

public class Theme : Object {

  private int _index;

  public    string name               { protected set; get; }
  public.   Image. icon.              { protected set; get; }
  public    RGBA   background         { protected set; get; }
  public    RGBA   foreground         { protected set; get; }
  public    RGBA   root_background    { protected set; get; }
  public    RGBA   root_foreground    { protected set; get; }
  public    RGBA   nodesel_background { protected set; get; }
  public    RGBA   nodesel_foreground { protected set; get; }
  public    RGBA   textsel_background { protected set; get; }
  public    RGBA   textsel_foreground { protected set; get; }
  public    RGBA   text_cursor        { protected set; get; }
  protected RGBA[] link_colors        { set; get; }

  /* Default constructor */
  public Theme() {
    _index = 0;
  }

  /* Returns the next available link color index */
  public int next_color_index() {
    return( _index++ );
  }

  /* Returns the color associated with the given index */
  public RGBA link_color( int index ) {
    return( link_colors[index % link_colors.length] );
  }

  /* Returns the RGBA color for the given color value */
  protected RGBA get_color( string value ) {
    RGBA c = {1.0, 1.0, 1.0, 1.0};
    c.parse( value );
    return( c );
  }

  /* Returns the CSS provider for this theme */
  public CssProvider get_css_provider() {
    CssProvider provider = new CssProvider();
    try {
      provider.load_from_data( "GtkDrawingArea { background:" + background.to_string() + "; }" );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to load background color: %s", e.message );
    }
    return( provider );
  }

}
