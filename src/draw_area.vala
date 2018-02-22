using Gtk;
using Gdk;
using Cairo;

public class DrawArea : Gtk.DrawingArea {

  private double _press_x;
  private double _press_y;
  private bool   _pressed = false;
  private Node   _current_node;
  private Node[] _nodes;

  /* Default constructor */
  public DrawArea() {

    /* Add event listeners */
    this.draw.connect( on_draw );
    this.button_press_event.connect( on_press );
    this.motion_notify_event.connect( on_motion );
    this.button_release_event.connect( on_release );

    /* Make sure the above events are listened for */
    this.add_events( EventMask.BUTTON_PRESS_MASK | EventMask.BUTTON_RELEASE_MASK | EventMask.BUTTON1_MOTION_MASK );

    /* TEMPORARY */
    RootNode n = new RootNode.with_name( "Main Idea" );
    n.posx = 350;
    n.posy = 200;

    NonrootNode nr1 = new NonrootNode();
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
      _pressed = true;
      set_current_node( event.x, event.y );
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
    return( false );
  }

}
