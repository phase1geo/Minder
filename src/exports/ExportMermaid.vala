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

public class ExportMermaid : Object {

  /* Exports the given drawing area to the file of the given name */
  public static bool export( string fname, DrawArea da ) {
    var  file   = File.new_for_path( fname );
    bool retval = true;
    try {
      var os = file.create( FileCreateFlags.PRIVATE );
      export_top_nodes( os, da );
    } catch( Error e ) {
      retval = false;
    }
    return( retval );
  }

  private static string map_layout_to_direction( Node n ) {

    string lname = n.layout.name;

    if( (lname == _( "Vertical" )) || (lname == _( "Downwards" )) ) {
      return( "TB" );
    } else if( lname == _( "To left" ) ) {
      return( "RL" );
    } else if( lname == _( "Upwards" ) ) {
      return( "BT" );
    }

    return( "LR" );

  }

  /* Draws each of the top-level nodes */
  private static void export_top_nodes( FileOutputStream os, DrawArea da ) {

    try {

      var nodes = da.get_nodes();
      for( int i=0; i<nodes.length; i++ ) {
        string title = "\ngraph " + map_layout_to_direction( nodes.index( i ) ) + "\n";
        os.write( title.data );
        export_node( os, nodes.index( i ) );
      }

    } catch( Error e ) {
      // Handle the error
    }

  }

  private static string make_title( Node n ) {

    string id_str  = "id" + n.id().to_string();
    bool   rounded = n.style.node_border.name() == "rounded";
    string left    = rounded ? "(" : "[";
    string right   = rounded ? ")" : "]";
    string name    = n.name;

    if( (name == "") && (n.get_image() != null) ) {
      name = "Image";
    }

    return( id_str + left + "\"" + n.name + "\"" + right );

  }

  private static string make_link( Node n ) {

    bool arrow = n.style.link_arrow;
    bool thin  = n.style.link_width < 5;
    bool solid = n.style.link_dash.name == "solid";

    if( arrow ) {
      return( thin ? (solid ? "-->" : "-.->") : (solid ? "==>" : "-:->") );
    } else {
      return( thin ? (solid ? "---" : "-.-")  : (solid ? "===" : "-:-") );
    }

  }

  /* Draws the given node and its children to the output stream */
  private static void export_node( FileOutputStream os, Node node ) {
    
    try {

      var title    = make_title( node );
      var children = node.children();

      if( node.is_root() && (children.length == 0) ) {
        var line = "  " + title + ";\n";
        os.write( line.data );
      } else {
        for( int i=0; i<children.length; i++ ) {
          var link   = make_link( children.index( i ) );
          var ctitle = make_title( children.index( i ) );
          var line   = "  " + title + " " + link + " " + ctitle + ";\n";
          os.write( line.data );
          export_node( os, children.index( i ) );
        }
      }

    } catch( Error e ) {
      // Handle error
    }

  }

}
