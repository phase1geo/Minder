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
using GLib;
using Gdk;

public class MinderClipboard {

  const string NODES_TARGET_NAME = "x-application/minder-nodes";

  //-------------------------------------------------------------
  // Copies the selected text to the clipboard
  public static void copy_text( string txt ) {
    var clipboard = Display.get_default().get_clipboard();
    clipboard.set_text( txt );
  }

  //-------------------------------------------------------------
  // Copies the given image to the clipboard.
  public static void copy_image( Pixbuf img ) {
    var clipboard = Display.get_default().get_clipboard();
    var texture   = Texture.for_pixbuf( img );
    clipboard.set_texture( texture );
  }

  //-------------------------------------------------------------
  // Copies the given image buffer to the clipboard.
  public static void copy_image_buffer( uint8[] img ) {
    var clipboard = Display.get_default().get_clipboard();
    var bytes     = new Bytes( img );
    var texture   = Texture.from_bytes( bytes );
    clipboard.set_texture( texture );
  }

  //-------------------------------------------------------------
  // Copies the current selected node list to the clipboard
  public static void copy_nodes( MindMap map ) {

    Array<Node> nodes;
    Connections conns;
    NodeGroups  groups;

    /* Store the data to copy */
    map.model.get_nodes_for_clipboard( out nodes, out conns, out groups );

    /* Inform the clipboard */
    var clipboard = Display.get_default().get_clipboard();
    var text      = map.model.serialize_for_copy( nodes, conns, groups );

    var bytes = new Bytes( text.data );
    var provider = new ContentProvider.for_bytes( NODES_TARGET_NAME, bytes );
    clipboard.set_content( provider );

  }

  //-------------------------------------------------------------
  // Returns true if there are any nodes pasteable in the clipboard
  public static bool node_pasteable() {
    var clipboard = Display.get_default().get_clipboard();
    return( clipboard.get_formats().contain_mime_type( NODES_TARGET_NAME ) );
  }

  //-------------------------------------------------------------
  // Returns true if an image is in the clipboard.
  public static bool image_pasteable() {
    var clipboard = Display.get_default().get_clipboard();
    return( clipboard.get_formats().contain_mime_type( "image/png" ) );
  }

  //-------------------------------------------------------------
  // Returns true if text is in the clipboard.
  public static bool text_pasteable() {
    var clipboard = Display.get_default().get_clipboard();
    return( clipboard.get_formats().contain_gtype( Type.STRING ) );
  }

  //-------------------------------------------------------------
  // Called to paste current item in clipboard to the given DrawArea
  public static void paste( MindMap map, bool shift ) {

    var clipboard   = Display.get_default().get_clipboard();
    var text_needed = map.is_node_editable() || map.is_connection_editable();

    try {
      if( clipboard.get_formats().contain_mime_type( NODES_TARGET_NAME ) ) {
        clipboard.read_async.begin( { NODES_TARGET_NAME }, 0, null, (obj, res) => {
          string str;
          var stream = clipboard.read_async.end( res, out str );
          var contents = Utils.read_stream( stream );
          map.model.paste_nodes( contents, shift );
        });
      } else if( clipboard.get_formats().contain_mime_type( "image/png" ) || !text_needed ) {
        clipboard.read_texture_async.begin( null, (ob, res) => {
          var texture = clipboard.read_texture_async.end( res );
          if( texture != null ) {
            var pixbuf = Utils.texture_to_pixbuf( texture );
            map.model.paste_image( pixbuf, true );
          }
        });
      } else if( clipboard.get_formats().contain_gtype( Type.STRING ) ) {
        clipboard.read_text_async.begin( null, (obj, res) => {
          var text = clipboard.read_text_async.end( res );
          map.model.paste_text( text, shift );
        });
      }
    } catch( Error e ) {}

  }

  //-------------------------------------------------------------
  // Returns a node link to the first node in the clipboard
  public static void paste_node_link( MindMap map ) {

    var clipboard = Display.get_default().get_clipboard();

    try {
      if( clipboard.get_formats().contain_mime_type( NODES_TARGET_NAME ) ) {
        clipboard.read_async.begin( { NODES_TARGET_NAME }, 0, null, (obj, res) => {
          string str;
          var stream = clipboard.read_async.end( res, out str );
          var contents = Utils.read_stream( stream );
          map.model.paste_node_link( contents );
        });
      }
    } catch( Error e ) {}

  }

  //-------------------------------------------------------------
  // Pastes a node link or text into the given NoteView widget
  public static void paste_into_note( NoteView note ) {

    var clipboard = Display.get_default().get_clipboard();

    try {
      if( clipboard.get_formats().contain_mime_type( NODES_TARGET_NAME ) ) {
        clipboard.read_async.begin( { NODES_TARGET_NAME }, 0, null, (obj, res) => {
          string str;
          var stream   = clipboard.read_async.end( res, out str );
          var contents = Utils.read_stream( stream );
          var link     = MapModel.deserialize_for_node_link( contents );
          if( link != null ) {
            note.paste_node_link( link );
          }
        });
      } else if( clipboard.get_formats().contain_gtype( Type.STRING ) ) {
        clipboard.read_text_async.begin( null, (obj, res) => {
          var text = clipboard.read_text_async.end( res );
          note.paste_text( text );
        });
      }
    } catch( Error e ) {}

  }

}
