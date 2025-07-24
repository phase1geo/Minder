/*
* Copyright (c) 2025 (https://github.com/phase1geo/Minder)
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

using Gee;

public delegate void KeyCommandFunc( MindMap map );

public class KeyCommands {

  private class KeyCommand {
    public bool           editable { get; private set; }
    public string?        label    { get; private set; }
    public KeyCommandFunc func     { get; private set; }
    public KeyCommand( bool editable, string? label, KeyCommandFunc func ) {
      this.editable = editable;
      this.label    = label;
      this.func     = func;
    }
  }

  private HashMap<string, KeyCommand> _commands;

  public KeyCommands() {

    _commands = new HashMap<string, KeyCommand>();

    add_command( "control-pressed",      false, control_pressed,      null );
    add_command( "show-contextual-menu", true,  show_contextual_menu, _( "Show contextual menu" ) );
    add_command( "zoom-in",              true,  zoom_in,              _( "Zoom in" ) );
    add_command( "zoom-out",             true,  zoom_out,             _( "Zoom out" ) );

    add_command( "node-align-top",       true,  node_align_top,       _( "Align selected node top edges" ) );
    add_command( "node-align-vcenter",   true,  node_align_vcenter,   _( "Align selected node vertial centers" ) );
    add_command( "node-align-bottom",    true,  node_align_bottom,    _( "Align selected node bottom edges" ) );
    add_command( "node-align-left",      true,  node_align_left,      _( "Align selected node left edges" ) );
    add_command( "node-align-hcenter",   true,  node_align_hcenter,   _( "Align selected node horizontal centers" ) );
    add_command( "node-align-right",     true,  node_align_right,     _( "Align selected node right edges" ) );

  }

  //-------------------------------------------------------------
  // Adds a single command to the list of supported commands.  If
  // the label is null, this command cannot be modified by the user.
  private void add_command( string command, bool editable, KeyCommandFunc func, string? label ) {
    var key_command = new KeyCommand( editable, label, func );
    _commands.set( command, key_command );
  }

  //-------------------------------------------------------------
  // Returns true if the given command shortcut is editable by the
  // user.
  public bool is_shortcut_editable( string command ) {
    return( _commands.get( command ).editable ); 
  }

  //-------------------------------------------------------------
  // Returns the label associated with the given command.  If the
  // returned label is null, this command should not be displayed.
  public string? get_label( string command ) {
    return( _commands.get( command ).label );
  }

  //-------------------------------------------------------------
  // Executs the command associated with the 
  public void execute( MindMap map, string command ) {
    if( _commands.has_key( command ) ) {
      _commands.get( command ).func( map );
    }
  }

  //-------------------------------------------------------------
  // COMMANDS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Called whenever the control key is pressed down.
  private void control_pressed( MindMap map ) {
    // TODO - map.set_control( true );
  }

  //-------------------------------------------------------------
  // Display the contextual menu for the currently selected item.
  private void show_contextual_menu( MindMap map ) {
    map.canvas.show_contextual_menu( map.canvas.scaled_x, map.canvas.scaled_y );
  }

  //-------------------------------------------------------------
  // Zooms the current mindmap in (increase size).
  private void zoom_in( MindMap map ) {
    map.canvas.zoom_in();
  }

  //-------------------------------------------------------------
  // Zooms the current mindmap out (decrease size).
  private void zoom_out( MindMap map ) {
    map.canvas.zoom_out();
  }

  //-------------------------------------------------------------
  // Align the selected nodes along their top edge.
  private void node_align_top( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_top( map, map.selected.nodes() );
    }
  }

  //-------------------------------------------------------------
  // Align the selected nodes along their vertical center.
  private void node_align_vcenter( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_vcenter( map, map.selected.nodes() );
    }
  }

  //-------------------------------------------------------------
  // Align the selected nodes along their bottom edge.
  private void node_align_bottom( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_bottom( map, map.selected.nodes() );
    }
  }

  //-------------------------------------------------------------
  // Align the selected nodes along their left edge.
  private void node_align_left( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_left( map, map.selected.nodes() );
    }
  }

  //-------------------------------------------------------------
  // Align the selected nodes along their horizontal center.
  private void node_align_hcenter( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_hcenter( map, map.selected.nodes() );
    }
  }

  //-------------------------------------------------------------
  // Align the selected nodes along their right edge.
  private void node_align_right( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_right( map, map.selected.nodes() );
    }
  }

  /*
    add_shortcut( Key.a,            false, false, false, "node-select-parent" );
    add_shortcut( Key.d,            false, false, false, "node-select-children" );
    add_shortcut( Key.f,            false, false, false, "node-toggle-folds-shallow" );
    add_shortcut( Key.f,            false, true,  false, "node-toggle-folds-deep" );
    add_shortcut( Key.g,            false, false, false, "node-add-group" );
    add_shortcut( Key.l,            false, true,  false, "node-change-link-color" );
    add_shortcut( Key.m,            false, false, false, "node-select-root" );
    add_shortcut( Key.r,            false, false, false, "redo-action" );
    add_shortcut( Key.t,            false, false, false, "node-change-task" );
    add_shortcut( Key.u,            false, false, false, "undo-action" );
    add_shortcut( Key.numbersign,   false, true,  false, "node-toggle-sequence" );
    add_shortcut( Key.x,            false, false, false, "node-create-connection" );
    add_shortcut( Key.y,            false, false, false, "node-toggle-links" );
    add_shortcut( Key.e,            false, true,  false, "show-properties-note" );
    add_shortcut( Key.i,            false, false, false, "show-properties-first" );
    add_shortcut( Key.e,            false, false, false, "any-editable" );
    add_shortcut( Key.s,            false, false, false, "show-selected" );

    add_shortcut( Key.o,            false, true,  false, "callout-select-node" );

    add_shortcut( Key.f,            false, false, false, "connection-select-from-node" );
    add_shortcut( Key.n,            false, false, false, "connection-select-next" );
    add_shortcut( Key.p,            false, false, false, "connection-select-previous" );
    add_shortcut( Key.t,            false, false, false, "connection-select-to-node" );

    add_shortcut( Key.c,            false, true,  false, "node-center" );
    add_shortcut( Key.d,            false, true,  false, "node-select-tree" );
    add_shortcut( Key.i,            false, true,  false, "node-add-image" );
    add_shortcut( Key.o,            false, true,  false, "node-select-callout" );
    add_shortcut( Key.s,            false, true,  false, "node-sort-alphabetically" );
    add_shortcut( Key.x,            false, true,  false, "node-select-connection" );
    add_shortcut( Key.y,            false, true,  false, "node-select-linked-node" );
    add_shortcut( Key.c,            false, false, false, "node-select-child-node" );
    add_shortcut( Key.h,            false, false, false, "node-select-left" );
    add_shortcut( Key.j,            false, false, false, "node-select-down" );
    add_shortcut( Key.k,            false, false, false, "node-select-up" );
    add_shortcut( Key.l,            false, false, false, "node-select-right" );
    add_shortcut( Key.n,            false, false, false, "node-select-sibling-next" );
    add_shortcut( Key.o,            false, false, false, "node-add-callout" );
    add_shortcut( Key.p,            false, false, false, "node-select-sibling-previous" );
    add_shortcut( Key.x,            false, false, false, "node-start-connection" );
  */

}
