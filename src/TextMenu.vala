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

public class TextMenu : Gtk.Menu {

  DrawArea     _da;
  Gtk.MenuItem _copy;
  Gtk.MenuItem _cut;
  Gtk.MenuItem _paste;
  Gtk.MenuItem _emoji;
  Gtk.MenuItem _add_link;
  Gtk.MenuItem _del_link;
  Gtk.MenuItem _edit_link;

  public TextMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    _copy = new Gtk.MenuItem.with_label( _( "Copy" ) );
    _copy.activate.connect( copy );
    Utils.add_accel_label( _copy, 'c', Gdk.ModifierType.CONTROL_MASK );

    _cut = new Gtk.MenuItem.with_label( _( "Cut" ) );
    _cut.activate.connect( cut );
    Utils.add_accel_label( _cut, 'x', Gdk.ModifierType.CONTROL_MASK );

    _paste = new Gtk.MenuItem.with_label( _( "Paste" ) );
    _paste.activate.connect( paste );
    Utils.add_accel_label( _paste, 'v', Gdk.ModifierType.CONTROL_MASK );

    _emoji = new Gtk.MenuItem.with_label( _( "Insert Emoji" ) );
    _emoji.activate.connect( insert_emoji );
    Utils.add_accel_label( _emoji, '.', Gdk.ModifierType.CONTROL_MASK );

    _add_link = new Gtk.MenuItem.with_label( _( "Add Link" ) );
    _add_link.activate.connect( add_link );
    // Utils.add_accel_label( _delete, 'v', Gdk.ModifierType.CONTROL_MASK );

    _del_link = new Gtk.MenuItem.with_label( _( "Remove Link" ) );
    _del_link.activate.connect( remove_link );
    // Utils.add_accel_label( _add_link, 'v', Gdk.ModifierType.CONTROL_MASK );

    _edit_link = new Gtk.MenuItem.with_label( _( "Edit Link" ) );
    _edit_link.activate.connect( edit_link );
    // Utils.add_accel_label( _del_link, 'v', Gdk.ModifierType.CONTROL_MASK );

    /* Add the menu items to the menu */
    add( _copy );
    add( _cut );
    add( _paste );
    add( new SeparatorMenuItem() );
    add( _emoji );
    add( new SeparatorMenuItem() );
    add( _add_link );
    add( _del_link );
    add( _edit_link );

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  /* Copies the selected text to the clipboard */
  private void copy() {
    _da.copy_selected_text();
  }

  /* Copies the selected text to the clipboard and removes the text */
  private void cut() {
    _da.cut_selected_text();
  }

  /*
   Pastes text in the clipboard to the current location of the cursor, replacing
   any selected text.
  */
  private void paste() {
    _da.paste_text();
  }

  /*
   Displays the emoji selection window to allow the user to insert an emoji
   character at the current cursor location.
  */
  private void insert_emoji() {
    _da.handle_control_period();
  }

  /*
   Adds a link to text that is currently selected.  This item should not be
   allowed if there is either nothing selected or the current selection overlaps
   text that currently has a link associated with it.
  */
  private void add_link() {
    /* TBD */
  }

  /* Allows the user to remove the link located at the current cursor */
  private void remove_link() {
    /* TBD */
  }

  /* Allows the user to edit the associated link. */
  private void edit_link() {
    /* TBD */
  }

  /*
   Called when this menu is about to be displayed.  Allows the menu items to
   get set to contextually relevant states.
  */
  private void on_popup() {

    /* Set the menu sensitivity */
    _copy.set_sensitive( copy_or_cut_possible() );
    _cut.set_sensitive( copy_or_cut_possible() );
    _paste.set_sensitive( paste_possible() );
    _add_link.set_sensitive( add_link_possible() );
    _del_link.set_sensitive( remove_link_possible() );
    _edit_link.set_sensitive( edit_link_possible() );

  }

  /*
   We can copy or cut text if it is selected.
  */
  private bool copy_or_cut_possible() {

    var node     = _da.get_current_node();
    var conn     = _da.get_current_connection();
    int cursor   = 0;
    int selstart = 0;
    int selend   = 0;

    if( node != null ) {
      node.name.get_cursor_info( out cursor, out selstart, out selend );
    } else if( conn != null ) {
      conn.title.get_cursor_info( out cursor, out selstart, out selend );
    }

    return( selstart != selend );

  }

  /* Returns true if there is text in the clipboard to paste */
  private bool paste_possible() {

    var clipboard = Clipboard.get_default( get_display() );
    string? value = clipboard.wait_for_text();

    return( value != null );

  }

  /*
   A link can be added if text is selected and the selected text does not
   overlap with any existing links.
  */
  private bool add_link_possible() {

    var node = _da.get_current_node();

    if( node != null ) {
      int cursor, selstart, selend;
      var indices = new Array<int>();
      node.name.get_cursor_info( out cursor, out selstart, out selend );
      return( (selstart != selend) && !node.urls.overlaps_with( selstart, selend, ref indices ) );
    }

    return( false );

  }

  /*
   A link can be removed if no text is selected and the cursor is located on
   an existing link.
  */
  private bool remove_link_possible() {

    var node = _da.get_current_node();

    if( node != null ) {
      int cursor, selstart, selend;
      node.name.get_cursor_info( out cursor, out selstart, out selend );
      return( (selstart == selend) && (node.urls.find_link( cursor ) != -1) );
    }

    return( false );

  }

  /*
   A link can be edited if no text is selected and the cursor is located on
   an existing link.
  */
  private bool edit_link_possible() {

    var node = _da.get_current_node();

    if( node != null ) {
      int cursor, selstart, selend;
      node.name.get_cursor_info( out cursor, out selstart, out selend );
      return( (selstart == selend) && (node.urls.find_link( cursor ) != -1) );
    }

    return( false );

  }

}
