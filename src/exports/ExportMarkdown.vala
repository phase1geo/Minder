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

using Gtk;

public class ExportMarkdown : Export {

  struct Hier {
    public int  spaces;
    public Node node;
  }

  //-------------------------------------------------------------
  // Constructor
  public ExportMarkdown() {
    base( "markdown", _( "Markdown" ), { ".md", ".markdown" }, true, true, false, true );
  }

  private bool handle_directory( string fname, out string mdfile, out string imgdir ) {
    mdfile = fname;
    imgdir = fname;
    if( get_bool( "include-image-links" ) ) {
      var filename = fname;
      var dirname  = fname;
      if( fname.has_suffix( ".md" ) ) {
        var parts = fname.split( "." );
        dirname = string.joinv( ".", parts[0:parts.length-1] );
      }
      if( DirUtils.create_with_parents( dirname, 0775 ) == 0 ) {
        imgdir = GLib.Path.build_filename( dirname, "images" );
        if( DirUtils.create_with_parents( imgdir, 0775 ) == 0 ) {
          mdfile = GLib.Path.build_filename( dirname, GLib.Path.get_basename( fname ) );
          return( true );
        }
      }
      return( false );
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Exports the given drawing area to the file of the given name
  public override bool import( string fname, MindMap map ) {
    var file        = File.new_for_path( fname );
    var current_dir = Path.get_dirname( fname );
    try {

      DataInputStream dis = new DataInputStream( file.read() );
      size_t          len;

      // Read the entire file contents
      var str = dis.read_upto( "\0", 1, out len ) + "\0";

      // Import the text
      import_text( str, map, current_dir );

      map.queue_draw();
      map.changed();

    } catch( IOError err ) {
      return( false );
    } catch( Error err ) {
      return( false );
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Creates a new node from the given information and attaches
  // it to the specified parent node
  private Node make_node( MindMap map, Node? parent, string bullet, string task, string pre_name, string current_dir, bool attach = true ) {

    NodeImage? image = null;
    var        name  = pre_name;

    try {

      MatchInfo match_info;
      var re = new Regex( """(.*)<img\s+(.*?)/>(.*)""" );

      if( re.match( name, 0, out match_info ) ) {
        var src_re   = new Regex( "src\\s*=\\s*\"(.*?)\"" );
        var pretext  = match_info.fetch( 1 ).strip();
        var attrs    = match_info.fetch( 2 );
        var posttext = match_info.fetch( 3 ).strip();
        name = (pretext == "") ? posttext : (pretext + " " + posttext);
        if( src_re.match( attrs, 0, out match_info ) ) {
          var file  = match_info.fetch( 1 );
          var w_re  = new Regex( "width\\s*=\\s*\"(.*?)\"" );
          var width = 200;
          if( w_re.match( attrs, 0, out match_info ) ) {
            width = int.parse( match_info.fetch( 1 ) );
          }
          if( !Path.is_absolute( file ) ) {
            file = Path.build_filename( current_dir, file );
          }
          image = new NodeImage.from_uri( map.image_manager, "file://" + file, width );
        }
      }

    } catch( RegexError e ) {
    }

    var node = new Node.with_name( map, name, map.layouts.get_default() );

    // Add the style component to the node
    if( parent == null ) {
      node.style = map.global_style;
      if( attach ) {
        map.model.position_root_node( node );
        map.model.add_root( node, -1 );
        map.set_current_node( node );
      }
    } else {
      node.style = StyleInspector.styles.get_style_for_level( (parent.get_level() + 1), null );
      if( attach ) {
        node.attach( parent, (int)parent.children().length, map.get_theme() );
      }
    }

    // Check the bullet type for a sequence
    if( Regex.match_simple( "\\d+\\.", bullet ) && (node.parent != null) ) {
      node.parent.sequence = true;
    }

    // Add the task information, if necessary
    if( task != "" ) {
      node.enable_task( true );
      if( (task == "x") || (task == "X") ) {
        node.set_task_done( true );
      }
    }

    // Add the node image, if necessary
    node.set_image( map.image_manager, image );

    return( node );

  }

  //-------------------------------------------------------------
  // Appends the given string to the name
  public void append_name( Node node, string str ) {
    node.name.text.append_text( " " + str.strip() );
  }

  //-------------------------------------------------------------
  // Append the given string to the note
  public void append_note( Node node, string str ) {
    node.note = "%s\n%s".printf( node.note, str ).strip();
  }

  //-------------------------------------------------------------
  // Imports a mindmap from the given text
  private void import_text( string txt, MindMap map, string current_dir ) {

    try {

      var stack   = new Array<Hier?>();
      var lines   = txt.split( "\n" );
      var re      = new Regex( "^(\\s*)((\\-|\\+|\\*|#|>|\\d+\\.)\\s*)?(\\[([ xX])\\]\\s*)?(.*)$" );
      var current = map.get_current_node();

      // Populate the stack with the current node, if one exists.  Set the spaces
      // count to -1 so that everything but a new header is added to this node.
      if( current != null ) {
        stack.append_val( {-1, current} );
      }

      foreach( string line in lines ) {

        MatchInfo match_info;
        Node      node;

        // If we found some useful text, include it here
        if( re.match( line, 0, out match_info ) ) {

          var spaces = match_info.fetch( 1 ).replace( "\t", " " ).length;
          var bullet = match_info.fetch( 3 );
          var task   = match_info.fetch( 5 );
          var str    = match_info.fetch( 6 );

          // Add note
          if( str.strip() == "" ) continue;
          if( bullet == ">" ) {
            if( stack.length > 0 ) {
              append_note( stack.index( stack.length - 1 ).node, str );
            }

          // If we don't have a bullet, we are a continuation of the previous line
          } else if( bullet == "" ) {
            append_name( stack.index( stack.length - 1 ).node, str );

          // If the stack is empty
          } else if( stack.length == 0 ) {
            node = make_node( map, null, bullet, task, str, current_dir );
            stack.append_val( {spaces, node} );

          // Add sibling node
          } else if( spaces == stack.index( stack.length - 1 ).spaces ) {
            node = make_node( map, stack.index( stack.length - 1 ).node.parent, bullet, task, str, current_dir, true );
            stack.remove_index( stack.length - 1 );
            stack.append_val( {spaces, node} );

          // Add child node
          } else if( spaces > stack.index( stack.length - 1 ).spaces ) {
            node = make_node( map, stack.index( stack.length - 1 ).node, bullet, task, str, current_dir );
            stack.append_val( {spaces, node} );

          // Add ancestor node
          } else {
            while( (stack.length > 0) && (spaces < stack.index( stack.length - 1 ).spaces) ) {
              stack.remove_index( stack.length - 1 );
            }
            if( stack.length == 0 ) {
              node = make_node( map, null, bullet, task, str, current_dir );
              stack.append_val( {spaces, node} );
            } else if( spaces == stack.index( stack.length - 1 ).spaces ) {
              node = make_node( map, stack.index( stack.length - 1 ).node.parent, bullet, task, str, current_dir );
              stack.remove_index( stack.length - 1 );
              stack.append_val( {spaces, node} );
            } else {
              node = make_node( map, stack.index( stack.length - 1 ).node, bullet, task, str, current_dir );
              stack.append_val( {spaces, node} );
            }
          }

        }

      }

    } catch( GLib.RegexError err ) {
      // TBD
    }

    // TBD

  }

  //-------------------------------------------------------------
  // EXPORTS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Exports the given drawing area to the file of the given name.
  public override bool export( string fname, MindMap map ) {
    bool retval = true;
    if( send_to_clipboard() ) {
      MinderClipboard.copy_text( export_top_nodes( map, null ) );
    } else {
      string filename, imgdir;
      if( !handle_directory( fname, out filename, out imgdir ) ) return( false );
      var file = File.new_for_path( filename );
      try {
        var os = file.replace( null, false, FileCreateFlags.NONE );
        os.write( export_top_nodes( map, imgdir ).data );
      } catch( Error e ) {
        retval = false;
      }
    }
    return( retval );
  }

  //-------------------------------------------------------------
  // Draws each of the top-level nodes
  private string export_top_nodes( MindMap map, string? imgdir ) {

    var retval = "";

    try {

      var nodes  = map.get_nodes();
      for( int i=0; i<nodes.length; i++ ) {
        var title = "# " + nodes.index( i ).name.text.text + "\n\n";
        retval += title;
        if( nodes.index( i ).note != "" ) {
          var note = "  > " + nodes.index( i ).note.replace( "\n", "\n  > " ) + "\n\n";
          retval += note;
        }
        var children = nodes.index( i ).children();
        for( int j=0; j<children.length; j++ ) {
          retval += export_node( map.image_manager, children.index( j ), imgdir );
        }
      }

    } catch( Error e ) {
      // Handle the error
    }

    return( retval );

  }

  //-------------------------------------------------------------
  // Copies the given image file to the image directory
  private bool copy_file( string imgdir, string filename ) {
    var basename = GLib.Path.get_basename( filename );
    var lname    = GLib.Path.build_filename( imgdir, basename );
    var rfile    = File.new_for_path( filename );
    var lfile    = File.new_for_path( lname );
    try {
      rfile.copy( lfile, FileCopyFlags.OVERWRITE );
    } catch( Error e ) {
      return( false );
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Draws the given node and its children to the output stream
  private string export_node( ImageManager im, Node node, string? imgdir, string prefix = "  " ) {

    var retval = "";

    try {

      var title = prefix + (node.is_in_sequence() ? "%d. ".printf( node.index() + 1 ) : "- ");

      if( node.is_task() ) {
        if( node.is_task_done() ) {
          title += "[x] ";
        } else {
          title += "[ ] ";
        }
      }

      if( (node.image != null) && (imgdir != null) && get_bool( "include-image-links" ) ) {
        var file = im.get_file( node.image.id );
        if( copy_file( imgdir, file ) ) {
          var basename = GLib.Path.get_basename( file );
          title += "<img src=\"images/" + basename +
                   "\" alt=\"image\" width=\"" + node.image.width.to_string() +
                   "\" height=\"" + node.image.height.to_string() + "\"/><br/>\n" + prefix + "  ";
        }
      }

      title  += node.name.text.text.replace( "\n", prefix + " " ) + "\n";
      retval += title;

      if( node.note != "" ) {
        string note = prefix + "  > " + node.note.replace( "\n", "\n" + prefix + "  > " ) + "\n";
        retval += note;
      }

      retval += "\n";

      var children = node.children();
      for( int i=0; i<children.length; i++ ) {
        retval += export_node( im, children.index( i ), imgdir, prefix + "  " );
      }

    } catch( Error e ) {
      // Handle error
    }

    return( retval );

  }

  //-------------------------------------------------------------
  // Add the PNG settings
  public override void add_settings( Grid grid ) {

    add_setting_bool( "include-image-links", grid, _( "Include image links" ),
      _( "Creates a directory containing the Markdown and embedded images" ), false );

  }

  //-------------------------------------------------------------
  // Save the settings
  public override void save_settings( Xml.Node* node ) {

    node->set_prop( "include-image-links", get_bool( "include-image-links" ).to_string() );

  }

  //-------------------------------------------------------------
  // Load the settings
  public override void load_settings( Xml.Node* node ) {

    var i = node->get_prop( "include-image-links" );
    if( i != null ) {
      set_bool( "include-image-links", bool.parse( i ) );
    }

  }

}
