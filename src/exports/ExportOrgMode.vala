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

  /* Constructor */
  public ExportOrgMode() {
    base( "org-mode", _( "Org-Mode" ), { ".org" }, true, false, false );
  }

  /* Add settings for Org Mode */
  public override void add_settings( Grid grid ) {
    add_setting_bool( "indent-mode", grid, _( "Indent Mode" ), _( "Export using indentation spaces" ), true );
  }

  /* Save the settings */
  public override void save_settings( Xml.Node* node ) {
    var value = get_bool( "indent-mode" );
    node->set_prop( "indent-mode", value.to_string() );
  }

  /* Load the settings */
  public override void load_settings( Xml.Node* node ) {
    var q = node->get_prop( "indent-mode" );
    if( q != null ) {
      var value = bool.parse( q );
      set_bool( "indent-mode", value );
    }
  }

  /* Exports the given drawing area to the file of the given name */
  public override bool export( string fname, DrawArea da ) {
    var  file   = File.new_for_path( fname );
    bool retval = true;
    try {
      var os = file.replace( null, false, FileCreateFlags.NONE );
      export_top_nodes( os, da );
    } catch( Error e ) {
      retval = false;
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
  private void export_top_nodes( FileOutputStream os, DrawArea da ) {

    try {

      var nodes = da.get_nodes();
      for( int i=0; i<nodes.length; i++ ) {
        string title = "* " + nodes.index( i ).name.text.text + "\n\n";
        os.write( title.data );
        if( nodes.index( i ).note != "" ) {
          string note = "\n" + linestart( "" ) + nodes.index( i ).note.replace( "\n", "\n  " );
          os.write( note.data );
        }
        var children = nodes.index( i ).children();
        for( int j=0; j<children.length; j++ ) {
          export_node( os, children.index( j ), sprefix() );
        }
      }

    } catch( Error e ) {
      // Handle the error
    }

  }

  /* Draws the given node and its children to the output stream */
  private void export_node( FileOutputStream os, Node node, string prefix ) {

    try {

      string title = prefix + (node.is_in_sequence() ? "%d. ".printf( node.index() + 1 ) : "* ");

      if( node.is_task() ) {
        if( node.is_task_done() ) {
          title += "[x] ";
        } else {
          title += "[ ] ";
        }
      }

      title += node.name.text.text.replace( "\n", wrap( prefix ) ) + "\n";

      os.write( title.data );

      if( node.note != "" ) {
        string note = "\n" + linestart( prefix ) + node.note.replace( "\n", "\n" + linestart( prefix ) ) + "\n";
        os.write( note.data );
      }

      os.write( "\n".data );

      var children = node.children();
      for( int i=0; i<children.length; i++ ) {
        export_node( os, children.index( i ), prefix + sprefix() );
      }

    } catch( Error e ) {
      // Handle error
    }

  }

}
