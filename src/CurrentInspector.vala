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
using Gdk;
using Granite.Widgets;

public class CurrentInspector : Box {

  private DrawArea? _da = null;
  private Stack     _stack;

  public CurrentInspector( MainWindow win ) {

    _stack = new Stack() {
      transition_duration = 500,
      transition_type     = StackTransitionType.NONE
    };

    var node_box  = new NodeInspector( win );
    var conn_box  = new ConnectionInspector( win );
    var group_box = new GroupInspector( win );
    var empty_box = new EmptyInspector( win );

    _stack.add_named( node_box,  "node" );
    _stack.add_named( conn_box,  "connection" );
    _stack.add_named( group_box, "group" );
    _stack.add_named( empty_box, "empty" );

    win.canvas_changed.connect( tab_changed );

    append( _stack );

  }

  /* Sets the width of this panel to the given value */
  public void set_width( int width ) {
    var ni = _stack.get_child_by_name( "node" )       as NodeInspector;
    var ci = _stack.get_child_by_name( "connection" ) as ConnectionInspector;
    var gi = _stack.get_child_by_name( "group" )      as GroupInspector;
    if( ni != null ) {
      ni.set_width( width );
    }
    if( ci != null ) {
      ci.set_width( width );
    }
    if( gi != null ) {
      gi.set_width( width );
    }
  }

  //-------------------------------------------------------------
  // Sets the transition duration to the given value.
  public void set_transition_duration( int duration ) {
    _stack.set_transition_duration( duration );
  }

  /* Resets the width of this inspector to its default width */
  public void reset_width() {
    set_width( 300 );
  }

  /* Connected signal will provide us whenever the current tab changes in the main window */
  private void tab_changed( DrawArea? da ) {
    if( _da != null ) {
      _da.current_changed.disconnect( current_changed );
    }
    _da = da;
    if( da != null ) {
      da.current_changed.connect( current_changed );
      current_changed();
    }
  }

  /* Called whenever the user changes the current node in the canvas */
  private void current_changed() {

    if( _da.get_current_node() != null ) {
      if( _stack.visible_child_name != "node" ) {
        _stack.transition_type = (_stack.visible_child_name == "empty") ? StackTransitionType.SLIDE_UP : StackTransitionType.NONE;
        _stack.set_visible_child_name( "node" );
      }
    } else if( _da.get_current_connection() != null ) {
      if( _stack.visible_child_name != "connection" ) {
        _stack.transition_type = (_stack.visible_child_name == "empty") ? StackTransitionType.SLIDE_UP : StackTransitionType.NONE;
        _stack.set_visible_child_name( "connection" );
      }
    } else if( _da.get_current_group() != null ) {
      if( _stack.visible_child_name != "group" ) {
        _stack.transition_type = (_stack.visible_child_name == "empty") ? StackTransitionType.SLIDE_UP : StackTransitionType.NONE;
        _stack.set_visible_child_name( "group" );
      }
    } else {
      _stack.transition_type = StackTransitionType.SLIDE_DOWN;
      _stack.set_visible_child_name( "empty" );
    }

  }

  /* Gives the node or connection note field keyboard focus */
  public void grab_note() {

    if( _da.get_current_node() != null ) {
      var ni = _stack.get_child_by_name( "node" ) as NodeInspector;
      if( ni != null ) {
        ni.grab_note();
      }
    } else if( _da.get_current_connection() != null ) {
      var ci = _stack.get_child_by_name( "connection" ) as ConnectionInspector;
      if( ci != null ) {
        ci.grab_note();
      }
    } else if( _da.get_current_group() != null ) {
      var gi = _stack.get_child_by_name( "group" ) as GroupInspector;
      if( gi != null ) {
        gi.grab_note();
      }
    }

  }

  /* Grabs the focus on the first field of the displayed pane */
  public void grab_first() {
    switch( _stack.visible_child_name ) {
      case "node"       :  (_stack.get_child_by_name( "node" )       as NodeInspector).grab_first();        break;
      case "connection" :  (_stack.get_child_by_name( "connection" ) as ConnectionInspector).grab_first();  break;
      case "group"      :  (_stack.get_child_by_name( "group" )      as GroupInspector).grab_first();       break;
    }
  }

}
