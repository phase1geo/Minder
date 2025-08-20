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

public class Preferences : Gtk.Window {

  private MainWindow _win;
  private MenuButton _theme_mb;
  private string     _shortcut_inst_start_str;
  private string     _shortcut_inst_edit_str;
  private Label      _shortcut_instructions;

  private const GLib.ActionEntry[] action_entries = {
    { "action_set_default_theme",    action_set_default_theme, "s" },
    { "action_clear_all_shortcuts",  action_clear_all_shortcuts },
    { "action_set_minder_shortcuts", action_set_minder_shortcuts },
  };

  //-------------------------------------------------------------
  // Constructor
  public Preferences( MainWindow win ) {

    Object(
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
      stack  = stack,
      margin_top = 10
    };

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( switcher );
    box.append( stack );

    child = box;

    // Set the stage for menu actions
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "prefs", actions );

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

    grid.attach( make_label( _( "Rotate main branch link colors" ) ), 0, 6 );
    grid.attach( make_switch( "rotate-main-link-colors" ), 1, 6 );
    grid.attach( make_info( _( "If enabled, causes a new color to be used whenever a main branch is created" ) ), 3, 6 );

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

  private Box create_shortcuts() {

    var grid = new Grid() {
      column_spacing  = 12,
      row_spacing     = 6,
      row_homogeneous = true
    };

    var row = 0;
    var section_end_seen = false;
    var group_end_seen   = false;
    for( int i=0; i<KeyCommand.NUM; i++ ) {
      var command = (KeyCommand)i;
      if( command.viewable() ) {
        if( command.is_section_start() ) {
          var box = new Box( Orientation.VERTICAL, 5 );
          if( section_end_seen ) {
            box.append( make_separator() );
          }
          var l = new Label( "<span size=\"large\" weight=\"bold\">" + command.shortcut_label() + "</span>" ) {
            halign     = Align.START,
            use_markup = true
          };
          box.append( l );
          grid.attach( box, 0, row, 4 );
          group_end_seen = false;
        } else if( command.is_section_end() ) {
          section_end_seen = true;
        } else if( command.is_group_start() ) {
          var box = new Box( Orientation.VERTICAL, 5 );
          if( group_end_seen ) {
            box.append( make_separator() );
          }
          var l = new Label( command.shortcut_label() ) {
            halign = Align.START,
            use_markup = true
          };
          l.add_css_class( "titled" );
          box.append( l );
          grid.attach( box, 1, row, 3 );
        } else if( command.is_group_end() ) {
          group_end_seen = true;
        } else {
          var prefix   = make_label( "    " );
          var label    = make_label( command.shortcut_label() );
          var shortcut = make_shortcut( command );
          grid.attach( prefix,   1, row );
          grid.attach( label,    2, row );
          grid.attach( shortcut, 3, row );
        }
        row++;
      }
    }

    var sw = new ScrolledWindow() {
      vscrollbar_policy = PolicyType.AUTOMATIC,
      hscrollbar_policy = PolicyType.NEVER,
      overlay_scrolling = false,
      hexpand           = true,
      margin_top = 20,
      child = grid
    };
    sw.set_size_request( 400, 500 );

    _shortcut_inst_start_str = _( "Double-click to edit shortcut.  Select + Delete to remove shortcut." );
    _shortcut_inst_edit_str  = _( "Escape to cancel.  Press key combination to set." );

    _shortcut_instructions = new Label( _shortcut_inst_start_str ) {
      halign  = Align.CENTER,
      hexpand = true,
    };

    var default_menu = new GLib.Menu();
    default_menu.append( _( "Set Minder Defaults" ), "prefs.action_set_minder_shortcuts" );

    var clear_menu = new GLib.Menu();
    clear_menu.append( _( "Clear All Shortcuts" ), "prefs.action_clear_all_shortcuts" );

    var menu = new GLib.Menu();
    menu.append_section( null, default_menu );
    menu.append_section( null, clear_menu );

    var search_btn = new Button.from_icon_name( "system-search-symbolic" );
    var search = new SearchEntry() {
      halign           = Align.FILL,
      placeholder_text = _( "Search commands" ),
      visible          = false,
      tooltip_text     = _( "Search shortcuts" )
    };

    var search_key = new EventControllerKey();
    search.add_controller( search_key );

    search.search_changed.connect(() => {
      update_search_results( grid, search.text );
      grid.row_homogeneous = (search.text == "");
    });

    search_btn.clicked.connect(() => {
      search.visible = !search.visible;
      search.text    = "";
      search.grab_focus();
    });

    search_key.key_pressed.connect((keyval, keycode, state) => {
      if( keyval == Gdk.Key.Escape ) {
        search.visible = false;
        search.text    = "";
        search_btn.grab_focus();
        return( true );
      }
      return( false );
    });

    var more = new MenuButton() {
      halign     = Align.END,
      icon_name  = "view-more-symbolic",
      menu_model = menu
    };

    var hbox = new Box( Orientation.HORIZONTAL, 5 );
    hbox.append( _shortcut_instructions );
    hbox.append( search_btn );
    hbox.append( more );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( hbox );
    box.append( search );
    box.append( sw );

    return( box );

  }

