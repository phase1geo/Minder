/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

  private bool _clear_selection = false;

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

    var md_menu = new GLib.Menu();
    append_menu_item( md_menu, KeyCommand.EDIT_HEADER1,     _( "# Header1" ) );
    append_menu_item( md_menu, KeyCommand.EDIT_HEADER2,     _( "## Header2" ) );
    append_menu_item( md_menu, KeyCommand.EDIT_HEADER3,     _( "### Header3" ) );
    append_menu_item( md_menu, KeyCommand.EDIT_HEADER4,     _( "#### Header4" ) );
    append_menu_item( md_menu, KeyCommand.EDIT_HEADER5,     _( "##### Header5" ) );
    append_menu_item( md_menu, KeyCommand.EDIT_HEADER6,     _( "###### Header6" ) );
    append_menu_item( md_menu, KeyCommand.EDIT_BOLD,        _( "**Bold**" ) );
    append_menu_item( md_menu, KeyCommand.EDIT_ITALICS,     _( "__Italicize_" ) );
    append_menu_item( md_menu, KeyCommand.EDIT_STRIKE,      _( "~~Strikeout~~" ) );
    append_menu_item( md_menu, KeyCommand.EDIT_CODE,        _( "`Code`" ) );
    append_menu_item( md_menu, KeyCommand.EDIT_HIGHLIGHT,   _( "==Highlight==" ) );
    append_menu_item( md_menu, KeyCommand.EDIT_SUPERSCRIPT, _( "<sup>Superscript</sup>") );
    append_menu_item( md_menu, KeyCommand.EDIT_SUBSCRIPT,   _( "<sub>Subscript</sub>") );
    append_menu_item( md_menu, KeyCommand.EDIT_LINK,        _( "[Link text](URL)" ) );

    var md_submenu = new GLib.Menu();
    md_submenu.append_submenu( _( "Markdown" ), md_menu );

    menu.append_section( null, edit_menu );
    menu.append_section( null, emoji_menu );
    menu.append_section( null, open_menu );
    menu.append_section( null, other_menu );
    menu.append_section( null, md_submenu );

  }

  //-------------------------------------------------------------
  // Called when this menu is about to be displayed.  Allows the
  // menu items to get set to contextually relevant states.
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

      if( valid && !selected ) {
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

    // Set the menu sensitivity
    var copy_or_cut = copy_or_cut_possible();
    set_enabled( KeyCommand.EDIT_COPY,  copy_or_cut );
    set_enabled( KeyCommand.EDIT_CUT,   copy_or_cut );
    set_enabled( KeyCommand.EDIT_PASTE, paste_possible() );

    var md_enabled = Minder.settings.get_boolean( "enable-markdown" );
    for( int i=(KeyCommand.EDIT_MARKDOWN_START + 1); i<KeyCommand.EDIT_MARKDOWN_END; i++ ) {
      set_enabled( (KeyCommand)i, md_enabled );
    }

  }

  //-------------------------------------------------------------
  // Called when the menu is poppped down.
  protected override void on_popdown() {
    if( _clear_selection ) {
      var text = map.get_current_text();
      if( text != null ) {
        text.clear_selection();
      }
    }
  }

  //-------------------------------------------------------------
  // We can copy or cut text if it is selected.
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

  //-------------------------------------------------------------
  // Returns true if there is text in the clipboard to paste.
  private bool paste_possible() {
    return( MinderClipboard.text_pasteable() );
  }

}
