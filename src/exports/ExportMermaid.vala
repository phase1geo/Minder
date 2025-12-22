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

using Gtk;

public class ExportMermaid : Export {

  public class NodeHier {
    public Node node   { get; set; }
    public int  prefix { get; set; default = 0; }
    public NodeHier( Node n, int p ) {
      node   = n;
      prefix = p;
    }
  }

  //-------------------------------------------------------------
  // Constructor
  public ExportMermaid() {
    base( "mermaid", _( "Mermaid" ), { ".mmd" }, true, true, false, true );
  }

  //-------------------------------------------------------------
  // EXPORT
  //-------------------------------------------------------------

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

  //-------------------------------------------------------------
  // Determine the layout direction for the given node in the graph.
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

  //-------------------------------------------------------------
  // Export the nodes in the given mindmap as a Mermaid mindmap.
  private string export_top_nodes_mindmap( MindMap map ) {

    var retval = "";

    try {

      var nodes = map.get_nodes();
      
      if( nodes.length != 1 ) {
        return( retval );
      }

      var root     = nodes.index( 0 );
      var children = root.children();

      string title = "mindmap\n%s\n".printf( make_title( root, true ) );
      retval += title;

      for( int i=0; i<children.length; i++ ) {
        retval += export_node_mindmap( children.index( i ), "  " );
      }

    } catch( Error e ) {
      // Handle the error
    }

    return( retval );

  }

  //-------------------------------------------------------------
  // Generates an id string from the given node (we will use the
  // nodes' ID).
  private string make_id( Node n ) {
    if( n.is_root() ) {
      return( "root" );
    } else {
      return( "id" + n.id().to_string() );
    }
  }

  //-------------------------------------------------------------
  // Generates the node title as a Mermaid title.  Includes how
  // to draw the title in the graph/mindmap.
  private string make_title( Node n, bool for_mindmap ) {

    var name = n.name.text.text;

    if( (name == "") && (n.image != null) ) {
      name = "Image";
    }

    if( n.style.node_markup && for_mindmap ) {
      name = "`" + name + "`";
    }

    switch( n.style.node_border.name() ) {
      case "rounded" :  return( make_id( n ) + "(\""  + name + "\")" );
      case "pilled"  :  return( make_id( n ) + "((\"" + name + "\"))" );
      case "squared" :  return( make_id( n ) + "[\""  + name + "\"]" );
      default        :
        if( for_mindmap ) {
          return( "\"" + name + "\"" );
        } else {
          return( make_id( n ) + "[\""  + name + "\"]" );
        }
    }

  }

  //-------------------------------------------------------------
  // Creates a Mermaid graph link for the given node.
  private string make_link( Node n ) {

    bool arrow = n.style.link_arrow;
    bool solid = n.style.link_dash.name == "solid";

    if( arrow ) {
      return( solid ? "-->" : "-.->" );
    } else {
      return( solid ? "---" : "-.-" );
    }

  }

  //-------------------------------------------------------------
  // Returns the color RGB string of the link from the given node.
  private string make_link_color( Node n ) {

    var rgba = n.link_color;

    return( "#%02x%02x%02x".printf( (int)(rgba.red * 255), (int)(rgba.green * 255), (int)(rgba.blue * 255) ) );

  }

  //-------------------------------------------------------------
  // Returns the node styling string for a Mermaid graph.
  private string make_node_style( Node n ) {

    string color = make_link_color( n );
    string fill  = n.style.node_fill ? ("fill:" + color + ",") : "";
    string width = n.style.node_borderwidth.to_string();

    return( "style " + make_id( n ) + " " + fill + "stroke:" + color + ",stroke-width:" + width + "px" );

  }

  //-------------------------------------------------------------
  // Returns the link style for a Mermaid graph.
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

      var title    = make_title( node, false );
      var children = node.children();

