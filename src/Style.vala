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

  public LinkType?        link_type          { get; set; default = null; }
  public int?             link_width         { get; set; default = null; }
  public bool?            link_arrow         { get; set; default = null; }
  public LinkDash?        link_dash          { get; set; default = null; }
  public NodeBorder?      node_border        { get; set; default = null; }
  public int?             node_borderwidth   { get; set; default = null; }
  public bool?            node_fill          { get; set; default = null; }
  public int?             node_margin        { get; set; default = null; }
  public int?             node_padding       { get; set; default = null; }
  public FontDescription? node_font          { get; set; default = null; }
  public int?             node_width         { get; set; default = null; }
  public bool?            node_markup        { get; set; default = null; }
  public LinkDash?        connection_dash    { get; set; default = null; }
  public int?             connection_width   { get; set; default = null; }
  public string?          connection_arrow   { get; set; default = null; }
  public int?             connection_padding { get; set; default = null; }
  public FontDescription? connection_font    { get; set; default = null; }

  /* Default constructor */
  public Style() {

    _template = false;

    node_font = new FontDescription();
    node_font.set_family( "Sans" );
    node_font.set_size( 11 * Pango.SCALE );

    connection_font = new FontDescription();
    connection_font.set_family( "Sans" );
    connection_font.set_size( 10 * Pango.SCALE );

  }

  /* Constructor used for style templating */
  public Style.templated() {
    _template = true;
  }

  /* Returns true if the node assigned with this style can be filled with a color */
  public bool is_fillable() {
    return( node_fill && node_border.is_fillable() );
  }

  /* Clears this style template options */
  public void clear_template() {

    if( _template ) {
      link_type          = null;
      link_width         = null;
      link_arrow         = null;
      link_dash          = null;
      node_border        = null;
      node_borderwidth   = null;
      node_fill          = null;
      node_margin        = null;
      node_padding       = null;
      node_font          = null;
      node_width         = null;
      node_markup        = null;
      connection_dash    = null;
      connection_width   = null;
      connection_arrow   = null;
      connection_padding = null;
      connection_font    = null;
    }

  }

  /* Copies the given style to this style.  Returns true if the style changed; otherwise, returns false. */
  public bool copy( Style s ) {

    bool changed = false;

    if( ((s.link_type          != null) || !s._template) && (link_type          != s.link_type) )          { changed = true;  link_type          = s.link_type; }
    if( ((s.link_width         != null) || !s._template) && (link_width         != s.link_width) )         { changed = true;  link_width         = s.link_width; }
    if( ((s.link_arrow         != null) || !s._template) && (link_arrow         != s.link_arrow) )         { changed = true;  link_arrow         = s.link_arrow; }
    if( ((s.link_dash          != null) || !s._template) && (link_dash          != s.link_dash) )          { changed = true;  link_dash          = s.link_dash; }
    if( ((s.node_border        != null) || !s._template) && (node_border        != s.node_border) )        { changed = true;  node_border        = s.node_border; }
    if( ((s.node_borderwidth   != null) || !s._template) && (node_borderwidth   != s.node_borderwidth) )   { changed = true;  node_borderwidth   = s.node_borderwidth; }
    if( ((s.node_fill          != null) || !s._template) && (node_fill          != s.node_fill) )          { changed = true;  node_fill          = s.node_fill; }
    if( ((s.node_margin        != null) || !s._template) && (node_margin        != s.node_margin) )        { changed = true;  node_margin        = s.node_margin; }
    if( ((s.node_padding       != null) || !s._template) && (node_padding       != s.node_padding) )       { changed = true;  node_padding       = s.node_padding; }
    if( ((s.node_font          != null) || !s._template) )                                                 { changed = true;  node_font          = s.node_font.copy(); }
    if( ((s.node_width         != null) || !s._template) && (node_width         != s.node_width) )         { changed = true;  node_width         = s.node_width; }
    if( ((s.node_markup        != null) || !s._template) && (node_markup        != s.node_markup) )        { changed = true;  node_markup        = s.node_markup; }
    if( ((s.connection_dash    != null) || !s._template) && (connection_dash    != s.connection_dash) )    { changed = true;  connection_dash    = s.connection_dash; }
    if( ((s.connection_width   != null) || !s._template) && (connection_width   != s.connection_width) )   { changed = true;  connection_width   = s.connection_width; }
    if( ((s.connection_arrow   != null) || !s._template) && (connection_arrow   != s.connection_arrow) )   { changed = true;  connection_arrow   = s.connection_arrow; }
    if( ((s.connection_padding != null) || !s._template) && (connection_padding != s.connection_padding) ) { changed = true;  connection_padding = s.connection_padding; }
    if( ((s.connection_font    != null) || !s._template) )                                                 { changed = true;  connection_font    = s.connection_font.copy(); }

    return( changed );

  }

  public string to_string() {
    string[] arr = {};
    if( link_type          != null ) arr += "ltype[%s]".printf( link_type.name() );
    if( link_width         != null ) arr += "lwidth[%d]".printf( link_width );
    if( link_arrow         != null ) arr += "larrow[%s]".printf( link_arrow.to_string() );
    if( link_dash          != null ) arr += "ldash[%s]".printf( link_dash.name );
    if( node_border        != null ) arr += "nborder[%s]".printf( node_border.name() );
    if( node_borderwidth   != null ) arr += "nbwidth[%d]".printf( node_borderwidth );
    if( node_fill          != null ) arr += "nfill[%s]".printf( node_fill.to_string() );
    if( node_margin        != null ) arr += "nmargin[%d]".printf( node_margin );
    if( node_padding       != null ) arr += "npad[%d]".printf( node_padding );
    if( node_font          != null ) arr += "nfont";
    if( node_width         != null ) arr += "nwidth[%d]".printf( node_width );
    if( node_markup        != null ) arr += "nmarkup[%s]".printf( node_markup.to_string() );
    if( connection_dash    != null ) arr += "cdash[%s]".printf( connection_dash.name );
    if( connection_width   != null ) arr += "cwidth[%d]".printf( connection_width );
    if( connection_arrow   != null ) arr += "carrow[%s]".printf( connection_arrow );
    if( connection_padding != null ) arr += "cpad[%d]".printf( connection_padding );
    if( connection_font    != null ) arr += "cfont";
    return( string.joinv( "+", arr ) );
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
    string? p = node->get_prop( "connectionpadding" );
    if( p != null ) {
      connection_padding = int.parse( p );
    }
    string? f = node->get_prop( "connectionfont" );
    if( f != null ) {
      connection_font = FontDescription.from_string( f );
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
    if( connection_padding != null ) {
      n->set_prop( "connectionpadding", connection_padding.to_string() );
    }
    if( connection_font != null ) {
      n->set_prop( "connectionfont", connection_font.to_string() );
    }

  }

  /* Stores this style in XML format */
  public void save_connection( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "style" );
    save_connection_in_node( n );
    parent->add_child( n );

  }

  /* Draws the link with the given information, applying the stored styling */
  public void draw_link( Cairo.Context ctx, Style parent_style, Node to_node,
                         double from_x, double from_y, double to_x, double to_y,
                         out double tailx, out double taily, out double tipx, out double tipy ) {

    ctx.save();
    ctx.set_line_width( link_width );
    link_dash.set_context( ctx, link_width );
    parent_style.link_type.draw( ctx, to_node, from_x, from_y, to_x, to_y, out tailx, out taily, out tipx, out tipy );
    ctx.restore();

  }

  /* Draws the shape behind a node with the given dimensions and stored styling */
  public void draw_node_border( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s ) {

    ctx.save();
    ctx.set_line_width( node_borderwidth );
    node_border.draw_border( ctx, x, y, w, h, s );
    ctx.restore();

  }

  /* Draws the node fill */
  public void draw_node_fill( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s ) {

    node_border.draw_fill( ctx, x, y, w, h, s );

  }

  /* Sets up the given context to draw the stylized connection */
  public void draw_connection( Cairo.Context ctx ) {

    ctx.set_line_width( connection_width );
    connection_dash.set_context( ctx, connection_width );

  }

}
