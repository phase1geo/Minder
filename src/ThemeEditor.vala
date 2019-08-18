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
using Gee;

public class ThemeEditor : Gtk.Box {

  private MainWindow                  _win;
  private Theme                       _theme;
  private Image                       _preview;
  private string                      _orig_name;
  private bool                        _edit;
  private Entry                       _name;
  private HashMap<string,ColorButton> _btns;
  private Switch                      _prefer_dark;

  public ThemeEditor( MainWindow win ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _win = win;

    var grid = new Grid();
    grid.row_spacing    = 5;
    grid.column_spacing = 30;

    _preview = new Image();
    pack_start( _preview, false, false );

    var nbox = new Box( Orientation.HORIZONTAL, 10 );
    var nlbl = new Label( Utils.make_title( _( "Name" ) + ":" ) );
    nlbl.xalign     = (float)0;
    nlbl.use_markup = true;
    _name    = new Entry();

    nbox.pack_start( nlbl,  false, false );
    nbox.pack_start( _name, true,  false );
    pack_start( nbox, true, true );

    _btns = new HashMap<string,ColorButton>();

    add_color( _( "Background" ),             "background",         grid, 0 );
    add_color( _( "Foreground" ),             "foreground",         grid, 1 );
    add_color( _( "Root Node Background" ),   "root_background",    grid, 2 );
    add_color( _( "Root Node Foreground" ),   "root_foreground",    grid, 3 );
    add_color( _( "Node Select Background" ), "nodesel_background", grid, 4 );
    add_color( _( "Node Select Foreground" ), "nodesel_foreground", grid, 5 );
    add_color( _( "Text Select Background" ), "textsel_background", grid, 6 );
    add_color( _( "Text Select Foreground" ), "textsel_foreground", grid, 7 );
    add_color( _( "Text Cursor" ),            "text_cursor",        grid, 8 );
    add_color( _( "Attachable Highlight" ),   "attachable",         grid, 9 );
    add_color( _( "Connection Color" ),       "connection",         grid, 10 );

    grid.attach( new Label( "" ), 0, 11 );

    var dark_lbl        = new Label( Utils.make_title( _( "Prefer Dark Mode" ) ) );
    dark_lbl.xalign     = (float)0;
    dark_lbl.use_markup = true;

    _prefer_dark = new Switch();
    _prefer_dark.button_release_event.connect((e) => {
      _theme.prefer_dark = !_theme.prefer_dark;
      return( false );
    });

    grid.attach( dark_lbl,     0, 12 );
    grid.attach( _prefer_dark, 1, 12 );
    grid.attach( new Label( "" ), 0, 13 );

    /* Add link colors */
    for( int i=0; i<Theme.num_link_colors(); i++ ) {
      add_color( _( "Link Color" ) + " #%d".printf( i + 1 ), "link_color%d".printf( i ), grid, (14 + i) );
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
  private void add_color( string lbl_str, string name, Grid grid, int row ) {

    var lbl        = new Label( Utils.make_title( lbl_str ) );
    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    var btn = new ColorButton();
    btn.color_set.connect(() => {
      _theme.set_color( name, btn.rgba );
      _preview.surface = _theme.make_icon();
    });
    _btns.set( name, btn );

    grid.attach( lbl, 0, row );
    grid.attach( btn, 1, row, 2 );

  }

  /* This should be called prior to editing a theme */
  public void initialize( Theme theme, bool edit ) {
    
    /* Initialize class variables */
    _orig_name = theme.name;
    _edit      = edit;
    _theme     = new Theme.from_theme( theme );

    /* Figure out a unique name for the new theme */
    var names   = new Array<string>();
    var largest = 0;
    var index   = 0;
    _win.themes.names( ref names );
    for( int i=0; i<names.length; i++ ) {
      if( (names.index( i ).scanf( (_( "Custom" ) + " #%d"), &index ) != 0) && (largest < index) ) {
        largest = index;
      }
    }
    _theme.name = _( "Custom" ) + " #%d".printf( largest );

    /* Initialize the UI */
    var colors = _theme.colors();
    for( int i=0; i<colors.length; i++ ) {
      _btns.get( colors.index( i ) ).rgba = _theme.get_color( colors.index( i ) );
    }
    _name.text       = _theme.name;
    _preview.surface = _theme.make_icon();
    _prefer_dark.set_active( _theme.prefer_dark );

  }

  /* Hides the theme editor panel without saving */
  private void close_window() {
    _win.hide_theme_editor();
  }

  /* Saves the theme and hides the theme editor panel */
  private void save_theme() {
    _win.themes.add_theme( _theme );
    _win.hide_theme_editor();
  }

  private void apply_theme() {
    _win.get_current_da().set_theme( _theme );
  }

}
