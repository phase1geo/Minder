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

public class DrawArea : Gtk.DrawingArea {

  private double      _press_x;
  private double      _press_y;
  private double      _origin_x   = 0.0;
  private double      _origin_y   = 0.0;
  private bool        _pressed    = false;
  private EventType   _press_type = EventType.NOTHING;
  private bool        _motion     = false;
  private Node        _current_node;
  private Array<Node> _nodes;
  private Theme       _theme;
  private Layout      _layout;
  private double      _scale_factor = 1.0;
  private string      _orig_name;
  private NodeSide    _orig_side;
  private Node?       _attach_node  = null;

  public UndoBuffer undo_buffer { set; get; default = new UndoBuffer(); }
  public Themes     themes      { set; get; default = new Themes(); }
  public Layouts    layouts     { set; get; default = new Layouts(); }

  public signal void changed();
  public signal void node_changed();
  public signal void scale_changed( double scale );
  public signal void show_node_properties();
  public signal void loaded();

  /* Default constructor */
  public DrawArea() {

    /* Create the array of root nodes in the map */
    _nodes = new Array<Node>();

    /* Set the theme to the default theme */
    set_theme( "Default" );
    set_layout( _( "Horizontal" ) );

    /* Add event listeners */
    this.draw.connect( on_draw );
    this.button_press_event.connect( on_press );
    this.motion_notify_event.connect( on_motion );
    this.button_release_event.connect( on_release );
    this.key_press_event.connect( on_keypress );

    /* Make sure the above events are listened for */
    this.add_events(
      EventMask.BUTTON_PRESS_MASK |
      EventMask.BUTTON_RELEASE_MASK |
      EventMask.BUTTON1_MOTION_MASK |
      EventMask.KEY_PRESS_MASK |
      EventMask.STRUCTURE_MASK
    );

    /* Make sure the drawing area can receive keyboard focus */
    this.can_focus = true;

  }

  /* Returns the name of the currently selected theme */
  public string get_theme_name() {
    return( _theme.name );
  }

  /* Sets the theme to the given value */
  public void set_theme( string name ) {
    _theme = themes.get_theme( name );
    StyleContext.add_provider_for_screen(
      Screen.get_default(),
      _theme.get_css_provider(),
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );
    queue_draw();
  }

  /* Returns the name of the currently selected theme */
  public string get_layout_name() {
    return( _layout.name );
  }

  /* Sets the layout to the given value */
  public void set_layout( string name ) {
    _layout = layouts.get_layout( name );
    /* TBD - We need to adjust all of the nodes using the given layout */
    queue_draw();
  }

  /* Loads the drawing area origin from the XML node */
  private void load_drawarea( Xml.Node* n ) {

    string? x = n->get_prop( "x" );
    if( x != null ) {
      _origin_x = double.parse( x );
    }

    string? y = n->get_prop( "y" );
    if( y != null ) {
      _origin_y = double.parse( y );
    }

    string? sf = n->get_prop( "scale" );
    if( sf != null ) {
      _scale_factor = double.parse( sf );
      scale_changed( _scale_factor );
    }

  }

  /* Loads the given theme from the list of available options */
  private void load_theme( Xml.Node* n ) {
    string? name = n->get_prop( "name" );
    if( name != null ) {
      _theme = themes.get_theme( name );
      StyleContext.add_provider_for_screen(
        Screen.get_default(),
        _theme.get_css_provider(),
        STYLE_PROVIDER_PRIORITY_APPLICATION
      );
    }
  }

  /* Loads the given layout from the list of available options */
  private void load_layout( Xml.Node* n ) {
    string? name = n->get_prop( "name" );
    if( name != null ) {
      _layout = layouts.get_layout( name );
    }
  }

