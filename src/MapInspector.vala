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

public class MapInspector : Box {

  private MainWindow    _win;
  private MindMap?      _map            = null;
  private GLib.Settings _settings;
  private ModeButtons   _layout;
  private Grid?         _theme_grid     = null;
  private Button?       _balance        = null;
  private Button?       _fold_completed = null;
  private Button?       _unfold_all     = null;
  private Switch        _hide_connections;
  private Switch        _hide_callouts;
  private Button        _hleft;
  private Button        _hcenter;
  private Button        _hright;
  private Button        _vtop;
  private Button        _vcenter;
  private Button        _vbottom;
  private Revealer      _alignment_revealer;

  // This signal can be called by outside code to force icons to be updated
  public signal void update_icons();

  //-------------------------------------------------------------
  // Default constructor.
  public MapInspector( MainWindow win, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _win      = win;
    _settings = settings;

    // Create the interface
    add_connection_ui();
    add_callout_ui();
    add_layout_ui();
    add_alignment_ui();
    add_theme_ui();
    add_button_ui();

    // Listen for changes to the current tab
    win.canvas_changed.connect( tab_changed );
    win.themes.themes_changed.connect( update_themes );

    // Listen for preference changes
    _settings.changed.connect( settings_changed );

    // Listen for changes to the system dark mode
    var granite_settings = Granite.Settings.get_default();
    granite_settings.notify["prefers-color-scheme"].connect( () => {
      update_themes();
    });

  }

  //-------------------------------------------------------------
  // Listen for any changes to the current tab in the main window.
  private void tab_changed( MindMap? map ) {
    if( _map != null ) {
      _map.loaded.disconnect( update_theme_layout );
      _map.current_changed.disconnect( current_changed );
    }
    if( map != null ) {
      map.loaded.connect( update_theme_layout );
      map.current_changed.connect( current_changed );
    }
    _map = map;
    if( _map != null ) {
      _map.animator.enable = _settings.get_boolean( "enable-animations" );
      _hide_connections.set_active( _map.model.connections.hide );
      _hide_callouts.set_active( _map.model.hide_callouts );
      _map.model.set_theme( _map.get_theme(), false );
    }
    update_theme_layout();
  }

  //-------------------------------------------------------------
  // Called whenever the preferences change values.  We will
  // update the displayed themes based on the hide setting.
  private void settings_changed( string key ) {
    switch( key ) {
      case "hide-themes-not-matching-visual-style" :  update_themes();  break;
    }
  }

