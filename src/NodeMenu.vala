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

public class NodeMenu : BaseMenu {

  private GLib.Menu _edit_menu;
  private GLib.Menu _change_submenu;

  //-------------------------------------------------------------
  // Default constructor
  public NodeMenu( Gtk.Application app, DrawArea da ) {

    base( app, da, "node" );

    _edit_menu = new GLib.Menu();
    append_menu_item( _edit_menu, KeyCommand.EDIT_COPY,          _( "Copy" ) );
    append_menu_item( _edit_menu, KeyCommand.EDIT_CUT,           _( "Cut" ) );
    append_menu_item( _edit_menu, KeyCommand.EDIT_PASTE,         _( "Paste" ) );
    append_menu_item( _edit_menu, KeyCommand.NODE_PASTE_REPLACE, _( "Paste and Replace Node" ) );
    append_menu_item( _edit_menu, KeyCommand.NODE_REMOVE,        _( "Delete" ) );
    append_menu_item( _edit_menu, KeyCommand.NODE_REMOVE_ONLY,   _( "Delete Single Node" ) );

    var color_menu = new GLib.Menu();
    append_menu_item( color_menu, KeyCommand.NODE_CHANGE_LINK_COLOR,    _( "Set to color…" ) );
    append_menu_item( color_menu, KeyCommand.NODE_RANDOMIZE_LINK_COLOR, _( "Randomize color" ) );
    append_menu_item( color_menu, KeyCommand.NODE_REPARENT_LINK_COLOR,  _( "Use parent color" ) );

    _change_submenu = new GLib.Menu();
    append_menu_item( _change_submenu, KeyCommand.EDIT_SELECTED,       _( "Edit Text…" ) );
    append_menu_item( _change_submenu, KeyCommand.EDIT_NOTE,           _( "Edit Note" ) );
    append_menu_item( _change_submenu, KeyCommand.NODE_CHANGE_TASK,    _( "Add Task" ) );
    append_menu_item( _change_submenu, KeyCommand.NODE_CHANGE_IMAGE,   _( "Add Image" ) );
    append_menu_item( _change_submenu, KeyCommand.REMOVE_STICKER_SELECTED, _( "Remove Sticker" ) );
    append_menu_item( _change_submenu, KeyCommand.NODE_TOGGLE_LINKS,   _( "Add Node Link" ) );
    append_menu_item( _change_submenu, KeyCommand.NODE_ADD_CONNECTION, _( "Add Connection" ) );
    append_menu_item( _change_submenu, KeyCommand.NODE_ADD_GROUP,      _( "Add Group" ) );
    append_menu_item( _change_submenu, KeyCommand.NODE_TOGGLE_CALLOUT, _( "Add Callout" ) );
    _change_submenu.append_submenu( _( "Link Color" ), color_menu );
    append_menu_item( _change_submenu, KeyCommand.NODE_TOGGLE_FOLDS_SHALLOW, _( "Fold Children" ) );
    append_menu_item( _change_submenu, KeyCommand.NODE_TOGGLE_SEQUENCE,      _( "Toggle Sequence" ) );

    var change_menu = new GLib.Menu();
    change_menu.append_submenu( _( "Change Node" ), _change_submenu );

    var add_submenu = new GLib.Menu();
    append_menu_item( add_submenu, KeyCommand.NODE_ADD_ROOT,          _( "Add Root Node" ) );
    append_menu_item( add_submenu, KeyCommand.NODE_ADD_PARENT,        _( "Add Parent Node" ) );
    append_menu_item( add_submenu, KeyCommand.NODE_ADD_CHILD,         _( "Add Child Node" ) );
    append_menu_item( add_submenu, KeyCommand.NODE_ADD_SIBLING_AFTER, _( "Add Sibling Node" ) );

    var quick_menu = new GLib.Menu();
    append_menu_item( quick_menu, KeyCommand.NODE_QUICK_ENTRY_INSERT,  _( "Insert Nodes" ) );
    append_menu_item( quick_menu, KeyCommand.NODE_QUICK_ENTRY_REPLACE, _( "Replace Nodes" ) );

    var add_menu = new GLib.Menu();
    add_menu.append_submenu( _( "Add Node" ), add_submenu );
    // add_menu.append( _( "Use to Summarize Previous Sibling Nodes" ), "node.action_convert_to_summary_node" );
    add_menu.append_submenu( _( "Quick Entry" ), quick_menu );

    var sel_node_menu = new GLib.Menu();
    append_menu_item( sel_node_menu, KeyCommand.NODE_SELECT_ROOT,         _( "Root Node" ) );
    append_menu_item( sel_node_menu, KeyCommand.NODE_SELECT_SIBLING_NEXT, _( "Next Sibling Node" ) );
    append_menu_item( sel_node_menu, KeyCommand.NODE_SELECT_SIBLING_PREV, _( "Previous Sibling Node" ) );
    append_menu_item( sel_node_menu, KeyCommand.NODE_SELECT_CHILD,        _( "Child Node" ) );
    append_menu_item( sel_node_menu, KeyCommand.NODE_SELECT_CHILDREN,     _( "Child Nodes" ) );
    append_menu_item( sel_node_menu, KeyCommand.NODE_SELECT_TREE,         _( "Subtree" ) );
    append_menu_item( sel_node_menu, KeyCommand.NODE_SELECT_PARENT,       _( "Parent Node" ) );
    append_menu_item( sel_node_menu, KeyCommand.NODE_SELECT_LINKED,       _( "Linked Node" ) );

    var sel_other_menu = new GLib.Menu();
    append_menu_item( sel_other_menu, KeyCommand.NODE_SELECT_CONNECTION, _( "Connection" ) );
    append_menu_item( sel_other_menu, KeyCommand.NODE_SELECT_CALLOUT,    _( "Callout" ) );

    var sel_submenu = new GLib.Menu();
    sel_submenu.append_section( null, sel_node_menu );
    sel_submenu.append_section( null, sel_other_menu );

    var sel_menu = new GLib.Menu();
    sel_menu.append_submenu( _( "Select" ), sel_submenu );
    append_menu_item( sel_menu, KeyCommand.NODE_CENTER, _( "Center Current Node" ) );

    var sort_submenu = new GLib.Menu();
    append_menu_item( sort_submenu, KeyCommand.NODE_SORT_ALPHABETICALLY, _( "Alphabetically" ) );
    append_menu_item( sort_submenu, KeyCommand.NODE_SORT_RANDOMLY,       _( "Randomly" ) );

    var sort_menu = new GLib.Menu();
    sort_menu.append_submenu( _( "Sort Children" ), sort_submenu );

    var detach_menu = new GLib.Menu();
    append_menu_item( detach_menu, KeyCommand.NODE_DETACH, _( "Detach" ) );

    menu.append_section( null, _edit_menu );
    menu.append_section( null, change_menu );
    menu.append_section( null, add_menu );
    menu.append_section( null, sel_menu );
    menu.append_section( null, sort_menu );
    menu.append_section( null, detach_menu );

  }