  /* Loads the contents of the data input stream */
  public void load( Xml.Node* n ) {

    /* Clear the existing nodes */
    _nodes.remove_range( 0, _nodes.length );

    /* Load the contents of the file */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "theme"    :  load_theme( it );   break;
          case "layout"   :  load_layout( it );  break;
          case "drawarea" :  load_drawarea( it );  break;
          case "nodes"    :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                RootNode node = new RootNode( _layout );
                node.load( it2, _layout );
                _nodes.append_val( node );
              }
            }
            break;
        }
      }
    }

    queue_draw();
    queue_draw();

    /* Indicate to anyone listening that we have loaded a new file */
    loaded();

  }

  /* Saves the contents of the drawing area to the data output stream */
  public bool save( Xml.Node* parent ) {

    Xml.Node* theme = new Xml.Node( null, "theme" );
    theme->new_prop( "name", _theme.name );
    parent->add_child( theme );

    Xml.Node* layout = new Xml.Node( null, "layout" );
    layout->new_prop( "name", _layout.name );
    parent->add_child( layout );

    Xml.Node* origin = new Xml.Node( null, "drawarea" );
    origin->new_prop( "x", _origin_x.to_string() );
    origin->new_prop( "y", _origin_y.to_string() );
    origin->new_prop( "scale", _scale_factor.to_string() );
    parent->add_child( origin );

    Xml.Node* nodes = new Xml.Node( null, "nodes" );
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).save( nodes );
    }
    parent->add_child( nodes );

    return( true );

  }

  /* Imports the OPML data, creating a mind map */
  public void import_opml( Xml.Node* n, ref Array<int>? expand_state) {

    int node_id = 1;

    /* Clear the existing nodes */
    _nodes.remove_range( 0, _nodes.length );

    /* Load the contents of the file */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "outline") {
          var root = new RootNode( _layout );
          root.import_opml( it, node_id, ref expand_state, _layout );
          _nodes.append_val( root );
        }
      }
    }

  }

  /* Exports all of the nodes in OPML format */
  public void export_opml( Xml.Node* parent, out string expand_state ) {
    Array<int> estate  = new Array<int>();
    int        node_id = 1;
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).export_opml( parent, ref node_id, ref estate );
    }
    expand_state = "";
    for( int i=0; i<estate.length; i++ ) {
      if( i > 0 ) {
        expand_state += ",";
      }
      expand_state += estate.index( i ).to_string();
    }
  }

  /* Initialize the empty drawing area with a node */
  public void initialize() {

    /* Clear the list of existing nodes */
    _nodes.remove_range( 0, _nodes.length );

    /* Clear the undo buffer */
    undo_buffer.clear();

    /* Create the main idea node */
    var n = new RootNode.with_name( "Main Idea", _layout );

    /* Set the node information */
    n.posx = (get_allocated_width()  / 2) - 30;
    n.posy = (get_allocated_height() / 2) - 10;

    _nodes.append_val( n );
    _orig_name    = "";

    /* Make this initial node the current node */
    set_current_node( n );

    /* Redraw the canvas */
    queue_draw();
    queue_draw();

  }

  /* Returns the current node */
  public Node? get_current_node() {
    return( _current_node );
  }

  /* Returns the current layout */
  public Layout get_layout() {
    return( _layout );
  }

  /*
   Populates the list of matches with any nodes that match the given string
   pattern.
  */
  public void get_match_items( string pattern, ref Gtk.ListStore matches ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).get_match_items( pattern, ref matches );
    }
  }

  /* Sets the current node to the given node */
  public void set_current_node( Node? n ) {
    if( n == null ) {
      _current_node = n;
      node_changed();
    } else if( _current_node == n ) {
      _current_node.mode = NodeMode.CURRENT;
    } else {
      if( _current_node != null ) {
        _current_node.mode = NodeMode.NONE;
      }
      _current_node = n;
      _current_node.mode = NodeMode.CURRENT;
      node_changed();
    }
  }

  /* Toggles the value of the specified node, if possible */
  public void toggle_task( Node n ) {
    undo_buffer.add_item( new UndoNodeTask( this, n, true, !n.task_done() ) );
    n.toggle_task_done();
  }

  /* Toggles the fold for the given node */
  public void toggle_fold( Node n ) {
    bool fold = !n.folded;
    undo_buffer.add_item( new UndoNodeFold( this, n, fold ) );
    n.folded = fold;
  }

  /*
   Sets the current node pointer to the node that is within the given coordinates.
   Returns true if we sucessfully set current_node to a valid node and made it
   selected.
  */
  private bool set_current_node_at_position( double x, double y, EventButton e ) {
    for( int i=0; i<_nodes.length; i++ ) {
      Node match = _nodes.index( i ).contains( x, y );
      if( match != null ) {
        if( match.is_within_task( x, y ) && match.is_leaf() ) {
          toggle_task( match );
          return( false );
        } else if( match.is_within_fold( x, y ) ) {
          toggle_fold( match );
          return( false );
        }
        _orig_side = match.side;
        if( match == _current_node ) {
          if( is_mode_edit() ) {
            switch( e.type ) {
              case EventType.BUTTON_PRESS :         match.set_cursor_at_char( x, y, false );  break;
              case EventType.DOUBLE_BUTTON_PRESS :  match.set_cursor_at_word( x, y, false );  break;
              case EventType.TRIPLE_BUTTON_PRESS :  match.set_cursor_all( false );            break;
            }
          }
          return( true );
        } else {
          if( _current_node != null ) {
            _current_node.mode = NodeMode.NONE;
          }
          _current_node = match;
          if( match.mode == NodeMode.NONE ) {
            match.mode = NodeMode.CURRENT;
            node_changed();
            return( true );
          }
        }
        return( false );
      }
    }
    if( _current_node != null ) {
      _current_node.mode = NodeMode.NONE;
    }
    _current_node = null;
    node_changed();
    return( true );
  }

  /* Returns the supported scale points */
  public double[] get_scale_marks() {
    double[] marks = {10, 25, 50, 75, 100, 150, 200, 250, 300, 350, 400};
    return( marks );
  }

  /* Returns a properly scaled version of the given value */
  private double scale_value( double val ) {
    return( val / _scale_factor );
  }

  /* Sets the scaling factor for the drawing area and forces a redraw */
  public void set_scaling_factor( double scale_factor ) {
    if( _scale_factor != scale_factor ) {
      int    width  = get_allocated_width()  / 2;
      int    height = get_allocated_height() / 2;
      double diff_x = (width  / _scale_factor) - (width  / scale_factor);
      double diff_y = (height / _scale_factor) - (height / scale_factor);
      move_origin( diff_x, diff_y );
      _scale_factor = scale_factor;
      scale_changed( _scale_factor );
      queue_draw();
    }
  }

  /* Returns the scaling factor based on the given width and height */
  private double get_scaling_factor( double width, double height ) {
    double w = width  / get_allocated_width();
    double h = height / get_allocated_height();
    return( (w > h) ? w : h );
  }

  /* Zooms into the image by one scale mark */
  public void zoom_in() {
    var value = _scale_factor * 100;
    var marks = get_scale_marks();
    foreach (double mark in marks) {
      if( value < mark ) {
        set_scaling_factor( mark / 100 );
        return;
      }
    }
  }

  /* Zooms out of the image by one scale mark */
  public void zoom_out() {
    double value = _scale_factor * 100;
    var    marks = get_scale_marks();
    double last  = marks[0];
    foreach (double mark in marks) {
      if( value <= mark ) {
        set_scaling_factor( last / 100 );
        return;
      }
      last = mark;
    }
  }

  /*
   Returns the scaling factor required to display the currently selected node.
   If no node is currently selected, returns a value of 0.
  */
  public void zoom_to_selected() {
    double x, y, w, h;
    if( _current_node == null ) return;
    _layout.bbox( _current_node, -1, -1, out x, out y, out w, out h );
    move_origin( (scale_value( x ) - _origin_x), (scale_value( y ) - _origin_y) );
    set_scaling_factor( get_scaling_factor( w, h ) );
  }

  /* Returns the scaling factor required to display all nodes */
  public void zoom_to_fit() {
    double x1 = 0;
    double y1 = 0;
    double x2 = 0;
    double y2 = 0;
    for( int i=0; i<_nodes.length; i++ ) {
      double x, y, w, h;
      _layout.bbox( _nodes.index( i ), -1, -1, out x, out y, out w, out h );
      x1 = (x1 < x) ? x1 : x;
      y1 = (y1 < y) ? y1 : y;
      x2 = (x2 < (x + w)) ? (x + w) : x2;
      y2 = (y2 < (y + h)) ? (y + h) : y2;
    }
    move_origin( (scale_value( x1 ) - _origin_x), (scale_value( y1 ) - _origin_y) );
    set_scaling_factor( get_scaling_factor( (x2 - x1), (y2 - y1) ) );
  }

  /* Centers the given node within the canvas by adjusting the origin */
  public void center( Node n ) {

    double x, y, w, h;
    n.bbox( out x, out y, out w, out h );

    double ccx = scale_value( get_allocated_width()  / 2 );
    double ccy = scale_value( get_allocated_height() / 2 );
    double ncx = x + (w / 2);
    double ncy = y + (h / 2);

    move_origin( (ncx - ccx), (ncy - ccy) );

  }

  /* Brings the given node into view in its entirety including the given amount of padding */
  public void see( Node n, double pad = 20.0 ) {

    double x, y, w, h;
    n.bbox( out x, out y, out w, out h );

    double diff_x = 0;
    double diff_y = 0;
    double sw     = scale_value( get_allocated_width() );
    double sh     = scale_value( get_allocated_height() );

    if( (x - pad) < 0 ) {
      diff_x = (x - pad);
    } else if( (x + w) > sw ) {
      diff_x = (x + w + pad) - sw;
    }

    if( (y - pad) < 0 ) {
      diff_y = (y - pad);
    } else if( (y + h) > sh ) {
      diff_y = (y + h + pad) - sh;
    }

    if( (diff_x != 0) || (diff_y != 0) ) {
      move_origin( diff_x, diff_y );
    }

  }

  /* Returns the attachable node if one is found */
  private Node? attachable_node( double x, double y ) {
    for( int i=0; i<_nodes.length; i++ ) {
      Node tmp = _nodes.index( i ).contains( x, y );
      /* If the node under the cursor is not the current node nor its parent, it can be attached to. */
      if( (tmp != null) && (tmp != _current_node) && (tmp != _current_node.parent) && !_current_node.contains_node( tmp ) ) {
        return( tmp );
      }
    }
    return( null );
  }

  /*
   Adjusts the x and y origins, panning all elements by the given amount.
   Important Note:  When the canvas is panned to the left (causing all
   nodes to be moved to the left, the origin_x value becomes a positive
   number.
  */
  public void move_origin( double diff_x, double diff_y ) {
    _origin_x += diff_x;
    _origin_y += diff_y;
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).pan( diff_x, diff_y );
    }
  }

  /* Draw the available nodes */
  private bool on_draw( Context ctx ) {
    if( _layout.default_text_height == 0 ) {
      var text = Pango.cairo_create_layout( ctx );
      int width, height;
      text.set_font_description( _layout.get_font_description() );
      text.set_text( "O", -1 );
      text.get_size( out width, out height );
      _layout.default_text_height = height / Pango.SCALE;
    }
    ctx.scale( _scale_factor, _scale_factor );
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).draw_all( ctx, _theme );
    }
    return( false );
  }

  /* Handle button press event */
  private bool on_press( EventButton event ) {
    if( event.button == 1 ) {
      _press_x    = scale_value( event.x );
      _press_y    = scale_value( event.y );
      _pressed    = set_current_node_at_position( _press_x, _press_y, event );
      _press_type = event.type;
      _motion     = false;
      grab_focus();
      queue_draw();
    }
    return( false );
  }

  /* Handle mouse motion */
  private bool on_motion( EventMotion event ) {
    if( _pressed ) {
      if( _current_node != null ) {
        double diffx = scale_value( event.x ) - _press_x;
        double diffy = scale_value( event.y ) - _press_y;
        if( _current_node.mode == NodeMode.CURRENT ) {
          Node attach_node = attachable_node( scale_value( event.x ), scale_value( event.y ) );
          if( attach_node != null ) {
            attach_node.mode = NodeMode.ATTACHABLE;
            _attach_node     = attach_node;
          } else if( _attach_node != null ) {
            _attach_node.mode = NodeMode.NONE;
            _attach_node      = null;
          }
          _current_node.posx += diffx;
          _current_node.posy += diffy;
          _layout.set_side( _current_node );
        } else {
          switch( _press_type ) {
            case EventType.BUTTON_PRESS        :  _current_node.set_cursor_at_char( scale_value( event.x ), scale_value( event.y ), true );  break;
            case EventType.DOUBLE_BUTTON_PRESS :  _current_node.set_cursor_at_word( scale_value( event.x ), scale_value( event.y ), true );  break;
          }
        }
        queue_draw();
      } else {
        double diff_x = _press_x - scale_value( event.x );
        double diff_y = _press_y - scale_value( event.y );
        move_origin( diff_x, diff_y );
        queue_draw();
      }
      _press_x = scale_value( event.x );
      _press_y = scale_value( event.y );
      _motion  = true;
      changed();
    }
    return( false );
  }

  /* Handle button release event */
  private bool on_release( EventButton event ) {
    _pressed = false;
    if( _current_node != null ) {
      if( _current_node.mode == NodeMode.CURRENT ) {
        if( _attach_node != null ) {
          if( _current_node.is_root() ) {
            for( int i=0; i<_nodes.length; i++ ) {
              if( _nodes.index( i ) == _current_node ) {
                _nodes.remove_index( i );
                break;
              }
            }
            _current_node = new NonrootNode.from_RootNode( (RootNode)_current_node );
          } else {
            _current_node.detach( _orig_side, _layout );
          }
          _current_node.attach( _attach_node, -1, _layout );
          _attach_node.mode = NodeMode.NONE;
          _attach_node      = null;
          queue_draw();
          changed();
          node_changed();
        } else if( !_motion ) {
          _current_node.set_cursor_all( false );
          _orig_name = _current_node.name;
          _current_node.move_cursor_to_end();
        } else if( _current_node.parent != null ) {
          _current_node.parent.move_to_position( _current_node, _orig_side, scale_value( event.x ), scale_value( event.y ), _layout );
          queue_draw();
        }
      }
    }
    return( false );
  }

  /* Returns true if we are in some sort of edit mode */
  private bool is_mode_edit() {
    return( _current_node.mode == NodeMode.EDITABLE );
  }

  /* Returns true if we are in the selected mode */
  private bool is_mode_selected() {
    return( _current_node.mode == NodeMode.CURRENT );
  }

  /* If the specified node is not null, selects the node and makes it the current node */
  private bool select_node( Node? n ) {
    if( n != null ) {
      if( n != _current_node ) {
        if( _current_node != null ) {
          _current_node.mode = NodeMode.NONE;
        }
        _current_node = n;
        _current_node.mode = NodeMode.CURRENT;
        node_changed();
      }
      return( true );
    }
    return( false );
  }

  /* Deletes the given node */
  private void delete_node( Node n ) {
    undo_buffer.add_item( new UndoNodeDelete( this, _current_node, _layout ) );
    if( _current_node.is_root() ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) == _current_node ) {
          _nodes.remove_index( i );
          break;
        }
      }
    } else {
      n.delete( _layout );
    }
    _current_node = null;
    queue_draw();
    node_changed();
    changed();
  }

  /* Called whenever the backspace character is entered in the drawing area */
  private void handle_backspace() {
    if( is_mode_edit() ) {
      _current_node.edit_backspace( _layout );
      queue_draw();
      changed();
    } else if( is_mode_selected() ) {
      delete_node( _current_node );
      _current_node = null;
    }
  }

  /* Called whenever the delete character is entered in the drawing area */
  private void handle_delete() {
    if( is_mode_edit() ) {
      _current_node.edit_delete( _layout );
      queue_draw();
      changed();
    } else if( is_mode_selected() ) {
      delete_node( _current_node );
      _current_node = null;
    }
  }

  /* Called whenever the escape character is entered in the drawing area */
  private void handle_escape() {
    if( is_mode_edit() ) {
      _current_node.mode = NodeMode.CURRENT;
      node_changed();
      queue_draw();
    }
  }

  /* Called whenever the return character is entered in the drawing area */
  private void handle_return() {
    if( is_mode_edit() ) {
      undo_buffer.add_item( new UndoNodeName( this, _current_node, _orig_name ) );
      _current_node.mode = NodeMode.CURRENT;
      node_changed();
      queue_draw();
    } else if( !_current_node.is_root() ) {
      NonrootNode node = new NonrootNode( _layout );
      _orig_name = "";
      if( _current_node.parent.is_root() ) {
        node.color_index = _theme.next_color_index();
      } else {
        node.color_index = ((NonrootNode)_current_node).color_index;
      }
      _current_node.mode = NodeMode.NONE;
      node.side          = _current_node.side;
      node.attach( _current_node.parent, (_current_node.index() + 1), _layout );
      undo_buffer.add_item( new UndoNodeInsert( this, node, _layout ) );
      if( select_node( node ) ) {
        node.mode = NodeMode.EDITABLE;
        queue_draw();
      }
      adjust_origin();
      changed();
    } else {
      var node = new RootNode.with_name( _( "Another Idea" ), _layout );
      _layout.position_root( _nodes.index( _nodes.length - 1 ), node );
      _nodes.append_val( node );
      if( select_node( node ) ) {
        node.mode = NodeMode.EDITABLE;
        queue_draw();
      }
      adjust_origin();
      changed();
    }
  }

  /* Adds the given node to the list of root nodes */
  public void add_root( Node n, int index ) {
    n.mode = NodeMode.NONE;
    if( index == -1 ) {
      _nodes.append_val( n );
    } else {
      _nodes.insert_val( index, n );
    }
  }

  /* Removes the node at the given root index from the list of root nodes */
  public void remove_root( int index ) {
    _nodes.remove_index( index );
  }

  /* Returns true if the drawing area has a node that is available for detaching */
  public bool detachable() {
    return( (_current_node != null) && (_current_node.parent != null) );
  }

  /* Detaches the current node from its parent and adds it as a root node */
  public void detach() {
    if( !detachable() ) return;
    Node     parent = _current_node.parent;
    int      index  = _current_node.index();
    NodeSide side   = _current_node.side;
    _current_node.detach( side, _layout );
    _current_node = new RootNode.from_NonrootNode( (NonrootNode)_current_node );
    if( index == -1 ) {
      _nodes.append_val( _current_node );
    } else {
      _nodes.insert_val( index, _current_node );
    }
    undo_buffer.add_item( new UndoNodeDetach( this, _current_node, (int)_nodes.length, parent, side, index, _layout ) );
    queue_draw();
    changed();
  }

  /* Balances the existing nodes based on the current layout */
  public void balance_nodes() {

    /* TBD - We will balance the current nodes based on the current layout */

  }

  /* Called whenever the tab character is entered in the drawing area */
  private void handle_tab() {
    if( is_mode_edit() ) {
      undo_buffer.add_item( new UndoNodeName( this, _current_node, _orig_name ) );
      _current_node.mode = NodeMode.CURRENT;
      node_changed();
      queue_draw();
    } else if( is_mode_selected() ) {
      NonrootNode node = new NonrootNode( _layout );
      _orig_name = "";
      if( _current_node.is_root() ) {
        node.color_index = _theme.next_color_index();
      } else {
        node.color_index = ((NonrootNode)_current_node).color_index;
        node.side        = _current_node.side;
      }
      _current_node.mode = NodeMode.NONE;
      node.attach( _current_node, -1, _layout );
      undo_buffer.add_item( new UndoNodeInsert( this, node, _layout ) );
      if( select_node( node ) ) {
        node.mode = NodeMode.EDITABLE;
        queue_draw();
      }
      adjust_origin();
      changed();
    }
  }

  /* Called whenever the right key is entered in the drawing area */
  private void handle_right() {
    if( is_mode_edit() ) {
      _current_node.move_cursor( 1 );
      queue_draw();
    } else if( is_mode_selected() ) {
      if( select_node( _current_node.first_child() ) ) {
        queue_draw();
      }
    }
  }

  /* Called whenever the left key is entered in the drawing area */
  private void handle_left() {
    if( is_mode_edit() ) {
      _current_node.move_cursor( -1 );
      queue_draw();
    } else if( is_mode_selected() ) {
      if( select_node( _current_node.parent ) ) {
        queue_draw();
      }
    }
  }

  /* Called whenever the home key is entered in the drawing area */
  private void handle_home() {
    if( is_mode_edit() ) {
      _current_node.move_cursor_to_start();
      queue_draw();
    }
  }

  /* Called whenever the end key is entered in the drawing area */
  private void handle_end() {
    if( is_mode_edit() ) {
      _current_node.move_cursor_to_end();
      queue_draw();
    }
  }

  /* Called whenever the up key is entered in the drawing area */
  private void handle_up() {
    if( is_mode_selected() ) {
      if( _current_node.is_root() ) {
        for( int i=0; i<_nodes.length; i++ ) {
          if( _nodes.index( i ) == _current_node ) {
            if( i > 0 ) {
              if( select_node( _nodes.index( i - 1 ) ) ) {
                queue_draw();
              }
              return;
            }
          }
        }
      } else {
        if( select_node( _current_node.parent.prev_child( _current_node ) ) ) {
          queue_draw();
        }
      }
    }
  }

  /* Called whenever the down key is entered in the drawing area */
  private void handle_down() {
    if( is_mode_selected() ) {
      if( _current_node.is_root() ) {
        for( int i=0; i<_nodes.length; i++ ) {
          if( _nodes.index( i ) == _current_node ) {
            if( (i + 1) < _nodes.length ) {
              if( select_node( _nodes.index( i + 1 ) ) ) {
                queue_draw();
              }
              return;
            }
          }
        }
      } else {
        if( select_node( _current_node.parent.next_child( _current_node ) ) ) {
          queue_draw();
        }
      }
    }
  }

  /* Called whenever the page up key is entered in the drawing area */
  private void handle_pageup() {
    if( is_mode_selected() ) {
      if( _current_node.is_root() ) {
        if( _nodes.length > 0 ) {
          if( select_node( _nodes.index( 0 ) ) ) {
            queue_draw();
          }
        }
      } else {
        if( select_node( _current_node.parent.first_child() ) ) {
          queue_draw();
        }
      }
    }
  }

  /* Called whenever the page down key is entered in the drawing area */
  private void handle_pagedn() {
    if( is_mode_selected() ) {
      if( _current_node.is_root() ) {
        if( _nodes.length > 0 ) {
          if( select_node( _nodes.index( _nodes.length - 1 ) ) ) {
            queue_draw();
          }
        }
      } else {
        if( select_node( _current_node.parent.last_child() ) ) {
          queue_draw();
        }
      }
    }
  }

  /*
   Checks to see if the current node boundaries are close to running off the canvas
   and adjusts the view to keep everything visible
  */
  private void adjust_origin() {
    double x, y, w, h;
    double diff_x = 0;
    double diff_y = 0;
    _current_node.bbox( out x, out y, out w, out h );
    double scaled_x = scale_value( x );
    double scaled_y = scale_value( y );
    double scaled_w = scale_value( w );
    double scaled_h = scale_value( h );
    if( scaled_x < scale_value( 10 ) ) {
      diff_x = scale_value( -100 );
    } else if( (get_allocated_width() - (scaled_x + scaled_w)) < scale_value( 10 ) ) {
      diff_x = scale_value( 100 );
    }
    if( scaled_y < scale_value( 10 ) ) {
      diff_y = scale_value( -100 );
    } else if( (get_allocated_height() - (scaled_y + scaled_h)) < scale_value( 10 ) ) {
      diff_y = scale_value( 100 );
    }
    move_origin( diff_x, diff_y );
  }

  /* Called whenever a printable character is entered in the drawing area */
  private void handle_printable( string str ) {
    if( str.get_char( 0 ).isprint() ) {
      if( is_mode_edit() ) {
        _current_node.edit_insert( str, _layout );
        adjust_origin();
        queue_draw();
        changed();
      } else if( is_mode_selected() ) {
        switch( str ) {
          case "e" :  // Place the current node in edit mode
            _current_node.mode = NodeMode.EDITABLE;
            break;
          case "n" :  // Move the selection to the next sibling
            handle_down();
            break;
          case "p" :  // Move the selection to the previous sibling
            handle_up();
            break;
          case "a" :  // Move to the parent node
            handle_left();
            break;
          case "f" :  // Fold/unfold the current node
            toggle_fold( _current_node );
            break;
          case "t" :  // Toggle the task done indicator
            if( _current_node.is_task() ) {
              toggle_task( _current_node );
            }
            break;
          case "m" :  // Select the root node
            if( (_nodes.length == 0) || !select_node( _nodes.index( 0 ) ) ) {
              return;
            }
            break;
          case "c" :  // Select the first child node
            handle_right();
            break;
          case "C" :  // Center the selected node
            center( _current_node );
            break;
          case "i" :  // Display the node properties panel
            show_node_properties();
            return;
          case "u" :  // Perform undo
            if( undo_buffer.undoable() ) {
              undo_buffer.undo();
            }
            break;
          case "r" :  // Perform redo
            if( undo_buffer.redoable() ) {
              undo_buffer.redo();
            }
            break;
          case "s" :  // See the node
            see( _current_node );
            break;
          case "z" :  // Zoom out
            zoom_out();
            break;
          case "Z" :  // Zoom in
            zoom_in();
            break;
          default :
            // This is a key that doesn't have any associated functionality
            // so just return immediately so that we don't force a redraw
            return;
        }
        queue_draw();
      }
    }
  }

  /* Handle a key event */
  private bool on_keypress( EventKey event ) {
    if( _current_node != null ) {
      switch( event.keyval ) {
        case 65288 :  handle_backspace();  break;
        case 65535 :  handle_delete();     break;
        case 65307 :  handle_escape();     break;
        case 65293 :  handle_return();     break;
        case 65289 :  handle_tab();        break;
        case 65363 :  handle_right();      break;
        case 65361 :  handle_left();       break;
        case 65360 :  handle_home();       break;
        case 65367 :  handle_end();        break;
        case 65362 :  handle_up();         break;
        case 65364 :  handle_down();       break;
        case 65365 :  handle_pageup();     break;
        case 65366 :  handle_pagedn();     break;
        default :
          //if( !event.str.get_char( 0 ).isprint() ) {
          //  stdout.printf( "In on_keypress, keyval: %s\n", event.keyval.to_string() );
          //}
          handle_printable( event.str );
          break;
      }

    /* If there is no current node, allow some of the keyboard shortcuts */
    } else {
      switch( event.str ) {
        case "m" :
          if( (_nodes.length > 0) && select_node( _nodes.index( 0 ) ) ) {
            queue_draw();
          }
          break;
        case "u" :  // Perform undo
          if( undo_buffer.undoable() ) {
            undo_buffer.undo();
          }
          break;
        case "r" :  // Perform redo
          if( undo_buffer.redoable() ) {
            undo_buffer.redo();
          }
          break;
        case "z" :  // Zoom out
          zoom_out();
          break;
        case "Z" :  // Zoom in
          zoom_in();
          break;
        default :
          // No need to do anything here
          break;
      }
    }
    return( true );
  }

}
