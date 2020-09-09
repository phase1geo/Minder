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

public class EmptyMenu : Gtk.Menu {

  DrawArea     _da;
  Gtk.MenuItem _paste;
  Gtk.MenuItem _root;
  Gtk.MenuItem _quick;
  Gtk.MenuItem _selroot;

  /* Default constructor */
  public EmptyMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    _paste = new Gtk.MenuItem();
    _paste.add( new Granite.AccelLabel( _( "Paste" ), "<Control>v" ) );
    _paste.activate.connect( paste );

    _root = new Gtk.MenuItem();
    _root.add( new Granite.AccelLabel( _( "Add Root Node" ), "Return" ) );
    _root.activate.connect( add_root_node );

    _quick = new Gtk.MenuItem();
    _quick.add( new Granite.AccelLabel( _( "Add Nodes With Quick Entry" ), "<Control><Shift>e" ) );
    _quick.activate.connect( add_quick_entry );

    var selnode = new Gtk.MenuItem.with_label( _( "Select Node" ) );
    var selmenu = new Gtk.Menu();
    selnode.set_submenu( selmenu );

    _selroot = new Gtk.MenuItem();
    _selroot.add( new Granite.AccelLabel( _( "Root" ), "m" ) );
    _selroot.activate.connect( select_root_node );

    /* Add the menu items to the menu */
    add( _paste );
    add( new SeparatorMenuItem() );
    add( _root );
    add( _quick );
    add( new SeparatorMenuItem() );
    add( selnode );

    /* Add the items to the selection menu */
    selmenu.add( _selroot );

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  /* Returns true if there is a currently selected connection */
  private bool connection_selected() {
    return( _da.get_current_connection() != null );
  }

  /* Called when the menu is popped up */
  private void on_popup() {

    /* Set the menu sensitivity */
    _paste.set_sensitive( _da.node_pasteable() );
    _root.set_sensitive( !connection_selected() );
    _selroot.set_sensitive( _da.root_selectable() );

  }

  /* Pastes node tree as root from clipboard */
  private void paste() {
    _da.do_paste( false );
  }

  /* Creates a new root node */
  private void add_root_node() {
    _da.add_root_node();
  }

  /* Adds top-level nodes via the quick entry facility */
  private void add_quick_entry() {
    _da.handle_control_E();
  }

  /* Selects the current root node */
  private void select_root_node() {
    _da.select_root_node();
  }

}
