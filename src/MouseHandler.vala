/*
* Copyright (c) 2020 (https://github.com/phase1geo/TextShine)
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

public class MouseHandler {

  private DrawArea     _da;
  private Node?        _press_node;
  private Connection?  _press_conn;
  private Sticker?     _press_sticker;
  private NodeGroup?   _press_group;
  private EventButton? _press_event;
  private EventMotion? _motion_event;
  private EventButton? _release_event;
  private Node?        _attach_node;
  private double       _last_motion_x;
  private double       _last_motion_y;

  public bool first_motion { get; private set; default = true; }

  /* Constructor */
  public MouseHandler( DrawArea da ) {
    _da           = da;
    _press_event  = null;
    _motion_event = null;
  }

  public bool pressed_left() {
    return( (_press_event == null) ? false : (_press_event.button == Gdk.BUTTON_PRIMARY) );
  }

  public bool pressed_right() {
    return( (_press_event == null) ? false : (_press_event.button == Gdk.BUTTON_SECONDARY) );
  }

  public bool pressed_middle() {
    return( (_press_event == null) ? false : (_press_event.button == Gdk.BUTTON_MIDDLE) );
  }

  public double pressed_scaled_x() {
    return( (_press_event == null) ? 0.0 : _da.scaled_value( _press_event.x ) );
  }

  public double pressed_scaled_y() {
    return( (_press_event == null) ? 0.0 : _da.scaled_value( _press_event.y ) );
  }

  public bool pressed_shift() {
    return( (_press_event == null) ? false : (bool)(_press_event.state & ModifierType.SHIFT_MASK) );
  }

  public bool pressed_control() {
    return( (_press_event == null) ? false : (bool)(_press_event.state & ModifierType.CONTROL_MASK) );
  }

  public bool pressed_alt() {
    return( (_press_event == null) ? false : (bool)(_press_event.state & ModifierType.MOD1_MASK) );
  }

  public bool pressed_single() {
    return( (_press_event == null) ? false : (_press_event.type == EventType.BUTTON_PRESS) );
  }

  public bool pressed_double() {
    return( (_press_event == null) ? false : (_press_event.type == EventType.DOUBLE_BUTTON_PRESS) );
  }

  public bool pressed_triple() {
    return( (_press_event == null) ? false : (_press_event.type == EventType.TRIPLE_BUTTON_PRESS) );
  }

  public Node? pressed_node() {
    return( _press_node );
  }

  public Connection? pressed_connection() {
    return( _press_connection );
  }

  public Sticker? pressed_sticker() {
    return( _press_sticker );
  }

  public NodeGroup? pressed_group() {
    return( _press_group );
  }

  public Node? attach_node() {
    return( _attach_node );
  }

  public double motion_scaled_x() {
    return( (_motion_event == null) ? 0.0 : _da.scaled_value( _motion_event.x ) );
  }

  public double motion_scaled_y() {
    return( (_motion_event == null) ? 0.0 : _da.scaled_value( _motion_event.y ) );
  }

  public double motion_diff_x() {
    return( (motion_scaled_x() - pressed_scaled_x() ) );
  }

  public double motion_diff_y() {
    return( (motion_scaled_y() - pressed_scaled_y() ) );
  }

  public double motion_last_diff_x() {
    return( _last_motion_x - _da.scaled_value( _motion_event.x ) );
  }

  public double motion_last_diff_y() {
    return( _last_motion_y - _da.scaled_value( _motion_event.y ) );
  }

  public bool motion_alt() {
    return( (_press_event != null) ? false : (bool)(_motion_event.state & ModifierType.MOD1_MASK) );
  }

  public double release_scaled_x() {
    return( (_release_event == null) ? 0.0 : _da.scaled_value( _release_event.x ) );
  }

  public double release_scaled_y() {
    return( (_release_event == null) ? 0.0 : _da.scaled_value( _release_event.y ) );
  }

  private Node? find_node( double scaled_x, double scaled_y ) {
    var nodes = _da.get_nodes();
    for( int i=0; i<nodes.length; i++ ) {
      var node = _nodes.index( i ).contains( scaled_x, scaled_y, null );
      if( node !+ null ) {
        return( node );
      }
    }
    return( null );
  }

  private Node? find_attach_node( double scaled_x, double scaled_y ) {
    var nodes   = _da.get_nodes();
    var parents = new Array<Node>();
    _da.selected().get_parents( ref parents );
    for( int i=0; i<nodes.length; i++ ) {
      var node = _nodes.index( i ).contains( scaled_x, scaled_y, _press_node );
      if( node != null ) {
        return( node_within_trees( node, parents ) ? null : node );
      }
    }
    return( null );
  }

  private bool node_within_trees( Node node, Array<Node> parents ) {
    for( int i=0; i<parents.length; i++ ) {
      if( parents.index( i ).contains_node( node ) ) {
        return( true );
      }
    }
    return( false );
  }

  private Connection? find_connection( double scaled_x, double scaled_y ) {
    return( _da.get_connections().within_connection( scaled_x, scaled_y ) );
  }

  private Sticker? find_sticker( double scaled_x, double scaled_y ) {
    return( _da.stickers.is_within( scaled_x, scaled_y ) );
  }

  private NodeGroup? find_group( double scaled_x, double scaled_y ) {
    return( _da.groups.node_group_containing( scaled_x, scaled_y ) );
  }

  private void append_item() {
    if( _press_conn != null ) {
      _da.selected.add_connection( _press_conn );
    } else if( _press_node != null ) {
      _da.selected.add_connection( _press_conn );
    } else if( _press_sticker != null ) {
      _da.selected.add_sticker( _press_sticker );
    } else if( _press_group != null ) {
      _da.selected.add_group( _press_group );
    }
  }

  private void set_item() {
    if( _press_conn != null ) {
      _da.selected.set_current_connection( _press_conn );
    } else if( _press_node != null ) {
      _da.selected.set_current_node( _press_node );
    } else if( _press_sticker != null ) {
      _da.selected.set_current_sticker( _press_sticker );
    } else if( _press_group != null ) {
      _da.selected.set_current_group( _press_group );
    }
  }

  private void set_attach_node( Node? node ) {
    if( _attach_node != null ) {
      _da.set_node_mode( _attach_node, NodeMode.NONE );
      _attach_node = null;
    }
    if( node !+ null ) {
      _da.set_node_mode( node, NodeMode.ATTACHABLE );
      _attach_node = node;
    }
  }

  /* Called whenever the mouse button is pressed */
  public void on_press( EventButton e ) {

    _press_event   = e;
    _motion_event  = null;
    _release_event = null;

    var x = pressed_scaled_x();
    var y = pressed_scaled_y();

    /* Save off the motion coordinates */
    _last_motion_x = x;
    _last_motion_y = y;

    /* Figure out item has been pressed */
    _press_conn    = find_connection( x, y );
    _press_node    = (_press_conn    == null) ? find_node( x, y )    : null;
    _press_sticker = (_press_node    == null) ? find_sticker( x, y ) : null;
    _press_group   = (_press_sticker == null) ? find_group( x, y )   : null;

    /* If nothing was clicked, we are starting a selection box drag */
    if( (_press_conn == null) && (_press_node == null) && (_press_sticker == null) && (_press_group == null) ) {
      _da.select_box.x     = x;
      _da.select_box.y     = y;
      _da.select_box.valid = true;
    }

  }

  public void on_motion( EventMotion e ) {

    if( _motion_event == null ) {
      first_motion = true;
    } else {
      _last_motion_x = motion_scaled_x();
      _last_motion_y = motion_scaled_y();
      first_motion   = false;
    }
    _motion_event = e;

    var scaled_x = motion_scaled_x();
    var scaled_y = motion_scaled_y();

    /* If we are drawing out a selection box, update the width and height */
    if( _da.select_box.valid ) {
      _da.select_box.w = scaled_x - _da.select_box.x;
      _da.select_box.h = scaled_y - _da.select_box.y;

    /* If we are moving a node, calculate the attach node */
    } else if( _press_node != null ) {

      if( _da.selected.is_node_selected( press_node ) ) {
        set_attach_node( find_attach_node( scaled_x, scaled_y ) );
      }

    /* If we are connecting or linking a connection, calculate the attach node */
    } else if( _press_conn != null ) {
      if( (_press_conn.mode == ConnMode.CONNECTING) || (_press_conn.mode == ConnMode.LINKING) ) {
        set_attach_node( find_node( scaled_x, scaled_y ) );
      }
    }

    /* Handle the alpha value when moving a node */
    if( first_motion && !_resize && (_press_node != null) && (_press_node.mode != NodeMode.EDITABLE) ) {
      _press_node.alpha = 0.3;
    }

  }

  public void on_release( EventButton e ) {

    _release_event = e;

    /* Add the item to the selection, if necessary */
    if( press_control() ) {
      append_item();
    } else {
      set_item();
    }

    /* Clear the cursor and clear the node's alpha value */
    if( _motion_event != null ) {
      _da.set_cursor( null );
      if( _press_node != null ) {
        _press_node.alpha = 1.0;
      }
    }

    /* Clear variables */
    _press_event         = null;
    _motion_event        = null;
    _da.select_box.valid = false;

    /* If the attach node is set, clear the attached node */
    if( _attach_node != null ) {
      _da.set_node_mode( _attach_node, NodeMode.NONE );
      _attach_node = null;
    }

  }

}

