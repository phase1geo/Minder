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

public class DrawAreaMenu : Gtk.Menu {

  DrawArea     _da;
  Gtk.MenuItem _copy;
  Gtk.MenuItem _cut;
  Gtk.MenuItem _paste;
  Gtk.MenuItem _delete;
  Gtk.MenuItem _edit;
  Gtk.MenuItem _task;
  Gtk.MenuItem _note;
  Gtk.MenuItem _fold;
  Gtk.MenuItem _detach;
  Gtk.MenuItem _root;
  Gtk.MenuItem _child;
  Gtk.MenuItem _sibling;

  /* Default constructor */
  public DrawAreaMenu( DrawArea da ) {

    _da = da;

    // var accel_group = new AccelGroup();
    // _da.add_accel_group( accel_group );

    _copy = new Gtk.MenuItem.with_label( _( "Copy" ) );
    _copy.activate.connect( copy );
    // _copy.add_accelerator( "activate", accel_group, ord( "c" ), gdk.CONTROL_MASK, ACCEL_VISIBLE );
    add_accel_label( _copy.get_child(), "<Control>c" );

    _cut = new Gtk.MenuItem.with_label( _( "Cut" ) );
    _cut.activate.connect( cut );
    add_accel_label( _cut.get_child(), "<Control>x" );

    _paste = new Gtk.MenuItem.with_label( _( "Paste" ) );
    _paste.activate.connect( paste );
    add_accel_label( _paste.get_child(), "<Control>v" );

    _delete = new Gtk.MenuItem.with_label( _( "Delete" ) );
    _delete.activate.connect( delete_node );
    add_accel_label( _delete.get_child(), "<Delete>" ) );

    _edit = new Gtk.MenuItem.with_label( _( "Edit..." ) );
    _edit.activate.connect( edit_node );
    add_accel_label( _edit.get_child(), "e" ) );

    _task = new Gtk.MenuItem.with_label( _( "Add Task" ) );
    _task.activate.connect( change_task );
    add_accel_label( _task.get_child(), "t" ) );

    _note = new Gtk.MenuItem.with_label( _( "Add Note" ) );
    _note.activate.connect( change_note );

    _fold = new Gtk.MenuItem.with_label( _( "Fold Children" ) );
    _fold.activate.connect( fold_node );
    add_accel_label( _fold.get_child(), "f" );

    _detach = new Gtk.MenuItem.with_label( _( "Detach" ) );
    _detach.activate.connect( detach_node );
    add_accel_label( _detach.get_child(), "d" );

    _root = new Gtk.MenuItem.with_label( _( "Add Root Node" ) );
    _root.activate.connect( add_root_node );

    _child = new Gtk.MenuItem.with_label( _( "Add Child Node" ) );
    _child.activate.connect( add_child_node );
    add_accel_label( _child.get_child(), "<Tab>" );

    _sibling = new Gtk.MenuItem.with_label( _( "Add Sibling Node" ) );
    _sibling.activate.connect( add_sibling_node );
    add_accel_label( _sibling.get_child(), "<Return>" );

    /* Add the menu items to the menu */
    add( _copy );
    add( _cut );
    add( _paste );
    add( _delete );
    add( new SeparatorMenuItem() );
    add( _edit );
    add( _task );
    add( _note );
    add( _fold );
    add( new SeparatorMenuItem() );
    add( _root );
    add( _child );
    add( _sibling );
    add( new SeparatorMenuItem() );
    add( _detach );

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  private void add_accel_label( Gtk.Widget widget, string accelerator ) {

    /* Convert the menu item to an accelerator label */
    AccelLabel? label = widget as AccelLabel;
    if( label == null ) return;

    /* Parse the accelerator */
    uint             key  = 0;
    Gdk.ModifierType mods = 0;
    accelerator_parse( accelerator, out key, out mods );

    /* Add the accelerator to the label */
    label.set_accel( key, mods );
    label.refetch();

  }

  /* Returns true if there is a currently selected node */
  private bool node_selected() {
    return( _da.get_current_node() != null );
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

  /* Returns true if there is a currently selected node that is foldable */
  private bool node_foldable() {
    Node? current = _da.get_current_node();
    return( (current != null) && !current.is_leaf() );
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
    _copy.set_sensitive( _da.node_copyable() );
    _cut.set_sensitive( _da.node_cuttable() );
    _paste.set_sensitive( _da.node_pasteable() );
    _delete.set_sensitive( _da.node_deleteable() );
    _edit.set_sensitive( node_selected() );
    _task.set_sensitive( node_selected() );
    _note.set_sensitive( node_selected() );
    _fold.set_sensitive( node_foldable() );
    _child.set_sensitive( node_selected() );
    _sibling.set_sensitive( node_selected() );
    _detach.set_sensitive( _da.detachable() );

    /* Set the menu item labels */
    _task.label = node_is_task()   ? _( "Remove Task" )     : _( "Add Task" );
    _note.label = node_has_note()  ? _( "Remove Note" )     : _( "Add Note" );
    _fold.label = node_is_folded() ? _( "Unfold Children" ) : _( "Fold Children" );

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
    _da.show_properties( "node" );
  }

  /* Changes the task status of the currently selected node */
  private void change_task() {
    if( node_is_task() ) {
      _da.change_current_task( false, false );
    } else {
      _da.change_current_task( true, false );
    }
    _da.node_changed();
  }

  /* Changes the note status of the currently selected node */
  private void change_note() {
    if( node_has_note() ) {
      _da.change_current_note( "" );
    } else {
      _da.show_properties( "node" );
    }
    _da.node_changed();
  }

  /* Fold the currently selected node */
  private void fold_node() {
    _da.change_current_fold( !node_is_folded() );
    _da.node_changed();
  }

  /* Creates a new root node */
  private void add_root_node() {
    _da.add_root_node();
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

}
