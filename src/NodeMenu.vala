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

public class NodeMenu {

  private DrawArea    _da;
  private PopoverMenu _popover;

  private const GLib.ActionEntry action_entries[] = {
    { "action_copy",                         action_copy },
    { "action_cut",                          action_cut },
    { "action_paste",                        action_paste },
    { "action_replace",                      action_replace },
    { "action_delete_node",                  action_delete_node },
    { "action_delete_node_only",             action_delete_node_only },
    { "action_change_link_color",            action_change_link_color },
    { "action_randomize_link_color",         action_randomize_link_color },
    { "action_reparent_link_color",          action_reparent_link_color },
    { "action_edit_node",                    action_edit_node },
    { "action_edit_note",                    action_edit_note },
    { "action_change_task",                  action_change_task },
    { "action_change_image",                 action_change_image },
    { "action_remove_sticker",               action_remove_sticker },
    { "action_change_link",                  action_change_link },
    { "action_add_connection",               action_add_connection },
    { "action_add_group",                    action_add_group },
    { "action_add_callout",                  action_add_callout },
    { "action_fold_node",                    action_fold_node },
    { "action_toggle_sequence",              action_toggle_sequence },
    { "action_add_root_node",                action_add_root_node },
    { "action_add_parent_node",              action_add_parent_node },
    { "action_add_child_node",               action_add_child_node },
    { "action_add_sibling_node",             action_add_sibling_node },
    { "action_quick_entry_insert",           action_quick_entry_insert },
    { "action_quick_entry_replace",          action_quick_entry_replace },
    // { "action_convert_to_summary_node", action_convert_to_summary_node },
    { "action_select_root_node",             action_select_root_node },
    { "action_select_next_sibling_node",     action_select_next_sibling_node },
    { "action_select_previous_sibling_node", action_select_previous_sibling_node },
    { "action_select_child_node",            action_select_child_node },
    { "action_select_child_nodes",           action_select_child_nodes },
    { "action_select_node_tree",             action_select_node_tree },
    { "action_select_parent_nodes",          action_select_parent_nodes },
    { "action_select_linked_node",           action_select_linked_node },
    { "action_select_connection",            action_select_connection },
    { "action_select_callout",               action_select_callout },
    { "action_center_current_node",          action_center_current_node },
    { "action_sort_alphabetically",          action_sort_alphabetically },
    { "action_sort_randomly",                action_sort_randomly },
    { "action_detach_node",                  action_detach_node },
  };

