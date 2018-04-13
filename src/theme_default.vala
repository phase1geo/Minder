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
    foreground         = get_color( "#d4d4d4" );
    root_background    = get_color( "#d4d4d4" );
    root_foreground    = get_color( "Black" );
    nodesel_background = get_color( "#64baff" );
    nodesel_foreground = get_color( "Black" );
    textsel_background = get_color( "#0d52bf" );
    textsel_foreground = get_color( "White" );
    text_cursor        = get_color( "Black" );

    /* Generate the link colors */
    link_colors = new RGBA[8];
    link_colors[0] = get_color( "#c6262e" );
    link_colors[1] = get_color( "#f37329" );
    link_colors[2] = get_color( "#f9c440" );
    link_colors[3] = get_color( "#68b723" );
    link_colors[4] = get_color( "#3689e6" );
    link_colors[5] = get_color( "#7a36b1" );
    link_colors[6] = get_color( "#715344" );
    link_colors[7] = get_color( "#333333" );

  }

}
