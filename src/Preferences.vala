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

public class Preferences : Gtk.Dialog {

  private MainWindow    _win;
  private GLib.Settings _settings;

  /* Constructor */
  public Preferences( MainWindow win, GLib.Settings settings ) {

    Object(
      border_width: 5,
      deletable: false,
      resizable: false,
      title: _("Preferences"),
      transient_for: win
    );

    _win      = win;
    _settings = settings;

    var stack = new Stack();
    stack.margin        = 6;
    stack.margin_bottom = 18;
    stack.margin_top    = 24;
    stack.add_titled( create_behavior(), "behavior", _( "Behavior" ) );
    stack.add_titled( create_appearance(), "appearance", _( "Appearance" ) );

    var switcher = new StackSwitcher();
    switcher.set_stack( stack );
    switcher.halign = Align.CENTER;

    var box = new Box( Orientation.VERTICAL, 0 );
    box.pack_start( switcher, false, true, 0 );
    box.pack_start( stack,    true,  true, 0 );

    get_content_area().add( box );

    /* Create close button at bottom of window */
    var close_button = new Button.with_label( _( "Close" ) );
    close_button.clicked.connect(() => {
      destroy();
    });

    add_action_widget( close_button, 0 );

  }

  private Grid create_behavior() {

    var grid = new Grid();
    grid.column_spacing = 12;
    grid.row_spacing    = 6;

    grid.attach( make_label( "Create new node from edit mode" ), 0, 0 );
    grid.attach( make_switch( "new-node-from-edit" ), 1, 0 );
    grid.attach( make_info( _( "Specifies if we should create a new node directly from edit mode if Return or Tab is pressed." ) ), 2, 0 );

    grid.attach( make_label( "Automatically make embedded URLs into links" ), 0, 1 );
    grid.attach( make_switch( "auto-parse-embedded-urls" ), 1, 1 );
    grid.attach( make_info( _( "Specifies if embedded URLs found in node titles should be automatically highlighted.") ), 2, 1 );

    grid.attach( make_label( "Enable Markdown" ), 0, 2 );
    grid.attach( make_switch( "enable-markdown" ), 1, 2 );

    grid.attach( make_label( "Create connection title on creation" ), 0, 3 );
    grid.attach( make_switch( "edit-connection-title-on-creation" ), 1, 3 );
    grid.attach( make_info( _( "Specifies if the connection title will be added and put into edit mode immediately after the connection is made." ) ), 2, 3 );

    grid.attach( make_label( "Select items on mouse hover" ), 0, 4 );
    grid.attach( make_switch( "select-on-hover" ), 1, 4 );
    grid.attach( make_info( _( "If enabled, selects items when mouse cursor hovers over the item." ) ), 2, 4 );

    return( grid );

  }

  private Grid create_appearance() {

    var grid = new Grid();
    grid.column_spacing = 12;
    grid.row_spacing    = 6;

    grid.attach( make_label( "Default theme" ), 0, 0 );
    grid.attach( make_themes(), 1, 0, 2 );

    grid.attach( make_label( "Enable animations" ),  0, 1 );
    grid.attach( make_switch( "enable-animations" ), 1, 1 );

    grid.attach( make_label( "Text field font size" ), 0, 2 );
    grid.attach( make_switch( "text-field-use-custom-font-size" ), 1, 2 );
    grid.attach( make_spinner( "text-field-custom-font-size", 8, 24, 1 ), 2, 2 );
    grid.attach( make_info( _( "Specifies the custom font size to use in text editing fields (i.e, quick entry or notes field)." ) ), 3, 1 );

    return( grid );

  }

  /* Creates label */
  private Label make_label( string label ) {
    var w = new Label( label );
    w.halign = Align.END;
    margin_start = 12;
    return( w );
  }

  /* Creates switch */
  private Switch make_switch( string setting ) {
    var w = new Switch();
    w.halign = Align.START;
    w.valign = Align.CENTER;
    _settings.bind( setting, w, "active", SettingsBindFlags.DEFAULT );
    return( w );
  }

  private SpinButton make_spinner( string setting, int min_value, int max_value, int step ) {
    var w = new SpinButton.with_range( min_value, max_value, step );
    _settings.bind( setting, w, "value", SettingsBindFlags.DEFAULT );
    return( w );
  }

  /* Creates an information image */
  private Image make_info( string detail ) {
    var w = new Image.from_icon_name( "dialog-information-symbolic", IconSize.MENU );
    w.halign       = Align.START;
    w.tooltip_text = detail;
    return( w );
  }

  /* Creates the theme menu button */
  private MenuButton make_themes() {

    var mb  = new MenuButton();
    var mnu = new Gtk.Menu();

    mb.label = _win.themes.get_theme( _settings.get_string( "default-theme" ) ).label;
    mb.popup = mnu;

    /* Get the available theme names */
    var names = new Array<string>();
    _win.themes.names( ref names );

    for( int i=0; i<names.length; i++ ) {
      var name = names.index( i );
      var lbl  = _win.themes.get_theme( name ).label;
      var item = new Gtk.MenuItem.with_label( lbl );
      item.activate.connect(() => {
        _settings.set_string( "default-theme", name );
        mb.label = lbl;
      });
      mnu.add( item );
    }

    mnu.show_all();

    return( mb );

  }

}
