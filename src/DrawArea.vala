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
using GLib;
using Gdk;
using Cairo;
using Gee;

public enum DragTypes {
  URI,
  STICKER
}

public struct SelectBox {
  double x;
  double y;
  double w;
  double h;
  bool   valid;
}

public class DrawArea : Gtk.DrawingArea {

  private const string move_cursor    = "move";
  private const string text_cursor    = "text";
  private const string pointer_cursor = "pointer";
  private const string pan_cursor     = "grabbing";

  private MindMap               _map;
  private double                _press_x;
  private double                _press_y;
  private double                _scaled_x;
  private double                _scaled_y;
  private double                _origin_x;
  private double                _origin_y;
  private double                _scale_factor;
  private double                _store_origin_x;
  private double                _store_origin_y;
  private double                _store_scale_factor;
  private bool                  _control         = false;
  private bool                  _shift           = false;
  private bool                  _alt             = false;
  private bool                  _pressed         = false;
  private int                   _press_num       = 0;
  private bool                  _press_middle    = false;
  private bool                  _resize          = false;
  private bool                  _orig_resizable  = false;
  private bool                  _motion          = false;
  private Connection?           _last_connection = null;
  private NodeSide              _orig_side       = NodeSide.LEFT;
  private Array<NodeInfo?>      _orig_info;
  private int                   _orig_width;
  private NodeMenu              _node_menu;
  private ConnectionMenu        _conn_menu;
  private ConnectionsMenu       _conns_menu;
  private NodesMenu             _nodes_menu;
  private GroupsMenu            _groups_menu;
  private CalloutMenu           _callout_menu;
  private EmptyMenu             _empty_menu;
  private TextMenu              _text_menu;
  private uint?                 _scroll_save_id = null;
  private ImageEditor           _image_editor;
  private UrlEditor             _url_editor;
  private IMContext             _im_context;
  private bool                  _debug        = true;
  private SelectBox             _select_box;
  private Tagger                _tagger;
  private TextCompletion        _completion;
  private double                _sticker_posx;
  private double                _sticker_posy;
  private uint                  _select_hover_id = 0;
  private EventControllerKey    _key_controller;
  private EventControllerScroll _scroll;
  private bool                  _create_new_from_edit;

  public MainWindow win      { private set; get; }
  public Animator   animator { set; get; }

  public MindMap map {
    get {
      return( _map );
    }
  }
  public IMContext im_context {
    get {
      return( _im_context );
    }
  }
  public double scaled_x {
    get {
      return( _scaled_x );
    }
  }
  public double scaled_y {
    get {
      return( _scaled_y );
    }
  }
  public double press_x {
    get {
      return( _press_x );
    }
  }
  public double press_y {
    get {
      return( _press_y );
    }
  }
  public double origin_x {
    set {
      _store_origin_x = _origin_x = value;
    }
    get {
      return( _origin_x );
    }
  }
  public double origin_y {
    set {
      _store_origin_y = _origin_y = value;
    }
    get {
      return( _origin_y );
    }
  }
  public double sfactor {
    set {
      _store_scale_factor = _scale_factor = value;
    }
    get {
      return( _scale_factor );
    }
  }
  public UrlEditor url_editor {
    get {
      return( _url_editor );
    }
  }
  public ImageEditor image_editor {
    get {
      return( _image_editor );
    }
  }
  public Tagger tagger {
    get {
      return( _tagger );
    }
  }
  public Connection? last_connection {
    get {
      return( _last_connection );
    }
    set {
      _last_connection = value;
    }
  }
  public Array<NodeInfo?> orig_info {
    get {
      return( _orig_info );
    }
  }

  public signal void current_changed( MindMap map );
  public signal void scale_changed( double scale );
  public signal void scroll_changed();
  public signal void show_properties( string? tab, PropertyGrab grab_type );
  public signal void hide_properties();

  /* Default constructor */
  public DrawArea( MindMap map, MainWindow w ) {

    _map = map;
    win  = w;

    /* Allocate memory for the animator */
    animator = new Animator( this );

    /* Allocate the image editor popover */
    _image_editor = new ImageEditor( this );
    _image_editor.changed.connect( _map.current_image_edited );

    /* Allocate the URL editor popover */
    _url_editor = new UrlEditor( this );

    /* Initialize the selection box */
    _select_box = {0, 0, 0, 0, false};

    /* Create the popup menus */
    _node_menu    = new NodeMenu( win.application, this );
    _conn_menu    = new ConnectionMenu( win.application, this );
    _conns_menu   = new ConnectionsMenu( win.application, this );
    _empty_menu   = new EmptyMenu( win.application, this );
    _nodes_menu   = new NodesMenu( win.application, this );
    _groups_menu  = new GroupsMenu( win.application, this );
    _callout_menu = new CalloutMenu( win.application, this );
    _text_menu    = new TextMenu( win.application, this );

    /* Create the node information array */
    _orig_info = new Array<NodeInfo?>();

    /* Create text completion */
    _completion = new TextCompletion( this );

    /* Get the value of the new node from edit */
    update_create_new_from_edit( _map.settings );
    _map.settings.changed.connect(() => {
      update_create_new_from_edit( _map.settings );
    });

    /* Add event listeners */
    this.set_draw_func( on_draw );

    var click = new GestureClick() {
      button = Gdk.BUTTON_PRIMARY
    };
    this.add_controller( click );
    click.pressed.connect((n_press, x, y) => { on_press( n_press, x, y, Gdk.BUTTON_PRIMARY ); });
    click.released.connect( on_release );

    var middle_click = new GestureClick() {
      button = Gdk.BUTTON_MIDDLE
    };
    this.add_controller( middle_click );
    middle_click.pressed.connect((n_press, x, y) => { on_press( n_press, x, y, Gdk.BUTTON_MIDDLE ); });

    var right_click = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };
    this.add_controller( right_click );
    right_click.pressed.connect( on_right_press );

    var motion = new EventControllerMotion();
    this.add_controller( motion );
    motion.motion.connect( on_motion );

    _key_controller = new EventControllerKey();
    this.add_controller( _key_controller );
    _key_controller.key_pressed.connect( on_keypress );
    _key_controller.key_released.connect( on_keyrelease );

    _scroll = new EventControllerScroll( EventControllerScrollFlags.BOTH_AXES );
    this.add_controller( _scroll );
    _scroll.scroll.connect( on_scroll );

    var file_drop = new DropTarget( typeof(File), Gdk.DragAction.COPY );
    this.add_controller( file_drop );
    file_drop.motion.connect( handle_file_drag_motion );
    file_drop.drop.connect( handle_file_drop );

    var sticker_drop = new DropTarget( typeof(Picture), Gdk.DragAction.COPY );
    this.add_controller( sticker_drop );
    sticker_drop.motion.connect( handle_sticker_drag_motion );
    sticker_drop.drop.connect( handle_sticker_drop );

    var text_drop = new DropTarget( typeof(string), Gdk.DragAction.MOVE );
    this.add_controller( text_drop );
    text_drop.motion.connect( handle_text_drag_motion );
    text_drop.drop.connect( handle_text_drop );

    /* Make sure the drawing area can receive keyboard focus */
    this.can_focus = true;
    this.focusable = true;

    /*
     Make sure that we add a CSS class name to ourselves so we can color
     our background with the theme.
    */
    get_style_context().add_class( "canvas" );

