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

public class NodesMenu : Gtk.Menu {

  DrawArea     _da;
  Gtk.MenuItem _copy;
  Gtk.MenuItem _cut;
  Gtk.MenuItem _delete;
  Gtk.MenuItem _fold;
  Gtk.MenuItem _connect;
  Gtk.MenuItem _link;

  /* Default constructor */
  public NodesMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    _copy = new Gtk.MenuItem.with_label( _( "Copy" ) );
    _copy.activate.connect( copy_nodes );

    _cut = new Gtk.MenuItem.with_label( _( "Cut" ) );
    _cut.activate.connect( cut_nodes );

    _delete = new Gtk.MenuItem.with_label( _( "Delete" ) );
    _delete.activate.connect( delete_nodes );

    _fold = new Gtk.MenuItem.with_label( _( "Fold Children" ) );
    _fold.activate.connect( fold_nodes );

    _connect = new Gtk.MenuItem.with_label( _( "Connect" ) );
    _connect.activate.connect( connect_nodes );

    _link = new Gtk.MenuItem.with_label( _( "Link Nodes" ) );
    _link.activate.connect( link_nodes );

    /*
    var selnode = new Gtk.MenuItem.with_label( _( "Select Node" ) );
    var selmenu = new Gtk.Menu();
    selnode.set_submenu( selmenu );

    _selroot = new Gtk.MenuItem.with_label( _( "Root" ) );
    _selroot.activate.connect( select_root_node );
    Utils.add_accel_label( _selroot, 'm', 0 );
    */

    /* Add the menu items to the menu */
    add( _copy );
    add( _cut );
    add( _delete );
    add( new SeparatorMenuItem() );
    add( _fold );
    add( new SeparatorMenuItem() );
    add( _connect );
    add( _link );

    /*
    add( selnode );

    // Add the items to the selection menu
    selmenu.add( _selroot );
    */

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  /* Returns true if there is a currently selected connection */
  private bool connection_selected() {
    return( _da.get_current_connection() != null );
  }

  /* Returns true if there is a currently selected node that is foldable */
  private void nodes_foldable_status( out bool foldable, out bool unfoldable ) {
    foldable = unfoldable = false;
    var nodes = _da.get_selected_nodes();
    for( int i=0; i<nodes.length; i++ ) {
      if( !nodes.index( i ).is_leaf() ) {
        foldable   |= !nodes.index( i ).folded;
        unfoldable |=  nodes.index( i ).folded;
      }
    }
  }

  /* Called when the menu is popped up */
  private void on_popup() {

    var node_num = _da.get_selected_nodes().length;

    bool foldable, unfoldable;
    nodes_foldable_status( out foldable, out unfoldable );

    /* Set the menu sensitivity */
    _fold.set_sensitive( foldable || unfoldable );
    _connect.set_sensitive( node_num == 2 );

    _fold.label = unfoldable ? _( "Unfold Children" )  : _( "Fold Children" );

    //_selroot.set_sensitive( _da.root_selectable() );

  }

  /* Copies all selected nodes to the node clipboard */
  private void copy_nodes() {
    _da.do_copy();
  }

  /* Cuts all selected nodes to the node clipboard */
  private void cut_nodes() {
    _da.do_cut();
  }

  /* Delete all selected nodes, collapsing deselected descendants */
  private void delete_nodes() {
    _da.delete_nodes();
  }

  /* Folds/unfolds the selected nodes */
  private void fold_nodes() {
    _da.toggle_folds();
  }

  /*
   Creates a connection between two selected nodes, where the first node is the from node and the
   second node is the to node.
  */
  private void connect_nodes() {
    _da.create_connection();
  }

  /*
   Links two selected nodes such that the first selected node will link to the second selected node.
  */
  private void link_nodes() {
    _da.create_links();
  }

}
