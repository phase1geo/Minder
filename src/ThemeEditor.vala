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
  private Theme                       _orig_theme;
  private bool                        _edit;
  private Entry                       _name;
  private HashMap<string,ColorButton> _btns;
  private Switch                      _prefer_dark;
  private Revealer                    _delrev;

  public ThemeEditor( MainWindow win ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _win  = win;
    _btns = new HashMap<string,ColorButton>();

    /* Add title */
    var title = new Label( Utils.make_title( _( "Customize Theme" ) + "\n" ) );
    title.use_markup = true;
    pack_start( title, false, true );

    /* Add name label */
    var nbox = new Box( Orientation.HORIZONTAL, 10 );
    var nlbl = new Label( Utils.make_title( _( "Name" ) + ":" ) );
    nlbl.xalign     = (float)0;
    nlbl.use_markup = true;
    _name    = new Entry();
    _name.focus_out_event.connect((e) => {
      if( !_edit || (_name.text != _orig_theme.name) ) {
        _name.text = _win.themes.uniquify_name( _name.text );
      }
      return( false );
    });

    nbox.pack_start( nlbl,  false, false );
    nbox.pack_start( _name, true, true );
    pack_start( nbox, false, true );

    /* Create scrollable options grid */
    var sw = new ScrolledWindow( null, null );
    var vp = new Viewport( null, null );
    vp.set_size_request( 180, 600 );
    sw.add( vp );
    pack_start( sw, true, true );

    /* Add theme options to grid */
    var grid = new Grid();
    grid.row_spacing    = 5;
    grid.column_spacing = 30;
    grid.border_width   = 5;
    vp.add( grid );

    var color_lbl = new Label( Utils.make_title( _( "Base Colors" ) + "\n" ) );
    color_lbl.xalign     = (float)0;
    color_lbl.use_markup = true;
    grid.attach( color_lbl, 0, 0, 2 );

    add_color( _( "Background" ),             "background",         grid, 1 );
    add_color( _( "Foreground" ),             "foreground",         grid, 2 );
    add_color( _( "Root Node Background" ),   "root_background",    grid, 3 );
    add_color( _( "Root Node Foreground" ),   "root_foreground",    grid, 4 );
    add_color( _( "Node Select Background" ), "nodesel_background", grid, 5 );
    add_color( _( "Node Select Foreground" ), "nodesel_foreground", grid, 6 );
    add_color( _( "Text Select Background" ), "textsel_background", grid, 7 );
    add_color( _( "Text Select Foreground" ), "textsel_foreground", grid, 8 );
    add_color( _( "Text Cursor" ),            "text_cursor",        grid, 9 );
    add_color( _( "Attachable Highlight" ),   "attachable",         grid, 10 );
    add_color( _( "Connection Color" ),       "connection",         grid, 11 );

    grid.attach( new Label( "" ), 0, 12 );

    var dark_lbl        = new Label( Utils.make_title( _( "Prefer Dark Mode" ) ) );
    dark_lbl.xalign     = (float)0;
    dark_lbl.use_markup = true;

    _prefer_dark = new Switch();
    _prefer_dark.button_release_event.connect((e) => {
      _theme.prefer_dark = !_theme.prefer_dark;
      _win.get_current_da().set_theme( _theme, true );
      return( false );
    });

    grid.attach( dark_lbl,     0, 13 );
    grid.attach( _prefer_dark, 1, 13 );
    grid.attach( new Label( "" ), 0, 14 );

    var link_lbl = new Label( Utils.make_title( _( "Link Colors" ) + "\n" ) );
    link_lbl.xalign     = (float)0;
    link_lbl.use_markup = true;
    grid.attach( link_lbl, 0, 15, 2 );

    /* Add link colors */
    for( int i=0; i<Theme.num_link_colors(); i++ ) {
      add_color( _( "Link Color" ) + " #%d".printf( i + 1 ), "link_color%d".printf( i ), grid, (16 + i) );
    }

    /* Create the button bar */
    var bbox = new Box( Orientation.HORIZONTAL, 5 );

    _delrev = new Revealer();
    var del = new Button.with_label( _( "Delete" ) );
    del.get_style_context().add_class( "destructive-action" );
    del.clicked.connect( confirm_deletion );
    _delrev.add( del );

    var cancel = new Button.with_label( _( "Cancel" ) );
    cancel.clicked.connect( close_window );

    var save = new Button.with_label( _( "Save" ) );
    save.get_style_context().add_class( STYLE_CLASS_SUGGESTED_ACTION );
    save.clicked.connect( save_theme );

    bbox.pack_start( _delrev, false, false );
    bbox.pack_end(   save,    false, false );
    bbox.pack_end(   cancel,  false, false );

    pack_end( bbox, false, true );

    border_width = 10;

    show_all();

  }

  /* Adds a coloring row */
  private void add_color( string lbl_str, string name, Grid grid, int row ) {

    // var lbl        = new Label( Utils.make_title( lbl_str ) );
    var lbl        = new Label( "  " + lbl_str );
    lbl.xalign     = (float)0;
    // lbl.use_markup = true;

    var btn = new ColorButton();
    btn.color_set.connect(() => {
      _theme.set_color( name, btn.rgba );
      _win.get_current_da().set_theme( _theme, true );
    });
    _btns.set( name, btn );

    grid.attach( lbl, 0, row );
    grid.attach( btn, 1, row, 2 );

  }

  /* This should be called prior to editing a theme */
  public void initialize( Theme theme, bool edit ) {
    
    /* Initialize class variables */
    _orig_theme = theme;
    _edit       = edit;
    _theme      = new Theme.from_theme( theme );

    /* Figure out a unique name for the new theme */
    if( !edit ) {
      _theme.name = _win.themes.uniquify_name( _( "Custom" ) + " #1" );
    }

    /* Initialize the UI */
    var colors = _theme.colors();
    for( int i=0; i<colors.length; i++ ) {
      _btns.get( colors.index( i ) ).rgba = _theme.get_color( colors.index( i ) );
    }
    _name.text       = _theme.name;
    _prefer_dark.set_active( _theme.prefer_dark );
    _delrev.reveal_child = edit;

  }

  /* Displays the dialog window to confirm theme deletion */
  private void confirm_deletion() {

    var dialog = new Granite.MessageDialog.with_image_from_icon_name(
      _( "Delete theme?" ),
      _( "This operation cannot be undone." ),
      "dialog-warning",
      ButtonsType.NONE
    );

    var no = new Button.with_label( _( "No" ) );
    dialog.add_action_widget( no, ResponseType.CANCEL );

    var yes = new Button.with_label( _( "Yes" ) );
    yes.get_style_context().add_class( STYLE_CLASS_SUGGESTED_ACTION );
    dialog.add_action_widget( yes, ResponseType.ACCEPT );

    dialog.set_transient_for( _win );
    dialog.set_default_response( ResponseType.ACCEPT );
    dialog.set_title( "" );

    dialog.show_all();

    var res = dialog.run();

    dialog.destroy();

    if( res == ResponseType.ACCEPT ) {
      delete_theme();
    }

  }

  /* Deletes the current theme */
  private void delete_theme() {
    _win.get_current_da().set_theme( _win.themes.get_theme( _( "Default" ) ), true );
    _win.themes.delete_theme( _orig_theme.name );
    _win.hide_theme_editor();
  }

  /* Hides the theme editor panel without saving */
  private void close_window() {
    _win.get_current_da().set_theme( _orig_theme, true );
    _win.hide_theme_editor();
  }

  /* Saves the theme and hides the theme editor panel */
  private void save_theme() {
    _theme.name = _name.text;
    if( _edit ) {
      _orig_theme.copy( _theme );
      _win.themes.themes_changed();
    } else {
      _win.themes.add_theme( _theme );
    }
    _win.hide_theme_editor();
  }

}
