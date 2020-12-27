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

using Gdk;

public class MouseHandler {

  private DrawArea     _da;
  private EventButton? _press_event;
  private Node?        _press_node;
  private Connection?  _press_conn;
  private Sticker?     _press_sticker;
  private NodeGroup?   _press_group;
  private EventMotion? _motion_event;
  private Node?        _motion_node;
  private Connection?  _motion_conn;
  private Sticker?     _motion_sticker;
  private NodeGroup?   _motion_group;
  private EventButton? _release_event;
  private double       _last_motion_x;
  private double       _last_motion_y;
  private bool         _press_resizer;
  private double       _orig_x;
  private double       _orig_y;
  private double       _orig_w;

  public bool  first_motion { get; private set; default = true; }
  public Node? attach_node  { get; set; default = null; }
	
	public signal void node_pressed( Node node, double x, double y );
	public signal void connection_pressed( Connection conn, double x, double y );
	public signal void sticker_pressed( Sticker sticker, double x, double y );
	public signal void group_pressed( NodeGroup group, double x, double y );
  public signal void nothing_pressed( double x, double y );
	
	public signal void node_clicked( Node node, double x, double y );
	public signal void connection_clicked( Connection conn, double x, double y );
	public signal void sticker_clicked( Sticker sticker, double x, double y );
	public signal void group_clicked( NodeGroup group, double x, double y );
	public signal void nothing_clicked( double x, double y );

  public signal void node_moved( Node node, double x, double y );
  public signal void connection_moved( Connection conn, double x, double y );
  public signal void sticker_moved( Sticker sticker, double x, double y );
  public signal void nothing_moved( double x, double y );
	
	public signal void node_dropped( Node node, double x, double y );
	public signal void connection_dropped( Connection conn, double x, double y );
	public signal void sticker_dropped( Sticker sticker, double x, double y );
	
	public signal void over_node( Node node, double x, double y );
	public signal void over_connection( Connection conn, double x, double y );
	public signal void over_sticker( Sticker sticker, double x, double y );
	public signal void over_group( NodeGroup group, double x, double y );
	public signal void over_nothing( double x, double y );

  public signal void select_box_changed();
	
  /* Constructor */
  public MouseHandler( DrawArea da ) {
    _da            = da;
    _press_event   = null;
    _motion_event  = null;
    _release_event = null;
  }

  public bool pressed() {
    return( _press_event != null );
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
    return( (_press_event == null) ? 0.0 : _da.scale_value( _press_event.x ) );
  }

