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

public class TextMenu {

  private DrawArea    _da;
  private PopoverMenu _popover;
  private bool        _clear_selection = false;

  private const GLib.ActionEntry action_entries[] = {
    { "action_copy",         action_copy },
    { "action_cut",          action_cut },
    { "action_paste",        action_paste },
    { "action_insert_emoji", action_insert_emoji },
    { "action_open_link",    action_open_link },
    { "action_add_link",     action_add_link },
    { "action_edit_link",    action_edit_link },
    { "action_remove_link",  action_remove_link },
    { "action_restore_link", action_restore_link },
  };

  //-------------------------------------------------------------
  // Default constructor
  public TextMenu( Gtk.Application app, DrawArea da ) {

    _da = da;

    // Add the menu items to the menu
    var edit_menu = new GLib.Menu();
    edit_menu.append( _( "Copy" ),  "text.action_copy" );
    edit_menu.append( _( "Cut" ),   "text.action_cut" );
    edit_menu.append( _( "Paste" ), "text.action_paste" );

    var emoji_menu = new GLib.Menu();
    emoji_menu.append( _( "Insert Emoji" ), "text.action_insert_emoji" );

    var open_menu = new GLib.Menu();
    open_menu.append( _( "Open Link" ), "text.action_open_link" );

    var other_menu = new GLib.Menu();
    other_menu.append( _( "Add Link" ),     "text.action_add_link" );
    other_menu.append( _( "Edit Link" ),    "text.action_edit_link" );
    other_menu.append( _( "Remove Link" ),  "text.action_remove_link" );
    other_menu.append( _( "Restore Link" ), "text.action_restore_link" );

    var menu = new GLib.Menu();
    menu.append_section( null, edit_menu );
    menu.append_section( null, emoji_menu );
    menu.append_section( null, open_menu );
    menu.append_section( null, other_menu );

    _popover = new PopoverMenu.from_model( menu );
    _popover.set_parent( _da );
    _popover.closed.connect( on_popdown );

    // Add the menu actions
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    _da.insert_action_group( "text", actions );

    // Add keyboard shortcuts
    app.set_accels_for_action( "text.action_copy",         { "<Control>c" } );
    app.set_accels_for_action( "text.action_cut",          { "<Control>x" } );
    app.set_accels_for_action( "text.action_paste",        { "<Control>v" } );
    app.set_accels_for_action( "text.action_insert_emoji", { "<Control>period" } );
    app.set_accels_for_action( "text.action_add_link",     { "<Control>k" } );
    app.set_accels_for_action( "text.action_edit_link",    { "<Control>k" } );
    app.set_accels_for_action( "text.action_remove_link",  { "<Control><Shift>k" } );

  }

  //-------------------------------------------------------------
  // Shows the menu at the given location.
  public void show( double x, double y ) {

    // Set the menu state
    on_popup();

    // Display the popover at the given location
    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    _popover.pointing_to = rect;
    _popover.popup();

  }

  //-------------------------------------------------------------
  // Hides the menu.
  public void hide() {

    // Hides the menu
    _popover.popdown();

  }

  /* Copies the selected text to the clipboard */
  private void action_copy() {
    _da.copy_selected_text();
  }

  /* Copies the selected text to the clipboard and removes the text */
  private void action_cut() {
    _da.cut_selected_text();
  }

  /*
   Pastes text in the clipboard to the current location of the cursor, replacing
   any selected text.
  */
  private void action_paste() {
    MinderClipboard.paste( _da.map, false );
  }

  /*
   Displays the emoji selection window to allow the user to insert an emoji
   character at the current cursor location.
  */
  private void action_insert_emoji() {
    _da.handle_control_period();
  }

  /* Opens the first link found */
  private void action_open_link() {

    CanvasText? ct = null;

    if( _da.is_node_editable() ) {
      ct = _da.get_current_node().name;
    } else if( _da.is_callout_editable() ) {
      ct = _da.get_current_callout().text;
    }

    if( ct != null ) {
      int cursor, selstart, selend;
      ct.get_cursor_info( out cursor, out selstart, out selend );
      var links = ct.text.get_full_tags_in_range( FormatTag.URL, cursor, cursor );
      Utils.open_url( links.index( 0 ).extra );
    }

  }

  /*
   Adds a link to text that is currently selected.  This item should not be
   allowed if there is either nothing selected or the current selection overlaps
   text that currently has a link associated with it.
  */
  private void action_add_link() {
    _da.url_editor.add_url();
  }

