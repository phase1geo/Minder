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
  private bool                        _init           = true;

  public MapInspector( MainWindow win, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _win      = win;
    _settings = settings;

    /* Create the interface */
    add_animation_ui();
    add_connection_ui();
    add_link_color_ui();
    add_layout_ui();
    add_theme_ui();
    add_button_ui();

    /* Listen for changes to the current tab */
    win.canvas_changed.connect( tab_changed );
    win.themes.themes_changed.connect( update_themes );

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
    _da.set_theme( _da.get_theme(), false );
    update_theme_layout();
  }

  /* Add the animation enable UI */
  private void add_animation_ui() {

    var box     = new Box( Orientation.HORIZONTAL, 0 );
    var lbl     = new Label( Utils.make_title( _( "Enable animations" ) ) );
    var animate = _settings.get_boolean( "enable-animations" );

    lbl.xalign = (float)0;
    lbl.use_markup = true;

    var enable = new Switch();
    enable.set_active( animate );
    enable.button_release_event.connect( animation_changed );

    box.pack_start( lbl,    false, true, 0 );
    box.pack_end(   enable, false, true, 0 );

    pack_start( box, false, true );

  }

  /* Called whenever the animation switch is changed within the inspector */
  private bool animation_changed( Gdk.EventButton e ) {
    _da.animator.enable = !_da.animator.enable;
    _settings.set_boolean( "enable-animations", _da.animator.enable );
    return( false );
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
    _da.get_connections().hide = !_da.get_connections().hide;
    _settings.set_boolean( "hide-connections", _da.get_connections().hide );
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

    if( !_init ) {
      return;
    }

    /* Get the theme information to display */
    var names  = new Array<string>();
    var icons  = new Array<Gtk.Image>();

    _win.themes.names( ref names );
    _win.themes.icons( ref icons );

    /* Add the themes */
    for( int i=0; i<names.length; i++ ) {
      var name  = names.index( i );
      var ebox  = new EventBox();
      var item  = new Box( Orientation.VERTICAL, 0 );
      var label = new Label( theme_label( name ) );
      item.border_width = 5;
      item.pack_start( icons.index( i ), false, false );
      item.pack_start( label,            false, true, 5 );
      ebox.button_press_event.connect((w, e) => {
        var theme = _win.themes.get_theme( name );
        select_theme( name );
        _da.set_theme( theme, true );
        if( theme.custom && (e.type == Gdk.EventType.DOUBLE_BUTTON_PRESS) ) {
          edit_current_theme();
        }
        return( false );
      });
      ebox.add( item );
      _theme_grid.attach( ebox, (i % 2), (i / 2) );
    }
    _theme_grid.show_all();

    /* Make sure that the current theme is selected */
    if( _da != null ) {
      select_theme( _da.get_theme_name() );
    }

    _init = false;

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

  }

  /* Returns the label to use for the given theme by name */
  private string theme_label( string name ) {
    var theme = _win.themes.get_theme( name );
    if( theme.temporary ) {
      return( theme.label + " (" + _( "Unsaved" ) + ")" );
    }
    return( name );
  }

  /* Makes sure that only the given theme is selected in the UI */
  private void select_theme( string name ) {

    int index    = 0;
    var names    = new Array<string>();
    var children = _theme_grid.get_children();
    _win.themes.names( ref names );

    children.reverse();

    /* Deselect all themes */
    children.foreach((entry) => {
      var e = (EventBox)entry;
      var b = (Box)e.get_children().nth_data( 0 );
      var l = (Label)b.get_children().nth_data( 1 );
      e.get_style_context().remove_class( "theme-selected" );
      l.set_markup( theme_label( names.index( index ) ) );
      index++;
    });

    /* Select the matching theme */
    index = 0;
    children.foreach((entry) => {
      if( names.index( index ) == name ) {
        var e = (EventBox)entry;
        var b = (Box)e.get_children().nth_data( 0 );
        var l = (Label)b.get_children().nth_data( 1 );
        e.get_style_context().add_class( "theme-selected" );
        l.set_markup( "<span color=\"white\">%s</span>".printf( theme_label( names.index( index ) ) ) );
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

  }

}
