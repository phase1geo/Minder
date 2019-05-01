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

  private DrawArea _da;

  public CurrentInspector( DrawArea da ) {

    _da = da;

    /* Set the transition duration information */
    transition_duration = 500;
    // transition_type     = StackTransitionType.SLIDE_UP_DOWN;
    transition_type     = StackTransitionType.NONE;

    var node_box  = new NodeInspector( da );
    var conn_box  = new ConnectionInspector( da );
    var empty_box = new EmptyInspector( da );

    add_named( node_box,  "node" );
    add_named( conn_box,  "connection" );
    add_named( empty_box, "empty" );

    _da.node_changed.connect( current_changed );
    _da.connection_changed.connect( current_changed );

    show_all();

  }

  /* Returns the width of this window */
  public int get_width() {
    return( 300 );
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

}
