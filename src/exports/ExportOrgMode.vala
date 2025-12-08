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

public class ExportOrgMode : Export {

  //-------------------------------------------------------------
  // Constructor
  public ExportOrgMode() {
    base( "org-mode", _( "Org-Mode" ), { ".org" }, true, false, false, true );
  }

  //-------------------------------------------------------------
  // Add settings for Org Mode
  public override void add_settings( Grid grid ) {
    add_setting_bool( "indent-mode", grid, _( "Indent Mode" ), _( "Export using indentation spaces" ), true );
  }

  //-------------------------------------------------------------
  // Save the settings.
  public override void save_settings( Xml.Node* node ) {
    var value = get_bool( "indent-mode" );
    node->set_prop( "indent-mode", value.to_string() );
  }

  //-------------------------------------------------------------
  // Load the settings.
  public override void load_settings( Xml.Node* node ) {
    var q = node->get_prop( "indent-mode" );
    if( q != null ) {
      var value = bool.parse( q );
      set_bool( "indent-mode", value );
    }
  }

  //-------------------------------------------------------------
  // Exports the given drawing area to the file of the given name.
  public override bool export( string fname, MindMap map ) {
    bool retval = true;
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

  private string sprefix() {
    return( get_bool( "indent-mode" ) ? "  " : "*" );
  }

  private string wrap( string prefix ) {
    return( get_bool( "indent-mode" ) ? (prefix + " ") : "" );
  }

  private string linestart( string prefix ) {
    return( get_bool( "indent-mode" ) ? (prefix + "  ") : "" );
  }

  /* Draws each of the top-level nodes */
  private string export_top_nodes( MindMap map ) {

    var retval = "";

    try {

      var nodes = map.get_nodes();
      for( int i=0; i<nodes.length; i++ ) {
        string title = "* " + nodes.index( i ).name.text.text + "\n\n";
        retval += title;
        if( nodes.index( i ).note != "" ) {
          string note = "\n" + linestart( "" ) + nodes.index( i ).note.replace( "\n", "\n  " );
          retval += note;
        }
        var children = nodes.index( i ).children();
        for( int j=0; j<children.length; j++ ) {
          retval += export_node( children.index( j ), sprefix() );
        }
      }

    } catch( Error e ) {
      // Handle the error
    }

    return( retval );

  }

  /* Draws the given node and its children to the output stream */
  private string export_node( Node node, string prefix ) {

    var retval = "";

    try {

      string title = prefix + (node.is_in_sequence() ? "%d. ".printf( node.index() + 1 ) : "* ");

      if( node.is_task() ) {
        if( node.is_task_done() ) {
          title += "[x] ";
        } else {
          title += "[ ] ";
        }
      }

      title  += node.name.text.text.replace( "\n", wrap( prefix ) ) + "\n";
      retval += title;

      if( node.note != "" ) {
        string note = "\n" + linestart( prefix ) + node.note.replace( "\n", "\n" + linestart( prefix ) ) + "\n";
        retval += note;
      }

      retval += "\n";

      var children = node.children();
      for( int i=0; i<children.length; i++ ) {
        retval += export_node( children.index( i ), prefix + sprefix() );
      }

    } catch( Error e ) {
      // Handle error
    }

    return( retval );

  }

}