  //-------------------------------------------------------------
  // Called whenever the search results match.  Updates the shortcut list.
  private void update_search_results( Grid grid, string text ) {
    Widget? current_section = null;
    Widget? current_group   = null;
    var row = 0;
    for( int i=0; i<KeyCommand.NUM; i++ ) {
      var command = (KeyCommand)i;
      if( command.viewable() ) {
        if( command.is_section_start() ) {
          current_section = grid.get_child_at( 0, row );
          assert( current_section != null );
          if( current_section != null ) {
            current_section.visible = false;
          }
        } else if( command.is_group_start() ) {
          current_group = grid.get_child_at( 1, row );
          assert( current_group != null );
          if( current_group != null ) {
            current_group.visible = false;
          }
        } else if( !command.is_section_end() && !command.is_group_end() ) {
          var matched = (text == "") || command.shortcut_label().down().contains( text.down() );
          if( matched ) {
            if( current_section != null ) {
              current_section.visible = matched;
            }
            if( current_group != null ) {
              current_group.visible = matched;
            }
          }
          for( int j=1; j<4; j++ ) {
            var w = grid.get_child_at( j, row );
            if( w != null ) {
              w.visible = matched;
            }
          }
        }
        row++;
      }
    }
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
  // Creates a shortcut widget to display and interact with the
  // current shortcut.
  private Stack make_shortcut( KeyCommand command ) {

    var disabled = _( "None" );
    var enter    = _( "Enter shortcut" );
    var shortcut = _win.shortcuts.get_shortcut( command );

    var sl = new ShortcutLabel( (shortcut != null) ? shortcut.get_accelerator() : "" ) {
      halign    = Align.START,
      can_focus = command.editable(),
      focusable = command.editable()
    };
    sl.add_css_class( "shortcut-unselected" );

    var sl_focus = new EventControllerFocus();
    var sl_key   = new EventControllerKey();
    var sl_click = new GestureClick() {
      button = Gdk.BUTTON_PRIMARY
    };

    sl.add_controller( sl_focus );
    sl.add_controller( sl_key );
    sl.add_controller( sl_click );

    var nl = new EditableLabel( disabled ) {
      halign    = Align.START,
      editable  = false,
      can_focus = command.editable(),
      focusable = command.editable()
    };
    nl.add_css_class( "shortcut-unselected" );

    var nl_focus = new EventControllerFocus();
    var nl_key   = new EventControllerKey();
    var nl_click = new GestureClick() {
      button = Gdk.BUTTON_PRIMARY
    };

    nl.add_controller( nl_focus );
    nl.add_controller( nl_key );
    nl.add_controller( nl_click );

    var stack = new Stack();
    stack.add_named( sl, "set" );
    stack.add_named( nl, "unset" );
    stack.visible_child_name = (shortcut != null) ? "set" : "unset";

    sl_focus.enter.connect(() => {
      sl.add_css_class( "shortcut-selected" );
    });

    sl_focus.leave.connect(() => {
      sl.remove_css_class( "shortcut-selected" );
    });

    sl_click.pressed.connect((n_press, x, y) => {
      sl.grab_focus();
      if( n_press == 2 ) {
        nl.text = enter;
        _shortcut_instructions.label = _shortcut_inst_edit_str;
        stack.visible_child_name = "unset";
        nl.grab_focus();
      }
    });

    sl_key.key_pressed.connect((keyval, keycode, state) => {
      if( (keyval == Key.Delete) || (keyval == Key.BackSpace) ) {
        _win.shortcuts.clear_shortcut( command );
        shortcut = null;
        nl.text  = disabled;
        stack.visible_child_name = "unset";
        nl.grab_focus();
        return( true );
      } else if( keyval == Key.Return ) {
        nl.text = enter;
        _shortcut_instructions.label = _shortcut_inst_edit_str;
        stack.visible_child_name = "unset";
        nl.grab_focus();
        return( true );
      }
      return( false );
    });

    nl_focus.enter.connect(() => {
      nl.add_css_class( "shortcut-selected" );
    });

    nl_focus.leave.connect(() => {
      nl.remove_css_class( "shortcut-selected" );
      if( nl.text == enter ) {
        if( shortcut != null ) {
          stack.visible_child_name = "set";
          sl.grab_focus();
        } else {
          nl.text = disabled;
        }
        _shortcut_instructions.label = _shortcut_inst_start_str;
      }
    });

    nl_click.pressed.connect((n_press, x, y) => {
      nl.grab_focus();
      if( n_press == 2 ) {
        nl.text = enter;
        _shortcut_instructions.label = _shortcut_inst_edit_str;
      }
    });

    nl_key.key_pressed.connect((keyval, keycode, state) => {
      if( nl.text == disabled ) {
        if( keyval == Key.Return ) {
          nl.text = enter;
          _shortcut_instructions.label = _shortcut_inst_edit_str;
          return( true );
        }
      } else {
        if( (keyval == Key.Delete) || (keyval == Key.BackSpace) ) {
          _win.shortcuts.clear_shortcut( command );
          shortcut = null;
          nl.text = disabled;
          _shortcut_instructions.label = _shortcut_inst_start_str;
        } else if( keyval == Key.Escape ) {
          if( shortcut != null ) {
            stack.visible_child_name = "set";
            sl.grab_focus();
          } else {
            nl.text = disabled;
          }
          _shortcut_instructions.label = _shortcut_inst_start_str;
        } else if( (keyval != Key.Control_L) && (keyval != Key.Control_R) &&
                   (keyval != Key.Shift_L)   && (keyval != Key.Shift_L)   &&
                   (keyval != Key.Alt_L)     && (keyval != Key.Alt_R)  && (keyval != 0) ) {
          var control  = (bool)((state & ModifierType.CONTROL_MASK) == ModifierType.CONTROL_MASK);
          var shift    = (bool)((state & ModifierType.SHIFT_MASK)   == ModifierType.SHIFT_MASK);
          var alt      = (bool)((state & ModifierType.ALT_MASK)     == ModifierType.ALT_MASK);
          var conflict = _win.shortcuts.shortcut_conflicts_with( keyval, control, shift, alt, command );
          var scut     = new Shortcut( keyval, control, shift, alt, command );
          if( conflict == null ) {
            shortcut = scut;
            _win.shortcuts.set_shortcut( shortcut );
            sl.accelerator = shortcut.get_accelerator();
            stack.visible_child_name = "set";
            sl.grab_focus();
            _shortcut_instructions.label = _shortcut_inst_start_str;
          } else {
            show_conflict_dialog( scut, conflict );
          }
        }
        return( true );
      }
      return( false );
    });

    return( stack );

  }

  //-------------------------------------------------------------
  // Displays a dialog to display the reason for the shortcut
  // conflict.
  private void show_conflict_dialog( Shortcut attempt, Shortcut conflict ) {

    var dialog = new Granite.MessageDialog.with_image_from_icon_name(
      _( "Unable to set new shortcut due to conflicts" ),
      _( "%s conflicts with '%s'" ).printf(
        Granite.accel_to_string( attempt.get_accelerator() ),
        conflict.command.shortcut_label()
      ),
      "dialog-error"
    ) {
      modal = true,
      transient_for = this
    };

    dialog.response.connect((id) => {
      dialog.close();
    });

    dialog.present();

  }

  //-------------------------------------------------------------
  // Creates a horizontal separator.
  private Separator make_separator() {
    var s = new Separator( Orientation.HORIZONTAL );
    return( s );
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

  //-------------------------------------------------------------
  // Clears all of the shortcuts so that the user can set things
  // up from scratch.
  private void action_clear_all_shortcuts() {
    Utils.create_confirmation_dialog(
      this, _( "Clear all shortcuts?" ), _( "Current shortcut settings will be lost" ),
      () => {
        _win.shortcuts.clear_all_shortcuts();
      }
    );
  }

  //-------------------------------------------------------------
  // Resets all shortcuts to match the default shortcuts for Minder.
  private void action_set_minder_shortcuts() {
    Utils.create_confirmation_dialog(
      this, _( "Use Minder Default Shortcuts?" ), _( "Current shortcut settings will be lost" ),
      () => {
        _win.shortcuts.restore_default_shortcuts();
        _win.shortcuts.save();
      }
    );
  }

}
