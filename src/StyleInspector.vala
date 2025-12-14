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
  SELECTED_CALLOUTS,     // Applies changes to selected callouts
  NUM;

  // Displays the label to display for this enumerated value
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

  private MainWindow       _win;
  private MindMap?         _map = null;
  private GLib.Settings    _settings;
  private Scale            _branch_radius;
  private Box              _branch_radius_box;
  private Scale            _branch_margin;
  private ModeButtons      _link_types;
  private Scale            _link_width;
  private Switch           _link_arrow;
  private Scale            _link_arrow_size;
  private ImageMenu        _link_dash;
  private ModeButtons      _node_borders;
  private Scale            _node_borderwidth;
  private Switch           _node_fill;
  private Scale            _node_margin;
  private Scale            _node_padding;
  private FontDialogButton _node_font;
  private ModeButtons      _node_text_align;
  private SpinButton       _node_width;
  private Switch           _node_markup;
  private ImageMenu        _conn_dash;
  private ImageMenu        _conn_arrow;
  private Scale            _conn_arrow_size;
  private Scale            _conn_lwidth;
  private Scale            _conn_padding;
  private FontDialogButton _conn_font;
  private ModeButtons      _conn_text_align;
  private SpinButton       _conn_twidth;
  private FontDialogButton _callout_font;
  private ModeButtons      _callout_text_align;
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
  private Style?           _curr_style = null;
  private Button           _paste_btn;
  private MenuButton       _template_btn;
  private Style?           _clipboard_style  = null;
  private StyleAffects?    _clipboard_affect = null;

  public static Styles styles = new Styles();
  public static Style? last_global_style = null;

  public signal void update_icons();
  public signal void editable_changed();

  //-------------------------------------------------------------
  // Default constructor
  public StyleInspector( MainWindow win, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:20 );

    _win      = win;
    _settings = settings;

    // Initialize the affects
    _affects = StyleAffects.ALL;

    // Create the UI for nodes
    var affect = create_affect_ui();

    _branch_group  = create_branch_ui();
    _link_group    = create_link_ui();
    _node_group    = create_node_ui();
    _conn_group    = create_connection_ui();
    _callout_group = create_callout_ui();

    // Pack the scrollwindow
    var box = new Box( Orientation.VERTICAL, 10 );
    box.append( _branch_group );
    box.append( _link_group );
    box.append( _node_group );
    box.append( _conn_group );
    box.append( _callout_group );

    var sw = new ScrolledWindow() {
      vexpand = true,
      child = box
    };
    // sw.child.set_size_request( 200, 600 );

    // Pack the elements into this widget
    append( affect );
    append( sw );

    // Listen for changes to the current tab in the main window
    win.canvas_changed.connect( tab_changed );
    editable_changed.connect( handle_current_changed );

    // Add the template menus
    _win.templates.add_menus( TemplateType.STYLE_GENERAL,    this, win, add_style_template, load_style_template, delete_style_template );
    _win.templates.add_menus( TemplateType.STYLE_NODE,       this, win, add_style_template, load_style_template, delete_style_template );
    _win.templates.add_menus( TemplateType.STYLE_CONNECTION, this, win, add_style_template, load_style_template, delete_style_template );
    _win.templates.add_menus( TemplateType.STYLE_CALLOUT,    this, win, add_style_template, load_style_template, delete_style_template );

  }

  //-------------------------------------------------------------
  // Listen for any changes to the current tab in the main window
  private void tab_changed( MindMap? map ) {
    if( _map != null ) {
      _map.current_changed.disconnect( handle_current_changed );
    }
    if( map != null ) {
      map.current_changed.connect( handle_current_changed );
    }
    _map = map;
    handle_ui_changed();
  }

  //-------------------------------------------------------------
  // Creates a save as template dialog and displays it to the user
  // If the user successfully adds a name, adds it to the list of
  // templates and saves it to the application template file.
  private void add_style_template( Template template ) {

    var style_template = (StyleTemplate)template;
    style_template.update_from_style( _curr_style );

    // If we are adding a new general style template, add the template
    // to the other styles as well.
    if( style_template.ttype == TemplateType.STYLE_GENERAL ) {

      // Add the node style
      var node_style = new StyleTemplate( TemplateType.STYLE_NODE, template.name );
      node_style.update_from_style( style_template.style );
      _win.templates.add_template( node_style );

      // Add the connection style
      var conn_style = new StyleTemplate( TemplateType.STYLE_CONNECTION, template.name );
      conn_style.update_from_style( style_template.style );
      _win.templates.add_template( conn_style );

      // Add the callout style
      var call_style = new StyleTemplate( TemplateType.STYLE_CALLOUT, template.name );
      call_style.update_from_style( style_template.style );
      _win.templates.add_template( call_style );

    }

  }

  //-------------------------------------------------------------
  // Loads the given template into this widget.
  private void load_style_template( Template template ) {
    var style_template = (StyleTemplate)template;
    update_from_style( style_template.style );
  }

  //-------------------------------------------------------------
  // Handles a deletion request from the template editor.  We will check
  // to see if we are deleting a global style template that is being used
  // by the default style preferences option.  If we are, display a dialog
  // alerting the user about this
  private void delete_style_template() {

    if( (_affects == StyleAffects.ALL) && (Minder.settings.get_int( "default-global-style" ) == 2) ) {

      var name  = Minder.settings.get_string( "default-global-style-name" );
      var group = _win.templates.get_template_group( TemplateType.STYLE_GENERAL );
      var names = group.get_names();
      for( int i=0; i<names.length; i++ ) {
        if( names.index( i ) == name ) {
          return;
        }
      }

      // We didn't find the default global style in preferences, set it to default Minder style
      // and tell the user about it
      Minder.settings.set_int( "default-global-style", 0 );
      Minder.settings.set_string( "default-global-style-name", "" );
      show_global_style_dialog( name );

    }

  }

  //-------------------------------------------------------------
  // Displays a dialog that will prompt the user to select a new
  // default global style value.
  private void show_global_style_dialog( string name ) {

    // Force the default to be "use the default Minder global style"
    Minder.settings.set_int( "default-global-style", 0 );

    var dialog = new Granite.MessageDialog.with_image_from_icon_name(
      _( "Deleted preferences default global style" ),
      _( "The default global style '%s' was deleted.  Setting default global style in preferences to use the default Minder global style." ).printf( name ),
      "dialog-warning",
      ButtonsType.NONE
    ) {
      transient_for = _win,
      title         = "",
    };

    dialog.set_default_response( ResponseType.CLOSE );

    var close = new Button.with_label( _( "Close" ) );
    close.add_css_class( Granite.STYLE_CLASS_SUGGESTED_ACTION );
    dialog.add_action_widget( close, ResponseType.CLOSE );

    dialog.response.connect((id) => {
      dialog.close();
    });

    dialog.show();

  }

  //-------------------------------------------------------------
  // Creates the menubutton that changes the affect
  private Box create_affect_ui() {

    var lbl = new Label( _( "Changes affect:" ) ) {
      halign = Align.START
    };
    lbl.add_css_class( "titled" );

    _affects_label = new Label( "" ) {
      halign = Align.START,
      hexpand = true
    };

    var copy_btn = new Button.from_icon_name( "edit-copy-symbolic" ) {
      halign = Align.END,
      tooltip_text = _( "Copy current style" )
    };

    copy_btn.clicked.connect(() => {
      _clipboard_style = new Style();
      _clipboard_style.copy( _curr_style );
      _clipboard_affect = _affects;
      _paste_btn.sensitive = true;
    });

    _paste_btn = new Button.from_icon_name( "edit-paste-symbolic" ) {
      halign       = Align.END,
      tooltip_text = _( "Paste copied style" ),
      sensitive    = false
    };

    _paste_btn.clicked.connect(() => {
      update_from_style( _clipboard_style );
    });

    _template_btn = new MenuButton() {
      halign       = Align.END,
      icon_name    = "folder-templates-symbolic",
      tooltip_text = _( "Style Templates" )
    };

    // Pack the menubutton box
    var box = new Box( Orientation.HORIZONTAL, 10 );
    box.append( lbl );
    box.append( _affects_label );
    box.append( copy_btn );
    box.append( _paste_btn );
    box.append( _template_btn );

    return( box );

  }

  //-------------------------------------------------------------
  // Adds the options to manipulate line options.
  private Box create_branch_ui() {

    var branch_type   = create_branch_type_ui();
    var branch_radius = create_branch_radius_ui();
    var branch_margin = create_branch_margin_ui();

    var cbox = new Box( Orientation.VERTICAL, 0 ) {
      homogeneous  = true,
      margin_start = 10,
      margin_end   = 10,
      margin_top   = 10,
    };
    cbox.append( branch_type );
    cbox.append( branch_radius );
    cbox.append( branch_margin );

    // Create expander
    var exp = new Expander( "  " + _( "Branch Options" ) ) {
      expanded = _settings.get_boolean( "style-branch-options-expanded" ),
      child    = cbox
    };
    exp.add_css_class( "titled" );
    exp.activate.connect(() => {
      _settings.set_boolean( "style-branch-options-expanded", !exp.expanded );
    });

    var sep = new Separator( Orientation.HORIZONTAL );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( exp );
    box.append( sep );

    return( box );

  }

  //-------------------------------------------------------------
  // Create the branch type UI
  private Box create_branch_type_ui() {

    var lbl = new Label( _( "Style" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _link_types = new ModeButtons() {
      halign = Align.END,
      valign = Align.CENTER
    };
    _link_types.changed.connect( action_set_link_type );

    update_icons.connect(() => {
      _link_types.update_icons();
    });

    var link_types = styles.get_link_types();
    for( int i=0; i<link_types.length; i++ ) {
      var link_type = link_types.index( i );
      _link_types.add_button( link_type.light_icon_name(), link_type.dark_icon_name(), link_type.display_name() );
    }

    var box = new Box( Orientation.HORIZONTAL, 10 ) {
      homogeneous = true
    };
    box.append( lbl );
    box.append( _link_types );

    return( box );

  }

  //-------------------------------------------------------------
  // Called whenever the user changes the current layout
  private void action_set_link_type( int index ) {
    var link_types = styles.get_link_types();
    if( index < link_types.length ) {
      var link_type = link_types.index( _link_types.selected );
      _curr_style.link_type = link_type;
      _map.undo_buffer.add_item( new UndoStyleLinkType( _affects, link_type, _map ) );
    }
  }

  //-------------------------------------------------------------
  // Creates the UI for changing the branch drawing type.
  private Box create_branch_radius_ui() {

    var lbl = new Label( _( "Corner Radius" ) ) {
      hexpand = true,
      xalign  = (float)0
    };

    _branch_radius = new Scale.with_range( Orientation.HORIZONTAL, 10, 40, 1 ) {
      halign     = Align.FILL,
      draw_value = true
    };
    _branch_radius.change_value.connect( branch_radius_changed );

    _branch_radius_box = new Box( Orientation.HORIZONTAL, 10 ) {
      homogeneous = true,
      visible     = false
    };
    _branch_radius_box.append( lbl );
    _branch_radius_box.append( _branch_radius );

    return( _branch_radius_box );

  }

  //-------------------------------------------------------------
  // Called whenever the branch radius value is changed
  private bool branch_radius_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 40 ) {
      return( false );
    }
    var margin = new UndoStyleBranchRadius( _affects, intval, _map );
    _curr_style.branch_radius = intval;
    if( _change_add ) {
      _map.undo_buffer.add_item( margin );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( margin );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Creates the branch margin UI.
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

  //-------------------------------------------------------------
  // Called whenever the node margin value is changed
  private bool branch_margin_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 150 ) {
      return( false );
    }
    var margin = new UndoStyleBranchMargin( _affects, intval, _map );
    _curr_style.branch_margin = intval;
    if( _change_add ) {
      _map.undo_buffer.add_item( margin );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( margin );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Adds the options to manipulate line options
  private Box create_link_ui() {

    var link_dash  = create_link_dash_ui();
    var link_width = create_link_width_ui();
    var link_arrow = create_link_arrow_ui();
    var link_arrow_size = create_link_arrow_size_ui();

    var cbox = new Box( Orientation.VERTICAL, 0 ) {
      homogeneous   = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    cbox.append( link_dash );
    cbox.append( link_width );
    cbox.append( link_arrow );
    cbox.append( link_arrow_size );

    // Create expander
    var exp = new Expander( "  " + _( "Link Options" ) ) {
      expanded = _settings.get_boolean( "style-link-options-expanded" ),
      child    = cbox
    };
    exp.add_css_class( "titled" );
    exp.activate.connect(() => {
      _settings.set_boolean( "style-link-options-expanded", !exp.expanded );
    });

    var sep = new Separator( Orientation.HORIZONTAL );

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( exp );
    box.append( sep );

    return( box );

  }

  //-------------------------------------------------------------
  // Create the link dash widget
  private Box create_link_dash_ui() {

    var lbl = new Label( _( "Line Dash" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    var dashes = styles.get_link_dashes();

    _link_dash = new ImageMenu() {
      halign = Align.END
    };

    _link_dash.changed.connect((index) => {
      _curr_style.link_dash = dashes.index( index );
      _map.undo_buffer.add_item( new UndoStyleLinkDash( _affects, dashes.index( index ), _map ) );
    });

    update_icons.connect(() => {
      _link_dash.update_icons();
    });

    for( int i=0; i<dashes.length; i++ ) {
      var dash = dashes.index( i );
      _link_dash.add_image( dash.make_icon( false ), dash.make_icon( true ) );
    }

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( _link_dash );

    return( box );

  }

  //-------------------------------------------------------------
  // Create widget for handling the width of a link
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

  //-------------------------------------------------------------
  // Called whenever the user changes the link width value
  private bool link_width_changed( ScrollType scroll, double value ) {
    if( value > 8 ) value = 8;
    var int_value  = (int)value;
    var link_width = new UndoStyleLinkWidth( _affects, int_value, _map );
    _curr_style.link_width = int_value;
    if( _change_add ) {
      _map.undo_buffer.add_item( link_width );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( link_width );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Creates the link arrow UI element
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

  //-------------------------------------------------------------
  // Called when the user clicks on the link arrow switch
  private void link_arrow_changed() {
    if( !_ignore ) {
      bool val = _link_arrow.get_active();
      _curr_style.link_arrow = val;
      _map.undo_buffer.add_item( new UndoStyleLinkArrow( _affects, val, _map ) );
    }
  }

  //-------------------------------------------------------------
  // Creates the link arrow size UI.
  private Box create_link_arrow_size_ui() {

    var lbl = new Label( _( "Link Arrow Size" ) ) {
      halign  = Align.START,
      hexpand = true
    };

    _link_arrow_size = new Scale.with_range( Orientation.HORIZONTAL, 0, 3, 1 ) {
      halign     = Align.FILL,
      draw_value = false
    };

    _link_arrow_size.add_mark( 0, PositionType.BOTTOM, "S" );
    _link_arrow_size.add_mark( 1, PositionType.BOTTOM, "M" );
    _link_arrow_size.add_mark( 2, PositionType.BOTTOM, "L" );
    _link_arrow_size.add_mark( 3, PositionType.BOTTOM, "XL" );
    _link_arrow_size.change_value.connect( link_arrow_size_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      homogeneous = true
    };
    box.append( lbl );
    box.append( _link_arrow_size );

    return( box );

  }

  //-------------------------------------------------------------
  // Called whenever the user changes the link arrow size value
  private bool link_arrow_size_changed( ScrollType scroll, double value ) {
    if( value > 3 ) value = 3;
    var int_value       = (int)value;
    var link_arrow_size = new UndoStyleLinkArrowSize( _affects, int_value, _map );
    _curr_style.link_arrow_size = int_value;
    if( _change_add ) {
      _map.undo_buffer.add_item( link_arrow_size );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( link_arrow_size );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Creates the options to manipulate node options
  private Box create_node_ui() {

    var node_border      = create_node_border_ui();
    var node_borderwidth = create_node_borderwidth_ui();
    var node_fill        = create_node_fill_ui();
    var node_margin      = create_node_margin_ui();
    var node_padding     = create_node_padding_ui();
    var node_font        = create_node_font_ui();
    var node_text_align  = create_node_text_align_ui();
    var node_width       = create_node_width_ui();
    var node_markup      = create_node_markup_ui();

    var cbox = new Box( Orientation.VERTICAL, 0 ) {
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
    cbox.append( node_text_align );
    cbox.append( node_width );
    cbox.append( node_markup );

    // Create expander
    var exp = new Expander( "  " + _( "Node Options" ) ) {
      expanded = _settings.get_boolean( "style-node-options-expanded" ),
      child    = cbox
    };
    exp.add_css_class( "titled" );
    exp.activate.connect(() => {
      _settings.set_boolean( "style-node-options-expanded", !exp.expanded );
    });

    var sep = new Separator( Orientation.HORIZONTAL );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( exp );
    box.append( sep );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the node border panel
  private Box create_node_border_ui() {

    var lbl = new Label( _( "Border Style" ) ) {
      halign  = Align.START,
      hexpand = true
    };

    _node_borders = new ModeButtons() {
      halign = Align.END,
      valign = Align.CENTER
    };
    _node_borders.changed.connect( set_node_border );

    update_icons.connect(() => {
      _node_borders.update_icons();
    });

    var node_borders = styles.get_node_borders();
    for( int i=0; i<node_borders.length; i++ ) {
      var node_border = node_borders.index( i );
      _node_borders.add_button( node_border.light_icon_name(), node_border.dark_icon_name(), node_border.display_name() );
    }

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.append( lbl );
    box.append( _node_borders );

    return( box );

  }

  //-------------------------------------------------------------
  // Called whenever the user changes the current layout
  private void set_node_border( int index ) {
    var node_borders = styles.get_node_borders();
    if( index < node_borders.length ) {
      _curr_style.node_border = node_borders.index( index );
      _map.undo_buffer.add_item( new UndoStyleNodeBorder( _affects, node_borders.index( index ), _map ) );
    }
  }

  //-------------------------------------------------------------
  // Create widget for handling the width of a link
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

  //-------------------------------------------------------------
  // Called whenever the user changes the link width value
  private bool node_borderwidth_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    var borderwidth = new UndoStyleNodeBorderwidth( _affects, intval, _map );
    _curr_style.node_borderwidth = intval;
    if( _change_add ) {
      _map.undo_buffer.add_item( borderwidth );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( borderwidth );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Create the node fill UI
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

  //-------------------------------------------------------------
  // Called whenever the node fill status changes
  private void node_fill_changed() {
    if( !_ignore ) {
      bool val = _node_fill.get_active();
      _curr_style.node_fill = val;
      _map.undo_buffer.add_item( new UndoStyleNodeFill( _affects, val, _map ) );
    }
  }

  //-------------------------------------------------------------
  // Allows the user to change the node margin
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

  //-------------------------------------------------------------
  // Called whenever the node margin value is changed
  private bool node_margin_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 20 ) {
      return( false );
    }
    var margin = new UndoStyleNodeMargin( _affects, intval, _map );
    _curr_style.node_margin = intval;
    if( _change_add ) {
      _map.undo_buffer.add_item( margin );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( margin );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Allows the user to change the node padding
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

  //-------------------------------------------------------------
  // Called whenever the node margin value is changed
  private bool node_padding_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 20 ) {
      return( false );
    }
    var padding = new UndoStyleNodePadding( _affects, intval, _map );
    _curr_style.node_padding = intval;
    if( _change_add ) {
      _map.undo_buffer.add_item( padding );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( padding );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Creates the node font selector
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
      use_size = false
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
    _node_font.notify["font-desc"].connect(() => {
      var family = _node_font.font_desc.get_family();
      var size   = _node_font.font_desc.get_size();
      _curr_style.node_font = _node_font.font_desc.copy();
      _map.undo_buffer.add_item( new UndoStyleNodeFont( _affects, family, size, _map ) );
    });

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _node_font );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the UI for the node text alignment widget.
  private Box create_node_text_align_ui() {

    var lbl = new Label( _( "Text Alignment" ) ) {
      halign  = Align.START,
      hexpand = true
    };

    _node_text_align = new ModeButtons() {
      halign = Align.END,
      valign = Align.CENTER
    };
    _node_text_align.changed.connect( set_node_text_align );

    _node_text_align.add_button( "format-justify-left-symbolic",   null, _( "Left" ) );
    _node_text_align.add_button( "format-justify-center-symbolic", null, _( "Center" ) );
    _node_text_align.add_button( "format-justify-right-symbolic",  null, _( "Right" ) );

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.append( lbl );
    box.append( _node_text_align );

    return( box );

  }

  //-------------------------------------------------------------
  // Sets the node text alignment value.
  private void set_node_text_align( int index ) {
    Pango.Alignment? align = null;
    switch( index ) {
      case 0 :  align = Pango.Alignment.LEFT;    break;
      case 1 :  align = Pango.Alignment.CENTER;  break;
      case 2 :  align = Pango.Alignment.RIGHT;   break;
    }
    if( align != null ) {
      _curr_style.node_text_align = align;
      _map.undo_buffer.add_item( new UndoStyleNodeTextAlign( _affects, align, _map ) );
    }
  }

  //-------------------------------------------------------------
  // Creates the node width selector
  private Box create_node_width_ui() {

    var lbl = new Label( _( "Width" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _node_width = new SpinButton.with_range( 200, 1000, 100 ) {
      halign = Align.END,
      valign = Align.CENTER,
    };
    _node_width.value_changed.connect(() => {
      if( !_ignore ) {
        var width = (int)_node_width.get_value();
        _curr_style.node_width = width;
        _map.undo_buffer.replace_item( new UndoStyleNodeWidth( _affects, width, _map ) );
      }
    });

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _node_width );

    return( box );

  }

  //-------------------------------------------------------------
  // Create the node markup style setting
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

  //-------------------------------------------------------------
  // Called whenever the node fill status changes
  private void node_markup_changed() {
    if( !_ignore ) {
      var val = _node_markup.get_active();
      _map.undo_buffer.add_item( new UndoStyleNodeMarkup( _affects, val, _map ) );
    }
  }

  //-------------------------------------------------------------
  // Creates the connection style UI
  private Box create_connection_ui() {

    var conn_dash       = create_connection_dash_ui();
    var conn_arrow      = create_connection_arrow_ui();
    var conn_arrow_size = create_connection_arrow_size_ui();
    var conn_lwidth     = create_connection_line_width_ui();
    var conn_padding    = create_connection_padding_ui();
    var conn_font       = create_connection_font_ui();
    var conn_text_align = create_connection_text_align_ui();
    var conn_twidth     = create_connection_title_width_ui();

    var cbox = new Box( Orientation.VERTICAL, 0 ) {
      homogeneous   = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    cbox.append( conn_dash );
    cbox.append( conn_arrow );
    cbox.append( conn_arrow_size );
    cbox.append( conn_lwidth );
    cbox.append( conn_padding );
    cbox.append( conn_font );
    cbox.append( conn_text_align );
    cbox.append( conn_twidth );

    // Create expander
    _conn_exp = new Expander( "  " + _( "Connection Options" ) ) {
      expanded = _settings.get_boolean( "style-connection-options-expanded" ),
      child    = cbox
    };
    _conn_exp.add_css_class( "titled" );
    _conn_exp.activate.connect(() => {
      _settings.set_boolean( "style-connection-options-expanded", !_conn_exp.expanded );
    });

    var sep = new Separator( Orientation.HORIZONTAL );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( _conn_exp );
    box.append( sep );

    return( box );

  }

  //-------------------------------------------------------------
  // Create the connection dash widget
  private Box create_connection_dash_ui() {

    var lbl = new Label( _( "Line Dash" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    var dashes = styles.get_link_dashes();

    _conn_dash = new ImageMenu() {
      halign = Align.END
    };

    _conn_dash.changed.connect((index) => {
      _curr_style.connection_dash = dashes.index( index );
      _map.undo_buffer.add_item( new UndoStyleConnectionDash( _affects, dashes.index( index ), _map ) );
    });

    update_icons.connect(() => {
      _conn_dash.update_icons();
    });

    for( int i=0; i<dashes.length; i++ ) {
      var dash = dashes.index( i );
      _conn_dash.add_image( dash.make_icon( false ), dash.make_icon( true ) );
    }

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( _conn_dash );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the connection arrow position UI
  private Box create_connection_arrow_ui() {

    var lbl = new Label( _( "Arrows" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    string arrows[4] = {"none", "fromto", "tofrom", "both"};

    _conn_arrow = new ImageMenu() {
      halign = Align.END
    };

    _conn_arrow.changed.connect((index) => {
      _curr_style.connection_arrow = arrows[index];
      _map.undo_buffer.add_item( new UndoStyleConnectionArrow( _affects, arrows[index], _map ) );
    });

    update_icons.connect(() => {
      _conn_arrow.update_icons();
    });

    foreach (string arrow in arrows) {
      _conn_arrow.add_image( Connection.make_arrow_icon( arrow, false ), Connection.make_arrow_icon( arrow, true ) );
    }

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign      = Align.FILL,
      homogeneous = true
    };
    box.append( lbl );
    box.append( _conn_arrow );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the link arrow size UI.
  private Box create_connection_arrow_size_ui() {

    var lbl = new Label( _( "Arrow Size" ) ) {
      halign  = Align.START,
      hexpand = true
    };

    _conn_arrow_size = new Scale.with_range( Orientation.HORIZONTAL, 0, 3, 1 ) {
      halign     = Align.FILL,
      draw_value = false
    };

    _conn_arrow_size.add_mark( 0, PositionType.BOTTOM, "S" );
    _conn_arrow_size.add_mark( 1, PositionType.BOTTOM, "M" );
    _conn_arrow_size.add_mark( 2, PositionType.BOTTOM, "L" );
    _conn_arrow_size.add_mark( 3, PositionType.BOTTOM, "XL" );
    _conn_arrow_size.change_value.connect( connection_arrow_size_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      homogeneous = true
    };
    box.append( lbl );
    box.append( _conn_arrow_size );

    return( box );

  }

  //-------------------------------------------------------------
  // Called whenever the user changes the connection arrow size value
  private bool connection_arrow_size_changed( ScrollType scroll, double value ) {
    if( value > 3 ) value = 3;
    var int_value       = (int)value;
    var conn_arrow_size = new UndoStyleConnectionArrowSize( _affects, int_value, _map );
    _curr_style.connection_arrow_size = int_value;
    if( _change_add ) {
      _map.undo_buffer.add_item( conn_arrow_size );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( conn_arrow_size );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Create widget for handling the width of a connection
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

  //-------------------------------------------------------------
  // Called whenever the user changes the link width value.
  private bool connection_line_width_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 8 ) intval = 8;
    var width = new UndoStyleConnectionLineWidth( _affects, intval, _map );
    _curr_style.connection_line_width = intval;
    if( _change_add ) {
      _map.undo_buffer.add_item( width );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( width );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Allows the user to change the node padding
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

  //-------------------------------------------------------------
  // Called whenever the node margin value is changed
  private bool connection_padding_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 20 ) {
      return( false );
    }
    var padding = new UndoStyleConnectionPadding( _affects, intval, _map );
    _curr_style.connection_padding = intval;
    if( _change_add ) {
      _map.undo_buffer.add_item( padding );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( padding );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Creates the node font selector
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
      use_size = false
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
    _conn_font.notify["font-desc"].connect(() => {
      var family = _conn_font.font_desc.get_family();
      var size   = _conn_font.font_desc.get_size();
      _curr_style.connection_font = _conn_font.font_desc.copy();
      _map.undo_buffer.add_item( new UndoStyleConnectionFont( _affects, family, size, _map ) );
    });

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _conn_font );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the UI for the connection text alignment widget.
  private Box create_connection_text_align_ui() {

    var lbl = new Label( _( "Text Alignment" ) ) {
      halign  = Align.START,
      hexpand = true
    };

    _conn_text_align = new ModeButtons() {
      halign = Align.END,
      valign = Align.CENTER
    };
    _conn_text_align.changed.connect( set_connection_text_align );

    _conn_text_align.add_button( "format-justify-left-symbolic",   null, _( "Left" ) );
    _conn_text_align.add_button( "format-justify-center-symbolic", null, _( "Center" ) );
    _conn_text_align.add_button( "format-justify-right-symbolic",  null, _( "Right" ) );

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.append( lbl );
    box.append( _conn_text_align );

    return( box );

  }

  //-------------------------------------------------------------
  // Sets the connection text alignment value.
  private void set_connection_text_align( int index ) {
    Pango.Alignment? align = null;
    switch( index ) {
      case 0 :  align = Pango.Alignment.LEFT;    break;
      case 1 :  align = Pango.Alignment.CENTER;  break;
      case 2 :  align = Pango.Alignment.RIGHT;   break;
    }
    if( align != null ) {
      _curr_style.connection_text_align = align;
      _map.undo_buffer.add_item( new UndoStyleConnectionTextAlign( _affects, align, _map ) );
    }
  }

  //-------------------------------------------------------------
  // Creates the connection title width selector
  private Box create_connection_title_width_ui() {

    var lbl = new Label( _( "Title Width" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };

    _conn_twidth = new SpinButton.with_range( 100, 400, 50 ) {
      halign = Align.END,
      valign = Align.CENTER,
    };
    _conn_twidth.value_changed.connect(() => {
      if( !_ignore ) {
        var width = (int)_conn_twidth.get_value();
        _curr_style.connection_title_width = width;
        _map.undo_buffer.replace_item( new UndoStyleConnectionTitleWidth( _affects, width, _map ) );
      }
    });

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _conn_twidth );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the callout style UI
  private Box create_callout_ui() {

    var callout_font       = create_callout_font_ui();
    var callout_text_align = create_callout_text_align_ui();
    var callout_padding    = create_callout_padding_ui();
    var callout_pwidth     = create_callout_pointer_width_ui();
    var callout_plength    = create_callout_pointer_length_ui();

    var cbox = new Box( Orientation.VERTICAL, 0 ) {
      homogeneous   = true,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 10,
      margin_bottom = 10
    };
    cbox.append( callout_font );
    cbox.append( callout_text_align );
    cbox.append( callout_padding );
    cbox.append( callout_pwidth );
    cbox.append( callout_plength );

    // Create expander
    _callout_exp = new Expander( "  " + _( "Callout Options" ) ) {
      use_markup = true,
      expanded   = _settings.get_boolean( "style-callout-options-expanded" ),
      child      = cbox
    };
    _callout_exp.add_css_class( "titled" );
    _callout_exp.activate.connect(() => {
      _settings.set_boolean( "style-callout-options-expanded", !_callout_exp.expanded );
    });

    var sep = new Separator( Orientation.HORIZONTAL );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( _callout_exp );
    box.append( sep );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the callout font selector
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
      use_size = false
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
    _callout_font.notify["font-desc"].connect(() => {
      var family = _callout_font.font_desc.get_family();
      var size   = _callout_font.font_desc.get_size();
      _curr_style.callout_font = _callout_font.font_desc.copy();
      _map.add_undo( new UndoStyleCalloutFont( _affects, family, size, _map ) );
    });

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _callout_font );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the UI for the callout text alignment widget.
  private Box create_callout_text_align_ui() {

    var lbl = new Label( _( "Text Alignment" ) ) {
      halign  = Align.START,
      hexpand = true
    };

    _callout_text_align = new ModeButtons() {
      halign = Align.END,
      valign = Align.CENTER
    };
    _callout_text_align.changed.connect( set_callout_text_align );

    _callout_text_align.add_button( "format-justify-left-symbolic",   null, _( "Left" ) );
    _callout_text_align.add_button( "format-justify-center-symbolic", null, _( "Center" ) );
    _callout_text_align.add_button( "format-justify-right-symbolic",  null, _( "Right" ) );

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.append( lbl );
    box.append( _callout_text_align );

    return( box );

  }

  //-------------------------------------------------------------
  // Sets the callout text alignment value.
  private void set_callout_text_align( int index ) {
    Pango.Alignment? align = null;
    switch( index ) {
      case 0 :  align = Pango.Alignment.LEFT;    break;
      case 1 :  align = Pango.Alignment.CENTER;  break;
      case 2 :  align = Pango.Alignment.RIGHT;   break;
    }
    if( align != null ) {
      _curr_style.callout_text_align = align;
      _map.undo_buffer.add_item( new UndoStyleCalloutTextAlign( _affects, align, _map ) );
    }
  }

  //-------------------------------------------------------------
  // Allows the user to change the callout padding
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

  //-------------------------------------------------------------
  // Called whenever the callout padding value is changed
  private bool callout_padding_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 20 ) {
      return( false );
    }
    var padding = new UndoStyleCalloutPadding( _affects, intval, _map );
    _curr_style.callout_padding = intval;
    if( _change_add ) {
      _map.undo_buffer.add_item( padding );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( padding );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Allows the user to change the callout padding
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

  //-------------------------------------------------------------
  // Called whenever the callout padding value is changed
  private bool callout_pointer_width_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 30 ) {
      return( false );
    }
    var pwidth = new UndoStyleCalloutPointerWidth( _affects, intval, _map );
    _curr_style.callout_ptr_width = intval;
    if( _change_add ) {
      _map.undo_buffer.add_item( pwidth );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( pwidth );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Allows the user to change the callout padding
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

  //-------------------------------------------------------------
  // Called whenever the callout padding value is changed
  private bool callout_pointer_length_changed( ScrollType scroll, double value ) {
    var intval = (int)Math.round( value );
    if( intval > 100 ) {
      return( false );
    }
    var plength = new UndoStyleCalloutPointerLength( _affects, intval, _map );
    _curr_style.callout_ptr_length = intval;
    if( _change_add ) {
      _map.undo_buffer.add_item( plength );
      _change_add = false;
    } else {
      _map.undo_buffer.replace_item( plength );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Update style from template style.
  private void update_from_style( Style style ) {
    switch( _affects ) {
      case StyleAffects.ALL :
        var nodes = _map.get_nodes();
        var conns = _map.connections.connections;
        for( int i=0; i<nodes.length; i++ ) {
          nodes.index( i ).set_style_for_tree( style );
        }
        for( int i=0; i<conns.length; i++ ) {
          conns.index( i ).style = style;
        }
        break;
      case StyleAffects.SELECTED_NODES :
        var nodes = _map.selected.nodes();
        for( int i=0; i<nodes.length; i++ ) {
          nodes.index( i ).style = style;
        }
        break;
      case StyleAffects.SELECTED_CONNECTIONS :
        var conns = _map.selected.connections();
        for( int i=0; i<conns.length; i++ ) {
          conns.index( i ).style = style;
        }
        break;
      case StyleAffects.SELECTED_CALLOUTS :
        var callouts = _map.selected.callouts();
        for( int i=0; i<callouts.length; i++ ) {
          callouts.index( i ).style = style;
        }
        break;
    }
    update_ui_with_style( style );
    _map.queue_draw();
    _map.auto_save();
  }

  //-------------------------------------------------------------
  // Sets the affects value and save the change to the settings
  private void set_affects( StyleAffects affects ) {
    var selected         = _map.selected;
    if( _clipboard_affect != null ) {
      _paste_btn.sensitive = ((_clipboard_affect == affects) || (_clipboard_affect == StyleAffects.ALL));
    }
    _affects             = affects;
    _affects_label.label = affects.label();
    switch( _affects ) {
      case StyleAffects.ALL     :
        _curr_style            = _map.global_style;
        last_global_style      = _curr_style;
        _branch_group.visible  = true;
        _link_group.visible    = true;
        _node_group.visible    = true;
        _conn_group.visible    = true;
        _callout_group.visible = true;
        _conn_exp.expanded     = _settings.get_boolean( "style-connection-options-expanded" );
        _callout_exp.expanded  = _settings.get_boolean( "style-callout-options-expanded" ); 
        _template_btn.popover  = _win.templates.get_template_group_menu( TemplateType.STYLE_GENERAL );
        break;
      case StyleAffects.SELECTED_NODES :
        _curr_style = new Style();
        _curr_style.copy( selected.nodes().index( 0 ).style );
        _branch_group.visible  = true;
        _link_group.visible    = true;
        _node_group.visible    = true;
        _conn_group.visible    = false;
        _callout_group.visible = false;
        _template_btn.popover  = _win.templates.get_template_group_menu( TemplateType.STYLE_NODE );
        break;
      case StyleAffects.SELECTED_CONNECTIONS :
        _curr_style = new Style();
        _curr_style.copy( selected.connections().index( 0 ).style );
        _branch_group.visible  = false;
        _link_group.visible    = false;
        _node_group.visible    = false;
        _conn_group.visible    = true;
        _callout_group.visible = false;
        _conn_exp.expanded     = true;
        _template_btn.popover  = _win.templates.get_template_group_menu( TemplateType.STYLE_CONNECTION );
        break;
      case StyleAffects.SELECTED_CALLOUTS :
        _curr_style = new Style();
        _curr_style.copy( selected.callouts().index( 0 ).style );
        _branch_group.visible  = false;
        _link_group.visible    = false;
        _node_group.visible    = false;
        _conn_group.visible    = false;
        _callout_group.visible = true;
        _callout_exp.expanded  = true;
        _template_btn.popover  = _win.templates.get_template_group_menu( TemplateType.STYLE_CALLOUT );
        break;
    }
    update_ui_with_style( _curr_style );
  }

  //-------------------------------------------------------------
  // Checks the nodes in the given tree at the specified level to
  // see if there are any non-leaf nodes.
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

  //-------------------------------------------------------------
  // We need to disable the link types widget if our affected
  // nodes are leaf nodes only.
  private void update_link_types_state() {
    bool sensitive = false;
    switch( _affects ) {
      case StyleAffects.ALL :
        for( int i=0; i<_map.get_nodes().length; i++ ) {
          if( !_map.get_nodes().index( i ).is_leaf() ) {
            sensitive = true;
            break;
          }
        }
        break;
      case StyleAffects.SELECTED_NODES :
        for( int i=0; i<_map.get_selected_nodes().length; i++ ) {
          if( _map.get_selected_nodes().index( i ).children().length > 0 ) {
            sensitive = true;
            break;
          }
        }
        break;
    }
    _link_types.set_sensitive( sensitive && _map.editable );
  }

  //-------------------------------------------------------------
  // Updates the state of the link types modebutton widget with the
  // link type style information.
  private void update_link_types_with_style( Style style ) {
    update_link_types_state();
    if( style.link_type != null ) {
      var link_types = styles.get_link_types();
      for( int i=0; i<link_types.length; i++ ) {
        if( link_types.index( i ).name() == style.link_type.name() ) {
          _link_types.selected = i;
          break;
        }
      }
      _branch_radius_box.visible = (style.link_type.name() == "rounded") && _link_types.get_sensitive();
    }
  }

  //-------------------------------------------------------------
  // Updates the state of the link dashes modebutton widget with
  // the link dashes style information.
  private void update_link_dashes_with_style( Style style ) {
    if( style.link_dash != null ) {
      var link_dashes = styles.get_link_dashes();
      for( int i=0; i<link_dashes.length; i++ ) {
        if( link_dashes.index( i ).name == style.link_dash.name ) {
          _link_dash.selected = i;
          break;
        }
      }
    }
    _link_dash.editable_changed( _map.editable );
  }

  //-------------------------------------------------------------
  // Updates the state of the node borders modebutton widget with
  // the node border style information.
  private void update_node_borders_with_style( Style style ) {
    if( style.node_border != null ) {
      var node_borders = styles.get_node_borders();
      for( int i=0; i<node_borders.length; i++ ) {
        if( node_borders.index( i ).name() == style.node_border.name() ) {
          _node_borders.selected = i;
          break;
        }
      }
    }
    _node_borders.editable_changed( _map.editable );
  }

  //-------------------------------------------------------------
  // Updates the state of the node text alignment modebutton widget
  // with the node text alignment style information.
  private void update_node_text_align_with_style( Style style ) {
    if( style.node_text_align != null ) {
      switch( style.node_text_align ) {
        case Pango.Alignment.LEFT   :  _node_text_align.selected = 0;  break;
        case Pango.Alignment.CENTER :  _node_text_align.selected = 1;  break;
        case Pango.Alignment.RIGHT  :  _node_text_align.selected = 2;  break;
      }
    }
    _node_text_align.editable_changed( _map.editable );
  }

  //-------------------------------------------------------------
  // Updates the state of the connection dash modebutton widget
  // with the connection dash style information.
  private void update_conn_dashes_with_style( Style style ) {
    if( style.connection_dash != null ) {
      var link_dashes = styles.get_link_dashes();
      for( int i=0; i<link_dashes.length; i++ ) {
        if( link_dashes.index( i ).name == style.connection_dash.name ) {
          _conn_dash.selected = i;
          break;
        }
      }
    }
    _conn_dash.editable_changed( _map.editable );
  }

  //-------------------------------------------------------------
  // Updates the state of the connection arrow style dropdown
  // widget based on the connection arrow style information.
  private void update_conn_arrows_with_style( Style style ) {
    if( style.connection_arrow != null ) {
      string arrows[4] = {"none", "fromto", "tofrom", "both"};
      var i = 0;
      foreach( var arrow in arrows ) {
        if( arrow == style.connection_arrow ) {
          _conn_arrow.selected = i;
          break;
        }
        i++;
      }
    }
    _conn_arrow.editable_changed( _map.editable );
  }

  //-------------------------------------------------------------
  // Updates the state of the connection text alignment modebutton
  // widget based on the connection text alignment style information.
  private void update_conn_text_align_with_style( Style style ) {
    if( style.connection_text_align != null ) {
      switch( style.connection_text_align ) {
        case Pango.Alignment.LEFT   :  _conn_text_align.selected = 0;  break;
        case Pango.Alignment.CENTER :  _conn_text_align.selected = 1;  break;
        case Pango.Alignment.RIGHT  :  _conn_text_align.selected = 2;  break;
      }
    }
    _conn_text_align.editable_changed( _map.editable );
  }

  //-------------------------------------------------------------
  // Updates the state of the callout text alignment modebutton
  // widget based on the callout text alignment style information.
  private void update_callout_text_align_with_style( Style style ) {
    if( style.callout_text_align != null ) {
      switch( style.callout_text_align ) {
        case Pango.Alignment.LEFT   :  _callout_text_align.selected = 0;  break;
        case Pango.Alignment.CENTER :  _callout_text_align.selected = 1;  break;
        case Pango.Alignment.RIGHT  :  _callout_text_align.selected = 2;  break;
      }
    }
    _callout_text_align.editable_changed( _map.editable );
  }

  //-------------------------------------------------------------
  // Update the user interface elements to match the selected level
  private void update_ui_with_style( Style style ) {

    var branch_margin   = style.branch_margin;
    var branch_radius   = style.branch_radius;
    var link_width      = style.link_width;
    var link_arrow      = style.link_arrow;
    var link_arrow_size = style.link_arrow_size;
    var node_bw         = style.node_borderwidth;
    var node_fill       = style.node_fill;
    var node_margin     = style.node_margin;
    var node_padding    = style.node_padding;
    var node_width      = style.node_width;
    var node_markup     = style.node_markup;
    var conn_arrow_size = style.connection_arrow_size;
    var conn_line_width = style.connection_line_width;
    var conn_padding    = style.connection_padding;
    var callout_padding = style.callout_padding;
    var callout_pwidth  = style.callout_ptr_width;
    var callout_plength = style.callout_ptr_length;

    _ignore = true;

    // Nodes
    if( (_affects == StyleAffects.ALL) || (_affects == StyleAffects.SELECTED_NODES) ) {
      if( branch_margin != null ) {
        _branch_margin.set_value( (double)branch_margin );
      }
      if( branch_radius != null ) {
        _branch_radius.set_value( (double)branch_radius );
      }
      if( link_width != null ) {
        _link_width.set_value( (double)link_width );
      }
      if( link_arrow != null ) {
        _link_arrow.set_active( (bool)link_arrow );
      }
      if( link_arrow_size != null ) {
        _link_arrow_size.set_value( (double)link_arrow_size );
      }
      update_link_types_with_style( style );
      update_link_dashes_with_style( style );
      if( node_bw != null ) {
        _node_borderwidth.set_value( (double)node_bw );
      }
      if( node_fill != null ) {
        _node_fill.set_active( (bool)node_fill );
      }
      if( node_margin != null ) {
        _node_margin.set_value( (double)node_margin );
      }
      if( node_padding != null ) {
        _node_padding.set_value( (double)node_padding );
      }
      if( style.node_font != null ) {
        _node_font.set_font_features( style.node_font.to_string() );
      }
      if( node_width != null ) {
        _node_width.set_value( (float)node_width );
      }
      if( node_markup != null ) {
        _node_markup.set_active( (bool)node_markup );
      }
      update_node_borders_with_style( style );
      update_node_text_align_with_style( style );
    }

    // Connections
    if( (_affects == StyleAffects.ALL) || (_affects == StyleAffects.SELECTED_CONNECTIONS) ) {
      update_conn_dashes_with_style( style );
      update_conn_arrows_with_style( style );
      update_conn_text_align_with_style( style );
      if( conn_arrow_size != null ) {
        _conn_arrow_size.set_value( (double)conn_arrow_size );
      }
      if( conn_line_width != null ) {
        _conn_lwidth.set_value( (double)conn_line_width );
      }
      if( style.connection_font != null ) {
        _conn_font.set_font_features( style.connection_font.to_string() );
      }
      if( style.connection_title_width != null ) {
        _conn_twidth.set_value( style.connection_title_width );
      }
      if( conn_padding != null ) {
        _conn_padding.set_value( (double)conn_padding );
      }
    }

    // Callout
    if( (_affects == StyleAffects.ALL) || (_affects == StyleAffects.SELECTED_CALLOUTS) ) {
      update_callout_text_align_with_style( style );
      if( style.callout_font != null ) {
        _callout_font.set_font_features( style.callout_font.to_string() );
      }
      if( callout_padding != null ) {
        _callout_padding.set_value( (double)callout_padding );
      }
      if( callout_pwidth != null ) {
        _callout_ptr_width.set_value( (double)callout_pwidth );
      }
      if( callout_plength != null ) {
        _callout_ptr_length.set_value( (double)callout_plength );
      }
    }

    _ignore = false;

    // Handle editable changes
    _branch_margin.set_sensitive( _map.editable );
    _branch_radius.set_sensitive( _map.editable );
    _link_width.set_sensitive( _map.editable );
    _link_arrow.set_sensitive( _map.editable );
    _link_arrow_size.set_sensitive( _map.editable );
    _node_borderwidth.set_sensitive( _map.editable );
    _node_fill.set_sensitive( (style.node_border != null) && style.node_border.is_fillable() && _map.editable );
    _node_margin.set_sensitive( _map.editable );
    _node_padding.set_sensitive( _map.editable );
    _node_font.set_sensitive( _map.editable );
    _node_width.set_sensitive( _map.editable );
    _node_markup.set_sensitive( _map.editable );
    _conn_lwidth.set_sensitive( _map.editable );
    _conn_font.set_sensitive( _map.editable );
    _conn_twidth.set_sensitive( _map.editable );
    _conn_padding.set_sensitive( _map.editable );
    _callout_font.set_sensitive( _map.editable );
    _callout_padding.set_sensitive( _map.editable );
    _callout_ptr_width.set_sensitive( _map.editable );
    _callout_ptr_length.set_sensitive( _map.editable );

  }

  //-------------------------------------------------------------
  // Called whenever the current node changes
  private void handle_current_changed() {
    if( _map.get_current_node() != null ) {
      update_ui_with_style( _map.get_current_node().style );
    } else if( _map.get_current_connection() != null ) {
      update_ui_with_style( _map.get_current_connection().style );
    } else if( _map.get_current_callout() != null ) {
      update_ui_with_style( _map.get_current_callout().style );
    }
    handle_ui_changed();
  }

  //-------------------------------------------------------------
  // Called whenever the current node or connection changes
  private void handle_ui_changed() {
    var selected = _map.selected;
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

  //-------------------------------------------------------------
  // Grabbing focus on the first UI element
  public void grab_first() {
    _link_types.grab_focus();
  }

}
