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

public class ThemeSolarizedDark : Theme {

  /* Create the theme colors */
  public ThemeSolarizedDark() {

    name   = "solarized_dark";
    label  = _( "Solarized Dark" );
    custom = false;

    /* Generate the non-link colors */
    set_color( "background",            color_from_string( "#002B36" ) );
    set_color( "foreground",            color_from_string( "#93A1A1" ) );
    set_color( "root_background",       color_from_string( "#d4d4d4" ) );
    set_color( "root_foreground",       color_from_string( "#000000" ) );
    set_color( "nodesel_background",    color_from_string( "#586E75" ) );
    set_color( "nodesel_foreground",    color_from_string( "#ffffff" ) );
    set_color( "textsel_background",    color_from_string( "#657B83" ) );
    set_color( "textsel_foreground",    color_from_string( "#002B36" ) );
    set_color( "text_cursor",           color_from_string( "#93A1A1" ) );
    set_color( "attachable",            color_from_string( "#9bdb4d" ) );
    set_color( "connection_background", color_from_string( "#606060" ) );
    set_color( "connection_foreground", color_from_string( "#93A1A1" ) );
    set_color( "url_background",        color_from_string( "Grey") );
    set_color( "url_foreground",        color_from_string( "Blue" ) );

    set_color( "link_color0", color_from_string( "#DC322F" ) );
    set_color( "link_color1", color_from_string( "#CB4B16" ) );
    set_color( "link_color2", color_from_string( "#B58900" ) );
    set_color( "link_color3", color_from_string( "#859900" ) );
    set_color( "link_color4", color_from_string( "#268BD2" ) );
    set_color( "link_color5", color_from_string( "#6C71C4" ) );
    set_color( "link_color6", color_from_string( "#D33682" ) );
    set_color( "link_color7", color_from_string( "#2AA198" ) );

    prefer_dark = true;

  }

}
