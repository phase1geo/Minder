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

  //-------------------------------------------------------------
  // Constructor
  public ExportMermaid() {
    base( "mermaid", _( "Mermaid" ), { ".mmd" }, true, false, false, true );
  }

  //-------------------------------------------------------------
  // Exports the given drawing area to the file of the given name
  public override bool export( string fname, MindMap map ) {
    var retval = true;
    var text   = "";
    if( get_bool( "mindmap" ) ) {
      text = export_top_nodes_mindmap( map );
    } else {
      text = export_top_nodes_graph( map );
    }
    if( send_to_clipboard() ) {
      MinderClipboard.copy_text( text );
    } else {
      var file = File.new_for_path( fname );
      try {
        var os = file.replace( null, false, FileCreateFlags.NONE );
        os.write( text.data );
      } catch( Error e ) {
        retval = false;
      }
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

  //-------------------------------------------------------------
  // Draws each of the top-level nodes
  private string export_top_nodes_graph( MindMap map ) {

    var retval = "";

    try {

      var nodes   = map.get_nodes();
      int link_id = 0;

      if( nodes.length == 0 ) {
        return( retval );
      }

      string title = "graph " + map_layout_to_direction( nodes.index( 0 ) ) + "\n";
      retval += title;

      for( int i=0; i<nodes.length; i++ ) {
        retval += export_node_graph( nodes.index( i ), ref link_id );
      }

    } catch( Error e ) {
      // Handle the error
    }

    return( retval );

  }

  private string export_top_nodes_mindmap( MindMap map ) {

    var retval = "";

    try {

      var nodes = map.get_nodes();
      
      if( nodes.length != 1 ) {
        return( retval );
      }

      var root     = nodes.index( 0 );
      var children = root.children();

      string title = "mindmap\nroot(" + root.name.text.text + ")\n";
      retval += title;

      for( int i=0; i<children.length; i++ ) {
        retval += export_node_mindmap( children.index( i ), "  " );
      }

    } catch( Error e ) {
      // Handle the error
    }

    return( retval );

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

  //-------------------------------------------------------------
  // Draws the given node and its children to the output stream
  // for graph output
  private string export_node_graph( Node node, ref int link_id ) {

    var retval = "";

    try {

      var title    = make_title( node );
      var children = node.children();

      if( node.is_root() && (children.length == 0) ) {
        var line = "  " + title + ";\n";
        retval += line;
      } else {
        for( int i=0; i<children.length; i++ ) {
          var link   = make_link( children.index( i ) );
          var ctitle = make_title( children.index( i ) );
          var nstyle = make_node_style( children.index( i ) );
          var lstyle = make_link_style( children.index( i ), ref link_id );
          var line   = "  " + title + " " + link + " " + ctitle + ";  " + nstyle + ";  " + lstyle + ";\n";
          retval += line;
          retval += export_node_graph( children.index( i ), ref link_id );
        }
      }

    } catch( Error e ) {
      // Handle error
    }

    return( retval );

  }

  //-------------------------------------------------------------
  // Draws the given node and its children to the output stream
  // for mindmap output
  private string export_node_mindmap( Node node, string prefix ) {

    var retval = "";

    try {

      var title    = prefix + make_title( node ) + "\n";
      var children = node.children();

      retval += title;

      for( int i=0; i<children.length; i++ ) {
        retval += export_node_mindmap( children.index( i ), prefix + "  " );
      }

    } catch( Error e ) {
      // Handle error
    }

    return( retval );

  }

  //-------------------------------------------------------------
  // Adds settings panel
  public override void add_settings( Grid grid ) {
    add_setting_bool( "mindmap", grid, _( "Use Mermaid Mindmap Format" ), null, false );
  }

  //-------------------------------------------------------------
  // Save the settings
  public override void save_settings( Xml.Node* node ) {
    node->set_prop( "mindmap", get_bool( "mindmap" ).to_string() );
  }

  //-------------------------------------------------------------
  // Load the settings
  public override void load_settings( Xml.Node* node ) {
    var mm = node->get_prop( "mindmap" );
    if( mm != null ) {
      set_bool( "mindmap", bool.parse( mm ) );
    }
  }

}
