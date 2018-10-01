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

/* Connection mode value for the Connection.mode property */
public enum ConnMode {
  NONE = 0,    // Normally drawn mode
  CONNECTING,  // Indicates that the connection is being made between two nodes
  SELECTED,    // Indicates that the connection is currently selected
  ADJUSTING    // Indicates that we are moving the drag handle to change the line shape
}

public class Connection {

  private Node?   _from_node = null;
  private Node?   _to_node   = null;
  private double  _posx;
  private double  _posy;
  private double  _dragx;
  private double  _dragy;
  private double? _last_fx = null;
  private double? _last_fy = null;
  private double? _last_tx = null;
  private double? _last_ty = null;
  private Style   _style   = new Style();

  public string   title { get; set; default = ""; }
<<<<<<< HEAD
  public ConnMode mode  { get; set; default = ConnMode.CONNECTING; }
  public Style    style { get; set; default = new Style(); }
=======
  public ConnMode mode  { get; set; default = ConnMode.NONE; }
  public Style    style { 
    get {
      return( _style );
    }
    set {
      _style.copy( value );
    }
  }
>>>>>>> 54d53469fef6c8251e20ca85b4cd4bee2e9de275

  /* Default constructor */
  public Connection( Node from_node ) {
    _from_node = from_node;
    get_connect_point( from_node, out _posx, out _posy );
    _dragx = _posx;
    _dragy = _posy;
    style  = StyleInspector.styles.get_global_style();
  }

  /* Constructor from XML data */
  public Connection.from_xml( DrawArea da, Xml.Node* n ) {
    style = StyleInspector.styles.get_global_style();
    load( da, n );
  }

  /* Returns the point to add the connection to based on the node */
  private void get_connect_point( Node node, out double cx, out double cy ) {
    double x, y, w, h;
    node.bbox( out x, out y, out w, out h );
    /* TEMPORARY - This needs to be more robust */
    if( node == _from_node ) {
      cx = x + (w / 2);
      cy = y;
    } else {
      cx = x + (w / 2);
      cy = y + h;
    }
  }

  /* Completes the connection */
  public void connect_to( Node node ) {
    double fx, fy, tx, ty;
    if( _from_node == null ) {
      get_connect_point( _to_node, out tx, out ty );
      get_connect_point( node,     out fx, out fy );
      _from_node = node;
    } else {
      get_connect_point( _from_node, out fx, out fy );
      get_connect_point( node,       out tx, out ty );
      _to_node = node;
    }
    _dragx = (fx + tx) / 2;
    _dragy = (fy + ty) / 2;
  }

  /* Draws the connections to the given point */
  public void draw_to( double x, double y ) {
    double nx, ny;
    _posx = x;
    _posy = y;
    if( _from_node == null ) {
      get_connect_point( _to_node, out nx, out ny );
    } else {
      get_connect_point( _from_node, out nx, out ny );
    }
    _dragx = (nx + x) / 2;
    _dragy = (ny + y) / 2;
  }

  /* Returns true if the given point is within the drag handle */
  public bool within_drag_handle( double x, double y ) {
    return( ((_dragx - 3) <= x) && (x <= (_dragx + 3)) && ((_dragy - 3) <= y) && (y <= (_dragy + 3)) );
  }

  /* Returns true if the given point lies within the from connection handle */
  public bool within_from_handle( double x, double y ) {
    return( within_handle( _from_node, x, y ) );
  }

  /* Returns true if the given point lies within the from connection handle */
  public bool within_to_handle( double x, double y ) {
    return( within_handle( _to_node, x, y ) );
  }

  /* Updates the location of the drag handle */
  public void move_drag_handle( double x, double y ) {
    mode   = ConnMode.ADJUSTING;
    _dragx = x;
    _dragy = y;
  }

  /* Updates the location of dragx/dragy based on the amount of canvas pan */
  public void pan( double diff_x, double diff_y ) {
    _dragx -= diff_x;
    _dragy -= diff_y;
  }

  /* Returns true if the given point lies within the from connection handle */
  private bool within_handle( Node node, double x, double y ) {
    if( mode == ConnMode.SELECTED ) {
      double fx, fy;
      get_connect_point( node, out fx, out fy );
      return( ((fx - 3) <= x) && (x <= (fx + 3)) && ((fy - 3) <= y) && (y <= (fy + 3)) );
    }
    return( false );
  }

