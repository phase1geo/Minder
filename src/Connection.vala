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

using Cairo;
using Pango;
using Gdk;
using GLib.Math;

/* Connection mode value for the Connection.mode property */
public enum ConnMode {
  NONE = 0,    // Normally drawn mode
  CONNECTING,  // Indicates that the connection is being made between two nodes
  SELECTED,    // Indicates that the connection is currently selected
  ADJUSTING,   // Indicates that we are moving the drag handle to change the line shape
  EDITABLE     // Indicates that the connection title is in edit mode
}

public class Connection {

  private int         RADIUS     = 6;
  private ConnMode    _mode      = ConnMode.NONE;
  private Node?       _from_node = null;
  private Node?       _to_node   = null;
  private double      _posx;
  private double      _posy;
  private double      _dragx;
  private double      _dragy;
  private Style       _style = new Style();
  private Bezier      _curve;
  private CanvasText? _title = null;

  public CanvasText? title {
    get {
      return( _title );
    }
  }
  public string   note  { get; set; default = ""; }
  public ConnMode mode  {
    get {
      return( _mode );
    }
    set {
      if( _mode != value ) {
        _mode = value;
        if( _mode == ConnMode.EDITABLE ) {
          if( _title != null ) {
            _title.edit = true;
            _title.set_cursor_all( false );
          }
        } else {
          if( _title != null ) {
            _title.edit = false;
            _title.clear_selection();
          }
        }
      }
    }
  }
  public Style style { 
    get {
      return( _style );
    }
    set {
      if( _style.copy( value ) && (_title != null) ) {
        _title.set_font( _style.node_font );
      }
    }
  }
  public double alpha { get; set; default=1.0; }

  /* Default constructor */
  public Connection( DrawArea da, Node from_node ) {
    double x, y, w, h;
    from_node.bbox( out x, out y, out w, out h );
    _posx      = x + (w / 2);
    _posy      = y + (h / 2);
    _from_node = from_node;
    connect_node( _from_node );
    _dragx     = _posx;
    _dragy     = _posy;
    position_title();
    _curve     = new Bezier.with_endpoints( _posx, _posy, _posx, _posy );
    style      = StyleInspector.styles.get_global_style();
  }

  /* Constructs a connection based on another connection */
  public Connection.from_connection( DrawArea da, Connection conn ) {
    _curve = new Bezier();
    copy( da, conn );
  }

  /* Constructor from XML data */
  public Connection.from_xml( DrawArea da, Xml.Node* n ) {
    style = StyleInspector.styles.get_global_style();
    load( da, n );
  }

  /* Copies the given connection to this instance */
  public void copy( DrawArea da, Connection conn ) {
    _from_node    = conn._from_node;
    _to_node      = conn._to_node;
    _dragx        = conn._dragx;
    _dragy        = conn._dragy;
    position_title();
    _curve.copy( conn._curve );
    if( conn.title == null ) {
      _title = null;
    } else {
      if( title == null ) {
        _title = new CanvasText( da );
      }
      _title.copy( conn.title );
    }
    mode          = conn.mode;
    style         = conn.style;
  }

  /* Adds a title */
  public void change_title( DrawArea da, string title ) {
    if( title == "" ) {
      _title = null;
    } else if( _title == null ) {
      _title = new CanvasText.with_text( da, title );
      _title.set_font( style.node_font );
      position_title();
    } else {
      _title.text = title;
      position_title();
    }
  }

  /* Positions the given title according to the location of the _dragx and _dragy values */
  private void position_title() {
    if( title != null ) {
      var text_width  = title.width;
      var text_height = title.height;
      _title.posx = _dragx - (text_width  / 2);
      _title.posy = _dragy - (text_height / 2);
    }
  }

  /* Connects to the given node */
  private void connect_node( Node node ) {
    node.moved.connect( this.end_moved );
    node.resized.connect( this.end_resized );
  }

  /* Disconnects from the given node */
  private void disconnect_node( Node node ) {
    node.moved.disconnect( this.end_moved );
    node.resized.disconnect( this.end_resized );
  }

  /* Completes the connection */
  public void connect_to( Node node ) {
    double fx, fy, tx, ty;
    double x, y, w, h;
    node.bbox( out x, out y, out w, out h );
    if( _from_node == null ) {
      _from_node = node;
    } else {
      _to_node = node;
    }
    connect_node( node );
    _curve.set_point( ((_from_node == node) ? 0 : 2), (x + (w / 2)), (y + (h / 2)) );
    _curve.get_point( 0, out fx, out fy );
    _curve.get_point( 2, out tx, out ty );
    _dragx = (fx + tx) / 2;
    _dragy = (fy + ty) / 2;
    position_title();
    _curve.update_control_from_drag_handle( _dragx, _dragy );
    set_connect_point( node );
  }

