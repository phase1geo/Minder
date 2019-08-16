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

public class ThemeEditor : Gtk.Box {

  private MainWindow   _win;
  private ThemeCustom? _theme = null;
  private Image        _preview;

  public ThemeEditor( MainWindow win ) {

    Object( orientation:Orientation.VERTICAL, spacing:20 );

    _win   = win;
    _theme = new ThemeCustom();

    var grid = new Grid();
    grid.row_spacing    = 5;
    grid.column_spacing = 30;

    _preview = new Image.from_surface( _theme.make_icon() );
    pack_start( _preview, false, false );

    add_color( _( "Background" ),             _theme.background,         "background",         0, grid, 0 );
    add_color( _( "Foreground" ),             _theme.foreground,         "foreground",         0, grid, 1 );
    add_color( _( "Root Node Background" ),   _theme.root_background,    "root_background",    0, grid, 2 );
    add_color( _( "Root Node Foreground" ),   _theme.root_foreground,    "root_foreground",    0, grid, 3 );
    add_color( _( "Node Select Background" ), _theme.nodesel_background, "nodesel_background", 0, grid, 4 );
    add_color( _( "Node Select Foreground" ), _theme.nodesel_foreground, "nodesel_foreground", 0, grid, 5 );
    add_color( _( "Text Select Background" ), _theme.textsel_background, "textsel_background", 0, grid, 6 );
    add_color( _( "Text Select Foreground" ), _theme.textsel_foreground, "textsel_foreground", 0, grid, 7 );
    add_color( _( "Text Cursor" ),            _theme.text_cursor,        "text_cursor",        0, grid, 8 );
    add_color( _( "Attachable Highlight" ),   _theme.attachable_color,   "attachable_color",   0, grid, 9 );
    add_color( _( "Connection Color" ),       _theme.connection_color,   "connection_color",   0, grid, 10 );

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

    /* Add link colors */
    for( int i=0; i<_theme.num_link_colors(); i++ ) {
      add_color( _( "Link Color" ) + " #%d".printf( i + 1 ), _theme.link_color( i ), "link_color", i, grid, (12 + i) );
    }

    pack_start( grid, true, true );

    /* Create the button bar */
    var bbox = new Box( Orientation.HORIZONTAL, 5 );

    var cancel = new Button.with_label( _( "Cancel" ) );
    cancel.clicked.connect( close_window );

    var save = new Button.with_label( _( "Save" ) );
    save.clicked.connect( save_theme );

    var apply = new Button.with_label( _( "Apply" ) );
    apply.clicked.connect( apply_theme );

    bbox.pack_end( apply,  false, false );
    bbox.pack_end( save,   false, false );
    bbox.pack_end( cancel, false, false );

    pack_end( bbox, false, true );

    border_width = 10;

    show_all();

  }

  /* Adds a coloring row */
  private void add_color( string lbl_str, RGBA color, string type, int index, Grid grid, int row ) {

    var lbl        = new Label( Utils.make_title( lbl_str ) );
    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    var btn = new ColorButton();
    btn.rgba = color;
    btn.color_set.connect(() => {
      set_color( btn.rgba, type, index );
      _preview = new Image.from_surface( _theme.make_icon() );
    });

    grid.attach( lbl, 0, row );
    grid.attach( btn, 1, row, 2 );

  }

  /* Sets the color base on the given type and index */
  private void set_color( RGBA color, string type, int index = 0 ) {
    switch( type ) {
      case "background"         :  _theme.background.parse( Utils.color_from_rgba( color ) );          stdout.printf( "background, old: %s, new: %s\n", color.to_string(), _theme.background.to_string() );  break;
      case "foreground"         :  _theme.foreground.parse( Utils.color_from_rgba( color ) );          break;
      case "root_background"    :  _theme.root_background.parse( Utils.color_from_rgba( color ) );     break;
      case "root_foreground"    :  _theme.root_foreground.parse( Utils.color_from_rgba( color ) );     break;
      case "nodesel_background" :  _theme.nodesel_background.parse( Utils.color_from_rgba( color ) );  break;
      case "nodesel_foreground" :  _theme.nodesel_foreground.parse( Utils.color_from_rgba( color ) );  break;
      case "textsel_background" :  _theme.textsel_background.parse( Utils.color_from_rgba( color ) );  break;
      case "textsel_foreground" :  _theme.textsel_foreground.parse( Utils.color_from_rgba( color ) );  break;
      case "text_cursor"        :  _theme.text_cursor.parse( Utils.color_from_rgba( color ) );         break;
      case "attachable_color"   :  _theme.attachable_color.parse( Utils.color_from_rgba( color ) );    break;
      case "connection_color"   :  _theme.connection_color.parse( Utils.color_from_rgba( color ) );    break;
      default                   :  _theme.change_link_color( index, color );                           break;
    }
  }

  /* Hides the theme editor panel without saving */
  private void close_window() {
    _win.hide_theme_editor();
  }

  /* Saves the theme and hides the theme editor panel */
  private void save_theme() {
    _win.hide_theme_editor();
  }

  private void apply_theme() {

    /* TBD */

  }

}
