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
  NONE = 0,  // Normally drawn mode
  SELECTED   // Indicates that the connection is currently selected
}

public class Connection {

  private Node?    _from_node = null;
  private Node?    _to_node   = null;
  private double   _posx;
  private double   _posy;
  private double   _dragx;
  private double   _dragy;

  public string   title { get; set; default = ""; }
  public ConnMode mode  { get; set; default = ConnMode.NONE; }

  /* Default constructor */
  public Connection( Node from_node ) {
    _from_node = from_node;
    get_connect_point( from_node, out _posx, out _posy );
    _dragx = _posx;
    _dragy = _posy;
  }

  /* Constructor from XML data */
  public Connection.from_xml( DrawArea da, Xml.Node* n ) {
    load( da, n );
  }

  /* Returns the point to add the connection to based on the node */
  private void get_connect_point( Node node, out double cx, out double cy ) {
    double x, y, w, h;
    node.bbox( out x, out y, out w, out h );
    cx = x + w;
    cy = y + (h / 2);
  }

  /* Completes the connection */
  public void connect_to( Node to_node ) {
    double fx, fy, tx, ty;
    get_connect_point( _from_node, out fx, out fy );
    get_connect_point( _to_node,   out tx, out ty );
    _to_node = to_node;
    _dragx   = (fx + tx) / 2;
    _dragy   = (fy + ty) / 2;
  }

  /* Draws the connections to the given point */
  public void draw_to( double x, double y ) {
    double fx, fy;
    get_connect_point( _from_node, out fx, out fy );
    _posx  = x;
    _posy  = y;
    _dragx = (fx + x) / 2;
    _dragy = (fy + y) / 2;
  }

  /* Returns true if the given point is within the drag handle */
  public bool within_drag_handle( double x, double y ) {
    return( ((_dragx - 4) <= x) && (x <= (_dragx + 4)) && ((_dragy - 4) <= y) && (y <= (_dragy + 4)) );
  }

  /* Returns true if the given point lies within the from connection handle */
  public bool within_from_handle( double x, double y ) {
    return( within_handle( _from_node, x, y ) );
  }

  /* Returns true if the given point lies within the from connection handle */
  public bool within_to_handle( double x, double y ) {
    return( within_handle( _to_node, x, y ) );
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

  }

  /* Saves the connection information to the given XML node */
  public void save( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "connection" );
    n->set_prop( "from_id", _from_node.id().to_string() );
    n->set_prop( "to_id",   _to_node.id().to_string() );
    n->set_prop( "drag_x",  _dragx.to_string() );
    n->set_prop( "drag_y",  _dragy.to_string() );
    n->set_prop( "title",   title );
    parent->add_child( n );

  }

  /* Draws the connection to the given context */
  public virtual void draw( Cairo.Context ctx, Theme theme ) {

    double start_x, start_y;
    double end_x,   end_y;

    get_connect_point( _from_node, out start_x, out start_y );

    if( _to_node == null ) {
      end_x = _posx;
      end_y = _posy;
    } else {
      get_connect_point( _to_node, out end_x, out end_y );
    }

    var color = theme.connection_color;
    
    /* Draw the curve */
    ctx.set_line_width( 2 );
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );

    ctx.save();
    ctx.set_dash( {15, 5}, 0 );
    ctx.move_to( start_x, start_y );
    ctx.curve_to( start_x, start_y, ((start_x + end_x) / 2), ((start_y + end_y) / 2), end_x, end_y );
    ctx.stroke();

    /* Draw the circle at the midpoint */
    ctx.arc( _dragx, _dragy, 8, 0, (2 * Math.PI) );
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

}
