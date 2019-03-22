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
using Gtk;

public class ThemeSolarizedLight : Theme {

  /* Create the theme colors */
  public ThemeSolarizedLight() {

    name = _( "Solarized Light" ); 

    /* Generate the non-link colors */
    background         = get_color( "#FDF6E3" );
    foreground         = get_color( "#586E75" );
    root_background    = get_color( "#839496" );
    root_foreground    = get_color( "#FDF6E3" );
    nodesel_background = get_color( "#586E75" );
    nodesel_foreground = get_color( "#ffffff" );
    textsel_background = get_color( "#93A1A1" );
    textsel_foreground = get_color( "#002B36" );
    text_cursor        = get_color( "#586E75" );
    attachable_color   = get_color( "#9bdb4d" );
    connection_color   = get_color( "#777777" );
    prefer_dark        = false;

    /* Generate the link colors */
    add_link_color( get_color( "#DC322F" ) );
    add_link_color( get_color( "#CB4B16" ) );
    add_link_color( get_color( "#B58900" ) );
    add_link_color( get_color( "#859900" ) );
    add_link_color( get_color( "#268BD2" ) );
    add_link_color( get_color( "#6C71C4" ) );
    add_link_color( get_color( "#D33682" ) );
    add_link_color( get_color( "#2AA198" ) );

  }

}