  //-------------------------------------------------------------
  // Add the connection show/hide UI.
  private void add_connection_ui() {

    var lbl = new Label( _( "Hide connections" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0,
    };
    lbl.add_css_class( "titled" );

    _hide_connections = new Switch() {
      halign = Align.END,
      active = false
    };
    _hide_connections.notify["active"].connect( hide_connections_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _hide_connections );

    append( box );

  }

  //-------------------------------------------------------------
  // Called whenever the hide connections switch is changed within
  // the inspector.
  private void hide_connections_changed() {
    _map.selected.clear_connections();
    _map.connections.hide = !_map.connections.hide;
    _map.queue_draw();
  }

  //-------------------------------------------------------------
  // Add the callout show/hide UI.
  private void add_callout_ui() {

    var lbl = new Label( _( "Hide callouts" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0,
    };
    lbl.add_css_class( "titled" );

    _hide_callouts = new Switch() {
      halign = Align.END,
      active = false
    };
    _hide_callouts.notify["active"].connect( hide_callouts_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _hide_callouts );

    append( box );

  }

  //-------------------------------------------------------------
  // Called whenever the hide connections switch is changed within
  // the inspector.
  private void hide_callouts_changed() {
    _map.selected.clear_callouts();
    _map.model.hide_callouts = !_map.model.hide_callouts;
    _map.queue_draw();
  }

  //-------------------------------------------------------------
  // Adds the layout UI.
  private void add_layout_ui() {

    var layouts     = new Layouts();
    var light_icons = new Array<string>();
    var dark_icons  = new Array<string>();
    var names       = new Array<string>();
    layouts.get_icons( ref light_icons, ref dark_icons );
    layouts.get_names( ref names );

    /* Create the modebutton to select the current layout */
    var lbl = new Label( _( "Node Layouts" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0,
    };
    lbl.add_css_class( "titled" );

    _layout = new ModeButtons() {
      halign = Align.END
    };
    _layout.changed.connect( set_layout );
    
    update_icons.connect(() => {
      _layout.update_icons();
    });

    for( int i=0; i<names.length; i++ ) {
      _layout.add_button( light_icons.index( i ), dark_icons.index( i ), names.index( i ) );
    }

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _layout );

    append( box );

  }

  //-------------------------------------------------------------
  // Handles changes to the selected layout.
  private void set_layout( int index ) {

    var names = new Array<string>();
    _map.layouts.get_names( ref names );

    if( index < names.length ) {
      var name   = names.index( index );
      var layout = _map.layouts.get_layout( name );
      var node   = _map.get_current_node();
      _map.model.set_layout( name, ((node == null) ? null : node.get_root()) );
      _balance.set_sensitive( layout.balanceable );
      _alignment_revealer.reveal_child = (name == _( "Manual" ));
    }

  }

  //-------------------------------------------------------------
  // Adds alignment buttons when multiple nodes are selected in
  // manual layout mode.
  private void add_alignment_ui() {

    /* Create the modebutton to select the current layout */
    var lbl = new Label( _( "Node Alignment" ) ) {
      xalign = (float)0,
    };
    lbl.add_css_class( "titled" );

    /* Create the alignment buttons */
    _hleft = new Button.from_icon_name( "align-horizontal-left-symbolic" );
    _win.register_widget_for_tooltip( _hleft, KeyCommand.NODE_ALIGN_LEFT, _( "Align left edges" ) );
    _hleft.clicked.connect(() => { _win.execute_command( KeyCommand.NODE_ALIGN_LEFT ); });

    _hcenter = new Button.from_icon_name( "align-horizontal-center-symbolic" );
    _win.register_widget_for_tooltip( _hcenter, KeyCommand.NODE_ALIGN_HCENTER, _( "Align horizontal centers" ) );
    _hcenter.clicked.connect(() => { _win.execute_command( KeyCommand.NODE_ALIGN_HCENTER ); });

    _hright = new Button.from_icon_name( "align-horizontal-right-symbolic" );
    _win.register_widget_for_tooltip( _hright, KeyCommand.NODE_ALIGN_RIGHT, _( "Align right edges" ) );
    _hright.clicked.connect(() => { _win.execute_command( KeyCommand.NODE_ALIGN_RIGHT ); });

    _vtop = new Button.from_icon_name( "align-vertical-top-symbolic" );
    _win.register_widget_for_tooltip( _vtop, KeyCommand.NODE_ALIGN_TOP, _( "Align top edges" ) );
    _vtop.clicked.connect(() => { _win.execute_command( KeyCommand.NODE_ALIGN_TOP ); });

    _vcenter = new Button.from_icon_name( "align-vertical-center-symbolic" );
    _win.register_widget_for_tooltip( _vcenter, KeyCommand.NODE_ALIGN_VCENTER, _( "Align vertical centers" ) );
    _vcenter.clicked.connect(() => { _win.execute_command( KeyCommand.NODE_ALIGN_VCENTER ); });

    _vbottom = new Button.from_icon_name( "align-vertical-bottom-symbolic" );
    _win.register_widget_for_tooltip( _vbottom, KeyCommand.NODE_ALIGN_BOTTOM, _( "Align bottom edges" ) );
    _vbottom.clicked.connect(() => { _win.execute_command( KeyCommand.NODE_ALIGN_BOTTOM ); });

    var toolbar = new Box( Orientation.HORIZONTAL, 5 );
    toolbar.append( _hleft );
    toolbar.append( _hcenter );
    toolbar.append( _hright );
    toolbar.append( _vtop );
    toolbar.append( _vcenter );
    toolbar.append( _vbottom );

    var box = new Box( Orientation.HORIZONTAL, 10 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( toolbar );

    _alignment_revealer = new Revealer() {
      child = box
    };

    append( _alignment_revealer );

  }

  //-------------------------------------------------------------
  // Updates the state of the node alignment buttons.
  private void update_node_alignment() {
    var enable_alignment = _map.model.nodes_alignable();
    _hleft.set_sensitive( enable_alignment );
    _hcenter.set_sensitive( enable_alignment );
    _hright.set_sensitive( enable_alignment );
    _vtop.set_sensitive( enable_alignment );
    _vcenter.set_sensitive( enable_alignment );
    _vbottom.set_sensitive( enable_alignment );
  }

  //-------------------------------------------------------------
  // Adds the themes UI.
  private void add_theme_ui() {

    /* Create the UI */
    var lbl = new Label( _( "Themes" ) ) {
      halign = Align.FILL,
      xalign = (float)0,
    };
    lbl.add_css_class( "titled" );

    _theme_grid = new Grid() {
      column_homogeneous = true
    };

    var tb = new Box( Orientation.VERTICAL, 0 );
    tb.append( _theme_grid );

    var sw = new ScrolledWindow() {
      halign  = Align.FILL,
      valign  = Align.FILL,
      vexpand = true,
      child   = tb
    };
    sw.child.set_size_request( 200, 600 );

    /* Add the themes to the theme box */
    update_themes();

    var add = new Button.from_icon_name( "list-add-symbolic" ) {
      valign       = Align.END,
      has_frame    = false,
      tooltip_text = _( "Add Custom Theme" )
    };
    add.clicked.connect( create_custom_theme );
    tb.append( add );

    /* Pack the panel */
    append( lbl );
    append( sw );

  }

  //-------------------------------------------------------------
  // Adds the bottom button frame.
  private void add_button_ui() {

    var grid = new Grid() {
      halign             = Align.FILL,
      column_homogeneous = true,
      column_spacing     = 5,
      row_spacing        = 5
    };

    _balance = new Button.from_icon_name( "minder-balance-light-symbolic" );
    _win.register_widget_for_shortcut( _balance, KeyCommand.BALANCE_NODES, _( "Balance Nodes" ) );
    _balance.clicked.connect(() => { _win.execute_command( KeyCommand.BALANCE_NODES ); });

    _fold_completed = new Button.from_icon_name( "minder-fold-completed-light-symbolic" );
    _win.register_widget_for_shortcut( _fold_completed, KeyCommand.FOLD_COMPLETED_TASKS, _( "Fold Completed Tasks" ) );
    _fold_completed.clicked.connect(() => { _win.execute_command( KeyCommand.FOLD_COMPLETED_TASKS ); });

    _unfold_all = new Button.from_icon_name( "minder-unfold-light-symbolic" );
    _win.register_widget_for_shortcut( _unfold_all, KeyCommand.UNFOLD_ALL_NODES, _( "Unfold All Nodes" ) );
    _unfold_all.clicked.connect(() => { _win.execute_command( KeyCommand.UNFOLD_ALL_NODES ); });

    update_icons.connect(() => {
      var dark = Utils.use_dark_mode( _balance );
      _balance.icon_name        = dark ? "minder-balance-dark-symbolic"        : "minder-balance-light-symbolic";
      _fold_completed.icon_name = dark ? "minder-fold-completed-dark-symbolic" : "minder-fold-completed-light-symbolic";
      _unfold_all.icon_name     = dark ? "minder-unfold-dark-symbolic"         : "minder-unfold-light-symbolic";
    });

    grid.attach( _balance,        0, 0 );
    grid.attach( _fold_completed, 1, 0 );
    grid.attach( _unfold_all,     2, 0 );

    append( grid );

  }

  //-------------------------------------------------------------
  // Updates the theme box widget with the current list of themes.
  private void update_themes() {

    /* Clear the contents of the theme box */
    for( int i=0; i<2; i++ ) {
      _theme_grid.remove_column( 0 );
    }

    /* Get the theme information to display */
    var names    = new Array<string>();
    var icons    = new Array<Picture>();
    var hide     = _settings.get_boolean( "hide-themes-not-matching-visual-style" );
    var settings = Granite.Settings.get_default();
    var dark     = settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

    _win.themes.names( ref names );
    _win.themes.icons( ref icons );

    /* Add the themes */
    var index = 0;
    for( int i=0; i<names.length; i++ ) {
      var name  = names.index( i );
      var theme = _win.themes.get_theme( name );
      if( !hide || (dark == theme.prefer_dark) ) {
        var label = new Label( theme_label( name ) );
        var item  = new Box( Orientation.VERTICAL, 0 ) {
          margin_start  = 5,
          margin_end    = 5,
          margin_top    = 5,
          margin_bottom = 5
        };
        item.append( icons.index( i ) );
        item.append( label );
        var click = new GestureClick();
        item.add_controller( click );
        click.pressed.connect((n_press, x, y) => {
          select_theme( name );
          _map.model.set_theme( theme, true );
          if( theme.custom && (n_press == 2) ) {
            edit_current_theme();
          }
        });
        _theme_grid.attach( item, (index % 2), (index / 2) );
        index++;
      }
    }

    /* Make sure that the current theme is selected */
    if( _map != null ) {
      select_theme( _map.get_theme().name );
    }

  }

  //-------------------------------------------------------------
  // Sets the map inspector UI to match the given layout name.
  private void select_layout( string name ) {

    var names = new Array<string>();
    _map.layouts.get_names( ref names );

    for( int i=0; i<names.length; i++ ) {
      if( name == names.index( i ) ) {
        _layout.selected = i;
        break;
      }
    }

    /* Set the sensitivity of the Balance Nodes button */
    _balance.set_sensitive( _map.layouts.get_layout( name ).balanceable );

    /* Make sure that alignment tools are shown when manual layout is selected */
    _alignment_revealer.reveal_child = (name == _( "Manual" ));

  }

  //-------------------------------------------------------------
  // Returns the label to use for the given theme by name.
  private string theme_label( string name ) {
    var theme = _win.themes.get_theme( name );
    if( theme.temporary ) {
      return( theme.label + " (" + _( "Unsaved" ) + ")" );
    }
    return( theme.label );
  }

  //-------------------------------------------------------------
  // Makes sure that only the given theme is selected in the UI.
  private void select_theme( string name ) {

    var names    = new Array<string>();
    var shown    = new Array<string>();
    var hide     = _settings.get_boolean( "hide-themes-not-matching-visual-style" );
    var settings = Granite.Settings.get_default();
    var dark     = settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;

    _win.themes.names( ref names );

    /* Only show the names that are not hidden */
    for( int i=0; i<names.length; i++ ) {
      var tname = names.index( i );
      var theme = _win.themes.get_theme( tname );
      if( !hide || (dark == theme.prefer_dark) ) {
        shown.append_val( tname );
      }
    }

    /* Update selection of themes */
    var index = 0;
    var child = Utils.get_child_at_index( _theme_grid, index );
    while( child != null ) {
      if( shown.index( index ) == name ) {
        child.add_css_class( "theme-selected" );
        var l = (Label)Utils.get_child_at_index( child, 1 );
        l.set_markup( "<span color=\"white\">%s</span>".printf( theme_label( shown.index( index ) ) ) );
      } else {
        child.remove_css_class( "theme-selected" );
        var l = (Label)Utils.get_child_at_index( child, 1 );
        l.set_markup( theme_label( shown.index( index ) ) );
      }
      child = Utils.get_child_at_index( _theme_grid, ++index );
    }

  }

  //-------------------------------------------------------------
  // Updates the current theme.
  private void update_theme_layout() {

    /* Make sure the current theme is selected */
    select_theme( _map.get_theme().name );

    /* Initialize the button states */
    current_changed();

  }

  //-------------------------------------------------------------
  // Displays the current theme editor.
  private void create_custom_theme() {
    _win.show_theme_editor( false );
  }

  //-------------------------------------------------------------
  // Displays the current theme editor.
  private void edit_current_theme() {
    _win.show_theme_editor( true );
  }

  //-------------------------------------------------------------
  // Called whenever the current item is changed.
  private void current_changed() {

    Node? current         = _map.get_current_node();
    var   foldable        = _map.model.completed_tasks_foldable();
    var   unfoldable      = _map.model.unfoldable();
    bool  layout_selected = false;

    /* Select the layout that corresponds with the current tree */
    if( current != null ) {
      if( layout_selected = (current.layout != null) ) {
        select_layout( current.layout.name );
      }
    } else if( _map.get_nodes().length > 0 ) {
      if( layout_selected = (_map.get_nodes().index( 0 ).layout != null) ) {
        select_layout( _map.get_nodes().index( 0 ).layout.name );
      }
    }

    if( !layout_selected ) {
      select_layout( _map.layouts.get_default().name );
    }

    /* Update the sensitivity of the buttons */
    _fold_completed.set_sensitive( foldable );
    _unfold_all.set_sensitive( unfoldable );

    /* Update the node alignment buttons */
    update_node_alignment();

  }

  //-------------------------------------------------------------
  // Grabs input focus on the first UI element.
  public void grab_first() {
    _layout.grab_focus();
  }

} 