  /* Default constructor */
  public NodeMenu( Gtk.Application app, DrawArea da ) {

    _da = da;

    var edit_menu = new GLib.Menu();
    edit_menu.append( _( "Copy" ),                   "node.action_copy" );
    edit_menu.append( _( "Cut" ),                    "node.action_cut" );
    edit_menu.append( _( "Paste" ),                  "node.action_paste" );
    edit_menu.append( _( "Paste and Replace Node" ), "node.action_replace" );
    edit_menu.append( _( "Delete" ),                 "node.action_delete_node" );
    edit_menu.append( _( "Delete Single Node" ),     "node.action_delete_node_only" );

    var color_menu = new GLib.Menu();
    color_menu.append( _( "Set to color…" ),    "node.action_change_link_color" );
    color_menu.append( _( "Randomize color" ),  "node.action_randomize_link_color" );
    color_menu.append( _( "Use parent color" ), "node.action_reparent_link_color" );

    var change_submenu = new GLib.Menu();
    change_submenu.append( _( "Edit Text…" ),      "node.action_edit_node" );
    change_submenu.append( _( "Edit Note" ),       "node.action_edit_note" );
    change_submenu.append( _( "Add Task" ),        "node.action_change_task" );
    change_submenu.append( _( "Add Image" ),       "node.action_change_image" );
    change_submenu.append( _( "Remove Sticker" ),  "node.action_remove_sticker" );
    change_submenu.append( _( "Add Node Link" ),   "node.action_change_link" );
    change_submenu.append( _( "Add Connection" ),  "node.action_add_connection" );
    change_submenu.append( _( "Add Group" ),       "node.action_add_group" );
    change_submenu.append( _( "Add Callout" ),     "node.action_add_callout" );
    change_submenu.append_submenu( _( "Link Color" ), color_menu );
    change_submenu.append( _( "Fold Children" ),   "node.action_fold_node" );
    change_submenu.append( _( "Toggle Sequence" ), "node.action_toggle_sequence" );

    var change_menu = new GLib.Menu();
    change_menu.add_submenu( _( "Change Node" ), change_submenu );

    var add_submenu = new GLib.Menu();
    add_submenu.append( _( "Add Root Node" ),    "node.action_add_root_node" );
    add_submenu.append( _( "Add Parent Node" ),  "node.action_add_parent_node" );
    add_submenu.append( _( "Add Child Node" ),   "node.action_add_child_node" );
    add_submenu.append( _( "Add Sibling Node" ), "node.action_add_sibling_node" );

    var quick_menu = new GLib.Menu();
    quick_menu.append( _( "Insert Nodes" ),  "node.action_quick_entry_insert" );
    quick_menu.append( _( "Replace Nodes" ), "node.action_quick_entry_replace" );

    var add_menu = new GLib.Menu();
    add_menu.append_submenu( _( "Add Node" ), add_submenu );
    // add_menu.append( _( "Use to Summarize Previous Sibling Nodes" ), "node.action_convert_to_summary_node" );
    add_menu.append_submenu( _( "Quick Entry" ), quick_menu );

    var sel_node_menu = new GLib.Menu();
    sel_node_menu.append( _( "Root Node" ),             "node.action_select_root_node" );
    sel_node_menu.append( _( "Next Sibling Node" ),     "node.action_select_next_sibling_node" );
    sel_node_menu.append( _( "Previous Sibling Node" ), "node.action_select_previous_sibling_node" );
    sel_node_menu.append( _( "Child Node" ),            "node.action_select_child_node" );
    sel_node_menu.append( _( "Child Nodes" ),           "node.action_select_child_nodes" );
    sel_node_menu.append( _( "Subtree" ),               "node.action_select_node_tree" );
    sel_node_menu.append( _( "Parent Node" ),           "node.action_select_parent_nodes" );
    sel_node_menu.append( _( "Linked Node" ),           "node.action_select_linked_node" );

    var sel_other_menu = new GLib.Menu();
    sel_other_menu.append( _( "Connection" ), "node.action_select_connection" );
    sel_other_menu.append( _( "Callout" ),    "node.action_select_callout" );

    var sel_submenu = new GLib.Menu();
    sel_submenu.append_section( null, sel_node_menu );
    sel_submenu.append_section( null, sel_other_menu );

    var sel_menu = new GLib.Menu();
    sel_menu.append_section( null, sel_submenu );
    sel_menu.append( _( "Center Current Node" ), "node.action_center_current_node" );

    var sort_submenu = new GLib.Menu();
    sort_submenu.append( _( "Alphabetically" ), "node.action_sort_alphabetically" );
    sort_submenu.append( _( "Randomize" ),      "node.action_sort_randomly" );

    var sort_menu = new GLib.Menu();
    sort_menu.append_submenu( _( "Sort Children" ), sort_submenu );

    var detach_menu = new GLib.Menu();
    detach_menu.append( _( "Detach" ), "node.action_detach_node" );

    var menu = new GLib.Menu();
    menu.append_section( null, edit_menu );
    menu.append_section( null, change_menu );
    menu.append_section( null, add_menu );
    menu.append_section( null, sel_menu );
    menu.append_section( null, sort_menu );
    menu.append_section( null, detach_menu );

    _popover = new PopoverMenu.with_model( menu );

    // Add the menu actions
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    _da.insert_action_group( "node", actions );

    // Add keyboard shortcuts
    app.set_accels_for_action( "node.action_copy",                { "<Control>c" } );
    app.set_accels_for_action( "node.action_cut",                 { "<Control>x" } );
    app.set_accels_for_action( "node.action_paste",               { "<Control>v" } );
    app.set_accels_for_action( "node.action_replace",             { "<Control><Shift>v" } );
    app.set_accels_for_action( "node.action_delete",              { "Delete" } );
    app.set_accels_for_action( "node.action_edit_node",           { "e" } );
    app.set_accels_for_action( "node.action_edit_note",           { "<Shift>e" } );
    app.set_accels_for_action( "node.action_change_task",         { "t" } );
    app.set_accels_for_action( "node.action_change_image",        { "<Shift>i" } );
    app.set_accels_for_action( "node.action_change_link",         { "y" } );
    app.set_accels_for_action( "node.action_add_connection",      { "x" } );
    app.set_accels_for_action( "node.action_add_group",           { "g" } );
    app.set_accels_for_action( "node.action_add_callout",         { "o" } );
    app.set_accels_for_action( "node.action_change_link_color",   { "<Shift>l" } );
    app.set_accels_for_action( "node.action_fold_node",           { "f" } );
    app.set_accels_for_action( "node.action_toggle_sequence",     { "numbersign" } );
    app.set_accels_for_action( "node.action_add_child_node",      { "Tab" } );
    app.set_accels_for_action( "node.action_add_sibling_node",    { "Return" } );
    // app.set_accels_for_action( "node.action_convert_to_summary_node", { "<Shift>Tab" } );
    app.set_accels_for_action( "node.action_quick_entry_insert",  { "<Control><Shift>e" } );
    app.set_accels_for_action( "node.action_quick_entry_replace", { "<Control><Shift>r" } );
    app.set_accels_for_action( "node.action_select_root_node",             { "m" } );
    app.set_accels_for_action( "node.action_select_next_sibling_node",     { "n" } );
    app.set_accels_for_action( "node.action_select_previous_sibling_node", { "p" } );
    app.set_accels_for_action( "node.action_select_child_node",            { "c" } );
    app.set_accels_for_action( "node.action_select_child_nodes",           { "d" } );
    app.set_accels_for_action( "node.action_select_node_tree",             { "<Shift>d" } );
    app.set_accels_for_action( "node.action_select_parent_nodes",          { "a" } );
    app.set_accels_for_action( "node.action_select_linked_node",           { "<Shift>y" } );
    app.set_accels_for_action( "node.action_select_connection",            { "<Shift>x" } );
    app.set_accels_for_action( "node.action_select_callout",               { "<Shift>o" } );
    app.set_accels_for_action( "node.action_center_current_node",          { "<Shift>c" } );

  }