  /* Allows the user to remove the link located at the current cursor */
  private void action_remove_link() {
    _da.url_editor.remove_url();
  }

  /* Allows the user to edit the associated link. */
  private void action_edit_link() {
    _da.url_editor.edit_url();
  }

  /* Restores an embedded link that was previously removed */
  private void action_restore_link() {

    CanvasText? ct = null;

    if( _da.is_node_editable() ) {
      ct = _da.get_current_node().name;
    } else if( _da.is_callout_editable() ) {
      ct = _da.get_current_callout().text;
    }

    if( ct != null ) {
      int cursor, selstart, selend;
      ct.get_cursor_info( out cursor, out selstart, out selend );
    // TBD - node.urls.restore_link( cursor );
      ct.clear_selection();
      _da.auto_save();
    }

  }

  /*
   Called when this menu is about to be displayed.  Allows the menu items to
   get set to contextually relevant states.
  */
  private void on_popup() {

    var node    = _da.get_current_node();
    var callout = _da.get_current_callout();

    /* Set the menu sensitivity */
    _da.action_set_enabled( "text.action_copy",  copy_or_cut_possible() );
    _da.action_set_enabled( "text.action_cut",   copy_or_cut_possible() );
    _da.action_set_enabled( "text.action_paste", paste_possible() );

    /* Initialize the visible attribute */
    _da.action_set_enabled( "text.action_open_link",    false );
    _da.action_set_enabled( "text.action_add_link",     false );
    _da.action_set_enabled( "text.action_edit_link",    false );
    _da.action_set_enabled( "text.action_delete_link",  false );
    _da.action_set_enabled( "text.action_restore_link", false );
    _clear_selection = false;

    CanvasText? ct = null;

    if( _da.is_node_editable() ) {
      ct = _da.get_current_node().name;
    } else if( _da.is_callout_editable() ) {
      ct = _da.get_current_callout().text;
    }

    if( ct != null ) {

      int cursor, selstart, selend;
      ct.get_cursor_info( out cursor, out selstart, out selend );

      var links    = ct.text.get_full_tags_in_range( FormatTag.URL, cursor, cursor );
      var link     = (links.length > 0) ? links.index( 0 ) : null;
      var selected = (selstart != selend);
      var valid    = (link != null);

      /* If we have found a link, select it */
      if( !selected ) {
        ct.change_selection( link.start, link.end );
      }

      var embedded = (links.length > 0) && (link.extra == ct.text.text.slice( link.start, link.end ));
      var ignore   = false;

      // embedded ignore   RESULT
      // -------- ------   ------
      //    0       0       add, del, edit
      //    0       1       add, del, edit
      //    1       0       del
      //    1       1       rest

      // Set view of all link menus
      _da.action_set_enabled( "text.action_open_link",    (valid && !ignore) );
      _da.action_set_enabled( "text.action_add_link",     (!embedded && !ignore && _da.add_link_possible( ct )) );
      _da.action_set_enabled( "text.action_edit_link",    (valid && !selected && !embedded) );
      _da.action_set_enabled( "text.action_delete_link",  (valid && !selected && (!embedded || !ignore)) );
      _da.action_set_enabled( "text.action_restore_link", (valid && !selected && embedded && ignore) );

      _clear_selection = valid && !selected;

    }

  }

  /* Called when the menu is poppped down */
  private void on_popdown() {

    if( _clear_selection ) {
      var node    = _da.get_current_node();
      var callout = _da.get_current_callout();
      if( node != null ) {
        node.name.clear_selection();
      } else if( callout != null ) {
        callout.text.clear_selection();
      }
    }

  }

  /*
   We can copy or cut text if it is selected.
  */
  private bool copy_or_cut_possible() {

    var node     = _da.get_current_node();
    var conn     = _da.get_current_connection();
    var callout  = _da.get_current_callout();
    int cursor   = 0;
    int selstart = 0;
    int selend   = 0;

    if( node != null ) {
      node.name.get_cursor_info( out cursor, out selstart, out selend );
    } else if( conn != null ) {
      conn.title.get_cursor_info( out cursor, out selstart, out selend );
    } else if( callout != null ) {
      callout.text.get_cursor_info( out cursor, out selstart, out selend );
    }

    return( selstart != selend );

  }

  /* Returns true if there is text in the clipboard to paste */
  private bool paste_possible() {
    return( MinderClipboard.text_pasteable() );
  }

}
