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

public class NodeMenu : Gtk.Menu {

  DrawArea     _da;
  Gtk.MenuItem _copy;
  Gtk.MenuItem _cut;
  Gtk.MenuItem _paste;
  Gtk.MenuItem _delete;
  Gtk.MenuItem _edit;
  Gtk.MenuItem _task;
  Gtk.MenuItem _note;
  Gtk.MenuItem _image;
  Gtk.MenuItem _link;
  Gtk.MenuItem _conn;
  Gtk.MenuItem _fold;
  Gtk.MenuItem _detach;
  Gtk.MenuItem _root;
  Gtk.MenuItem _parent;
  Gtk.MenuItem _child;
  Gtk.MenuItem _sibling;
  Gtk.MenuItem _sortby;
  Gtk.MenuItem _selroot;
  Gtk.MenuItem _selnext;
  Gtk.MenuItem _selprev;
  Gtk.MenuItem _selchild;
  Gtk.MenuItem _selparent;
  Gtk.MenuItem _selconn;
  Gtk.MenuItem _sellink;
  Gtk.MenuItem _center;

  /* Default constructor */
  public NodeMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    _copy = new Gtk.MenuItem.with_label( _( "Copy" ) );
    _copy.activate.connect( copy );
    Utils.add_accel_label( _copy, 'c', Gdk.ModifierType.CONTROL_MASK );

    _cut = new Gtk.MenuItem.with_label( _( "Cut" ) );
    _cut.activate.connect( cut );
    Utils.add_accel_label( _cut, 'x', Gdk.ModifierType.CONTROL_MASK );

    _paste = new Gtk.MenuItem.with_label( _( "Paste" ) );
    _paste.activate.connect( paste );
    Utils.add_accel_label( _paste, 'v', Gdk.ModifierType.CONTROL_MASK );

    _delete = new Gtk.MenuItem.with_label( _( "Delete" ) );
    _delete.activate.connect( delete_node );
    Utils.add_accel_label( _delete, 65535, 0 );

    _edit = new Gtk.MenuItem.with_label( _( "Edit…" ) );
    _edit.activate.connect( edit_node );
    Utils.add_accel_label( _edit, 'e', 0 );

    _task = new Gtk.MenuItem.with_label( _( "Add Task" ) );
    _task.activate.connect( change_task );

    _note = new Gtk.MenuItem.with_label( _( "Add Note" ) );
    _note.activate.connect( change_note );

    _image = new Gtk.MenuItem.with_label( _( "Add Image" ) );
    _image.activate.connect( change_image );

    _link = new Gtk.MenuItem.with_label( _( "Add Node Link" ) );
    _link.activate.connect( change_link );

    _conn = new Gtk.MenuItem.with_label( _( "Add Connection" ) );
    _conn.activate.connect( add_connection );
    Utils.add_accel_label( _conn, 'x', 0 );

    _fold = new Gtk.MenuItem.with_label( _( "Fold Children" ) );
    _fold.activate.connect( fold_node );
    Utils.add_accel_label( _fold, 'f', 0 );

    _detach = new Gtk.MenuItem.with_label( _( "Detach" ) );
    _detach.activate.connect( detach_node );

    _root = new Gtk.MenuItem.with_label( _( "Add Root Node" ) );
    _root.activate.connect( add_root_node );

    _parent = new Gtk.MenuItem.with_label( _( "Add Parent Node" ) );
    _parent.activate.connect( add_parent_node );

    _child = new Gtk.MenuItem.with_label( _( "Add Child Node" ) );
    _child.activate.connect( add_child_node );
    Utils.add_accel_label( _child, 65289, 0 );

    _sibling = new Gtk.MenuItem.with_label( _( "Add Sibling Node" ) );
    _sibling.activate.connect( add_sibling_node );
    Utils.add_accel_label( _sibling, 65293, 0 );

    var selnode = new Gtk.MenuItem.with_label( _( "Select" ) );
    var selmenu = new Gtk.Menu();
    selnode.set_submenu( selmenu );

