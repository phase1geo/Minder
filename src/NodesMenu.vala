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
  Gtk.MenuItem _link_colors;
  Gtk.MenuItem _parent_link_colors;

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

    var link_color_menu = new Gtk.Menu();

    _link_colors = new Gtk.MenuItem.with_label( _( "Link Colors" ) );
    _link_colors.set_submenu( link_color_menu );

    var set_link_colors = new Gtk.MenuItem.with_label( _( "Set to color…" ) );
    set_link_colors.activate.connect( change_link_colors );

    var rand_link_colors = new Gtk.MenuItem.with_label( _( "Randomize colors" ) );
    rand_link_colors.activate.connect( randomize_link_colors );

    _parent_link_colors = new Gtk.MenuItem.with_label( _( "Use parent color" ) );
    _parent_link_colors.activate.connect( reparent_link_colors );

    link_color_menu.add( set_link_colors );
    link_color_menu.add( rand_link_colors );
    link_color_menu.add( _parent_link_colors );

    /* Add the menu items to the menu */
    add( _copy );
    add( _cut );
    add( _delete );
    add( new SeparatorMenuItem() );
    add( _link_colors );
    add( _fold );
    add( new SeparatorMenuItem() );
    add( _connect );
    add( _link );

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

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

  /* Returns true if at least one selected node has its local_link_color indicator set */
  private bool link_colors_parentable() {
    var nodes = _da.get_selected_nodes();
    for( int i=0; i<nodes.length; i++ ) {
      if( nodes.index( i ).link_color_root ) {
        return( true );
      }
    }
    return( false );
  }

  /* Called when the menu is popped up */
  private void on_popup() {

    var node_num = _da.get_selected_nodes().length;

    bool foldable, unfoldable;
    nodes_foldable_status( out foldable, out unfoldable );

    /* Set the menu sensitivity */
    _fold.set_sensitive( foldable || unfoldable );
    _connect.set_sensitive( node_num == 2 );
    _parent_link_colors.set_sensitive( link_colors_parentable() );

    _fold.label = unfoldable ? _( "Unfold Children" )  : _( "Fold Children" );

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

  /* Changes the color of all selected nodes */
  private void change_link_colors() {
    var color_picker = new ColorChooserDialog( _( "Select a link color" ), _da.win );
    if( color_picker.run() == ResponseType.OK ) {
      _da.change_link_colors( color_picker.get_rgba() );
    }
    color_picker.close();
  }

  /* Randomize the selected link colors */
  private void randomize_link_colors() {
    _da.randomize_link_colors();
  }

  /* Changes the selected nodes to use parent node's colors */
  private void reparent_link_colors() {
    _da.reparent_link_colors();
  }

}
