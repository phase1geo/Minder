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
using Gee;

public class ExportText : Object {

  struct Hier {
    public int  spaces;
    public Node node;
  }

  /* Exports the given drawing area to the file of the given name */
  public static bool export( string fname, DrawArea da ) {

    var  file   = File.new_for_path( fname );
    bool retval = true;

    try {
      var os  = file.replace( null, false, FileCreateFlags.NONE );
      var str = export_top_nodes( da );
      os.write( str.data );
      os.close();
    } catch( Error e ) {
      retval = false;
    }

    return( retval );

  }

  /* Draws each of the top-level nodes */
  public static string export_top_nodes( DrawArea da ) {

    var value = "";
    var nodes = da.get_nodes();

    for( int i=0; i<nodes.length; i++ ) {
      value += "# " + nodes.index( i ).name.text.text + "\n";
      var children = nodes.index( i ).children();
      for( int j=0; j<children.length; j++ ) {
        value += export_node( children.index( j ) );
      }
    }

    return( value );

  }

  /* Draws the given node and its children to the output stream */
  public static string export_node( Node node, string prefix = "\t" ) {

    string value = prefix + "- ";

    /* Add the task information, if necessary */
    if( node.is_task() ) {
      if( node.is_task_done() ) {
        value += "[x] ";
      } else {
        value += "[ ] ";
      }
    }

    /* Add the node title */
    value += node.name.text.text + "\n";

    /* Add the node note, if specified */
    if( node.note != "" ) {
      value += prefix + "  > " + node.note.replace( "\n", "\n%s  > ".printf( prefix ) ) + "\n";
    }

    /* Add the children */
    var children = node.children();
    for( int i=0; i<children.length; i++ ) {
      value += export_node( children.index( i ), prefix + "\t" );
    }

    return( value );

  }

  /****************************************************************************/

  /* Imports a text file */
  public static bool import( string fname, DrawArea da ) {

    try {

      File            file = File.new_for_path( fname );
      DataInputStream dis  = new DataInputStream( file.read() );
      size_t          len;
      Array<Node>     nodes;

      /* Read the entire file contents */
      var str = dis.read_upto( "\0", 1, out len ) + "\0";

      /* Import the text */
      import_text( str, da.settings.get_int( "quick-entry-spaces-per-tab" ), da, false );

      da.queue_draw();
      da.changed();

    } catch( IOError err ) {
      return( false );
    } catch( Error err ) {
      return( false );
    }

    return( true );

  }

  /* Creates a new node from the given information and attaches it to the specified parent node */
  public static Node make_node( DrawArea da, Node? parent, string task, string name, Array<Node>? nodes, bool attach = true ) {

    var node = new Node.with_name( da, name, da.layouts.get_default() );

    /* Add the style component to the node */
    if( parent == null ) {
      node.style = StyleInspector.styles.get_global_style();
      if( attach ) {
        da.position_root_node( node );
        da.add_root( node, -1 );
        da.set_current_node( node );
      }
    } else {
      node.style = StyleInspector.styles.get_style_for_level( (parent.get_level() + 1), null );
      if( attach ) {
        node.attach( parent, (int)parent.children().length, da.get_theme() );
      }
    }

    /* Add the task information, if necessary */
    if( task != "" ) {
      node.enable_task( true );
      if( (task == "x") || (task == "X") ) {
        node.set_task_done( true );
      }
    }

    /* Add the node to the nodes array if it exists */
    if( nodes != null ) {
      nodes.append_val( node );
    }

    return( node );

  }

  /* Append the given string to the note */
  public static void append_note( Node node, string str ) {
    node.note = "%s\n%s".printf( node.note, str ).strip();
  }

  /* Imports the given text string */
  public static void import_text( string txt, int tab_spaces, DrawArea da, bool replace, Array<Node>? nodes = null ) {

    try {

      var stack   = new Array<Hier?>();
      var lines   = txt.split( "\n" );
      var re      = new Regex( "^(\\s*)((\\-|\\+|\\*|#|>)\\s*)?(\\[([ xX])\\]\\s*)?(.*)$" );
      var tspace  = string.nfill( ((tab_spaces <= 0) ? 1 : tab_spaces), ' ' );
      var current = da.get_current_node();

      /*
       Populate the stack with the current node, if one exists.  Set the spaces
       count to -1 so that everything but a new header is added to this node.
      */
      if( current != null ) {
        stack.append_val( {(replace ? 0 : -1), current} );
      }

      foreach( string line in lines ) {

        MatchInfo match_info;
        Node      node;

        /* If we found some useful text, include it here */
        if( re.match( line, 0, out match_info ) ) {

          var spaces = match_info.fetch( 1 ).replace( "\t", tspace ).length;
          var bullet = match_info.fetch( 3 );
          var task   = match_info.fetch( 5 );
          var str    = match_info.fetch( 6 );

          /* Add note */
          if( str.strip() == "" ) continue;
          if( bullet == ">" ) {
            if( stack.length > 0 ) {
              if( replace ) {
                stack.index( stack.length - 1 ).node.note = str;
                replace = false;
              } else {
                append_note( stack.index( stack.length - 1 ).node, str );
              }
            }

          /* If the stack is empty */
          } else if( stack.length == 0 ) {
            node = make_node( da, null, task, str, nodes );
            stack.append_val( {spaces, node} );

          /* Add sibling node */
          } else if( spaces == stack.index( stack.length - 1 ).spaces ) {
            node = make_node( da, stack.index( stack.length - 1 ).node.parent, task, str, nodes, !replace );
            if( replace ) {
              da.replace_node( stack.index( stack.length - 1 ).node, node );
              replace = false;
            }
            stack.remove_index( stack.length - 1 );
            stack.append_val( {spaces, node} );

          /* Add child node */
          } else if( spaces > stack.index( stack.length - 1 ).spaces ) {
            node = make_node( da, stack.index( stack.length - 1 ).node, task, str, nodes );
            stack.append_val( {spaces, node} );

          /* Add ancestor node */
          } else {
            while( (stack.length > 0) && (spaces < stack.index( stack.length - 1 ).spaces) ) {
              stack.remove_index( stack.length - 1 );
            }
            if( stack.length == 0 ) {
              node = make_node( da, null, task, str, nodes );
              stack.append_val( {spaces, node} );
            } else if( spaces == stack.index( stack.length - 1 ).spaces ) {
              node = make_node( da, stack.index( stack.length - 1 ).node.parent, task, str, nodes );
              stack.remove_index( stack.length - 1 );
              stack.append_val( {spaces, node} );
            } else {
              node = make_node( da, stack.index( stack.length - 1 ).node, task, str, nodes );
              stack.append_val( {spaces, node} );
            }
          }

        }

      }

    } catch( GLib.RegexError err ) {
      /* TBD */
    }

  }

}
