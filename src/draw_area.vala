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
    nr1.posy = 200;

    _nodes += n;
    _nodes += nr1;

  }

  /* Sets the current node pointer to the node that is within the given coordinates */
  private void set_current_node( double x, double y ) {
    _current_node = null;
    foreach (Node n in _nodes) {
      if( n.is_within( x, y ) ) {
        _current_node = n;
        return;
      }
    }
  }

  /* Draw the available nodes */
  private bool on_draw( Context ctx ) {
    foreach (Node n in _nodes) {
      n.draw( ctx );
    }
    return( false );
  }

  /* Handle button press event */
  private bool on_press( EventButton event ) {
    if( event.button == 1 ) {
      _press_x = event.x;
      _press_y = event.y;
      set_current_node( event.x, event.y );
      if( _current_node.mode != NodeMode.EDITABLE ) {
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
        n.mode = NodeMode.NONE;
      }
      switch( m ) {
        case NodeMode.NONE     :  _current_node.mode = NodeMode.SELECTED;  break;
        case NodeMode.SELECTED :  _current_node.mode = NodeMode.EDITABLE;  break;
      }
      queue_draw();
    }
    return( false );
  }

  /* Handle a key event */
  private bool on_keypress( EventKey event ) {
    if( _current_node != null ) {
      switch( event.keyval ) {
        case 65288 :  // Backspace
          _current_node.name = _current_node.name.substring( 0, (_current_node.name.length - 1) );
          queue_draw();
          break;
        case 65293 :  // Return key
          if( _current_node.mode == NodeMode.EDITABLE ) {
            stdout.printf( "Editable!\n" );
            _current_node.mode = NodeMode.SELECTED;
          } else if( !_current_node.is_root() ) {
            _current_node.mode = NodeMode.NONE;
            stdout.printf( "Adding sibling!" );
            // _current_node = _current_node.add_sibling();
          }
          queue_draw();
          break;
        case 65289 :  // Tab key
          if( _current_node.mode == NodeMode.SELECTED ) {
            NonrootNode node;
            if( _current_node.is_root() ) {
              node = new NonrootNode( _palette.next() );
            } else {
              node = new NonrootNode( ((NonrootNode)_current_node).color );
            }
            _current_node.attach( node );
            _current_node = node;
            _current_node.mode = NodeMode.EDITABLE;
            queue_draw();
          }
          break;
        default :
          stdout.printf( "In on_keypress, keyval: %s\n", event.keyval.to_string() );
          if( _current_node.mode == NodeMode.EDITABLE ) {
            if( event.str.get_char( 0 ).isprint() ) {
              _current_node.name += event.str;
              queue_draw();
            }
          }
          break;
      }
    }
    return( false );
  }

}
