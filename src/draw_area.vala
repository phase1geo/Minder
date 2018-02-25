using Gtk;
using Gdk;
using Cairo;

public class DrawArea : Gtk.DrawingArea {

  private double       _press_x;
  private double       _press_y;
  private bool         _pressed = false;
  private Node         _current_node;
  private Node[]       _nodes;
  private ColorPalette _palette;

  /* Default constructor */
  public DrawArea() {

    /* Create the color palette */
    _palette = new ColorPalette();

    /* Add event listeners */
    this.draw.connect( on_draw );
    this.button_press_event.connect( on_press );
    this.motion_notify_event.connect( on_motion );
    this.button_release_event.connect( on_release );
    this.key_press_event.connect( on_keypress );

    /* Make sure the above events are listened for */
    this.add_events(
      EventMask.BUTTON_PRESS_MASK |
      EventMask.BUTTON_RELEASE_MASK |
      EventMask.BUTTON1_MOTION_MASK |
      EventMask.KEY_PRESS_MASK );

    /* Make sure the drawing area can receive keyboard focus */
    this.can_focus = true;

    /* TEMPORARY */
    RootNode n = new RootNode.with_name( "Main Idea" );
    n.posx = 350;
    n.posy = 200;

    NonrootNode nr1 = new NonrootNode( _palette.next() );
    nr1.name = "Child A";
    nr1.posx = 500;
    nr1.posy = 175;

    NonrootNode nr2 = new NonrootNode( _palette.next() );
    nr2.name = "Child B";
    nr2.posx = 500;
    nr2.posy = 225;

    nr1.attach( n );
    nr2.attach( n );

    _nodes += n;

  }

  /* Sets the current node pointer to the node that is within the given coordinates */
  private void set_current_node( double x, double y ) {
    _current_node = null;
    foreach (Node n in _nodes) {
      _current_node = n.contains( x, y );
      if( _current_node != null ) {
        return;
      }
    }
  }

  /* Returns the attachable node if one is found */
  private Node? attachable_node( double x, double y ) {
    foreach (Node n in _nodes) {
      Node tmp = n.contains( x, y );
      if( (tmp != null) && (tmp != _current_node) && !tmp.contains_node( n ) ) {
        return( tmp );
      }
    }
    return( null );
  }

  /* Draw the available nodes */
  private bool on_draw( Context ctx ) {
    foreach (Node n in _nodes) {
      n.draw_all( ctx );
    }
    return( false );
  }

  /* Handle button press event */
  private bool on_press( EventButton event ) {
    if( event.button == 1 ) {
      _press_x = event.x;
      _press_y = event.y;
      set_current_node( event.x, event.y );
      if( (_current_node == null) || (_current_node.mode != NodeMode.EDITABLE) || (_current_node.mode != NodeMode.EDITED) ) {
        _pressed = true;
      }
    }
    return( false );
  }

  /* Handle mouse motion */
  private bool on_motion( EventMotion event ) {
    if( _pressed ) {
      if( _current_node != null ) {
        _current_node.posx += (event.x - _press_x);
        _current_node.posy += (event.y - _press_y);
        queue_draw();
      }
      _press_x = event.x;
      _press_y = event.y;
    }
    return( false );
  }

  /* Handle button release event */
  private bool on_release( EventButton event ) {
    _pressed = false;
    if( _current_node != null ) {
      NodeMode m = _current_node.mode;
      foreach (Node n in _nodes) {
        n.clear_modes();
      }
      switch( m ) {
        case NodeMode.NONE     :
          _current_node.mode = NodeMode.SELECTED;
          Node attach_node = attachable_node( event.x, event.y );
          if( attach_node != null ) {
            _current_node.detach();
            _current_node.attach( attach_node );
          }
          break;
        case NodeMode.SELECTED :
          _current_node.move_cursor_to_end();
          _current_node.mode = NodeMode.EDITABLE;
          break;
      }
      queue_draw();
    }
    return( false );
  }

  /* Handle a key event */
  private bool on_keypress( EventKey event ) {
    if( _current_node != null ) {
      bool mode_edit = (_current_node.mode == NodeMode.EDITABLE) || (_current_node.mode == NodeMode.EDITED);
      bool mode_sel  = (_current_node.mode == NodeMode.SELECTED);
      switch( event.keyval ) {
        case 65288 :  // Backspace
          if( mode_edit ) {
            _current_node.edit_backspace();
            queue_draw();
          } else if( mode_sel ) {
            _current_node.delete();
            queue_draw();
          }
          break;
        case 65535 :  // Delete key
          if( mode_edit ) {
            _current_node.edit_delete();
            queue_draw();
          } else if( mode_sel ) {
            _current_node.delete();
            queue_draw();
          }
          break;
        case 65307 :  // Escape key
          if( mode_edit ) {
            _current_node.mode = NodeMode.SELECTED;
            queue_draw();
          }
          break;
        case 65293 :  // Return key
          if( mode_edit ) {
            _current_node.mode = NodeMode.SELECTED;
            queue_draw();
          } else if( !_current_node.is_root() ) {
            _current_node.mode = NodeMode.NONE;
            // _current_node = _current_node.add_sibling();
            queue_draw();
          }
          break;
        case 65289 :  // Tab key
          if( mode_edit ) {
            _current_node.mode = NodeMode.SELECTED;
            queue_draw();
          } else if( mode_sel ) {
            NonrootNode node;
            if( _current_node.is_root() ) {
              node = new NonrootNode( _palette.next() );
            } else {
              NonrootNode tmp = (NonrootNode)_current_node;
              node = new NonrootNode( tmp.color );
            }
            node.attach( _current_node );
            _current_node = node;
            _current_node.mode = NodeMode.EDITABLE;
            queue_draw();
          }
          break;
        case 65363 :  // Right key
          if( mode_edit ) {
            _current_node.move_cursor( 1 );
          } else if( mode_sel ) {
            Node first_child = _current_node.first_child();
            if( first_child != null ) {
              _current_node = first_child;
            }
          }
          queue_draw();
          break;
        case 65361 :  // Left key
          if( mode_edit ) {
            _current_node.move_cursor( -1 );
          }
          queue_draw();
          break;
        case 65360 :  // Home key
          if( mode_edit ) {
            _current_node.move_cursor_to_start();
          }
          queue_draw();
          break;
        case 65367 :  // End key
          if( mode_edit ) {
            _current_node.move_cursor_to_end();
          }
          queue_draw();
          break;
        default :
          if( !event.str.get_char( 0 ).isprint() ) {
            stdout.printf( "In on_keypress, keyval: %s\n", event.keyval.to_string() );
          }
          if( mode_edit ) {
            if( event.str.get_char( 0 ).isprint() ) {
              _current_node.edit_insert( event.str );
              queue_draw();
            }
          }
          break;
      }
    }
    return( false );
  }

}
