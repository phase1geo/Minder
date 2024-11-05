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
  SELECTED_CONNECTIONS,  // Applies changes to selected connections
  SELECTED_CALLOUTS;     // Applies changes to selected callouts

  /* Displays the label to display for this enumerated value */
  public string label() {
    switch( this ) {
      case ALL                  :  return( _( "All" ) );
      case SELECTED_NODES       :  return( _( "Selected Nodes" ) );
      case SELECTED_CONNECTIONS :  return( _( "Selected Connections" ) );
      case SELECTED_CALLOUTS    :  return( _( "Selected Callouts" ) );
    }
    return( _( "Unknown" ) );
  }

}

public class StyleInspector : Box {

  private DrawArea?        _da = null;
  private GLib.Settings    _settings;
  private Revealer         _branch_radius_revealer;
  private Scale            _branch_radius;
  private Scale            _branch_margin;
  private ModeButtons      _link_types;
  private Scale            _link_width;
  private Switch           _link_arrow;
  private Picture          _link_dash;
  private ModeButtons      _node_borders;
  private Scale            _node_borderwidth;
  private Switch           _node_fill;
  private Scale            _node_margin;
  private Scale            _node_padding;
  private FontDialogButton _node_font;
  private SpinButton       _node_width;
  private Switch           _node_markup;
  private Picture          _conn_dash;
  private Picture          _conn_arrow;
  private Scale            _conn_lwidth;
  private Scale            _conn_padding;
  private FontDialogButton _conn_font;
  private SpinButton       _conn_twidth;
  private FontDialogButton _callout_font;
  private Scale            _callout_padding;
  private Scale            _callout_ptr_width;
  private Scale            _callout_ptr_length;
  private StyleAffects     _affects;
  private Label            _affects_label;
  private Box              _branch_group;
  private Box              _link_group;
  private Box              _node_group;
  private Box              _conn_group;
  private Box              _callout_group;
  private Expander         _conn_exp;
  private Expander         _callout_exp;
  private bool             _change_add = true;
  private bool             _ignore     = false;

  public static Styles styles = new Styles();

  public StyleInspector( MainWindow win, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:20 );

    _settings = settings;

    /* Initialize the affects */
    _affects = StyleAffects.ALL;

    /* Create the UI for nodes */
    var affect = create_affect_ui();

    _branch_group  = create_branch_ui();
    _link_group    = create_link_ui();
    _node_group    = create_node_ui();
    _conn_group    = create_connection_ui();
    _callout_group = create_callout_ui();

    /* Pack the scrollwindow */
    var box = new Box( Orientation.VERTICAL, 10 );
    box.append( _branch_group );
    box.append( _link_group );
    box.append( _node_group );
    box.append( _conn_group );
    box.append( _callout_group );

    var sw = new ScrolledWindow() {
      child = box
    };
    sw.child.set_size_request( 200, 600 );

    /* Pack the elements into this widget */
    append( affect );
    append( sw );

