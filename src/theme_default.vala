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

using Gdk;

public class ThemeDefault : Theme {

  /* Create the theme colors */
  public ThemeDefault() {

    name = "Default";

    /* Generate the non-link colors */
    background         = get_color( "Grey" );
    foreground         = get_color( "White" );
    root_background    = get_color( "White" );
    root_foreground    = get_color( "Black" );
    nodesel_background = get_color( "Light Blue" );
    nodesel_foreground = get_color( "Black" );
    textsel_background = get_color( "Blue" );
    textsel_foreground = get_color( "White" );
    text_cursor        = get_color( "Green" );

    /* Generate the link colors */
    link_colors = new RGBA[8];
    link_colors[0] = get_color( "Red" );
    link_colors[1] = get_color( "Orange" );
    link_colors[2] = get_color( "Yellow" );
    link_colors[3] = get_color( "Green" );
    link_colors[4] = get_color( "Blue" );
    link_colors[5] = get_color( "Purple" );
    link_colors[6] = get_color( "Brown" );
    link_colors[7] = get_color( "Black" );

  }

}
