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

public class ExportMarkdown : Export {

  /* Constructor */
  public ExportMarkdown() {
    base( "markdown", _( "Markdown" ), { ".md", ".markdown" }, true, false, false );
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

  /* Exports the given drawing area to the file of the given name */
  public override bool export( string fname, DrawArea da ) {
    string filename, imgdir;
    if( !handle_directory( fname, out filename, out imgdir ) ) return( false );
    var  file     = File.new_for_path( filename );
    bool retval   = true;
    try {
      var os = file.replace( null, false, FileCreateFlags.NONE );
      export_top_nodes( os, da, imgdir );
    } catch( Error e ) {
      retval = false;
    }
    return( retval );
  }

  /* Draws each of the top-level nodes */
  private void export_top_nodes( FileOutputStream os, DrawArea da, string imgdir ) {

    try {

      var nodes = da.get_nodes();
      for( int i=0; i<nodes.length; i++ ) {
        string title = "# " + nodes.index( i ).name.text.text + "\n\n";
        os.write( title.data );
        if( nodes.index( i ).note != "" ) {
          string note = "  > " + nodes.index( i ).note.replace( "\n", "\n  > " );
          os.write( note.data );
        }
        var children = nodes.index( i ).children();
        for( int j=0; j<children.length; j++ ) {
          export_node( os, da.image_manager, children.index( j ), imgdir );
        }
      }

    } catch( Error e ) {
      // Handle the error
    }

  }

  /* Copies the given image file to the image directory */
  private bool copy_file( string imgdir, string filename ) {
    var basename = GLib.Path.get_basename( filename );
    var lname    = GLib.Path.build_filename( imgdir, basename );
    var rfile    = File.new_for_path( filename );
    var lfile    = File.new_for_path( lname );
    stdout.printf( "basename: %s, lname: %s, filename: %s\n", basename, lname, filename );
    try {
      rfile.copy( lfile, FileCopyFlags.OVERWRITE );
    } catch( Error e ) {
      stdout.printf( "message: %s\n", e.message );
      return( false );
    }
    return( true );
  }

  /* Draws the given node and its children to the output stream */
  private void export_node( FileOutputStream os, ImageManager im, Node node, string imgdir, string prefix = "  " ) {

    try {

      var title = prefix + "- ";

      if( node.is_task() ) {
        if( node.is_task_done() ) {
          title += "[x] ";
        } else {
          title += "[ ] ";
        }
      }

      if( (node.image != null) && get_bool( "include-image-links" ) ) {
        var file = im.get_file( node.image.id );
        if( copy_file( imgdir, file ) ) {
          var basename = GLib.Path.get_basename( file );
          title += "<img src=\"images/" + basename +
                   "\" alt=\"image\" width=\"" + node.image.width.to_string() +
                   "\" height=\"" + node.image.height.to_string() + "\"/>\n" + prefix + "  ";
        }
      }

      title += node.name.text.text.replace( "\n", prefix + " " ) + "\n";

      os.write( title.data );

      if( node.note != "" ) {
        string note = prefix + "  > " + node.note.replace( "\n", "\n" + prefix + "  > " ) + "\n";
        os.write( note.data );
      }

      os.write( "\n".data );

      var children = node.children();
      for( int i=0; i<children.length; i++ ) {
        export_node( os, im, children.index( i ), imgdir, prefix + "  " );
      }

    } catch( Error e ) {
      // Handle error
    }

  }

  /* Add the PNG settings */
  public override void add_settings( Grid grid ) {

    add_setting_bool( "include-image-links", grid, _( "Include image links" ),
      _( "Creates a directory containing the Markdown and embedded images" ), false );

  }

  /* Save the settings */
  public override void save_settings( Xml.Node* node ) {

    node->set_prop( "include-image-links", get_bool( "include-image-links" ).to_string() );

  }

  /* Load the settings */
  public override void load_settings( Xml.Node* node ) {

    var i = node->get_prop( "include-image-links" );
    if( i != null ) {
      set_bool( "include-image-links", bool.parse( i ) );
    }

  }

}
