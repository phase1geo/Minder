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

public class ExportPlantUML : Object {

  /* Exports the given drawing area to the file of the given name */
  public static bool export( string fname, DrawArea da ) {
    var  file   = File.new_for_path( fname );
    bool retval = true;
    try {
      var os = file.replace( null, false, FileCreateFlags.NONE );
      export_header( os, da );
      export_top_nodes( os, da );
      export_footer( os, da );
    } catch( Error e ) {
      retval = false;
    }
    return( retval );
  }

  private static void export_header( FileOutputStream os, DrawArea da ) {
    var start = "@startmindmap\n";
    os.write( start.data );
  }

  private static void export_footer( FileOutputStream os, DrawArea da ) {
    var start = "@endmindmap\n";
    os.write( start.data );

  }

  /* Draws each of the top-level nodes */
  private static void export_top_nodes( FileOutputStream os, DrawArea da ) {

    try {

      var nodes = da.get_nodes();
      for( int i=0; i<nodes.length; i++ ) {
        export_node( os, nodes.index( i ), 1 );
      }

    } catch( Error e ) {
      // Handle the error
    }

  }

  /* Draws the given node and its children to the output stream */
  private static void export_node( FileOutputStream os, Node node, int depth ) {

    try {

      string layout_name = node.layout.name;
      var    li          = '*';

      if( !node.is_root() && ((layout_name == _( "Horizontal" )) || (layout_name == _( "Vertical" ))) ) {
        li = ((node.side == NodeSide.LEFT) || (node.side == NodeSide.TOP)) ? '-' : '+';
      }

      var title = string.nfill( depth, li );

      if( !node.is_root() ) {
        if( node.style.node_border.is_fillable() ) {
          title += "[%s] ".printf( Utils.color_from_rgba( node.link_color ) );
        } else {
          title += "_ ";
        }
      } else {
        title += " ";
      }

      title += node.name.text.text + "\n";

      os.write( title.data );

      var children = node.children();
      for( int i=0; i<children.length; i++ ) {
        export_node( os, children.index( i ), (depth + 1) );
      }

    } catch( Error e ) {
      // Handle error
    }

  }

}
