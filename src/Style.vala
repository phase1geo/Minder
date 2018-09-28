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
  public NodeBorder      node_border      { get; set; }
  public int             node_width       { get; set; }
  public int             node_borderwidth { get; set; }
  public FontDescription node_font        { get; set; }

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
    node_border      = s.node_border;
    node_width       = s.node_width;
    node_borderwidth = s.node_borderwidth;
    node_font        = s.node_font.copy();
  }

  /* Loads the style information in the given XML node */
  public void load( Xml.Node* node ) {

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

  /* Stores this style in XML format */
  public void save( Xml.Node* parent ) {
    Xml.Node* n = new Xml.Node( null, "style" );
    n->set_prop( "link_type",        link_type.name() );
    n->set_prop( "link_width",       link_width.to_string() );
    n->set_prop( "link_arrow",       link_arrow.to_string() );
    n->set_prop( "node_border",      node_border.name() );
    n->set_prop( "node_width",       node_width.to_string() );
    n->set_prop( "node_borderwidth", node_borderwidth.to_string() );
    n->set_prop( "node_font",        node_font.to_string() );
    parent->add_child( n );
  }

  /* Draws the link with the given information, applying the stored styling */
  public void draw_link( Cairo.Context ctx, double from_x, double from_y, double to_x, double to_y, bool horizontal,
                         out double fx, out double fy, out double tx, out double ty ) {
    ctx.set_line_width( link_width );
    link_type.draw( ctx, from_x, from_y, to_x, to_y, horizontal, out fx, out fy, out tx, out ty );
  }

  /* Draws the shape behind a node with the given dimensions and stored styling */
  public void draw_border( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s ) {
    ctx.set_line_width( node_borderwidth );
    node_border.draw_border( ctx, x, y, w, h, s );
  }

  /* Draws the node fill */
  public void draw_fill( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s ) {
    node_border.draw_fill( ctx, x, y, w, h, s );
  }

}