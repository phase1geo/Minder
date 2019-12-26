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

public class UrlEditor : Popover {

  private DrawArea _da;
  private bool     _add = true;
  private Entry    _entry;
  private Button   _apply;

  /* Default constructor */
  public UrlEditor( DrawArea da ) {

    _da = da;

    relative_to = (Gtk.Window)da.get_toplevel();

    var box   = new Box( Orientation.VERTICAL, 5 );
    box.border_width = 5;

    var ebox  = new Box( Orientation.HORIZONTAL, 5 );
    var lbl   = new Label( _( "URL" ) + ":" );
    _entry = new Entry();
    _entry.width_chars = 50;
    _entry.input_purpose = InputPurpose.URL;
    _entry.activate.connect(() => {
      _apply.activate();
    });
    _entry.changed.connect( check_entry );

    ebox.pack_start( lbl,    false, false );
    ebox.pack_start( _entry, true,  false );

    _apply = new Button.with_label( _( "Apply" ) );
    _apply.get_style_context().add_class( STYLE_CLASS_SUGGESTED_ACTION );
    _apply.clicked.connect(() => {
      set_url();
      show_popover( false );
    });

    var cancel = new Button.with_label( _( "Cancel" ) );
    cancel.clicked.connect(() => {
      var node = _da.get_current_node();
      node.name.clear_selection();
      show_popover( false );
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.pack_end( _apply, false, false );
    bbox.pack_end( cancel, false, false );

    box.pack_start( ebox, false, true );
    box.pack_start( bbox, false, true );
    box.show_all();

    add( box );

  }

  /* Shows or hides this popover */
  private void show_popover( bool show ) {

#if GTK322
    if( show ) {
      popup();
    } else {
      popdown();
    }
#else
    if( show ) {
      show();
    } else {
      hide();
    }
#endif
  }

  /*
   Checks the contents of the entry string.  If it is a URL, make the action button active;
   otherwise, inactivate the action button.
  */
  private void check_entry() {
    var node = _da.get_current_node();
    _apply.set_sensitive( node.urls.is_url( _entry.text ) );
  }

  /*
   Sets the URL of the current node's selected text to the value stored in the
   popover entry.
  */
  private void set_url() {
    var node = _da.get_current_node();
    int selstart, selend, cursor;
    node.name.get_cursor_info( out cursor, out selstart, out selend );
    if( _add ) {
      node.urls.add_link( selstart, selend, _entry.text );
    } else {
      node.urls.change_link( cursor, _entry.text );
      node.name.clear_selection();
    }
    _da.changed();
  }

  /* Called when we want to add a URL to the currently selected text of the given node. */
  public void add_url() {

    var node = _da.get_current_node();

    int selstart, selend, cursor;
    node.name.get_cursor_info( out cursor, out selstart, out selend );

    /* Position the popover */
    double left, top;
    node.name.get_char_pos( selstart, out left, out top );
    Gdk.Rectangle rect = {(int)left, (int)top, 1, 1};
    pointing_to = rect;

    _add        = true;
    _entry.text = "";
    _apply.set_sensitive( false );

    show_popover( true );

  }

  /* Called when we want to edit the URL of the current node */
  public void edit_url() {

    var node = _da.get_current_node();

    int selstart, selend, cursor;
    node.name.get_cursor_info( out cursor, out selstart, out selend );

    /* Position the popover */
    double left, top;
    var link = node.urls.find_link( cursor );
    node.name.get_char_pos( link.spos, out left, out top );
    Gdk.Rectangle rect = {(int)left, (int)top, 1, 1};
    pointing_to = rect;

    _add        = false;
    _entry.text = link.url;
    _apply.set_sensitive( true );

    show_popover( true );

  }

}