  /* Called when disconnecting a connection from a node */
  public void disconnect( bool from ) {
    if( from ) {
      _curve.get_from_point( out _posx, out _posy );
      disconnect_node( _from_node );
      _from_node = null;
    } else {
      _curve.get_to_point( out _posx, out _posy );
      disconnect_node( _to_node );
      _to_node = null;
    }
    mode = ConnMode.CONNECTING;
  }

  /* Draws the connections to the given point */
  public void draw_to( double x, double y ) {
    double nx, ny;
    Node node = (_from_node != null) ? _from_node : _to_node;
    _posx = x;
    _posy = y;
    _curve.get_point( ((node == _from_node) ? 0 : 2), out nx, out ny );
    _dragx = (nx + x) / 2;
    _dragy = (ny + y) / 2;
    position_title();
    _curve.update_control_from_drag_handle( _dragx, _dragy );
    set_connect_point( node );
  }

  /* Handles any position changes of either the to or from node */
  private void end_moved( Node node, double diffx, double diffy ) {
    double x, y, w, h;
    node.bbox( out x, out y, out w, out h );
    _curve.set_point( ((_from_node == node) ? 0 : 2), (x + (w / 2)), (y + (h / 2)) );
    _dragx += (diffx / 2);
    _dragy += (diffy / 2);
    position_title();
    _curve.update_control_from_drag_handle( _dragx, _dragy );
    set_connect_point( _from_node );
    set_connect_point( _to_node );
  }

  /* Handles any resizing changes of either the to or from node */
  private void end_resized( Node node, double diffw, double diffh ) {
    double x, y, w, h;
    node.bbox( out x, out y, out w, out h );
    _curve.set_point( ((_from_node == node) ? 0 : 2), (x + (w / 2)), (y + (h / 2)) );
    _dragx += (diffw / 2);
    _dragy += (diffh / 2);
    position_title();
    _curve.update_control_from_drag_handle( _dragx, _dragy );
    set_connect_point( _from_node );
    set_connect_point( _to_node );
  }

  /* Returns true if we are attached to the given node */
  public bool attached_to_node( Node node ) {
    return( (_from_node == node) || (_to_node == node) );
  }

  /* Returns the point to add the connection to based on the node */
  private void set_connect_point( Node node ) {

    double x, y, w, h;
    double bw     = node.style.node_borderwidth;
    double extra  = bw + (style.connection_width / 2);
    double margin = node.style.node_margin;

    node.bbox( out x, out y, out w, out h );

    /* Remove the node's margin */
    x += margin;
    y += margin;
    w -= (margin * 2);
    h -= (margin * 2);

    _curve.set_connect_point( (node == _from_node), (y - extra), (y + h + extra), (x - extra), (x + w + extra) );

  }

  /* Returns true if the given point is within proximity to the stored curve */
  public bool on_curve( double x, double y ) {
    double fx, fy, tx, ty;
    _curve.get_from_point( out fx, out fy );
    _curve.get_to_point( out tx, out ty );
    var curve = new Bezier.with_endpoints( fx, fy, tx, ty );
    curve.update_control_from_drag_handle( _dragx, _dragy );
    return( curve.within_range( x, y ) );
  }

  /* Returns true if the given x/y point lies within a handle located at hx/hy */
  private bool within_handle( double hx, double hy, double x, double y ) {
    return( ((hx - RADIUS) <= x) && (x <= (hx + RADIUS)) && ((hy - RADIUS) <= y) && (y <= (hy + RADIUS)) );
  }

  /* Returns true if the given point is within the drag handle */
  public bool within_drag_handle( double x, double y ) {
    if( mode == ConnMode.SELECTED ) {
      if( title == null ) {
        return( within_handle( _dragx, _dragy, x, y ) );
      } else {
        double tx, ty, tw, th;
        title_bbox( out tx, out ty, out tw, out th );
        return( within_handle( _dragx, (_dragy + (th / 2) + _style.connection_padding), x, y ) );
      }
    } 
    return( false );
  }

  /* Returns true if the given point lies within the from connection handle */
  public bool within_from_handle( double x, double y ) {
    return( within_endpoint_handle( true, x, y ) );
  }

  /* Returns true if the given point lies within the from connection handle */
  public bool within_to_handle( double x, double y ) {
    return( within_endpoint_handle( false, x, y ) );
  }

  /* Returns true if the given point lies within the from connection handle */
  private bool within_endpoint_handle( bool from, double x, double y ) {
    if( mode == ConnMode.SELECTED ) {
      double px, py;
      if( from ) {
        _curve.get_from_point( out px, out py );
      } else {
        _curve.get_to_point( out px, out py );
      }
      return( within_handle( px, py, x, y ) );
    }
    return( false );
  }