  //-------------------------------------------------------------
  // Shows this menu at the given location.
  public void show( double x, double y ) {

    // Handle menu state
    on_popup();

    // Display the popover at the given location
    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    _popover.pointing_to = rect;
    _popover.popup();

  }

  /* Returns true if the currently selected node is a task */
  private bool node_is_task() {
    Node? current = _da.get_current_node();
    return( (current != null) && current.task_enabled() );
  }

  /* Returns true if the currently selected node task is marked as done */
  private bool node_task_is_done() {
    Node? current = _da.get_current_node();
    return( node_is_task() && current.task_done() );
  }

  /* Returns true if a note is associated with the currently selected node */
  private bool node_has_note() {
    Node? current = _da.get_current_node();
    return( (current != null) && (current.note != "") );
  }

  /* Returns true if an image is associated with the currently selected node */
  private bool node_has_image() {
    Node? current = _da.get_current_node();
    return( (current != null) && (current.image != null) );
  }

  /* Returns true if an node link is associated with the currently selected node */
  private bool node_has_link() {
    Node? current = _da.get_current_node();
    return( (current != null) && (current.linked_node != null) );
  }

  /* Returns true if a callout is associated with the currently selected node */
  private bool node_has_callout() {
    var current = _da.get_current_node();
    return( (current != null) && (current.callout != null) );
  }

  /* Returns true if there is a currently selected node that is foldable */
  private bool node_foldable() {
    Node? current = _da.get_current_node();
    return( (current != null) && !current.is_leaf() );
  }

  /* Returns true if there are two or more nodes in the map and one is selected */
  private bool node_linkable() {
    Node? current = _da.get_current_node();
    return( (current != null) && (!current.is_root() || (_da.get_nodes().length > 1)) );
  }

  /* Returns true if the currently selected node can have a parent node added */
  private bool node_parentable() {
    Node? current = _da.get_current_node();
    return( (current != null) && !current.is_root() );
  }

  /* Returns true if the currently selected node has more than one child node */
  private bool node_sortable() {
    Node? current = _da.get_current_node();
    return( (current != null) && (current.children().length > 1) );
  }

  /*
   Returns true if there is a currently selected node that is currently
   folded.
  */
  private bool node_is_folded() {
    Node? current = _da.get_current_node();
    return( (current != null) && current.folded );
  }

