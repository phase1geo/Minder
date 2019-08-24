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
      var os = file.create( FileCreateFlags.PRIVATE );
      export_top_nodes( os, da );
    } catch( Error e ) {
      retval = false;
    }

    return( retval );

  }

  /* Draws each of the top-level nodes */
  private static void export_top_nodes( FileOutputStream os, DrawArea da ) {

    try {

      var nodes = da.get_nodes();
      for( int i=0; i<nodes.length; i++ ) {
        string title = nodes.index( i ).name.text + "\n";
        os.write( title.data );
        var children = nodes.index( i ).children();
        for( int j=0; j<children.length; j++ ) {
          export_node( os, children.index( j ) );
        }
      }

    } catch( Error e ) {
      // Handle the error
    }

  }

  /* Draws the given node and its children to the output stream */
  private static void export_node( FileOutputStream os, Node node, string prefix = "        " ) {
    
    try {

      string title = prefix;

      if( node.is_task() ) {
        if( node.is_task_done() ) {
          title += "- [x] ";
        } else {
          title += "- [ ] ";
        }
      }

      title += node.name.text + "\n";

      os.write( title.data );

      if( node.note != "" ) {
        string note = prefix + "  " + node.note + "\n";
        os.write( note.data );
      }

      var children = node.children();
      for( int i=0; i<children.length; i++ ) {
        export_node( os, children.index( i ), prefix + "        " );
      }

    } catch( Error e ) {
      // Handle error
    }

  }

  /* Imports a text file */
  public static bool import( string fname, DrawArea da ) {

    var str = "# This is a test string\n" +
              "  - Do this item first\n" +
              "  - Second item\n" +
              "    + Subitem A\n" +
              "    + Subitem B\n" +
              "  - [x] Third item\n" +
              "    > Quick note about the third item\n" +
              " - Fourth item";

    import_text( str, 8, da );

    return( true );

  }

  public static Node make_node( DrawArea da, Node? parent, string task, string name ) {

    var node = new Node.with_name( da, name, da.layouts.get_default() );

    /* Add the style component to the node */
    if( parent == null ) {
      node.style = StyleInspector.styles.get_global_style();
    } else {
      node.style = StyleInspector.styles.get_style_for_level( parent.get_level() + 1 );
      node.attach( parent, (int)parent.children().length, da.get_theme() );
    }

    /* Add the task information, if necessary */
    if( task != "" ) {
      node.enable_task( true );
      if( (task == "x") || (task == "X") ) {
        node.set_task_done( true );
      }
    }

    return( node );

  }

  /* Imports the given text string */
  public static void import_text( string txt, int tab_spaces, DrawArea da ) {

    try {

      var stack  = new ArrayQueue<Hier?>();
      var lines  = txt.split( "\n" );
      var re     = new Regex( "^(\\s*)((\\-|\\+|\\*|#|>)\\s*)?(\\[([ xX])\\]\\s*)?(.*)$" );
      var tspace = string.nfill( tab_spaces, ' ' );

      foreach( string line in lines ) {
        MatchInfo match_info;
        if( re.match( line, 0, out match_info ) ) {

          var spaces = match_info.fetch( 1 ).replace( "\t", tspace ).length;
          var bullet = match_info.fetch( 3 );
          var task   = match_info.fetch( 5 );
          var str    = match_info.fetch( 6 );

          /* Add root node */
          if( bullet == "#" ) {
            var node = make_node( da, null, task, str );
            da.add_root( node, -1 );
            stack.offer_head( {spaces, node} );

          /* Add note */
          } else if( bullet == ">" ) {
            stack.peek_head().node.note += str;

          /* Add sibling node */
          } else if( spaces == stack.peek_head().spaces ) {
            var node = make_node( da, stack.peek_head().node.parent, task, str );
            stack.poll_head();
            stack.offer_head( {spaces, node} );

          /* Add child node */
          } else if( spaces > stack.peek_head().spaces ) {
            var node = make_node( da, stack.peek_head().node, task, str );
            stack.offer_head( {spaces, node} );

          /* Add ancestor node */
          } else {
            while( !stack.is_empty && (spaces < stack.peek_head().spaces) ) {
              stack.poll_head();
            }
            if( spaces == stack.peek_head().spaces ) {
              var node = make_node( da, stack.peek_head().node.parent, task, str );
              stack.poll_head();
              stack.offer_head( {spaces, node} );
            } else {
              var node = make_node( da, stack.peek_head().node, task, str );
              stack.offer_head( {spaces, node} );
            }
          }
        }
      }

      da.changed();
      da.queue_draw();

    } catch( GLib.RegexError err ) {
      /* TBD */
    }

  }

}
