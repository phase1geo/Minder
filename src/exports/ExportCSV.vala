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

public class ExportCSV : Export {

  //-------------------------------------------------------------
  // Constructor
  public ExportCSV() {
    base( "csv", _( "CSV" ), { ".csv" }, true, false, false, true );
  }

  //-------------------------------------------------------------
  // Exports the given drawing area to the file of the given name
  public override bool export( string fname, MindMap map ) {
    var retval = true;
    var text   = "";
    var levels = levels( map );
    text += export_levels( levels );
    text += export_top_nodes( map, levels );
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

  private string export_levels( int levels ) {
    var str = "";
    try {
      str += "level0,note0";
      for( int i=1; i<levels; i++ ) {
        str += ",level" + i.to_string() + ",note" + i.to_string();
      }
      str += "\n";
    } catch( Error e ) {
      // Do something with error
    }
    return( str );
  }

  private int levels( MindMap map ) {
    var nodes      = map.get_nodes();
    int max_levels = 0;
    for( int i=0; i<nodes.length; i++ ) {
      int levels = child_levels( nodes.index( i ) );
      if( levels > max_levels ) {
        max_levels = levels;
      }
    }
    return( max_levels );
  }

  private int child_levels( Node node ) {
    var children   = node.children();
    int max_levels = 0;
    for( int i=0; i<children.length; i++ ) {
      int levels = child_levels( children.index( i ) );
      if( levels > max_levels ) {
        max_levels = levels;
      }
    }
    return( max_levels + 1 );
  }

  //-------------------------------------------------------------
  // Convert the given string to one that is valid for CSV files
  private string stringify( string val ) {

    // Strip any double-quotes and newlines found
    string newval = val.replace( "\"", "" ).replace( "\n", " " );

    // If the value contains any comma characters, quote the entire string
    if( newval.index_of( "," ) != -1 ) {
      return( "\"" + newval + "\"" );
    }

    return( newval );

  }

  //-------------------------------------------------------------
  // Draws each of the top-level nodes
  private string export_top_nodes( MindMap map, int levels ) {

    var retval = "";

    try {

      var nodes = map.get_nodes();
      for( int i=0; i<nodes.length; i++ ) {
        string title = stringify( nodes.index( i ).name.text.text ) + "," + stringify( nodes.index( i ).note );
        for( int j=0; j<(levels - 1); j++ ) {
          title += ",,";
        }
        title  += "\n";
        retval += title;
        var children = nodes.index( i ).children();
        for( int j=0; j<children.length; j++ ) {
          retval += export_node( children.index( j ), ",,", levels );
        }
      }

    } catch( Error e ) {
      // Handle the error
    }

    return( retval );

  }

  //-------------------------------------------------------------
  // Draws the given node and its children to the output stream
  private string export_node( Node node, string prefix, int levels ) {

    var retval = "";

    try {

      string title = prefix;

      if( node.is_task() ) {
        if( node.is_task_done() ) {
          title += " - [x] ";
        } else {
          title += " - [ ] ";
        }
      }

      title += stringify( node.name.text.text ) + "," + stringify( node.note );

      for( int i=0; i<(levels - 1 - (prefix.length / 2)); i++ ) {
        title += ",,";
      }

      title  += "\n";
      retval += title;

      var children = node.children();
      for( int i=0; i<children.length; i++ ) {
        retval += export_node( children.index( i ), prefix + ",,", levels );
      }

    } catch( Error e ) {
      // Handle error
    }

    return( retval );

  }

}