  /* Called when the menu is popped up */
  private void on_popup() {

    var current = _da.get_current_node();

    /* Set the menu sensitivity */
    _da.set_action_enabled( "node.action_paste", true );
    _da.set_action_enabled( "node.action_replace", true );
    _da.set_action_enabled( "node.action_add_connection", !_da.get_connections().hide );
    _da.set_action_enabled( "node.action_add_parent_node", node_parentable() );
    _da.set_action_enabled( "node.action_change_link_color",    !current.is_root() );
    _da.set_action_enabled( "node.action_randomize_link_color", !current.is_root() );
    _da.set_action_enabled( "node.action_reparent_link_color",  (!current.is_root() && !current.main_branch() && current.link_color_root) );
    _da.set_action_enabled( "node.action_fold_node", node_foldable() );
    _da.set_action_enabled( "node.action_toggle_sequence", _da.sequences_togglable() );
    _da.set_action_enabled( "node.action_change_link", node_linkable() );
    _da.set_action_enabled( "node.action_detach_node", _da.detachable() );
    _da.set_action_enabled( "node.action_sort_alphabetically", node_sortable() );
    _da.set_action_enabled( "node.action_sort_randomly",       node_sortable() );
    _da.set_action_enabled( "node.action_select_root_node", _da.root_selectable() );
    _da.set_action_enabled( "node.action_select_next_sibling_node", _da.sibling_selectable() );
    _da.set_action_enabled( "node.action_select_previous_sibling_node", _da.sibling_selectable() );
    _da.set_action_enabled( "node.action_select_child_node", _da.children_selectable() );
    _da.set_action_enabled( "node.action_select_parent_node", _da.parent_selectable() );
    _da.set_action_enabled( "node.action_select_linked_node", node_has_link() );
    _da.set_action_enabled( "node.action_select_callout", node_has_callout() );
    _da.set_action_enabled( "node.action_remove_sticker", (current.sticker != null) );
    _da.set_action_enabled( "node.action_add_sibling_node", !current.is_summary() );
    _da.set_action_enabled( "node.action_convert_to_summary_node", _da.node_summarizable() );

    /* TODO
    // Set the menu item labels
    var task_lbl    = node_is_task()   ?
                      node_task_is_done() ? _( "Remove Task" ) :
                                            _( "Mark Task As Done" ) :
                                            _( "Add Task" );
    var link_lbl    = node_has_link()  ? _( "Remove Node Link" ) : _( "Add Node Link" );
    var fold_lbl    = node_is_folded() ? _( "Unfold Children" )  : _( "Fold Children" );
    var callout_lbl = node_has_callout() ? _( "Remove Callout" ) : _( "Add Callout" );

    _task.get_child().destroy();
    _task.add( new Granite.AccelLabel( task_lbl, task_acc.accel_string ) );
    _link.get_child().destroy();
    _link.add( new Granite.AccelLabel( link_lbl, link_acc.accel_string ) );
    _fold.get_child().destroy();
    _fold.add( new Granite.AccelLabel( fold_lbl, fold_acc.accel_string ) );
    _callout.get_child().destroy();
    _callout.add( new Granite.AccelLabel( callout_lbl, callout_acc.accel_string ) );

    _image.get_child().destroy();
    if( node_has_image() ) {
      _image.add( new Granite.AccelLabel( _( "Remove Image" ), null ) );
    } else {
      _image.add( new Granite.AccelLabel( _( "Add Image" ), "<Shift>i" ) );
    }

    // Set the paste and replace text
    if( MinderClipboard.node_pasteable() ) {
      _paste.label   = _( "Paste Node As Child" );
      _replace.label = _( "Paste and Replace Node" );
    } else if( MinderClipboard.image_pasteable() ) {
      _paste.label   = _( "Paste Image As Child Node" );
      _replace.label = _( "Paste and Replace Node Image" );
    } else if( MinderClipboard.text_pasteable() ) {
      _paste.label   = _( "Paste Text As Child Node" );
      _replace.label = _( "Paste and Replace Node Text" );
    } else {
      _da.set_action_enabled( "node.action_paste",   false );
      _da.set_action_enabled( "node.action_replace", false );
    }
    */

  }

  /* Copies the current node to the clipboard */
  private void action_copy() {
    _da.do_copy();
  }

  /* Cuts the current node to the clipboard */
  private void action_cut() {
    _da.do_cut();
  }

  /*
   Pastes the node stored in the clipboard as either a root node (if no
   node is currently selected) or attaches it to the currently selected
   node.
  */
  private void action_paste() {
    _da.do_paste( false );
  }

  /*
   Replaces the node's text, image or entire node with the contents stored
   in the clipboard.
  */
  private void action_replace() {
    _da.do_paste( true );
  }

  /* Deletes the current node */
  private void action_delete_node() {
    _da.delete_node();
  }

  /* Deletes just the node that is selected */
  private void action_delete_node_only() {
    _da.delete_nodes();
  }

  /* Displays the sidebar to edit the node properties */
  private void action_edit_node() {
    var current = _da.get_current_node();
    _da.set_node_mode( current, NodeMode.EDITABLE );
    _da.queue_draw();
  }

