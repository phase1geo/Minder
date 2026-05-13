/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/Minder)
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
using Gee;

public class ExportFileSystem : Export {

  //-------------------------------------------------------------
  // Constructor
  public ExportFileSystem() {
    base( "fs", _( "File System" ), {"*"}, true, true, true, false );
  }

  //-------------------------------------------------------------
  // Performs export to the given filename
  public override bool export( string dname, MindMap map ) {
    if( DirUtils.create( dname, 0775 ) == -1 ) {
      return( false );
    }
    for( int i=0; i<map.get_nodes().length; i++ ) {
      if( !export_node( dname, map.get_nodes().index( i ) ) ) {
        return( false );
      }
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Exports the given node contents to the given directory path
  private bool export_node( string dname, Node node ) {
    var path = Path.build_filename( dname, node.name.text.text );
    if( node.is_leaf() ) {
      try {
        FileUtils.set_contents( path, node.note );
      } catch( FileError e ) {
        return( false );
      }
    } else {
      if( DirUtils.create( path, 0775 ) == -1 ) {
        return( false );
      }
      for( int i=0; i<node.children().length; i++ ) {
        if( !export_node( path, node.children().index( i ) ) ) {
          return( false );
        }
      }
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Imports given filename into drawing area
  public override bool import( string dname, MindMap map ) {
    var node = map.model.create_root_node( Path.get_basename( dname ) );
    return( import_node( dname, node, map ) );
  }

  //-------------------------------------------------------------
  // Imports the given directory as a node tree of the given parent
  private bool import_node( string dname, Node parent, MindMap map ) {
    if( FileUtils.test( dname, FileTest.IS_DIR ) ) {
      var dir = Dir.open( dname, 0 );
      string? name;
      while( (name = dir.read_name()) != null ) {
        var node = map.model.create_child_node( parent, name );
        var path = Path.build_filename( dname, name );
        if( !import_node( path, node, map ) ) {
          return( false );
        }
      }
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Adds settings to the export dialog page
  public override void add_settings( Grid grid ) {
    // TBD
  }

  //-------------------------------------------------------------
  // Saves the settings
  public override void save_settings( Xml.Node* node ) {
    // TBD
  }

  //-------------------------------------------------------------
  // Loads the settings
  public override void load_settings( Xml.Node* node ) {
    // TBD
  } 

}


