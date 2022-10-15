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

public class GroupsMenu : Gtk.Menu {

  DrawArea     _da;
  Gtk.MenuItem _delete;
  Gtk.MenuItem _merge;
  Gtk.MenuItem _note;
  Gtk.MenuItem _color;
  Gtk.MenuItem _selnodes;
  Gtk.MenuItem _selmain;

  /* Default constructor */
  public GroupsMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    _delete = new Gtk.MenuItem();
    _delete.add( new Granite.AccelLabel( _( "Delete" ), "Delete" ) );
    _delete.activate.connect( delete_groups );

    _merge = new Gtk.MenuItem.with_label( _( "Merge" ) );
    _merge.activate.connect( merge_groups );

    _note = new Gtk.MenuItem();
    _note.add( new Granite.AccelLabel( _( "Edit Note" ), "<Shift>e" ) );
    _note.activate.connect( edit_note );

    _color = new Gtk.MenuItem.with_label( _( "Change color…" ) );
    _color.activate.connect( change_color );

    var selmenu = new Gtk.Menu();
    var select = new Gtk.MenuItem.with_label( _( "Select" ) );
    select.set_submenu( selmenu );

    _selmain = new Gtk.MenuItem.with_label( _( "Top Nodes" ) );
    _selmain.activate.connect( select_main );

    _selnodes = new Gtk.MenuItem.with_label( _( "All Grouped Nodes" ) );
    _selnodes.activate.connect( select_all );

    selmenu.add( _selmain );
    selmenu.add( _selnodes );

    /* Add the menu items to the menu */
    add( _delete );
    add( new SeparatorMenuItem() );
    add( _note );
    add( _color );
    add( _merge );
    add( new SeparatorMenuItem() );
    add( select );

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  /* Called when the menu is popped up */
  private void on_popup() {

    var groups = _da.get_selected_groups();
    var num    = groups.length;

    /* Set the menu sensitivity */
    _merge.set_sensitive( num > 1 );

  }

  /* Deletes the current group */
  private void delete_groups() {
    _da.remove_groups();
  }

  /* Merges two or more groups into a single group */
  private void merge_groups() {
    _da.add_group();
  }

  /* Edits the group note */
  private void edit_note() {
    _da.show_properties( "current", PropertyGrab.NOTE );
  }

  /* Allows the user to change the color of the selected groups */
  private void change_color() {
    var color_picker = new ColorChooserDialog( _( "Select a link color" ), _da.win );
    if( color_picker.run() == ResponseType.OK ) {
      _da.change_group_color( color_picker.get_rgba() );
    }
    color_picker.close();
  }

  /* Selects the top-most nodes in each selected node group */
  private void select_main() {
    var groups   = _da.get_selected_groups();
    var selected = _da.get_selections();
    for( int i=0; i<groups.length; i++ ) {
      var nodes = groups.index( i ).nodes;
      for( int j=0; j<nodes.length; j++ ) {
        selected.add_node( nodes.index( j ), false );
      }
    }
    selected.clear_groups();
  }

  /* Selects all of the nodes within the group */
  private void select_all() {
    var groups   = _da.get_selected_groups();
    var selected = _da.get_selections();
    for( int i=0; i<groups.length; i++ ) {
      var nodes = groups.index( i ).nodes;
      for( int j=0; j<nodes.length; j++ ) {
        selected.add_node_tree( nodes.index( j ), false );
      }
    }
    selected.clear_groups();
  }

}
