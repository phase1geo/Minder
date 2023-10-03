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

  DrawArea              _da;
  Gtk.MenuItem          _copy;
  Gtk.MenuItem          _cut;
  Gtk.MenuItem          _paste;
  Gtk.MenuItem          _emoji;
  Gtk.MenuItem          _open_link;
  Gtk.MenuItem          _add_link;
  Gtk.MenuItem          _del_link;
  Gtk.MenuItem          _edit_link;
  Gtk.MenuItem          _rest_link;
  Gtk.SeparatorMenuItem _link_div1;
  Gtk.SeparatorMenuItem _link_div2;

  public TextMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    _copy = new Gtk.MenuItem();
    _copy.add( new Granite.AccelLabel( _( "Copy" ), "<Control>c" ) );
    _copy.activate.connect( copy );

    _cut = new Gtk.MenuItem();
    _cut.add( new Granite.AccelLabel( _( "Cut" ), "<Control>x" ) );
    _cut.activate.connect( cut );

    _paste = new Gtk.MenuItem();
    _paste.add( new Granite.AccelLabel( _( "Paste" ), "<Control>v" ) );
    _paste.activate.connect( paste );

    _emoji = new Gtk.MenuItem();
    _emoji.add( new Granite.AccelLabel( _( "Insert Emoji" ), "<Control>period" ) );
    _emoji.activate.connect( insert_emoji );

    _open_link = new Gtk.MenuItem.with_label( _( "Open Link" ) );
    _open_link.activate.connect( open_link );

    _add_link = new Gtk.MenuItem();
    _add_link.add( new Granite.AccelLabel( _( "Add Link" ), "<Control>k" ) );
    _add_link.activate.connect( add_link );

    _edit_link = new Gtk.MenuItem.with_label( _( "Edit Link" ) );
    _edit_link.activate.connect( edit_link );

    _del_link = new Gtk.MenuItem();
    _del_link.add( new Granite.AccelLabel( _( "Remove Link" ), "<Shift><Control>k" ) );
    _del_link.activate.connect( remove_link );

    _rest_link = new Gtk.MenuItem.with_label( _( "Restore Link" ) );
    _rest_link.activate.connect( restore_link );

    _link_div1 = new Gtk.SeparatorMenuItem();
    _link_div2 = new Gtk.SeparatorMenuItem();

    /* Add the menu items to the menu */
    add( _copy );
    add( _cut );
    add( _paste );
    add( new SeparatorMenuItem() );
    add( _emoji );
    add( _link_div1 );
    add( _open_link );
    add( _link_div2 );
    add( _add_link );
    add( _edit_link );
    add( _del_link );
    add( _rest_link );

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );
    hide.connect( on_popdown );

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
    MinderClipboard.paste( _da, false );
  }

  /*
   Displays the emoji selection window to allow the user to insert an emoji
   character at the current cursor location.
  */
  private void insert_emoji() {
    _da.handle_control_period();
  }

  private void open_link() {
    var node = _da.get_current_node();
    int cursor, selstart, selend;
    node.name.get_cursor_info( out cursor, out selstart, out selend );
    var links = node.name.text.get_full_tags_in_range( FormatTag.URL, cursor, cursor );
    Utils.open_url( links.index( 0 ).extra );
  }

  /*
   Adds a link to text that is currently selected.  This item should not be
   allowed if there is either nothing selected or the current selection overlaps
   text that currently has a link associated with it.
  */
  private void add_link() {
    _da.url_editor.add_url();
  }

  /* Allows the user to remove the link located at the current cursor */
  private void remove_link() {
    _da.url_editor.remove_url();
  }

  /* Allows the user to edit the associated link. */
  private void edit_link() {
    _da.url_editor.edit_url();
  }

  /* Restores an embedded link that was previously removed */
  private void restore_link() {
    var node = _da.get_current_node();
    int cursor, selstart, selend;
    node.name.get_cursor_info( out cursor, out selstart, out selend );
    // TBD - node.urls.restore_link( cursor );
    node.name.clear_selection();
    _da.auto_save();
  }

  /*
   Called when this menu is about to be displayed.  Allows the menu items to
   get set to contextually relevant states.
  */
  private void on_popup() {

    var node = _da.get_current_node();

    /* Set the menu sensitivity */
    _copy.set_sensitive( copy_or_cut_possible() );
    _cut.set_sensitive( copy_or_cut_possible() );
    _paste.set_sensitive( paste_possible() );

    /* Initialize the visible attribute */
    _open_link.visible = false;
    _add_link.visible  = false;
    _edit_link.visible = false;
    _del_link.visible  = false;
    _rest_link.visible = false;

    if( node != null ) {

      int cursor, selstart, selend;
      node.name.get_cursor_info( out cursor, out selstart, out selend );

      var links    = node.name.text.get_full_tags_in_range( FormatTag.URL, cursor, cursor );
      var link     = (links.length > 0) ? links.index( 0 ) : null;
      var selected = (selstart != selend);
      var valid    = (link != null);

      /* If we have found a link, select it */
      if( !selected ) {
        node.name.change_selection( link.start, link.end );
      }

      bool embedded = (links.length > 0) ? (link.extra == node.name.text.text.slice( link.start, link.end )) : false;
      bool ignore   = false;  // TBD

      // embedded ignore   RESULT
      // -------- ------   ------
      //    0       0       add, del, edit
      //    0       1       add, del, edit
      //    1       0       del
      //    1       1       rest

      /* Set view of all link menus */
      _open_link.visible = valid && !ignore;
      _add_link.visible  = !embedded && !ignore && _da.add_link_possible( node );
      _edit_link.visible = valid && !selected && !embedded;
      _del_link.visible  = valid && !selected && (!embedded || !ignore);
      _rest_link.visible = valid && !selected && embedded && ignore;

    }

    /* Set the visibility of the dividers */
    _link_div1.visible = _open_link.visible;
    _link_div2.visible = _add_link.visible || _edit_link.visible || _del_link.visible || _rest_link.visible;

  }

  /* Called when the menu is poppped down */
  private void on_popdown() {

    if( _edit_link.visible || _del_link.visible || _rest_link.visible ) {
      var node = _da.get_current_node();
      node.name.clear_selection();
    }

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

}
