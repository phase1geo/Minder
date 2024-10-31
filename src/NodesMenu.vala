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

public class NodesMenu {

  private DrawArea    _da;
  private PopoverMenu _popover;

  private const GLib.ActionEntry action_entries[] = {
    { "action_copy",                  action_copy },
    { "action_cut",                   action_cut },
    { "action_delete",                action_delete },
    { "action_change_link_colors",    action_change_link_colors },
    { "action_randomize_link_colors", action_randomize_link_colors },
    { "action_reparent_link_colors",  action_reparent_link_colors },
    { "action_toggle_tasks",          action_toggle_tasks },
    { "action_fold_nodes",            action_fold_nodes },
    { "action_toggle_sequences",      action_toggle_sequences },
    { "action_connect_nodes",         action_connect_nodes },
    { "action_link_nodes",            action_link_nodes },
    // { "action_summarize",             action_summarize },
    { "action_select_parent_nodes",   action_select_parent_nodes },
    { "action_select_child_nodes",    action_select_child_nodes },
    { "action_align_to_top",          action_align_to_top },
    { "action_align_to_hcenter",      action_align_to_hcenter },
    { "action_align_to_bottom",       action_align_to_bottom },
    { "action_align_to_left",         action_align_to_left },
    { "action_align_to_vcenter",      action_align_to_vcenter },
    { "action_align_to_right",        action_align_to_right },
  };

  /* Default constructor */
  public NodesMenu( Gtk.Application app, DrawArea da ) {

    _da = da;

    var edit_menu = new GLib.Menu();
    edit_menu.append( _( "Copy" ),   "nodes.action_copy" );
    edit_menu.append( _( "Cut" ),    "nodes.action_cut" );
    edit_menu.append( _( "Delete" ), "nodes.action_delete" );

    var color_menu = new GLib.Menu();
    color_menu.append( _( "Set To Color…" ),    "nodes.action_change_link_colors" );
    color_menu.append( _( "Randomize Colors" ), "nodes.action_randomize_link_colors" );
    color_menu.append( _( "Use Parent Color" ), "nodes.action_reparent_link_colors" );

    var change_menu = new GLib.Menu();
    change_menu.append_submenu( _( "Link Colors" ), color_menu );
    change_menu.append( _( "Toggle Tasks" ),     "nodes.action_toggle_tasks" );
    change_menu.append( _( "Toggle Folds" ),     "nodes.action_fold_nodes" );
    change_menu.append( _( "Toggle Sequences" ), "nodes.action_toggle_sequences" );

    var link_menu = new GLib.Menu();
    link_menu.append( _( "Connect" ),    "nodes.action_connect_nodes" );
    link_menu.append( _( "Link Nodes" ), "nodes.action_link_nodes" );
    // link_menu.append( _( "Add Summary Node" ), "nodes.action_summarize" );

    var sel_submenu = new GLib.Menu();
    sel_submenu.append( _( "Parent Nodes" ), "nodes.action_select_parent_nodes" );
    sel_submenu.append( _( "Child Nodes" ),  "nodes.action_select_child_nodes" );

    var sel_menu = new GLib.Menu();
    sel_menu.append_submenu( _( "Select" ), sel_submenu );

    var align_vert_menu = new GLib.Menu();
    align_vert_menu.append( _( "Align Top" ),                 "nodes.action_align_to_top" );
    align_vert_menu.append( _( "Align Center Horizontally" ), "nodes.action_align_to_hcenter" );
    align_vert_menu.append( _( "Align Bottom" ),              "nodes.action_align_to_bottom" );

    var align_horz_menu = new GLib.Menu();
    align_horz_menu.append( _( "Align Left" ),              "nodes.action_align_to_left" );
    align_horz_menu.append( _( "Align Center Vertically" ), "nodes.action_align_to_vcenter" );
    align_horz_menu.append( _( "Align Right" ),             "nodes.action_align_to_right" );

    var align_submenu = new GLib.Menu();
    align_submenu.append_section( null, align_vert_menu );
    align_submenu.append_section( null, align_horz_menu );

    var align_menu = new GLib.Menu();
    align_menu.append_submenu( _( "Align" ), align_submenu );

    var menu = new GLib.Menu();
    menu.append_section( null, edit_menu );
    menu.append_section( null, change_menu );
    menu.append_section( null, link_menu );
    menu.append_section( null, sel_menu );
    menu.append_section( null, align_menu );

    _popover = new Popover.with_model( menu );

    // Add the menu actions
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    _da.insert_action_group( "nodes", actions );

    // Add keyboard shortcuts
    app.set_accels_for_action( "nodes.action_copy",               { "<Control>c" } );
    app.set_accels_for_action( "nodes.action_cut",                { "<Control>x" } );
    app.set_accels_for_action( "nodes.action_delete",             { "Delete" } );
    app.set_accels_for_action( "nodes.action_toggle_tasks",       { "t" } );
    app.set_accels_for_action( "nodes.action_toggle_folds",       { "f" } );
    app.set_accels_for_action( "nodes.action_change_link_colors", { "<Shift>l" } );
    app.set_accels_for_action( "nodes.action_toggle_sequences",   { "numbersign" } );
    app.set_accels_for_action( "nodes.action_connect_nodes",      { "x" } );
    app.set_accels_for_action( "nodes.action_link_nodes",         { "y" } );
    // app.set_accels_for_action( "nodes.action_summarize",          { "<Shift>Tab" } );
    app.set_accels_for_action( "nodes.action_select_parent_nodes", { "a" } );
    app.set_accels_for_action( "nodes.action_select_child_nodes",  { "d" } );
    app.set_accels_for_action( "nodes.action_align_to_top",        { "minus" } );
    app.set_accels_for_action( "nodes.action_align_to_hcenter",    { "equal" } );
    app.set_accels_for_action( "nodes.action_align_to_bottom",     { "underscore" } );
    app.set_accels_for_action( "nodes.action_align_to_left",       { "bracketleft" } );
    app.set_accels_for_action( "nodes.action_align_to_vcenter",    { "bar" } );
    app.set_accels_for_action( "nodes.action_align_to_right",      { "bracketright" } );

  }

