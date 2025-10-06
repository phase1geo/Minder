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
  public signal void changed();

  //-------------------------------------------------------------
  // Constructor
  public TagInspector( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 10, valign: Align.FILL );

    _editor = new TagEditor( win, true );
    _editor.changed.connect(() => {
      if( _map != null ) {
        _map.queue_draw();
        _map.auto_save();
      }
    });
    _editor.select_changed.connect( tag_select_changed );

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
  // Updates the currently selected node by adding or removing
  // the given tag from its tag list.
  private void tag_select_changed( Tag tag, bool selected ) {

    stdout.printf( "In tag_select_changed, tag: %s, selected: %s\n", tag.name, selected.to_string() );

    var node = _map.get_current_node();
    if( node != null ) {
      if( selected ) {
        node.add_tag( tag );
      } else {
        node.remove_tag( tag );
      }
      _map.queue_draw();
      _map.auto_save();
    }

  }

  //-------------------------------------------------------------
  // Called whenever the user changes the current node in the
  // canvas.
  private void current_changed() {

    var node = _map.get_current_node();

    _editor.show_selected_tags( (node != null) ? node.tags : null );

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
  // Grabs the focus on the first field of the displayed pane
  public void grab_first() {
    _editor.grab_focus();
    current_changed();
  }

}