    /* Make sure that we us the ImContextSimple input method */
    _im_context = new IMMulticontext();
    _im_context.set_client_widget( this );
    _im_context.set_use_preedit( false );
    _im_context.commit.connect( handle_im_commit );
    _im_context.retrieve_surrounding.connect( handle_im_retrieve_surrounding );
    _im_context.delete_surrounding.connect( handle_im_delete_surrounding );

  }

  //-------------------------------------------------------------
  // Returns the current value of _orig_side.
  public NodeSide get_orig_side() {
    return( _orig_side );
  }

  //-------------------------------------------------------------
  // If the current selection ever changes, let the sidebar know
  // about it.
  private void selection_changed() {
    _map.update_focus_mode();
    current_changed( _map );
  }

  //-------------------------------------------------------------
  // Gets the top and bottom y position of this draw area.
  public void get_window_ys( out int top, out int bottom ) {
    var vh = get_allocated_height();
    top    = (int)origin_y;
    bottom = top + vh;
  }

  //-------------------------------------------------------------
  // Resets the cursor to the standard one.
  public void reset_cursor() {
    set_cursor( null );
  }

  //-------------------------------------------------------------
  // Sets the cursor of the drawing area to the named cursor.
  private void set_cursor_name( string name ) {
    set_cursor( new Cursor.from_name( name, null ) );
  }

  //-------------------------------------------------------------
  // Sets the current cursor to the text input cursor.
  public void set_text_cursor() {
    set_cursor_name( text_cursor );
  }

  //-------------------------------------------------------------
  // Initialize the drawing area.
  public void initialize() {

    // Initialize variables
    origin_x         = 0.0;
    origin_y         = 0.0;
    sfactor          = 1.0;
    _pressed         = false;
    _press_num       = 0;
    _motion          = false;
    _last_connection = null;

  }

  //-------------------------------------------------------------
  // Updates the IM context cursor location based on the canvas
  // text position
  public void update_im_cursor( CanvasText ct ) {
      var int_posx   = (int) (ct.posx * sfactor);
      var int_posy   = (int) (ct.posy * sfactor);
      var int_width  = (int) (ct.width * sfactor);
      var int_height = (int)  (ct.height * sfactor);
    
      Gdk.Rectangle rect = {int_posx + int_width, int_posy + int_height, 0, 0};
      _im_context.set_cursor_location( rect );
  }

  //-------------------------------------------------------------
  // Clears the current connection (if it is set) and updates the
  // UI accordingly
  public void clear_current_connection( bool signal_change ) {
    if( _map.selected.num_connections() > 0 ) {
      _map.selected.clear_connections( signal_change );
      _last_connection = null;
    }
  }

  //-------------------------------------------------------------
  // Clears the current node (if it is set) and updates the UI
  // accordingly
  private void clear_current_node( bool signal_change ) {
    if( _map.selected.num_nodes() > 0 ) {
      _map.selected.clear_nodes( signal_change );
    }
  }

  //-------------------------------------------------------------
  // Clears the current sticker (if it is set) and updates the UI
  // accordingly
  private void clear_current_sticker( bool signal_change ) {
    if( _map.selected.num_stickers() > 0 ) {
      _map.selected.clear_stickers( signal_change );
    }
  }

  //-------------------------------------------------------------
  // Clears the current group (if it is set) and updates the UI
  // accordingly
  private void clear_current_group( bool signal_change ) {
    if( _map.selected.num_groups() > 0 ) {
      _map.selected.clear_groups( signal_change );
    }
  }

  //-------------------------------------------------------------
  // Clears the current callout (if it is set) and updates the UI
  // accordingly
  private void clear_current_callout( bool signal_change ) {
    if( _map.selected.num_callouts() > 0 ) {
      _map.selected.clear_callouts( signal_change );
    }
  }

  //-------------------------------------------------------------
  // Called whenever the user clicks on a valid connection
  private bool set_current_connection_from_position( Connection conn, MapItemComponent component, double scaled_x, double scaled_y ) {

    if( _map.selected.is_current_connection( conn ) ) {
      if( conn.mode == ConnMode.EDITABLE ) {
        switch( _press_num ) {
          case 1 :
            conn.title.set_cursor_at_char( scaled_x, scaled_y, _shift );
            _im_context.reset();
            break;
          case 2 :
            conn.title.set_cursor_at_word( scaled_x, scaled_y, _shift );
            _im_context.reset();
            break;
          case 3 :
            conn.title.set_cursor_all( false );
            _im_context.reset();
            break;
        }
      } else if( _press_num == 2 ) {
        var current = _map.selected.current_connection();
        current.edit_title_begin( _map );
        _map.model.set_connection_mode( current, ConnMode.EDITABLE );
      }
      return( true );
    } else {
      if( _shift ) {
        _map.selected.add_connection( conn );
        _map.handle_connection_edit_on_creation( conn );
      } else {
        _map.set_current_connection( conn );
      }
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Called whenever the user clicks on node
  private bool set_current_node_from_position( Node node, MapItemComponent component, double scaled_x, double scaled_y ) {

    var dpress = _press_num == 2;
    var tpress = _press_num == 3;
    var tag    = FormatTag.LENGTH;
    var url    = "";
    var left   = 0.0;

    set_tooltip_markup( null );

    /* Check to see if the user clicked anywhere within the node which is itself a clickable target */
    switch( component ) {
      case MapItemComponent.TASK :
        _map.toggle_task( node );
        current_changed( _map );
        return( false );
      case MapItemComponent.NODE_LINK :
        _map.select_linked_node( node );
        return( false );
      case MapItemComponent.FOLD :
        _map.toggle_fold( node, _shift );
        current_changed( _map );
        return( false );
      case MapItemComponent.RESIZER :
        _resize         = true;
        _orig_resizable = node.image_resizable;
        _orig_width     = node.style.node_width;
        return( true );
      case MapItemComponent.TITLE :
        if( !_shift && _control && node.name.is_within_clickable( scaled_x, scaled_y, out tag, out url ) ) {
          if( tag == FormatTag.URL ) {
            Utils.open_url( url );
          }
          return( false );
        }
        break;
    }

    _orig_side = node.side;
    _orig_info.remove_range( 0, _orig_info.length );
    node.get_node_info( ref _orig_info );

    /* If the node is being edited, go handle the click */
    if( node.mode == NodeMode.EDITABLE ) {
      switch( _press_num ) {
        case 1 :
          node.name.set_cursor_at_char( scaled_x, scaled_y, _shift );
          _im_context.reset();
          break;
        case 2 :
          node.name.set_cursor_at_word( scaled_x, scaled_y, _shift );
          _im_context.reset();
          break;
        case 3 :
          node.name.set_cursor_all( false );
          _im_context.reset();
          break;
      }
      return( true );

    /*
     If the user double-clicked a node.  If an image was clicked on, edit the image;
     otherwise, set the node's mode to editable.
    */
    } else if( !_control && !_shift && (_press_num == 2) ) {
      if( component == MapItemComponent.IMAGE ) {
        _map.edit_current_image();
        return( false );
      } else {
        _map.model.set_node_mode( node, NodeMode.EDITABLE );
      }
      return( true );

    /* Otherwise, we need to adjust the selection */
    } else {

      /* The shift key has a toggling effect */
      if( _shift ) {
        if( _control ) {
          if( tpress ) {
            if( !_map.selected.remove_nodes_at_level( node ) ) {
              _map.selected.add_nodes_at_level( node );
            }
          } else if( dpress ) {
            if( !_map.selected.remove_node_tree( node ) ) {
              _map.selected.add_node_tree( node );
            }
          } else {
            if( !_map.selected.remove_child_nodes( node ) ) {
              _map.selected.add_child_nodes( node );
            }
          }
        } else {
          if( !_map.selected.remove_node( node ) ) {
            _map.selected.add_node( node );
          }
        }

      /*
       The Control key + single click will select the current node's children
       The Control key + double click will select the current node tree.
       The Control key + triple click will select all nodes at the same level.
      */
      } else if( _control ) {
        _map.selected.clear_nodes();
        if( tpress ) {
          _map.selected.add_nodes_at_level( node );
        } else if( dpress ) {
          _map.selected.add_node_tree( node );
        } else {
          _map.selected.add_child_nodes( node );
        }

      /* Otherwise, just select the current node */
      } else {
        _map.selected.set_current_node( node );
        if( node.parent != null ) {
          node.parent.set_summary_extents();
        }
      }

      if( node.parent != null ) {
        node.parent.last_selected_child = node;
      }
      if( node.is_summarized() ) {
        node.summary_node().last_selected_node = node;
      }
      return( true );
    }

  }

  //-------------------------------------------------------------
  // Handles a click on the specified sticker
  public bool set_current_sticker_from_position( Sticker sticker, double scaled_x, double scaled_y ) {

    /* If the sticker is selected, check to see if the cursor is over other parts */
    if( sticker.mode == StickerMode.SELECTED ) {
      if( sticker.is_within_resizer( scaled_x, scaled_y ) ) {
        _resize     = true;
        _orig_width = (int)sticker.width;
        return( true );
      }

    /* Otherwise, add the sticker to the selection */
    } else {
      _map.set_current_sticker( sticker );
    }

    /* Save the location of the sticker */
    _sticker_posx = sticker.posx;
    _sticker_posy = sticker.posy;

    return( true );

  }

  //-------------------------------------------------------------
  // Handles a click on the specified group
  public bool set_current_group_from_position( NodeGroup group, double scaled_x, double scaled_y ) {

    /* Select the current group */
    if( _shift ) {
      _map.selected.add_group( group );
    } else {
      _map.set_current_group( group );
    }

    return( true );

  }

  //-------------------------------------------------------------
  // Handles a click on the specified callout
  public bool set_current_callout_from_position( Callout callout, MapItemComponent component, double scaled_x, double scaled_y ) {

    var tag = FormatTag.LENGTH;
    var url = "";

    /* If the callout is being edited, go handle the click */
    switch( component ) {
      case MapItemComponent.RESIZER :
        _resize = true;
        _orig_width = (int)callout.total_width;
        return( true );
      case MapItemComponent.TITLE :
        if( !_shift && _control && callout.text.is_within_clickable( scaled_x, scaled_y, out tag, out url ) ) {
          if( tag == FormatTag.URL ) {
            Utils.open_url( url );
          }
          return( false );
        }
        break;
    }

    if( callout.mode == CalloutMode.EDITABLE ) {
      switch( _press_num ) {
        case 1 :
          callout.text.set_cursor_at_char( scaled_x, scaled_y, _shift );
          _im_context.reset();
          break;
        case 2 :
          callout.text.set_cursor_at_word( scaled_x, scaled_y, _shift );
          _im_context.reset();
          break;
        case 3 :
          callout.text.set_cursor_all( false );
          _im_context.reset();
          break;
      }
      return( true );

    /* If the user double-clicked a callout, set the callout mode to editable */
    } else if( _press_num == 2 ) {
      _map.model.set_callout_mode( callout, CalloutMode.EDITABLE );
      return( true );

    /* Otherwise, just make the callout the selected callout */
    } else {
      _map.set_current_callout( callout );
    }

    return( true );

  }

  //-------------------------------------------------------------
  // Handles a right click to deal with any selection changes.
  private void handle_right_click( double x, double y ) {
    if( _map.model.select_connection_if_unselected( x, y ) ||
        _map.model.select_node_if_unselected( x, y ) ) {
      /* Nothing else to do */
    }
  }

  //-------------------------------------------------------------
  // Sets the current node pointer to the node that is within the
  // given coordinates.  Returns true if we sucessfully set
  // current_node to a valid node and made it selected.
  private bool set_current_at_position( double scaled_x, double scaled_y ) {

    /* If we are going to pan the canvas, do it and return */
    if( _press_middle || _alt ) {
      return( true );
    }

    MapItemComponent component;
    var match_conn = _map.get_connection_at_position( scaled_x, scaled_y, out component );
    if( (match_conn != null) && component.is_connection_handle() && (match_conn.mode == ConnMode.SELECTED) ) {
      if( component == MapItemComponent.DRAG_HANDLE ) {
        _map.model.set_connection_mode( match_conn, ConnMode.ADJUSTING );
      } else {
        _last_connection = new Connection.from_connection( _map, match_conn );
        match_conn.disconnect_from_node( true );
      }
      return( true );
    }

    var current_conn = _map.selected.current_connection();
    
    if( (_map.model.attach_node == null) || (current_conn == null) || !current_conn.mode.is_connecting() ) {
      if( (match_conn != null) && (component != MapItemComponent.DRAG_HANDLE) ) {
        clear_current_node( false );
        clear_current_sticker( false );
        clear_current_group( false );
        clear_current_callout( false );
        return( set_current_connection_from_position( match_conn, component, scaled_x, scaled_y ) );
      }
      var match_node = _map.model.get_node_at_position( scaled_x, scaled_y, out component );
      if( match_node != null ) {
        clear_current_connection( false );
        clear_current_sticker( false );
        clear_current_group( false );
        clear_current_callout( false );
        return( set_current_node_from_position( match_node, component, scaled_x, scaled_y ) );
      }
      var match_callout = _map.model.get_callout_at_position( scaled_x, scaled_y, out component );
      if( match_callout != null ) {
        clear_current_node( false );
        clear_current_connection( false );
        clear_current_sticker( false );
        clear_current_group( false );
        return( set_current_callout_from_position( match_callout, component, scaled_x, scaled_y ) );
      }
      var match_sticker = _map.model.get_sticker_at_position( scaled_x, scaled_y );
      if( match_sticker != null ) {
        clear_current_node( false );
        clear_current_connection( false );
        clear_current_group( false );
        clear_current_callout( false );
        return( set_current_sticker_from_position( match_sticker, scaled_x, scaled_y ) );
      }
      var match_group = _map.model.get_group_at_position( scaled_x, scaled_y );
      if( match_group != null ) {
        clear_current_node( false );
        clear_current_connection( false );
        clear_current_sticker( false );
        clear_current_callout( false );
        return( set_current_group_from_position( match_group, scaled_x, scaled_y ) );
      }
      _select_box.x     = scaled_x;
      _select_box.y     = scaled_y;
      _select_box.valid = true;
      if( !_shift ) {
        clear_current_node( true );
      }
      clear_current_connection( true );
      clear_current_sticker( true );
      clear_current_group( true );
      clear_current_callout( true );
      if( _map.model.last_node != null ) {
        _map.selected.set_current_node( _map.model.last_node );
      }
    }

    return( true );

  }

  //-------------------------------------------------------------
  // Returns the supported scale points.
  public static double[] get_scale_marks() {
    double[] marks = {10, 25, 50, 75, 100, 150, 200, 250, 300, 350, 400};
    return( marks );
  }

  //-------------------------------------------------------------
  // Returns a properly scaled version of the given value.
  private double scale_value( double val ) {
    return( val / sfactor );
  }

  //-------------------------------------------------------------
  // Sets the scaling factor for the drawing area, causing the
  // center pixel to remain in the center and forces a redraw.
  public bool set_scaling_factor( double sf ) {
    if( sfactor != sf ) {
      int    width  = get_allocated_width()  / 2;
      int    height = get_allocated_height() / 2;
      double diff_x = (width  / sf) - (width / sfactor);
      double diff_y = (height / sf) - (height / sfactor );
      if( move_origin( diff_x, diff_y, sf ) ) {
        sfactor = sf;
        scale_changed( sfactor );
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Sets the scaling factor for the drawing area, causing the
  // pixel on defined coordinates to remain stable and forces a
  // redraw.
  //
  // coord_x = distance of zoom position from origin, in screen coordinates
  // coord_y = distance of zoom position from origin, in screen coordinates
  public bool set_scaling_factor_coord( double sf, double coord_x, double coord_y ) {
    if( sfactor != sf ) {
      double diff_x = (coord_x / sf) - (coord_x / sfactor);
      double diff_y = (coord_y / sf) - (coord_y / sfactor);
      if( move_origin( diff_x, diff_y, sf ) ) {
        sfactor = sf;
        scale_changed( sfactor );
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns the scaling factor based on the given width and height.
  private double get_scaling_factor( double width, double height ) {
    double w  = get_allocated_width() / width;
    double h  = get_allocated_height() / height;
    double sf = (w < h) ? w : h;
    return( (sf > 4) ? 4 : sf );
  }

  //-------------------------------------------------------------
  // Zooms into the image by one scale mark.  Returns true if the
  // zoom was successful; otherwise, returns false.
  public bool zoom_in() {
    // Zoom center of the screen
    int s_x = get_allocated_width() / 2;
    int s_y = get_allocated_height() / 2;

    return zoom_in_coords(s_x, s_y);
  }

  //-------------------------------------------------------------
  // Zooms in by one mark in the zoom mark list.  If we are
  // currently at the largest mark, stop zooming.
  public bool zoom_in_coords( double zoom_x, double zoom_y ) {
    double value = sfactor * 100;
    var    marks = get_scale_marks();
    double last  = marks[0];
    if( value < marks[0] ) {
      value = marks[0];
    }

    foreach (double mark in marks) {
      if( mark <= value ) {
        continue;
      }

      animator.add_scale_in_place( "zoom in place", zoom_x, zoom_y );
      if( set_scaling_factor_coord( mark / 100, zoom_x, zoom_y ) ) {
        animator.animate();
      } else {
        animator.cancel_last_add();
      }
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Zooms out of the image by one scale mark.  Returns true if
  // the zoom was successful; otherwise, returns false.
  public bool zoom_out() {
    // Zoom center of the screen
    int s_x = get_allocated_width() / 2;
    int s_y = get_allocated_height() / 2;

    return zoom_out_coords(s_x, s_y);
  }

  //-------------------------------------------------------------
  // Zooms out by one mark in the zoom mark list.  If we are
  // currently at the smallest mark, stop zooming.
  public bool zoom_out_coords( double zoom_x, double zoom_y ) {
    double value = sfactor * 100;
    var    marks = get_scale_marks();
    double last  = marks[0];
    if( value > marks[marks.length-1] ) {
      value = marks[marks.length-1];
    }

    foreach (double mark in marks) {
      if( value > mark ) {
        last = mark;
        continue;
      }

      animator.add_scale_in_place( "zoom out in place", zoom_x, zoom_y );
      if( set_scaling_factor_coord( last / 100, zoom_x, zoom_y ) ) {
        animator.animate();
      } else {
        animator.cancel_last_add();
      }
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Positions the given box in the canvas based on the provided
  // x and y positions (values between 0 and 1).
  private void position_box( double x, double y, double w, double h, double xpos, double ypos, string msg = "NONE" ) {
    double ccx = scale_value( get_allocated_width()  * xpos );
    double ccy = scale_value( get_allocated_height() * ypos );
    double ncx = x + (w * xpos);
    double ncy = y + (h * ypos);
    move_origin( (ccx - ncx), (ccy - ncy) );
  }

  //-------------------------------------------------------------
  // Returns the scaling factor required to display the currently
  // selected node.  If no node is currently selected, returns a
  // value of 0.
  public void zoom_to_selected() {
    var current = _map.selected.current_node();
    if( current == null ) return;
    animator.add_pan_scale( "zoom to selected" );
    var nb = current.tree_bbox;
    position_box( nb.x, nb.y, nb.width, nb.height, 0.5, 0.5, "zoom_to_selected" );
    if( set_scaling_factor( get_scaling_factor( nb.width, nb.height ) ) ) {
      animator.animate();
    } else {
      animator.cancel_last_add();
    }
  }

  //-------------------------------------------------------------
  // Returns the scaling factor required to display all nodes.
  public void zoom_to_fit() {

    animator.add_pan_scale( "zoom to fit" );

    /* Get the document rectangle */
    double x, y, w, h;
    _map.model.document_rectangle( out x, out y, out w, out h );

    /* Center the map and scale it to fit */
    position_box( x, y, w, h, 0.5, 0.5, "zoom_to_fit" );
    if( set_scaling_factor( get_scaling_factor( w, h ) ) ) {
      animator.animate();
    } else {
      animator.cancel_last_add();
    }

  }

  //-------------------------------------------------------------
  // Scale to actual size.
  public void zoom_actual() {

    /* Start animation */
    animator.add_pan_scale( "action_zoom_actual" );

    /* Scale to a full scale */
    if( set_scaling_factor( 1.0 ) ) {
      animator.animate();
    } else {
      animator.cancel_last_add();
    }

  }

  //-------------------------------------------------------------
  // Centers the given node within the canvas by adjusting the
  // origin.
  public void center_node( Node n ) {
    double x, y, w, h;
    n.bbox( out x, out y, out w, out h );
    animator.add_pan( "center node" );
    position_box( x, y, w, h, 0.5, 0.5, "center_node" );
    animator.animate();
  }

  //-------------------------------------------------------------
  // Centers the currently selected node.
  public void center_current_node() {
    var current = _map.selected.current_node();
    if( current != null ) {
      center_node( current );
    }
  }

  //-------------------------------------------------------------
  // Brings the given node into view in its entirety including
  // the given amount of padding.
  public void see( bool animate = true, double width_adjust = 0, double pad = 100.0 ) {

    double x, y, w, h;

    var current_conn    = _map.selected.current_connection();
    var current_node    = _map.selected.current_node();
    var current_callout = _map.selected.current_callout();
    var current_group   = _map.selected.current_group();

    if( current_conn != null ) {
      current_conn.bbox( out x, out y, out w, out h );
    } else if( current_node != null ) {
      current_node.bbox( out x, out y, out w, out h );
    } else if( current_callout != null ) {
      current_callout.bbox( out x, out y, out w, out h );
    } else if( current_group != null ) {
      current_group.nodes.index( 0 ).bbox( out x, out y, out w, out h );
    } else {
      return;
    }

    double diff_x = 0;
    double diff_y = 0;
    double sw     = scale_value( get_allocated_width() + width_adjust );
    double sh     = scale_value( get_allocated_height() );
    double sf     = get_scaling_factor( (w + (pad * 2)), (h + (pad * 2)) );

    if( (x - pad) < 0 ) {
      diff_x = 0 - (x - pad);
    } else if( (x + w) > sw ) {
      diff_x = sw - (x + w + pad);
    }

    if( (y - pad) < 0 ) {
      diff_y = 0 - (y - pad);
    } else if( (y + h) > sh ) {
      diff_y = sh - (y + h + pad);
    }

    if( (diff_x != 0) || (diff_y != 0) ) {
      if( sf >= sfactor ) {
        if( animate ) {
          animator.add_pan( "see" );
        }
        move_origin( diff_x, diff_y );
      } else {
        if( animate ) {
          animator.add_pan_scale( "see" );
        }
        sfactor = sf;
        scale_changed( sfactor );
        move_origin( diff_x, diff_y );
      }
      if( animate ) {
        animator.animate();
      } else {
        queue_draw();
      }
    }

  }

  //-------------------------------------------------------------
  // Returns true if a node is droppable at the given coordinates
  public bool text_droppable( double x, double y ) {
    Node?       node;
    Connection? conn;
    Sticker?    sticker;
    _map.model.get_droppable( scale_value( x ), scale_value( y ), out node, out conn, out sticker );
    return( node != null );
  }

  //-------------------------------------------------------------
  // Returns the origin.
  public void get_origin( out double x, out double y ) {
    x = origin_x;
    y = origin_y;
  }

  //-------------------------------------------------------------
  // Sets the origin to the given x and y coordinates.
  public void set_origin( double x, double y ) {
    move_origin( (x - origin_x), (y - origin_y) );
  }

  //-------------------------------------------------------------
  // Checks to see if the boundary of the map never goes out of
  // view.
  private bool out_of_bounds( double diff_x, double diff_y, double scale ) {

    double x, y, w, h;
    double aw = get_allocated_width()  / scale;
    double ah = get_allocated_height() / scale;
    double s  = 40 / scale;

    _map.model.document_rectangle( out x, out y, out w, out h );

    x += diff_x;
    y += diff_y;

    return( ((x + w) < s) || ((y + h) < s) || ((aw - x) < s) || ((ah - y) < s) );

  }

  //-------------------------------------------------------------
  // Adjusts the x and y origins, panning all elements by the
  // given amount.  Important Note:  When the canvas is panned to
  // the left (causing all nodes to be moved to the left, the
  // origin_x value becomes a positive number.
  public bool move_origin( double diff_x, double diff_y, double? next_scale = null ) {
    if( out_of_bounds( diff_x, diff_y, (next_scale ?? sfactor) ) ) {
      return( false );
    }
    origin_x += diff_x;
    origin_y += diff_y;
    return( true );
  }

  //-------------------------------------------------------------
  // Draw the background from the stylesheet.
  public void draw_background( Context ctx ) {
    get_style_context().render_background( ctx, 0, 0, (get_allocated_width() / _scale_factor), (get_allocated_height() / _scale_factor) );
  }

  //-------------------------------------------------------------
  // Draws the selection box, if one is set.
  public void draw_select_box( Context ctx ) {
    if( !_select_box.valid ) return;
    Utils.set_context_color_with_alpha( ctx, _map.get_theme().get_color( "nodesel_background" ), 0.1 );
    ctx.rectangle( _select_box.x, _select_box.y, _select_box.w, _select_box.h );
    ctx.fill();
  }

  //-------------------------------------------------------------
  // Draw the available nodes.
  public void on_draw( DrawingArea da, Context ctx, int width, int height ) {
    ctx.scale( sfactor, sfactor );
    draw_background( ctx );
    _map.draw_all( ctx, false, (_pressed && _motion && !_resize) );
  }

  //-------------------------------------------------------------
  // Displays the contextual menu based on what is currently
  // selected.
  private void show_contextual_menu( double x, double y ) {

    var current_node    = _map.selected.current_node();
    var current_conn    = _map.selected.current_connection();
    var current_callout = _map.selected.current_callout();

    if( current_node != null ) {
      if( current_node.mode == NodeMode.EDITABLE ) {
        _text_menu.show( x, y );
      } else {
        _node_menu.show( x, y );
      }
    } else if( _map.selected.num_nodes() > 1 ) {
      _nodes_menu.show( x, y );
    } else if( current_conn != null ) {
      if( current_conn.mode == ConnMode.EDITABLE ) {
        _text_menu.show( x, y );
      } else {
        _conn_menu.show( x, y );
      }
    } else if( _map.selected.num_connections() > 1 ) {
      _conns_menu.show( x, y );
    } else if( current_callout != null ) {
      if( current_callout.mode == CalloutMode.EDITABLE ) {
        _text_menu.show( x, y );
      } else {
        _callout_menu.show( x, y );
      }
    } else if( _map.selected.num_groups() > 0 ) {
      _groups_menu.show( x, y );
    } else {
      _empty_menu.show( x, y );
    }

  }

  //-------------------------------------------------------------
  // Handle button press event
  private void on_press( int n_press, double x, double y, int button ) {

    var scaled_x = scale_value( x );
    var scaled_y = scale_value( y );

    _press_x      = scaled_x;
    _press_y      = scaled_y;
    _press_middle = button == Gdk.BUTTON_MIDDLE;
    _press_num    = n_press;
    _pressed      = set_current_at_position( _press_x, _press_y );
    _motion       = false;

    grab_focus();
    queue_draw();

  }

  //-------------------------------------------------------------
  // Handle a right-click to display the contextual menu.
  private void on_right_press( int n_press, double x, double y ) {

    var scaled_x = scale_value( x );
    var scaled_y = scale_value( y );

    handle_right_click( scaled_x, scaled_y );
    show_contextual_menu( scaled_x, scaled_y );

  }

  //-------------------------------------------------------------
  // Handle mouse motion.
  private void on_motion( double x, double y ) {

    /* Clear the hover */
    if( _select_hover_id > 0 ) {
      Source.remove( _select_hover_id );
      _select_hover_id = 0;
    }

    /* If we have an attachable summary node, clear it */
    _map.model.set_attach_summary( null );

    /* If the node is attached, clear it */
    _map.model.set_attach_node( null );

    var last_x = _scaled_x;
    var last_y = _scaled_y;
    _scaled_x = scale_value( x );
    _scaled_y = scale_value( y );

    var current_node    = _map.get_current_node();
    var current_conn    = _map.get_current_connection();
    var current_sticker = _map.get_current_sticker();
    var current_callout = _map.get_current_callout();
    var current_group   = _map.get_current_group();

    /* If the mouse button is current pressed, handle it */
    if( _pressed ) {

      /* If we are holding the middle mouse button while moving, pan the canvas */
      if( _press_middle || _alt ) {
        double diff_x = _scaled_x - last_x;
        double diff_y = _scaled_y - last_y;
        move_origin( diff_x, diff_y );
        queue_draw();
        _map.auto_save();
        return;
      }
  
      /* If we are dealing with a connection, update it based on its mode */
      if( current_conn != null ) {
        MapItemComponent component;
        switch( current_conn.mode ) {
          case ConnMode.ADJUSTING :
            current_conn.move_drag_handle( _scaled_x, _scaled_y );
            queue_draw();
            break;
          case ConnMode.CONNECTING :
          case ConnMode.LINKING    :
            update_connection( x, y );
            var match = _map.model.get_node_at_position( _scaled_x, _scaled_y, out component );
            if( match != null ) {
              _map.model.set_attach_node( match );
            }
            break;
        }

      /* If we are dealing with a node, handle it based on its mode */
      } else if( (current_node != null) && !_select_box.valid ) {
        double diffx = _scaled_x - _press_x;
        double diffy = _scaled_y - _press_y;
        if( current_node.mode == NodeMode.CURRENT ) {
          if( _resize ) {
            current_node.image_resizable = _control ? !_orig_resizable : _orig_resizable;
            current_node.resize( diffx );
            _map.auto_save();
          } else {
            var attach_summary = _map.attachable_summary_node( _scaled_x, _scaled_y );
            if( attach_summary != null ) {
              _map.model.set_attach_summary( attach_summary );
            }
            var attach_node = _map.model.attachable_node( _scaled_x, _scaled_y );
            if( attach_node != null ) {
              _map.model.set_attach_node( attach_node );
            }
            var summarized_moved = current_node.is_summarized() && (current_node.summary_node().summarized_count() > 1);
            if( summarized_moved && current_node.side.vertical() ) {
              current_node.set_posx_only( (current_node.posx - origin_x) + diffx );
            } else {
              current_node.posx += diffx;
            }
            if( summarized_moved && current_node.side.horizontal() ) {
              current_node.set_posy_only( (current_node.posy - origin_y) + diffy );
            } else {
              current_node.posy += diffy;
            }
            current_node.layout.set_side( current_node );
          }
        } else {
          switch( _press_num ) {
            case 1 :  current_node.name.set_cursor_at_char( _scaled_x, _scaled_y, true );  break;
            case 2 :  current_node.name.set_cursor_at_word( _scaled_x, _scaled_y, true );  break;
          }
        }
        queue_draw();

      /* If we are dealing with a sticker, handle it */
      } else if( current_sticker != null ) {
        double diffx = _scaled_x - _press_x;
        double diffy = _scaled_y - _press_y;
        if( _resize ) {
          current_sticker.resize( diffx );
        } else {
          current_sticker.posx += diffx;
          current_sticker.posy += diffy;
        }
        queue_draw();
        _map.auto_save();

      /* If we are dealing with a callout, handle it */
      } else if( current_callout != null ) {
        double diffx = _scaled_x - _press_x;
        if( _resize ) {
          current_callout.resize( diffx );
          queue_draw();
          _map.auto_save();
        }

      /* Otherwise, we are drawing a selection rectangle */
      } else if( current_group == null ) {
        _select_box.w = (_scaled_x - _select_box.x);
        _select_box.h = (_scaled_y - _select_box.y);
        _map.select_nodes_within_box( _select_box, _shift );
        queue_draw();
      }

      if( !_motion && !_resize && (current_node != null) && (current_node.mode != NodeMode.EDITABLE) && current_node.is_within_node( _scaled_x, _scaled_y ) ) {
        if( current_node.is_summarized() && (current_node.summary_node().summarized_count() > 1) ) {
          current_node.set_alpha_only( 0.3 );
        } else {
          current_node.alpha = 0.3;
        }
      }
      _press_x = _scaled_x;
      _press_y = _scaled_y;
      _motion  = true;

    // If we are not dragging, check to see what item the mouse is hovering over
    } else {

      MapItemComponent component;
      var tag = FormatTag.LENGTH;
      var url = "";
      if( current_sticker != null ) {
        if( current_sticker.is_within_resizer( _scaled_x, _scaled_y ) ) {
          set_cursor_name( "ew-resize" );
          return;
        }
      }
      if( current_callout != null ) {
        if( current_callout.is_within_resizer( _scaled_x, _scaled_y ) ) {
          set_cursor_name( "ew-resize" );
          return;
        }
      }
      if( current_conn != null )  {
        if( (current_conn.mode == ConnMode.CONNECTING) || (current_conn.mode == ConnMode.LINKING) ) {
          update_connection( x, y );
        }
        if( current_conn.within_drag_handle( _scaled_x, _scaled_y ) ||
            current_conn.within_from_handle( _scaled_x, _scaled_y ) ||
            current_conn.within_to_handle( _scaled_x, _scaled_y ) ) {
          set_cursor_name( move_cursor );
          return;
        } else if( current_conn.within_note( _scaled_x, _scaled_y ) ) {
          set_tooltip_markup( Utils.prepare_note_markup( current_conn.note ) );
          return;
        } else {
          var match_conn = _map.get_connection_at_position( _scaled_x, _scaled_y, out component );
          if( (match_conn != null) && select_connection_on_hover( match_conn, _shift ) ) {
            return;
          }
        }
      } else {
        var match_conn = _map.get_connection_at_position( _scaled_x, _scaled_y, out component );
        if( match_conn != null ) {
          if( component == MapItemComponent.NOTE ) {
            set_tooltip_markup( Utils.prepare_note_markup( match_conn.note ) );
            return;
          } else if( select_connection_on_hover( match_conn, _shift ) ) {
            return;
          }
        }
      }
      var match_node = _map.model.get_node_at_position( _scaled_x, _scaled_y, out component );
      if( match_node != null ) {
        _map.update_last_match( match_node );
        if( (current_conn != null) && ((current_conn.mode == ConnMode.CONNECTING) || (current_conn.mode == ConnMode.LINKING)) ) {
          _map.model.set_attach_node( match_node );
        } else if( component == MapItemComponent.TASK ) {
          set_cursor_name( pointer_cursor );
          set_tooltip_markup( _( "%0.3g%% complete" ).printf( match_node.task_completion_percentage() ) );
        } else if( component == MapItemComponent.NOTE ) {
          set_tooltip_markup( Utils.prepare_note_markup( match_node.note ) );
        } else if( component == MapItemComponent.FOLD ) {
          set_cursor_name( pointer_cursor );
          if( match_node.folded ) {
            set_tooltip_markup( prepare_folded_count_markup( match_node ) );
          }
        } else if( component == MapItemComponent.NODE_LINK ) {
          set_cursor_name( pointer_cursor );
          set_tooltip_markup( Utils.prepare_note_markup( match_node.linked_node.get_tooltip( _map ) ) );
        } else if( component == MapItemComponent.RESIZER ) {
          set_cursor_name( "ew-resize" );
          if( match_node.image == null ) {
            set_tooltip_markup( _( "Drag to resize node" ) );
          } else {
            set_tooltip_markup( _( "Drag to resize node and image.\nControl-drag to resize only node." ) );
          }
        } else if( _control && match_node.name.is_within_clickable( _scaled_x, _scaled_y, out tag, out url ) ) {
          if( tag == FormatTag.URL ) {
            set_cursor_name( pointer_cursor );
            set_tooltip_markup( url );
          }
        } else if( match_node.mode == NodeMode.EDITABLE ) {
          set_cursor_name( text_cursor );
          set_tooltip_markup( null );
        } else {
          if( !match_node.folded ) {
            match_node.show_fold = true;
            queue_draw();
          }
          reset_cursor();
          set_tooltip_markup( null );
          select_node_on_hover( match_node, _shift );
        }
        return;
      }
      var callout = _map.model.get_callout_at_position( _scaled_x, _scaled_y, out component );
      if( callout != null ) {
        if( _control && callout.text.is_within_clickable( _scaled_x, _scaled_y, out tag, out url ) ) {
          if( tag == FormatTag.URL ) {
            set_cursor_name( pointer_cursor );
            set_tooltip_markup( url );
          }
        } else if( callout.mode == CalloutMode.EDITABLE ) {
          set_cursor_name( text_cursor );
          set_tooltip_markup( null );
        } else {
          reset_cursor();
          set_tooltip_markup( null );
        }
        return;
      }

      _map.update_last_match( null );
      reset_cursor();
      set_tooltip_markup( null );
      select_sticker_group_on_hover( _shift );

    }

  }

  //-------------------------------------------------------------
  // Selects the given node on hover, if enabled.
  private bool select_node_on_hover( Node node, bool shift ) {
    if( _map.settings.get_boolean( "select-on-hover" ) ) {
      var timeout = _map.settings.get_int( "select-on-hover-timeout" );
      _select_hover_id = Timeout.add( timeout, () => {
        _select_hover_id = 0;
        if( !shift || (_map.selected.num_nodes() == 0) ) {
          _map.selected.set_current_node( node );
        } else {
          _map.selected.add_node( node );
        }
        queue_draw();
        return( false );
      });
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Selects the given connection on hover, if enabled.
  private bool select_connection_on_hover( Connection conn, bool shift ) {
    if( _map.settings.get_boolean( "select-on-hover" ) ) {
      var timeout = _map.settings.get_int( "select-on-hover-timeout" );
      _select_hover_id = Timeout.add( timeout, () => {
        _select_hover_id = 0;
        if( !shift || (_map.selected.num_connections() == 0) ) {
          _map.selected.set_current_connection( conn );
        } else {
          _map.selected.add_connection( conn );
        }
        queue_draw();
        return( false );
      });
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Selects the current sticker/group on hover.
  private bool select_sticker_group_on_hover( bool shift ) {
    if( _map.settings.get_boolean( "select-on-hover" ) ) {
      var timeout = _map.settings.get_int( "select-on-hover-timeout" );
      var sticker = _map.model.get_sticker_at_position( _scaled_x, _scaled_y );
      if( sticker != null ) {
        _select_hover_id = Timeout.add( timeout, () => {
          _select_hover_id = 0;
          if( !shift || (_map.selected.num_stickers() == 0) ) {
            _map.selected.set_current_sticker( sticker );
          } else {
            _map.selected.add_sticker( sticker );
          }
          queue_draw();
          return( false );
        });
        return( true );
      }
      var group = _map.model.get_group_at_position( _scaled_x, _scaled_y );
      if( group != null ) {
        _select_hover_id = Timeout.add( timeout, () => {
          _select_hover_id = 0;
          if( !shift || (_map.selected.num_groups() == 0) ) {
            _map.selected.set_current_group( group );
          } else {
            _map.selected.add_group( group );
          }
          queue_draw();
          return( false );
        });
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Prepare the given folded count for use in a markup tooltip.
  private string prepare_folded_count_markup( Node node ) {
    var tooltip = "";
    tooltip += _( "Children: %u\n" ).printf( node.children().length );
    tooltip += _( "Total: %d" ).printf( node.descendant_count() );
    return( tooltip );
  }

  //-------------------------------------------------------------
  // Handle button release event.
  private void on_release( int n_press, double x, double y ) {

    var current_node    = _map.selected.current_node();
    var current_conn    = _map.selected.current_connection();
    var current_sticker = _map.selected.current_sticker();
    var current_callout = _map.selected.current_callout();

    _pressed = false;

    if( _select_box.valid ) {
      _select_box = {0, 0, 0, 0, false};
      queue_draw();
    }

    /* Return the cursor to the default cursor */
    if( _motion ) {
      reset_cursor();
    }

    /* If we were resizing a node, end the resize */
    if( _resize ) {
      _resize = false;
      if( current_sticker != null ) {
        _map.add_undo( new UndoStickerResize( current_sticker, _orig_width ) );
      } else if( current_node != null ) {
        _map.add_undo( new UndoNodeResize( current_node, _orig_width, _orig_resizable ) );
        current_node.image_resizable = _orig_resizable;
      } else if( current_callout != null ) {
        _map.add_undo( new UndoCalloutResize( current_callout, _orig_width ) );
      }
      _map.auto_save();
      return;
    }

    /* If a connection is selected, deal with the possibilities */
    if( current_conn != null ) {

      /* If the connection end is released on an attachable node, attach the connection to the node */
      if( _map.model.attach_node != null ) {
        if( current_conn.mode == ConnMode.LINKING ) {
          _map.end_link( _map.model.attach_node );
        } else {
          _map.end_connection( _map.model.attach_node );
          if( _last_connection != null ) {
            _map.add_undo( new UndoConnectionChange( _( "connection endpoint change" ), _last_connection, current_conn ) );
          }
        }
        _last_connection = null;

      /* If we were dragging the connection midpoint, change the connection mode to SELECTED */
      } else if( current_conn.mode == ConnMode.ADJUSTING ) {
        _map.add_undo( new UndoConnectionChange( _( "connection drag" ), _last_connection, current_conn ) );
        _map.selected.set_current_connection( current_conn );
        _map.auto_save();

      /* If we were dragging a connection end and failed to attach it to a node, return the connection to where it was prior to the drag */
      } else if( _last_connection != null ) {
        current_conn.copy( _map, _last_connection );
        _last_connection = null;
      }

      queue_draw();

    /* If a node is selected, deal with the possibilities */
    } else if( current_node != null ) {

      if( current_node.mode == NodeMode.CURRENT ) {

        /* If we are hovering over an attach node, perform the attachment */
        if( _map.model.attach_node != null ) {
          _map.attach_current_node();

        /* If we are not in motion, set the cursor */
        } else if( !_motion ) {
          current_node.name.set_cursor_all( false );
          current_node.name.move_cursor_to_end();

        /* If we are not a root node or a summary node, move the node into the appropriate position */
        } else if( current_node.parent != null ) {
          var orig_index   = current_node.index();
          var orig_summary = current_node.summary_node();
          animator.add_nodes( _map.get_nodes(), "move to position" );
          if( current_node.parent != null ) {
            current_node.parent.clear_summary_extents();
          }
          if( current_node.is_summary() ) {
            (current_node as SummaryNode).nodes_changed( 1, 1 );
          } else {
            current_node.parent.move_to_position( current_node, _orig_side, scale_value( x ), scale_value( y ) );
          }
          if( !current_node.is_summarized() && (_map.attach_summary != null) ) {
            _map.attach_summary.add_node( current_node );
          } else if( current_node.is_summarized() && (current_node.summary_node().summarized_count() > 1) && (_map.attach_summary == null) ) {
            current_node.summary_node().remove_node( current_node );
          } else if( current_node.is_summarized() ) {
            current_node.summary_node().node_moved( current_node );
          }
          _map.add_undo( new UndoNodeMove( current_node, _orig_side, orig_index, orig_summary ) );
          animator.animate();

          /* Clear the attachable summary indicator */
          _map.model.set_attach_summary( null );

        /* Otherwise, redraw everything after the move */
        } else {
          queue_draw();
        }

      }

    /* If a sticker is selected, deal with the possiblities */
    } else if( current_sticker != null ) {
      if( current_sticker.mode == StickerMode.SELECTED ) {
        _map.add_undo( new UndoStickerMove( current_sticker, _sticker_posx, _sticker_posy ) );
      }
    }

    /* If motion is set, clear it and clear the alpha */
    if( _motion ) {
      if( current_node != null ) {
        current_node.alpha = 1.0;
      }
      _motion = false;
    }

  }

  //-------------------------------------------------------------
  // Called whenever the backspace character is entered in the
  // drawing area.
  private void handle_backspace() {
    if( _map.is_connection_editable() ) {
      _map.selected.current_connection().title.backspace( _map.undo_text );
      queue_draw();
      _map.auto_save();
    } else if( _map.is_connection_selected() ) {
      _map.model.delete_connection();
    } else if( _map.selected.num_connections() > 0 ) {
      _map.model.delete_connections();
    } else if( _map.is_node_editable() ) {
      _map.selected.current_node().name.backspace( _map.undo_text );
      queue_draw();
      _map.auto_save();
    } else if( _map.is_node_selected() ) {
      Node? next;
      var   current = _map.selected.current_node();
      if( ((next = _map.model.sibling_node( 1 )) == null) && ((next = _map.model.sibling_node( -1 )) == null) && current.is_root() ) {
        _map.model.delete_node();
      } else {
        if( next == null ) {
          next = current.parent;
        }
        _map.model.delete_node();
        if( _map.select_node( next ) ) {
          queue_draw();
        }
      }
    } else if( _map.selected.num_nodes() > 0 ) {
      _map.model.delete_nodes();
    } else if( _map.is_sticker_selected() ) {
      _map.model.remove_sticker();
    } else if( _map.selected.num_groups() > 0 ) {
      _map.model.remove_groups();
    } else if( _map.is_callout_editable() ) {
      _map.selected.current_callout().text.backspace( _map.undo_text );
      queue_draw();
      _map.auto_save();
    } else if( _map.is_callout_selected() ) {
      _map.model.remove_callout();
    }
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-Backspace keyboard
  // shortcut when editing nodes/connections.
  private void handle_control_backspace() {
    if( _map.is_connection_editable() ) {
      _map.selected.current_connection().title.backspace_word( _map.undo_text );
      current_changed( _map );
      queue_draw();
    } else if( _map.is_node_editable() ) {
      _map.selected.current_node().name.backspace_word( _map.undo_text );
      current_changed( _map );
      queue_draw();
    } else if( _map.is_callout_editable() ) {
      _map.selected.current_callout().text.backspace_word( _map.undo_text );
      current_changed( _map );
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the delete character is entered in the
  // drawing area.
  private void handle_delete() {
    if( _map.is_connection_editable() ) {
      _map.selected.current_connection().title.delete( _map.undo_text );
      queue_draw();
      _map.auto_save();
    } else if( _map.is_connection_selected() ) {
      _map.model.delete_connection();
    } else if( _map.selected.num_connections() > 0 ) {
      _map.model.delete_connections();
    } else if( _map.is_node_editable() ) {
      _map.selected.current_node().name.delete( _map.undo_text );
      queue_draw();
      _map.auto_save();
    } else if( _map.is_node_selected() ) {
      _map.model.delete_node();
    } else if( _map.selected.num_nodes() > 0 ) {
      _map.model.delete_nodes();
    } else if( _map.is_sticker_selected() ) {
      _map.model.remove_sticker();
    } else if( _map.selected.num_groups() > 0 ) {
      _map.model.remove_groups();
    } else if( _map.is_callout_editable() ) {
      _map.get_current_callout().text.delete( _map.undo_text );
      queue_draw();
      _map.auto_save();
    } else if( _map.is_callout_selected() ) {
      _map.model.remove_callout();
    }
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-Delete keyboard
  // shortcut when editing nodes/connections.
  private void handle_control_delete() {
    if( _map.is_connection_editable() ) {
      _map.get_current_connection().title.delete_word( _map.undo_text );
      current_changed( _map );
      queue_draw();
    } else if( _map.is_node_editable() ) {
      _map.get_current_node().name.delete_word( _map.undo_text );
      current_changed( _map );
      queue_draw();
    } else if( _map.is_callout_editable() ) {
      _map.get_current_callout().text.delete_word( _map.undo_text );
      current_changed( _map );
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the escape character is entered in the
  // drawing area.
  private void handle_escape() {
    if( _map.is_connection_editable() ) {
      if( _completion.shown ) {
        _completion.hide();
      } else {
        var current = _map.selected.current_connection();
        _im_context.reset();
        current.edit_title_end();
        _map.model.set_connection_mode( current, ConnMode.SELECTED );
        current_changed( _map );
        queue_draw();
        _map.auto_save();
      }
    } else if( _map.is_node_editable() ) {
      if( _completion.shown ) {
        _completion.hide();
      } else {
        var current = _map.selected.current_node();
        _im_context.reset();
        _map.model.set_node_mode( current, NodeMode.CURRENT );
        current_changed( _map );
        queue_draw();
        _map.auto_save();
      }
    } else if( _map.is_callout_editable() ) {
      if( _completion.shown ) {
        _completion.hide();
      } else {
        var current = _map.selected.current_callout();
        _im_context.reset();
        _map.model.set_callout_mode( current, CalloutMode.SELECTED );
        current_changed( _map );
        queue_draw();
        _map.auto_save();
      }
    } else if( _map.is_connection_connecting() ) {
      var current = _map.selected.current_connection();
      _map.get_connections().remove_connection( current, true );
      _map.selected.remove_connection( current );
      _map.model.set_attach_node( null );
      _map.selected.set_current_node( _map.model.last_node );
      _last_connection = null;
      queue_draw();
    } else if( _map.is_node_selected() ) {
      hide_properties();
    } else if( _map.is_callout_selected() ) {
      hide_properties();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the return character is entered in the
  // drawing area.
  private void handle_return( bool shift ) {
    if( _map.is_connection_editable() ) {
      if( _completion.shown ) {
        _completion.select();
        queue_draw();
      } else {
        var current = _map.selected.current_connection();
        current.edit_title_end();
        _map.model.set_connection_mode( current, ConnMode.SELECTED );
        _map.auto_save();
        current_changed( _map );
        queue_draw();
      }
    } else if( _map.is_node_editable() ) {
      if( _completion.shown ) {
        _completion.select();
        queue_draw();
      } else {
        var current = _map.selected.current_node();
        _map.model.set_node_mode( current, NodeMode.CURRENT );
        if( _create_new_from_edit ) {
          if( !current.is_root() ) {
            _map.model.add_sibling_node( shift );
          } else {
            _map.model.add_root_node();
          }
        } else {
          _map.auto_save();
          current_changed( _map );
          queue_draw();
        }
      }
    } else if( _map.is_callout_editable() ) {
      if( _completion.shown ) {
        _completion.select();
        queue_draw();
      } else {
        var current = _map.selected.current_callout();
        _map.model.set_callout_mode( current, CalloutMode.SELECTED );
        current_changed( _map );
        queue_draw();
      }
    } else if( _map.is_connection_connecting() && (_map.model.attach_node != null) ) {
      _map.end_connection( _map.model.attach_node );
    } else if( _map.is_node_selected() ) {
      if( !_map.selected.current_node().is_root() ) {
        _map.model.add_sibling_node( shift );
      } else if( shift ) {
        _map.model.add_connected_node();
      } else {
        _map.model.add_root_node();
      }
    } else if( _map.selected.num_nodes() == 0 ) {
      _map.model.add_root_node();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the user hits a Control-Return key.  Causes
  // a newline to be inserted.
  private void handle_control_return() {
    if( _map.is_connection_editable() ) {
      _map.selected.current_connection().title.insert( "\n", _map.undo_text );
      current_changed( _map );
      queue_draw();
    } else if( _map.is_node_editable() ) {
      _map.selected.current_node().name.insert( "\n", _map.undo_text );
      see();
      current_changed( _map );
      queue_draw();
    } else if( _map.is_callout_editable() ) {
      _map.selected.current_callout().text.insert( "\n", _map.undo_text );
      current_changed( _map );
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the tab character is entered in the drawing
  // area.
  private void handle_tab( bool shift ) {
    if( _map.is_node_editable() ) {
      if( _completion.shown ) {
        _completion.select();
      } else {
        var current = _map.selected.current_node();
        _map.model.set_node_mode( current, NodeMode.CURRENT );
        if( _create_new_from_edit ) {
          // if( shift ) {
          //   add_summary_node_from_current();
          // } else {
            _map.model.add_child_node();
          // }
        } else {
          current_changed( _map );
          queue_draw();
        }
      }
    } else if( _map.is_node_selected() ) {
      // if( shift ) {
      //   add_summary_node_from_current();
      // } else {
        _map.model.add_child_node();
      // }
    } else if( _map.selected.num_nodes() > 1 ) {
      // add_summary_node_from_selected();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the Control-Tab key combo is entered.  Causes
  // a tab character to be inserted into the title.
  private void handle_control_tab() {
    if( _map.is_node_editable() ) {
      _map.selected.current_node().name.insert( "\t", _map.undo_text );
      see();
      current_changed( _map );
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the right key is entered in the drawing area.
  private void handle_right( bool shift, bool alt ) {
    if( _map.is_connection_editable() ) {
      if( shift ) {
        _map.get_current_connection().title.selection_by_char( 1 );
      } else {
        _map.get_current_connection().title.move_cursor( 1 );
      }
      queue_draw();
    } else if( _map.is_node_editable() ) {
      if( shift ) {
        _map.get_current_node().name.selection_by_char( 1 );
      } else {
        _map.get_current_node().name.move_cursor( 1 );
      }
      queue_draw();
    } else if( _map.is_callout_editable() ) {
      if( shift ) {
        _map.get_current_callout().text.selection_by_char( 1 );
      } else {
        _map.get_current_callout().text.move_cursor( 1 );
      }
      queue_draw();
    } else if( _map.is_connection_connecting() && (_map.model.attach_node != null) ) {
      _map.model.update_connection_by_node( _map.model.get_node_right( _map.model.attach_node ) );
    } else if( _map.is_connection_selected() ) {
      _map.select_connection( 1 );
    } else if( _map.is_node_selected() ) {
      var current    = _map.selected.current_node();
      var right_node = _map.model.get_node_right( current );
      if( alt ) {
        if( current.swap_with_sibling( right_node ) ||
            current.make_parent_sibling( right_node ) ||
            current.make_children_siblings( right_node ) ) {
          queue_draw();
          _map.auto_save();
        }
      } else if( _map.select_node( right_node ) ) {
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Called whenever the Control-right key combo is entered.
  // Moves the cursor one word to the right.
  private void handle_control_right( bool shift ) {
    if( _map.is_connection_editable() ) {
      if( shift ) {
        _map.selected.current_connection().title.selection_by_word( 1 );
      } else {
        _map.selected.current_connection().title.move_cursor_by_word( 1 );
      }
      queue_draw();
    } else if( _map.is_node_editable() ) {
      if( shift ) {
        _map.selected.current_node().name.selection_by_word( 1 );
      } else {
        _map.selected.current_node().name.move_cursor_by_word( 1 );
      }
      queue_draw();
    } else if( _map.is_callout_editable() ) {
      if( shift ) {
        _map.selected.current_callout().text.selection_by_word( 1 );
      } else {
        _map.selected.current_callout().text.move_cursor_by_word( 1 );
      }
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the left key is entered in the drawing area.
  private void handle_left( bool shift, bool alt ) {
    if( _map.is_connection_editable() ) {
      if( shift ) {
        _map.selected.current_connection().title.selection_by_char( -1 );
      } else {
        _map.selected.current_connection().title.move_cursor( -1 );
      }
      queue_draw();
    } else if( _map.is_node_editable() ) {
      if( shift ) {
        _map.selected.current_node().name.selection_by_char( -1 );
      } else {
        _map.selected.current_node().name.move_cursor( -1 );
      }
      queue_draw();
    } else if( _map.is_callout_editable() ) {
      if( shift ) {
        _map.selected.current_callout().text.selection_by_char( -1 );
      } else {
        _map.selected.current_callout().text.move_cursor( -1 );
      }
      queue_draw();
    } else if( _map.is_connection_connecting() && (_map.model.attach_node != null) ) {
      _map.model.update_connection_by_node( _map.model.get_node_left( _map.model.attach_node ) );
    } else if( _map.is_connection_selected() ) {
      _map.select_connection( -1 );
    } else if( _map.is_node_selected() ) {
      var current   = _map.selected.current_node();
      var left_node = _map.model.get_node_left( current );
      if( alt ) {
        if( current.swap_with_sibling( left_node ) ||
            current.make_parent_sibling( left_node ) ||
            current.make_children_siblings( left_node ) ) {
          queue_draw();
          _map.auto_save();
        }
      } else if( _map.select_node( left_node ) ) {
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // If Control is used, jumps the cursor to the end of the
  // previous word.  If Control-Shift is used, adds the previous
  // word to the selection.
  private void handle_control_left( bool shift ) {
    if( _map.is_connection_editable() ) {
      if( shift ) {
        _map.selected.current_connection().title.selection_by_word( -1 );
      } else {
        _map.selected.current_connection().title.move_cursor_by_word( -1 );
      }
      queue_draw();
    } else if( _map.is_node_editable() ) {
      if( shift ) {
        _map.selected.current_node().name.selection_by_word( -1 );
      } else {
        _map.selected.current_node().name.move_cursor_by_word( -1 );
      }
      queue_draw();
    } else if( _map.is_callout_editable() ) {
      if( shift ) {
        _map.selected.current_callout().text.selection_by_word( -1 );
      } else {
        _map.selected.current_callout().text.move_cursor_by_word( -1 );
      }
    }
  }

  //-------------------------------------------------------------
  // Handles the emoji insertion process for the given text item
  private void insert_emoji( CanvasText text ) {
    int x, ytop, ybot;
    text.get_cursor_pos( out x, out ytop, out ybot );
    Gdk.Rectangle rect = {x, (ytop + ((ybot - ytop) / 2)), 1, 1};
    var emoji = new EmojiChooser() {
      pointing_to = rect
    };
    emoji.set_parent( this );
    emoji.popup();
    emoji.emoji_picked.connect((txt) => {
      text.insert( txt, _map.undo_text );
      grab_focus();
      queue_draw();
    });
  }

  //-------------------------------------------------------------
  // Called whenever the period key is entered with the control
  // key.
  public void handle_control_period() {
    if( _map.is_node_editable() ) {
      insert_emoji( _map.selected.current_node().name );
    } else if( _map.is_connection_editable() ) {
      insert_emoji( _map.selected.current_connection().title );
    } else if( _map.is_callout_editable() ) {
      insert_emoji( _map.selected.current_callout().text );
    }
  }

  //-------------------------------------------------------------
  // Displays the quick entry UI in insertion mode.
  public void handle_control_E() {
    var quick_entry = new QuickEntry( _map, false, _map.settings );
    quick_entry.preload( "- " );
  }

  //-------------------------------------------------------------
  // Creates a link from the selected text within the currently
  // editable node or connection.
  private void handle_control_k( bool shift ) {
    CanvasText? ct = null;
    if( _map.is_node_editable() ) {
      ct = _map.get_current_node().name;
    } else if( _map.is_callout_editable() ) {
      ct = _map.get_current_callout().text;
    }
    if( ct != null ) {
      if( shift ) {
        url_editor.remove_url();
      } else if( _map.model.add_link_possible( ct ) ) {
        url_editor.add_url();
      }
    }
  }

  //-------------------------------------------------------------
  // Displays the quick entry UI in replacement mode.
  public void handle_control_R() {
    var quick_entry = new QuickEntry( _map, true, _map.settings );
    var export      = (ExportText)win.exports.get_by_name( "text" );
    quick_entry.preload( export.export_node( _map, _map.selected.current_node(), "" ) );
  }

  //-------------------------------------------------------------
  // Closes the current tab.
  private void handle_control_w() {
    win.close_current_tab();
  }

  //-------------------------------------------------------------
  // Handles Control-home key in edit mode for canvas text.
  private void edit_control_home( CanvasText ct, bool shift ) {
    if( shift ) {
      ct.selection_to_start( true );
    } else {
      ct.move_cursor_to_start();
    }
    _im_context.reset();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Called whenever the Control+home key is entered in the
  // drawing area.
  private void handle_control_home( bool shift ) {
    if( _map.is_connection_editable() ) {
      edit_control_home( _map.selected.current_connection().title, shift );
    } else if( _map.is_node_editable() ) {
      edit_control_home( _map.selected.current_node().name, shift );
    } else if( _map.is_callout_editable() ) {
      edit_control_home( _map.selected.current_callout().text, shift );
    }
  }

  //-------------------------------------------------------------
  // Handles home key in edit mode for canvas text.
  private void edit_home( CanvasText ct, bool shift ) {
    if( shift ) {
      ct.selection_to_start_of_line( true );
    } else {
      ct.move_cursor_to_start_of_line();
    }
    _im_context.reset();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Called whenever the home key is entered in the drawing area.
  private void handle_home( bool shift ) {
    if( _map.is_connection_editable() ) {
      edit_home( _map.selected.current_connection().title, shift );
    } else if( _map.is_node_editable() ) {
      edit_home( _map.selected.current_node().name, shift );
    } else if( _map.is_callout_editable() ) {
      edit_home( _map.selected.current_callout().text, shift );
    }
  }

  //-------------------------------------------------------------
  // Handles Control-end key in edit mode for canvas text.
  private void edit_control_end( CanvasText ct, bool shift ) {
    if( shift ) {
      ct.selection_to_end( true );
    } else {
      ct.move_cursor_to_end();
    }
    _im_context.reset();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Called whenever the Control+end key is entered in the drawing
  // area.
  private void handle_control_end( bool shift ) {
    if( _map.is_connection_editable() ) {
      edit_control_end( _map.selected.current_connection().title, shift );
    } else if( _map.is_node_editable() ) {
      edit_control_end( _map.selected.current_node().name, shift );
    } else if( _map.is_callout_editable() ) {
      edit_control_end( _map.selected.current_callout().text, shift );
    }
  }

  //-------------------------------------------------------------
  // Handles End key in edit mode for canvas text.
  private void edit_end( CanvasText ct, bool shift ) {
    if( shift ) {
      ct.selection_to_end_of_line( true );
    } else {
      ct.move_cursor_to_end_of_line();
    }
    _im_context.reset();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Called whenever the end key is entered in the drawing area.
  private void handle_end( bool shift ) {
    if( _map.is_connection_editable() ) {
      edit_end( _map.selected.current_connection().title, shift );
    } else if( _map.is_node_editable() ) {
      edit_end( _map.selected.current_node().name, shift );
    } else if( _map.is_callout_editable() ) {
      edit_end( _map.selected.current_callout().text, shift );
    }
  }

  //-------------------------------------------------------------
  // Handles Up key in edit mode for canvas text.
  private void edit_up( CanvasText ct, bool shift ) {
    if( _completion.shown ) {
      _completion.up();
    } else if( shift ) {
      ct.selection_vertically( -1 );
    } else {
      ct.move_cursor_vertically( -1 );
    }
    _im_context.reset();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Called whenever the up key is entered in the drawing area.
  private void handle_up( bool shift, bool alt ) {
    if( _map.is_connection_editable() ) {
      edit_up( _map.selected.current_connection().title, shift );
    } else if( _map.is_node_editable() ) {
      edit_up( _map.selected.current_node().name, shift );
    } else if( _map.is_callout_editable() ) {
      edit_up( _map.selected.current_callout().text, shift );
    } else if( _map.is_connection_connecting() && (_map.model.attach_node != null) ) {
      _map.model.update_connection_by_node( _map.model.get_node_up( _map.model.attach_node ) );
    } else if( _map.is_node_selected() ) {
      var current = _map.selected.current_node();
      var up_node = _map.model.get_node_up( current );
      if( alt ) {
        if( current.swap_with_sibling( up_node ) ||
            current.make_parent_sibling( up_node ) ||
            current.make_children_siblings( up_node ) ) {
          queue_draw();
          _map.auto_save();
        }
      } else if( _map.select_node( up_node ) ) {
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Handles an up key when text is being edited.
  private void edit_control_up( CanvasText ct, bool shift ) {
    if( shift ) {
      ct.selection_to_start( false );
    } else {
      ct.move_cursor_to_start();
    }
    _im_context.reset();
    queue_draw();
  }

  //-------------------------------------------------------------
  // If the Control key is used, jumps the cursor to the beginning
  // of the text.  If Control-Shift is used, selects everything
  // from the beginnning of the string to the cursor position.
  private void handle_control_up( bool shift ) {
    if( _map.is_connection_editable() ) {
      edit_control_up( _map.selected.current_connection().title, shift );
    } else if( _map.is_node_editable() ) {
      edit_control_up( _map.selected.current_node().name, shift );
    } else if( _map.is_callout_editable() ) {
      edit_control_up( _map.selected.current_callout().text, shift );
    }
  }

  //-------------------------------------------------------------
  // Handles the Down key in edit mode for canvas text.
  private void edit_down( CanvasText ct, bool shift ) {
    if( _completion.shown ) {
      _completion.down();
    } else if( shift ) {
      ct.selection_vertically( 1 );
    } else {
      ct.move_cursor_vertically( 1 );
    }
    _im_context.reset();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Called whenever the down key is entered in the drawing area.
  private void handle_down( bool shift, bool alt ) {
    if( _map.is_connection_editable() ) {
      edit_down( _map.selected.current_connection().title, shift );
    } else if( _map.is_node_editable() ) {
      edit_down( _map.selected.current_node().name, shift );
    } else if( _map.is_callout_editable() ) {
      edit_down( _map.selected.current_callout().text, shift );
    } else if( _map.is_connection_connecting() && (_map.model.attach_node != null) ) {
      _map.model.update_connection_by_node( _map.model.get_node_down( _map.model.attach_node ) );
    } else if( _map.is_node_selected() ) {
      var current   = _map.selected.current_node();
      var down_node = _map.model.get_node_down( current );
      if( alt ) {
        if( current.swap_with_sibling( down_node ) ||
            current.make_parent_sibling( down_node ) ||
            current.make_children_siblings( down_node ) ) {
          queue_draw();
          _map.auto_save();
        }
      } else if( _map.select_node( down_node ) ) {
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Handles Control-Down key in edit mode for canvas text.
  private void edit_control_down( CanvasText ct, bool shift ) {
    if( shift ) {
      ct.selection_to_end( false );
    } else {
      ct.move_cursor_to_end();
    }
    _im_context.reset();
    queue_draw();
  }

  //-------------------------------------------------------------
  // If the Control key is used, jumps the cursor to the end of
  // the text.  If Control-Shift is used, selects all text from
  // the current cursor position to the end of the string.
  private void handle_control_down( bool shift ) {
    if( _map.is_connection_editable() ) {
      edit_control_down( _map.selected.current_connection().title, shift );
    } else if( _map.is_node_editable() ) {
      edit_control_down( _map.selected.current_node().name, shift );
    } else if( _map.is_callout_editable() ) {
      edit_control_down( _map.selected.current_callout().text, shift );
    }
  }

  //-------------------------------------------------------------
  // Called whenever the page up key is entered in the drawing area.
  private void handle_pageup() {
    if( _map.is_connection_connecting() && (_map.model.attach_node != null) ) {
      _map.model.update_connection_by_node( _map.model.get_node_pageup( _map.model.attach_node ) );
    } else if( _map.is_node_selected() ) {
      if( _map.select_node( _map.model.get_node_pageup( _map.get_current_node() ) ) ) {
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Called whenever the page down key is entered in the drawing
  // area.
  private void handle_pagedn() {
    if( _map.is_connection_connecting() && (_map.model.attach_node != null) ) {
      _map.model.update_connection_by_node( _map.model.get_node_pagedn( _map.model.attach_node ) );
    } else if( _map.is_node_selected() ) {
      if( _map.select_node( _map.model.get_node_pagedn( _map.get_current_node() ) ) ) {
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Handle input method.
  private void handle_im_commit( string str ) {
    insert_text( str );
  }

  //-------------------------------------------------------------
  // Inserts text.
  private bool insert_text( string str ) {
    if( !str.get_char( 0 ).isprint() ) return( false );
    if( _map.is_connection_editable() ) {
      _map.selected.current_connection().title.insert( str, _map.undo_text );
      queue_draw();
    } else if( _map.is_node_editable() ) {
      _map.selected.current_node().name.insert( str, _map.undo_text );
      see();
      queue_draw();
    } else if( _map.is_callout_editable() ) {
      _map.selected.current_callout().text.insert( str, _map.undo_text );
      queue_draw();
    } else {
      return( false );
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Helper class for the handle_im_retrieve_surrounding method.
  private void retrieve_surrounding_in_text( CanvasText ct ) {
    int    cursor, selstart, selend;
    string text = ct.text.text;
    ct.get_cursor_info( out cursor, out selstart, out selend );
    _im_context.set_surrounding( text, text.length, text.index_of_nth_char( cursor ) );
  }

  //-------------------------------------------------------------
  // Called in IMContext callback of the same name.
  private bool handle_im_retrieve_surrounding() {
    if( _map.is_node_editable() ) {
      retrieve_surrounding_in_text( _map.selected.current_node().name );
      return( true );
    } else if( _map.is_connection_editable() ) {
      retrieve_surrounding_in_text( _map.selected.current_connection().title );
      return( true );
    } else if( _map.is_callout_editable() ) {
      retrieve_surrounding_in_text( _map.selected.current_callout().text );
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Helper class for the handle_im_delete_surrounding method.
  private void delete_surrounding_in_text( CanvasText ct, int offset, int chars ) {
    int cursor, selstart, selend;
    ct.get_cursor_info( out cursor, out selstart, out selend );
    var startpos = cursor - offset;
    var endpos   = startpos + chars;
    ct.delete_range( startpos, endpos, _map.undo_text );
  }

  //-------------------------------------------------------------
  // Called in IMContext callback of the same name.
  private bool handle_im_delete_surrounding( int offset, int nchars ) {
    if( _map.is_node_editable() ) {
      delete_surrounding_in_text( _map.selected.current_node().name, offset, nchars );
      return( true );
    } else if( _map.is_connection_editable() ) {
      delete_surrounding_in_text( _map.selected.current_connection().title, offset, nchars );
      return( true );
    } else if( _map.is_callout_editable() ) {
      delete_surrounding_in_text( _map.selected.current_callout().text, offset, nchars );
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if the following key was found to be pressed
  // (regardless of keyboard layout).
  private bool has_key( uint[] kvs, uint key ) {
    foreach( uint kv in kvs ) {
      if( kv == key ) return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Handle a key event
  private bool on_keypress( uint keyval, uint keycode, ModifierType state ) {

    /* If we have the mouse pressed, ignore keypresses */
    if( _pressed ) return( false );

    /* Make sure that we flush all animations if the user starts a keypress */
    animator.flush();

    // Handle Control, Shift or Alt keyvals
    switch( keyval ) {
      case Gdk.Key.Control_L :
      case Gdk.Key.Control_R :
        _control = true;
        handle_control( true );
        break;
      case Gdk.Key.Shift_L :
      case Gdk.Key.Shift_R :
        _shift = true;
        break;
      case Gdk.Key.Alt_L :
      case Gdk.Key.Alt_R :
        _alt = true;
        break;
    }

    /* Figure out which modifiers were used */
    var control         = (bool)(state & ModifierType.CONTROL_MASK);
    var shift           = (bool)(state & ModifierType.SHIFT_MASK);
    var alt             = (bool)(state & ModifierType.ALT_MASK);
    var nomod           = !(control || shift || alt);
    var current_node    = _map.selected.current_node();
    var current_conn    = _map.selected.current_connection();
    var current_callout = _map.selected.current_callout();
    var current_group   = _map.selected.current_group();
    KeymapKey[] ks      = {};
    uint[] kvs          = {};

    Display.get_default().map_keycode( keycode, out ks, out kvs );

    /* If there is a current node or connection selected, operate on it */
    if( (current_node != null) || (current_conn != null) || (current_callout != null) || (current_group != null) ) {
      if( control ) {
        if( !shift && has_key( kvs, Key.c ) )           { _map.model.do_copy(); }
        else if( !shift && has_key( kvs, Key.x ) )      { _map.model.do_cut(); }
        else if( !shift && has_key( kvs, Key.v ) )      { do_paste( false ); }
        else if(  shift && has_key( kvs, Key.v ) )      { do_paste( true ); }
        else if( has_key( kvs, Key.Return ) )           { handle_control_return(); }
        else if( has_key( kvs, Key.BackSpace ) )        { handle_control_backspace(); }
        else if( has_key( kvs, Key.Delete ) )           { handle_control_delete(); }
        else if( has_key( kvs, Key.Tab ) )              { handle_control_tab(); }
        else if( has_key( kvs, Key.Right ) )            { handle_control_right( shift ); }
        else if( has_key( kvs, Key.Left ) )             { handle_control_left( shift ); }
        else if( has_key( kvs, Key.Up ) )               { handle_control_up( shift ); }
        else if( has_key( kvs, Key.Down ) )             { handle_control_down( shift ); }
        else if( has_key( kvs, Key.Home ) )             { handle_control_home( shift ); }
        else if( has_key( kvs, Key.End ) )              { handle_control_end( shift ); }
        else if( !shift && has_key( kvs, Key.a ) )      { _map.select_all(); }
        else if(  shift && has_key( kvs, Key.a ) )      { _map.deselect_all(); }
        else if( !shift && has_key( kvs, Key.period ) ) { handle_control_period(); }
        else if(  shift && has_key( kvs, Key.e ) )      { handle_control_E(); }
        else if( !shift && has_key( kvs, Key.k ) )      { handle_control_k( false ); }
        else if(  shift && has_key( kvs, Key.k ) )      { handle_control_k( true ); }
        else if(  shift && has_key( kvs, Key.r ) )      { handle_control_R(); }
        else if( !shift && has_key( kvs, Key.w ) )      { handle_control_w(); }
        else if( !shift && has_key( kvs, Key.y ) )      { do_paste_node_link(); }
        else return( false );
      } else if( nomod || shift || alt) {
        if( has_key( kvs, Key.BackSpace ) )      { handle_backspace(); }
        else if( has_key( kvs, Key.Delete ) )    { handle_delete(); }
        else if( has_key( kvs, Key.Escape ) )    { handle_escape(); }
        else if( has_key( kvs, Key.Return ) )    { handle_return( shift ); }
        else if( has_key( kvs, Key.Tab ) )       { handle_tab( shift ); }
        else if( has_key( kvs, Key.Right ) )     { handle_right( shift, alt ); }
        else if( has_key( kvs, Key.Left ) )      { handle_left( shift, alt ); }
        else if( has_key( kvs, Key.Home ) )      { handle_home( shift ); }
        else if( has_key( kvs, Key.End ) )       { handle_end( shift ); }
        else if( has_key( kvs, Key.Up ) )        { handle_up( shift, alt ); }
        else if( has_key( kvs, Key.Down ) )      { handle_down( shift, alt ); }
        else if( has_key( kvs, Key.Page_Up ) )   { handle_pageup(); }
        else if( has_key( kvs, Key.Page_Down ) ) { handle_pagedn(); }
        else if( has_key( kvs, Key.Control_L ) ) { handle_control( true ); }
        else if( has_key( kvs, Key.Control_R ) ) { handle_control( true ); }
        else if( has_key( kvs, Key.F10 ) )       { if( shift ) show_contextual_menu( _scaled_x, _scaled_y ); }
        else if( has_key( kvs, Key.Menu ) )      { show_contextual_menu( _scaled_x, _scaled_y ); }
        else {
          if( (current_node != null) && (current_node.mode != NodeMode.EDITABLE) ) {
            return( handle_node_keypress( shift, kvs ) );
          } else if( (current_conn != null) && (current_conn.mode != ConnMode.EDITABLE) ) {
            return( handle_connection_keypress( shift, kvs ) );
          } else if( (current_callout != null) && (current_callout.mode != CalloutMode.EDITABLE) ) {
            return( handle_callout_keypress( shift, kvs ) );
          } else if( current_group != null ) {
            return( handle_group_keypress( shift, kvs ) );
          } else {
            _im_context.filter_keypress( _key_controller.get_current_event() );
            return( false );
          }
        }
      }

    /* If there is no current node, allow some of the keyboard shortcuts */
    } else if( control ) {
      if( shift && has_key( kvs, Key.e ) )       { handle_control_E(); }
      else if( !shift && has_key( kvs, Key.c ) ) { _map.model.do_copy(); }
      else if( !shift && has_key( kvs, Key.x ) ) { _map.model.do_cut(); }
      else if( !shift && has_key( kvs, Key.v ) ) { do_paste( false ); }
      else return( false );

    } else if( nomod || shift ) {
      if( !shift && has_key( kvs, Key.minus ) )             { if( _map.model.nodes_alignable() ) NodeAlign.align_top( _map, _map.selected.nodes() ); }
      else if( !shift && has_key( kvs, Key.equal ) )        { if( _map.model.nodes_alignable() ) NodeAlign.align_vcenter( _map, _map.selected.nodes() ); }
      else if(  shift && has_key( kvs, Key.z ) )            { zoom_in(); }
      else if( !shift && has_key( kvs, Key.bracketleft ) )  { if( _map.model.nodes_alignable() ) NodeAlign.align_left( _map, _map.selected.nodes() ); }
      else if( !shift && has_key( kvs, Key.bracketright ) ) { if( _map.model.nodes_alignable() ) NodeAlign.align_right( _map, _map.selected.nodes() ); }
      else if(  shift && has_key( kvs, Key.underscore ) )   { if( _map.model.nodes_alignable() ) NodeAlign.align_bottom( _map, _map.selected.nodes() ); }
      else if( !shift && has_key( kvs, Key.a ) )            { _map.select_parent_nodes(); }
      else if( !shift && has_key( kvs, Key.d ) )            { _map.select_child_nodes(); }
      else if( !shift && has_key( kvs, Key.f ) )            { _map.model.toggle_folds( false ); }
      else if(  shift && has_key( kvs, Key.f ) )            { _map.model.toggle_folds( true ); }
      else if( !shift && has_key( kvs, Key.g ) )            { _map.model.add_group(); }
      else if(  shift && has_key( kvs, Key.l ) )            { _nodes_menu.action_change_link_colors(); }
      else if( !shift && has_key( kvs, Key.m ) )            { _map.select_root_node(); }
      else if( !shift && has_key( kvs, Key.r ) )            { if( _map.undo_buffer.redoable() ) _map.undo_buffer.redo(); }
      else if( !shift && has_key( kvs, Key.t ) )            { _map.model.change_selected_tasks(); }
      else if( !shift && has_key( kvs, Key.u ) )            { if( _map.undo_buffer.undoable() ) _map.undo_buffer.undo(); }
      else if( !shift && has_key( kvs, Key.z ) )            { zoom_out(); }
      else if(  shift && has_key( kvs, Key.bar ) )          { if( _map.model.nodes_alignable() ) NodeAlign.align_hcenter( _map, _map.selected.nodes() ); }
      else if(  shift && has_key( kvs, Key.numbersign ) )   { _map.model.toggle_sequence(); }
      else if( has_key( kvs, Key.BackSpace ) )              { handle_backspace(); }
      else if( has_key( kvs, Key.Delete ) )                 { handle_delete(); }
      else if( has_key( kvs, Key.Return ) )                 { handle_return( shift ); }
      else if( has_key( kvs, Key.Control_L ) )              { handle_control( true ); }
      else if( has_key( kvs, Key.Control_R ) )              { handle_control( true ); }
      else if( has_key( kvs, Key.F10 ) )                    { if( shift ) show_contextual_menu( _scaled_x, _scaled_y ); }
      else if( has_key( kvs, Key.Menu ) )                   { show_contextual_menu( _scaled_x, _scaled_y ); }
      else if( !shift && has_key( kvs, Key.x ) )            { _map.model.create_connection(); }
      else if( !shift && has_key( kvs, Key.y ) )            { _map.model.toggle_links(); }
      else return( false );
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Handles any filtered keypresses that occur when a group is
  // selected.
  private bool handle_group_keypress( bool shift, uint[] kvs ) {
    var current = _map.selected.current_group();
    if( shift && has_key( kvs, Key.e ) )       { show_properties( "current", PropertyGrab.NOTE ); }
    else if(  shift && has_key( kvs, Key.z ) ) { zoom_in(); }
    else if( !shift && has_key( kvs, Key.i ) ) { show_properties( "current", PropertyGrab.FIRST ); }
    else if( !shift && has_key( kvs, Key.r ) ) { if( _map.undo_buffer.redoable() ) _map.undo_buffer.redo(); }
    else if( !shift && has_key( kvs, Key.u ) ) { if( _map.undo_buffer.undoable() ) _map.undo_buffer.undo(); }
    else if( !shift && has_key( kvs, Key.z ) ) { zoom_out(); }
    else return( false );
    return( true );
  }

  //-------------------------------------------------------------
  // Handles any filtered keypresses that occur when a callout is
  // selected.
  private bool handle_callout_keypress( bool shift, uint[] kvs ) {
    var current = _map.selected.current_callout();
    if( shift && has_key( kvs, Key.e ) ) { show_properties( "current", PropertyGrab.NOTE ); }
    else if(  shift && has_key( kvs, Key.o ) ) { _map.select_callout_node(); }
    else if(  shift && has_key( kvs, Key.z ) ) { zoom_in(); }
    else if( !shift && has_key( kvs, Key.e ) ) { _map.model.set_callout_mode( current, CalloutMode.EDITABLE );  queue_draw(); }
    else if( !shift && has_key( kvs, Key.i ) ) { show_properties( "current", PropertyGrab.FIRST ); }
    else if( !shift && has_key( kvs, Key.r ) ) { if( _map.undo_buffer.redoable() ) _map.undo_buffer.redo(); }
    else if( !shift && has_key( kvs, Key.u ) ) { if( _map.undo_buffer.undoable() ) _map.undo_buffer.undo(); }
    else if( !shift && has_key( kvs, Key.z ) ) { zoom_out(); }
    else return( false );
    return( true );
  }

  //-------------------------------------------------------------
  // Handles any filtered keypresses that occur when a connection
  // is selected.
  private bool handle_connection_keypress( bool shift, uint[] kvs ) {
    var current = _map.selected.current_connection();
    if( shift && has_key( kvs, Key.e ) )      { show_properties( "current", PropertyGrab.NOTE ); }
    else if(  shift && has_key( kvs, Key.z ) ) { zoom_in(); }
    else if( !shift && has_key( kvs, Key.e ) ) {
      current.edit_title_begin( _map );
      _map.model.set_connection_mode( current, ConnMode.EDITABLE );
      queue_draw();
    }
    else if( !shift && has_key( kvs, Key.f ) ) { _map.select_connection_node( true ); }
    else if( !shift && has_key( kvs, Key.i ) ) { show_properties( "current", PropertyGrab.FIRST ); }
    else if( !shift && has_key( kvs, Key.n ) ) { _map.select_connection( 1 ); }
    else if( !shift && has_key( kvs, Key.p ) ) { _map.select_connection( -1 ); }
    else if( !shift && has_key( kvs, Key.r ) ) { if( _map.undo_buffer.redoable() ) _map.undo_buffer.redo(); }
    else if( !shift && has_key( kvs, Key.s ) ) { see(); }
    else if( !shift && has_key( kvs, Key.t ) ) { _map.select_connection_node( false ); }
    else if( !shift && has_key( kvs, Key.u ) ) { if( _map.undo_buffer.undoable() ) _map.undo_buffer.undo(); }
    else if( !shift && has_key( kvs, Key.z ) ) { zoom_out(); }
    else return( false );
    return( true );
  }

  //-------------------------------------------------------------
  // Handles keypresses when a single node is currenly selected.
  private bool handle_node_keypress( bool shift, uint[] kvs ) {
    var current = _map.selected.current_node();
    if( shift && has_key( kvs, Key.numbersign ) ) { _map.model.toggle_sequence(); }
    else if(  shift && has_key( kvs, Key.c ) )    { center_current_node(); }
    else if(  shift && has_key( kvs, Key.d ) )    { _map.select_node_tree(); }
    else if(  shift && has_key( kvs, Key.e ) )    { show_properties( "current", PropertyGrab.NOTE ); }
    else if(  shift && has_key( kvs, Key.f ) )    { _map.model.toggle_fold( current, true ); }
    else if(  shift && has_key( kvs, Key.i ) )    { _map.model.add_current_image(); }
    else if(  shift && has_key( kvs, Key.l ) )    { _node_menu.action_change_link_color(); }
    else if(  shift && has_key( kvs, Key.o ) )    { _map.select_callout(); }
    else if(  shift && has_key( kvs, Key.s ) )    { _map.model.sort_alphabetically(); }
    else if(  shift && has_key( kvs, Key.x ) )    { _map.select_attached_connection(); }
    else if(  shift && has_key( kvs, Key.y ) )    { _map.select_linked_node(); }
    else if(  shift && has_key( kvs, Key.z ) )    { zoom_in(); }
    else if( !shift && has_key( kvs, Key.a ) )    { _map.select_parent_nodes(); }
    else if( !shift && has_key( kvs, Key.c ) )    { _map.select_child_node(); }
    else if( !shift && has_key( kvs, Key.d ) )    { _map.select_child_nodes(); }
    else if( !shift && has_key( kvs, Key.e ) )    {
      _map.model.set_node_mode( current, NodeMode.EDITABLE );
      queue_draw();
    }
    else if( !shift && has_key( kvs, Key.f ) )    { _map.model.toggle_fold( current, false ); }
    else if( !shift && has_key( kvs, Key.g ) )    { _map.model.add_group(); }
    else if( !shift && has_key( kvs, Key.h ) )    { handle_left( false, false ); }
    else if( !shift && has_key( kvs, Key.i ) )    { show_properties( "current", PropertyGrab.FIRST ); }
    else if( !shift && has_key( kvs, Key.j ) )    { handle_down( false, false ); }
    else if( !shift && has_key( kvs, Key.k ) )    { handle_up( false, false ); }
    else if( !shift && has_key( kvs, Key.l ) )    { handle_right( false, false ); }
    else if( !shift && has_key( kvs, Key.m ) )    { _map.select_root_node(); }
    else if( !shift && has_key( kvs, Key.n ) )    { _map.select_sibling_node( 1 ); }
    else if( !shift && has_key( kvs, Key.o ) )    { _map.model.add_callout(); }
    else if( !shift && has_key( kvs, Key.p ) )    { _map.select_sibling_node( -1 ); }
    else if( !shift && has_key( kvs, Key.r ) )    { if( _map.undo_buffer.redoable() ) _map.undo_buffer.redo(); }
    else if( !shift && has_key( kvs, Key.s ) )    { see(); }
    else if( !shift && has_key( kvs, Key.t ) )    {
      if( current.task_enabled() ) {
        if( current.task_done() ) {
          _map.model.change_current_task( false, false );
        } else {
          _map.model.change_current_task( true, true );
        }
      } else {
        _map.model.change_current_task( true, false );
      }
    }
    else if( !shift && has_key( kvs, Key.u ) )    { if( _map.undo_buffer.undoable() ) _map.undo_buffer.undo(); }
    else if( !shift && has_key( kvs, Key.x ) )    { _map.model.start_connection( true, false ); }
    else if( !shift && has_key( kvs, Key.y ) )    { _map.model.toggle_links(); }
    else if( !shift && has_key( kvs, Key.z ) )    { zoom_out(); }
    else return( false );
    return( true );
  }

  //-------------------------------------------------------------
  // Handles a key release event.
  private void on_keyrelease( uint keyval, uint keycode, ModifierType state ) {
    switch( keyval ) {
      case Gdk.Key.Control_L :
      case Gdk.Key.Control_R :
        _control = false;
        handle_control( false );
        break;
      case Gdk.Key.Shift_L :
      case Gdk.Key.Shift_R :
        _shift = false;
        break;
      case Gdk.Key.Alt_L :
      case Gdk.Key.Alt_R :
        _alt = false;
        break;
    }
  }

  //-------------------------------------------------------------
  // Handles a key press/release of the control key.  Checks to
  // see if the current cursor is over a URL.  If it is, sets the
  // cursor appropriately.
  private void handle_control( bool pressed ) {
    var tag = FormatTag.LENGTH;
    var url = "";
    MapItemComponent component;
    var match = _map.model.get_node_at_position( _scaled_x, _scaled_y, out component );
    if( (match != null) && match.name.is_within_clickable( _scaled_x, _scaled_y, out tag, out url ) ) {
      if( tag == FormatTag.URL ) {
        if( pressed ) {
          set_cursor_name( pointer_cursor );
          set_tooltip_markup( url );
        } else {
          reset_cursor();
          set_tooltip_markup( null );
        }
      }
      return;
    }
    var callout = _map.model.get_callout_at_position( _scaled_x, _scaled_y, out component );
    if( (callout != null) && callout.text.is_within_clickable( _scaled_x, _scaled_y, out tag, out url ) ) {
      if( tag == FormatTag.URL ) {
        if( pressed ) {
          set_cursor_name( pointer_cursor );
          set_tooltip_markup( url );
        } else {
          reset_cursor();
          set_tooltip_markup( null );
        }
      }
    }
  }
  
  //-------------------------------------------------------------
  // Returns true if we can perform a node paste operation.
  private bool node_pasteable() {
    return( MinderClipboard.node_pasteable() );
  }

  //-------------------------------------------------------------
  // Pastes the contents of the clipboard into the current node.
  public void do_paste( bool shift ) {
    MinderClipboard.paste( _map, shift );
  }

  //-------------------------------------------------------------
  // Paste the current node as a node link in the current node.
  public void do_paste_node_link() {
    if( node_pasteable() ) {
      MinderClipboard.paste_node_link( _map );
    }
  }

  //-------------------------------------------------------------
  // Called whenever the user scrolls on the canvas.  We will
  // adjust the origin to give the canvas the appearance of
  // scrolling.
  private bool on_scroll( double delta_x, double delta_y ) {
    
    // Swap the deltas if the SHIFT key is held down
    if( _shift && !_control ) {
      double tmp = delta_x;
      delta_x = delta_y;
      delta_y = tmp;
    } else if( _control ) {
      double x, y;
      var e = _scroll.get_current_event();
      e.get_position( out x, out y );
      if( delta_y < 0 ) {
        zoom_in_coords( x, y );
      } else if( delta_y > 0 ) {
        zoom_out_coords( x, y );
      }
      return( false );
    }

    // Adjust the origin and redraw
    move_origin( ((0 - delta_x) * 120), ((0 - delta_y) * 120) );
    queue_draw();

    /* Scroll save */
    scroll_save();

    return( false );

  }

  //-------------------------------------------------------------
  // Perform a scroll save.
  public void scroll_save() {
    if( _scroll_save_id != null ) {
      Source.remove( _scroll_save_id );
    }
    _scroll_save_id = Timeout.add( 200, do_scroll_save );
  }

  //-------------------------------------------------------------
  // Allows the document to have its origin data saved to the tab
  // state document.
  private bool do_scroll_save() {
    _scroll_save_id = null;
    scroll_changed();
    return( false );
  }

  //-------------------------------------------------------------
  // Handle any drag operations involving text.
  private Gdk.DragAction handle_text_drag_motion( double x, double y ) {

    Node       attach_node;
    Connection attach_conn;
    Sticker    attach_sticker;

    var scaled_x = scale_value( x );
    var scaled_y = scale_value( y );

    _map.model.get_droppable( scaled_x, scaled_y, out attach_node, out attach_conn, out attach_sticker );

    // Set the attach mode
    _map.model.set_attach_node( attach_node, NodeMode.DROPPABLE );

    return( Gdk.DragAction.MOVE );

  }

  //-------------------------------------------------------------
  // Called when text is dropped on the DrawArea
  private bool handle_text_drop( Value val, double x, double y ) {

    Node node;
    var  text = (string)val;

    if( Utils.is_url( text.chomp() ) && do_file_drop( text.chomp(), x, y ) ) {
      return( true );
    }

    if( (_map.model.attach_node != null) && (_map.model.attach_node.mode == NodeMode.DROPPABLE) ) {
      node = _map.model.create_child_node( _map.model.attach_node, text );
      _map.add_undo( new UndoNodeInsert( node, node.index() ) );
      if( _map.select_node( node ) ) {
        queue_draw();
        see();
        _map.auto_save();
      }
      return( true );
    }

    return( false );

  }

  //-------------------------------------------------------------
  // Called whenever we drag something over the canvas.
  private Gdk.DragAction handle_file_drag_motion( double x, double y ) {

    Node       attach_node;
    Connection attach_conn;
    Sticker    attach_sticker;

    var scaled_x = scale_value( x );
    var scaled_y = scale_value( y );

    _map.model.get_droppable( scaled_x, scaled_y, out attach_node, out attach_conn, out attach_sticker );

    // Set the attach node (if valid) as droppable
    _map.model.set_attach_node( attach_node, NodeMode.DROPPABLE );

    return( Gdk.DragAction.COPY );

  }

  //-------------------------------------------------------------
  // Called when something is dropped on the DrawArea.
  private bool handle_file_drop( Value val, double x, double y ) {

    var file = (GLib.File)val;

    return( do_file_drop( file.get_uri(), x, y ) );

  }

  //-------------------------------------------------------------
  // Performs the file drop operation.
  private bool do_file_drop( string uri, double x, double y ) {

    if( (_map.model.attach_node == null) || (_map.model.attach_node.mode != NodeMode.DROPPABLE) ) {

      var image = new NodeImage.from_uri( _map.image_manager, uri, 200 );
      if( image.valid ) {
        var node = _map.model.create_root_node( _( "Another Idea" ) );
        node.set_image( _map.model.image_manager, image );
        if( _map.select_node( node ) ) {
          _map.model.set_node_mode( node, NodeMode.EDITABLE, false );
          queue_draw();
          _map.auto_save();
        }
        return( true );
      }

    } else {

      var image = new NodeImage.from_uri( _map.image_manager, uri, _map.model.attach_node.style.node_width );
      if( image.valid ) {
        var orig_image = _map.model.attach_node.image;
        _map.model.attach_node.set_image( _map.model.image_manager, image );
        _map.add_undo( new UndoNodeImage( _map.model.attach_node, orig_image ) );
        _map.model.set_attach_node( null );
        queue_draw();
        current_changed( _map );
        _map.auto_save();
        return( true );
      }

    }

    return( false );

  }

  //-------------------------------------------------------------
  // Called whenever we drag a sticker over the canvas.
  private Gdk.DragAction handle_sticker_drag_motion( double x, double y ) {

    Node       attach_node;
    Connection attach_conn;
    Sticker    attach_sticker;

    var scaled_x = scale_value( x );
    var scaled_y = scale_value( y );

    _map.model.get_droppable( scaled_x, scaled_y, out attach_node, out attach_conn, out attach_sticker );

    _map.model.set_attach_node( attach_node, NodeMode.DROPPABLE );
    _map.model.set_attach_connection( attach_conn, ConnMode.DROPPABLE );
    _map.model.set_attach_sticker( attach_sticker, StickerMode.DROPPABLE );

    return( Gdk.DragAction.COPY );

  }

  //-------------------------------------------------------------
  // Called when a sticker is dropped on the DrawArea.
  private bool handle_sticker_drop( Value val, double x, double y ) {

    var drop_sticker = (Picture)val;

    if( ((_map.model.attach_node == null) || (_map.model.attach_node.mode != NodeMode.DROPPABLE)) &&
        ((_map.model.attach_conn == null) || (_map.model.attach_conn.mode != ConnMode.DROPPABLE)) ) {

      if( _map.model.attach_sticker != null ) {
        var sticker = new Sticker( _map, drop_sticker.name, _map.model.attach_sticker.posx, _map.model.attach_sticker.posy, (int)_map.model.attach_sticker.width );
        _map.stickers.remove_sticker( _map.model.attach_sticker );
        _map.stickers.add_sticker( sticker );
        _map.selected.set_current_sticker( sticker );
        _map.add_undo( new UndoStickerChange( _map.model.attach_sticker, sticker ) );
        _map.model.set_attach_sticker( null );
      } else {
        var sticker = new Sticker( _map, drop_sticker.name, scale_value( x ), scale_value( y ) );
        _map.stickers.add_sticker( sticker );
        _map.selected.set_current_sticker( sticker );
        _map.add_undo( new UndoStickerAdd( sticker ) );
      }

      grab_focus();
      see();
      queue_draw();
      current_changed( _map );
      _map.auto_save();

    } else {

      if( _map.model.attach_node != null ) {
        if( _map.model.attach_node.sticker == null ) {
          _map.add_undo( new UndoNodeStickerAdd( _map.model.attach_node, drop_sticker.name ) );
        } else {
          _map.add_undo( new UndoNodeStickerChange( _map.model.attach_node, _map.model.attach_node.sticker ) );
        }
        _map.model.attach_node.sticker = drop_sticker.name;
        _map.model.set_attach_node( null );
      } else if( _map.model.attach_conn != null ) {
        if( _map.model.attach_conn.sticker == null ) {
          _map.add_undo( new UndoConnectionStickerAdd( _map.model.attach_conn, drop_sticker.name ) );
        } else {
          _map.add_undo( new UndoConnectionStickerChange( _map.model.attach_conn, _map.model.attach_conn.sticker ) );
        }
        _map.model.attach_conn.sticker = drop_sticker.name;
        _map.model.set_attach_connection( null );
      }

      queue_draw();
      current_changed( _map );
      _map.auto_save();

    }

    return( true );

  }

  //-------------------------------------------------------------
  // Called when a connection is being drawn by moving the mouse.
  public void update_connection( double x, double y ) {
    var current = _map.selected.current_connection();
    if( current == null ) return;
    current.draw_to( scale_value( x ), scale_value( y ) );
    queue_draw();
  }

  //-------------------------------------------------------------
  // Updates the create_new_from_edit variable.
  private void update_create_new_from_edit( GLib.Settings settings ) {
    _create_new_from_edit = _map.settings.get_boolean( "new-node-from-edit" );
  }

  //-------------------------------------------------------------
  // Called by the Tagger class to actually add the tag to the
  // currently selected row.
  public void add_tag( string tag ) {
    var node = _map.selected.current_node();
    if( node == null ) return;
    var name = node.name;
    var orig_text = new CanvasText( _map );
    orig_text.copy( name );
    tagger.preedit_load_tags( name.text );
    name.text.insert_text( name.text.text.length, (" @" + tag) );
    name.text.changed();
    tagger.postedit_load_tags( name.text );
    _map.add_undo( new UndoNodeName( _map, node, orig_text ) );
    _map.auto_save();
  }

  //-------------------------------------------------------------
  // Displays the auto-completion widget with the given list of
  // values.
  public void show_auto_completion( GLib.List<TextCompletionItem> values, int start_pos, int end_pos ) {
    if( _map.is_node_editable() ) {
      _completion.show( _map.selected.current_node().name, values, start_pos, end_pos );
    } else if( _map.is_callout_editable() ) {
      _completion.show( _map.selected.current_callout().text, values, start_pos, end_pos );
    } else {
      _completion.hide();
    }
  }

  //-------------------------------------------------------------
  // Hides the auto-completion widget from view.
  public void hide_auto_completion() {
    _completion.hide();
  }

}