  //-------------------------------------------------------------
  // Shows this menu.
  public void show( double x, double y ) {

    on_popup();

    /* Display the popover at the given location */
    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    _popover.pointing_to = rect;
    _popover.popup();

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
    var summarizable = _da.nodes_summarizable();
    var alignable    = _da.nodes_alignable();

    bool foldable, unfoldable;
    nodes_foldable_status( out foldable, out unfoldable );

    /* Set the menu sensitivity */
    _da.set_action_enabled( "nodes.action_toggle_folds",         (foldable || unfoldable) );
    _da.set_action_enabled( "nodes.action_toggle_sequences",     _da.sequences_togglable() );
    _da.set_action_enabled( "nodes.action_connect_nodes",        (node_num == 2) );
    // _da.set_action_enabled( "nodes.action_summarize",        summarizable );
    _da.set_action_enabled( "nodes.action_reparent_link_colors", link_colors_parentable() );
    _da.set_action_enabled( "nodes.action_align_to_top",         alignable );
    _da.set_action_enabled( "nodes.action_align_to_hcenter",     alignable );
    _da.set_action_enabled( "nodes.action_align_to_bottom",      alignable );
    _da.set_action_enabled( "nodes.action_align_to_left",        alignable );
    _da.set_action_enabled( "nodes.action_align_to_vcenter",     alignable );
    _da.set_action_enabled( "nodes.action_align_to_right",       alignable );
    _da.set_action_enabled( "nodes.action_select_parent_nodes",  _da.parent_selectable() );
    _da.set_action_enabled( "nodes.action_select_child_nodes",   _da.children_selectable() );

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
  private void action_copy() {
    _da.do_copy();
  }

  /* Cuts all selected nodes to the node clipboard */
  private void action_cut() {
    _da.do_cut();
  }

  /* Delete all selected nodes, collapsing deselected descendants */
  private void action_delete() {
    _da.delete_nodes();
  }

  /* Toggles the task indicator of the selected nodes */
  private void action_toggle_tasks() {
    _da.change_selected_tasks();
  }

  /* Folds/unfolds the selected nodes */
  private void action_fold_nodes() {
    _da.toggle_folds();
  }

  //-------------------------------------------------------------
  // Toggles sequences
  private void action_toggle_sequences() {
    _da.toggle_sequence();
  }

  /*
   Creates a connection between two selected nodes, where the first node is the from node and the
   second node is the to node.
  */
  private void action_connect_nodes() {
    _da.create_connection();
  }

  /*
   Links two selected nodes such that the first selected node will link to the second selected node.
  */
  private void action_link_nodes() {
    _da.toggle_links();
  }

  /* Adds a new summary node */
  private void action_summarize() {
    _da.add_summary_node_from_selected();
  }

  /* Changes the color of all selected nodes */
  public void action_change_link_colors() {
    var color_picker = new ColorChooserDialog( _( "Select a link color" ), _da.win );
    if( color_picker.run() == ResponseType.OK ) {
      _da.change_link_colors( color_picker.get_rgba() );
    }
    color_picker.close();
  }

  /* Randomize the selected link colors */
  private void action_randomize_link_colors() {
    _da.randomize_link_colors();
  }

  /* Changes the selected nodes to use parent node's colors */
  private void action_reparent_link_colors() {
    _da.reparent_link_colors();
  }

  /* Selects all of the parent nodes of the selected nodes */
  private void action_select_parent_nodes() {
    _da.select_parent_nodes();
  }

  /* Selects all child nodes of selected nodes */
  private void action_select_child_nodes() {
    _da.select_child_nodes();
  }

  /* Aligns all selected nodes to the top of the first node */
  private void action_align_to_top() {
    NodeAlign.align_top( _da, _da.get_selected_nodes() );
  }

  /* Aligns all selected nodes to the center of the first node horizontally */
  private void action_align_to_hcenter() {
    NodeAlign.align_hcenter( _da, _da.get_selected_nodes() );
  }

  /* Aligns all selected nodes to the bottom of the first node */
  private void action_align_to_bottom() {
    NodeAlign.align_bottom( _da, _da.get_selected_nodes() );
  }

  /* Aligns all selected nodes to the left side of the first node */
  private void action_align_to_left() {
    NodeAlign.align_left( _da, _da.get_selected_nodes() );
  }

  /* Aligns all selected nodes to the center of the first node vertically */
  private void action_align_to_vcenter() {
    NodeAlign.align_vcenter( _da, _da.get_selected_nodes() );
  }

  /* Aligns all selected nodes to the right side of the first node */
  private void action_align_to_right() {
    NodeAlign.align_right( _da, _da.get_selected_nodes() );
  }

}
