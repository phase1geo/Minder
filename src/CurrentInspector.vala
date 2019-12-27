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

public class CurrentInspector : Stack {

  private DrawArea? _da = null;

  public CurrentInspector( MainWindow win ) {

    /* Set the transition duration information */
    transition_duration = 500;
    transition_type     = StackTransitionType.NONE;

    var node_box  = new NodeInspector( win );
    var conn_box  = new ConnectionInspector( win );
    var empty_box = new EmptyInspector( win );

    add_named( node_box,  "node" );
    add_named( conn_box,  "connection" );
    add_named( empty_box, "empty" );

    win.canvas_changed.connect( tab_changed );

    show_all();

  }

  /* Sets the width of this panel to the given value */
  public void set_width( int width ) {
    var ni = get_child_by_name( "node" )       as NodeInspector;
    var ci = get_child_by_name( "connection" ) as ConnectionInspector;
    if( ni != null ) {
      ni.set_width( width );
    }
    if( ci != null ) {
      ci.set_width( width );
    }
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
      if( visible_child_name != "node" ) {
        transition_type = (visible_child_name == "connection") ? StackTransitionType.NONE : StackTransitionType.SLIDE_UP;
        set_visible_child_name( "node" );
      }
    } else if( _da.get_current_connection() != null ) {
      if( visible_child_name != "connection" ) {
        transition_type = (visible_child_name == "node") ? StackTransitionType.NONE : StackTransitionType.SLIDE_UP;
        set_visible_child_name( "connection" );
      }
    } else {
      transition_type = StackTransitionType.SLIDE_DOWN;
      set_visible_child_name( "empty" );
    }

  }

  /* Gives the node or connection note field keyboard focus */
  public void grab_note() {

    if( _da.get_current_node() != null ) {
      var ni = get_child_by_name( "node" ) as NodeInspector;
      if( ni != null ) {
        ni.grab_note();
      }
    } else if( _da.get_current_connection() != null ) {
      var ci = get_child_by_name( "connection" ) as ConnectionInspector;
      if( ci != null ) {
        ci.grab_note();
      }
    }

  }

}
