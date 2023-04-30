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

public struct NodeHier {
  public int  spaces;
  public Node node;
  public int  first_line;
  public int  last_line;
}

public class ExportText : Export {

  /* Constructor */
  public ExportText() {
    base( "text", _( "PlainText" ), { ".txt" }, true, true, false );
  }

  /* Exports the given drawing area to the file of the given name */
  public override bool export( string fname, DrawArea da ) {

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
  public string export_top_nodes( DrawArea da ) {

    var value = "";
    var nodes = da.get_nodes();

    for( int i=0; i<nodes.length; i++ ) {
      value += "# " + nodes.index( i ).name.text.text + "\n";
      var children = nodes.index( i ).children();
      for( int j=0; j<children.length; j++ ) {
        value += export_node( da, children.index( j ) );
      }
    }

    return( value );

  }

  /* Draws the given node and its children to the output stream */
  public string export_node( DrawArea da, Node node, string prefix = "\t" ) {

    string value = prefix + "- ";

    /* Add the task information, if necessary */
    if( node.is_task() ) {
      if( node.is_task_done() ) {
        value += "[x] ";
      } else {
        value += "[ ] ";
      }
    }

    if( node.image != null ) {
      var uri = da.image_manager.get_uri( node.image.id );
      if( uri != "" ) {
        value += "![](" + uri + ") ";
      }
    }

    /* Add the node title */
    value += node.name.text.text + "\n";

    /* Add the node note, if specified */
    if( node.note != "" ) {
      value += prefix + "  > " + node.note.chomp().replace( "\n", "\n%s  > ".printf( prefix ) ) + "\n";
    }

    /* Add the children */
    var children = node.children();
    for( int i=0; i<children.length; i++ ) {
      value += export_node( da, children.index( i ), prefix + "\t" );
    }

    return( value );

  }

  /****************************************************************************/

  /* Imports a text file */
  public override bool import( string fname, DrawArea da ) {

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
      da.auto_save();

    } catch( IOError err ) {
      return( false );
    } catch( Error err ) {
      return( false );
    }

    return( true );

  }

  /* Creates a new node from the given information and attaches it to the specified parent node */
  public Node make_node( DrawArea da, string task, string img, string name ) {

    var node = new Node.with_name( da, name, da.layouts.get_default() );

    /* Add the task information, if necessary */
    if( task != "" ) {
      node.enable_task( true );
      if( (task == "x") || (task == "X") ) {
        node.set_task_done( true );
      }
    }

    /* Add the image, if specified */
    if( img != "" ) {
      stdout.printf( "Creating node image from %s\n", img );
      var ifile = File.new_for_path( img );
      var ni    = new NodeImage.from_uri( da.image_manager, ifile.get_uri(), 200 );
      node.set_image( da.image_manager, ni );
    }

    return( node );

  }

  private void parent_node( DrawArea da, Node node, Node? parent ) {
    if( parent == null ) {
      node.style = StyleInspector.styles.get_global_style();
      da.position_root_node( node );
      da.add_root( node, -1 );
      da.set_current_node( node );
    } else {
      node.style = StyleInspector.styles.get_style_for_level( (parent.get_level() + 1), null );
      node.attach( parent, (int)parent.children().length, da.get_theme() );
    }
  }

  /* Append the given string to the note */
  public void append_note( Node node, string str ) {
    node.note = "%s\n%s".printf( node.note, str ).strip();
  }

  /* Appends the given string to the node's title */
  public void append_title( Node node, string str ) {
    node.name.text.append_text( str );
  }

