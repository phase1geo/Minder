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
  Gtk.MenuItem _replace;
  Gtk.MenuItem _delete;
  Gtk.MenuItem _delonly;
  Gtk.MenuItem _edit;
  Gtk.MenuItem _task;
  Gtk.MenuItem _note;
  Gtk.MenuItem _image;
  Gtk.MenuItem _sticker;
  Gtk.MenuItem _link;
  Gtk.MenuItem _conn;
  Gtk.MenuItem _group;
  Gtk.MenuItem _link_color;
  Gtk.MenuItem _parent_link_color;
  Gtk.MenuItem _fold;
  Gtk.MenuItem _detach;
  Gtk.MenuItem _root;
  Gtk.MenuItem _parent;
  Gtk.MenuItem _child;
  Gtk.MenuItem _sibling;
  Gtk.MenuItem _quick_insert;
  Gtk.MenuItem _quick_replace;
  Gtk.MenuItem _sortby;
  Gtk.MenuItem _selroot;
  Gtk.MenuItem _selnext;
  Gtk.MenuItem _selprev;
  Gtk.MenuItem _selchild;
  Gtk.MenuItem _selchildren;
  Gtk.MenuItem _seltree;
  Gtk.MenuItem _selparent;
  Gtk.MenuItem _selconn;
  Gtk.MenuItem _sellink;
  Gtk.MenuItem _center;

  /* Default constructor */
  public NodeMenu( DrawArea da, AccelGroup accel_group ) {

    _da = da;

    _copy = new Gtk.MenuItem();
    _copy.add( new Granite.AccelLabel( _( "Copy" ), "<Control>c" ) );
    _copy.activate.connect( copy );

    _cut = new Gtk.MenuItem();
    _cut.add( new Granite.AccelLabel( _( "Cut" ), "<Control>x" ) );
    _cut.activate.connect( cut );

    _paste = new Gtk.MenuItem();
    _paste.add( new Granite.AccelLabel( _( "Paste" ), "<Control>v" ) );
    _paste.activate.connect( paste );

    _replace = new Gtk.MenuItem();
    _replace.add( new Granite.AccelLabel( _( "Paste and Replace Node" ), "<Control><Shift>v" ) );
    _replace.activate.connect( replace );

    _delete = new Gtk.MenuItem();
    _delete.add( new Granite.AccelLabel( _( "Delete" ), "Delete" ) );
    _delete.activate.connect( delete_node );

    _delonly = new Gtk.MenuItem.with_label( _( "Delete Single Node" ) );
    _delonly.activate.connect( delete_node_only );

    var change = new Gtk.MenuItem.with_label( _( "Change Node" ) );
    var change_menu = new Gtk.Menu();
    change.set_submenu( change_menu );

    _edit = new Gtk.MenuItem();
    _edit.add( new Granite.AccelLabel( _( "Edit Text…" ), "e" ) );
    _edit.activate.connect( edit_node );

    _note = new Gtk.MenuItem();
    _note.add( new Granite.AccelLabel( _( "Edit Note" ), "<Shift>e" ) );
    _note.activate.connect( edit_note );

    _task = new Gtk.MenuItem();
    _task.add( new Granite.AccelLabel( _( "Add Task" ), "t" ) );
    _task.activate.connect( change_task );

    _image = new Gtk.MenuItem.with_label( _( "Add Image" ) );
    _image.activate.connect( change_image );

    _sticker = new Gtk.MenuItem.with_label( _( "Remove Sticker" ) );
    _sticker.activate.connect( remove_sticker );

    _link = new Gtk.MenuItem();
    _link.add( new Granite.AccelLabel( _( "Add Node Link" ), "y" ) );
    _link.activate.connect( change_link );

    _conn = new Gtk.MenuItem();
    _conn.add( new Granite.AccelLabel( _( "Add Connection" ), "x" ) );
    _conn.activate.connect( add_connection );

    _group = new Gtk.MenuItem();
    _group.add( new Granite.AccelLabel( _( "Add Group" ), "g" ) );
    _group.activate.connect( add_group );

    _link_color = new Gtk.MenuItem.with_label( _( "Link Color" ) );
    var link_color_menu = new Gtk.Menu();
    _link_color.set_submenu( link_color_menu );

    var set_link_color = new Gtk.MenuItem.with_label( _( "Set to color…" ) );
    set_link_color.activate.connect( change_link_color );

    var rand_link_color = new Gtk.MenuItem.with_label( _( "Randomize color" ) );
    rand_link_color.activate.connect( randomize_link_color );

    _parent_link_color = new Gtk.MenuItem.with_label( _( "Use parent color" ) );
    _parent_link_color.activate.connect( reparent_link_color );

    _fold = new Gtk.MenuItem();
    _fold.add( new Granite.AccelLabel( _( "Fold Children" ), "f" ) );
    _fold.activate.connect( fold_node );

    _detach = new Gtk.MenuItem.with_label( _( "Detach" ) );
    _detach.activate.connect( detach_node );

    var addnode = new Gtk.MenuItem.with_label( _( "Add Node" ) );
    var addmenu = new Gtk.Menu();
    addnode.set_submenu( addmenu );

    _root = new Gtk.MenuItem.with_label( _( "Add Root Node" ) );
    _root.activate.connect( add_root_node );

    _parent = new Gtk.MenuItem.with_label( _( "Add Parent Node" ) );
    _parent.activate.connect( add_parent_node );

    _child = new Gtk.MenuItem();
    _child.add( new Granite.AccelLabel( _( "Add Child Node" ), "Tab" ) );
    _child.activate.connect( add_child_node );

    _sibling = new Gtk.MenuItem();
    _sibling.add( new Granite.AccelLabel( _( "Add Sibling Node" ), "Return" ) );
    _sibling.activate.connect( add_sibling_node );

    var quick_menu = new Gtk.Menu();
    var quick = new Gtk.MenuItem.with_label( _( "Quick Entry" ) );
    quick.set_submenu( quick_menu );

    _quick_insert = new Gtk.MenuItem();
    _quick_insert.add( new Granite.AccelLabel( _( "Insert Nodes" ), "<Control><Shift>e" ) );
    _quick_insert.activate.connect( quick_entry_insert );

    _quick_replace = new Gtk.MenuItem();
    _quick_replace.add( new Granite.AccelLabel( _( "Replace Nodes" ), "<Control><Shift>r" ) );
    _quick_replace.activate.connect( quick_entry_replace );
    // Utils.add_accel_label( _quick_replace, 'r', (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK) );

    var selnode = new Gtk.MenuItem.with_label( _( "Select" ) );
    var selmenu = new Gtk.Menu();
    selnode.set_submenu( selmenu );

    _selroot = new Gtk.MenuItem();
    _selroot.add( new Granite.AccelLabel( _( "Root Node" ), "m" ) );
    _selroot.activate.connect( select_root_node );
    // Utils.add_accel_label( _selroot, 'm', 0 );

    _selnext = new Gtk.MenuItem();
    _selnext.add( new Granite.AccelLabel( _( "Next Sibling Node" ), "n" ) );
    _selnext.activate.connect( select_next_sibling_node );
    // Utils.add_accel_label( _selnext, 'n', 0 );

    _selprev = new Gtk.MenuItem();
    _selprev.add( new Granite.AccelLabel( _( "Previous Sibling Node" ), "p" ) );
    _selprev.activate.connect( select_previous_sibling_node );
    // Utils.add_accel_label( _selprev, 'p', 0 );

    _selchild = new Gtk.MenuItem();
    _selchild.add( new Granite.AccelLabel( _( "Child Node" ), "c" ) );
    _selchild.activate.connect( select_child_node );
    // Utils.add_accel_label( _selchild, 'c', 0 );

    _selchildren = new Gtk.MenuItem();
    _selchildren.add( new Granite.AccelLabel( _( "Child Nodes" ), "d" ) );
    _selchildren.activate.connect( select_child_nodes );
    // Utils.add_accel_label( _selchildren, 'd', 0 );

    _seltree = new Gtk.MenuItem();
    _seltree.add( new Granite.AccelLabel( _( "Subtree" ), "<Shift>d" ) );
    _seltree.activate.connect( select_node_tree );
    // Utils.add_accel_label( _seltree, 'd', Gdk.ModifierType.SHIFT_MASK );

    _selparent = new Gtk.MenuItem();
    _selparent.add( new Granite.AccelLabel( _( "Parent Node" ), "a" ) );
    _selparent.activate.connect( select_parent_nodes );
    // Utils.add_accel_label( _selparent, 'a', 0 );

    _sellink = new Gtk.MenuItem();
    _sellink.add( new Granite.AccelLabel( _( "Linked Node" ), "<Shift>y" ) );
    _sellink.activate.connect( select_linked_node );
    // Utils.add_accel_label( _sellink, 'Y', Gdk.ModifierType.SHIFT_MASK );

    _selconn = new Gtk.MenuItem();
    _selconn.add( new Granite.AccelLabel( _( "Connection" ), "<Shift>x" ) );
    _selconn.activate.connect( select_connection );
    // Utils.add_accel_label( _selconn, 'X', Gdk.ModifierType.SHIFT_MASK );

    _center = new Gtk.MenuItem();
    _center.add( new Granite.AccelLabel( _( "Center Current Node" ), "<Shift>c" ) );
    _center.activate.connect( center_current_node );
    // Utils.add_accel_label( _center, 'C', Gdk.ModifierType.SHIFT_MASK );

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
    add( _replace );
    add( _delete );
    add( _delonly );
    add( new SeparatorMenuItem() );
    add( change );
    /*
    add( _edit );
    add( _note );
    add( _task );
    add( _image );
    add( _sticker );
    add( _link );
    add( _conn );
    add( _group );
    add( _link_color );
    add( _fold );
    */
    add( new SeparatorMenuItem() );
    add( addnode );
    add( quick );
    add( new SeparatorMenuItem() );
    add( selnode );
    add( _center );
    add( new SeparatorMenuItem() );
    add( _sortby );
    add( new SeparatorMenuItem() );
    add( _detach );

    /* Add the items to the change node menu */
    change_menu.add( _edit );
    change_menu.add( _note );
    change_menu.add( _task );
    change_menu.add( _image );
    change_menu.add( _sticker );
    change_menu.add( _link );
    change_menu.add( _conn );
    change_menu.add( _group );
    change_menu.add( _link_color );
    change_menu.add( _fold );

    /* Add the items to the add node menu */
    addmenu.add( _root );
    addmenu.add( _parent );
    addmenu.add( _child );
    addmenu.add( _sibling );

    /* Add the items to the sort menu */
    sortmenu.add( sort_alpha );
    sortmenu.add( sort_rand );

    /* Add the items to the selection menu */
    selmenu.add( _selroot );
    selmenu.add( _selnext );
    selmenu.add( _selprev );
    selmenu.add( _selchild );
    selmenu.add( _selchildren );
    selmenu.add( _seltree );
    selmenu.add( _selparent );
    selmenu.add( _sellink );
    selmenu.add( new SeparatorMenuItem() );
    selmenu.add( _selconn );

    /* Add the items to the link color menu */
    link_color_menu.add( set_link_color );
    link_color_menu.add( rand_link_color );
    link_color_menu.add( _parent_link_color );

    /* Add the items to the quick entry menu */
    quick_menu.add( _quick_insert );
    quick_menu.add( _quick_replace );

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
    _paste.set_sensitive( true );
    _replace.set_sensitive( true );
    _conn.set_sensitive( !_da.get_connections().hide );
    _parent.set_sensitive( node_parentable() );
    _link_color.set_sensitive( !current.is_root() );
    _parent_link_color.set_sensitive( !current.main_branch() && current.link_color_root );
    _fold.set_sensitive( node_foldable() );
    _link.set_sensitive( node_linkable() );
    _detach.set_sensitive( _da.detachable() );
    _sortby.set_sensitive( node_sortable() );
    _selroot.set_sensitive( _da.root_selectable() );
    _selnext.set_sensitive( _da.sibling_selectable() );
    _selprev.set_sensitive( _da.sibling_selectable() );
    _selchild.set_sensitive( _da.children_selectable() );
    _selparent.set_sensitive( _da.parent_selectable() );
    _sellink.set_sensitive( node_has_link() );
    _sticker.set_sensitive( current.sticker != null );

    /* Set the menu item labels */
    var task_lbl = node_is_task()   ?
                   node_task_is_done() ? _( "Remove Task" ) :
                                         _( "Mark Task As Done" ) :
                                         _( "Add Task" );
    var link_lbl = node_has_link()  ? _( "Remove Node Link" ) : _( "Add Node Link" );
    var fold_lbl = node_is_folded() ? _( "Unfold Children" )  : _( "Fold Children" );
    var task_acc = (Granite.AccelLabel)_task.get_child();
    var link_acc = (Granite.AccelLabel)_link.get_child();
    var fold_acc = (Granite.AccelLabel)_fold.get_child();

    _task.get_child().destroy();
    _task.add( new Granite.AccelLabel( task_lbl, task_acc.accel_string ) );
    _link.get_child().destroy();
    _link.add( new Granite.AccelLabel( link_lbl, link_acc.accel_string ) );
    _fold.get_child().destroy();
    _fold.add( new Granite.AccelLabel( fold_lbl, fold_acc.accel_string ) );

    _image.label = node_has_image() ? _( "Remove Image" ) : _( "Add Image" );

    /* Set the paste and replace text */
    var clipboard = Clipboard.get_default( get_display() );
    if( clipboard.wait_is_text_available() ) {
      _paste.label   = _( "Paste Text As Child Node" );
      _replace.label = _( "Paste and Replace Node Text" );
    } else if( clipboard.wait_is_image_available() ) {
      _paste.label   = _( "Paste Image As Child Node" );
      _replace.label = _( "Paste and Replace Node Image" );
    } else if( _da.node_pasteable() ) {
      _paste.label   = _( "Paste Node As Child" );
      _replace.label = _( "Paste and Replace Node" );
    } else {
      _paste.set_sensitive( false );
      _replace.set_sensitive( false );
    }

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
    _da.do_paste( false );
  }

  /*
   Replaces the node's text, image or entire node with the contents stored
   in the clipboard.
  */
  private void replace() {
    _da.do_paste( true );
  }

  /* Deletes the current node */
  private void delete_node() {
    _da.delete_node();
  }

  /* Deletes just the node that is selected */
  private void delete_node_only() {
    _da.delete_nodes();
  }

  /* Displays the sidebar to edit the node properties */
  private void edit_node() {
    _da.show_properties( "current", PropertyGrab.FIRST );
  }

  /* Changes the task status of the currently selected node */
  private void change_task() {
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
  private void edit_note() {
    _da.show_properties( "current", PropertyGrab.NOTE );
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

  /* Removes the sticker from the node */
  private void remove_sticker() {
    var current = _da.get_current_node();
    _da.undo_buffer.add_item( new UndoNodeStickerRemove( current ) );
    current.sticker = null;
    _da.queue_draw();
    _da.auto_save();
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

  private void add_group() {
    _da.add_group();
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

  /* Show the quick entry insert window */
  private void quick_entry_insert() {
    _da.handle_control_E();
  }

  /* Show the quick entry replace window */
  private void quick_entry_replace() {
    _da.handle_control_R();
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

  /* Selects all of the child nodes of the current node */
  private void select_child_nodes() {
    _da.select_child_nodes();
  }

  /* Selects all of the descendant nodes of the current node */
  private void select_node_tree() {
    _da.select_node_tree();
  }

  /* Selects the parent node of the current node */
  private void select_parent_nodes() {
    _da.select_parent_nodes();
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

  private void change_link_color() {
    var color_picker = new ColorChooserDialog( _( "Select a link color" ), _da.win );
    if( color_picker.run() == ResponseType.OK ) {
      _da.change_current_link_color( color_picker.get_rgba() );
    }
    color_picker.close();
  }

  private void randomize_link_color() {
    _da.randomize_current_link_color();
  }

  private void reparent_link_color() {
    _da.reparent_current_link_color();
  }

}
