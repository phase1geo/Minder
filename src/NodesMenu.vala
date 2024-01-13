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
  Gtk.MenuItem _task;
  Gtk.MenuItem _fold;
  Gtk.MenuItem _connect;
  Gtk.MenuItem _link;
  // Gtk.MenuItem _summary;
  Gtk.MenuItem _link_colors;
  Gtk.MenuItem _parent_link_colors;
  Gtk.MenuItem _align;
  Gtk.MenuItem _selnodes;
  Gtk.MenuItem _selparent;
  Gtk.MenuItem _selchildren;

  /* Default constructor */
  public NodesMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    _copy = new Gtk.MenuItem();
    _copy.add( new Granite.AccelLabel( _( "Copy" ), "<Control>c" ) );
    _copy.activate.connect( copy_nodes );

    _cut = new Gtk.MenuItem();
    _cut.add( new Granite.AccelLabel( _( "Cut" ), "<Control>x" ) );
    _cut.activate.connect( cut_nodes );

    _delete = new Gtk.MenuItem();
    _delete.add( new Granite.AccelLabel( _( "Delete" ), "Delete" ) );
    _delete.activate.connect( delete_nodes );

    _task = new Gtk.MenuItem();
    _task.add( new Granite.AccelLabel( _( "Toggle Tasks" ), "t" ) );
    _task.activate.connect( toggle_tasks );

    _fold = new Gtk.MenuItem();
    _fold.add( new Granite.AccelLabel( _( "Fold Children" ), "f" ) );
    _fold.activate.connect( fold_nodes );

    _connect = new Gtk.MenuItem();
    _connect.add( new Granite.AccelLabel( _( "Connect" ), "x" ) );
    _connect.activate.connect( connect_nodes );

    _link = new Gtk.MenuItem();
    _link.add( new Granite.AccelLabel( _( "Link Nodes" ), "y" ) );
    _link.activate.connect( link_nodes );

    // _summary = new Gtk.MenuItem();
    // _summary.add( new Granite.AccelLabel( _( "Add Summary Node" ), "<Shift>Tab" ) );
    // _summary.activate.connect( summarize );

    var link_color_menu = new Gtk.Menu();

    _link_colors = new Gtk.MenuItem.with_label( _( "Link Colors" ) );
    _link_colors.set_submenu( link_color_menu );

    var set_link_colors = new Gtk.MenuItem();
    set_link_colors.add( new Granite.AccelLabel( _( "Set to color…" ), "<Shift>l" ) ); 
    set_link_colors.activate.connect( change_link_colors );

    var rand_link_colors = new Gtk.MenuItem.with_label( _( "Randomize colors" ) );
    rand_link_colors.activate.connect( randomize_link_colors );

    _parent_link_colors = new Gtk.MenuItem.with_label( _( "Use parent color" ) );
    _parent_link_colors.activate.connect( reparent_link_colors );

    link_color_menu.add( set_link_colors );
    link_color_menu.add( rand_link_colors );
    link_color_menu.add( _parent_link_colors );

    var selmenu = new Gtk.Menu();

    _selnodes = new Gtk.MenuItem.with_label( _( "Select" ) );
    _selnodes.set_submenu( selmenu );

    _selparent = new Gtk.MenuItem();
    _selparent.add( new Granite.AccelLabel( _( "Parent Nodes" ), "a" ) );
    _selparent.activate.connect( select_parent_nodes );
    // Utils.add_accel_label( _selparent, 'a', 0 );

    _selchildren = new Gtk.MenuItem();
    _selchildren.add( new Granite.AccelLabel( _( "Child Nodes" ), "d" ) );
    _selchildren.activate.connect( select_child_nodes );
    // Utils.add_accel_label( _selchildren, 'd', 0 );

    selmenu.add( _selparent );
    selmenu.add( _selchildren );

    var align_menu = new Gtk.Menu();

    _align = new Gtk.MenuItem.with_label( _( "Align Nodes" ) );
    _align.set_submenu( align_menu );

    var align_top = new Gtk.MenuItem();
    align_top.add( new Granite.AccelLabel( _( "Align Top" ), "minus" ) );
    align_top.activate.connect( align_to_top );

    var align_hcenter = new Gtk.MenuItem();
    align_hcenter.add( new Granite.AccelLabel( _( "Align Center Horizontally" ), "equal" ) );
    align_hcenter.activate.connect( align_to_hcenter );

    var align_bottom = new Gtk.MenuItem();
    align_bottom.add( new Granite.AccelLabel( _( "Align Bottom" ), "underscore" ) );
    align_bottom.activate.connect( align_to_bottom );

    var align_left = new Gtk.MenuItem();
    align_left.add( new Granite.AccelLabel( _( "Align Left" ), "bracketleft" ) );
    align_left.activate.connect( align_to_left );

    var align_vcenter = new Gtk.MenuItem();
    align_vcenter.add( new Granite.AccelLabel( _( "Align Center Vertically" ), "bar" ) );
    align_vcenter.activate.connect( align_to_vcenter );

    var align_right = new Gtk.MenuItem();
    align_right.add( new Granite.AccelLabel( _( "Align Right" ), "bracketright" ) );
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
    add( _task );
    add( _link_colors );
    add( _fold );
    add( new SeparatorMenuItem() );
    add( _connect );
    add( _link );
    // add( _summary );
    add( new SeparatorMenuItem() );
    add( _selnodes );
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

    var nodes        = _da.get_selected_nodes();
    var node_num     = nodes.length;
    var has_link     = _da.any_selected_nodes_linked();
    var summarizable = _da.nodes_summarizable();

    bool foldable, unfoldable;
    nodes_foldable_status( out foldable, out unfoldable );

    /* Set the menu sensitivity */
    _fold.set_sensitive( foldable || unfoldable );
    _connect.set_sensitive( node_num == 2 );
    // _summary.set_sensitive( summarizable );
    _parent_link_colors.set_sensitive( link_colors_parentable() );
    _align.set_sensitive( _da.nodes_alignable() );
    _selparent.set_sensitive( _da.parent_selectable() );
    _selchildren.set_sensitive( _da.children_selectable() );

    var fold_acc = (Granite.AccelLabel)_fold.get_child();
    var link_acc = (Granite.AccelLabel)_link.get_child();
    var fold_lbl = unfoldable ? _( "Unfold Children" )   : _( "Fold Children" );
    var link_lbl = has_link   ? _( "Remove Node Links" ) : _( "Link Nodes" );

    _fold.get_child().destroy();
    _fold.add( new Granite.AccelLabel( fold_lbl, fold_acc.accel_string ) );
    _link.get_child().destroy();
    _link.add( new Granite.AccelLabel( link_lbl, link_acc.accel_string ) );

  }

  /* Returns true if all of the nodes in the array have the same parent */
  private bool have_same_parent( Array<Node> nodes ) {
    var first = nodes.index( 0 );
    for( int i=1; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      if( first.parent != node.parent ) return( false );
    }
    return( true );
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

  /* Toggles the task indicator of the selected nodes */
  private void toggle_tasks() {
    _da.change_selected_tasks();
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
    _da.toggle_links();
  }

  /* Adds a new summary node */
  private void summarize() {
    _da.add_summary_node_from_selected();
  }

  /* Changes the color of all selected nodes */
  public void change_link_colors() {
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

  /* Selects all of the parent nodes of the selected nodes */
  private void select_parent_nodes() {
    _da.select_parent_nodes();
  }

  /* Selects all child nodes of selected nodes */
  private void select_child_nodes() {
    _da.select_child_nodes();
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