  public double pressed_scaled_y() {
    return( (_press_event == null) ? 0.0 : _da.scale_value( _press_event.y ) );
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

  public bool pressed_resizer() {
    return( _press_resizer );
  }

  public Node? pressed_node() {
    return( _press_node );
  }

  public Connection? pressed_connection() {
    return( _press_conn );
  }

  public Sticker? pressed_sticker() {
    return( _press_sticker );
  }

  public NodeGroup? pressed_group() {
    return( _press_group );
  }

  public bool motion() {
    return( _motion_event != null );
  }

  public double motion_scaled_x() {
    return( (_motion_event == null) ? 0.0 : _da.scale_value( _motion_event.x ) );
  }

  public double motion_scaled_y() {
    return( (_motion_event == null) ? 0.0 : _da.scale_value( _motion_event.y ) );
  }

  public double motion_diff_x() {
    return( (_motion_event == null) ? 0.0 : (_da.scale_value( _motion_event.x ) - _last_motion_x) );
  }

  public double motion_diff_y() {
    return( (_motion_event == null) ? 0.0 : (_da.scale_value( _motion_event.y ) - _last_motion_y) );
  }

  public bool motion_control() {
    return( (_motion_event == null) ? false : (bool)(_motion_event.state & ModifierType.CONTROL_MASK) );
  }

  public bool motion_alt() {
    return( (_motion_event == null) ? false : (bool)(_motion_event.state & ModifierType.MOD1_MASK) );
  }

  public bool motion_resizing() {
    return( (_motion_event != null) && _press_resizer );
  }

  public bool moving_node() {
    return( (_press_event != null) && (_motion_event != null) && (_press_node != null) && (_press_node.mode != NodeMode.EDITABLE) && !_press_resizer );
  }

  public Node? motion_node() {
    return( _motion_node );
  }

  public Connection? motion_connection() {
    return( _motion_conn );
  }

  public Sticker? motion_sticker() {
    return( _motion_sticker );
  }

  public NodeGroup? motion_group() {
    return( _motion_group );
  }

  public double release_scaled_x() {
    return( (_release_event == null) ? 0.0 : _da.scale_value( _release_event.x ) );
  }

  public double release_scaled_y() {
    return( (_release_event == null) ? 0.0 : _da.scale_value( _release_event.y ) );
  }

  private Node? find_node( double scaled_x, double scaled_y ) {
    var nodes = _da.get_nodes();
    for( int i=0; i<nodes.length; i++ ) {
      var node = nodes.index( i ).contains( scaled_x, scaled_y, null );
      if( node != null ) {
        return( node );
      }
    }
    return( null );
  }

  private Node? find_attach_node( double scaled_x, double scaled_y ) {
    var nodes   = _da.get_nodes();
    var parents = new Array<Node>();
    _da.selected.get_parents( ref parents );
    for( int i=0; i<nodes.length; i++ ) {
      var node = nodes.index( i ).contains( scaled_x, scaled_y, _press_node );
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

  private void toggle_item() {
    if( _press_conn != null ) {
      if( !_da.selected.remove_connection( _press_conn ) ) {
        _da.selected.add_connection( _press_conn );
      }
    } else if( _press_node != null ) {
      if( !_da.selected.remove_node( _press_node ) ) {
        _da.selected.add_node( _press_node );
      }
    } else if( _press_sticker != null ) {
      if( !_da.selected.remove_sticker( _press_sticker ) ) {
        _da.selected.add_sticker( _press_sticker );
      }
    } else if( _press_group != null ) {
      if( !_da.selected.remove_group( _press_group ) ) {
        _da.selected.add_group( _press_group );
      }
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

  private void change_attach_node( Node? node ) {
    if( attach_node != null ) {
      _da.set_node_mode( attach_node, NodeMode.NONE );
      attach_node = null;
    }
    if( node != null ) {
      _da.set_node_mode( node, NodeMode.ATTACHABLE );
      attach_node = node;
    }
  }

  /* Called whenever the mouse button is pressed */
  public void on_press( EventButton e ) {

    _press_event   = e;
    _press_resizer = false;
    _motion_event  = null;
    _release_event = null;

    var x = pressed_scaled_x();
    var y = pressed_scaled_y();

    /* Figure out item has been pressed */
    _press_conn    = find_connection( x, y );
    _press_node    = (_press_conn    == null) ? find_node( x, y )    : null;
    _press_sticker = (_press_node    == null) ? find_sticker( x, y ) : null;
    _press_group   = (_press_sticker == null) ? find_group( x, y )   : null;

    if( _press_conn != null ) {
      connection_pressed( _press_conn, x, y );

    /* If we clicked on a node or sticker, get some information about them */
    } else if( _press_node != null ) {
      _orig_x = _press_node.posx;
      _orig_y = _press_node.posy;
      _orig_w = _press_node.width;
      if( _press_node.is_within_resizer( x, y ) ) {
        _press_resizer = true;
        _da.set_cursor( CursorType.SB_H_DOUBLE_ARROW );
      }
			node_pressed( _press_node, x, y );

    } else if( _press_sticker != null ) {
      _orig_x = _press_sticker.posx;
      _orig_y = _press_sticker.posy;
      _orig_w = _press_sticker.width;
      if( _press_sticker.is_within_resizer( x, y ) ) {
        _press_resizer = true;
        _da.set_cursor( CursorType.SB_H_DOUBLE_ARROW );
      }
			sticker_pressed( _press_sticker, x, y );
			
    } else if( _press_group != null ) {
      group_pressed( _press_group, x, y );

    } else {
      nothing_pressed( x, y );
    }

    /* If nothing was clicked, we are starting a selection box drag */
    if( (_press_conn == null) && (_press_node == null) && (_press_sticker == null) && (_press_group == null) ) {
      _da.select_box.x     = x;
      _da.select_box.y     = y;
      _da.select_box.w     = 0;
      _da.select_box.h     = 0;
      _da.select_box.valid = true;
    }

  }

  public void on_motion( EventMotion e ) {

    if( _press_event != null ) {
      if( _motion_event == null ) {
        first_motion = true;
        if( !_press_resizer && (_press_node != null) && (_press_node.mode != NodeMode.EDITABLE) ) {
          _press_node.alpha = 0.3;
        }
      } else {
        first_motion = false;
      }
    }

    /* Save off last motion coordinates */
    _last_motion_x = first_motion ? _da.scale_value( e.x ) : motion_scaled_x();
    _last_motion_y = first_motion ? _da.scale_value( e.y ) : motion_scaled_y();

    _motion_event = e;

    var x = motion_scaled_x();
    var y = motion_scaled_y();

    /* If we are drawing out a selection box, update the width and height */
    if( _da.select_box.valid ) {
      _da.select_box.w = x - _da.select_box.x;
      _da.select_box.h = y - _da.select_box.y;
      select_box_changed();

    /* If we are moving a node, calculate the attach node */
    } else if( _press_node != null ) {
      if( _da.selected.is_node_selected( _press_node ) ) {
        change_attach_node( find_attach_node( x, y ) );
      }
      node_moved( _press_node, x, y );

    /* If we are connecting or linking a connection, calculate the attach node */
    } else if( _press_conn != null ) {
      if( (_press_conn.mode == ConnMode.CONNECTING) || (_press_conn.mode == ConnMode.LINKING) ) {
        change_attach_node( find_node( x, y ) );
      }
      connection_moved( _press_conn, x, y );

    /* If a sticker is being moved, send the signal */
    } else if( _press_sticker != null ) {
      sticker_moved( _press_sticker, x, y );

    /* If we pressed down on nothing and moved the mouse, call the nothing moved event */
    } else if( _press_event != null ) {
      nothing_moved( x, y );

    /* If we have not been pressed, check to see if the cursor is within an item */
    } else {
      _motion_conn    = find_connection( x, y );
      _motion_node    = (_motion_conn    == null) ? find_node( x, y )    : null;
      _motion_sticker = (_motion_node    == null) ? find_sticker( x, y ) : null;
      _motion_group   = (_motion_sticker == null) ? find_group( x, y )   : null;

      /* Signal the event */
      if( _motion_conn != null ) {
        over_connection( _motion_conn, x, y );
      } else if( _motion_node != null ) {
        over_node( _motion_node, x, y );
      } else if( _motion_sticker != null ) {
        over_sticker( _motion_sticker, x, y );
      } else if( _motion_group != null ) {
        over_group( _motion_group, x, y );
      } else {
        over_nothing( x, y );
      }
    }

  }

  public void on_release( EventButton e ) {

    _release_event = e;

    var x = _da.scale_value( e.x );
    var y = _da.scale_value( e.y );

    /* Update the selection */
    if( pressed_left() && pressed_single() ) {
      if( pressed_control() ) {
        toggle_item();
      } else {
        set_item();
      }
    }

    /* Special case when a node is clicked */
    if( _motion_event == null ) {

      if( _press_conn != null ) {
        connection_clicked( _press_conn, x, y );

      } else if( _press_node != null ) {
        var node = pressed_node();
        if( pressed_control() ) {
          if( pressed_double() ) {
            if( !_da.selected.remove_node_tree( node ) ) {
              _da.selected.add_node_tree( node );
            }
          } else if( pressed_triple() ) {
            if( !_da.selected.remove_child_nodes( node ) ) {
              _da.selected.add_child_nodes( node );
            }
          }
        } else if( pressed_alt() ) {
          if( pressed_double() ) {
            _da.selected.clear_nodes();
            _da.selected.add_node_tree( node );
          } else if( pressed_triple() ) {
            _da.selected.clear_nodes();
            _da.selected.add_child_nodes( node );
          }
        }
        node_clicked( _press_node, x, y );

      } else if( _press_sticker != null ) {
        sticker_clicked( _press_sticker, x, y );

      } else if( _press_group != null ) {
        group_clicked( _press_group, x, y );

      } else {
        nothing_clicked( x, y );
      }

    /* Otherwise, handle a drop event */
    } else {
      _da.set_cursor( null );
      if( _press_node != null ) {
        _press_node.alpha = 1.0;
        node_dropped( _press_node, x, y );
      } else if( _press_conn != null ) {
        connection_dropped( _press_conn, x, y );
      } else if( _press_sticker != null ) {
        sticker_dropped( _press_sticker, x, y );
      } else {
        _da.select_box.valid = false;
        select_box_changed();
      }
    }

  }

  /*
   This should be called by the on_release method in DrawArea just before this
   method completes.
  */
  public void clear() {

    /* Clear variables */
    _press_event         = null;
    _press_node          = null;
    _press_conn          = null;
    _press_sticker       = null;
    _press_group         = null;
    _motion_event        = null;

    /* If the attach node is set, clear the attached node */
    if( attach_node != null ) {
      _da.set_node_mode( attach_node, NodeMode.NONE );
      attach_node = null;
    }

  }

}

