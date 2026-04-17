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

public class MarkdownMenu : BaseMenu {

  //-------------------------------------------------------------
  // Default constructor
  public MarkdownMenu( Gtk.Application app, DrawArea da ) {

    base( app, da, "markdown" );

    append_menu_item( menu, KeyCommand.EDIT_HEADER1,     _( "# Header1" ) );
    append_menu_item( menu, KeyCommand.EDIT_HEADER2,     _( "## Header2" ) );
    append_menu_item( menu, KeyCommand.EDIT_HEADER3,     _( "### Header3" ) );
    append_menu_item( menu, KeyCommand.EDIT_HEADER4,     _( "#### Header4" ) );
    append_menu_item( menu, KeyCommand.EDIT_HEADER5,     _( "##### Header5" ) );
    append_menu_item( menu, KeyCommand.EDIT_HEADER6,     _( "###### Header6" ) );
    append_menu_item( menu, KeyCommand.EDIT_BOLD,        _( "**Bold**" ) );
    append_menu_item( menu, KeyCommand.EDIT_ITALICS,     _( "_Italicize_" ) );
    append_menu_item( menu, KeyCommand.EDIT_STRIKE,      _( "~~Strikeout~~" ) );
    append_menu_item( menu, KeyCommand.EDIT_HIGHLIGHT,   _( "==Highlight==" ) );
    append_menu_item( menu, KeyCommand.EDIT_SUPERSCRIPT, _( "<sup>Superscript</sup>") );
    append_menu_item( menu, KeyCommand.EDIT_SUBSCRIPT,   _( "<sub>Subscript</sub>") );
    append_menu_item( menu, KeyCommand.EDIT_LINK,        _( "[Link text](URL)" ) );

  }

}
