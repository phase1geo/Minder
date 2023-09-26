
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
  static Atom  NODES_ATOM        = Atom.intern_static_string( NODES_TARGET_NAME );

  private static DrawArea?    da    = null;
  private static Array<Node>? nodes = null;
  private static Connections? conns = null;
  private static string?      text  = null;
  private static Pixbuf       image = null;
  private static bool         set_internally = false;

  enum Target {
    STRING,
    IMAGE,
    NODES
  }

  const TargetEntry[] text_target_list = {
    { "UTF8_STRING", 0, Target.STRING },
    { "text/plain",  0, Target.STRING },
    { "STRING",      0, Target.STRING }
  };

  const TargetEntry[] image_target_list = {
    { "image/png", 0, Target.IMAGE }
  };

  const TargetEntry[] node_target_list = {
    { "UTF8_STRING",     0, Target.STRING },
    { "text/plain",      0, Target.STRING },
    { "STRING",          0, Target.STRING },
    { "image/png",       0, Target.IMAGE },
    { NODES_TARGET_NAME, 0, Target.NODES }
  };

  public static void set_with_data( Clipboard clipboard, SelectionData selection_data, uint info, void* user_data_or_owner) {
    switch( info ) {
      case Target.STRING:
        if( text != null ) {
          selection_data.set_text( text, -1 );
        } else if( (nodes != null) && (nodes.length == 1) ) {
          var str = "";
          var export = (ExportText)da.win.exports.get_by_name( "text" );
          for( int i=0; i<nodes.length; i++ ) {
            str += export.export_node( da, nodes.index( i ), "" );
          }
          selection_data.set_text( str, -1 );
        }
        break;
      case Target.IMAGE:
        if( image != null ) {
          selection_data.set_pixbuf( image );
        } else if( (nodes != null) && (nodes.length == 1) && (nodes.index( 0 ).image != null) ) {
          selection_data.set_pixbuf( nodes.index( 0 ).image.get_pixbuf().copy() );
        }
        break;
      case Target.NODES:
        if( (nodes != null) && (nodes.length > 0) ) {
          var text = da.serialize_for_copy( nodes, conns );
          selection_data.@set( NODES_ATOM, 0, text.data );
        }
        break;
    }
  }

  /* Clears the class structure */
  public static void clear_data( Clipboard clipboard, void* user_data_or_owner ) {
    if( !set_internally ) {
      da    = null;
      nodes = null;
      conns = null;
      text  = null;
      image = null;
    }
    set_internally = false;
  }

  /* Copies the selected text to the clipboard */
  public static void copy_text( string txt ) {

    /* Store the data to copy */
    text           = txt;
    set_internally = true;

    /* Inform the clipboard */
    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );
    clipboard.set_with_data( text_target_list, set_with_data, clear_data, null );

  }

  public static void copy_image( Pixbuf img ) {

    /* Store the data to copy */
    image          = img;
    set_internally = true;

    /* Inform the clipboard */
    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );
    clipboard.set_with_data( image_target_list, set_with_data, clear_data, null );

  }

  /* Copies the current selected node list to the clipboard */
  public static void copy_nodes( DrawArea d ) {

    /* Store the data to copy */
    da = d;
    da.get_nodes_for_clipboard( out nodes, out conns );

    set_internally = true;

    /* Inform the clipboard */
    var clipboard = Gtk.Clipboard.get_default( Gdk.Display.get_default() );
    clipboard.set_with_data( node_target_list, set_with_data, clear_data, null );

  }

  /* Returns true if there are any nodes pasteable in the clipboard */
  public static bool node_pasteable() {

    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );

    Atom[] targets;
    clipboard.wait_for_targets( out targets );

    foreach( var target in targets ) {
      if( target.name() == NODES_TARGET_NAME ) {
        return( true );
      }
    }

    return( false );

  }

  /* Called to paste current item in clipboard to the given DrawArea */
  public static void paste( DrawArea da, bool shift ) {

    var clipboard   = Clipboard.get_default( Gdk.Display.get_default() );
    var text_needed = da.is_node_editable() || da.is_connection_editable();

    Atom[] targets;
    clipboard.wait_for_targets( out targets );

    Atom? nodes_atom = null;
    Atom? text_atom  = null;
    Atom? image_atom = null;

    /* Get the list of targets that we will support */
    foreach( var target in targets ) {
      switch( target.name() ) {
        case NODES_TARGET_NAME :  nodes_atom = nodes_atom ?? target;  break;
        case "UTF8_STRING"     :
        case "STRING"          :
        case "text/plain"      :  text_atom  = text_atom  ?? target;  break;
        case "image/png"       :  image_atom = image_atom ?? target;  break;
      }
    }

    /* If we need to handle a node, do it here */
    if( nodes_atom != null ) {
      clipboard.request_contents( nodes_atom, (c, raw_data) => {
        var data = (string)raw_data.get_data();
        if( data == null ) return;
        da.paste_nodes( data, shift );
      });

    /* If we need to handle pasting an image, do it here */
    } else if( (image_atom != null) && ((text_atom == null) || !text_needed) ) {
      clipboard.request_contents( image_atom, (c, raw_data) => {
        var data = raw_data.get_pixbuf();
        if( data == null ) return;
        da.paste_image( data, shift );
      });

    /* If we need to handle pasting text, do it here */
    } else if( text_atom != null ) {
      clipboard.request_contents( text_atom, (c, raw_data) => {
        var data = (string)raw_data.get_data();
        if( data == null ) return;
        da.paste_text( data, shift );
      });
    }

  }

  /* Returns a node link to the first node in the clipboard */
  public static void paste_node_link( DrawArea da ) {
    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );

    Atom[] targets;
    clipboard.wait_for_targets( out targets );

    foreach( var target in targets ) {
      if( target.name() == NODES_TARGET_NAME ) {
        clipboard.request_contents( target, (c, raw_data) => {
          var data = (string)raw_data.get_data();
          if( data == null ) return;
          da.paste_node_link( data );
        });
        return;
      }
    }

  }

  /* Pastes a node link or text into the given NoteView widget */
  public static void paste_into_note( NoteView note ) {

    var clipboard = Clipboard.get_default( Gdk.Display.get_default() );

    Atom[] targets;
    clipboard.wait_for_targets( out targets );

    Atom? nodes_atom = null;
    Atom? text_atom  = null;

    /* Get the list of targets that we will support */
    foreach( var target in targets ) {
      switch( target.name() ) {
        case NODES_TARGET_NAME :  nodes_atom = nodes_atom ?? target;  break;
        case "UTF8_STRING"     :
        case "STRING"          :
        case "text/plain"      :  text_atom  = text_atom  ?? target;  break;
      }
    }

    if( nodes_atom != null ) {
      clipboard.request_contents( nodes_atom, (c, raw_data) => {
        var data = (string)raw_data.get_data();
        if( data == null ) return;
        var link = DrawArea.deserialize_for_node_link( data );
        if( link != null ) {
          note.paste_node_link( link );
        }
      });

    } else if( text_atom != null ) {
      clipboard.request_contents( text_atom, (c, raw_data) => {
        var data = (string)raw_data.get_data();
        if( data == null ) return;
        note.paste_text( data );
      });
    }

  }

}
