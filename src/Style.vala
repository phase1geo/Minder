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

using Pango;

public class Style {

  public LinkType        link_type        { get; set; }
  public int             link_width       { get; set; }
  public bool            link_arrow       { get; set; }
  public LinkDash        link_dash        { get; set; }
  public NodeBorder      node_border      { get; set; }
  public int             node_width       { get; set; }
  public int             node_borderwidth { get; set; }
  public FontDescription node_font        { get; set; }
  public LinkDash        connection_dash  { get; set; }
  public int             connection_width { get; set; }

  public Style() {
    node_font = new FontDescription();
    node_font.set_family( "Sans" );
    node_font.set_size( 11 * Pango.SCALE );
  }

  /* Copies the given style to this style */
  public void copy( Style s ) {
    link_type        = s.link_type;
    link_width       = s.link_width;
    link_arrow       = s.link_arrow;
    link_dash        = s.link_dash;
    node_border      = s.node_border;
    node_width       = s.node_width;
    node_borderwidth = s.node_borderwidth;
    node_font        = s.node_font.copy();
    connection_dash  = s.connection_dash;
    connection_width = s.connection_width;
  }

  /* Loads the style information in the given XML node */
  public void load_node( Xml.Node* node ) {

    string? lt = node->get_prop( "link_type" );
    if( lt != null ) {
      link_type = StyleInspector.styles.get_link_type( lt );
    }
    string? lw = node->get_prop( "link_width" );
    if( lw != null ) {
      link_width = int.parse( lw );
    }
    string? la = node->get_prop( "link_arrow" );
    if( la != null ) {
      link_arrow = bool.parse( la );
    }
    string? ld = node->get_prop( "link_dash" );
    if( ld != null ) {
      link_dash = StyleInspector.styles.get_link_dash( ld );
    }

    string? nb = node->get_prop( "node_border" );
    if( nb != null ) {
      node_border = StyleInspector.styles.get_node_border( nb );
    }
    string? nw = node->get_prop( "node_width" );
    if( nw != null ) {
      node_width = int.parse( nw );
    }
    string? nbw = node->get_prop( "node_borderwidth" );
    if( nbw != null ) {
      node_borderwidth = int.parse( nbw );
    }
    string? nf = node->get_prop( "node_font" );
    if( nf != null ) {
      node_font = FontDescription.from_string( nf );
    }

  }

  /* Loads the style information in the given XML node */
  public void load_connection( Xml.Node* node ) {

    string? d = node->get_prop( "dash" );
    if( d != null ) {
      connection_dash = StyleInspector.styles.get_link_dash( d );
    }
    string? w = node->get_prop( "width" );
    if( w != null ) {
      connection_width = int.parse( w );
    }

  }

  /* Stores this style in XML format */
  public void save_node( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "style" );

    n->set_prop( "link_type",        link_type.name() );
    n->set_prop( "link_width",       link_width.to_string() );
    n->set_prop( "link_arrow",       link_arrow.to_string() );
    n->set_prop( "link_dash",        link_dash.name );

    n->set_prop( "node_border",      node_border.name() );
    n->set_prop( "node_width",       node_width.to_string() );
    n->set_prop( "node_borderwidth", node_borderwidth.to_string() );
    n->set_prop( "node_font",        node_font.to_string() );

    parent->add_child( n );

  }

  /* Stores this style in XML format */
  public void save_connection( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "style" );

    n->set_prop( "dash",  connection_dash.name );
    n->set_prop( "width", connection_width.to_string() );

    parent->add_child( n );

  }

  /* Draws the link with the given information, applying the stored styling */
  public void draw_link( Cairo.Context ctx, double from_x, double from_y, double to_x, double to_y, bool horizontal,
                         out double tailx, out double taily, out double tipx, out double tipy ) {
    ctx.save();
    ctx.set_line_width( link_width );
    link_dash.set_context( ctx, link_width );
    link_type.draw( ctx, from_x, from_y, to_x, to_y, horizontal, out tailx, out taily, out tipx, out tipy );
    ctx.restore();
  }

  /* Draws the shape behind a node with the given dimensions and stored styling */
  public void draw_border( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s ) {
    ctx.save();
    ctx.set_line_width( node_borderwidth );
    node_border.draw_border( ctx, x, y, w, h, s );
    ctx.restore();
  }

  /* Draws the node fill */
  public void draw_fill( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s ) {
    node_border.draw_fill( ctx, x, y, w, h, s );
  }

  /* Sets up the given context to draw the stylized connection */
  public void draw_connection( Cairo.Context ctx ) {
    stdout.printf( "In draw_connection, width: %d\n", connection_width );
    ctx.set_line_width( connection_width );
    connection_dash.set_context( ctx, connection_width );
  }

}
