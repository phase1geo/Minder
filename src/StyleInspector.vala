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

public enum StyleAffects {

  ALL = 0,               // Applies changes to all nodes and connections
  SELECTED_NODES,        // Applies changes to selected nodes
  SELECTED_CONNECTIONS;  // Applies changes to selected connections

  /* Displays the label to display for this enumerated value */
  public string label() {
    switch( this ) {
      case ALL                  :  return( _( "All" ) );
      case SELECTED_NODES       :  return( _( "Selected Nodes" ) );
      case SELECTED_CONNECTIONS :  return( _( "Selected Connections" ) );
    }
    return( _( "Unknown" ) );
  }

}

public class StyleInspector : Box {

  private DrawArea?                  _da = null;
  private GLib.Settings              _settings;
  private Revealer                   _branch_radius_revealer;
  private Scale                      _branch_radius;
  private Scale                      _branch_margin;
  private Granite.Widgets.ModeButton _link_types;
  private Scale                      _link_width;
  private Switch                     _link_arrow;
  private Image                      _link_dash;
  private Granite.Widgets.ModeButton _node_borders;
  private Scale                      _node_borderwidth;
  private Switch                     _node_fill;
  private Scale                      _node_margin;
  private Scale                      _node_padding;
  private FontButton                 _node_font;
  private SpinButton                 _node_width;
  private Switch                     _node_markup;
  private Image                      _conn_dash;
  private Image                      _conn_arrow;
  private Scale                      _conn_lwidth;
  private Scale                      _conn_padding;
  private FontButton                 _conn_font;
  private SpinButton                 _conn_twidth;
  private StyleAffects               _affects;
  private Label                      _affects_label;
  private Box                        _branch_group;
  private Box                        _link_group;
  private Box                        _node_group;
  private Box                        _conn_group;
  private Expander                   _conn_exp;
  private bool                       _change_add = true;
  private bool                       _ignore     = false;

  public static Styles styles = new Styles();

  public StyleInspector( MainWindow win, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:20 );

    _settings = settings;

    /* Initialize the affects */
    _affects = StyleAffects.ALL;

    /* Create the UI for nodes */
    var affect = create_affect_ui();
    var box    = new Box( Orientation.VERTICAL, 0 );
    var sw     = new ScrolledWindow( null, null );
    var vp     = new Viewport( null, null );
    vp.set_size_request( 200, 600 );
    vp.add( box );
    sw.add( vp );

    _branch_group = create_branch_ui();
    _link_group   = create_link_ui();
    _node_group   = create_node_ui();
    _conn_group   = create_connection_ui();

    /* Pack the scrollwindow */
    box.pack_start( _branch_group, false, true );
    box.pack_start( _link_group,   false, true );
    box.pack_start( _node_group,   false, true );
    box.pack_start( _conn_group,   false, true );

    /* Pack the elements into this widget */
    pack_start( affect, false, true );
    pack_start( sw,     true,  true, 10 );

