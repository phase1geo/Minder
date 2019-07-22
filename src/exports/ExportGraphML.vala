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

using GLib;

public class ExportGraphML : Object {

  /* Exports the given drawing area to the file of the given name */
  public static bool export( string fname, DrawArea da ) {
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "graphml" );
    root->new_prop( "xmlns", "http://graphml.graphdrawing.org/xmlns" );
    Xml.Ns*   jns  = new Xml.Ns( root, "http://www.yworks.com/xml/yfiles-common/1.0/java", "java" );
    Xml.Ns*   sns  = new Xml.Ns( root, "http://www.yworks.com/xml/yfiles-common/markup/primitives/2.0", "sys" );
    Xml.Ns*   xns  = new Xml.Ns( root, "http://www.yworks.com/xml/yfiles-common/markup/2.0", "x" );
    Xml.Ns*   xsns = new Xml.Ns( root, "http://www.w3.org/2001/XMLSchema-instance", "xsi" );
    Xml.Ns*   yns  = new Xml.Ns( root, "http://www.yworks.com/xml/graphml", "y" );
    Xml.Ns*   ydns = new Xml.Ns( root, "http://www.yworks.com/xml/yed/3", "yed" );

    export_keys( root );
    export_graphs( root, yns, da );
    doc->set_root_element( root );
    doc->save_format_file( fname, 1 );
    delete doc;
    return( true );
  }

  /* Returns a single key populated with the specified information */
  private static Xml.Node* export_key_attr( string id, string for_item, string attr_name, string attr_type ) {
    Xml.Node* n = new Xml.Node( null, "key" );
    n->new_prop( "id", id );
    n->new_prop( "for", for_item );
    n->new_prop( "attr.name", attr_name );
    n->new_prop( "attr.type", attr_type );
    return( n );
  }

  /* Returns a single key populated with the specified information */
  private static Xml.Node* export_key_yfiles( string id, string for_item, string yfiles_type ) {
    Xml.Node* n = new Xml.Node( null, "key" );
    n->new_prop( "id", id );
    n->new_prop( "for", for_item );
    n->new_prop( "yfiles.type", yfiles_type );
    return( n );
  }

  /* Adds all of the keys to the root node */
  private static void export_keys( Xml.Node* root ) {
    root->add_child( export_key_attr(   "d5", "node", "description", "string" ) );
    root->add_child( export_key_yfiles( "d6", "node", "nodegraphics" ) );
    root->add_child( export_key_yfiles( "d7", "graphml", "resources" ) );
    root->add_child( export_key_attr(   "d9", "edge", "description", "string" ) );
    root->add_child( export_key_yfiles( "d10", "edge", "edgegraphics" ) );
  }

  /* Exports each tree as a separate graph */
  private static void export_graphs( Xml.Node* root, Xml.Ns* yns, DrawArea da ) {
    for( int i=0; i<da.get_nodes().length; i++ ) {
      Xml.Node* graph = new Xml.Node( null, "graph" );
      graph->new_prop( "edgedefault", "directed" );
      graph->new_prop( "id", ("G" + i.to_string()) );
      export_node_edge( graph, yns, da.get_nodes().index( i ), da.get_theme() );

      // TBD - Insert connections as edges here

      Xml.Node* d7 = new Xml.Node( null, "data" );
      d7->new_prop( "key", "d7" );

      Xml.Node* res = new Xml.Node( yns, "Resources" );
      d7->add_child( res );

      graph->add_child( d7 );
      root->add_child( graph );
    }
  }

  private static Xml.Node* export_node_shape( Node node, Theme theme, Xml.Ns* yns ) {
    Xml.Node* shape = new Xml.Node( yns, "ShapeNode" );

    Xml.Node* geometry = new Xml.Node( yns, "Geometry" );
    geometry->new_prop( "height", (node.height - (node.style.node_margin * 2)).to_string() );
    geometry->new_prop( "width",  (node.width  - (node.style.node_margin * 2)).to_string() );
    geometry->new_prop( "x",      (node.posx + node.style.node_margin).to_string() );
    geometry->new_prop( "y",      (node.posy + node.style.node_margin).to_string() );
    shape->add_child( geometry );

    Xml.Node* fill = new Xml.Node( yns, "Fill" );
    fill->new_prop( "color", Utils.color_from_rgba( node.is_root() ? theme.root_background : (node.style.node_fill ? node.link_color : theme.background) ) );
    fill->new_prop( "transparent", "false" );
    shape->add_child( fill );

    Xml.Node* bs = new Xml.Node( yns, "BorderStyle" );
    bs->new_prop( "color", Utils.color_from_rgba( node.link_color ) );
    bs->new_prop( "type", "line" );  // TBD
    bs->new_prop( "width", node.style.node_borderwidth.to_string() );
    shape->add_child( bs );

    Xml.Node* lbl = new Xml.Node( yns, "NodeLabel" );
    lbl->new_prop( "alignment", "left" );
    lbl->new_prop( "autoSizePolicy", "content" );
    lbl->new_prop( "fontFamily", node.style.node_font.get_family() );
    lbl->new_prop( "fontSize",   (node.style.node_font.get_size() / Pango.SCALE).to_string() );
    lbl->new_prop( "fontStyle", "plain" );
    lbl->new_prop( "hasBackgroundColor", "false" );
    lbl->new_prop( "hasLineColor", "false" );
    lbl->new_prop( "height", node.name.height.to_string() );
    lbl->new_prop( "horizontalTextPosition", "left" );
    lbl->new_prop( "iconTextGap", "4" );
    lbl->new_prop( "modelName", "custom" );
    lbl->new_prop( "textColor", Utils.color_from_rgba( node.is_root() ? theme.root_foreground : (node.style.node_fill ? theme.background : theme.foreground) ) );
    lbl->new_prop( "verticalTextPosition", "top" );
    lbl->new_prop( "visible", node.folded ? "false" : "true" );
    lbl->new_prop( "width", node.name.width.to_string() );
    lbl->new_prop( "x", node.style.node_padding.to_string() );
    lbl->new_prop( "xml:space", "preserve" );
    lbl->new_prop( "y", node.style.node_padding.to_string() );
    lbl->add_content( node.name.get_wrapped_text() );
    shape->add_child( lbl );

    Xml.Node* model = new Xml.Node( yns, "LabelModel" );
    Xml.Node* smodel = new Xml.Node( yns, "SmartNodeLabelModel" );
    smodel->new_prop( "distance", "4.0" );
    model->add_child( smodel );
    lbl->add_child( model );

    Xml.Node* param  = new Xml.Node( yns, "ModelParameter" );
    Xml.Node* sparam = new Xml.Node( yns, "SmartNodeLabelModelParameter" );
    sparam->new_prop( "labelRatioX", "0.0" );
    sparam->new_prop( "labelRatioY", "0.0" );
    sparam->new_prop( "nodeRatioX", "0.0" );
    sparam->new_prop( "nodeRatioY", "0.0" );
    sparam->new_prop( "offsetX", "0.0" );
    sparam->new_prop( "offsetY", "0.0" );
    sparam->new_prop( "upX", "0.0" );
    sparam->new_prop( "upY", "-1.0" );
    param->add_child( sparam );
    lbl->add_child( param );

    Xml.Node* s = new Xml.Node( yns, "Shape" );
    switch( node.style.node_border.name() ) {
      case "rounded" :  s->new_prop( "type", "roundrectangle" );  break;
      case "squared" :  s->new_prop( "type", "rectangle" );       break;
      default        :  s->new_prop( "type", "rectangle" );       break;
    }
    shape->add_child( s );

    return( shape );

  }

  private static Xml.Node* export_node( Node node, Theme theme, Xml.Ns* yns ) {
    Xml.Node* n  = new Xml.Node( null, "node" );
    Xml.Node* d5 = new Xml.Node( null, "data" );
    Xml.Node* d6 = new Xml.Node( null, "data" );
    n->new_prop( "id", ("n" + node.id().to_string()) );
    d5->new_prop( "key", "d5" );
    if( node.note != "" ) {
      d5->new_prop( "xml:space", "preserve" );
      d5->add_content( node.note );
    }
    n->add_child( d5 );
    d6->new_prop( "key", "d6" );
    d6->add_child( export_node_shape( node, theme, yns ) );
    n->add_child( d6 );
    return( n );
  }

  /* Adds the link line edge node */
  private static Xml.Node* export_node_lineedge( Node node, Xml.Ns* yns ) {

    Xml.Node* le = new Xml.Node( yns, "PolyLineEdge" );

    Xml.Node* ls = new Xml.Node( yns, "LineStyle" );
    ls->new_prop( "color", Utils.color_from_rgba( node.link_color ) );
    ls->new_prop( "type", "line" );
    ls->new_prop( "width", node.style.link_width.to_string() );
    le->add_child( ls );

    Xml.Node* bs = new Xml.Node( yns, "BendStyle" );
    bs->new_prop( "smoothed", "true" );
    le->add_child( bs );

    return( le );

  }

  private static Xml.Node* export_node_bezieredge( Node node, Xml.Ns* yns ) {

    Xml.Node* be   = new Xml.Node( yns, "BezierEdge" );

    Xml.Node* path = new Xml.Node( yns, "Path" );
    path->new_prop( "sx", "0.0" );
    path->new_prop( "sy", "0.0" );
    path->new_prop( "tx", "0.0" );
    path->new_prop( "ty", "0.0" );
    be->add_child( path );

    Xml.Node* ls = new Xml.Node( yns, "LineStyle" );
    ls->new_prop( "color", Utils.color_from_rgba( node.link_color ) );
    ls->new_prop( "type", "line" );
    ls->new_prop( "width", node.style.link_width.to_string() );
    be->add_child( ls );

    Xml.Node* arrow = new Xml.Node( yns, "Arrows" );
    arrow->new_prop( "source", "none" );
    arrow->new_prop( "target", "none" );
    be->add_child( arrow );

    return( be );

  }

  /* Adds the node link as an edge */
  private static Xml.Node* export_link( Node node, Xml.Ns* yns ) {
    if( node.is_root() ) return( null );
    Xml.Node* e = new Xml.Node( null, "edge" );
    e->new_prop( "id", ("e" + node.id().to_string()) );
    e->new_prop( "source", ("n" + node.parent.id().to_string()) );
    e->new_prop( "target", ("n" + node.id().to_string()) );

    Xml.Node* d9 = new Xml.Node( null, "data" );
    d9->new_prop( "key", "d9" );
    e->add_child( d9 );

    Xml.Node* d10 = new Xml.Node( null, "data" );
    d10->new_prop( "key", "d10" );
    d10->add_child( export_node_bezieredge( node, yns ) );
    e->add_child( d10 );

    return( e );

  }

  /* Adds a node along with its edge */
  private static void export_node_edge( Xml.Node* graph, Xml.Ns* yns, Node node, Theme theme ) {
    graph->add_child( export_node( node, theme, yns ) );
    if( !node.is_root() ) {
      graph->add_child( export_link( node, yns ) );
    }
    for( int i=0; i<node.children().length; i++ ) {
      export_node_edge( graph, yns, node.children().index( i ), theme );
    }
  }

  // -------------------------------------------------------------------

  /*
   Reads the contents of an OPML file and creates a new document based on
   the stored information.
  */
  public static bool import( string fname, DrawArea da ) {

    /* Read in the contents of the OPML file */
    var doc = Xml.Parser.parse_file( fname );
    if( doc == null ) {
      return( false );
    }

    /* Load the contents of the file */
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        Array<int>? expand_state = null;
        switch( it->name ) {
          case "head" :
            import_header( it, ref expand_state );
            break;
          case "body" :
            da.import_opml( it, ref expand_state );
            break;
        }
      }
    }

    /* Delete the OPML document */
    delete doc;

    return( true );

  }

  /* Parses the OPML head block for information that we will use */
  private static void import_header( Xml.Node* n, ref Array<int>? expand_state ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "expansionState" :
            if( (it->children != null) && (it->children->type == Xml.ElementType.TEXT_NODE) ) {
              expand_state = new Array<int>();
              string[] values = n->children->get_content().split( "," );
              foreach (string val in values) {
                int intval = int.parse( val );
                expand_state.append_val( intval );
              }
            }
            break;
        }
      }
    }
  }

}
