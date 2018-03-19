using Gtk;
using Gdk;
using Cairo;

public class DrawArea : Gtk.DrawingArea {

  private double _press_x;
  private double _press_y;
  private double _origin_x = 0.0;
  private double _origin_y = 0.0;
  private bool   _pressed = false;
  private Node   _current_node;
  private Node[] _nodes;
  private Theme  _theme;
  private Layout _layout;

  public bool changed { set; get; default = false; }

  /* Default constructor */
  public DrawArea() {

    _theme  = new ThemeDefault();
    _layout = new Layout();

    /* Set the CSS provider from the theme */
    StyleContext.add_provider_for_screen(
      Screen.get_default(),
      _theme.get_css_provider(),
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );

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

  }

  /* Loads the drawing area origin from the XML node */
  private void load_origin( Xml.Node* n ) {

    string? x = n->get_prop( "x" );
    if( x != null ) {
      _origin_x = double.parse( x );
    }

    string? y = n->get_prop( "y" );
    if( y != null ) {
      _origin_y = double.parse( y );
    }

  }

  /* Loads the given theme from the list of available options */
  private void load_theme( Xml.Node* n ) {
    string? name = n->get_prop( "name" );
    if( name != null ) {
      switch( name ) {
        default :  _theme = new ThemeDefault();  break;
      }
    }
  }

  /* Loads the given layout from the list of available options */
  private void load_layout( Xml.Node* n ) {
    string? name = n->get_prop( "name" );
    if( name != null ) {
      switch( name ) {
        default :  _layout = new Layout();  break;
      }
    }
  }