  //-------------------------------------------------------------
  // Returns true if the currently selected node is a task
  private bool node_is_task() {
    Node? current = map.get_current_node();
    return( (current != null) && current.task_enabled() );
  }

  //-------------------------------------------------------------
  // Returns true if the currently selected node task is marked
  // as done.
  private bool node_task_is_done() {
    Node? current = map.get_current_node();
    return( node_is_task() && current.task_done() );
  }

  //-------------------------------------------------------------
  // Returns true if a note is associated with the currently
  // selected node.
  private bool node_has_note() {
    Node? current = map.get_current_node();
    return( (current != null) && (current.note != "") );
  }

  //-------------------------------------------------------------
  // Returns true if an image is associated with the currently
  // selected node.
  private bool node_has_image() {
    Node? current = map.get_current_node();
    return( (current != null) && (current.image != null) );
  }

  //-------------------------------------------------------------
  // Returns true if an node link is associated with the currently
  // selected node.
  private bool node_has_link() {
    Node? current = map.get_current_node();
    return( (current != null) && (current.linked_node != null) );
  }

  //-------------------------------------------------------------
  // Returns true if a callout is associated with the currently
  // selected node.
  private bool node_has_callout() {
    return( map.model.node_has_callout() );
  }

  //-------------------------------------------------------------
  // Returns true if there is a currently selected node that is
  // foldable.
  private bool node_foldable() {
    Node? current = map.get_current_node();
    return( (current != null) && !current.is_leaf() );
  }

