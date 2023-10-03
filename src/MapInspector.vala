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

  private MainWindow                  _win;
  private DrawArea?                   _da             = null;
  private GLib.Settings               _settings;
  private Granite.Widgets.ModeButton? _layouts        = null;
  private Grid?                       _theme_grid     = null;
  private Button?                     _balance        = null;
  private Button?                     _fold_completed = null;
  private Button?                     _unfold_all     = null;
  private Switch                      _hide_callouts;
  private Button                      _hleft;
  private Button                      _hcenter;
  private Button                      _hright;
  private Button                      _vtop;
  private Button                      _vcenter;
  private Button                      _vbottom;
  private Revealer                    _alignment_revealer;

  public MapInspector( MainWindow win, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _win      = win;
    _settings = settings;

    /* Create the interface */
    add_connection_ui();
    add_callout_ui();
    add_link_color_ui();
    add_layout_ui();
    add_alignmen_ui();
    add_theme_ui();
    add_button_ui();

    /* Listen for changes to the current tab */
    win.canvas_changed.connect( tab_changed );
    win.themes.themes_changed.connect( update_themes );

    /* Listen for preference changes */
    _settings.changed.connect( settings_changed );

#if GRANITE_6_OR_LATER
    /* Listen for changes to the system dark mode */
    var granite_settings = Granite.Settings.get_default();
    granite_settings.notify["prefers-color-scheme"].connect( () => {
      update_themes();
    });
#endif

  }

  /* Listen for any changes to the current tab in the main window */
  private void tab_changed( DrawArea? da ) {
    if( _da != null ) {
      _da.loaded.disconnect( update_theme_layout );
      _da.current_changed.disconnect( current_changed );
    }
    if( da != null ) {
      da.loaded.connect( update_theme_layout );
      da.current_changed.connect( current_changed );
    }
    _da = da;
    _da.animator.enable        = _settings.get_boolean( "enable-animations" );
    _da.get_connections().hide = _settings.get_boolean( "hide-connections" );
    _hide_callouts.set_active( _da.hide_callouts );
    _da.set_theme( _da.get_theme(), false );
    update_theme_layout();
  }

  /*
   Called whenever the preferences change values.  We will update the displayed
   themes based on the hide setting.
  */
  private void settings_changed( string key ) {
    switch( key ) {
      case "hide-themes-not-matching-visual-style" :  update_themes();  break;
    }
  }

  /* Add the connection show/hide UI */
  private void add_connection_ui() {

    var box       = new Box( Orientation.HORIZONTAL, 0 );
    var lbl       = new Label( Utils.make_title( _( "Hide connections" ) ) );
    var hide_conn = _settings.get_boolean( "hide-connections" );

    lbl.xalign = (float)0;
    lbl.use_markup = true;

    var hide_connections = new Switch();
    hide_connections.set_active( hide_conn );
    hide_connections.button_release_event.connect( hide_connections_changed );

    box.pack_start( lbl,              false, true, 0 );
    box.pack_end(   hide_connections, false, true, 0 );

    pack_start( box, false, true );

  }

  /* Called whenever the hide connections switch is changed within the inspector */
  private bool hide_connections_changed( Gdk.EventButton e ) {
    _da.set_current_connection( null );
    _da.get_connections().hide = !_da.get_connections().hide;
    _settings.set_boolean( "hide-connections", _da.get_connections().hide );
    _da.queue_draw();
    return( false );
  }

  /* Add the callout show/hide UI */
  private void add_callout_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( Utils.make_title( _( "Hide callouts" ) ) );

    lbl.xalign = (float)0;
    lbl.use_markup = true;

    _hide_callouts = new Switch();
    _hide_callouts.set_active( false );
    _hide_callouts.button_release_event.connect( hide_callouts_changed );

    box.pack_start( lbl,            false, true, 0 );
    box.pack_end(   _hide_callouts, false, true, 0 );

    pack_start( box, false, true );

  }

  /* Called whenever the hide connections switch is changed within the inspector */
  private bool hide_callouts_changed( Gdk.EventButton e ) {
    _da.hide_callouts = !_da.hide_callouts;
    _da.queue_draw();
    return( false );
  }

  /* Add link color rotation UI */
  private void add_link_color_ui() {

    var box    = new Box( Orientation.HORIZONTAL, 0 );
    var lbl    = new Label( Utils.make_title( _( "Rotate main branch colors" ) ) );
    var rotate = _settings.get_boolean( "rotate-main-link-colors" );

    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    var rotate_colors = new Switch();
    rotate_colors.set_active( rotate );
    rotate_colors.button_release_event.connect( rotate_colors_changed );

    box.pack_start( lbl,           false, true, 0 );
    box.pack_end(   rotate_colors, false, true, 0 );

    pack_start( box, false, true );

  }

  /* Called whenever the rotate color switch is changed within the inspector */
  private bool rotate_colors_changed( Gdk.EventButton e ) {
    _da.get_theme().rotate = !_da.get_theme().rotate;
    _settings.set_boolean( "rotate-main-link-colors", _da.get_theme().rotate );
    return( false );
  }

  /* Adds the layout UI */
  private void add_layout_ui() {

    var icons   = new Array<string>();
    var layouts = new Layouts();
    layouts.get_icons( ref icons );

    /* Create the modebutton to select the current layout */
    var lbl = new Label( Utils.make_title( _( "Node Layouts" ) ) );
    lbl.xalign = (float)0;
    lbl.use_markup = true;

    /* Create the layouts mode button */
    _layouts = new Granite.Widgets.ModeButton();
    _layouts.has_tooltip = true;
    for( int i=0; i<icons.length; i++ ) {
      _layouts.append_icon( icons.index( i ), IconSize.SMALL_TOOLBAR );
    }
    _layouts.button_release_event.connect( layout_changed );
    _layouts.query_tooltip.connect( layout_show_tooltip );

    pack_start( lbl,      false, true );
    pack_start( _layouts, false, true );

  }

  /* Called whenever the user changes the current layout */
  private bool layout_changed( Gdk.EventButton e ) {
    var names = new Array<string>();
    _da.layouts.get_names( ref names );
    if( _layouts.selected < names.length ) {
      var   name   = names.index( _layouts.selected );
      var   layout = _da.layouts.get_layout( name );
      Node? node   = _da.get_current_node();
      _da.set_layout( name, ((node == null) ? null : node.get_root()) );
      _balance.set_sensitive( layout.balanceable );
      _alignment_revealer.reveal_child = (name == _( "Manual" ));
    }
    return( false );
  }

  /* Called whenever the tooltip needs to be displayed for the layout selector */
  private bool layout_show_tooltip( int x, int y, bool keyboard, Tooltip tooltip ) {
    if( keyboard ) {
      return( false );
    }
    var names = new Array<string>();
    _da.layouts.get_names( ref names );
    int button_width = (int)(_layouts.get_allocated_width() / names.length);
    if( (x / button_width) < names.length ) {
      tooltip.set_text( names.index( x / button_width ) );
      return( true );
    }
    return( false );
  }

  /* Adds alignment buttons when multiple nodes are selected in manual layout mode */
  private void add_alignmen_ui() {

    /* Create the modebutton to select the current layout */
    var lbl = new Label( Utils.make_title( _( "Node Alignment" ) ) );
    lbl.xalign = (float)0;
    lbl.use_markup = true;

    /* Create the alignment buttons */
    _hleft = new Button.from_icon_name( "align-horizontal-left-symbolic", IconSize.SMALL_TOOLBAR );
    _hleft.set_tooltip_markup( Utils.tooltip_with_accel( _( "Align left side of selected nodes" ), "bracketleft" ) );
    _hleft.clicked.connect(() => {
      NodeAlign.align_left( _da, _da.get_selected_nodes() );
    });

    _hcenter = new Button.from_icon_name( "align-horizontal-center-symbolic", IconSize.SMALL_TOOLBAR );
    _hcenter.set_tooltip_markup( Utils.tooltip_with_accel( _( "Align horizontal center of selected nodes" ), "bar" ) );
    _hcenter.clicked.connect(() => {
      NodeAlign.align_hcenter( _da, _da.get_selected_nodes() );
    });

    _hright = new Button.from_icon_name( "align-horizontal-right-symbolic", IconSize.SMALL_TOOLBAR );
    _hright.set_tooltip_markup( Utils.tooltip_with_accel( _( "Align right side of selected nodes" ), "bracketright" ) );
    _hright.clicked.connect(() => {
      NodeAlign.align_right( _da, _da.get_selected_nodes() );
    });

    _vtop = new Button.from_icon_name( "align-vertical-top-symbolic", IconSize.SMALL_TOOLBAR );
    _vtop.set_tooltip_markup( Utils.tooltip_with_accel( _( "Align top side of selected nodes" ), "minus" ) );
    _vtop.clicked.connect(() => {
      NodeAlign.align_top( _da, _da.get_selected_nodes() );
    });

    _vcenter = new Button.from_icon_name( "align-vertical-center-symbolic", IconSize.SMALL_TOOLBAR );
    _vcenter.set_tooltip_markup( Utils.tooltip_with_accel( _( "Align vertical center of selected nodes" ), "equal" ) );
    _vcenter.clicked.connect(() => {
      NodeAlign.align_vcenter( _da, _da.get_selected_nodes() );
    });

    _vbottom = new Button.from_icon_name( "align-vertical-bottom-symbolic", IconSize.SMALL_TOOLBAR );
    _vbottom.set_tooltip_markup( Utils.tooltip_with_accel( _( "Align bottom side of selected nodes" ), "underscore" ) );
    _vbottom.clicked.connect(() => {
      NodeAlign.align_bottom( _da, _da.get_selected_nodes() );
    });

    var toolbar = new Box( Orientation.HORIZONTAL, 5 );
    toolbar.pack_start( _hleft,   false, false );
    toolbar.pack_start( _hcenter, false, false );
    toolbar.pack_start( _hright,  false, false );
    toolbar.pack_start( _vtop,    false, false );
    toolbar.pack_start( _vcenter, false, false );
    toolbar.pack_start( _vbottom, false, false );

    var box = new Box( Orientation.VERTICAL, 10 );
    box.pack_start( lbl,     false, true );
    box.pack_start( toolbar, false, true );

    _alignment_revealer = new Revealer();
    _alignment_revealer.add( box );

    pack_start( _alignment_revealer, false, true );

  }

  /* Updates the state of the node alignment buttons */
  private void update_node_alignment() {
    var enable_alignment = _da.nodes_alignable();
    _hleft.set_sensitive( enable_alignment );
    _hcenter.set_sensitive( enable_alignment );
    _hright.set_sensitive( enable_alignment );
    _vtop.set_sensitive( enable_alignment );
    _vcenter.set_sensitive( enable_alignment );
    _vbottom.set_sensitive( enable_alignment );
  }

  /* Adds the themes UI */
  private void add_theme_ui() {

    /* Create the UI */
    var lbl = new Label( Utils.make_title( _( "Themes" ) ) );
    lbl.xalign = (float)0;
    lbl.use_markup = true;

    var sw  = new ScrolledWindow( null, null );
    var vp  = new Viewport( null, null );
    var tb  = new Box( Orientation.VERTICAL, 0 );
    _theme_grid = new Grid();
    _theme_grid.column_homogeneous = true;
    tb.pack_start( _theme_grid, true, true );
    vp.set_size_request( 200, 600 );
    vp.add( tb );
    sw.add( vp );

    /* Add the themes to the theme box */
    update_themes();

    var add = new Button.from_icon_name( "list-add-symbolic", IconSize.LARGE_TOOLBAR );
    add.relief = ReliefStyle.NONE;
    add.set_tooltip_text( _( "Add Custom Theme" ) );
    add.clicked.connect( create_custom_theme );
    tb.pack_start( add, false, true );

    /* Pack the panel */
    pack_start( lbl, false, true );
    pack_start( sw,  true,  true );

  }

  /* Adds the bottom button frame */
  private void add_button_ui() {

    var grid = new Grid();
    grid.column_homogeneous = true;
    grid.column_spacing     = 5;
    grid.row_spacing        = 5;

    _balance = new Button.from_icon_name( "minder-balance-symbolic", IconSize.SMALL_TOOLBAR );
    _balance.set_tooltip_text( _( "Balance Nodes" ) );
    _balance.clicked.connect(() => {
      _da.balance_nodes( true, true );
    });

    _fold_completed = new Button.from_icon_name( "minder-fold-completed-symbolic", IconSize.SMALL_TOOLBAR );
    _fold_completed.set_tooltip_text( _( "Fold Completed Tasks" ) );
    _fold_completed.clicked.connect(() => {
      _da.fold_completed_tasks();
    });

    _unfold_all = new Button.from_icon_name( "minder-unfold-symbolic", IconSize.SMALL_TOOLBAR );
    _unfold_all.set_tooltip_text( _( "Unfold All Nodes" ) );
    _unfold_all.clicked.connect(() => {
      _da.unfold_all_nodes();
    });

    grid.attach( _balance,        0, 0 );
    grid.attach( _fold_completed, 1, 0 );
    grid.attach( _unfold_all,     2, 0 );

    pack_start( grid, false, true );

  }

  /* Updates the theme box widget with the current list of themes */
  private void update_themes() {

    /* Clear the contents of the theme box */
    _theme_grid.get_children().foreach((entry) => {
      _theme_grid.remove( entry );
    });

    /* Get the theme information to display */
    var names    = new Array<string>();
    var icons    = new Array<Gtk.Image>();
#if GRANITE_6_OR_LATER
    var hide     = _settings.get_boolean( "hide-themes-not-matching-visual-style" );
    var settings = Granite.Settings.get_default();
    var dark     = settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
#else
    var hide     = false;
    var dark     = false;
#endif

    _win.themes.names( ref names );
    _win.themes.icons( ref icons );

    /* Add the themes */
    var index = 0;
    for( int i=0; i<names.length; i++ ) {
      var name  = names.index( i );
      var theme = _win.themes.get_theme( name );
      if( !hide || (dark == theme.prefer_dark) ) {
        var ebox  = new EventBox();
        var item  = new Box( Orientation.VERTICAL, 0 );
        var label = new Label( theme_label( name ) );
        item.border_width = 5;
        item.pack_start( icons.index( i ), false, false );
        item.pack_start( label,            false, true, 5 );
        ebox.button_press_event.connect((w, e) => {
          select_theme( name );
          _da.set_theme( theme, true );
          if( theme.custom && (e.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) ) {
            edit_current_theme();
          }
          return( false );
        });
        ebox.add( item );
        _theme_grid.attach( ebox, (index % 2), (index / 2) );
        index++;
      }
    }
    _theme_grid.show_all();

    /* Make sure that the current theme is selected */
    if( _da != null ) {
      select_theme( _da.get_theme_name() );
    }

  }

  /* Sets the map inspector UI to match the given layout name */
  private void select_layout( string name ) {

    /* Set the layout button to the matching value */
    if( name == _( "Manual" ) ) { _layouts.selected = 0; }
    else if( name == _( "Vertical" )   ) { _layouts.selected = 1; }
    else if( name == _( "Horizontal" ) ) { _layouts.selected = 2; }
    else if( name == _( "To left" )    ) { _layouts.selected = 3; }
    else if( name == _( "To right" )   ) { _layouts.selected = 4; }
    else if( name == _( "Upwards" )    ) { _layouts.selected = 5; }
    else if( name == _( "Downwards" )  ) { _layouts.selected = 6; }

    /* Set the sensitivity of the Balance Nodes button */
    _balance.set_sensitive( _da.layouts.get_layout( name ).balanceable );

    /* Make sure that alignment tools are shown when manual layout is selected */
    _alignment_revealer.reveal_child = (_layouts.selected == 0);

  }

  /* Returns the label to use for the given theme by name */
  private string theme_label( string name ) {
    var theme = _win.themes.get_theme( name );
    if( theme.temporary ) {
      return( theme.label + " (" + _( "Unsaved" ) + ")" );
    }
    return( theme.label );
  }

  /* Makes sure that only the given theme is selected in the UI */
  private void select_theme( string name ) {

    int index    = 0;
    var names    = new Array<string>();
    var shown    = new Array<string>();
    var children = _theme_grid.get_children();
#if GRANITE_6_OR_LATER
    var hide     = _settings.get_boolean( "hide-themes-not-matching-visual-style" );
    var settings = Granite.Settings.get_default();
    var dark     = settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK;
#else
    var hide     = false;
    var dark     = false;
#endif

    _win.themes.names( ref names );

    /* Only show the names that are not hidden */
    for( int i=0; i<names.length; i++ ) {
      var tname = names.index( i );
      var theme = _win.themes.get_theme( tname );
      if( !hide || (dark == theme.prefer_dark) ) {
        shown.append_val( tname );
      }
    }

    children.reverse();

    /* Deselect all themes */
    children.foreach((entry) => {
      var e = (EventBox)entry;
      var b = (Box)e.get_children().nth_data( 0 );
      var l = (Label)b.get_children().nth_data( 1 );
      e.get_style_context().remove_class( "theme-selected" );
      l.set_markup( theme_label( shown.index( index ) ) );
      index++;
    });

    /* Select the matching theme */
    index = 0;
    children.foreach((entry) => {
      if( shown.index( index ) == name ) {
        var e = (EventBox)entry;
        var b = (Box)e.get_children().nth_data( 0 );
        var l = (Label)b.get_children().nth_data( 1 );
        e.get_style_context().add_class( "theme-selected" );
        l.set_markup( "<span color=\"white\">%s</span>".printf( theme_label( shown.index( index ) ) ) );
      }
      index++;
    });

  }

  private void update_theme_layout() {

    /* Make sure the current theme is selected */
    select_theme( _da.get_theme_name() );

    /* Initialize the button states */
    current_changed();

  }

  /* Displays the current theme editor */
  private void create_custom_theme() {
    _win.show_theme_editor( false );
  }

  /* Displays the current theme editor */
  private void edit_current_theme() {
    _win.show_theme_editor( true );
  }

  /* Called whenever the current item is changed */
  private void current_changed() {

    Node? current         = _da.get_current_node();
    var   foldable        = _da.completed_tasks_foldable();
    var   unfoldable      = _da.unfoldable();
    bool  layout_selected = false;

    /* Select the layout that corresponds with the current tree */
    if( current != null ) {
      if( layout_selected = (current.layout != null) ) {
        select_layout( current.layout.name );
      }
    } else if( _da.get_nodes().length > 0 ) {
      if( layout_selected = (_da.get_nodes().index( 0 ).layout != null) ) {
        select_layout( _da.get_nodes().index( 0 ).layout.name );
      }
    }

    if( !layout_selected ) {
      select_layout( _da.layouts.get_default().name );
    }

    /* Update the sensitivity of the buttons */
    _fold_completed.set_sensitive( foldable );
    _unfold_all.set_sensitive( unfoldable );

    /* Update the node alignment buttons */
    update_node_alignment();

  }

  /* Grabs input focus on the first UI element */
  public void grab_first() {
    _layouts.grab_focus();
  }

}
