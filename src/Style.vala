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

  private bool _template;

  public LinkType?        link_type        { get; set; default = null; }
  public int?             link_width       { get; set; default = null; }
  public bool?            link_arrow       { get; set; default = null; }
  public LinkDash?        link_dash        { get; set; default = null; }
  public NodeBorder?      node_border      { get; set; default = null; }
  public int?             node_width       { get; set; default = null; }
  public int?             node_borderwidth { get; set; default = null; }
  public bool?            node_fill        { get; set; default = null; }
  public int?             node_margin      { get; set; default = null; }
  public int?             node_padding     { get; set; default = null; }
  public FontDescription? node_font        { get; set; default = null; }
  public bool?            node_markup      { get; set; default = null; }
  public LinkDash?        connection_dash  { get; set; default = null; }
  public int?             connection_width { get; set; default = null; }
  public string?          connection_arrow { get; set; default = null; }

  /* Default constructor */
  public Style() {

    _template = false;

    node_font = new FontDescription();
    node_font.set_family( "Sans" );
    node_font.set_size( 11 * Pango.SCALE );

  }

  /* Constructor used for style templating */
  public Style.templated() {
    _template = true;
  }

  /* Returns true if the node assigned with this style can be filled with a color */
  public bool is_fillable() {
    return( node_fill && node_border.is_fillable() );
  }

  /* Creates a font for a templated style */
  public void set_template_font( string family, int size ) {

    node_font = new FontDescription();
    node_font.set_family( family );
    node_font.set_size( size * Pango.SCALE );

  }

  /* Clears this style template options */
  public void clear_template() {

    if( _template ) {
      link_type        = null;
      link_width       = null;
      link_arrow       = null;
      link_dash        = null;
      node_border      = null;
      node_width       = null;
      node_borderwidth = null;
      node_fill        = null;
      node_margin      = null;
      node_padding     = null;
      node_font        = null;
      node_markup      = null;
      connection_dash  = null;
      connection_width = null;
      connection_arrow = null;
    }

  }

  /* Copies the given style to this style */
  public void copy( Style s ) {

    if( (s.link_type        != null) || !s._template ) link_type        = s.link_type;
    if( (s.link_width       != null) || !s._template ) link_width       = s.link_width;
    if( (s.link_arrow       != null) || !s._template ) link_arrow       = s.link_arrow;
    if( (s.link_dash        != null) || !s._template ) link_dash        = s.link_dash;
    if( (s.node_border      != null) || !s._template ) node_border      = s.node_border;
    if( (s.node_width       != null) || !s._template ) node_width       = s.node_width;
    if( (s.node_borderwidth != null) || !s._template ) node_borderwidth = s.node_borderwidth;
    if( (s.node_fill        != null) || !s._template ) node_fill        = s.node_fill;
    if( (s.node_margin      != null) || !s._template ) node_margin      = s.node_margin;
    if( (s.node_padding     != null) || !s._template ) node_padding     = s.node_padding;
    if( (s.node_font        != null) || !s._template ) node_font        = s.node_font.copy();
    if( (s.node_markup      != null) || !s._template ) node_markup      = s.node_markup;
    if( (s.connection_dash  != null) || !s._template ) connection_dash  = s.connection_dash;
    if( (s.connection_width != null) || !s._template ) connection_width = s.connection_width;
    if( (s.connection_arrow != null) || !s._template ) connection_arrow = s.connection_arrow;

  }

  /* Loads the style information in the given XML node */
  public void load_node( Xml.Node* node ) {

    string? lt = node->get_prop( "linktype" );
    if( lt != null ) {
      link_type = StyleInspector.styles.get_link_type( lt );
    }
    string? lw = node->get_prop( "linkwidth" );
    if( lw != null ) {
      link_width = int.parse( lw );
    }
    string? la = node->get_prop( "linkarrow" );
    if( la != null ) {
      link_arrow = bool.parse( la );
    }
    string? ld = node->get_prop( "linkdash" );
    if( ld != null ) {
      link_dash = StyleInspector.styles.get_link_dash( ld );
    }

    string? nb = node->get_prop( "nodeborder" );
    if( nb != null ) {
      node_border = StyleInspector.styles.get_node_border( nb );
    }
    string? nw = node->get_prop( "nodewidth" );
    if( nw != null ) {
      node_width = int.parse( nw );
    }
    string? nbw = node->get_prop( "nodeborderwidth" );
    if( nbw != null ) {
      node_borderwidth = int.parse( nbw );
    }
    string? nlf = node->get_prop( "nodefill" );
    if( nlf != null ) {
      node_fill = bool.parse( nlf );
    }
    string? nm = node->get_prop( "nodemargin" );
    if( nm != null ) {
      node_margin = int.parse( nm );
    }
    string? np = node->get_prop( "nodepadding" );
    if( np != null ) {
      node_padding = int.parse( np );
    }
    string? nf = node->get_prop( "nodefont" );
    if( nf != null ) {
      node_font = FontDescription.from_string( nf );
    }
    string? nmu = node->get_prop( "nodemarkup" );
    if( nmu != null ) {
      node_markup = bool.parse( nmu );
    }

  }

  /* Loads the style information in the given XML node */
  public void load_connection( Xml.Node* node ) {

    string? d = node->get_prop( "connectiondash" );
    if( d != null ) {
      connection_dash = StyleInspector.styles.get_link_dash( d );
    }
    string? w = node->get_prop( "connectionwidth" );
    if( w != null ) {
      connection_width = int.parse( w );
    }
    string? a = node->get_prop( "connectionarrow" );
    if( a != null ) {
      connection_arrow = a;
    }

  }

  public void save_node_in_node( Xml.Node* n ) {

    if( link_type != null ) {
      n->set_prop( "linktype", link_type.name() );
    }
    if( link_width != null ) {
      n->set_prop( "linkwidth", link_width.to_string() );
    }
    if( link_arrow != null ) {
      n->set_prop( "linkarrow", link_arrow.to_string() );
    }
    if( link_dash != null ) {
      n->set_prop( "linkdash", link_dash.name );
    }

    if( node_border != null ) {
      n->set_prop( "nodeborder", node_border.name() );
    }
    if( node_width != null ) {
      n->set_prop( "nodewidth", node_width.to_string() );
    }
    if( node_borderwidth != null ) {
      n->set_prop( "nodeborderwidth", node_borderwidth.to_string() );
    }
    if( node_fill != null ) {
      n->set_prop( "nodefill", node_fill.to_string() );
    }
    if( node_margin != null ) {
      n->set_prop( "nodemargin", node_margin.to_string() );
    }
    if( node_padding != null ) {
      n->set_prop( "nodepadding", node_padding.to_string() );
    }
    if( node_font != null ) {
      n->set_prop( "nodefont", node_font.to_string() );
    }
    if( node_markup != null ) {
      n->set_prop( "nodemarkup", node_markup.to_string() );
    }

  }

  /* Stores this style in XML format */
  public void save_node( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "style" );
    save_node_in_node( n );
    parent->add_child( n );

  }

  public void save_connection_in_node( Xml.Node* n ) {

    if( connection_dash != null ) {
      n->set_prop( "connectiondash",  connection_dash.name );
    }
    if( connection_width != null ) {
      n->set_prop( "connectionwidth", connection_width.to_string() );
    }
    if( connection_arrow != null ) {
      n->set_prop( "connectionarrow", connection_arrow );
    }

  }

  /* Stores this style in XML format */
  public void save_connection( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "style" );
    save_connection_in_node( n );
    parent->add_child( n );

  }

  /* Draws the link with the given information, applying the stored styling */
  public void draw_link( Cairo.Context ctx, Style parent_style, double from_x, double from_y,
                         double to_x, double to_y, bool horizontal,
                         out double tailx, out double taily, out double tipx, out double tipy ) {

    ctx.save();
    ctx.set_line_width( link_width );
    link_dash.set_context( ctx, link_width );
    parent_style.link_type.draw( ctx, from_x, from_y, to_x, to_y, horizontal, out tailx, out taily, out tipx, out tipy );
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

    ctx.set_line_width( connection_width );
    connection_dash.set_context( ctx, connection_width );

  }

}
