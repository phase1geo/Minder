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

public class TagInspector : Box {

  private MindMap?  _map = null;
  private TagEditor _editor;

  public signal void editable_changed();

  //-------------------------------------------------------------
  // Constructor
  public TagInspector( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 10, valign: Align.FILL );

    _editor = new TagEditor( win );

    win.canvas_changed.connect( tab_changed );

    editable_changed.connect(() => {
      /*
      node_box.editable_changed();
      conn_box.editable_changed();
      group_box.editable_changed();
      */
    });

    append( _editor );

  }

  //-------------------------------------------------------------
  // Connected signal will provide us whenever the current tab
  // changes in the main window.
  private void tab_changed( MindMap? map ) {
    if( _map != null ) {
      _map.current_changed.disconnect( current_changed );
    }
    _map = map;
    _editor.set_tags( map.model.tags );
    if( map != null ) {
      map.current_changed.connect( current_changed );
      current_changed();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the user changes the current node in the
  // canvas.
  private void current_changed() {

    /*
    if( _map.get_current_node() != null ) {
      if( _stack.visible_child_name != "node" ) {
        _stack.transition_type = (_stack.visible_child_name == "empty") ? StackTransitionType.SLIDE_UP : StackTransitionType.NONE;
        _stack.set_visible_child_name( "node" );
      }
    } else if( _map.get_current_connection() != null ) {
      if( _stack.visible_child_name != "connection" ) {
        _stack.transition_type = (_stack.visible_child_name == "empty") ? StackTransitionType.SLIDE_UP : StackTransitionType.NONE;
        _stack.set_visible_child_name( "connection" );
      }
    } else if( _map.get_current_group() != null ) {
      if( _stack.visible_child_name != "group" ) {
        _stack.transition_type = (_stack.visible_child_name == "empty") ? StackTransitionType.SLIDE_UP : StackTransitionType.NONE;
        _stack.set_visible_child_name( "group" );
      }
    } else {
      _stack.transition_type = StackTransitionType.SLIDE_DOWN;
      _stack.set_visible_child_name( "empty" );
    }
    */

  }

  //-------------------------------------------------------------
  // Gives the node or connection note field keyboard focus
  public void grab_note() {

    /*
    if( _map.get_current_node() != null ) {
      var ni = _stack.get_child_by_name( "node" ) as NodeInspector;
      if( ni != null ) {
        ni.grab_note();
      }
    } else if( _map.get_current_connection() != null ) {
      var ci = _stack.get_child_by_name( "connection" ) as ConnectionInspector;
      if( ci != null ) {
        ci.grab_note();
      }
    } else if( _map.get_current_group() != null ) {
      var gi = _stack.get_child_by_name( "group" ) as GroupInspector;
      if( gi != null ) {
        gi.grab_note();
      }
    }
    */

  }

  //-------------------------------------------------------------
  // Grabs the focus on the first field of the displayed pane
  public void grab_first() {
    /*
    switch( _stack.visible_child_name ) {
      case "node"       :  (_stack.get_child_by_name( "node" )       as NodeInspector).grab_first();        break;
      case "connection" :  (_stack.get_child_by_name( "connection" ) as ConnectionInspector).grab_first();  break;
      case "group"      :  (_stack.get_child_by_name( "group" )      as GroupInspector).grab_first();       break;
    }
    */
  }

}
