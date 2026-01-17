/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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

  public int?             branch_margin          { get; set; default = null; }
  public int?             branch_radius          { get; set; default = null; }
  public LinkType?        link_type              { get; set; default = null; }
  public int?             link_width             { get; set; default = null; }
  public bool?            link_arrow             { get; set; default = null; }
  public int?             link_arrow_size        { get; set; default = null; }
  public LinkDash?        link_dash              { get; set; default = null; }
  public NodeBorder?      node_border            { get; set; default = null; }
  public int?             node_borderwidth       { get; set; default = null; }
  public bool?            node_fill              { get; set; default = null; }
  public int              node_margin            { get; set; default = 0; }
  public int              node_padding           { get; set; default = 0; }
  public FontDescription? node_font              { get; set; default = null; }
  public Pango.Alignment? node_text_align        { get; set; default = null; }
  public int?             node_width             { get; set; default = null; }
  public bool?            node_markup            { get; set; default = null; }
  public LinkDash?        connection_dash        { get; set; default = null; }
  public int?             connection_line_width  { get; set; default = null; }
  public string?          connection_arrow       { get; set; default = null; }
  public int?             connection_arrow_size  { get; set; default = null; }
  public int?             connection_padding     { get; set; default = null; }
  public FontDescription? connection_font        { get; set; default = null; }
  public Pango.Alignment? connection_text_align  { get; set; default = null; }
  public int?             connection_title_width { get; set; default = null; }
  public FontDescription? callout_font           { get; set; default = null; }
  public Pango.Alignment? callout_text_align     { get; set; default = null; }
  public int?             callout_padding        { get; set; default = null; }
  public int?             callout_ptr_width      { get; set; default = null; }
  public int?             callout_ptr_length     { get; set; default = null; }

  //-------------------------------------------------------------
  // Default constructor.
  public Style() {

    _template = false;

    node_font = new FontDescription();
    node_font.set_family( "Sans" );
    node_font.set_size( 11 * Pango.SCALE );

    connection_font = new FontDescription();
    connection_font.set_family( "Sans" );
    connection_font.set_size( 10 * Pango.SCALE );

    callout_font = new FontDescription();
    callout_font.set_family( "Sans" );
    callout_font.set_size( 12 * Pango.SCALE );

  }

  //-------------------------------------------------------------
  // Constructor used for style templating.
  public Style.templated() {
    _template = true;
  }

  //-------------------------------------------------------------
  // Returns true if the node assigned with this style can be
  // filled with a color.
  public bool is_fillable() {
    return( node_fill && node_border.is_fillable() );
  }

  //-------------------------------------------------------------
  // Clears this style template options.
  public void clear_template() {

    if( _template ) {
      branch_margin          = null;
      branch_radius          = null;
      link_type              = null;
      link_width             = null;
      link_arrow             = null;
      link_arrow_size        = null;
      link_dash              = null;
      node_border            = null;
      node_borderwidth       = null;
      node_fill              = null;
      node_margin            = 0;
      node_padding           = 0;
      node_font              = null;
      node_text_align        = null;
      node_width             = null;
      node_markup            = null;
      connection_dash        = null;
      connection_line_width  = null;
      connection_arrow       = null;
      connection_arrow_size  = null;
      connection_padding     = null;
      connection_font        = null;
      connection_text_align  = null;
      connection_title_width = null;
      callout_font           = null;
      callout_text_align     = null;
      callout_padding        = null;
      callout_ptr_width      = null;
      callout_ptr_length     = null;
    }

  }

  //-------------------------------------------------------------
  // Copies the node branch style fields.
  public bool copy_node_branch( Style s ) {
    bool changed = false; 
    if( ((s.branch_margin != null) || !s._template) && (branch_margin != s.branch_margin) ) { changed = true;  branch_margin = s.branch_margin; }
    if( ((s.branch_radius != null) || !s._template) && (branch_radius != s.branch_radius) ) { changed = true;  branch_radius = s.branch_radius; }
    return( changed );
  }

  //-------------------------------------------------------------
  // Copies the node link style fields.
  public bool copy_node_link( Style s ) {
    bool changed = false;
    if( ((s.link_type       != null) || !s._template) && (link_type       != s.link_type) )       { changed = true;  link_type       = s.link_type; }
    if( ((s.link_width      != null) || !s._template) && (link_width      != s.link_width) )      { changed = true;  link_width      = s.link_width; }
    if( ((s.link_arrow      != null) || !s._template) && (link_arrow      != s.link_arrow) )      { changed = true;  link_arrow      = s.link_arrow; }
    if( ((s.link_arrow_size != null) || !s._template) && (link_arrow_size != s.link_arrow_size) ) { changed = true;  link_arrow_size = s.link_arrow_size; }
    if( ((s.link_dash       != null) || !s._template) && (link_dash       != s.link_dash) )       { changed = true;  link_dash       = s.link_dash; }
    return( changed );
  }

  //-------------------------------------------------------------
  // Copies the node body style fields.
  public bool copy_node_body( Style s ) {
    bool changed = false;
    if( ((s.node_border      != null) || !s._template) && (node_border      != s.node_border) )      { changed = true;  node_border      = s.node_border; }
    if( ((s.node_borderwidth != null) || !s._template) && (node_borderwidth != s.node_borderwidth) ) { changed = true;  node_borderwidth = s.node_borderwidth; }
    if( ((s.node_fill        != null) || !s._template) && (node_fill        != s.node_fill) )        { changed = true;  node_fill        = s.node_fill; }
    if( ((s.node_margin      != 0)    || !s._template) && (node_margin      != s.node_margin) )      { changed = true;  node_margin      = s.node_margin; }
    if( ((s.node_padding     != 0)    || !s._template) && (node_padding     != s.node_padding) )     { changed = true;  node_padding     = s.node_padding; }
    if( ((s.node_font        != null) || !s._template) )                                             { changed = true;  node_font        = s.node_font.copy(); }
    if( ((s.node_text_align  != null) || !s._template) && (node_text_align  != s.node_text_align) )  { changed = true;  node_text_align  = s.node_text_align; }
    if( ((s.node_width       != null) || !s._template) && (node_width       != s.node_width) )       { changed = true;  node_width       = s.node_width; }
    if( ((s.node_markup      != null) || !s._template) && (node_markup      != s.node_markup) )      { changed = true;  node_markup      = s.node_markup; }
    return( changed );
  }

  //-------------------------------------------------------------
  // Copies the connection style fields.
  public bool copy_connection( Style s ) {
    bool changed = false;
    if( ((s.connection_dash        != null) || !s._template) && (connection_dash        != s.connection_dash) )        { changed = true;  connection_dash        = s.connection_dash; }
    if( ((s.connection_line_width  != null) || !s._template) && (connection_line_width  != s.connection_line_width) )  { changed = true;  connection_line_width  = s.connection_line_width; }
    if( ((s.connection_arrow       != null) || !s._template) && (connection_arrow       != s.connection_arrow) )       { changed = true;  connection_arrow       = s.connection_arrow; }
    if( ((s.connection_arrow_size  != null) || !s._template) && (connection_arrow_size  != s.connection_arrow_size) )  { changed = true;  connection_arrow_size  = s.connection_arrow_size; }
    if( ((s.connection_padding     != null) || !s._template) && (connection_padding     != s.connection_padding) )     { changed = true;  connection_padding     = s.connection_padding; }
    if( ((s.connection_font        != null) || !s._template) )                                                         { changed = true;  connection_font        = s.connection_font.copy(); }
    if( ((s.connection_text_align  != null) || !s._template) && (connection_text_align  != s.connection_text_align) )  { changed = true;  connection_text_align  = s.connection_text_align; }
    if( ((s.connection_title_width != null) || !s._template) && (connection_title_width != s.connection_title_width) ) { changed = true;  connection_title_width = s.connection_title_width; }
    return( changed );
  }

  //-------------------------------------------------------------
  // Copies the callout style fields.
  public bool copy_callout( Style s ) {
    bool changed = false;
    if( ((s.callout_font       != null) || !s._template) )                                                 { changed = true;  callout_font       = s.callout_font.copy(); }
    if( ((s.callout_text_align != null) || !s._template) && (callout_text_align != s.callout_text_align) ) { changed = true;  callout_text_align = s.callout_text_align; }
    if( ((s.callout_padding    != null) || !s._template) && (callout_padding    != s.callout_padding) )    { changed = true;  callout_padding    = s.callout_padding; }
    if( ((s.callout_ptr_width  != null) || !s._template) && (callout_ptr_width  != s.callout_ptr_width) )  { changed = true;  callout_ptr_width  = s.callout_ptr_width; }
    if( ((s.callout_ptr_length != null) || !s._template) && (callout_ptr_length != s.callout_ptr_length) ) { changed = true;  callout_ptr_length = s.callout_ptr_length; }
    return( changed );
  }

  //-------------------------------------------------------------
  // Copies the given style to this style.  Returns true if the
  // style changed; otherwise, returns false.
  public bool copy( Style s ) {
    bool changed = false;
    changed |= copy_node_branch( s );
    changed |= copy_node_link( s );
    changed |= copy_node_body( s );
    changed |= copy_connection( s );
    changed |= copy_callout( s );
    return( changed );
  }

  //-------------------------------------------------------------
  // Displays a string version of the stored styling information
  // that is only useful for debugging purposes (there is no parser
  // for this format).
  public string to_string() {
    string[] arr = {};
    if( branch_margin          != null ) arr += "bmargin[%d]".printf( branch_margin );
    if( branch_radius          != null ) arr += "bradius[%d]".printf( branch_radius );
    if( link_type              != null ) arr += "ltype[%s]".printf( link_type.name() );
    if( link_width             != null ) arr += "lwidth[%d]".printf( link_width );
    if( link_arrow             != null ) arr += "larrow[%s]".printf( link_arrow.to_string() );
    if( link_arrow_size        != null ) arr += "larrsz[%d]".printf( link_arrow_size );
    if( link_dash              != null ) arr += "ldash[%s]".printf( link_dash.name );
    if( node_border            != null ) arr += "nborder[%s]".printf( node_border.name() );
    if( node_borderwidth       != null ) arr += "nbwidth[%d]".printf( node_borderwidth );
    if( node_fill              != null ) arr += "nfill[%s]".printf( node_fill.to_string() );
    if( node_margin            != 0 )    arr += "nmargin[%d]".printf( node_margin );
    if( node_padding           != 0 )    arr += "npad[%d]".printf( node_padding );
    if( node_font              != null ) arr += "nfont";
    if( node_text_align        != null ) {
      switch( node_text_align ) {
        case Pango.Alignment.LEFT   :  arr += "nalign[left]";    break;
        case Pango.Alignment.CENTER :  arr += "nalign[center]";  break;
        case Pango.Alignment.RIGHT  :  arr += "nalign[right]";   break;
      }
    }
    if( node_width             != null ) arr += "nwidth[%d]".printf( node_width );
    if( node_markup            != null ) arr += "nmarkup[%s]".printf( node_markup.to_string() );
    if( connection_dash        != null ) arr += "cdash[%s]".printf( connection_dash.name );
    if( connection_line_width  != null ) arr += "clwidth[%d]".printf( connection_line_width );
    if( connection_arrow       != null ) arr += "carrow[%s]".printf( connection_arrow );
    if( connection_arrow_size  != null ) arr += "carrsz[%d]".printf( connection_arrow_size );
    if( connection_padding     != null ) arr += "cpad[%d]".printf( connection_padding );
    if( connection_font        != null ) arr += "cfont";
    if( connection_text_align  != null ) {
      switch( connection_text_align ) {
        case Pango.Alignment.LEFT   :  arr += "calign[left]";    break;
        case Pango.Alignment.CENTER :  arr += "calign[center]";  break;
        case Pango.Alignment.RIGHT  :  arr += "calign[right]";   break;
      }
    }
    if( connection_title_width != null ) arr += "ctwidth[%d]".printf( connection_title_width );
    if( callout_font           != null ) arr += "ofont";
    if( callout_text_align  != null ) {
      switch( callout_text_align ) {
        case Pango.Alignment.LEFT   :  arr += "oalign[left]";    break;
        case Pango.Alignment.CENTER :  arr += "oalign[center]";  break;
        case Pango.Alignment.RIGHT  :  arr += "oalign[right]";   break;
      }
    }
    if( callout_padding        != null ) arr += "opad[%d]".printf( callout_padding );
    if( callout_ptr_width      != null ) arr += "opw[%d]".printf( callout_ptr_width );
    if( callout_ptr_length     != null ) arr += "opl[%d]".printf( callout_ptr_length );
    return( string.joinv( "+", arr ) );
  }

  //-------------------------------------------------------------
  // Loads the node branch style information from XML format.
  public void load_node_branch( Xml.Node* node ) {
    string? bm = node->get_prop( "branchmargin" );
    if( bm != null ) {
      branch_margin = int.parse( bm );
    }
    string? br = node->get_prop( "branchradius" );
    if( br != null ) {
      branch_radius = int.parse( br );
    }
  }

  //-------------------------------------------------------------
  // Loads the node link style information from XML format.
  public void load_node_link( Xml.Node* node ) {
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
    string? las = node->get_prop( "linkarrowsize" );
    if( las != null ) {
      link_arrow_size = int.parse( las );
    }
    string? ld = node->get_prop( "linkdash" );
    if( ld != null ) {
      link_dash = StyleInspector.styles.get_link_dash( ld );
    }
  }

  //-------------------------------------------------------------
  // Loads the node body information from XML format.
  public void load_node_node( Xml.Node* node ) {
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
    string? nta = node->get_prop( "nodetextalign" );
    if( nta != null ) {
      switch( nta ) {
        case "left"   :  node_text_align = Pango.Alignment.LEFT;    break;
        case "center" :  node_text_align = Pango.Alignment.CENTER;  break;
        case "right"  :  node_text_align = Pango.Alignment.RIGHT;   break;
      }
    }
    string? nmu = node->get_prop( "nodemarkup" );
    if( nmu != null ) {
      node_markup = bool.parse( nmu );
    }
  }

  //-------------------------------------------------------------
  // Loads the style information in the given XML node.
  public void load_node( Xml.Node* node ) {
    load_node_branch( node );
    load_node_link( node );
    load_node_node( node );
  }

  //-------------------------------------------------------------
  // Loads the style information in the given XML node.
  public void load_connection( Xml.Node* node ) {
    string? d = node->get_prop( "connectiondash" );
    if( d != null ) {
      connection_dash = StyleInspector.styles.get_link_dash( d );
    }
    string? lw = node->get_prop( "connectionlwidth" );
    if( lw == null ) {
      lw = node->get_prop( "connectionwidth" );
    }
    if( lw != null ) {
      connection_line_width = int.parse( lw );
    }
    string? a = node->get_prop( "connectionarrow" );
    if( a != null ) {
      connection_arrow = a;
    }
    string? az = node->get_prop( "connectionarrowsize" );
    if( az != null ) {
      connection_arrow_size = int.parse( az );
    }
    string? p = node->get_prop( "connectionpadding" );
    if( p != null ) {
      connection_padding = int.parse( p );
    }
    string? f = node->get_prop( "connectionfont" );
    if( f != null ) {
      connection_font = FontDescription.from_string( f );
    }
    string? cta = node->get_prop( "connectiontextalign" );
    if( cta != null ) {
      switch( cta ) {
        case "left"   :  connection_text_align = Pango.Alignment.LEFT;    break;
        case "center" :  connection_text_align = Pango.Alignment.CENTER;  break;
        case "right"  :  connection_text_align = Pango.Alignment.RIGHT;   break;
      }
    }
    string? tw = node->get_prop( "connectiontwidth" );
    if( tw != null ) {
      connection_title_width = int.parse( tw );
    }
  }

  //-------------------------------------------------------------
  // Loads the style information for a callout in the given XML node.
  public void load_callout( Xml.Node* node ) {
    var f = node->get_prop( "calloutfont" );
    if( f != null ) {
      callout_font = FontDescription.from_string( f );
    }
    string? ta = node->get_prop( "callouttextalign" );
    if( ta != null ) {
      switch( ta ) {
        case "left"   :  callout_text_align = Pango.Alignment.LEFT;    break;
        case "center" :  callout_text_align = Pango.Alignment.CENTER;  break;
        case "right"  :  callout_text_align = Pango.Alignment.RIGHT;   break;
      }
    }

    var p = node->get_prop( "calloutpadding" );
    if( p != null ) {
      callout_padding = int.parse( p );
    }

    var pw = node->get_prop( "calloutptrwidth" );
    if( pw != null ) {
      callout_ptr_width = int.parse( pw );
    }

    var pl = node->get_prop( "calloutptrlength" );
    if( pl != null ) {
      callout_ptr_length = int.parse( pl );
    }
  }

  //-------------------------------------------------------------
  // Saves the node branch style information in XML format.
  public void save_node_branch_in_node( Xml.Node* n ) {
    if( branch_margin != null ) {
      n->set_prop( "branchmargin", branch_margin.to_string() );
    }
    if( branch_radius != null ) {
      n->set_prop( "branchradius", branch_radius.to_string() );
    }
  }

  //-------------------------------------------------------------
  // Saves the node link style information in XML format.
  public void save_node_link_in_node( Xml.Node* n ) {
    if( link_type != null ) {
      n->set_prop( "linktype", link_type.name() );
    }
    if( link_width != null ) {
      n->set_prop( "linkwidth", link_width.to_string() );
    }
    if( link_arrow != null ) {
      n->set_prop( "linkarrow", link_arrow.to_string() );
    }
    if( link_arrow_size != null ) {
      n->set_prop( "linkarrowsize", link_arrow_size.to_string() );
    }
    if( link_dash != null ) {
      n->set_prop( "linkdash", link_dash.name );
    }
  }

  //-------------------------------------------------------------
  // Saves the node body style information in XML format.
  public void save_node_node_in_node( Xml.Node* n ) {
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
    if( node_margin != 0 ) {
      n->set_prop( "nodemargin", node_margin.to_string() );
    }
    if( node_padding != 0 ) {
      n->set_prop( "nodepadding", node_padding.to_string() );
    }
    if( node_font != null ) {
      n->set_prop( "nodefont", node_font.to_string() );
    }
    if( node_text_align != null ) {
      switch( node_text_align ) {
        case Pango.Alignment.LEFT   :  n->set_prop( "nodetextalign", "left" );    break;
        case Pango.Alignment.CENTER :  n->set_prop( "nodetextalign", "center" );  break;
        case Pango.Alignment.RIGHT  :  n->set_prop( "nodetextalign", "right" );   break;
      }
    }
    if( node_markup != null ) {
      n->set_prop( "nodemarkup", node_markup.to_string() );
    }
  }

  //-------------------------------------------------------------
  // Saves all of the node information in XML format.
  public void save_node_in_node( Xml.Node* n ) {
    save_node_branch_in_node( n );
    save_node_link_in_node( n );
    save_node_node_in_node( n );
  }

  //-------------------------------------------------------------
  // Stores this style in XML format.
  public void save_node( Xml.Node* parent ) {
    Xml.Node* n = new Xml.Node( null, "style" );
    save_node_in_node( n );
    parent->add_child( n );
  }

  //-------------------------------------------------------------
  // Saves th connection style information to the specified XML node.
  public void save_connection_in_node( Xml.Node* n ) {
    if( connection_dash != null ) {
      n->set_prop( "connectiondash",  connection_dash.name );
    }
    if( connection_line_width != null ) {
      n->set_prop( "connectionlwidth", connection_line_width.to_string() );
    }
    if( connection_arrow != null ) {
      n->set_prop( "connectionarrow", connection_arrow );
    }
    if( connection_arrow_size != null ) {
      n->set_prop( "connectionarrowsize", connection_arrow_size.to_string() );
    }
    if( connection_padding != null ) {
      n->set_prop( "connectionpadding", connection_padding.to_string() );
    }
    if( connection_font != null ) {
      n->set_prop( "connectionfont", connection_font.to_string() );
    }
    if( connection_text_align != null ) {
      switch( connection_text_align ) {
        case Pango.Alignment.LEFT   :  n->set_prop( "connectiontextalign", "left" );    break;
        case Pango.Alignment.CENTER :  n->set_prop( "connectiontextalign", "center" );  break;
        case Pango.Alignment.RIGHT  :  n->set_prop( "connectiontextalign", "right" );   break;
      }
    }
    if( connection_title_width != null ) {
      n->set_prop( "connectiontwidth", connection_title_width.to_string() );
    }
  }

  //-------------------------------------------------------------
  // Stores this style in XML format.
  public void save_connection( Xml.Node* parent ) {
    Xml.Node* n = new Xml.Node( null, "style" );
    save_connection_in_node( n );
    parent->add_child( n );
  }

  //-------------------------------------------------------------
  // Stores the callout style information in the given XML node.
  public void save_callout_in_node( Xml.Node* n ) {
    if( callout_font != null ) {
      n->set_prop( "calloutfont", callout_font.to_string() );
    }
    if( callout_text_align != null ) {
      switch( callout_text_align ) {
        case Pango.Alignment.LEFT   :  n->set_prop( "callouttextalign", "left" );    break;
        case Pango.Alignment.CENTER :  n->set_prop( "callouttextalign", "center" );  break;
        case Pango.Alignment.RIGHT  :  n->set_prop( "callouttextalign", "right" );   break;
      }
    }
    if( callout_padding != null) {
      n->set_prop( "calloutpadding", callout_padding.to_string() );
    }
    if( callout_ptr_width != null) {
      n->set_prop( "calloutptrwidth", callout_ptr_width.to_string() );
    }
    if( callout_ptr_length != null) {
      n->set_prop( "calloutptrlength", callout_ptr_length.to_string() );
    }
  }

  //-------------------------------------------------------------
  // Stores this style in XML format.
  public void save_callout( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "style" );
    save_callout_in_node( n );
    parent->add_child( n );

  }

  //-------------------------------------------------------------
  // Draws the link with the given information, applying the
  // stored styling.
  public void draw_link( Cairo.Context ctx, Node from_node, Node to_node, bool force_straight_link_type,
                         double from_x, double from_y, double to_x1, double to_y1, double to_x2, double to_y2,
                         out double tailx, out double taily, out double tipx, out double tipy ) {

    ctx.save();
    ctx.set_line_width( link_width );
    link_dash.set_context( ctx, link_width );
    if( force_straight_link_type ) {
      var straight = StyleInspector.styles.get_link_type( "straight" );
      straight.draw( ctx, from_node, to_node, from_x, from_y, to_x1, to_y1, out tailx, out taily, out tipx, out tipy );
    } else {
      from_node.style.link_type.draw( ctx, from_node, to_node, from_x, from_y, to_x1, to_y1, out tailx, out taily, out tipx, out tipy );
    }

    /* Draw the extension line, if necessary */
    if( (to_x1 != to_x2) || (to_y1 != to_y2) ) {
      ctx.move_to( to_x1, to_y1 );
      ctx.line_to( to_x2, to_y2 );
      ctx.stroke();
    }

    ctx.restore();

  }

  //-------------------------------------------------------------
  // Draws the shape behind a node with the given dimensions and
  // stored styling.
  public void draw_node_border( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s ) {

    ctx.save();
    ctx.set_line_width( node_borderwidth );
    node_border.draw_border( ctx, x, y, w, h, s, node_padding );
    ctx.restore();

  }

  //-------------------------------------------------------------
  // Draws the node fill.
  public void draw_node_fill( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s ) {

    node_border.draw_fill( ctx, x, y, w, h, s, node_padding );

  }

  //-------------------------------------------------------------
  // Sets up the given context to draw the stylized connection.
  public void draw_connection( Cairo.Context ctx ) {

    ctx.set_line_width( connection_line_width );
    connection_dash.set_context( ctx, connection_line_width );

  }

}