  /* Loads the connection information */
  private void load( DrawArea da, Xml.Node* node ) {

    string? f = node->get_prop( "from_id" );
    if( f != null ) {
      _from_node = da.get_node( int.parse( f ) );
    }

    string? t = node->get_prop( "to_id" );
    if( t != null ) {
      _to_node = da.get_node( int.parse( t ) );
    }

    string? x = node->get_prop( "drag_x" );
    if( x != null ) {
      _dragx = double.parse( x );
    }

    string? y = node->get_prop( "drag_y" );
    if( y != null ) {
      _dragy = double.parse( y );
    }

    string? ti = node->get_prop( "title" );
    if( ti != null ) {
      title = ti;
    }

    /* Load the connection style */
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "style" ) {
          style.load_connection( it );
        }
      }
    }

  }

  /* Saves the connection information to the given XML node */
  public void save( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "connection" );
    n->set_prop( "from_id", _from_node.id().to_string() );
    n->set_prop( "to_id",   _to_node.id().to_string() );
    n->set_prop( "drag_x",  _dragx.to_string() );
    n->set_prop( "drag_y",  _dragy.to_string() );
    n->set_prop( "title",   title );

    /* Save the style connection */
    style.save_connection( n );

    parent->add_child( n );

  }

  /*
   Checks to see if this connection is attached to the given node.  If it is,
   save the location of the node as it will be moved to a new position.
  */
  public void check_for_connection_to_node( Node node ) {
    _last_fx = _last_fy = _last_tx = _last_ty = null;
    if( _from_node == node ) {
      get_connect_point( _from_node, out _last_fx, out _last_fy );
      if( _to_node != null ) {
        get_connect_point( _to_node, out _last_tx, out _last_ty );
      }
    } else if( _to_node == node ) {
      get_connect_point( _to_node, out _last_tx, out _last_ty );
      if( _from_node != null ) {
        get_connect_point( _from_node, out _last_fx, out _last_fy );
      }
    }
  }

  /* Draws the connection to the given context */
  public virtual void draw( Cairo.Context ctx, Theme theme ) {

    double start_x, start_y;
    double end_x,   end_y;
    double dragx = _dragx;
    double dragy = _dragy;

    get_connect_point( _from_node, out start_x, out start_y );

    if( _to_node == null ) {
      end_x = _posx;
      end_y = _posy;
    } else {
      get_connect_point( _to_node, out end_x, out end_y );
    }

    /* Calculate the difference between the from and end values */
    if( (_last_fx != null) && (_last_tx != null) ) {
      dragx += ((start_x - _last_fx) + (end_x - _last_tx));
      dragy += ((start_y - _last_fy) + (end_y - _last_ty));
    }

    /* The value of t is always 0.5 */
    var color = theme.connection_color;
    var ax    = dragx - (((start_x + end_x) * 0.5) - dragx);
    var ay    = dragy - (((start_y + end_y) * 0.5) - dragy);

    /* Draw the curve */
    ctx.save();
    style.draw_connection( ctx );
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );

    /* Draw the curve as a quadratic curve (saves some additional calculations) */
    ctx.move_to( start_x, start_y );
    ctx.curve_to(
      (((2.0 / 3.0) * ax) + ((1.0 / 3.0) * start_x)),
      (((2.0 / 3.0) * ay) + ((1.0 / 3.0) * start_y)),
      (((2.0 / 3.0) * ax) + ((1.0 / 3.0) * end_x)),
      (((2.0 / 3.0) * ay) + ((1.0 / 3.0) * end_y)),
      end_x, end_y
    );
    ctx.stroke();

    /* Draw the arrow */
    if( mode != ConnMode.SELECTED ) {
      draw_arrow( ctx, color, end_x, end_y, ax, ay );
    }

    /* Draw the drag circle */
    ctx.arc( dragx, dragy, 6, 0, (2 * Math.PI) );
    ctx.fill();

    /* If we are selected draw the endpoints */
    if( mode == ConnMode.SELECTED ) {
      ctx.arc( start_x, start_y, 6, 0, (2 * Math.PI) );
      ctx.fill();
      ctx.arc( end_x, end_y, 6, 0, (2 * Math.PI) );
      ctx.fill();
    }

    ctx.restore();

  }

  /*
   Draws arrow point to the "to" node.  The tailx/y values should be the
   bezier control point closest to the "to" node.
  */
  protected virtual void draw_arrow( Cairo.Context ctx, RGBA color, double tipx, double tipy, double tailx, double taily ) {

    var arrowLength = 10; // can be adjusted
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

}
