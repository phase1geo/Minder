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

using Gtk;

public class ExportMermaid : Export {

  /* Constructor */
  public ExportMermaid() {
    base( "mermaid", _( "Mermaid" ), { ".mmd" }, true, false, false );
  }

  /* Exports the given drawing area to the file of the given name */
  public override bool export( string fname, DrawArea da ) {
    var  file   = File.new_for_path( fname );
    bool retval = true;
    try {
      var os = file.replace( null, false, FileCreateFlags.NONE );
      if( get_bool( "mindmap" ) ) {
        export_top_nodes_mindmap( os, da );
      } else {
        export_top_nodes_graph( os, da );
      }
    } catch( Error e ) {
      retval = false;
    }
    return( retval );
  }

  private string map_layout_to_direction( Node n ) {

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
  private void export_top_nodes_graph( FileOutputStream os, DrawArea da ) {

    try {

      var nodes   = da.get_nodes();
      int link_id = 0;

      if( nodes.length == 0 ) {
        return;
      }

      string title = "graph " + map_layout_to_direction( nodes.index( 0 ) ) + "\n";
      os.write( title.data );

      for( int i=0; i<nodes.length; i++ ) {
        export_node_graph( os, nodes.index( i ), ref link_id );
      }

    } catch( Error e ) {
      // Handle the error
    }

  }

  private void export_top_nodes_mindmap( FileOutputStream os, DrawArea da ) {

    try {

      var nodes = da.get_nodes();
      
      if( nodes.length != 1 ) {
        return;
      }

      var root     = nodes.index( 0 );
      var children = root.children();

      string title = "mindmap\nroot(" + root.name.text.text + ")\n";
      os.write( title.data );

      for( int i=0; i<children.length; i++ ) {
        export_node_mindmap( os, children.index( i ), "  " );
      }

    } catch( Error e ) {
      // Handle the error
    }

  }

  private string make_id( Node n ) {

    return( "id" + n.id().to_string() );

  }

  private string make_title( Node n ) {

    bool   rounded = n.style.node_border.name() == "rounded";
    string left    = rounded ? "(" : "[";
    string right   = rounded ? ")" : "]";
    string name    = n.name.text.text;

    if( (name == "") && (n.image != null) ) {
      name = "Image";
    }

    return( make_id( n ) + left + "\"" + n.name.text.text + "\"" + right );

  }

  private string make_link( Node n ) {

    bool arrow = n.style.link_arrow;
    bool solid = n.style.link_dash.name == "solid";

    if( arrow ) {
      return( solid ? "-->" : "-.->" );
    } else {
      return( solid ? "---" : "-.-" );
    }

  }

  private string make_link_color( Node n ) {

    var rgba = n.link_color;

    return( "#%02x%02x%02x".printf( (int)(rgba.red * 255), (int)(rgba.green * 255), (int)(rgba.blue * 255) ) );

  }

  private string make_node_style( Node n ) {

    string color = make_link_color( n );
    string fill  = n.style.node_fill ? ("fill:" + color + ",") : "";
    string width = n.style.node_borderwidth.to_string();

    return( "style " + make_id( n ) + " " + fill + "stroke:" + color + ",stroke-width:" + width + "px" );

  }

  private string make_link_style( Node n, ref int link_id ) {

    string color       = make_link_color( n );
    string width       = n.style.link_width.to_string();
    int    lid         = link_id++;
    var    pattern     = n.style.link_dash.pattern;
    string pattern_str = "";

    if( pattern.length > 0 ) {
      pattern_str = ",stroke-dasharray:";
      for( int i=0; i<pattern.length; i++ ) {
        pattern_str += "%s%d".printf( ((i == 0) ? "" : ","), (int)pattern[i] );
      }
    }

    // public double[] pattern;

    return( "linkStyle " + lid.to_string() + " stroke:" + color + ",stroke-width:" + width + "px" + pattern_str );

  }

  /* Draws the given node and its children to the output stream for graph output */
  private void export_node_graph( FileOutputStream os, Node node, ref int link_id ) {

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
          var nstyle = make_node_style( children.index( i ) );
          var lstyle = make_link_style( children.index( i ), ref link_id );
          var line   = "  " + title + " " + link + " " + ctitle + ";  " + nstyle + ";  " + lstyle + ";\n";
          os.write( line.data );
          export_node_graph( os, children.index( i ), ref link_id );
        }
      }

    } catch( Error e ) {
      // Handle error
    }

  }

  /* Draws the given node and its children to the output stream for mindmap output */
  private void export_node_mindmap( FileOutputStream os, Node node, string prefix ) {

    try {

      var title    = prefix + make_title( node );
      var children = node.children();

      os.write( title.data );

      for( int i=0; i<children.length; i++ ) {
        export_node_mindmap( os, children.index( i ), prefix + "  " );
      }

    } catch( Error e ) {
      // Handle error
    }

  }

  /* Adds settings panel */
  public override void add_settings( Grid grid ) {
    add_setting_bool( "mindmap", grid, _( "Use Mermaid Mindmap Format" ), null, false );
  }

  /* Save the settings */
  public override void save_settings( Xml.Node* node ) {
    node->set_prop( "mindmap", get_bool( "mindmap" ).to_string() );
  }

  /* Load the settings */
  public override void load_settings( Xml.Node* node ) {
    var mm = node->get_prop( "mindmap" );
    if( mm != null ) {
      set_bool( "mindmap", bool.parse( mm ) );
    }
  }

}