    _selroot = new Gtk.MenuItem.with_label( _( "Root Node" ) );
    _selroot.activate.connect( select_root_node );
    Utils.add_accel_label( _selroot, 'm', 0 );

    _selnext = new Gtk.MenuItem.with_label( _( "Next Sibling Node" ) );
    _selnext.activate.connect( select_next_sibling_node );
    Utils.add_accel_label( _selnext, 'n', 0 );

    _selprev = new Gtk.MenuItem.with_label( _( "Previous Sibling Node" ) );
    _selprev.activate.connect( select_previous_sibling_node );
    Utils.add_accel_label( _selprev, 'p', 0 );

    _selchild = new Gtk.MenuItem.with_label( _( "Child Node" ) );
    _selchild.activate.connect( select_child_node );
    Utils.add_accel_label( _selchild, 'c', 0 );

    _selparent = new Gtk.MenuItem.with_label( _( "Parent Node" ) );
    _selparent.activate.connect( select_parent_node );
    Utils.add_accel_label( _selparent, 'a', 0 );

    _sellink = new Gtk.MenuItem.with_label( _( "Linked Node" ) );
    _sellink.activate.connect( select_linked_node );
    Utils.add_accel_label( _sellink, 'Y', Gdk.ModifierType.SHIFT_MASK );

    _selconn = new Gtk.MenuItem.with_label( _( "Connection" ) );
    _selconn.activate.connect( select_connection );
    Utils.add_accel_label( _selconn, 'X', Gdk.ModifierType.SHIFT_MASK );

    _center = new Gtk.MenuItem.with_label( _( "Center Current Node" ) );
    _center.activate.connect( center_current_node );
    Utils.add_accel_label( _center, 'C', Gdk.ModifierType.SHIFT_MASK );

    _sortby = new Gtk.MenuItem.with_label( _( "Sort Children" ) );
    var sortmenu = new Gtk.Menu();
    _sortby.set_submenu( sortmenu );

    var sort_alpha = new Gtk.MenuItem.with_label( _( "Alphabetically" ) );
    sort_alpha.activate.connect( sort_alphabetically );

    var sort_rand = new Gtk.MenuItem.with_label( _( "Randomize" ) );
    sort_rand.activate.connect( sort_randomly );

    /* Add the menu items to the menu */
    add( _copy );
    add( _cut );
    add( _paste );
    add( _delete );
    add( new SeparatorMenuItem() );
    add( _edit );
    add( _task );
    add( _note );
    add( _image );
    add( _link );
    add( _conn );
    add( _fold );
    add( new SeparatorMenuItem() );
    add( _root );
    add( _parent );
    add( _child );
    add( _sibling );
    add( new SeparatorMenuItem() );
    add( selnode );
    add( _center );
    add( new SeparatorMenuItem() );
    add( _sortby );
    add( new SeparatorMenuItem() );
    add( _detach );

    /* Add the items to the sort menu */
    sortmenu.add( sort_alpha );
    sortmenu.add( sort_rand );

    /* Add the items to the selection menu */
    selmenu.add( _selroot );
    selmenu.add( _selnext );
    selmenu.add( _selprev );
    selmenu.add( _selchild );
    selmenu.add( _selparent );
    selmenu.add( _sellink );
    selmenu.add( new SeparatorMenuItem() );
    selmenu.add( _selconn );

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  /* Returns true if the currently selected node is a task */
  private bool node_is_task() {
    Node? current = _da.get_current_node();
    return( (current != null) && current.task_enabled() );
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

    /* Set the menu sensitivity */
    _paste.set_sensitive( _da.node_pasteable() );
    _conn.set_sensitive( !_da.get_connections().hide );
    _parent.set_sensitive( node_parentable() );
    _fold.set_sensitive( node_foldable() );
    _link.set_sensitive( node_linkable() );
    _detach.set_sensitive( _da.detachable() );
    _sortby.set_sensitive( node_sortable() );
    _selroot.set_sensitive( _da.root_selectable() );
    _selnext.set_sensitive( _da.sibling_selectable() );
    _selprev.set_sensitive( _da.sibling_selectable() );
    _selchild.set_sensitive( _da.child_selectable() );
    _selparent.set_sensitive( _da.parent_selectable() );
    _sellink.set_sensitive( node_has_link() );

    /* Set the menu item labels */
    _task.label  = node_is_task()   ? _( "Remove Task" )      : _( "Add Task" );
    _note.label  = node_has_note()  ? _( "Remove Note" )      : _( "Add Note" );
    _image.label = node_has_image() ? _( "Remove Image" )     : _( "Add Image" );
    _link.label  = node_has_link()  ? _( "Remove Node Link" ) : _( "Add Node Link" );
    _fold.label  = node_is_folded() ? _( "Unfold Children" )  : _( "Fold Children" );

  }

