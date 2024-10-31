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
using Gdk;

public class QuickEntry : Gtk.Window {

  private DrawArea         _da;
  private TextView         _entry;
  private Button           _apply;
  private Array<NodeHier?> _node_stack = null;
  private ExportText       _export;

  public QuickEntry( DrawArea da, bool replace, GLib.Settings settings ) {

    /* Configure the window */
    default_width   = 500;
    default_height  = 500;
    modal           = true;
    deletable       = false;
    title           = _( "Quick Entry" );
    transient_for   = da.win;
    window_position = WindowPosition.CENTER_ON_PARENT;

    /* Initialize member variables */
    _da     = da;
    _export = (ExportText)da.win.exports.get_by_name( "text" );

    /* Add window elements */
    var box = new Box( Orientation.VERTICAL, 0 );

    /* Create the text entry area */
    _entry = new TextView() {
      border_width  = 5,
      bottom_margin = 0,
      wrap_mode     = Gtk.WrapMode.WORD
    };
    _entry.add_css_class( "textfield" );

    var key = new EventControllerKey();
    _entry.add_controller( key );
    _entry.key_pressed.connect( on_keypress );

    var drop = new DropTarget();
    _entry.add_controller( drop );

    drop.drag_motion.connect( handle_drag_motion );
    drop.drop.connect( handle_drop );


    _entry.buffer.insert_text.connect( handle_text_insertion );
    _entry.buffer.create_tag( "node", "background_rgba", Utils.color_from_string( "grey90" ), null );

    /* Handle any changes to the side of the entry */
    _entry.size_allocate.connect((alloc) => {
      var new_margin = ((alloc.height - 100) < 0) ? 0 : (alloc.height - 100);
      if( _entry.bottom_margin != new_margin ) {
        _entry.bottom_margin = new_margin;
      }
    });

    /* Create the scrolled window for the text entry area */
    var sw = new ScrolledWindow() {
      child = _entry
    };

    var helpgrid = new Grid() {
      border_width = 5
    };
    var help_title = make_help_label( _( "Help for inputting node information:" ) + "\n" );
    var help_line  = make_help_label( "  - " + _( "Each line of text describes either the title of a node or note information for a node." ) );
    var help_tab0  = make_help_label( "  - <b>" + _( "Tab" ) + "</b>:" );
    var help_tab1  = make_help_label( "  " + _( "Creates a child node of the previous node." ) );
    var help_hdr0  = make_help_label( "  - <b>#</b>:" );
    var help_hdr1  = make_help_label( "  " + _( "If this character is the first non-whitespace character, makes a new root node from the title that follows." ) );
    var help_node0 = make_help_label( "  - <b>*, - or +</b>:" );
    var help_node1 = make_help_label( "  " + _( "If this character is the first non-whitespace character, make a new node from the title that follows." ) );
    var help_note0 = make_help_label( "  - <b>&gt;</b>:" );
    var help_note1 = make_help_label( "  " + _( "If this character is the first non-whitespace character, the following line is appended to the previous node's note." ) );
    var help_img0  = make_help_label( "  - <b>!</b> <i>" + _( "URI" ) + "</i>:" );
    var help_img1  = make_help_label( "  " + _( "If this character is the first non-whitespace character, adds an image from the URI to the previous node" ) );
    var help_utsk0 = make_help_label( "  - <b>[ ]</b>:" );
    var help_utsk1 = make_help_label( "  " + _( "If this follows *, + or -, the node is made an uncompleted task." ) );
    var help_ctsk0 = make_help_label( "  - <b>[x] or [X]</b>:" );
    var help_ctsk1 = make_help_label( "  " + _( "If this follows *, + or -, the node is made a completed task." ) );
    helpgrid.attach( help_title, 0, 0, 2 );
    helpgrid.attach( help_line,  0, 1, 2 );
    helpgrid.attach( help_tab0,  0, 2 );
    helpgrid.attach( help_tab1,  1, 2 );
    helpgrid.attach( help_hdr0,  0, 3 );
    helpgrid.attach( help_hdr1,  1, 3 );
    helpgrid.attach( help_node0, 0, 4 );
    helpgrid.attach( help_node1, 1, 4 );
    helpgrid.attach( help_note0, 0, 5 );
    helpgrid.attach( help_note1, 1, 5 );
    helpgrid.attach( help_img0,  0, 6 );
    helpgrid.attach( help_img1,  1, 6 );
    helpgrid.attach( help_utsk0, 0, 7 );
    helpgrid.attach( help_utsk1, 1, 7 );
    helpgrid.attach( help_ctsk0, 0, 8 );
    helpgrid.attach( help_ctsk1, 1, 8 );

    var helprev = new Revealer() {
      halign       = Align.FILL,
      valign       = Align.END,
      reveal_child = false,
      child        = helpgrid
    };

    var info = new Button.from_icon_name( "dialog-information-symbolic" ) {
      halign = Align.START,
      has_frame = false
    };
    info.clicked.connect(() => {
      helprev.reveal_child = !helprev.reveal_child;
    });
    bbox.append( info );

    if( replace ) {
      _apply = new Button.with_label( _( "Replace" ) ) {
        halign = Align.END
      };
      _apply.add_css_class( STYLE_CLASS_SUGGESTED_ACTION );
      _apply.clicked.connect( () => {
        if( handle_replace() ) {
          close();
        } else {
          helprev.reveal_child = true;
          help_node0.add_css_class( "highlighted" );
          help_node1.add_css_class( "highlighted" );
        }
      });
      if( !da.is_node_selected() ) _apply.set_sensitive( false );
    } else {
      _apply = new Button.with_label( _( "Insert" ) ) {
        halign = Align.END
      };
      _apply.add_css_class( STYLE_CLASS_SUGGESTED_ACTION );
      _apply.clicked.connect(() => {
        if( handle_insert() ) {
          close();
        } else {
          helprev.reveal_child = true;
          help_node0.add_css_class( "highlighted" );
          help_node1.add_css_class( "highlighted" );
        }
      });
    }

    var cancel = new Button.with_label( _( "Cancel" ) ) {
      halign = Align.END
    };
    cancel.clicked.connect(() => {
      close();
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign       = Align.FILL,
      valign       = Align.END,
      border_width = 5
    };
    bbox.append( info );
    bbox.append( _apply );
    bbox.append( cancel );

    box.append( sw );
    box.append( bbox );
    box.append( helprev );

    append( box );

  }

  private Label make_help_label( string str ) {
    var lbl = new Label( str );
    lbl.use_markup = true;
    lbl.xalign     = (float)0;
    lbl.get_style_context().add_class( "greyed-label" );
    return( lbl );
  }

  /* Called whenever text is inserted by the user (either by entry or by paste) */
  private void handle_text_insertion( ref TextIter pos, string new_text, int new_text_length ) {
    var cleaned = (pos.get_offset() == 0) ? new_text.chug() : new_text;
    if( cleaned != new_text ) {
      var void_entry = (void*)_entry;
      SignalHandler.block_by_func( void_entry, (void*)handle_text_insertion, this );
      _entry.buffer.insert_text( ref pos, cleaned, cleaned.length );
      _node_stack = null;
      SignalHandler.unblock_by_func( void_entry, (void*)handle_text_insertion, this );
      Signal.stop_emission_by_name( _entry.buffer, "insert_text" );
    }
  }

  private void clear_node_tag() {

    TextIter first, last;

    /* Clear the node tag */
    _entry.buffer.get_start_iter( out first );
    _entry.buffer.get_end_iter( out last );
    _entry.buffer.remove_tag_by_name( "node", first, last );

  }

  /* Called whenever we drag something over the canvas */
  private DragAction? handle_drag_motion( double x, double y ) {

    if( _node_stack == null ) {
      _node_stack = new Array<NodeHier>();
      if( !_export.parse_text( _da, _entry.buffer.text, _da.settings.get_int( "quick-entry-spaces-per-tab" ), _node_stack ) ) {
        _node_stack = null;
      }
    }

    /* Clear the node tag */
    clear_node_tag();

    if( _node_stack != null ) {

      TextIter iter, first, last;
      int first_line, last_line, line_top;

      _entry.get_line_at_y( out iter, y, out line_top );
      var node_info = _export.get_node_at_line( _node_stack, iter.get_line() );

      if( node_info != null ) {
        _entry.buffer.get_iter_at_line( out first, node_info.first_line );
        _entry.buffer.get_iter_at_line( out last,  (node_info.last_line + 1) );
        _entry.buffer.apply_tag_by_name( "node", first, last );
      }

      return( Gdk.DragAction.COPY );

    }

    return( null );

  }

  /* Called when something is dropped on the DrawArea */
  private bool handle_drop( Value val, double x, double y ) {

    stdout.printf( "In handle_drop, val.type_name: %s\n", val.type_name );

    if( val.type_name == "string" ) {

      TextIter iter;
      Node     node;
      int      line_top;
      string   prefix;

      _entry.get_line_at_y( out iter, y, out line_top );
      var node_info = _export.get_node_at_line( _node_stack, iter.get_line() );

      if( node_info != null ) {

        TextIter first, last;
        var node_str = "";

        foreach( var uri in data.get_uris() ) {
          var node_image = new NodeImage.from_uri( _da.image_manager, uri, 200 );
          node_info.node.set_image( _da.image_manager, node_image );
          if( node_str != "" ) {
            node_str += "\n";
          }
          node_str += _export.export_node( _da, node_info.node, string.nfill( node_info.spaces, ' ' ) );
        }

        /* Perform the text substitution */
        _entry.buffer.get_iter_at_line( out first, node_info.first_line );
        _entry.buffer.get_iter_at_line( out last,  (node_info.last_line + 1) );
        _entry.buffer.delete( ref first, ref last );
        _entry.buffer.insert( ref first, node_str, node_str.length );

        /* Make sure that we clear the node stack */
        _node_stack = null;

      }

    }

    clear_node_tag();

  }

  /* Returns the text from the start of the current line to the current insertion cursor */
  private string get_line_text( int adjust ) {

    TextIter current;
    TextIter startline;
    TextIter endline;
    var      buf = _entry.buffer;

    buf.get_iter_at_mark( out current, buf.get_insert() );

    /* Adjust the line */
    if( adjust < 0 ) {
      current.backward_lines( 0 - adjust );
    } else if( adjust > 0 ) {
      current.backward_lines( adjust );
    }

    buf.get_iter_at_line( out startline, current.get_line() );
    buf.get_iter_at_line( out endline,   current.get_line() + 1 );

    return( buf.get_text( startline, endline, true ) );

  }

  /* Returns the text from the start of the current line to the current insertion cursor */
  private string get_start_to_current_text() {

    TextIter startline;
    TextIter endline;
    var      buf = _entry.buffer;

    /* Get the text on the current line */
    buf.get_iter_at_mark( out endline,   buf.get_insert() );
    buf.get_iter_at_line( out startline, endline.get_line() );

    return( buf.get_text( startline, endline, true ) );

  }

  /* Returns the whitespace at the beginning of the current line */
  private bool get_whitespace( string line, out string wspace ) {

    wspace = "";

    try {

      MatchInfo match_info;
      var       re = new Regex( "^([ \\t]*)" );

      if( re.match( line, 0, out match_info ) ) {
        wspace = match_info.fetch( 1 );
        return( true );
      }

    } catch( RegexError err ) {
      return( false );
    }

    return( false );

  }

  /* Returns true if the current line describes the start of a new node */
  private bool is_node_line( string line ) {
    return( Regex.match_simple( "^[ \\t]*[+*#-]", line ) );
  }

  /* Returns true if the current line is a blank line */
  private bool is_blank_line( string line ) {
    return( line.strip() == "" );
  }

  /* Converts the given whitespace to all spaces */
  private string tabs_to_spaces( string wspace ) {
    var tspace = string.nfill( 8, ' ' );
    return( wspace.replace( "\t", tspace ) );
  }

  /* Aligns the given prefix whitespace to be tabbed properly */
  private string align_to_tab( string wspace ) {
    var ws = tabs_to_spaces( wspace );
    return( string.nfill( (ws.char_count() / 8), '\t' ) );
  }

  /* Deletes the whitespace on the current line */
  private void delete_whitespace( string? ins_text = null ) {

    string ws;
    if( get_whitespace( get_line_text( 0 ), out ws ) ) {

      TextIter current;
      TextIter start;
      var      buf = _entry.buffer;

      buf.get_iter_at_mark( out current, buf.get_insert() );
      buf.get_iter_at_line( out start,   current.get_line() );

      var end = start.copy();
      end.forward_chars( ws.char_count() );

      buf.delete( ref start, ref end );

      if( ins_text != null ) {
        buf.insert_text( ref start, ins_text, ins_text.length );
      }

    }

  }

  /* Handles any keypresses in the quick entry text field */
  private bool on_keypress( int keyval, int keycode, ModifierType state ) {

    var control = (bool)(state & ModifierType.CONTROL_MASK);
    var shift   = (bool)(state & ModifierType.SHIFT_MASK);
    var ch      = (unichar)keyval;

    switch( keyval ) {
      case Key.space        :  return( handle_space() );
      case Key.Return       :  return( handle_return( control ) );
      case Key.Tab          :  return( handle_tab( false ) );
      case Key.ISO_Left_Tab :  return( handle_tab( true ) );
      default             :
        if( ch.isprint() ) {
          return( handle_printable( ch.to_string() ) );
        }
        break;
    }

    return( false );

  }

  /* If the user attempts to hit the space bar when adding front-end whitespace, don't insert it */
  private bool handle_space() {

    return( get_start_to_current_text().strip() == "" );

  }

  /* If the return key is pressed, we will automatically indent the next line */
  private bool handle_return( bool control ) {

    if( control ) {
      _apply.clicked();
      return( false );
    }

    string wspace;

    if( get_whitespace( get_line_text( 0 ), out wspace ) ) {
      var prefix = align_to_tab( wspace );
      var ins    = "\n" + prefix;
      _entry.buffer.insert_at_cursor( ins, ins.length );
      return( true );
    }

    return( false );

  }

  /* If the Tab key is pressed, only allow it if it is valid to do so */
  private bool handle_tab( bool shift ) {

    TextIter current;
    var      prev = "";
    var      curr = "";
    var      line = get_line_text( 0 );

    _entry.buffer.get_iter_at_mark( out current, _entry.buffer.get_insert() );

    if( !shift ) {
      if( current.get_line() == 0 ) {
        return( true );
      } else if( get_whitespace( line, out curr ) && get_whitespace( get_line_text( -1 ), out prev ) && (is_blank_line( line ) || is_node_line( line )) ) {
        if( tabs_to_spaces( curr ).length <= tabs_to_spaces( prev ).length ) {
          var prefix = align_to_tab( curr ) + "\t";
          if( is_blank_line( line ) ) {
            prefix += "- ";
          }
          delete_whitespace( prefix );
        }
      }
    } else {
      if( get_whitespace( line, out curr ) && (is_blank_line( line ) || is_node_line( line )) ) {
        var prefix = align_to_tab( curr );
        if( prefix.char_count() > 0 ) {
          prefix = prefix.substring( prefix.index_of_nth_char( 1 ) );
        }
        if( is_blank_line( line ) ) {
          prefix += "- ";
        }
        delete_whitespace( prefix );
      }
    }

    return( true );

  }

  private bool handle_printable( string str ) {

    TextIter current;
    var      prev = "";
    var      curr = "";

    _entry.buffer.get_iter_at_mark( out current, _entry.buffer.get_insert() );

    if( get_start_to_current_text().strip() == "" ) {
      if( (str == "-") || (str == "+") || (str == "*") || (str == "#") ) {
        var ins = str + " ";
        _entry.buffer.insert_at_cursor( ins, ins.length );
        return( true );
      } else if( (str == ">") || (str == "!") ) {
        var ins = "  " + str + " ";
        _entry.buffer.insert_at_cursor( ins, ins.length );
        return( true );
      } else {
        var ins = "  ";
        _entry.buffer.insert_at_cursor( ins, ins.length );
      }
    }

    return( false );

  }

  /* Inserts the specified nodes into the given drawing area */
  private bool handle_insert() {
    var nodes  = new Array<Node>();
    var node   = _da.get_current_node();
    _export.import_text( _entry.buffer.text, _da.settings.get_int( "quick-entry-spaces-per-tab" ), _da, false, nodes );
    if( nodes.length == 0 ) return( false );
    _da.undo_buffer.add_item( new UndoNodesInsert( _da, nodes ) );
    _da.set_current_node( nodes.index( 0 ) );
    _da.queue_draw();
    _da.auto_save();
    _da.see();
    return( true );
  }

  /* Replaces the specified nodes into the given drawing area */
  private bool handle_replace() {
    var nodes  = new Array<Node>();;
    var node   = _da.get_current_node();
    var parent = node.parent;
    _export.import_text( _entry.buffer.text, _da.settings.get_int( "quick-entry-spaces-per-tab" ), _da, true, nodes );
    if( nodes.length == 0 ) return( false );
    _da.undo_buffer.add_item( new UndoNodesReplace( node, nodes ) );
    _da.set_current_node( nodes.index( 0 ) );
    _da.queue_draw();
    _da.auto_save();
    _da.see();
    return( true );
  }

  /* Preloads the text buffer with the given text */
  public void preload( string value ) {
    _entry.buffer.insert_at_cursor( value, value.length );
  }

}
