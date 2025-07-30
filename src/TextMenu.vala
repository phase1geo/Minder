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

public class TextMenu : BaseMenu {

  private bool        _clear_selection = false;

  //-------------------------------------------------------------
  // Default constructor
  public TextMenu( Gtk.Application app, DrawArea da ) {

    base( app, da, "text" );

    // Add the menu items to the menu
    var edit_menu = new GLib.Menu();
    append_menu_item( edit_menu, KeyCommand.EDIT_COPY,   _( "Copy" ) );
    append_menu_item( edit_menu, KeyCommand.EDIT_CUT,    _( "Cut" ) );
    append_menu_item( edit_menu, KeyCommand.EDIT_PASTE,  _( "Paste" ) );

    var emoji_menu = new GLib.Menu();
    append_menu_item( emoji_menu, KeyCommand.EDIT_INSERT_EMOJI, _( "Insert Emoji" ) );

    var open_menu = new GLib.Menu();
    append_menu_item( open_menu, KeyCommand.EDIT_OPEN_URL, _( "Open Link" ) );

    var other_menu = new GLib.Menu();
    append_menu_item( other_menu, KeyCommand.EDIT_ADD_URL,    _( "Add Link" ) );
    append_menu_item( other_menu, KeyCommand.EDIT_EDIT_URL,   _( "Edit Link" ) );
    append_menu_item( other_menu, KeyCommand.EDIT_REMOVE_URL, _( "Remove Link" ) );

    var menu = new GLib.Menu();
    menu.append_section( null, edit_menu );
    menu.append_section( null, emoji_menu );
    menu.append_section( null, open_menu );
    menu.append_section( null, other_menu );

    /*
    // Add the menu actions
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    da.insert_action_group( "text", actions );

    // Add keyboard shortcuts
    app.set_accels_for_action( "text.action_copy",         { "<Control>c" } );
    app.set_accels_for_action( "text.action_cut",          { "<Control>x" } );
    app.set_accels_for_action( "text.action_paste",        { "<Control>v" } );
    app.set_accels_for_action( "text.action_insert_emoji", { "<Control>period" } );
    app.set_accels_for_action( "text.action_add_link",     { "<Control>k" } );
    app.set_accels_for_action( "text.action_edit_link",    { "<Control>k" } );
    app.set_accels_for_action( "text.action_remove_link",  { "<Control><Shift>k" } );
    */

  }

  //-------------------------------------------------------------
  // Copies the selected text to the clipboard
  private void action_copy() {
    map.model.copy_selected_text();
  }

  //-------------------------------------------------------------
  // Copies the selected text to the clipboard and removes the text
  private void action_cut() {
    map.model.cut_selected_text();
  }

  //-------------------------------------------------------------
  // Pastes text in the clipboard to the current location of the
  // cursor, replacing any selected text.
  private void action_paste() {
    MinderClipboard.paste( map, false );
  }

  //-------------------------------------------------------------
  // Displays the emoji selection window to allow the user to
  // insert an emoji character at the current cursor location.
  private void action_insert_emoji() {
    map.canvas.handle_control_period();
  }

  //-------------------------------------------------------------
  // Opens the first link found
  private void action_open_link() {
    var text = map.get_current_text();
    if( text != null ) {
      int cursor, selstart, selend;
      text.get_cursor_info( out cursor, out selstart, out selend );
      var links = text.text.get_full_tags_in_range( FormatTag.URL, cursor, cursor );
      Utils.open_url( links.index( 0 ).extra );
    }
  }

  //-------------------------------------------------------------
  // Adds a link to text that is currently selected.  This item
  // should not be allowed if there is either nothing selected or
  // the current selection overlaps text that currently has a
  // link associated with it.
  private void action_add_link() {
    map.canvas.url_editor.add_url();
  }

  //-------------------------------------------------------------
  // Allows the user to remove the link located at the current
  // cursor.
  private void action_remove_link() {
    map.canvas.url_editor.remove_url();
  }

  //-------------------------------------------------------------
  // Allows the user to edit the associated link.
  private void action_edit_link() {
    map.canvas.url_editor.edit_url();
  }

  /*
   Called when this menu is about to be displayed.  Allows the menu items to
   get set to contextually relevant states.
  */
  protected override void on_popup() {

    var text = map.get_current_text();
    if( text != null ) {

      int cursor, selstart, selend;
      text.get_cursor_info( out cursor, out selstart, out selend );

      var links = text.text.get_full_tags_in_range( FormatTag.URL, cursor, cursor );
      var link  = (links.length > 0) ? links.index( 0 ) : null;

      var valid    = (link != null);
      var selected = (selstart != selend);
      var embedded = (links.length > 0) && (link.extra == text.text.text.slice( link.start, link.end ));

      if( !selected ) {
        text.change_selection( link.start, link.end );
      }

      set_enabled( KeyCommand.EDIT_OPEN_URL,   valid );
      set_enabled( KeyCommand.EDIT_ADD_URL,    (!embedded && map.model.add_link_possible( text )) );
      set_enabled( KeyCommand.EDIT_EDIT_URL,   (valid && !selected && !embedded) );
      set_enabled( KeyCommand.EDIT_REMOVE_URL, (valid && !selected) );

      _clear_selection = valid && !selected;

    } else {

      set_enabled( KeyCommand.EDIT_OPEN_URL,   false );
      set_enabled( KeyCommand.EDIT_ADD_URL,    false );
      set_enabled( KeyCommand.EDIT_EDIT_URL,   false );
      set_enabled( KeyCommand.EDIT_REMOVE_URL, false );

      _clear_selection = false;

    }

    /* Set the menu sensitivity */
    var copy_or_cut = copy_or_cut_possible();
    set_enabled( KeyCommand.EDIT_COPY,  copy_or_cut );
    set_enabled( KeyCommand.EDIT_CUT,   copy_or_cut );
    set_enabled( KeyCommand.EDIT_PASTE, paste_possible() );

  }

  /* Called when the menu is poppped down */
  protected override void on_popdown() {
    if( _clear_selection ) {
      var text = map.get_current_text();
      if( text != null ) {
        text.clear_selection();
      }
    }
  }

  /*
   We can copy or cut text if it is selected.
  */
  private bool copy_or_cut_possible() {

    var text     = map.get_current_text();
    var cursor   = 0;
    var selstart = 0;
    var selend   = 0;

    if( text != null ) {
      text.get_cursor_info( out cursor, out selstart, out selend );
    }

    return( selstart != selend );

  }

  /* Returns true if there is text in the clipboard to paste */
  private bool paste_possible() {
    return( MinderClipboard.text_pasteable() );
  }

}
