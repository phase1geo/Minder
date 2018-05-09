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
  Gtk.MenuItem _fold;

  /* Default constructor */
  public DrawAreaMenu( DrawArea da ) {

    _da = da;

    _copy = new Gtk.MenuItem.with_label( _( "Copy" ) );
    _copy.activate.connect( copy_node );

    _cut = new Gtk.MenuItem.with_label( _( "Cut" ) );
    _cut.activate.connect( cut_node );

    _paste = new Gtk.MenuItem.with_label( _( "Paste" ) );
    _paste.activate.connect( paste_node );

    _delete = new Gtk.MenuItem.with_label( _( "Delete" ) );
    _delete.activate.connect( delete_node );

    _edit = new Gtk.MenuItem.with_label( _( "Edit..." ) );
    _edit.activate.connect( edit_node );

    _fold = new Gtk.MenuItem.with_label( _( "Fold Children" ) );
    _fold.activate.connect( fold_node );

    /* Add the menu items to the menu */
    add( _copy );
    add( _cut );
    add( _paste );
    add( _delete );
    add( new SeparatorMenuItem() );
    add( _edit );
    add( _fold );

    /* Make the menu visible */
    show_all();

    /* Make sure that we handle menu state when we are popped up */
    show.connect( on_popup );

  }

  /* Returns true if there is a currently selected node */
  private bool node_selected() {
    return( _da.get_current_node() != null );
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
    _fold.set_sensitive( node_foldable() );

    /* Set the menu item labels */
    _fold.label = node_is_folded() ? _( "Unfold Children" ) : _( "Fold Children" );

  }

  /* Copies the current node to the clipboard */
  private void copy_node() {
    _da.copy_node_to_clipboard();
  }

  /* Cuts the current node to the clipboard */
  private void cut_node() {
    _da.cut_node_to_clipboard();
  }

  /*
   Pastes the node stored in the clipboard as either a root node (if no
   node is currently selected) or attaches it to the currently selected
   node.
  */
  private void paste_node() {
    _da.paste_node_from_clipboard();
  }

  /* Deletes the current node */
  private void delete_node() {
    _da.delete_node();
  }

  /* Displays the sidebar to edit the node properties */
  private void edit_node() {
    _da.show_node_properties();
  }

  /* Fold the currently selected node */
  private void fold_node() {
    _da.change_current_fold( !node_is_folded() );
  }

}
