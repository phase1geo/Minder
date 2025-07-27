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

  private MainWindow _win;
  private MenuButton _theme_mb;

  private const GLib.ActionEntry[] action_entries = {
    { "action_set_default_theme", action_set_default_theme, "s" },
  };

  //-------------------------------------------------------------
  // Constructor
  public Preferences( MainWindow win ) {

    Object(
      deletable: false,
      resizable: false,
      title: _("Preferences"),
      transient_for: win
    );

    _win = win;

    var stack = new Stack() {
      halign        = Align.FILL,
      valign        = Align.FILL,
      margin_start  = 6,
      margin_end    = 6,
      margin_bottom = 18,
      margin_top    = 24
    };
    stack.add_titled( create_behavior(),   "behavior",   _( "Behavior" ) );
    stack.add_titled( create_appearance(), "appearance", _( "Appearance" ) );
    stack.add_titled( create_shortcuts(),  "shortcuts",  _( "Shortcuts" ) );

    var switcher = new StackSwitcher() {
      halign = Align.CENTER,
      stack  = stack
    };

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( switcher );
    box.append( stack );

    get_content_area().append( box );

    /* Create close button at bottom of window */
    var close_button = new Button.with_label( _( "Close" ) );
    close_button.clicked.connect(() => {
      destroy();
    });

    add_action_widget( close_button, 0 );

  }

  private Grid create_behavior() {

    var grid = new Grid() {
      column_spacing = 12,
      row_spacing    = 6
    };

    grid.attach( make_label( _( "Create new node from edit mode" ) ), 0, 0 );
    grid.attach( make_switch( "new-node-from-edit" ), 1, 0 );
    grid.attach( make_info( _( "Specifies if we should create a new node directly from edit mode if Return or Tab is pressed." ) ), 3, 0 );

    grid.attach( make_label( _( "Automatically make embedded URLs into links" ) ), 0, 1 );
    grid.attach( make_switch( "auto-parse-embedded-urls" ), 1, 1 );
    grid.attach( make_info( _( "Specifies if embedded URLs found in node titles should be automatically highlighted.") ), 3, 1 );

    grid.attach( make_label( _( "Enable Markdown" ) ), 0, 2 );
    grid.attach( make_switch( "enable-markdown" ), 1, 2 );

    grid.attach( make_label( _( "Enable Unicode input" ) ), 0, 3 );
    grid.attach( make_switch( "enable-unicode-input" ), 1, 3 );
    grid.attach( make_info( _( "Specifies if Unicode characters can be input using backslash prefixed descriptors (ex. \\pi)" ) ), 3, 3 );

    grid.attach( make_label( _( "Create connection title on creation" ) ), 0, 4 );
    grid.attach( make_switch( "edit-connection-title-on-creation" ), 1, 4 );
    grid.attach( make_info( _( "Specifies if the connection title will be added and put into edit mode immediately after the connection is made." ) ), 3, 4 );

    grid.attach( make_label( _( "Select items on mouse hover" ) ), 0, 5 );
    grid.attach( make_switch( "select-on-hover" ), 1, 5 );
    grid.attach( make_info( _( "If enabled, selects items when mouse cursor hovers over the item." ) ), 3, 5 );

    return( grid );

  }

  private Grid create_appearance() {

    var grid = new Grid() {
      column_spacing = 12,
      row_spacing    = 6
    };

    grid.attach( make_label( _( "Hide themes not matching visual style" ) ), 0, 0 );
    grid.attach( make_switch( "hide-themes-not-matching-visual-style" ), 1, 0 );

    grid.attach( make_label( _( "Default theme" ) ), 0, 1 );
    grid.attach( make_themes(), 1, 1, 2 );
    grid.attach( make_info( _( "Sets the default theme to use for newly created mindmaps (use Map sidebar panel to make immediate changes)." ) ), 3, 1 );

    grid.attach( make_label( _( "Enable animations" ) ),  0, 2 );
    grid.attach( make_switch( "enable-animations" ), 1, 2 );

    grid.attach( make_label( _( "Text field font size" ) ), 0, 3 );
    grid.attach( make_switch( "text-field-use-custom-font-size" ), 1, 3 );
    grid.attach( make_spinner( "text-field-custom-font-size", 8, 24, 1 ), 2, 3 );
    grid.attach( make_info( _( "Specifies the custom font size to use in text editing fields (i.e, quick entry or notes field)." ) ), 3, 3 );

    grid.attach( make_label( _( "Colorize note fields" ) ), 0, 4 );
    grid.attach( make_switch( "colorize-notes" ), 1, 4 );

    return( grid );

  }

  private ScrolledWindow create_shortcuts() {

    var grid = new Grid() {
      column_spacing = 12,
      row_spacing    = 6
    };

    var row = 0;
    for( int i=0; i<KeyCommand.NUM; i++ ) {
      var command = (KeyCommand)i;
      if( command.viewable() ) {
        if( command.is_start() ) {
          grid.attach( make_label( command.shortcut_label() ), 0, row, 3 );
        } else {
          grid.attach( make_label( "  " ), 0, row );
          grid.attach( make_label( command.shortcut_label() ), 1, row );
          grid.attach( make_shortcut( command ), 2, row );
        }
        row++;
      }
    }

    var sw = new ScrolledWindow() {
      vscrollbar_policy = PolicyType.ALWAYS,
      hscrollbar_policy = PolicyType.NEVER,
      child = grid
    };

    return( sw );

  }

  //-------------------------------------------------------------
  // Creates label
  private Label make_label( string label ) {
    var w = new Label( label ) {
      halign = Align.END
    };
    margin_start = 12;
    return( w );
  }

  //-------------------------------------------------------------
  // Creates switch
  private Switch make_switch( string setting ) {
    var w = new Switch() {
      halign = Align.START,
      valign = Align.CENTER
    };
    Minder.settings.bind( setting, w, "active", SettingsBindFlags.DEFAULT );
    return( w );
  }

  //-------------------------------------------------------------
  // Creates spinner widget.
  private SpinButton make_spinner( string setting, int min_value, int max_value, int step ) {
    var w = new SpinButton.with_range( min_value, max_value, step );
    Minder.settings.bind( setting, w, "value", SettingsBindFlags.DEFAULT );
    return( w );
  }

  //-------------------------------------------------------------
  // Creates an information image.
  private Image make_info( string detail ) {
    var w = new Image.from_icon_name( "dialog-information-symbolic" ) {
      halign       = Align.START,
      tooltip_text = detail
    };
    return( w );
  }

  //-------------------------------------------------------------
  // Creates a shortcut widget.  When entered, allows the shortcut
  // to be created/modified.
  private Entry make_shortcut( KeyCommand command ) {
    var shortcut = _win.shortcuts.get_shortcut( command );
    var e = new Entry() {
      text             = (shortcut != null) ? shortcut.get_accelerator() : "",
      placeholder_text = (shortcut == null) ? _( "Click to set" )        : ""
    };
    return( e );
  }

  //-------------------------------------------------------------
  // Creates the theme menu button
  private MenuButton make_themes() {

    /* Get the available theme names */
    var names = new Array<string>();
    _win.themes.names( ref names );

    var menu = new GLib.Menu();

    for( int i=0; i<names.length; i++ ) {
      var name = names.index( i );
      var lbl  = _win.themes.get_theme( name ).label;
      menu.append( lbl, "prefs.action_set_default_theme('%s')".printf( name ) );
    }

    _theme_mb = new MenuButton() {
      label      = _win.themes.get_theme( Minder.settings.get_string( "default-theme" ) ).label,
      menu_model = menu
    };

    return( _theme_mb );

  }

  //-------------------------------------------------------------
  // Sets the default theme setting to the given theme name.
  private void action_set_default_theme( SimpleAction action, Variant? variant ) {
    if( variant != null ) {
      var name = variant.get_string();
      Minder.settings.set_string( "default-theme", name );
      _theme_mb.label = _win.themes.get_theme( name ).label;
    }
  }

}
