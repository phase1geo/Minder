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
  private Button                      _del;

  public ThemeEditor( MainWindow win ) {

    Object(
      orientation:   Orientation.VERTICAL,
      spacing:       10,
      margin_start:  10,
      margin_end:    10,
      margin_top:    10,
      margin_bottom: 10
    );

    _win  = win;
    _btns = new HashMap<string,ColorButton>();

    /* Add title */
    var title = new Label( Utils.make_title( _( "Customize Theme" ) + "\n" ) ) {
      use_markup = true
    };
    append( title );

    /* Add name label */
    var nlbl = new Label( Utils.make_title( _( "Name" ) + ":" ) ) {
      xalign     = (float)0,
      use_markup = true 
    };
    _name = new Entry();
    var entry_focus = new EventControllerFocus();
    _name.add_controller( entry_focus );
    entry_focus.leave.connect(() => {
      if( !_edit || (_name.text != _orig_theme.name) ) {
        _name.text = _win.themes.uniquify_name( _name.text );
      }
    });

    var nbox = new Box( Orientation.HORIZONTAL, 10 ) {
      halign = Align.FILL
    };
    nbox.append( nlbl );
    nbox.append( _name );
    append( nbox );

    /* Add theme options to grid */
    var grid = new Grid() {
      row_spacing    = 5,
      column_spacing = 30,
      margin_start   = 5,
      margin_end     = 5,
      margin_top     = 5,
      margin_bottom  = 5
    };

    /* Create scrollable options grid */
    var sw = new ScrolledWindow() {
      vexpand = true,
      child = grid
    };
    sw.child.set_size_request( 180, 600 );
    append( sw );

    var color_lbl = new Label( Utils.make_title( _( "Base Colors" ) + "\n" ) ) {
      xalign     = (float)0,
      use_markup = true
    };
    grid.attach( color_lbl, 0, 0, 2 );

    add_color( _( "Background" ),             "background",            grid, 1 );
    add_color( _( "Foreground" ),             "foreground",            grid, 2 );
    add_color( _( "Root Node Background" ),   "root_background",       grid, 3 );
    add_color( _( "Root Node Foreground" ),   "root_foreground",       grid, 4 );
    add_color( _( "Node Select Background" ), "nodesel_background",    grid, 5 );
    add_color( _( "Node Select Foreground" ), "nodesel_foreground",    grid, 6 );
    add_color( _( "Text Select Background" ), "textsel_background",    grid, 7 );
    add_color( _( "Text Select Foreground" ), "textsel_foreground",    grid, 8 );
    add_color( _( "Text Cursor" ),            "text_cursor",           grid, 9 );
    add_color( _( "Attachable Highlight" ),   "attachable",            grid, 10 );
    add_color( _( "Connection Color" ),       "connection_background", grid, 11 );
    add_color( _( "Connection Title Color" ), "connection_foreground", grid, 12 );
    add_color( _( "Callout Background" ),     "callout_background",    grid, 13 );
    add_color( _( "URL Link Background" ),    "url_background",        grid, 14 );
    add_color( _( "URL Link Foreground" ),    "url_foreground",        grid, 15 );
    add_color( _( "Tag" ),                    "tag",                   grid, 16 );
    add_color( _( "Markdown Syntax Chars" ),  "syntax",                grid, 17 );
    add_color( _( "Match Background" ),       "match_background",      grid, 18 );
    add_color( _( "Match Foreground" ),       "match_foreground",      grid, 19 );
    add_color( _( "Markdown List Item" ),     "markdown_listitem",     grid, 20 );

    var row = 20;

    grid.attach( new Label( "" ), 0, row );

    var dark_lbl = new Label( Utils.make_title( _( "Prefer Dark Mode" ) ) ) {
      xalign     = (float)0,
      use_markup = true
    };

    _prefer_dark = new Switch() {
      margin_top = 20
    };
    _prefer_dark.notify["active"].connect((e) => {
      _theme.prefer_dark = !_theme.prefer_dark;
      _win.get_current_da().map.set_theme( _theme, true );
    });

    grid.attach( dark_lbl,     0, (row + 1) );
    grid.attach( _prefer_dark, 1, (row + 1) );
    grid.attach( new Label( "" ), 0, (row + 2) );

    var link_lbl = new Label( Utils.make_title( _( "Link Colors" ) + "\n" ) ) {
      xalign     = (float)0,
      use_markup = true
    };
    grid.attach( link_lbl, 0, (row + 3), 2 );

    /* Add link colors */
    for( int i=0; i<Theme.num_link_colors(); i++ ) {
      add_color( _( "Link Color" ) + " #%d".printf( i + 1 ), "link_color%d".printf( i ), grid, ((row + 4) + i) );
    }

    /* Create the button bar */
    _del = new Button.with_label( _( "Delete" ) ) {
      halign  = Align.START,
      hexpand = true,
      visible = false
    };
    _del.add_css_class( "destructive-action" );
    _del.clicked.connect( confirm_deletion );

    var l = new Label( "" ) {
      hexpand = true
    };

    var cancel = new Button.with_label( _( "Cancel" ) ) {
      halign = Align.END
    };
    cancel.clicked.connect( close_window );

    var save = new Button.with_label( _( "Save" ) ) {
      halign = Align.END
    };
    save.add_css_class( Granite.STYLE_CLASS_SUGGESTED_ACTION );
    save.clicked.connect( save_theme );

    var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
      valign = Align.FILL
    };
    bbox.append( _del );
    bbox.append( l );
    bbox.append( cancel );
    bbox.append( save );

    append( bbox );

  }

  /* Adds a coloring row */
  private void add_color( string lbl_str, string name, Grid grid, int row ) {

    var lbl = new Label( "  " + lbl_str ) {
      xalign = (float)0
    };

    var btn = new ColorButton() {
      valign = Align.CENTER
    };
    btn.color_set.connect(() => {
      _theme.set_color( name, btn.rgba );
      _win.get_current_da().map.set_theme( _theme, true );
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
      _theme.name = _theme.label = _win.themes.uniquify_name( _( "Custom" ) + " #1" );
    }

    /* Initialize the UI */
    var colors = _theme.colors();
    for( int i=0; i<colors.length; i++ ) {
      _btns.get( colors.index( i ) ).rgba = _theme.get_color( colors.index( i ) );
    }
    _name.text = _theme.name;
    _prefer_dark.set_active( _theme.prefer_dark );
    _del.visible = edit && !theme.temporary;

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
    yes.add_css_class( Granite.STYLE_CLASS_SUGGESTED_ACTION );
    dialog.add_action_widget( yes, ResponseType.ACCEPT );

    dialog.set_transient_for( _win );
    dialog.set_default_response( ResponseType.ACCEPT );
    dialog.set_title( "" );

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        delete_theme();
      }
    });

  }

  /* Deletes the current theme */
  private void delete_theme() {
    _win.get_current_da().map.set_theme( _win.themes.get_theme( _( "Default" ) ), true );
    _win.themes.delete_theme( _orig_theme.name );
    _win.hide_theme_editor();
  }

  /* Hides the theme editor panel without saving */
  private void close_window() {
    _win.get_current_da().map.set_theme( _orig_theme, true );
    _win.hide_theme_editor();
  }

  /* Saves the theme and hides the theme editor panel */
  private void save_theme() {
    _theme.name = _theme.label = _name.text;
    if( _edit ) {
      _orig_theme.copy( _theme );
      _orig_theme.temporary = false;
      _win.themes.themes_changed();
    } else {
      _win.themes.add_theme( _theme );
    }
    _win.hide_theme_editor();
  }

}
