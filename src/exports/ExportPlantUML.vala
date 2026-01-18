/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

public class ExportPlantUML : Export {

  //-------------------------------------------------------------
  // Constructor
  public ExportPlantUML() {
    base( "plant-uml", _( "PlantUML" ), { ".puml" }, true, true, false, true );
  }

  //-------------------------------------------------------------
  // Exports the given drawing area to the file of the given name
  public override bool export( string fname, MindMap map ) {
    var retval = true;
    if( send_to_clipboard() ) {
      MinderClipboard.copy_text( export_top_nodes( map ) );
    } else {
      var file = File.new_for_path( fname );
      try {
        var os = file.replace( null, false, FileCreateFlags.NONE );
        os.write( export_top_nodes( map ).data );
      } catch( Error e ) {
        retval = false;
      }
    }
    return( retval );
  }

  private string export_header( MindMap map ) {
    return( "@startmindmap\n" );
  }

  private string export_footer( MindMap map ) {
    return( "@endmindmap\n\n" );
  }

  //-------------------------------------------------------------
  // Draws each of the top-level nodes
  private string export_top_nodes( MindMap map ) {

    var retval = "";

    try {

      var nodes = map.get_nodes();
      for( int i=0; i<nodes.length; i++ ) {
        retval += export_header( map );
        retval += export_node( nodes.index( i ), 1 );
        retval += export_footer( map );
      }

    } catch( Error e ) {
      // Handle the error
    }

    return( retval );

  }

  //-------------------------------------------------------------
  // Draws the given node and its children to the output stream
  private string export_node( Node node, int depth ) {

    var retval = "";

    try {

      string layout_name = node.layout.name;
      var    title       = "";

      if( node.main_branch() && ((node.index() == 0) || (node.side != node.parent.prev_child( node ).side)) ) {
        switch( node.side ) {
          case NodeSide.LEFT :
          case NodeSide.TOP  :  title += "\nleft side\n";   break;
          default            :  title += "\nright side\n";  break;
        }
      }

      title += string.nfill( depth, '*' );

      if( !node.is_root() ) {
        if( node.style.node_border.is_fillable() ) {
          title += "[%s] ".printf( Utils.color_from_rgba( node.link_color ) );
        } else {
          title += "_ ";
        }
      } else {
        title += " ";
      }

      title  += node.name.text.text.replace( "\n", "\\n" ) + "\n";
      retval += title;

      var children = node.children();
      for( int i=0; i<children.length; i++ ) {
        retval += export_node( children.index( i ), (depth + 1) );
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
  // Imports a PlantUML document
  public override bool import( string fname, MindMap map ) {

    try {

      File            file = File.new_for_path( fname );
      DataInputStream dis  = new DataInputStream( file.read() );
      size_t          len;
      Array<Node>     nodes;

      // Read the entire file contents
      var str = dis.read_upto( "\0", 1, out len ) + "\0";

      // Import the text
      import_doc( str, map );

      map.queue_draw();
      map.auto_save();

    } catch( IOError err ) {
      return( false );
    } catch( Error err ) {
      return( false );
    }

    return( true );
  }

  private void import_doc( string str, MindMap map ) {

    var lines = str.split( "\n" );
    var parse = false;
    var side  = NodeSide.RIGHT;

    MatchInfo matches;
    Regex     node_re;
    Node?     last_node = null;

    try {
      node_re = new Regex( "^([*+-]+|\\t*[*+-])(\\[#[0-9a-fA-F]{6}\\]|_)?\\s(.*)$" );
    } catch( RegexError e ) {
      return;
    }

    foreach( string line in lines ) {
      if( !parse ) {
        if( line.chomp() == "@startmindmap" ) {
          parse = true;
        }
      } else {
        if( line.chomp() == "@endmindmap" ) {
          parse = false;
        } else if( line.chomp() == "right side" ) {
          side = NodeSide.RIGHT;
        } else if( line.chomp() == "left side" ) {
          side = NodeSide.LEFT;
        } else if( node_re.match( line, 0, out matches ) ) {
          import_node( map, matches, side, ref last_node );
        }
      }
    }

  }

  //-------------------------------------------------------------
  // Imports the given node information and adds the new node to
  // the mind map
  private void import_node( MindMap map, MatchInfo matches, NodeSide side, ref Node? last_node ) {

    var li    = matches.fetch( 1 );
    var color = matches.fetch( 2 );
    var text  = matches.fetch( 3 ).replace( "\\n", "\n" );
    var depth = 1;

    // Figure out the node depth
    switch( li.get_char( 0 ) ) {
      case '*' :  depth = li.char_count();  break;
      case '+' :  depth = li.char_count();  side = NodeSide.RIGHT;  break;
      case '-' :  depth = li.char_count();  side = NodeSide.LEFT;   break;
      default  :
        depth = li.char_count() - 1;
        switch( li.get_char( li.index_of_nth_char( depth ) ) ) {
          case '+' :  side = NodeSide.RIGHT;  break;
          case '-' :  side = NodeSide.LEFT;   break;
        }
        break;
    }

    // Create node with the leftover text
    switch( depth ) {
      case 1 :
        last_node = map.model.create_root_node( text );
        break;
      case 2 :
        if( last_node != null ) {
          last_node = map.model.create_main_node( last_node.get_root(), side, text );
        }
        break;
      default :
        if( last_node != null ) {
          var last_depth = last_node.get_level() + 1;
          if( (last_depth + 1) == depth ) {
            last_node = map.model.create_child_node( last_node, text );
          } else if( last_depth == depth ) {
            last_node = map.model.create_sibling_node( last_node, true, text );
          } else if( last_depth > depth ) {
            for( int i=0; i<(last_depth - depth); i++ ) {
              last_node = last_node.parent;
            }
            last_node = map.model.create_sibling_node( last_node, true, text );
          }
        }
        break;
    }

    // Figure out the color and/or node shape
    if( color == "_" ) {
      last_node.style.node_border = StyleInspector.styles.get_node_border( "none" );
    } else {
      last_node.style.node_border = StyleInspector.styles.get_node_border( "squared" );
      if( color.get_char( 0 ) == '[' ) {
        RGBA c = {(float)1.0, (float)1.0, (float)1.0, (float)1.0};
        c.parse( color.slice( color.index_of_nth_char( 1 ), color.index_of_nth_char( 8 ) ) );
        last_node.link_color = c;
      }
    }

  }

}
