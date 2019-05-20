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

  private DrawArea                    _da;
  private GLib.Settings               _settings;
  private Granite.Widgets.ModeButton? _layouts        = null;
  private Box?                        _theme_box      = null;
  private Button?                     _balance        = null;
  private Button?                     _fold_completed = null;
  private Button?                     _unfold_all     = null;

  public MapInspector( DrawArea da, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _da       = da;
    _settings = settings;

    /* Create the interface */
    add_animation_ui();
    add_connection_ui();
    add_layout_ui();
    add_theme_ui();
    add_button_ui();

    /* Make sure that we have some defaults set */
    update_theme_layout();

    /* Whenever a new document is loaded, update the theme and layout within this UI */
    _da.loaded.connect( update_theme_layout );
    _da.current_changed.connect( current_changed );

  }

  /* Add the animation enable UI */
  private void add_animation_ui() {

    var box     = new Box( Orientation.HORIZONTAL, 0 );
    var lbl     = new Label( _( "<b>Enable animations</b>" ) );
    var animate = _settings.get_boolean( "enable-animations" );

    lbl.xalign = (float)0;
    lbl.use_markup = true;

    var enable = new Switch();
    enable.set_active( animate );
    enable.button_release_event.connect( animation_changed );

    box.pack_start( lbl,    false, true, 0 );
    box.pack_end(   enable, false, true, 0 );

    pack_start( box, false, true );

    /* Initialize the animator */
    _da.animator.enable = animate;

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
    var lbl       = new Label( _( "<b>Hide connections</b>" ) );
    var hide_conn = _settings.get_boolean( "hide-connections" );

    lbl.xalign = (float)0;
    lbl.use_markup = true;

    var hide_connections = new Switch();
    hide_connections.set_active( hide_conn );
    hide_connections.button_release_event.connect( hide_connections_changed );

    box.pack_start( lbl,              false, true, 0 );
    box.pack_end(   hide_connections, false, true, 0 );

    pack_start( box, false, true );

    /* Initialize the connections */
    _da.get_connections().hide = hide_conn;

  }

  /* Called whenever the hide connections switch is changed within the inspector */
  private bool hide_connections_changed( Gdk.EventButton e ) {
    _da.get_connections().hide = !_da.get_connections().hide;
    _settings.set_boolean( "hide-connections", _da.get_connections().hide );
    _da.queue_draw();
    return( false );
  }

  /* Adds the layout UI */
  private void add_layout_ui() {

    var icons = new Array<string>();
    _da.layouts.get_icons( ref icons );

    /* Create the modebutton to select the current layout */
    var lbl = new Label( _( "<b>Node Layouts</b>" ) );
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
    var lbl = new Label( _( "<b>Themes</b>" ) );
    lbl.xalign = (float)0;
    lbl.use_markup = true;

    var sw  = new ScrolledWindow( null, null );
    var vp  = new Viewport( null, null );
    _theme_box = new Box( Orientation.VERTICAL, 20 );
    vp.set_size_request( 200, 600 );
    vp.add( _theme_box );
    sw.add( vp );

    /* Get the theme information to display */
    var names = new Array<string>();
    var icons = new Array<Gtk.Image>();

    _da.themes.names( ref names );
    _da.themes.icons( ref icons );

    /* Add the themes */
    for( int i=0; i<names.length; i++ ) {
      var name  = names.index( i );
      var ebox  = new EventBox();
      var item  = new Box( Orientation.VERTICAL, 5 );
      var label = new Label( name );
      item.pack_start( icons.index( i ), false, false, 5 );
      item.pack_start( label,            false, true );
      ebox.button_press_event.connect((w, e) => {
        select_theme( name );
        _da.set_theme( name );
        return( false );
      });
      ebox.add( item );
      _theme_box.pack_start( ebox, false, true );
    }

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
      _da.balance_nodes();
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

  /* Makes sure that only the given theme is selected in the UI */
  private void select_theme( string name ) {

    int index = 0;
    var names = new Array<string>();
    _da.themes.names( ref names );

    /* Deselect all themes */
    _theme_box.get_children().foreach((entry) => {
      var e = (EventBox)entry;
      var b = (Box)e.get_children().nth_data( 0 );
      var l = (Label)b.get_children().nth_data( 1 );
      e.get_style_context().remove_class( "theme-selected" );
      l.set_markup( names.index( index ) );
      index++;
    });

    /* Select the matching theme */
    index = 0;
    _theme_box.get_children().foreach((entry) => {
      if( names.index( index ) == name ) {
        var e = (EventBox)entry;
        var b = (Box)e.get_children().nth_data( 0 );
        var l = (Label)b.get_children().nth_data( 1 );
        e.get_style_context().add_class( "theme-selected" );
        l.set_markup( "<span color=\"white\">%s</span>".printf( names.index( index ) ) );
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