    /* Listen for changes to the current tab in the main window */
    win.canvas_changed.connect( tab_changed );

  }

  /* Listen for any changes to the current tab in the main window */
  private void tab_changed( DrawArea? da ) {
    if( _da != null ) {
      _da.current_changed.disconnect( handle_current_changed );
    }
    if( da != null ) {
      da.current_changed.connect( handle_current_changed );
    }
    _da = da;
    handle_ui_changed();
  }

  /* Creates the menubutton that changes the affect */
  private Box create_affect_ui() {

    var box  = new Box( Orientation.HORIZONTAL, 10 );
    var lbl  = new Label( Utils.make_title( _( "Changes affect:" ) ) );
    lbl.use_markup = true;

    _affects_label = new Label( "" );

    /* Pack the menubutton box */
    box.pack_start( lbl,            false, false );
    box.pack_start( _affects_label, true,  true );

    return( box );

  }

  /* Adds the options to manipulate line options */
  private Box create_branch_ui() {

    var box = new Box( Orientation.VERTICAL, 0 );
    var sep = new Separator( Orientation.HORIZONTAL );

    /* Create expander */
    var exp = new Expander( "  " + Utils.make_title( _( "Branch Options" ) ) );
    exp.use_markup = true;
    exp.expanded   = _settings.get_boolean( "style-branch-options-expanded" );
    exp.activate.connect(() => {
      _settings.set_boolean( "style-branch-options-expanded", !exp.expanded );
    });

    var cbox = new Box( Orientation.VERTICAL, 10 );
    cbox.homogeneous  = true;
    cbox.border_width = 10;

    var branch_type   = create_branch_type_ui();
    var branch_radius = create_branch_radius_ui();
    var branch_margin = create_branch_margin_ui();

    cbox.pack_start( branch_type,   false, false );
    cbox.pack_start( branch_radius, false, true );
    cbox.pack_start( branch_margin, false, false );

    exp.add( cbox );

    box.pack_start( exp, false, true );
    box.pack_start( sep, false, true, 10 );

    return( box );

  }

  /* Create the branch type UI */
  private Box create_branch_type_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Style" ) );
    lbl.xalign = (float)0;

    /* Create the line types mode button */
    _link_types = new Granite.Widgets.ModeButton();
    _link_types.has_tooltip = true;
    _link_types.button_release_event.connect( branch_type_changed );
    _link_types.query_tooltip.connect( branch_type_show_tooltip );

    var link_types = styles.get_link_types();
    for( int i=0; i<link_types.length; i++ ) {
      _link_types.append_icon( link_types.index( i ).icon_name(), IconSize.SMALL_TOOLBAR );
    }

    box.pack_start( lbl,         false, true );
    box.pack_end(   _link_types, false, true );

    return( box );

  }

  /* Called whenever the user changes the current layout */
  private bool branch_type_changed( Gdk.EventButton e ) {
    var link_types = styles.get_link_types();
    if( _link_types.selected < link_types.length ) {
      var link_type = link_types.index( _link_types.selected );
      _da.undo_buffer.add_item( new UndoStyleLinkType( _affects, link_type, _da ) );
    }
    return( false );
  }

  /* Called whenever the tooltip needs to be displayed for the layout selector */
  private bool branch_type_show_tooltip( int x, int y, bool keyboard, Tooltip tooltip ) {
    if( keyboard ) {
      return( false );
    }
    var link_types = styles.get_link_types();
    int button_width = (int)(_link_types.get_allocated_width() / link_types.length);
    if( (x / button_width) < link_types.length ) {
      tooltip.set_text( link_types.index( x / button_width ).display_name() );
      return( true );
    }
    return( false );
  }

  private Revealer create_branch_radius_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Corner Radius" ) );
    lbl.xalign = (float)0;

    _branch_radius = new Scale.with_range( Orientation.HORIZONTAL, 10, 40, 1 );
    _branch_radius.draw_value = true;
    _branch_radius.change_value.connect( branch_radius_changed );
    _branch_radius.button_release_event.connect( branch_radius_released );

    box.pack_start( lbl,            false, true );
    box.pack_end(   _branch_radius, false, true );

    _branch_radius_revealer = new Revealer();
    _branch_radius_revealer.reveal_child = false;
    _branch_radius_revealer.add( box );

    return( _branch_radius_revealer );

  }

  /* Called whenever the branch radius value is changed */
  private bool branch_radius_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 40 ) {
      return( false );
    }
    var margin = new UndoStyleBranchRadius( _affects, intval, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( margin );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( margin );
    }
    return( false );
  }

  private bool branch_radius_released( EventButton e ) {
    _change_add = true;
    return( false );
  }

  private Box create_branch_margin_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Margin" ) );
    lbl.xalign = (float)0;

    _branch_margin = new Scale.with_range( Orientation.HORIZONTAL, 20, 150, 10 );
    _branch_margin.draw_value = true;
    _branch_margin.change_value.connect( branch_margin_changed );
    _branch_margin.button_release_event.connect( branch_margin_released );

    box.pack_start( lbl,          false, true );
    box.pack_end(   _branch_margin, false, true );

    return( box );

  }

  /* Called whenever the node margin value is changed */
  private bool branch_margin_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 150 ) {
      return( false );
    }
    var margin = new UndoStyleBranchMargin( _affects, intval, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( margin );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( margin );
    }
    return( false );
  }

  private bool branch_margin_released( EventButton e ) {
    _change_add = true;
    return( false );
  }

  /* Adds the options to manipulate line options */
  private Box create_link_ui() {

    var box = new Box( Orientation.VERTICAL, 0 );
    var sep = new Separator( Orientation.HORIZONTAL );

    /* Create expander */
    var exp = new Expander( "  " + Utils.make_title( _( "Link Options" ) ) );
    exp.use_markup = true;
    exp.expanded   = _settings.get_boolean( "style-link-options-expanded" );
    exp.activate.connect(() => {
      _settings.set_boolean( "style-link-options-expanded", !exp.expanded );
    });

    var cbox = new Box( Orientation.VERTICAL, 10 );
    cbox.homogeneous  = true;
    cbox.border_width = 10;

    var link_dash  = create_link_dash_ui();
    var link_width = create_link_width_ui();
    var link_arrow = create_link_arrow_ui();

    cbox.pack_start( link_dash,  false, false );
    cbox.pack_start( link_width, false, false );
    cbox.pack_start( link_arrow, false, false );

    exp.add( cbox );

    box.pack_start( exp, false, true );
    box.pack_start( sep, false, true, 10 );

    return( box );

  }

  /* Create the link dash widget */
  private Box create_link_dash_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Line Dash" ) );
    lbl.xalign = (float)0;

    var menu   = new Gtk.Menu();
    var dashes = styles.get_link_dashes();

    _link_dash = new Image.from_surface( dashes.index( 0 ).make_icon() );

    for( int i=0; i<dashes.length; i++ ) {
      var dash = dashes.index( i );
      var img  = new Image.from_surface( dash.make_icon() );
      var mi   = new Gtk.MenuItem();
      mi.activate.connect(() => {
        _da.undo_buffer.add_item( new UndoStyleLinkDash( _affects, dash, _da ) );
        _link_dash.surface = img.surface;
      });
      mi.add( img );
      menu.add( mi );
    }

    menu.show_all();

    var mb = new MenuButton();
    mb.add( _link_dash );
    mb.popup = menu;

    box.pack_start( lbl, false, true );
    box.pack_end(   mb,  false, true );

    return( box );

  }

  /* Create widget for handling the width of a link */
  private Box create_link_width_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Line Width" ) );
    lbl.xalign = (float)0;

    _link_width = new Scale.with_range( Orientation.HORIZONTAL, 2, 8, 1 );
    _link_width.draw_value = false;

    for( int i=2; i<=8; i++ ) {
      if( (i % 2) == 0 ) {
        _link_width.add_mark( i, PositionType.BOTTOM, "%d".printf( i ) );
      } else {
        _link_width.add_mark( i, PositionType.BOTTOM, null );
      }
    }

    _link_width.change_value.connect( link_width_changed );
    _link_width.button_release_event.connect( link_width_released );

    box.pack_start( lbl,         false, true );
    box.pack_end(   _link_width, false, true );

    return( box );

  }

  /* Called whenever the user changes the link width value */
  private bool link_width_changed( ScrollType scroll, double value ) {
    if( value > 8 ) value = 8;
    var link_width = new UndoStyleLinkWidth( _affects, (int)value, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( link_width );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( link_width );
    }
    return( false );
  }

  private bool link_width_released( EventButton e ) {
    _change_add = true;
    return( false );
  }

  /* Creates the link arrow UI element */
  private Box create_link_arrow_ui() {

    var box = new Box( Orientation.HORIZONTAL, 5 );
    var lbl = new Label( _( "Link Arrow" ) );

    _link_arrow = new Switch();
    _link_arrow.set_active( false );  /* TBD */
    _link_arrow.button_release_event.connect( link_arrow_changed );

    box.pack_start( lbl,       false, false );
    box.pack_end( _link_arrow, false, false );

    return( box );

  }

  /* Called when the user clicks on the link arrow switch */
  private bool link_arrow_changed( Gdk.EventButton e ) {
    bool val = !_link_arrow.get_active();
    Idle.add(() => {
      _da.undo_buffer.add_item( new UndoStyleLinkArrow( _affects, val, _da ) );
      return( Source.REMOVE );
    });
    return( false );
  }

  /* Creates the options to manipulate node options */
  private Box create_node_ui() {

    var box = new Box( Orientation.VERTICAL, 5 );
    var sep = new Separator( Orientation.HORIZONTAL );

    /* Create expander */
    var exp = new Expander( "  " + Utils.make_title( _( "Node Options" ) ) );
    exp.use_markup = true;
    exp.expanded   = _settings.get_boolean( "style-node-options-expanded" );
    exp.activate.connect(() => {
      _settings.set_boolean( "style-node-options-expanded", !exp.expanded );
    });

    var cbox = new Box( Orientation.VERTICAL, 10 );
    cbox.homogeneous  = true;
    cbox.border_width = 10;

    var node_border      = create_node_border_ui();
    var node_borderwidth = create_node_borderwidth_ui();
    var node_fill        = create_node_fill_ui();
    var node_margin      = create_node_margin_ui();
    var node_padding     = create_node_padding_ui();
    var node_font        = create_node_font_ui();
    var node_width       = create_node_width_ui();
    var node_markup      = create_node_markup_ui();

    cbox.pack_start( node_border,      false, false );
    cbox.pack_start( node_borderwidth, false, false );
    cbox.pack_start( node_fill,        false, false );
    cbox.pack_start( node_margin,      false, false );
    cbox.pack_start( node_padding,     false, false );
    cbox.pack_start( node_font,        false, false );
    cbox.pack_start( node_width,       false, false );
    cbox.pack_start( node_markup,      false, false );

    exp.add( cbox );

    box.pack_start( exp, false, true );
    box.pack_start( sep, false, true, 10 );

    return( box );

  }

  /* Creates the node border panel */
  private Box create_node_border_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Border Style" ) );

    /* Create the line types mode button */
    _node_borders = new Granite.Widgets.ModeButton();
    _node_borders.has_tooltip = true;
    _node_borders.button_release_event.connect( node_border_changed );
    _node_borders.query_tooltip.connect( node_border_show_tooltip );

    var node_borders = styles.get_node_borders();
    for( int i=0; i<node_borders.length; i++ ) {
      _node_borders.append_icon( node_borders.index( i ).icon_name(), IconSize.SMALL_TOOLBAR );
    }

    box.pack_start( lbl,           false, false );
    box.pack_end(   _node_borders, false, false );

    return( box );

  }

  /* Called whenever the user changes the current layout */
  private bool node_border_changed( Gdk.EventButton e ) {
    var node_borders = styles.get_node_borders();
    if( _node_borders.selected < node_borders.length ) {
      _da.undo_buffer.add_item( new UndoStyleNodeBorder( _affects, node_borders.index( _node_borders.selected ), _da ) );
    }
    return( false );
  }

  /* Called whenever the tooltip needs to be displayed for the layout selector */
  private bool node_border_show_tooltip( int x, int y, bool keyboard, Tooltip tooltip ) {
    if( keyboard ) {
      return( false );
    }
    var node_borders = styles.get_node_borders();
    int button_width = (int)(_node_borders.get_allocated_width() / node_borders.length);
    if( (x / button_width) < node_borders.length ) {
      tooltip.set_text( node_borders.index( x / button_width ).display_name() );
      return( true );
    }
    return( false );
  }

  /* Create widget for handling the width of a link */
  private Box create_node_borderwidth_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Border Width" ) );
    lbl.xalign = (float)0;

    _node_borderwidth = new Scale.with_range( Orientation.HORIZONTAL, 2, 8, 1 );
    _node_borderwidth.draw_value = false;

    for( int i=2; i<=8; i++ ) {
      if( (i % 2) == 0 ) {
        _node_borderwidth.add_mark( i, PositionType.BOTTOM, "%d".printf( i ) );
      } else {
        _node_borderwidth.add_mark( i, PositionType.BOTTOM, null );
      }
    }

    _node_borderwidth.change_value.connect( node_borderwidth_changed );
    _node_borderwidth.button_release_event.connect( node_borderwidth_released );

    box.pack_start( lbl,               false, true );
    box.pack_end(   _node_borderwidth, false, true );

    return( box );

  }

  /* Called whenever the user changes the link width value */
  private bool node_borderwidth_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    var borderwidth = new UndoStyleNodeBorderwidth( _affects, intval, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( borderwidth );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( borderwidth );
    }
    return( false );
  }

  private bool node_borderwidth_released( EventButton e ) {
    _change_add = true;
    return( false );
  }

  /* Create the node fill UI */
  private Box create_node_fill_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Color Fill") );
    lbl.xalign = (float)0;

    _node_fill = new Switch();
    _node_fill.button_release_event.connect( node_fill_changed );

    box.pack_start( lbl,        false, true );
    box.pack_end(   _node_fill, false, true );

    return( box );

  }

  /* Called whenever the node fill status changes */
  private bool node_fill_changed( Gdk.EventButton e ) {
    bool val = !_node_fill.get_active();
    Idle.add(() => {
      _da.undo_buffer.add_item( new UndoStyleNodeFill( _affects, val, _da ) );
      return( Source.REMOVE );
    });
    return( false );
  }

  /* Allows the user to change the node margin */
  private Box create_node_margin_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Margin" ) );
    lbl.xalign = (float)0;

    _node_margin = new Scale.with_range( Orientation.HORIZONTAL, 1, 20, 1 );
    _node_margin.draw_value = true;
    _node_margin.change_value.connect( node_margin_changed );
    _node_margin.button_release_event.connect( node_margin_released );

    box.pack_start( lbl,          false, true );
    box.pack_end(   _node_margin, false, true );

    return( box );

  }

  /* Called whenever the node margin value is changed */
  private bool node_margin_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 20 ) {
      return( false );
    }
    var margin = new UndoStyleNodeMargin( _affects, intval, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( margin );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( margin );
    }
    return( false );
  }

  private bool node_margin_released( EventButton e ) {
    _change_add = true;
    return( false );
  }

  /* Allows the user to change the node padding */
  private Box create_node_padding_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Padding" ) );
    lbl.xalign = (float)0;

    _node_padding = new Scale.with_range( Orientation.HORIZONTAL, 5, 20, 2 );
    _node_padding.draw_value = true;
    _node_padding.change_value.connect( node_padding_changed );
    _node_padding.button_release_event.connect( node_padding_released );

    box.pack_start( lbl,           false, true );
    box.pack_end(   _node_padding, false, true );

    return( box );

  }

  /* Called whenever the node margin value is changed */
  private bool node_padding_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 20 ) {
      return( false );
    }
    var padding = new UndoStyleNodePadding( _affects, intval, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( padding );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( padding );
    }
    return( false );
  }

  private bool node_padding_released( EventButton e ) {
    _change_add = true;
    return( false );
  }

  /* Creates the node font selector */
  private Box create_node_font_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Font" ) );
    lbl.xalign = (float)0;

    _node_font = new FontButton();
    _node_font.use_font = true;
    _node_font.show_style = false;
    _node_font.set_filter_func( (family, face) => {
      var fd     = face.describe();
      var weight = fd.get_weight();
      var style  = fd.get_style();
      return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
    });
    _node_font.font_set.connect(() => {
      var family = _node_font.get_font_family().get_name();
      var size   = _node_font.get_font_size();
      _da.undo_buffer.add_item( new UndoStyleNodeFont( _affects, family, size, _da ) );
    });

    box.pack_start( lbl,      false, true );
    box.pack_end( _node_font, false, true );

    return( box );

  }

  /* Creates the node width selector */
  private Box create_node_width_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Width" ) );
    lbl.xalign = (float)0;

    _node_width = new SpinButton.with_range( 200, 1000, 100 );
    _node_width.set_value( _settings.get_int( "style-node-width" ) );
    _node_width.value_changed.connect(() => {
      if( !_ignore ) {
        var width = (int)_node_width.get_value();
        _da.undo_buffer.replace_item( new UndoStyleNodeWidth( _affects, width, _da ) );
      }
    });

    box.pack_start( lbl,       false, true );
    box.pack_end( _node_width, false, true );

    return( box );

  }

  private Box create_node_markup_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Enable Markup" ) );
    lbl.xalign = (float)0;

    _node_markup = new Switch();
    _node_markup.button_release_event.connect( node_markup_changed );

    box.pack_start( lbl,        false, true );
    box.pack_end( _node_markup, false, true );

    return( box );

  }

  /* Called whenever the node fill status changes */
  private bool node_markup_changed( Gdk.EventButton e ) {
    bool val = !_node_markup.get_active();
    Idle.add(() => {
      _da.undo_buffer.add_item( new UndoStyleNodeMarkup( _affects, val, _da ) );
      return( Source.REMOVE );
    });
    return( false );
  }

  /* Creates the connection style UI */
  private Box create_connection_ui() {

    var box = new Box( Orientation.VERTICAL, 0 );
    var sep = new Separator( Orientation.HORIZONTAL );

    /* Create expander */
    _conn_exp = new Expander( "  " + Utils.make_title( _( "Connection Options" ) ) );
    _conn_exp.use_markup = true;
    _conn_exp.expanded   = _settings.get_boolean( "style-connection-options-expanded" );
    _conn_exp.activate.connect(() => {
      _settings.set_boolean( "style-connection-options-expanded", !_conn_exp.expanded );
    });

    var cbox = new Box( Orientation.VERTICAL, 10 );
    cbox.homogeneous  = true;
    cbox.border_width = 10;

    var conn_dash    = create_connection_dash_ui();
    var conn_arrow   = create_connection_arrow_ui();
    var conn_lwidth  = create_connection_line_width_ui();
    var conn_padding = create_connection_padding_ui();
    var conn_font    = create_connection_font_ui();
    var conn_twidth  = create_connection_title_width_ui();

    cbox.pack_start( conn_dash,    false, false );
    cbox.pack_start( conn_arrow,   false, false );
    cbox.pack_start( conn_lwidth,  false, false );
    cbox.pack_start( conn_padding, false, false );
    cbox.pack_start( conn_font,    false, false );
    cbox.pack_start( conn_twidth,  false, false );

    _conn_exp.add( cbox );

    box.pack_start( _conn_exp, false, true );
    box.pack_start( sep,       false, true, 10 );

    return( box );

  }

  /* Create the connection dash widget */
  private Box create_connection_dash_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Line Dash" ) );
    lbl.xalign = (float)0;

    var menu   = new Gtk.Menu();
    var dashes = styles.get_link_dashes();

    _conn_dash = new Image.from_surface( dashes.index( 0 ).make_icon() );

    for( int i=0; i<dashes.length; i++ ) {
      var dash = dashes.index( i );
      var img  = new Image.from_surface( dash.make_icon() );
      var mi   = new Gtk.MenuItem();
      mi.activate.connect(() => {
        _da.undo_buffer.add_item( new UndoStyleConnectionDash( _affects, dash, _da ) );
        _conn_dash.surface = img.surface;
      });
      mi.add( img );
      menu.add( mi );
    }

    menu.show_all();

    var mb = new MenuButton();
    mb.add( _conn_dash );
    mb.popup = menu;

    box.pack_start( lbl, false, true );
    box.pack_end(   mb,  false, true );

    return( box );

  }

  /* Creates the connection arrow position UI */
  private Box create_connection_arrow_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Arrows" ) );
    lbl.xalign = (float)0;

    var menu         = new Gtk.Menu();
    string arrows[4] = {"none", "fromto", "tofrom", "both"};

    _conn_arrow = new Image.from_surface( Connection.make_arrow_icon( "fromto" ) );

    foreach (string arrow in arrows) {
      var img = new Image.from_surface( Connection.make_arrow_icon( arrow ) );
      var mi  = new Gtk.MenuItem();
      mi.activate.connect(() => {
        _da.undo_buffer.add_item( new UndoStyleConnectionArrow( _affects, arrow, _da ) );
        _conn_arrow.surface = img.surface;
      });
      mi.add( img );
      menu.add( mi );
    }

    menu.show_all();

    var mb = new MenuButton();
    mb.add( _conn_arrow );
    mb.popup = menu;

    box.pack_start( lbl, false, true );
    box.pack_end(   mb,  false, true );

    return( box );

  }

  /* Create widget for handling the width of a connection */
  private Box create_connection_line_width_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Line Width" ) );
    lbl.xalign = (float)0;

    _conn_lwidth = new Scale.with_range( Orientation.HORIZONTAL, 1, 8, 1 );
    _conn_lwidth.draw_value = false;

    for( int i=2; i<=8; i++ ) {
      if( (i % 2) == 0 ) {
        _conn_lwidth.add_mark( i, PositionType.BOTTOM, "%d".printf( i ) );
      } else {
        _conn_lwidth.add_mark( i, PositionType.BOTTOM, null );
      }
    }

    _conn_lwidth.change_value.connect( connection_line_width_changed );
    _conn_lwidth.button_release_event.connect( connection_line_width_released );

    box.pack_start( lbl,          false, true );
    box.pack_end(   _conn_lwidth, false, true );

    return( box );

  }

  /* Called whenever the user changes the link width value */
  private bool connection_line_width_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 8 ) intval = 8;
    var width = new UndoStyleConnectionLineWidth( _affects, intval, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( width );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( width );
    }
    return( false );
  }

  private bool connection_line_width_released( EventButton e ) {
    _change_add = true;
    return( false );
  }

  /* Allows the user to change the node padding */
  private Box create_connection_padding_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous = true;

    var lbl = new Label( _( "Padding" ) );
    lbl.xalign = (float)0;

    _conn_padding = new Scale.with_range( Orientation.HORIZONTAL, 2, 10, 2 );
    _conn_padding.draw_value = true;
    _conn_padding.change_value.connect( connection_padding_changed );
    _conn_padding.button_release_event.connect( connection_padding_released );

    box.pack_start( lbl,           false, true );
    box.pack_end(   _conn_padding, false, true );

    return( box );

  }

  /* Called whenever the node margin value is changed */
  private bool connection_padding_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 20 ) {
      return( false );
    }
    var padding = new UndoStyleConnectionPadding( _affects, intval, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( padding );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( padding );
    }
    return( false );
  }

  private bool connection_padding_released( EventButton e ) {
    _change_add = true;
    return( false );
  }

  /* Creates the node font selector */
  private Box create_connection_font_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Title Font" ) );
    lbl.xalign = (float)0;

    _conn_font = new FontButton();
    _conn_font.use_font = true;
    _conn_font.show_style = false;
    _conn_font.set_filter_func( (family, face) => {
      var fd     = face.describe();
      var weight = fd.get_weight();
      var style  = fd.get_style();
      return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
    });
    _conn_font.font_set.connect(() => {
      var family = _conn_font.get_font_family().get_name();
      var size   = _conn_font.get_font_size();
      _da.undo_buffer.add_item( new UndoStyleConnectionFont( _affects, family, size, _da ) );
    });

    box.pack_start( lbl,      false, true );
    box.pack_end( _conn_font, false, true );

    return( box );

  }

  /* Creates the connection title width selector */
  private Box create_connection_title_width_ui() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( _( "Title Width" ) );
    lbl.xalign = (float)0;

    _conn_twidth = new SpinButton.with_range( 100, 400, 50 );
    _conn_twidth.set_value( _settings.get_int( "style-connection-title-width" ) );
    _conn_twidth.value_changed.connect(() => {
      if( !_ignore ) {
        var width = (int)_conn_twidth.get_value();
        _da.undo_buffer.replace_item( new UndoStyleConnectionTitleWidth( _affects, width, _da ) );
      }
    });

    box.pack_start( lbl,        false, true );
    box.pack_end( _conn_twidth, false, true );

    return( box );

  }

  /* Sets the affects value and save the change to the settings */
  private void set_affects( StyleAffects affects ) {
    var selected         = _da.get_selections();
    _affects             = affects;
    _affects_label.label = affects.label();
    switch( _affects ) {
      case StyleAffects.ALL     :
        update_ui_with_style( styles.get_global_style() );
        _branch_group.visible = true;
        _link_group.visible   = true;
        _node_group.visible   = true;
        _conn_group.visible   = true;
        _conn_exp.expanded    = _settings.get_boolean( "style-connection-options-expanded" );
        break;
      case StyleAffects.SELECTED_NODES :
        update_ui_with_style( selected.nodes().index( 0 ).style );
        _branch_group.visible = true;
        _link_group.visible   = true;
        _node_group.visible   = true;
        _conn_group.visible   = false;
        break;
      case StyleAffects.SELECTED_CONNECTIONS :
        update_ui_with_style( selected.connections().index( 0 ).style );
        _branch_group.visible = false;
        _link_group.visible   = false;
        _node_group.visible   = false;
        _conn_group.visible   = true;
        _conn_exp.expanded    = true;
        break;
    }
  }

  /* Checks the nodes in the given tree at the specified level to see if there are any non-leaf nodes */
  private bool check_level_for_branches( Node node, int levels, int level ) {
    if( (levels & (1 << level)) != 0 ) {
      return( !node.is_leaf() );
    } else {
      for( int i=0; i<node.children().length; i++ ) {
        if( check_level_for_branches( node.children().index( i ), levels, ((level == 9) ? 9 : (level + 1)) ) ) {
          return( true );
        }
      }
      return( false );
    }
  }

  /* We need to disable the link types widget if our affected nodes are leaf nodes only */
  private void update_link_types_state() {
    bool sensitive = false;
    switch( _affects ) {
      case StyleAffects.ALL :
        for( int i=0; i<_da.get_nodes().length; i++ ) {
          if( !_da.get_nodes().index( i ).is_leaf() ) {
            sensitive = true;
            break;
          }
        }
        break;
      case StyleAffects.SELECTED_NODES :
        for( int i=0; i<_da.get_selected_nodes().length; i++ ) {
          if( _da.get_selected_nodes().index( i ).children().length > 0 ) {
            sensitive = true;
            break;
          }
        }
        break;
    }
    _link_types.set_sensitive( sensitive );
  }

  private void update_link_types_with_style( Style style ) {
    var link_types = styles.get_link_types();
    for( int i=0; i<link_types.length; i++ ) {
      if( link_types.index( i ).name() == style.link_type.name() ) {
        _link_types.selected = i;
        break;
      }
    }
    update_link_types_state();
    _branch_radius_revealer.visible      = (style.link_type.name() == "rounded") && _link_types.get_sensitive();
    _branch_radius_revealer.reveal_child = (style.link_type.name() == "rounded") && _link_types.get_sensitive();
  }

  private void update_link_dashes_with_style( Style style ) {
    var link_dashes = styles.get_link_dashes();
    for( int i=0; i<link_dashes.length; i++ ) {
      if( link_dashes.index( i ).name == style.link_dash.name ) {
        _link_dash.surface = link_dashes.index( i ).make_icon();
        break;
      }
    }
  }

  private void update_node_borders_with_style( Style style ) {
    var node_borders = styles.get_node_borders();
    for( int i=0; i<node_borders.length; i++ ) {
      if( node_borders.index( i ).name() == style.node_border.name() ) {
        _node_borders.selected = i;
        break;
      }
    }
  }

  private void update_conn_dashes_with_style( Style style ) {
    var link_dashes = styles.get_link_dashes();
    for( int i=0; i<link_dashes.length; i++ ) {
      if( link_dashes.index( i ).name == style.connection_dash.name ) {
        _conn_dash.surface = link_dashes.index( i ).make_icon();
        break;
      }
    }
  }

  /* Update the user interface elements to match the selected level */
  private void update_ui_with_style( Style style ) {

    var branch_margin   = style.branch_margin;
    var branch_radius   = style.branch_radius;
    var link_width      = style.link_width;
    var link_arrow      = style.link_arrow;
    var node_bw         = style.node_borderwidth;
    var node_fill       = style.node_fill;
    var node_margin     = style.node_margin;
    var node_padding    = style.node_padding;
    var node_width      = style.node_width;
    var node_markup     = style.node_markup;
    var conn_line_width = style.connection_line_width;
    var conn_padding    = style.connection_padding;

    _ignore = true;
    _branch_margin.set_value( (double)branch_margin );
    _branch_radius.set_value( (double)branch_radius );
    update_link_types_with_style( style );
    update_link_dashes_with_style( style );
    update_node_borders_with_style( style );
    update_conn_dashes_with_style( style );
    _link_width.set_value( (double)link_width );
    _link_arrow.set_active( (bool)link_arrow );
    _node_borderwidth.set_value( (double)node_bw );
    _node_fill.set_active( (bool)node_fill );
    _node_fill.set_sensitive( style.node_border.is_fillable() );
    _node_margin.set_value( (double)node_margin );
    _node_padding.set_value( (double)node_padding );
    _node_font.set_font( style.node_font.to_string() );
    _node_width.set_value( (float)node_width );
    _node_markup.set_active( (bool)node_markup );
    _conn_arrow.surface = Connection.make_arrow_icon( style.connection_arrow );
    _conn_lwidth.set_value( (double)conn_line_width );
    _conn_font.set_font( style.connection_font.to_string() );
    _conn_twidth.set_value( style.connection_title_width );
    _conn_padding.set_value( (double)conn_padding );
    _ignore = false;

  }

  /* Called whenever the current node changes */
  private void handle_current_changed() {
    if( _da.get_current_node() != null ) {
      update_ui_with_style( _da.get_current_node().style );
    } else if( _da.get_current_connection() != null ) {
      update_ui_with_style( _da.get_current_connection().style );
    }
    handle_ui_changed();
  }

  /* Called whenever the current node or connection changes */
  private void handle_ui_changed() {
    var selected = _da.get_selections();
    if( selected.num_nodes() > 0 ) {
      set_affects( StyleAffects.SELECTED_NODES );
    } else if( selected.num_connections() > 0 ) {
      set_affects( StyleAffects.SELECTED_CONNECTIONS );
    } else {
      set_affects( StyleAffects.ALL );
    }
  }

  /* Grabbing focus on the first UI element */
  public void grab_first() {
    _link_types.grab_focus();
  }

}