      if( node.is_root() && (children.length == 0) ) {
        var line = "  " + title + ";\n";
        retval += line;
      } else {
        for( int i=0; i<children.length; i++ ) {
          var link   = make_link( children.index( i ) );
          var ctitle = make_title( children.index( i ), false );
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

      var title    = prefix + make_title( node, true ) + "\n";
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
  // IMPORT
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Main import method.  Takes the name of a Mermaid file, parses
  // it, and populates the given mindmap.
  public override bool import( string fname, MindMap map ) {

    try {

      File            file = File.new_for_path( fname );
      DataInputStream dis  = new DataInputStream( file.read() );
      size_t          len;
      Array<Node>     nodes;

      // Read the entire file contents
      var str = dis.read_upto( "\0", 1, out len ) + "\0";

      // Import the text
      if( import_text( str, map ) ) {
        map.queue_draw();
        map.auto_save();
      } else {
        return( false );
      }

    } catch( IOError err ) {
      return( false );
    } catch( Error err ) {
      return( false );
    }

    return( true );

  }

  //-------------------------------------------------------------
  // Imports the contents of the Mermaid file and populates the
  // given mindmap.  We only parse Mermaid mindmap data.
  private bool import_text( string txt, MindMap map ) {

    var stack = new Array<NodeHier>();

    try {

      var lines     = txt.split( "\n" );
      var start_re  = new Regex( "^(\\w+)([\\[\\(\\)\\{]{1,2})(.*)$" );
      var first     = true;
      var in_header = false;
      var in_title  = false;
      var quoted    = false;
      var markdown  = false;
      var prefix    = 0;
      var end_shape = "";
      var border    = "";
      var title     = "";

      foreach( string line in lines) {

        MatchInfo match_info;
        var       stripped = line.strip();

        if( stripped != "" ) {
          if( first ) {
            if( stripped == "---" ) {
              in_header = true;
            } else if( stripped != "mindmap" ) {
              return( false );
            }
            first = false;

          // If we have found the end of the header, indicate it
          } else if( stripped == "---" ) {
            first     = true;
            in_header = false;

          // We don't support Mermaid icons and classes presently
          } else if( !stripped.has_prefix( "::icon(" ) && !stripped.has_prefix( ":::" ) && !in_header ) {
            if( !in_title ) {
              prefix    = line.char_count() - line.chug().char_count(); 
              end_shape = "";
              border    = "underlined";
              if( start_re.match( stripped, 0, out match_info ) ) {
                switch( match_info.fetch( 2 ) ) {
                  case "("  :  end_shape = ")";   border = "rounded";  break;
                  case "["  :  end_shape = "]";   border = "squared";  break;
                  case "((" :  end_shape = "))";  border = "pilled";   break;
                  case "))" :  end_shape = "((";  break;
                  case ")"  :  end_shape = "(";   break;
                  case "{{" :  end_shape = "}}";  break;
                }
                stripped = match_info.fetch( 3 );
              }
              quoted = stripped.has_prefix( "\"" );
              if( quoted ) {
                var start = stripped.index_of_nth_char( 1 );
                stripped  = stripped.substring( start );
              }
              markdown = stripped.has_prefix( "`" );
              if( markdown ) {
                var start = stripped.index_of_nth_char( 1 );
                stripped  = stripped.substring( start );
              }
              title    = "";
              in_title = true;
            }
            if( in_title ) {
              if( (end_shape != "") && stripped.has_suffix( end_shape ) ) {
                stripped = stripped.substring( 0, (stripped.length - end_shape.length) );
                in_title = false;
              }
              if( quoted ) {
                if( stripped.has_suffix( "\"" ) ) {
                  stripped = stripped.substring( 0, (stripped.length - "\"".length) );
                  if( markdown && stripped.has_suffix( "`" ) ) {
                    stripped = stripped.substring( 0, (stripped.length - "`".length) );
                  }
                  in_title = false;
                }
                title += "\n" + stripped;
              } else {
                if( markdown && stripped.has_suffix( "`" ) ) {
                  stripped = stripped.substring( 0, (stripped.length - "`".length) );
                }
                title = stripped;
                in_title = false;
              }
            }
            if( !in_title ) {
              var  parent = get_parent( stack, prefix );
              Node node;
              title = title.chug().replace( "<br/>", "\n" );
              if( parent == null ) {
                node = map.model.create_root_node( title );
              } else if( parent.parent == null ) {
                node = map.model.create_main_node( parent, NodeSide.RIGHT, title );
              } else {
                node = map.model.create_child_node( parent, title );
              }
              node.style.node_border = StyleInspector.styles.get_node_border( border );
              node.style.node_markup = markdown;
              stack.append_val( new NodeHier( node, prefix ) );
            }
          }
        }

      }

    } catch( GLib.RegexError e ) {
      return( false );
    } 

    return( stack.length > 0 );

  }

  //-------------------------------------------------------------
  // Returns the parent node in the stack given the prefix count.
  private Node? get_parent( Array<NodeHier> stack, int prefix ) {
    var last = (int)(stack.length - 1);
    while( (last >= 0) && (prefix <= stack.index( last ).prefix) ) {
      stack.remove_index( last );
      last = (int)(stack.length - 1);
    }
    return( (stack.length == 0) ? null : stack.index( last ).node );
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