  /* Returns true if the given coordinates are within the title text area. */
  public bool within_title( double x, double y ) {
    return( (_title != null) && _title.is_within( x, y ) );
  }

  /* Updates the location of the drag handle */
  public void move_drag_handle( double x, double y ) {
    mode = ConnMode.ADJUSTING;
    _dragx = x;
    _dragy = y;
    position_title();
    _curve.update_control_from_drag_handle( x, y );
    set_connect_point( _from_node );
    set_connect_point( _to_node );
  }

  /* Loads the connection information */
  private void load( DrawArea da, Xml.Node* node ) {

    string? f = node->get_prop( "from_id" );
    if( f != null ) {
      _from_node = da.get_node( int.parse( f ) );
      connect_node( _from_node );
    }

    string? t = node->get_prop( "to_id" );
    if( t != null ) {
      _to_node = da.get_node( int.parse( t ) );
      connect_node( _to_node );
    }

    string? x = node->get_prop( "drag_x" );
    if( x != null ) {
      _dragx = double.parse( x );
    }

    string? y = node->get_prop( "drag_y" );
    if( y != null ) {
      _dragy = double.parse( y );
    }

    string? n = node->get_prop( "note" );
    if( n != null ) {
      note = n;
    }

    /* Update the stored curve */
    double fx, fy, fw, fh;
    double tx, ty, tw, th;
    _from_node.bbox( out fx, out fy, out fw, out fh );
    _to_node.bbox(   out tx, out ty, out tw, out th );
    _curve = new Bezier.with_endpoints( (fx + (fw / 2)), (fy + (fh / 2)), (tx + (tw / 2)), (ty + (th / 2)) );
    _curve.update_control_from_drag_handle( _dragx, _dragy );
    set_connect_point( _from_node );
    set_connect_point( _to_node );

    /* Load the connection style */
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "style" ) {
          style.load_connection( it );
        }
      }
    }

    string? ti = node->get_prop( "title" );
    if( ti != null ) {
      _title = new CanvasText.with_text( da, ti );
      _title.set_font( style.node_font );
      position_title();
    }

  }

  /* Saves the connection information to the given XML node */
  public void save( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "connection" );
    n->set_prop( "from_id",      _from_node.id().to_string() );
    n->set_prop( "to_id",        _to_node.id().to_string() );
    n->set_prop( "drag_x",       _dragx.to_string() );
    n->set_prop( "drag_y",       _dragy.to_string() );

    if( title != null ) {
      n->set_prop( "title", title.text );
    }

    /* Save the style connection */
    style.save_connection( n );

    parent->add_child( n );

  }

  /* Draws the connection to the given context */
  public virtual void draw( Cairo.Context ctx, Theme theme ) {

    /* If either the from or to node is hidden, don't bother to draw ourselves */
    if( ((_from_node != null) && !_from_node.is_root() && _from_node.parent.folded) ||
        ((_to_node   != null) && !_to_node.is_root()   && _to_node.parent.folded) ) {
      return;
    }

    double start_x, start_y;
    double end_x,   end_y;
    double dragx = _dragx;
    double dragy = _dragy;
    RGBA   bg    = (mode == ConnMode.NONE) ? theme.background : theme.nodesel_background;

    if( _from_node == null ) {
      start_x = _posx;
      start_y = _posy;
    } else {
      _curve.get_from_point( out start_x, out start_y );
    }

    if( _to_node == null ) {
      end_x = _posx;
      end_y = _posy;
    } else {
      _curve.get_to_point( out end_x, out end_y );
    }

    /* The value of t is always 0.5 */
    RGBA   color = theme.connection_color;
    double cx, cy;

    /* Calclate the control points based on the calculated start/end points */
    cx = dragx - (((start_x + end_x) * 0.5) - dragx);
    cy = dragy - (((start_y + end_y) * 0.5) - dragy);

    /* Draw the curve */
    ctx.save();
    style.draw_connection( ctx );
    Utils.set_context_color( ctx, color );

    /* Draw the curve as a quadratic curve (saves some additional calculations) */
    ctx.move_to( start_x, start_y );
    ctx.curve_to(
      (((2.0 / 3.0) * cx) + ((1.0 / 3.0) * start_x)),
      (((2.0 / 3.0) * cy) + ((1.0 / 3.0) * start_y)),
      (((2.0 / 3.0) * cx) + ((1.0 / 3.0) * end_x)),
      (((2.0 / 3.0) * cy) + ((1.0 / 3.0) * end_y)),
      end_x, end_y
    );
    ctx.stroke();

    ctx.set_dash( {}, 0 );

    /* Draw the arrow */
    if( mode != ConnMode.SELECTED ) {
      if( (style.connection_arrow == "fromto") || (style.connection_arrow == "both") ) {
        draw_arrow( ctx, style.connection_width, end_x, end_y, cx, cy );
      }
      if( (style.connection_arrow == "tofrom") || (style.connection_arrow == "both") ) {
        draw_arrow( ctx, style.connection_width, start_x, start_y, cx, cy );
      }
    }

    /* Draw the connection title if it exists */
    if( title != null ) {

      draw_title( ctx, theme );

    /* Draw the drag circle */
    } else if( mode != ConnMode.NONE ) {
      ctx.set_line_width( 1 );
      ctx.set_source_rgba( bg.red, bg.green, bg.blue, bg.alpha );
      ctx.arc( dragx, dragy, RADIUS, 0, (2 * Math.PI) );
      ctx.fill_preserve();
      ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
      ctx.stroke();
    }

    /* If we are selected draw the endpoints */
    if( mode == ConnMode.SELECTED ) {

      ctx.set_source_rgba( bg.red, bg.green, bg.blue, bg.alpha );
      ctx.arc( start_x, start_y, RADIUS, 0, (2 * Math.PI) );
      ctx.fill_preserve();
      ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
      ctx.stroke();

      ctx.set_source_rgba( bg.red, bg.green, bg.blue, bg.alpha );
      ctx.arc( end_x, end_y, RADIUS, 0, (2 * Math.PI) );
      ctx.fill_preserve();
      ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
      ctx.stroke();

    }

    ctx.restore();

  }

  /* Returns the bounding box for the stored title (assumes the title is not null */
  private void title_bbox( out double x, out double y, out double w, out double h ) {
    x = _title.posx;
    y = _title.posy;
    w = _title.width;
    h = _title.height;
  }

  /*
   Draws the connection title if it has been enabled.
  */
  private void draw_title( Cairo.Context ctx, Theme theme ) {

    var    color   = theme.connection_color;
    var    fg      = theme.background;
    var    padding = _style.connection_padding ?? 0;
    double x, y, w, h;

    title_bbox( out x, out y, out w, out h );

    /* Draw the box */
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
    ctx.rectangle( (x - padding), (y - padding), (w + (padding * 2)), (h + (padding * 2)) );
    ctx.fill();

    /* Draw the text */
    _title.draw( ctx, theme, fg, _alpha );

    /* Draw the drag handle */
    if( (mode == ConnMode.SELECTED) || (mode == ConnMode.ADJUSTING) ) {

      RGBA bg = theme.nodesel_background;

      ctx.set_line_width( 1 );
      ctx.set_source_rgba( bg.red, bg.green, bg.blue, bg.alpha );
      ctx.arc( _dragx, (_dragy + (h / 2) + padding), RADIUS, 0, (2 * Math.PI) );
      ctx.fill_preserve();
      ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
      ctx.stroke();

    }

  }

  /*
   Draws arrow point to the "to" node.  The tailx/y values should be the
   bezier control point closest to the "to" node.
  */
  private static void draw_arrow( Cairo.Context ctx, int line_width, double tipx, double tipy,
                                  double tailx, double taily ) {

    double extlen[7] = {14, 14, 15, 16, 17, 18, 18};

    var arrowLength = extlen[line_width-2];

    var dx = tipx - tailx;
    var dy = tipy - taily;

    var theta = Math.atan2( dy, dx );

    var rad = 35 * (Math.PI / 180);  // 35 angle, can be adjusted
    var x1  = tipx - arrowLength * Math.cos( theta + rad );
    var y1  = tipy - arrowLength * Math.sin( theta + rad );

    var phi2 = -35 * (Math.PI / 180);  // -35 angle, can be adjusted
    var x2   = tipx - arrowLength * Math.cos( theta + phi2 );
    var y2   = tipy - arrowLength * Math.sin( theta + phi2 );

    /* Draw the arrow */
    ctx.set_line_width( 1 );
    ctx.move_to( tipx, tipy );
    ctx.line_to( x1, y1 );
    ctx.line_to( x2, y2 );
    ctx.close_path();
    ctx.fill();

  }

  /* Makes an icon for the given dash */
  public static Cairo.Surface make_arrow_icon( string type ) {

    Cairo.ImageSurface surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, 100, 20 );
    Cairo.Context      ctx     = new Cairo.Context( surface );

    ctx.set_source_rgba( 0.5, 0.5, 0.5, 1 );
    ctx.set_line_width( 4 );
    ctx.set_line_cap( LineCap.ROUND );
    ctx.move_to( 15, 10 );
    ctx.line_to( 85, 10 );
    ctx.stroke();

    if( (type == "fromto") || (type == "both") ) {
      draw_arrow( ctx, 4, 90, 10, 10, 10 );
    }
    if( (type == "tofrom") || (type == "both") ) {
      draw_arrow( ctx, 4, 10, 10, 90, 10 );
    }

    return( surface );

  }

}