    /* Listen for changes to the current tab in the main window */
    win.canvas_changed.connect( tab_changed );

  }

  /* Listen for any changes to the current tab in the main window */
  private void tab_changed( DrawArea? da ) {
    if( _da != null ) {
//      _da.current_changed.disconnect( handle_current_changed );
    }
    if( da != null ) {
//      da.current_changed.connect( handle_current_changed );
    }
    _da = da;
    handle_ui_changed();
  }

  /* Creates the menubutton that changes the affect */
  private Box create_affect_ui() {

    var lbl = new Label( Utils.make_title( _( "Changes affect:" ) ) ) {
      halign     = Align.START,
      use_markup = true
    };

    _affects_label = new Label( "" ) {
      halign = Align.START
    };

    /* Pack the menubutton box */
    var box = new Box( Orientation.HORIZONTAL, 10 );
    box.append( lbl );
    box.append( _affects_label );

    return( box );

  }

  /* Adds the options to manipulate line options */
  private Box create_branch_ui() {

    var branch_type   = create_branch_type_ui();
    var branch_radius = create_branch_radius_ui();
    var branch_margin = create_branch_margin_ui();

    var cbox = new Box( Orientation.VERTICAL, 0 ) {
      vexpand       = true,
      homogeneous   = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
   //   margin_bottom = 10
    };
    cbox.append( branch_type );
    cbox.append( branch_radius );
    cbox.append( branch_margin );

    /* Create expander */
    var exp = new Expander( "  " + Utils.make_title( _( "Branch Options" ) ) ) {
      use_markup = true,
      expanded   = _settings.get_boolean( "style-branch-options-expanded" ),
      child      = cbox
    };
    exp.activate.connect(() => {
      _settings.set_boolean( "style-branch-options-expanded", !exp.expanded );
    });

    var sep = new Separator( Orientation.HORIZONTAL );

    var box = new Box( Orientation.VERTICAL, 10 );
    box.append( exp );
    box.append( sep );

    return( box );

  }

  /* Create the branch type UI */
  private Box create_branch_type_ui() {

    var lbl = new Label( _( "Style" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _link_types = new ModeButtons() {
      halign = Align.END
    };
    _link_types.changed.connect( action_set_link_type );

    var link_types = styles.get_link_types();
    for( int i=0; i<link_types.length; i++ ) {
      var link_type = link_types.index( i );
      _link_types.add_button( link_type.icon_name(), link_type.display_name() );
    }

    var box = new Box( Orientation.HORIZONTAL, 10 ) {
      homogeneous = true
    };
    box.append( lbl );
    box.append( _link_types );

    return( box );

  }

  /* Called whenever the user changes the current layout */
  private void action_set_link_type( int index ) {
    var link_types = styles.get_link_types();
    if( index < link_types.length ) {
      var link_type = link_types.index( _link_types.selected );
      _da.undo_buffer.add_item( new UndoStyleLinkType( _affects, link_type, _da ) );
    }
  }

  private Revealer create_branch_radius_ui() {

    var lbl = new Label( _( "Corner Radius" ) ) {
      hexpand = true,
      xalign  = (float)0
    };

    _branch_radius = new Scale.with_range( Orientation.HORIZONTAL, 10, 40, 1 ) {
      halign     = Align.FILL,
      draw_value = true
    };
    _branch_radius.change_value.connect( branch_radius_changed );

    var box = new Box( Orientation.HORIZONTAL, 10 ) {
      homogeneous = true
    };
    box.append( lbl );
    box.append( _branch_radius );

    _branch_radius_revealer = new Revealer() {
      reveal_child = false,
      child        = box
    };

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

  private Box create_branch_margin_ui() {

    var lbl = new Label( _( "Margin" ) ) {
      hexpand = true,
      xalign  = (float)0
    };

    _branch_margin = new Scale.with_range( Orientation.HORIZONTAL, 20, 150, 10 ) {
      halign     = Align.FILL,
      draw_value = true
    };
    _branch_margin.change_value.connect( branch_margin_changed );

    var box = new Box( Orientation.HORIZONTAL, 10 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( _branch_margin );

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

  /* Adds the options to manipulate line options */
  private Box create_link_ui() {

    var link_dash  = create_link_dash_ui();
    var link_width = create_link_width_ui();
    var link_arrow = create_link_arrow_ui();

    var cbox = new Box( Orientation.VERTICAL, 10 ) {
      homogeneous   = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    cbox.append( link_dash );
    cbox.append( link_width );
    cbox.append( link_arrow );

    /* Create expander */
    var exp = new Expander( "  " + Utils.make_title( _( "Link Options" ) ) ) {
      use_markup = true,
      expanded   = _settings.get_boolean( "style-link-options-expanded" ),
      child      = cbox
    };
    exp.activate.connect(() => {
      _settings.set_boolean( "style-link-options-expanded", !exp.expanded );
    });

    var sep = new Separator( Orientation.HORIZONTAL );

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( exp );
    box.append( sep );

    return( box );

  }

  /* Create the link dash widget */
  private Box create_link_dash_ui() {

    var lbl = new Label( _( "Line Dash" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    var dashes = styles.get_link_dashes();

    _link_dash = new Picture.for_paintable( dashes.index( 0 ).make_icon() );

    var menu = new GLib.Menu();
    /* TODO - Need to figure out how to display the paintables
    for( int i=0; i<dashes.length; i++ ) {
      var dash = dashes.index( i );
      var img  = new Image.from_paintable( dash.make_icon() );
      var mi   = new Gtk.MenuItem( );
      mi.activate.connect(() => {
        _da.undo_buffer.add_item( new UndoStyleLinkDash( _affects, dash, _da ) );
        _link_dash.paintable = img.paintable;
      });
      mi.add( img );
      menu.add( mi );
    }
    */

    var popover = new Popover();

    var mb = new MenuButton() {
      halign  = Align.END,
      valign  = Align.CENTER,
      child   = _link_dash,
      popover = popover
    };

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( mb );

    return( box );

  }

  /* Create widget for handling the width of a link */
  private Box create_link_width_ui() {

    var lbl = new Label( _( "Line Width" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _link_width = new Scale.with_range( Orientation.HORIZONTAL, 2, 8, 1 ) {
      halign     = Align.FILL,
      draw_value = false
    };

    for( int i=2; i<=8; i++ ) {
      if( (i % 2) == 0 ) {
        _link_width.add_mark( i, PositionType.BOTTOM, "%d".printf( i ) );
      } else {
        _link_width.add_mark( i, PositionType.BOTTOM, null );
      }
    }

    _link_width.change_value.connect( link_width_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      homogeneous = true
    };
    box.append( lbl );
    box.append( _link_width );

    return( box );

  }

  /* Called whenever the user changes the link width value */
  private bool link_width_changed( ScrollType scroll, double value ) {
    if( value > 8 ) value = 8;
    var int_value  = (int)value;
    var link_width = new UndoStyleLinkWidth( _affects, int_value, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( link_width );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( link_width );
    }
    return( false );
  }

  /* Creates the link arrow UI element */
  private Box create_link_arrow_ui() {

    var lbl = new Label( _( "Link Arrow" ) ) {
      halign  = Align.START,
      hexpand = true
    };

    _link_arrow = new Switch() {
      halign = Align.END,
      valign = Align.CENTER,
      active = false
    };
    _link_arrow.notify["active"].connect( link_arrow_changed );

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( lbl );
    box.append( _link_arrow );

    return( box );

  }

  /* Called when the user clicks on the link arrow switch */
  private void link_arrow_changed() {
    bool val = !_link_arrow.get_active();
    _da.undo_buffer.add_item( new UndoStyleLinkArrow( _affects, val, _da ) );
  }

  /* Creates the options to manipulate node options */
  private Box create_node_ui() {

    var node_border      = create_node_border_ui();
    var node_borderwidth = create_node_borderwidth_ui();
    var node_fill        = create_node_fill_ui();
    var node_margin      = create_node_margin_ui();
    var node_padding     = create_node_padding_ui();
    var node_font        = create_node_font_ui();
    var node_width       = create_node_width_ui();
    var node_markup      = create_node_markup_ui();

    var cbox = new Box( Orientation.VERTICAL, 10 ) {
      homogeneous   = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    cbox.append( node_border );
    cbox.append( node_borderwidth );
    cbox.append( node_fill );
    cbox.append( node_margin );
    cbox.append( node_padding );
    cbox.append( node_font );
    cbox.append( node_width );
    cbox.append( node_markup );

    /* Create expander */
    var exp = new Expander( "  " + Utils.make_title( _( "Node Options" ) ) ) {
      use_markup = true,
      expanded   = _settings.get_boolean( "style-node-options-expanded" ),
      child      = cbox
    };
    exp.activate.connect(() => {
      _settings.set_boolean( "style-node-options-expanded", !exp.expanded );
    });

    var sep = new Separator( Orientation.HORIZONTAL );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( exp );
    box.append( sep );

    return( box );

  }

  /* Creates the node border panel */
  private Box create_node_border_ui() {

    var lbl = new Label( _( "Border Style" ) ) {
      halign  = Align.START,
      hexpand = true
    };

    _node_borders = new ModeButtons() {
      halign = Align.END
    };
    _node_borders.changed.connect( set_node_border );

    var node_borders = styles.get_node_borders();
    for( int i=0; i<node_borders.length; i++ ) {
      var node_border = node_borders.index( i );
      _node_borders.add_button( node_border.icon_name(), node_border.display_name() );
    }

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.append( lbl );
    box.append( _node_borders );

    return( box );

  }

  /* Called whenever the user changes the current layout */
  private void set_node_border( int index ) {
    var node_borders = styles.get_node_borders();
    if( index < node_borders.length ) {
      _da.undo_buffer.add_item( new UndoStyleNodeBorder( _affects, node_borders.index( index ), _da ) );
    }
  }

  /* Create widget for handling the width of a link */
  private Box create_node_borderwidth_ui() {

    var lbl = new Label( _( "Border Width" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _node_borderwidth = new Scale.with_range( Orientation.HORIZONTAL, 2, 8, 1 ) {
      halign     = Align.FILL,
      draw_value = false
    };

    for( int i=2; i<=8; i++ ) {
      if( (i % 2) == 0 ) {
        _node_borderwidth.add_mark( i, PositionType.BOTTOM, "%d".printf( i ) );
      } else {
        _node_borderwidth.add_mark( i, PositionType.BOTTOM, null );
      }
    }

    _node_borderwidth.change_value.connect( node_borderwidth_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      homogeneous = true
    };
    box.append( lbl );
    box.append( _node_borderwidth );

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

  /* Create the node fill UI */
  private Box create_node_fill_ui() {

    var lbl = new Label( _( "Color Fill") ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _node_fill = new Switch() {
      halign       = Align.END,
      valign       = Align.CENTER,
      tooltip_text = _("Fills the node with color when the node\nborder is square, rounded or pill-shaped" )
    };
    _node_fill.notify["active"].connect( node_fill_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.append( lbl );
    box.append( _node_fill );

    return( box );

  }

  /* Called whenever the node fill status changes */
  private void node_fill_changed() {
    bool val = !_node_fill.get_active();
    _da.undo_buffer.add_item( new UndoStyleNodeFill( _affects, val, _da ) );
  }

  /* Allows the user to change the node margin */
  private Box create_node_margin_ui() {

    var lbl = new Label( _( "Margin" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _node_margin = new Scale.with_range( Orientation.HORIZONTAL, 1, 20, 1 ) {
      halign     = Align.FILL,
      draw_value = true
    };
    _node_margin.change_value.connect( node_margin_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      homogeneous = true
    };
    box.append( lbl );
    box.append( _node_margin );

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

  /* Allows the user to change the node padding */
  private Box create_node_padding_ui() {

    var lbl = new Label( _( "Padding" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _node_padding = new Scale.with_range( Orientation.HORIZONTAL, 5, 20, 2 ) {
      halign     = Align.FILL,
      draw_value = true
    };
    _node_padding.change_value.connect( node_padding_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      homogeneous = true
    };
    box.append( lbl );
    box.append( _node_padding );

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

  /* Creates the node font selector */
  private Box create_node_font_ui() {

    var lbl = new Label( _( "Font" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    var font_dialog = new FontDialog();
    _node_font = new FontDialogButton( font_dialog ) {
      valign   = Align.CENTER,
      use_font = true,
      use_size = true
    };
    var font_filter = new CustomFilter((obj) => {
      var font_face = (obj as Pango.FontFace);
      if( font_face != null ) {
        var fd     = font_face.describe();
        var weight = fd.get_weight();
        var style  = fd.get_style();
        return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
      }
      return( false );
    });
    font_dialog.set_filter( font_filter );
    _node_font.notify["font_desc"].connect(() => {
      var family = _node_font.font_desc.get_family();
      var size   = _node_font.font_desc.get_size();
      _da.undo_buffer.add_item( new UndoStyleNodeFont( _affects, family, size, _da ) );
    });

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _node_font );

    return( box );

  }

  /* Creates the node width selector */
  private Box create_node_width_ui() {

    var lbl = new Label( _( "Width" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _node_width = new SpinButton.with_range( 200, 1000, 100 ) {
      halign = Align.END,
      valign = Align.CENTER,
      value  = _settings.get_int( "style-node-width" )
    };
    _node_width.value_changed.connect(() => {
      if( !_ignore ) {
        var width = (int)_node_width.get_value();
        _da.undo_buffer.replace_item( new UndoStyleNodeWidth( _affects, width, _da ) );
      }
    });

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _node_width );

    return( box );

  }

  private Box create_node_markup_ui() {

    var lbl = new Label( _( "Enable Markup" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _node_markup = new Switch() {
      halign = Align.END,
      valign = Align.CENTER
    };
    _node_markup.notify["active"].connect( node_markup_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _node_markup );

    return( box );

  }

  /* Called whenever the node fill status changes */
  private void node_markup_changed() {
    var val = !_node_markup.get_active();
    _da.undo_buffer.add_item( new UndoStyleNodeMarkup( _affects, val, _da ) );
  }

  /* Creates the connection style UI */
  private Box create_connection_ui() {

    var conn_dash    = create_connection_dash_ui();
    var conn_arrow   = create_connection_arrow_ui();
    var conn_lwidth  = create_connection_line_width_ui();
    var conn_padding = create_connection_padding_ui();
    var conn_font    = create_connection_font_ui();
    var conn_twidth  = create_connection_title_width_ui();

    var cbox = new Box( Orientation.VERTICAL, 10 ) {
      homogeneous   = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    cbox.append( conn_dash );
    cbox.append( conn_arrow );
    cbox.append( conn_lwidth );
    cbox.append( conn_padding );
    cbox.append( conn_font );
    cbox.append( conn_twidth );

    /* Create expander */
    _conn_exp = new Expander( "  " + Utils.make_title( _( "Connection Options" ) ) ) {
      use_markup = true,
      expanded   = _settings.get_boolean( "style-connection-options-expanded" ),
      child      = cbox
    };
    _conn_exp.activate.connect(() => {
      _settings.set_boolean( "style-connection-options-expanded", !_conn_exp.expanded );
    });

    var sep = new Separator( Orientation.HORIZONTAL );

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( _conn_exp );
    box.append( sep );

    return( box );

  }

  /* Create the connection dash widget */
  private Box create_connection_dash_ui() {

    var lbl = new Label( _( "Line Dash" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    var dashes = styles.get_link_dashes();

    _conn_dash = new Picture.for_paintable( dashes.index( 0 ).make_icon() );

    /*
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
    */

    var popover = new Popover();

    var mb = new MenuButton() {
      halign  = Align.END,
      valign  = Align.CENTER,
      child   = _conn_dash,
      popover = popover
    };

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( mb );

    return( box );

  }

  /* Creates the connection arrow position UI */
  private Box create_connection_arrow_ui() {

    var lbl = new Label( _( "Arrows" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _conn_arrow = new Picture.for_paintable( Connection.make_arrow_icon( "fromto" ) );

    /* TODO
    var menu         = new Gtk.Menu();
    string arrows[4] = {"none", "fromto", "tofrom", "both"};

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
    */

    var popover = new Popover();

    var mb = new MenuButton() {
      halign  = Align.END,
      valign  = Align.CENTER,
      child   = _conn_arrow,
      popover = popover
    };

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( mb );

    return( box );

  }

  /* Create widget for handling the width of a connection */
  private Box create_connection_line_width_ui() {

    var lbl = new Label( _( "Line Width" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _conn_lwidth = new Scale.with_range( Orientation.HORIZONTAL, 1, 8, 1 ) {
      halign     = Align.FILL,
      draw_value = false
    };

    for( int i=2; i<=8; i++ ) {
      if( (i % 2) == 0 ) {
        _conn_lwidth.add_mark( i, PositionType.BOTTOM, "%d".printf( i ) );
      } else {
        _conn_lwidth.add_mark( i, PositionType.BOTTOM, null );
      }
    }

    _conn_lwidth.change_value.connect( connection_line_width_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( _conn_lwidth );

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

  /* Allows the user to change the node padding */
  private Box create_connection_padding_ui() {

    var lbl = new Label( _( "Padding" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _conn_padding = new Scale.with_range( Orientation.HORIZONTAL, 2, 10, 2 ) {
      halign     = Align.FILL,
      draw_value = true
    };
    _conn_padding.change_value.connect( connection_padding_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( _conn_padding );

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

  /* Creates the node font selector */
  private Box create_connection_font_ui() {

    var lbl = new Label( _( "Title Font" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    var font_dialog = new FontDialog();
    _conn_font = new FontDialogButton( font_dialog ) {
      valign   = Align.CENTER,
      use_font = true,
      use_size = true
    };
    var font_filter = new CustomFilter((obj) => {
      var font_face = (obj as Pango.FontFace);
      if( font_face != null ) {
        var fd     = font_face.describe();
        var weight = fd.get_weight();
        var style  = fd.get_style();
        return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
      }
      return( false );
    });
    font_dialog.set_filter( font_filter );
    _conn_font.notify["font_desc"].connect(() => {
      var family = _node_font.font_desc.get_family();
      var size   = _node_font.font_desc.get_size();
      _da.undo_buffer.add_item( new UndoStyleConnectionFont( _affects, family, size, _da ) );
    });

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _conn_font );

    return( box );

  }

  /* Creates the connection title width selector */
  private Box create_connection_title_width_ui() {

    var lbl = new Label( _( "Title Width" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _conn_twidth = new SpinButton.with_range( 100, 400, 50 ) {
      halign = Align.END,
      valign = Align.CENTER,
      value  = _settings.get_int( "style-connection-title-width" )
    };
    _conn_twidth.value_changed.connect(() => {
      if( !_ignore ) {
        var width = (int)_conn_twidth.get_value();
        _da.undo_buffer.replace_item( new UndoStyleConnectionTitleWidth( _affects, width, _da ) );
      }
    });

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _conn_twidth );

    return( box );

  }

  /* Creates the callout style UI */
  private Box create_callout_ui() {

    var callout_font    = create_callout_font_ui();
    var callout_padding = create_callout_padding_ui();
    var callout_pwidth  = create_callout_pointer_width_ui();
    var callout_plength = create_callout_pointer_length_ui();

    var cbox = new Box( Orientation.VERTICAL, 10 ) {
      homogeneous   = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    cbox.append( callout_font );
    cbox.append( callout_padding );
    cbox.append( callout_pwidth );
    cbox.append( callout_plength );

    /* Create expander */
    _callout_exp = new Expander( "  " + Utils.make_title( _( "Callout Options" ) ) ) {
      use_markup = true,
      expanded   = _settings.get_boolean( "style-callout-options-expanded" ),
      child      = cbox
    };
    _callout_exp.activate.connect(() => {
      _settings.set_boolean( "style-callout-options-expanded", !_callout_exp.expanded );
    });

    var sep = new Separator( Orientation.HORIZONTAL );

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( _callout_exp );
    box.append( sep );

    return( box );

  }

  /* Creates the callout font selector */
  private Box create_callout_font_ui() {

    var lbl = new Label( _( "Text Font" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    var font_dialog = new FontDialog();
    _callout_font = new FontDialogButton( font_dialog ) {
      valign   = Align.CENTER,
      use_font = true,
      use_size = true
    };
    var font_filter = new CustomFilter((obj) => {
      var font_face = (obj as Pango.FontFace);
      if( font_face != null ) {
        var fd     = font_face.describe();
        var weight = fd.get_weight();
        var style  = fd.get_style();
        return( (weight == Pango.Weight.NORMAL) && (style == Pango.Style.NORMAL) );
      }
      return( false );
    });
    font_dialog.set_filter( font_filter );
    _callout_font.notify["font_desc"].connect(() => {
      var family = _node_font.font_desc.get_family();
      var size   = _node_font.font_desc.get_size();
      _da.undo_buffer.add_item( new UndoStyleCalloutFont( _affects, family, size, _da ) );
    });

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _callout_font );

    return( box );

  }

  /* Allows the user to change the callout padding */
  private Box create_callout_padding_ui() {

    var lbl = new Label( _( "Padding" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _callout_padding = new Scale.with_range( Orientation.HORIZONTAL, 4, 20, 2 ) {
      halign     = Align.FILL,
      draw_value = true
    };
    _callout_padding.change_value.connect( callout_padding_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( _callout_padding );

    return( box );

  }

  /* Called whenever the callout padding value is changed */
  private bool callout_padding_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 20 ) {
      return( false );
    }
    var padding = new UndoStyleCalloutPadding( _affects, intval, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( padding );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( padding );
    }
    return( false );
  }

  /* Allows the user to change the callout padding */
  private Box create_callout_pointer_width_ui() {

    var lbl = new Label( _( "Pointer Width" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _callout_ptr_width = new Scale.with_range( Orientation.HORIZONTAL, 10, 30, 5 ) {
      halign     = Align.FILL,
      draw_value = true
    };
    _callout_ptr_width.change_value.connect( callout_pointer_width_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( _callout_ptr_width );

    return( box );

  }

  /* Called whenever the callout padding value is changed */
  private bool callout_pointer_width_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 30 ) {
      return( false );
    }
    var pwidth = new UndoStyleCalloutPointerWidth( _affects, intval, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( pwidth );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( pwidth );
    }
    return( false );
  }

  /* Allows the user to change the callout padding */
  private Box create_callout_pointer_length_ui() {

    var lbl = new Label( _( "Pointer Length" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _callout_ptr_length = new Scale.with_range( Orientation.HORIZONTAL, 10, 100, 5 ) {
      halign     = Align.FILL,
      draw_value = true
    };
    _callout_ptr_length.change_value.connect( callout_pointer_length_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( _callout_ptr_length );

    return( box );

  }

  /* Called whenever the callout padding value is changed */
  private bool callout_pointer_length_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 100 ) {
      return( false );
    }
    var plength = new UndoStyleCalloutPointerLength( _affects, intval, _da );
    if( _change_add ) {
      _da.undo_buffer.add_item( plength );
      _change_add = false;
    } else {
      _da.undo_buffer.replace_item( plength );
    }
    return( false );
  }

  /* Sets the affects value and save the change to the settings */
  private void set_affects( StyleAffects affects ) {
    var selected         = _da.get_selections();
    _affects             = affects;
    _affects_label.label = affects.label();
    switch( _affects ) {
      case StyleAffects.ALL     :
        update_ui_with_style( styles.get_global_style() );
        _branch_group.visible  = true;
        _link_group.visible    = true;
        _node_group.visible    = true;
        _conn_group.visible    = true;
        _callout_group.visible = true;
        _conn_exp.expanded     = _settings.get_boolean( "style-connection-options-expanded" );
        _callout_exp.expanded  = _settings.get_boolean( "style-callout-options-expanded" ); 
        break;
      case StyleAffects.SELECTED_NODES :
        update_ui_with_style( selected.nodes().index( 0 ).style );
        _branch_group.visible  = true;
        _link_group.visible    = true;
        _node_group.visible    = true;
        _conn_group.visible    = false;
        _callout_group.visible = false;
        break;
      case StyleAffects.SELECTED_CONNECTIONS :
        update_ui_with_style( selected.connections().index( 0 ).style );
        _branch_group.visible  = false;
        _link_group.visible    = false;
        _node_group.visible    = false;
        _conn_group.visible    = true;
        _callout_group.visible = false;
        _conn_exp.expanded     = true;
        break;
      case StyleAffects.SELECTED_CALLOUTS :
        update_ui_with_style( selected.callouts().index( 0 ).style );
        _branch_group.visible  = false;
        _link_group.visible    = false;
        _node_group.visible    = false;
        _conn_group.visible    = false;
        _callout_group.visible = true;
        _callout_exp.expanded  = true;
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
        _link_dash.paintable = link_dashes.index( i ).make_icon();
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
        // TODO _conn_dash.paintable = link_dashes.index( i ).make_icon();
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
    var callout_padding = style.callout_padding;
    var callout_pwidth  = style.callout_ptr_width;
    var callout_plength = style.callout_ptr_length;

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
    _node_font.set_font_features( style.node_font.to_string() );
    _node_width.set_value( (float)node_width );
    _node_markup.set_active( (bool)node_markup );
    _conn_arrow.set_paintable( Connection.make_arrow_icon( style.connection_arrow ) );
    _conn_lwidth.set_value( (double)conn_line_width );
    _conn_font.set_font_features( style.connection_font.to_string() );
    _conn_twidth.set_value( style.connection_title_width );
    _conn_padding.set_value( (double)conn_padding );
    _callout_font.set_font_features( style.callout_font.to_string() );
    _callout_padding.set_value( (double)callout_padding );
    _callout_ptr_width.set_value( (double)callout_pwidth );
    _callout_ptr_length.set_value( (double)callout_plength );
    _ignore = false;

  }

  /* Called whenever the current node changes */
  private void handle_current_changed() {
    if( _da.get_current_node() != null ) {
      update_ui_with_style( _da.get_current_node().style );
    } else if( _da.get_current_connection() != null ) {
      update_ui_with_style( _da.get_current_connection().style );
    } else if( _da.get_current_callout() != null ) {
      update_ui_with_style( _da.get_current_callout().style );
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
    } else if( selected.num_callouts() > 0 ) {
      set_affects( StyleAffects.SELECTED_CALLOUTS );
    } else {
      set_affects( StyleAffects.ALL );
    }
  }

  /* Grabbing focus on the first UI element */
  public void grab_first() {
    _link_types.grab_focus();
  }

}