  /* Changes the task status of the currently selected node */
  private void action_change_task() {
    if( node_is_task() ) {
      if( node_task_is_done() ) {
        _da.change_current_task( false, false );
      } else {
        _da.change_current_task( true, true );
      }
    } else {
      _da.change_current_task( true, false );
    }
    _da.current_changed( _da );
  }

  /* Changes the note status of the currently selected node */
  private void action_edit_note() {
    _da.show_properties( "current", PropertyGrab.NOTE );
  }

  /* Changes the image of the currently selected node */
  private void action_change_image() {
    if( node_has_image() ) {
      _da.delete_current_image();
    } else {
      _da.add_current_image();
    }
    _da.current_changed( _da );
  }

  /* Removes the sticker from the node */
  private void action_remove_sticker() {
    var current = _da.get_current_node();
    _da.undo_buffer.add_item( new UndoNodeStickerRemove( current ) );
    current.sticker = null;
    _da.queue_draw();
    _da.auto_save();
  }

  /* Changes the node link of the currently selected node */
  private void action_change_link() {
    if( node_has_link() ) {
      _da.delete_links();
    } else {
      _da.start_connection( false, true );
    }
  }

  /* Changes the connection of the currently selected node */
  private void action_add_connection() {
    _da.start_connection( false, false );
  }

  /* Creates a group from the currently selected node */
  private void action_add_group() {
    _da.add_group();
  }

  /* Adds a callback to the currently selected node */
  private void action_add_callout() {
    if( node_has_callout() ) {
      _da.remove_callout();
    } else {
      _da.add_callout();
    }
  }

  /* Fold the currently selected node */
  private void action_fold_node() {
    _da.change_current_fold( !node_is_folded() );
  }

  //-------------------------------------------------------------
  // Toggles the sequence indicator of the current node
  private void action_toggle_sequence() {
    _da.toggle_sequence();
  }

  /* Creates a new root node */
  private void action_add_root_node() {
    _da.add_root_node();
  }

  /* Creates a new parent node for the current node */
  private void action_add_parent_node() {
    _da.add_parent_node();
  }

  /* Creates a new child node from the current node */
  private void action_add_child_node() {
    _da.add_child_node();
  }

  /* Creates a sibling node of the current node */
  private void action_add_sibling_node() {
    _da.add_sibling_node( false );
  }

  /* Converts the current node into a summary node */
  private void action_convert_to_summary_node() {
    _da.add_summary_node_from_current();
  }

  /* Show the quick entry insert window */
  private void action_quick_entry_insert() {
    _da.handle_control_E();
  }

  /* Show the quick entry replace window */
  private void action_quick_entry_replace() {
    _da.handle_control_R();
  }

  /* Detaches the currently selected node and make it a root node */
  private void action_detach_node() {
    _da.detach();
  }

  /* Selects the current root node */
  private void action_select_root_node() {
    _da.select_root_node();
  }

  /* Selects the next sibling node of the current node */
  private void action_select_next_sibling_node() {
    _da.select_sibling_node( 1 );
  }

  /* Selects the previous sibling node of the current node */
  private void action_select_previous_sibling_node() {
    _da.select_sibling_node( -1 );
  }

  /* Selects the first child node of the current node */
  private void action_select_child_node() {
    _da.select_child_node();
  }

  /* Selects all of the child nodes of the current node */
  private void action_select_child_nodes() {
    _da.select_child_nodes();
  }

  /* Selects all of the descendant nodes of the current node */
  private void action_select_node_tree() {
    _da.select_node_tree();
  }

  /* Selects the parent node of the current node */
  private void action_select_parent_nodes() {
    _da.select_parent_nodes();
  }

  /* Selects the node the current node is linked to */
  private void action_select_linked_node() {
    _da.select_linked_node();
  }

  /* Selects the one of the connections attached to the current node */
  private void action_select_connection() {
    _da.select_attached_connection();
  }

  /* Selects the associated callout */
  private void action_select_callout() {
    _da.select_callout();
  }

  /* Centers the current node */
  private void action_center_current_node() {
    _da.center_current_node();
  }

  private void action_sort_alphabetically() {
    _da.sort_alphabetically();
  }

  private void action_sort_randomly() {
    _da.sort_randomly();
  }

  public void action_change_link_color() {
    var color_picker = new ColorChooserDialog( _( "Select a link color" ), _da.win );
    if( color_picker.run() == ResponseType.OK ) {
      _da.change_current_link_color( color_picker.get_rgba() );
    }
    color_picker.close();
  }

  private void action_randomize_link_color() {
    _da.randomize_current_link_color();
  }

  private void action_reparent_link_color() {
    _da.reparent_current_link_color();
  }

}