  //-------------------------------------------------------------
  // Returns true if there are two or more nodes in the map and
  // one is selected.
  private bool node_linkable() {
    Node? current = map.get_current_node();
    return( (current != null) && (!current.is_root() || (map.get_nodes().length > 1)) );
  }

  //-------------------------------------------------------------
  // Returns true if the currently selected node can have a parent
  // node added.
  private bool node_parentable() {
    Node? current = map.get_current_node();
    return( (current != null) && !current.is_root() );
  }

  //-------------------------------------------------------------
  // Returns true if the currently selected node has more than
  // one child node.
  private bool node_sortable() {
    Node? current = map.get_current_node();
    return( (current != null) && (current.children().length > 1) );
  }

  //-------------------------------------------------------------
  // Returns true if there is a currently selected node that is
  // currently folded.
  private bool node_is_folded() {
    Node? current = map.get_current_node();
    return( (current != null) && current.folded );
  }

  //-------------------------------------------------------------
  // Changes the menu item at the given position in the given Menu
  // to the new name.
  private void change_menu( GLib.Menu menu, int pos, string new_name, string action ) {
    menu.remove( pos );
    menu.insert( pos, new_name, action );
  }

  //-------------------------------------------------------------
  // Called when the menu is popped up.
  protected override void on_popup() {

    var current = map.get_current_node();

    // Set the menu item labels
    var task_lbl    = node_is_task()   ?
                      node_task_is_done() ? _( "Remove Task" ) :
                                            _( "Mark Task As Done" ) :
                                            _( "Add Task" );
    var link_lbl    = node_has_link()    ? _( "Remove Node Link" ) : _( "Add Node Link" );
    var fold_lbl    = node_is_folded()   ? _( "Unfold Children" )  : _( "Fold Children" );
    var callout_lbl = node_has_callout() ? _( "Remove Callout" ) : _( "Add Callout" );
    var img_lbl     = node_has_image()   ? _( "Remove Image" )   : _( "Add Image" );

    change_menu_item_label( _change_submenu, KeyCommand.NODE_CHANGE_TASK,          task_lbl );
    change_menu_item_label( _change_submenu, KeyCommand.NODE_CHANGE_IMAGE,         img_lbl );
    change_menu_item_label( _change_submenu, KeyCommand.NODE_TOGGLE_LINKS,         link_lbl );
    change_menu_item_label( _change_submenu, KeyCommand.NODE_TOGGLE_CALLOUT,       callout_lbl );
    change_menu_item_label( _change_submenu, KeyCommand.NODE_TOGGLE_FOLDS_SHALLOW, fold_lbl );

    // Set the paste and replace text
    if( MinderClipboard.node_pasteable() ) {
      change_menu_item_label( _edit_menu, KeyCommand.EDIT_PASTE,         _( "Paste Node As Child" ) );
      change_menu_item_label( _edit_menu, KeyCommand.NODE_PASTE_REPLACE, _( "Paste and Replace Node" ) );
    } else if( MinderClipboard.image_pasteable() ) {
      change_menu_item_label( _edit_menu, KeyCommand.EDIT_PASTE,         _( "Paste Image As Child Node" ) );
      change_menu_item_label( _edit_menu, KeyCommand.NODE_PASTE_REPLACE, _( "Paste and Replace Node Image" ) );
    } else if( MinderClipboard.text_pasteable() ) {
      change_menu_item_label( _edit_menu, KeyCommand.EDIT_PASTE,         _( "Paste Text As Child Node" ) );
      change_menu_item_label( _edit_menu, KeyCommand.NODE_PASTE_REPLACE, _( "Paste and Replace Node Text" ) );
    } else {
      change_menu_item_label( _edit_menu, KeyCommand.EDIT_PASTE,         _( "Paste" ) );
      change_menu_item_label( _edit_menu, KeyCommand.NODE_PASTE_REPLACE, _( "Paste and Replace Node" ) );
      set_enabled( KeyCommand.EDIT_PASTE, false );
      set_enabled( KeyCommand.NODE_PASTE_REPLACE, false );
    }

    var node_pasteable = MinderClipboard.node_pasteable();

    // Set the menu sensitivity
    set_enabled( KeyCommand.EDIT_CUT,                  map.editable );
    set_enabled( KeyCommand.EDIT_PASTE,                (node_pasteable && map.editable) );
    set_enabled( KeyCommand.NODE_PASTE_REPLACE,        (node_pasteable && map.editable) );
    set_enabled( KeyCommand.NODE_REMOVE,               map.editable );
    set_enabled( KeyCommand.NODE_REMOVE_ONLY,          map.editable );
    set_enabled( KeyCommand.EDIT_SELECTED,             map.editable );
    set_enabled( KeyCommand.EDIT_NOTE,                 map.editable );
    set_enabled( KeyCommand.NODE_CHANGE_TASK,          map.editable );
    set_enabled( KeyCommand.NODE_CHANGE_IMAGE,         map.editable );
    set_enabled( KeyCommand.NODE_ADD_CONNECTION,       (!map.model.connections.hide && map.editable) );
    set_enabled( KeyCommand.NODE_ADD_PARENT,           (node_parentable() && map.editable) );
    set_enabled( KeyCommand.NODE_ADD_GROUP,            map.editable );
    set_enabled( KeyCommand.NODE_ADD_ROOT,             map.editable );
    set_enabled( KeyCommand.NODE_ADD_CHILD,            map.editable );
    set_enabled( KeyCommand.NODE_QUICK_ENTRY_INSERT,   map.editable );
    set_enabled( KeyCommand.NODE_QUICK_ENTRY_REPLACE,  map.editable );
    set_enabled( KeyCommand.NODE_CHANGE_LINK_COLOR,    (!current.is_root() && map.editable) );
    set_enabled( KeyCommand.NODE_RANDOMIZE_LINK_COLOR, (!current.is_root() && map.editable) );
    set_enabled( KeyCommand.NODE_REPARENT_LINK_COLOR,  (!current.is_root() && !current.main_branch() && current.link_color_root && map.editable) );
    set_enabled( KeyCommand.NODE_TOGGLE_FOLDS_SHALLOW, (node_foldable() && map.editable) );
    set_enabled( KeyCommand.NODE_TOGGLE_SEQUENCE,      (map.model.sequences_togglable() && map.editable) );
    set_enabled( KeyCommand.NODE_TOGGLE_LINKS,         (node_linkable() && map.editable) );
    set_enabled( KeyCommand.NODE_TOGGLE_CALLOUT,       map.editable );
    set_enabled( KeyCommand.NODE_DETACH,               (map.model.detachable() && map.editable) );
    set_enabled( KeyCommand.NODE_SORT_ALPHABETICALLY,  (node_sortable() && map.editable) );
    set_enabled( KeyCommand.NODE_SORT_RANDOMLY,        (node_sortable() && map.editable) );
    set_enabled( KeyCommand.NODE_SELECT_ROOT,          map.root_selectable() );
    set_enabled( KeyCommand.NODE_SELECT_SIBLING_NEXT,  map.model.sibling_exists( current ) );
    set_enabled( KeyCommand.NODE_SELECT_SIBLING_PREV,  map.model.sibling_exists( current ) );
    set_enabled( KeyCommand.NODE_SELECT_CHILD,         map.children_selectable() );
    set_enabled( KeyCommand.NODE_SELECT_CHILDREN,      map.children_selectable() );
    set_enabled( KeyCommand.NODE_SELECT_PARENT,        map.parent_selectable() );
    set_enabled( KeyCommand.NODE_SELECT_LINKED,        node_has_link() );
    set_enabled( KeyCommand.NODE_SELECT_CALLOUT,       node_has_callout() );
    set_enabled( KeyCommand.NODE_SELECT_CONNECTION,    map.editable );
    set_enabled( KeyCommand.NODE_SELECT_CALLOUT,       map.editable );
    set_enabled( KeyCommand.REMOVE_STICKER_SELECTED,   ((current.sticker != null) && map.editable) );
    set_enabled( KeyCommand.NODE_ADD_SIBLING_AFTER,    (!current.is_summary() && map.editable) );

  }

  /*
  //-------------------------------------------------------------
  // Converts the current node into a summary node.
  private void action_convert_to_summary_node() {
    map.model.add_summary_node_from_current();
  }
  */

}
