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

public class ConnectionMenu : Gtk.Menu {

  DrawArea     _da;
  Gtk.MenuItem _delete;
  Gtk.MenuItem _edit;
  Gtk.MenuItem _note;
  Gtk.MenuItem _selstart;
  Gtk.MenuItem _selend;

  /* Default constructor */
  public ConnectionMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    _delete = new Gtk.MenuItem.with_label( _( "Delete" ) );
    _delete.activate.connect( delete_connection );
    Utils.add_accel_label( _delete, 65535, 0 );

    _edit = new Gtk.MenuItem.with_label( _( "Edit…" ) );
    _edit.activate.connect( edit_title );
    Utils.add_accel_label( _edit, 'e', 0 );

    _note = new Gtk.MenuItem.with_label( _( "Add Note" ) );
    _note.activate.connect( change_note );

    var selnode = new Gtk.MenuItem.with_label( _( "Select Node" ) );
    var selmenu = new Gtk.Menu();
    selnode.set_submenu( selmenu );

    _selstart = new Gtk.MenuItem.with_label( _( "Start Node" ) );
    _selstart.activate.connect( select_start_node );
    Utils.add_accel_label( _selstart, 'p', 0 );

    _selend = new Gtk.MenuItem.with_label( _( "End Node" ) );
    _selend.activate.connect( select_end_node );
    Utils.add_accel_label( _selend, 'n', 0 );

    /* Add the menu items to the menu */
    add( _delete );
    add( new SeparatorMenuItem() );
    add( _edit );
    add( _note );
    add( new SeparatorMenuItem() );
    add( selnode );

    /* Add the items to the selection menu */
    selmenu.add( _selstart );
    selmenu.add( _selend );

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  /* Returns true if a note is associated with the currently selected node */
  private bool connection_has_note() {
    Connection? current = _da.get_current_connection();
    return( (current != null) && (current.note != "") );
  }

  /* Called when the menu is popped up */
  private void on_popup() {

    /* Set the menu item labels */
    _note.label = connection_has_note() ? _( "Remove Note" ) : _( "Add Note" );

  }

  /* Deletes the current node */
  private void delete_connection() {
    _da.delete_connection();
  }

  /* Displays the sidebar to edit the node properties */
  private void edit_title() {
    Connection conn = _da.get_current_connection();
    if( conn.title == null ) {
      conn.change_title( _da, "", true );
    }
    conn.mode = ConnMode.EDITABLE;
  }

  /* Changes the note status of the currently selected node */
  private void change_note() {
    if( connection_has_note() ) {
      _da.change_current_connection_note( "" );
    } else {
      _da.show_properties( "current", true );
    }
    _da.connection_changed();
  }

  /* Selects the next sibling node of the current node */
  private void select_start_node() {
    _da.select_connection_node( true );
  }

  /* Selects the previous sibling node of the current node */
  private void select_end_node() {
    _da.select_connection_node( false );
  }

}