  public bool parse_text( DrawArea da, string txt, int tab_spaces, Array<NodeHier> stack ) {

    try {

      Node? node = null;
      var lines  = txt.split( "\n" );
      var re     = new Regex( "^(\\s*)((\\-|\\+|\\*|#|>)\\s*)?(\\[([ xX])\\]\\s*)?(!\\[[^]]*\\]\\(([^\\)]+)\\)\\s*)?(.*)$" );
      var tspace = string.nfill( ((tab_spaces <= 0) ? 1 : tab_spaces), ' ' );
      var lnum   = 0;

      foreach( string line in lines ) {

        MatchInfo match_info;

        /* If we found some useful text, include it here */
        if( re.match( line, 0, out match_info ) ) {

          var spaces = match_info.fetch( 1 ).replace( "\t", tspace ).length;
          var bullet = match_info.fetch( 3 );
          var task   = match_info.fetch( 5 );
          var img    = match_info.fetch( 7 );
          var str    = match_info.fetch( 8 );

          stdout.printf( "line: %s\n", line );
          stdout.printf( "  bullet: %s\n", bullet );

          /* Add note */
          if( str.strip() == "" ) continue;
          if( bullet == ">" ) {
            if( node != null ) {
              stdout.printf( "  Appending to note: %s\n", str );
              append_note( node, str );
              stack.index( stack.length - 1 ).last_line = lnum;
            }

          /* If we are starting a new node, create it and add it to the stack */
          } else if( (bullet == "-") || (bullet == "*") || (bullet == "+") || (bullet == "#") ) {
            node = make_node( da, task, img, str );
            stdout.printf( "Created node, task: %s, img: %s, str: %s\n", task, img, str );
            stack.append_val( {spaces, node, lnum, lnum} );

          /* Otherwise, we need to append a new line to the current title */
          } else if( node != null ) {
            stdout.printf( "  Appending to title: %s\n", str );
            append_title( node, str );
            stack.index( stack.length - 1 ).last_line = lnum;
          }

        }

        lnum++;

      }

    } catch( GLib.RegexError err ) {
      return( false );
    }

    display_node_hier( stack );

    return( true );

  }

  /* Imports the given text string */
  public void import_text( string txt, int tab_spaces, DrawArea da, bool replace, Array<Node>? nodes = null ) {

    var stack = new Array<NodeHier?>();
    if( !parse_text( da, txt, tab_spaces, stack ) ) {
      return;
    }

    var current = da.get_current_node();
    if( current != null ) {
      if( replace ) {
        da.replace_node( current, stack.index( 0 ).node );
      } else {
        parent_node( da, stack.index( 0 ).node, current );
      }
    }

    if( nodes != null ) {
      nodes.append_val( stack.index( 0 ).node );
    }

    for( int i=1; i<stack.length; i++ ) {

      var spaces = stack.index( i ).spaces;
      var node   = stack.index( i ).node;

      /* Add sibling node */
      if( spaces == stack.index( i - 1 ).spaces ) {
        parent_node( da, node, stack.index( i - 1 ).node.parent );

      /* Add child node */
      } else if( spaces > stack.index( i - 1 ).spaces ) {
        parent_node( da, node, stack.index( i - 1 ).node );

      /* Add ancestor node */
      } else {
        var parent = i - 1;
        while( (parent >= 0) && (spaces < stack.index( parent ).spaces) ) {
          parent--;
        }
        if( parent != -1 ) {
          if( spaces == stack.index( parent ).spaces ) {
            parent_node( da, node, stack.index( parent ).node.parent );
          } else {
            parent_node( da, node, stack.index( parent ).node );
          }
        }
      }

      if( nodes != null ) {
        nodes.append_val( node );
      }

    }

  }

  public void display_node_hier( Array<NodeHier> stack ) {

    stdout.printf( "Node Hierarchy\n" );
    stdout.printf( "--------------\n" );
   
    for( int i=0; i<stack.length; i++ ) {
      var entry = stack.index( i );
      stdout.printf( "  %s, spaces: %d, first: %d, last: %d\n", entry.node.name.text.text, entry.spaces, entry.first_line, entry.last_line );
    }

  }

  public bool get_node_line_range( Array<NodeHier> stack, int current_line, out int first_line, out int last_line ) {
    
    for( int i=0; i<stack.length; i++ ) {
      first_line = stack.index( i ).first_line;
      last_line  = stack.index( i ).last_line;
      if( (first_line <= current_line) && (current_line <= last_line) ) {
        return( true );
      }
    }

    return( false );

  }

}
