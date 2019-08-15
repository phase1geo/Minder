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

public class ThemeWindow : Gtk.Window {

  private ThemeCustom _theme;

  public ThemeWindow() {

    _theme = new ThemeCustom();

    var grid = new Grid();
    grid.row_spacing        = 5;
    grid.column_spacing     = 30;
    // grid.column_homogeneous = true;

    add_color( _( "Background" ),             _theme.background,         grid, 0 );
    add_color( _( "Foreground" ),             _theme.foreground,         grid, 1 );
    add_color( _( "Root Node Background" ),   _theme.root_background,    grid, 2 );
    add_color( _( "Root Node Foreground" ),   _theme.root_foreground,    grid, 3 );
    add_color( _( "Node Select Background" ), _theme.nodesel_background, grid, 4 );
    add_color( _( "Node Select Foreground" ), _theme.nodesel_background, grid, 5 );
    add_color( _( "Text Select Background" ), _theme.textsel_background, grid, 6 );
    add_color( _( "Text Select Foreground" ), _theme.textsel_background, grid, 7 );
    add_color( _( "Text Cursor" ),            _theme.text_cursor,        grid, 8 );
    add_color( _( "Attachable Highlight" ),   _theme.attachable_color,   grid, 9 );
    add_color( _( "Connection Color" ),       _theme.connection_color,   grid, 10 );

    var dark_lbl        = new Label( Utils.make_title( _( "Prefer Dark Mode" ) ) );
    dark_lbl.xalign     = (float)0;
    dark_lbl.use_markup = true;

    var dark_tgl = new Switch();
    dark_tgl.set_active( _theme.prefer_dark );
    dark_tgl.button_release_event.connect((e) => {
      _theme.prefer_dark = !_theme.prefer_dark;
      return( false );
    });

    grid.attach( dark_lbl, 0, 11 );
    grid.attach( dark_tgl, 1, 11 );

    add( grid );

    border_width = 5;

    show_all();

  }

  /* Adds a coloring row */
  private void add_color( string lbl_str, RGBA color, Grid grid, int row ) {

    var lbl        = new Label( Utils.make_title( lbl_str ) );
    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    var btn = new ColorButton();
    btn.rgba = color;
    btn.color_set.connect(() => {
      color.parse( Utils.color_from_rgba( btn.rgba ) );
    });

    grid.attach( lbl, 0, row );
    grid.attach( btn, 1, row, 2 );

  }

}
