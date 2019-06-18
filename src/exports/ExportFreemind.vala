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
using Gdk;
using Gee;

public class ExportFreemind : Object {

  /* Exports the given drawing area to the file of the given name */
  public static bool export( string fname, DrawArea da ) {
    return( false );
  }

  /*
   Reads the contents of an OPML file and creates a new document based on
   the stored information.
  */
  public static bool import( string fname, DrawArea da ) {

    /* Read in the contents of the Freemind file */
    var doc = Xml.Parser.parse_file( fname );
    if( doc == null ) {
      return( false );
    }

    /* Load the contents of the file */
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "map" ) {
          import_map( da, it );
        }
      }
    }

    /* Delete the OPML document */
    delete doc;

    return( true );

  }

  /* Parses the OPML head block for information that we will use */
  private static void import_map( DrawArea da, Xml.Node* n ) {

    var color_map = new HashMap<string,RGBA>();
    var id_map    = new HashMap<string,int>();
    var to_nodes  = new Array<string>();

    /* Not sure what to do with the version information */
    string? v = n->get_prop( "version" );

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "node" ) {
          var root = import_node( it, da, null, color_map, id_map, to_nodes );
          da.get_nodes().append_val( root );
        }
      }
    }

    /* Finish up the connections */
    for( int i=0; i<to_nodes.length; i++ ) {
      if( id_map.has_key( to_nodes.index( i ) ) ) {
        var to_node = da.get_node( da.get_nodes(), id_map.get( to_nodes.index( i ) ) );
        if( to_node != null ) {
          da.get_connections().complete_connection( i, to_node );
        }
      }
    }

  }

  /* Parses the given Freemind node */
  public static Node import_node( Xml.Node* n, DrawArea da, Node? parent, HashMap<string,RGBA> color_map, HashMap<string,int> id_map, Array<string> to_nodes ) {

    var node = new Node( da, da.layouts.get_default() );

    string? i = n->get_prop( "id" );
    if( i != null ) {
      id_map.set( i, node.id() );
    }

    string? t = n->get_prop( "text" );
    if( t != null ) {
      node.name.text = t;
    }

    string? l = n->get_prop( "link" );
    if( l != null ) {
      /* Not currently supported */
    }

    string? f = n->get_prop( "folded" );
    if( f != null ) {
      node.folded = bool.parse( f );
    }

    string? c = n->get_prop( "color" );
    if( c != null ) {
      if( color_map.has_key( c ) ) {
        node.link_color = color_map.get( c );
      } else {
        node.link_color = da.get_theme().next_color();
        color_map.set( c, node.link_color );
      }
    }

    string? p = n->get_prop( "position" );
    if( p != null ) {
      node.side = (p == "left") ? NodeSide.LEFT : NodeSide.RIGHT;
    }

    /* Parse the child nodes */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "node"      :  import_node( it, da, node, color_map, id_map, to_nodes );  break;
          case "edge"      :  import_edge( it, node );  break;
          case "font"      :  import_font( it, node );  break;
          case "icon"      :  break;  // Not implemented
          case "cloud"     :  break;  // Not implemented
          case "arrowlink" :  import_arrowlink( it, da, node, to_nodes );  break;
        }
      }
    }

    /* Attach the new node to its parent */
    node.attach( parent, -1, da.get_theme() );

    return( node );

  }

  private static void import_edge( Xml.Node* n, Node node ) {

    string? s = n->get_prop( "style" );
    if( s != null ) {
      switch( s ) {
        case "bezier" :  node.style.link_type = new LinkTypeCurved();    break;
        case "linear" :  node.style.link_type = new LinkTypeStraight();  break;
      }
    }

    string? c = n->get_prop( "color" );
    if( c != null ) {
      /* Not implemented - link color and node color must be the same */
    }

    string? w = n->get_prop( "width" );
    if( w != null ) {
      node.style.link_width = int.parse( w );
    }

  }

  private static void import_font( Xml.Node* n, Node node ) {

    string? f = n->get_prop( "name" );
    if( f != null ) {
      node.style.node_font.set_family( f );
    }

    string? s = n->get_prop( "size" );
    if( s != null ) {
      node.style.node_font.set_size( int.parse( s ) );
    }

    string? b = n->get_prop( "bold" );
    if( b != null ) {
      if( bool.parse( b ) ) {
        node.name.text = "<b>" + node.name.text + "</b>";
      }
    }

    string? i = n->get_prop( "italic" );
    if( i != null ) {
      if( bool.parse( i ) ) {
        node.name.text = "<i>" + node.name.text + "</i>";
      }
    }

  }

  private static void import_arrowlink( Xml.Node* n, DrawArea da, Node from_node, Array<string> to_nodes ) {

    var conn        = new Connection( da, from_node );
    var start_arrow = "None";
    var end_arrow   = "None";

    string? c = n->get_prop( "color" );
    if( c != null ) {
      /* Not implemented */
    }

    string? d = n->get_prop( "destination" );
    if( d != null ) {
      to_nodes.append_val( d );
    }

    string? sa = n->get_prop( "startarrow" );
    if( sa != null ) {
      start_arrow = sa;
    }

    string? ea = n->get_prop( "endarrow" );
    if( ea != null ) {
      end_arrow = ea;
    }

    /* Stylize the arrow */
    switch( start_arrow + end_arrow ) {
      case "NoneNone"       :  conn.style.connection_arrow = "none";    break;
      case "NoneDefault"    :  conn.style.connection_arrow = "fromto";  break;
      case "DefaultNone"    :  conn.style.connection_arrow = "tofrom";  break;
      case "DefaultDefault" :  conn.style.connection_arrow = "both";    break;
    }

    /* Add the connection to the connections list */
    da.get_connections().add_connection( conn );

  }

}