  /* Loads the contents of the data input stream */
  public void load( Xml.Node* n ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "theme"  :  load_theme( it );   break;
          case "layout" :  load_layout( it );  break;
          case "origin" :  load_origin( it );  break;
          case "nodes"  :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                RootNode node = new RootNode();
                node.load( it2 );
                _nodes += node;
              }
            }
            break;
        }
      }
    }
    queue_draw();
  }

  /* Saves the contents of the drawing area to the data output stream */
  public bool save( Xml.Node* parent ) {

    Xml.Node* theme = new Xml.Node( null, "theme" );
    theme->new_prop( "name", _theme.name );
    parent->add_child( theme );

    Xml.Node* layout = new Xml.Node( null, "layout" );
    theme->new_prop( "name", _layout.name );
    parent->add_child( layout );

    Xml.Node* origin = new Xml.Node( null, "origin" );
    origin->new_prop( "x", _origin_x.to_string() );
    origin->new_prop( "y", _origin_y.to_string() );
    parent->add_child( origin );

    Xml.Node* nodes = new Xml.Node( null, "nodes" );
    foreach (Node n in _nodes ) {
      n.save( nodes );
    }
    parent->add_child( nodes );

    return( true );

  }

  /* Initialize the empty drawing area with a node */
  public void initialize() {

    /* Create the main idea node */
    RootNode n = new RootNode.with_name( "Main Idea" );
    n.posx = 350;
    n.posy = 200;

    _nodes += n;

    queue_draw();

  }

  /* Sets the current node pointer to the node that is within the given coordinates */
  private void set_current_node_at_position( double x, double y ) {
    _current_node = null;
    foreach (Node n in _nodes) {
      if( select_node( n.contains( x, y ) ) ) {
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

  /* Adjusts the x and y origins, panning all elements by the given amount */
  private void move_origin( double diff_x, double diff_y ) {
    _origin_x += diff_x;
    _origin_y += diff_y;
    foreach (Node n in _nodes) {
      n.pan( diff_x, diff_y );
    }
  }

  /* Draw the available nodes */
  private bool on_draw( Context ctx ) {
    foreach (Node n in _nodes) {
      n.draw_all( ctx, _theme, _layout );
    }
    return( false );
  }

  /* Handle button press event */
  private bool on_press( EventButton event ) {
    if( event.button == 1 ) {
      _press_x = event.x;
      _press_y = event.y;
      set_current_node_at_position( event.x, event.y );
      stdout.printf( "After set_current_node_at_position\n" );
      if( _current_node != null ) {
        stdout.printf( "  current_node is NOT null, mode: %s :)\n", _current_node.mode.to_string() );
        switch( _current_node.mode ) {
          case NodeMode.NONE     :
            stdout.printf( "A SELECTED\n" );
            _current_node.mode = NodeMode.SELECTED;
            _pressed = true;
            break;
          case NodeMode.SELECTED :
            stdout.printf( "A EDITABLE\n" );
            _current_node.move_cursor_to_end();
            _current_node.mode = NodeMode.EDITABLE;
            _pressed = true;
            break;
        }
      } else {
        _pressed = true;
      }
      queue_draw();
    }
    return( false );
  }

  /* Handle mouse motion */
  private bool on_motion( EventMotion event ) {
    if( _pressed ) {
      if( _current_node != null ) {
        double diffx = (event.x - _press_x);
        double diffy = (event.y - _press_y);
        _current_node.posx += diffx;
        _current_node.posy += diffy;
        _layout.set_side( _current_node );
        _layout.adjust_tree( _current_node, diffx, diffy );
        queue_draw();
      } else {
        double diff_x = (_press_x - event.x);
        double diff_y = (_press_y - event.y);
        move_origin( diff_x, diff_y );
        queue_draw();
      }
      _press_x = event.x;
      _press_y = event.y;
      changed = true;
    }
    return( false );
  }

  /* Handle button release event */
  private bool on_release( EventButton event ) {
    _pressed = false;
    if( _current_node != null ) {
      if( _current_node.mode == NodeMode.SELECTED ) {
        Node attach_node = attachable_node( event.x, event.y );
        if( attach_node != null ) {
          _current_node.detach();
          _current_node.attach( attach_node );
          queue_draw();
          changed = true;
        }
      }
    }
    return( false );
  }

  /* Returns true if we are in some sort of edit mode */
  private bool is_mode_edit() {
    return( (_current_node.mode == NodeMode.EDITABLE) || (_current_node.mode == NodeMode.EDITED) );
  }

  /* Returns true if we are in the selected mode */
  private bool is_mode_selected() {
    return( _current_node.mode == NodeMode.SELECTED );
  }

  /* If the specified node is not null, selects the node and makes it the current node */
  private bool select_node( Node? n ) {
    if( n != null ) {
      if( n.mode == NodeMode.NONE ) {
        if( _current_node != null ) {
          stdout.printf( "B NONE\n" );
          _current_node.mode = NodeMode.NONE;
        }
        _current_node = n;
        stdout.printf( "B SELECTED\n" );
        _current_node.mode = NodeMode.SELECTED;
      }
      return( true );
    }
    return( false );
  }

  /* Called whenever the backspace character is entered in the drawing area */
  private void handle_backspace() {
    if( is_mode_edit() ) {
      _current_node.edit_backspace();
      queue_draw();
      changed = true;
    } else if( is_mode_selected() ) {
      _current_node.delete();
      queue_draw();
      changed = true;
    }
  }

  /* Called whenever the delete character is entered in the drawing area */
  private void handle_delete() {
    if( is_mode_edit() ) {
      _current_node.edit_delete();
      queue_draw();
      changed = true;
    } else if( is_mode_selected() ) {
      _current_node.delete();
      queue_draw();
      changed = true;
    }
  }

  /* Called whenever the escape character is entered in the drawing area */
  private void handle_escape() {
    if( is_mode_edit() ) {
      stdout.printf( "C SELECTED\n" );
      _current_node.mode = NodeMode.SELECTED;
      queue_draw();
    }
  }

  /* Called whenever the return character is entered in the drawing area */
  private void handle_return() {
    if( is_mode_edit() ) {
      stdout.printf( "D SELECTED\n" );
      _current_node.mode = NodeMode.SELECTED;
      queue_draw();
    } else if( !_current_node.is_root() ) {
      NonrootNode node = new NonrootNode();
      if( _current_node.parent.is_root() ) {
        node.color_index = _theme.next_color_index();
      } else {
        node.color_index = ((NonrootNode)_current_node).color_index;
        node.side        = _current_node.side;
      }
      stdout.printf( "D NONE\n" );
      _current_node.mode = NodeMode.NONE;
      _layout.add_child_of( _current_node.parent, node );
      node.attach( _current_node.parent );
      if( select_node( node ) ) {
        stdout.printf( "D EDITABLE\n" );
        node.mode = NodeMode.EDITABLE;
        queue_draw();
      }
      adjust_origin();
      changed = true;
    }
  }

  /* Called whenever the tab character is entered in the drawing area */
  private void handle_tab() {
    if( is_mode_edit() ) {
      stdout.printf( "E SELECTED\n" );
      _current_node.mode = NodeMode.SELECTED;
      queue_draw();
    } else if( is_mode_selected() ) {
      NonrootNode node = new NonrootNode();
      if( _current_node.is_root() ) {
        node.color_index = _theme.next_color_index();
      } else {
        node.color_index = ((NonrootNode)_current_node).color_index;
        node.side        = _current_node.side;
      }
      stdout.printf( "E NONE\n" );
      _current_node.mode = NodeMode.NONE;
      _layout.add_child_of( _current_node, node );
      node.attach( _current_node );
      if( select_node( node ) ) {
        stdout.printf( "E EDITABLE\n" );
        node.mode = NodeMode.EDITABLE;
        queue_draw();
      }
      adjust_origin();
      changed = true;
    }
  }

  /* Called whenever the right key is entered in the drawing area */
  private void handle_right() {
    if( is_mode_edit() ) {
      _current_node.move_cursor( 1 );
      queue_draw();
    } else if( is_mode_selected() ) {
      if( select_node( _current_node.first_child() ) ) {
        queue_draw();
      }
    }
  }

  /* Called whenever the left key is entered in the drawing area */
  private void handle_left() {
    if( is_mode_edit() ) {
      _current_node.move_cursor( -1 );
      queue_draw();
    } else if( is_mode_selected() ) {
      if( select_node( _current_node.parent ) ) {
        queue_draw();
      }
    }
  }

  /* Called whenever the home key is entered in the drawing area */
  private void handle_home() {
    if( is_mode_edit() ) {
      _current_node.move_cursor_to_start();
      queue_draw();
    }
  }

  /* Called whenever the end key is entered in the drawing area */
  private void handle_end() {
    if( is_mode_edit() ) {
      _current_node.move_cursor_to_end();
      queue_draw();
    }
  }

  /* Called whenever the up key is entered in the drawing area */
  private void handle_up() {
    if( is_mode_selected() ) {
      if( _current_node.is_root() ) {
        int i = 0;
        foreach (Node n in _nodes) {
          if( n == _current_node ) {
            if( i > 0 ) {
              if( select_node( _nodes[i-1] ) ) {
                queue_draw();
              }
              return;
            }
          }
          i++;
        }
      } else {
        if( select_node( _current_node.parent.prev_child( _current_node ) ) ) {
          queue_draw();
        }
      }
    }
  }

  /* Called whenever the down key is entered in the drawing area */
  private void handle_down() {
    if( is_mode_selected() ) {
      if( _current_node.is_root() ) {
        int i = 0;
        foreach (Node n in _nodes) {
          if( n == _current_node ) {
            if( (i + 1) > _nodes.length ) {
              if( select_node( _nodes[i+1] ) ) {
                queue_draw();
              }
              return;
            }
          }
          i++;
        }
      } else {
        if( select_node( _current_node.parent.next_child( _current_node ) ) ) {
          queue_draw();
        }
      }
    }
  }

  /* Called whenever the page up key is entered in the drawing area */
  private void handle_pageup() {
    if( is_mode_selected() ) {
      if( _current_node.is_root() ) {
        if( _nodes.length > 0 ) {
          if( select_node( _nodes[0] ) ) {
            queue_draw();
          }
        }
      } else {
        if( select_node( _current_node.parent.first_child() ) ) {
          queue_draw();
        }
      }
    }
  }

  /* Called whenever the page down key is entered in the drawing area */
  private void handle_pagedn() {
    if( is_mode_selected() ) {
      if( _current_node.is_root() ) {
        if( _nodes.length > 0 ) {
          if( select_node( _nodes[_nodes.length-1] ) ) {
            queue_draw();
          }
        }
      } else {
        if( select_node( _current_node.parent.last_child() ) ) {
          queue_draw();
        }
      }
    }
  }

  private void adjust_origin() {
    double x, y, w, h;
    double diff_x = 0;
    double diff_y = 0;
    _current_node.bbox( out x, out y, out w, out h );
    if( x < 10 ) {
      diff_x = -100;
    } else if( (get_allocated_width() - (x + w)) < 10 ) {
      diff_x = 100;
    }
    if( y < 10 ) {
      diff_y = -100;
    } else if( (get_allocated_height() - (y + h)) < 10 ) {
      diff_y = 100;
    }
    move_origin( diff_x, diff_y );
  }

  /* Called whenever a printable character is entered in the drawing area */
  private void handle_printable( string str ) {
    if( is_mode_edit() && str.get_char( 0 ).isprint() ) {
      _current_node.edit_insert( str );
      adjust_origin();
      queue_draw();
      changed = true;
    }
  }

  /* Handle a key event */
  private bool on_keypress( EventKey event ) {
    if( _current_node != null ) {
      switch( event.keyval ) {
        case 65288 :  handle_backspace();  break;
        case 65535 :  handle_delete();     break;
        case 65307 :  handle_escape();     break;
        case 65293 :  handle_return();     break;
        case 65289 :  handle_tab();        break;
        case 65363 :  handle_right();      break;
        case 65361 :  handle_left();       break;
        case 65360 :  handle_home();       break;
        case 65367 :  handle_end();        break;
        case 65362 :  handle_up();         break;
        case 65364 :  handle_down();       break;
        case 65365 :  handle_pageup();     break;
        case 65366 :  handle_pagedn();     break;
        default :
          //if( !event.str.get_char( 0 ).isprint() ) {
          //  stdout.printf( "In on_keypress, keyval: %s\n", event.keyval.to_string() );
          //}
          handle_printable( event.str );
          break;
      }
    }
    return( true );
  }

}
