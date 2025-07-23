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

public class UrlEditor : Box {

  private MindMap _map;
  private bool    _add = true;
  private Entry   _entry;
  private Button  _apply;

  public signal void open();
  public signal void close();

  /* Default constructor */
  public UrlEditor( DrawArea da ) {

    Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _map = da.map;

    var lbl   = new Label( _( "URL" ) + ":" );
    _entry = new Entry() {
      width_chars   = 50,
      input_purpose = InputPurpose.URL
    };
    _entry.activate.connect(() => {
      _apply.activate();
    });
    _entry.changed.connect( check_entry );

    var ebox = new Box( Orientation.HORIZONTAL, 5 );
    ebox.append( lbl );
    ebox.append( _entry );

    _apply = new Button.with_label( _( "Apply" ) ) {
      halign = Align.END
    };
    _apply.add_css_class( Granite.STYLE_CLASS_SUGGESTED_ACTION );
    _apply.clicked.connect(() => {
      set_url();
      close();
    });

    var cancel = new Button.with_label( _( "Cancel" ) ) {
      halign = Align.END
    };
    cancel.clicked.connect(() => {
      var ct = current_text();
      if( ct != null ) {
        ct.clear_selection();
      }
      close();
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.append( _apply );
    bbox.append( cancel );

    append( ebox );
    append( bbox );

  }

  /* Returns the current canvas text to operate on */
  private CanvasText? current_text() {
    CanvasText? ct = null;
    if( _map.get_current_node() != null ) {
      ct = _map.get_current_node().name;
    } else if( _map.get_current_callout() != null ) {
      ct = _map.get_current_callout().text;
    }
    return( ct );
  }

  /*
   Checks the contents of the entry string.  If it is a URL, make the action button active;
   otherwise, inactivate the action button.
  */
  private void check_entry() {
    _apply.set_sensitive( Utils.is_url( _entry.text ) );
  }

  /*
   Sets the URL of the current canvas text's selected text to the value stored in the
   popover entry.
  */
  private void set_url() {
    var node     = _map.get_current_node();
    var callout  = _map.get_current_callout();
    var ct       = current_text();
    var selected = false;
    if( node != null ) {
      selected = node.mode == NodeMode.CURRENT;
      if( selected ) {
        _map.model.set_node_mode( node, NodeMode.EDITABLE );
      }
    } else if( callout != null ) {
      selected = callout.mode == CalloutMode.SELECTED;
      if( selected ) {
        _map.model.set_callout_mode( callout, CalloutMode.EDITABLE );
      }
    }
    if( ct != null ) {
      if( !_add ) {
        ct.remove_tag( FormatTag.URL, _map.undo_text );
      }
      ct.add_tag( FormatTag.URL, _entry.text, false, _map.undo_text );
      ct.clear_selection();
      if( selected ) {
        if( node != null ) {
          _map.model.set_node_mode( node, NodeMode.CURRENT );
        } else if( callout != null ) {
          _map.model.set_callout_mode( callout, CalloutMode.SELECTED );
        }
      }
      _map.queue_draw();
      _map.auto_save();
    }
  }

  /* Called when we want to add a URL to the currently selected text of the given node. */
  public void add_url() {

    var ct = current_text();

    int selstart, selend, cursor;
    ct.get_cursor_info( out cursor, out selstart, out selend );

    /* Position the popover */
    double left, top, bottom;
    int line;
    ct.get_char_pos( selstart, out left, out top, out bottom, out line );
    var int_left = (int)left;
    var int_top  = (int)top;
    Gdk.Rectangle rect = {int_left, int_top, 1, 1};

    _add = true;
    set_url_from_clipboard();

    Idle.add(() => {
      open();
      return( false );
    });

  }

  /* Removes the current URLs from the given node */
  public void remove_url() {
    var ct       = current_text();
    var node     = _map.get_current_node();
    var callout  = _map.get_current_callout();
    var selected = false;
    if( node != null ) {
      selected = node.mode == NodeMode.CURRENT;
      if( selected ) {
        _map.model.set_node_mode( node, NodeMode.EDITABLE );
      }
    } else if( callout != null ) {
      selected = callout.mode == CalloutMode.SELECTED;
      if( selected ) {
        _map.model.set_callout_mode( callout, CalloutMode.EDITABLE );
      }
    }
    if( ct != null ) {
      ct.remove_tag( FormatTag.URL, _map.undo_text );
      ct.clear_selection();
      if( selected ) {
        if( node != null ) {
          _map.model.set_node_mode( node, NodeMode.CURRENT );
        } else if( callout != null ) {
          _map.model.set_callout_mode( callout, CalloutMode.SELECTED );
        }
      }
      _map.queue_draw();
      _map.auto_save();
    }
  }

  /*
   Returns the URL that is in the clipboard (if one exists); otherwise,
   returns the empty string.
  */
  private void set_url_from_clipboard() {
    var clipboard   = Display.get_default().get_clipboard();
    if( clipboard.get_formats().contain_gtype( Type.STRING ) ) {
      try {
        clipboard.read_text_async.begin( null, (obj, res) => {
          var text = clipboard.read_text_async.end( res );
          if( text != null ) {
            _entry.text = text;
            check_entry();
          }
        });
      } catch( Error e ) {}
    }
  }

  /* Called when we want to edit the URL of the current node */
  public void edit_url() {

    var ct = current_text();

    int selstart, selend, cursor;
    ct.get_cursor_info( out cursor, out selstart, out selend );

    /* Position the popover */
    double left, top, bottom;
    int    line;
    var links = ct.text.get_full_tags_in_range( FormatTag.URL, cursor, cursor );
    ct.get_char_pos( links.index( 0 ).start, out left, out top, out bottom, out line );
    var int_left = (int)left;
    var int_top  = (int)top;
    Gdk.Rectangle rect = {int_left, int_top, 1, 1};

    _add        = false;
    _entry.text = links.index( 0 ).extra;
    _apply.set_sensitive( true );

    open();

  }

}
