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

public class NodesMenu : BaseMenu {

  //-------------------------------------------------------------
  // Default constructor.
  public NodesMenu( Gtk.Application app, DrawArea da ) {

    base( app, da, "nodes" );

    var edit_menu = new GLib.Menu();
    append_menu_item( edit_menu, KeyCommand.EDIT_COPY,   _( "Copy" ) );
    append_menu_item( edit_menu, KeyCommand.EDIT_CUT,    _( "Cut" ) );
    append_menu_item( edit_menu, KeyCommand.NODE_REMOVE, _( "Delete" ) );

    var color_menu = new GLib.Menu();
    append_menu_item( color_menu, KeyCommand.NODE_CHANGE_LINK_COLOR,    _( "Set To Color…" ) );
    append_menu_item( color_menu, KeyCommand.NODE_RANDOMIZE_LINK_COLOR, _( "Randomize Colors" ) );
    append_menu_item( color_menu, KeyCommand.NODE_REPARENT_LINK_COLOR,  _( "Use Parent Color" ) );

    var change_menu = new GLib.Menu();
    change_menu.append_submenu( _( "Link Colors" ), color_menu );
    append_menu_item( change_menu, KeyCommand.NODE_CHANGE_TASK,          _( "Toggle Tasks" ) );
    append_menu_item( change_menu, KeyCommand.NODE_TOGGLE_FOLDS_SHALLOW, _( "Toggle Folds" ) );
    append_menu_item( change_menu, KeyCommand.NODE_TOGGLE_SEQUENCE,      _( "Toggle Sequences" ) );

    var link_menu = new GLib.Menu();
    append_menu_item( link_menu, KeyCommand.NODE_ADD_CONNECTION, _( "Connect" ) );
    append_menu_item( link_menu, KeyCommand.NODE_TOGGLE_LINKS,   _( "Link Nodes" ) );
    // link_menu.append( _( "Add Summary Node" ), "nodes.action_summarize" );

    var sel_submenu = new GLib.Menu();
    append_menu_item( sel_submenu, KeyCommand.NODE_SELECT_PARENT,   _( "Parent Nodes" ) );
    append_menu_item( sel_submenu, KeyCommand.NODE_SELECT_CHILDREN, _( "Child Nodes" ) );

    var sel_menu = new GLib.Menu();
    sel_menu.append_submenu( _( "Select" ), sel_submenu );

    var align_vert_menu = new GLib.Menu();
    append_menu_item( align_vert_menu, KeyCommand.NODE_ALIGN_TOP,     _( "Align Top" ) );
    append_menu_item( align_vert_menu, KeyCommand.NODE_ALIGN_HCENTER, _( "Align Center Horizontally" ) );
    append_menu_item( align_vert_menu, KeyCommand.NODE_ALIGN_BOTTOM,  _( "Align Bottom" ) );

    var align_horz_menu = new GLib.Menu();
    append_menu_item( align_horz_menu, KeyCommand.NODE_ALIGN_LEFT,    _( "Align Left" ) );
    append_menu_item( align_horz_menu, KeyCommand.NODE_ALIGN_VCENTER, _( "Align Center Vertically" ) );
    append_menu_item( align_horz_menu, KeyCommand.NODE_ALIGN_RIGHT,   _( "Align Right" ) );

    var align_submenu = new GLib.Menu();
    align_submenu.append_section( null, align_vert_menu );
    align_submenu.append_section( null, align_horz_menu );

    var align_menu = new GLib.Menu();
    align_menu.append_submenu( _( "Align" ), align_submenu );

    menu.append_section( null, edit_menu );
    menu.append_section( null, change_menu );
    menu.append_section( null, link_menu );
    menu.append_section( null, sel_menu );
    menu.append_section( null, align_menu );

  }

  //-------------------------------------------------------------
  // Returns true if there is a currently selected node that is
  // foldable.
  private void nodes_foldable_status( out bool foldable, out bool unfoldable ) {
    foldable = unfoldable = false;
    var nodes = map.get_selected_nodes();
    for( int i=0; i<nodes.length; i++ ) {
      if( !nodes.index( i ).is_leaf() ) {
        foldable   |= !nodes.index( i ).folded;
        unfoldable |=  nodes.index( i ).folded;
      }
    }
  }

  //-------------------------------------------------------------
  // Returns true if at least one selected node has its
  // local_link_color indicator set.
  private bool link_colors_parentable() {
    var nodes = map.get_selected_nodes();
    for( int i=0; i<nodes.length; i++ ) {
      if( nodes.index( i ).link_color_root ) {
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Called when the menu is popped up.
  protected override void on_popup() {

    var nodes        = map.get_selected_nodes();
    var node_num     = nodes.length;
    var summarizable = map.model.nodes_summarizable();
    var alignable    = map.model.nodes_alignable();

    bool foldable, unfoldable;
    nodes_foldable_status( out foldable, out unfoldable );

    // Set the menu sensitivity
    set_enabled( KeyCommand.EDIT_CUT,                  map.editable );
    set_enabled( KeyCommand.NODE_REMOVE,               map.editable );
    set_enabled( KeyCommand.NODE_CHANGE_LINK_COLOR,    map.editable );
    set_enabled( KeyCommand.NODE_RANDOMIZE_LINK_COLOR, map.editable );
    set_enabled( KeyCommand.NODE_REPARENT_LINK_COLOR,  map.editable );
    set_enabled( KeyCommand.NODE_CHANGE_TASK,          map.editable );
    set_enabled( KeyCommand.NODE_TOGGLE_FOLDS_SHALLOW, ((foldable || unfoldable) && map.editable) );
    set_enabled( KeyCommand.NODE_TOGGLE_SEQUENCE,      (map.model.sequences_togglable() && map.editable) );
    set_enabled( KeyCommand.NODE_TOGGLE_LINKS,         map.editable );
    set_enabled( KeyCommand.NODE_ADD_CONNECTION,       ((node_num == 2) && map.editable) );
    set_enabled( KeyCommand.NODE_REPARENT_LINK_COLOR,  (link_colors_parentable() && map.editable) );
    set_enabled( KeyCommand.NODE_ALIGN_TOP,            (alignable && map.editable) );
    set_enabled( KeyCommand.NODE_ALIGN_HCENTER,        (alignable && map.editable) );
    set_enabled( KeyCommand.NODE_ALIGN_BOTTOM,         (alignable && map.editable) );
    set_enabled( KeyCommand.NODE_ALIGN_LEFT,           (alignable && map.editable) );
    set_enabled( KeyCommand.NODE_ALIGN_VCENTER,        (alignable && map.editable) );
    set_enabled( KeyCommand.NODE_ALIGN_RIGHT,          (alignable && map.editable) );
    set_enabled( KeyCommand.NODE_SELECT_PARENT,        map.parent_selectable() );
    set_enabled( KeyCommand.NODE_SELECT_CHILDREN,      map.children_selectable() );

  }

}
