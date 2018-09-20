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

public class Connection {

  private Node?  _from_node = null;
  private Node?  _to_node   = null;
  private double _posx;
  private double _posy;

  public string title { get; set; default = ""; }

  /* Default constructor */
  public Connection( Node from_node ) {
    _from_node = from_node;
    get_connect_point( from_node, out _posx, out _posy );
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
    _to_node = to_node;
  }

  /* Draws the connections to the given point */
  public void draw_to( double x, double y ) {
    _posx = x;
    _posy = y;
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
    n->set_prop( "title",   title );
    parent->add_child( n );

  }

  /* Draws the connection to the given context */
  public virtual void draw( Cairo.Context ctx, Theme theme ) {

    double start_x, start_y;
    double end_x,   end_y;

    get_connect_point( _from_node, out start_x, out start_y );

    RGBA   color   = theme.connection_color;
    
    if( _to_node == null ) {
      end_x = _posx;
      end_y = _posy;
    } else {
      get_connect_point( _to_node, out end_x, out end_y );
    }

    ctx.set_line_width( 2 );
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
    ctx.set_dash( {15, 5}, 0 );
    ctx.move_to( start_x, start_y );
    ctx.line_to( end_x, end_y );

  }

}
