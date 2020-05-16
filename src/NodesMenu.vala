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
  Gtk.MenuItem _align;

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

    var align_menu = new Gtk.Menu();

    _align = new Gtk.MenuItem.with_label( _( "Align Nodes" ) );
    _align.set_submenu( align_menu );

    var align_top = new Gtk.MenuItem.with_label( _( "Align Top" ) );
    align_top.activate.connect( align_to_top );

    var align_hcenter = new Gtk.MenuItem.with_label( _( "Align Center Horizontally" ) );
    align_hcenter.activate.connect( align_to_hcenter );

    var align_bottom = new Gtk.MenuItem.with_label( _( "Align Bottom" ) );
    align_bottom.activate.connect( align_to_bottom );

    var align_left = new Gtk.MenuItem.with_label( _( "Align Left" ) );
    align_left.activate.connect( align_to_left );

    var align_vcenter = new Gtk.MenuItem.with_label( _( "Align Center Veritically" ) );
    align_vcenter.activate.connect( align_to_vcenter );

    var align_right = new Gtk.MenuItem.with_label( _( "Align Right" ) );
    align_right.activate.connect( align_to_right );

    align_menu.add( align_top );
    align_menu.add( align_hcenter );
    align_menu.add( align_bottom );
    align_menu.add( new SeparatorMenuItem() );
    align_menu.add( align_left );
    align_menu.add( align_vcenter );
    align_menu.add( align_right );

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
    add( new SeparatorMenuItem() );
    add( _align );

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

    var nodes    = _da.get_selected_nodes();
    var node_num = nodes.length;

    bool foldable, unfoldable;
    nodes_foldable_status( out foldable, out unfoldable );

    /* Set the menu sensitivity */
    _fold.set_sensitive( foldable || unfoldable );
    _connect.set_sensitive( node_num == 2 );
    _parent_link_colors.set_sensitive( link_colors_parentable() );
    _align.set_sensitive( _da.nodes_alignable() );

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

  /* Aligns all selected nodes to the top of the first node */
  private void align_to_top() {
    NodeAlign.align_top( _da, _da.get_selected_nodes() );
  }

  /* Aligns all selected nodes to the center of the first node horizontally */
  private void align_to_hcenter() {
    NodeAlign.align_hcenter( _da, _da.get_selected_nodes() );
  }

  /* Aligns all selected nodes to the bottom of the first node */
  private void align_to_bottom() {
    NodeAlign.align_bottom( _da, _da.get_selected_nodes() );
  }

  /* Aligns all selected nodes to the left side of the first node */
  private void align_to_left() {
    NodeAlign.align_left( _da, _da.get_selected_nodes() );
  }

  /* Aligns all selected nodes to the center of the first node vertically */
  private void align_to_vcenter() {
    NodeAlign.align_vcenter( _da, _da.get_selected_nodes() );
  }

  /* Aligns all selected nodes to the right side of the first node */
  private void align_to_right() {
    NodeAlign.align_right( _da, _da.get_selected_nodes() );
  }

}