  /* Copies the current node to the clipboard */
  private void copy() {
    _da.do_copy();
  }

  /* Cuts the current node to the clipboard */
  private void cut() {
    _da.do_cut();
  }

  /*
   Pastes the node stored in the clipboard as either a root node (if no
   node is currently selected) or attaches it to the currently selected
   node.
  */
  private void paste() {
    _da.do_paste();
  }

  /* Deletes the current node */
  private void delete_node() {
    _da.delete_node();
  }

  /* Displays the sidebar to edit the node properties */
  private void edit_node() {
    _da.show_properties( "current", false );
  }

  /* Changes the task status of the currently selected node */
  private void change_task() {
    if( node_is_task() ) {
      _da.change_current_task( false, false );
    } else {
      _da.change_current_task( true, false );
    }
    _da.current_changed( _da );
  }

  /* Changes the note status of the currently selected node */
  private void change_note() {
    if( node_has_note() ) {
      _da.change_current_node_note( "" );
    } else {
      _da.show_properties( "current", true );
    }
    _da.current_changed( _da );
  }

  /* Changes the image of the currently selected node */
  private void change_image() {
    if( node_has_image() ) {
      _da.delete_current_image();
    } else {
      _da.add_current_image();
    }
    _da.current_changed( _da );
  }

  /* Changes the node link of the currently selected node */
  private void change_link() {
    if( node_has_link() ) {
      _da.delete_current_link();
    } else {
      _da.start_connection( false, true );
    }
  }

  /* Changes the connection of the currently selected node */
  private void add_connection() {
    _da.start_connection( false, false );
  }

  /* Fold the currently selected node */
  private void fold_node() {
    _da.change_current_fold( !node_is_folded() );
    _da.current_changed( _da );
  }

  /* Creates a new root node */
  private void add_root_node() {
    _da.add_root_node();
  }

  /* Creates a new parent node for the current node */
  private void add_parent_node() {
    _da.add_parent_node();
  }

  /* Creates a new child node from the current node */
  private void add_child_node() {
    _da.add_child_node();
  }

  /* Creates a sibling node of the current node */
  private void add_sibling_node() {
    _da.add_sibling_node();
  }

  /* Detaches the currently selected node and make it a root node */
  private void detach_node() {
    _da.detach();
  }

  /* Selects the current root node */
  private void select_root_node() {
    _da.select_root_node();
  }

  /* Selects the next sibling node of the current node */
  private void select_next_sibling_node() {
    _da.select_sibling_node( 1 );
  }

  /* Selects the previous sibling node of the current node */
  private void select_previous_sibling_node() {
    _da.select_sibling_node( -1 );
  }

  /* Selects the first child node of the current node */
  private void select_child_node() {
    _da.select_child_node();
  }

  /* Selects the parent node of the current node */
  private void select_parent_node() {
    _da.select_parent_node();
  }

  /* Selects the node the current node is linked to */
  private void select_linked_node() {
    _da.select_linked_node();
  }

  /* Selects the one of the connections attached to the current node */
  private void select_connection() {
    _da.select_attached_connection();
  }

  /* Centers the current node */
  private void center_current_node() {
    _da.center_current_node();
  }

  private void sort_alphabetically() {
    _da.sort_alphabetically();
  }

  private void sort_randomly() {
    _da.sort_randomly();
  }

}
