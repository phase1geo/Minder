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

using GLib;

public class Animator : Object {

  private DrawArea            _da;              // Reference to canvas
  private Node?               _node    = null;  // Reference to node to move (if null, we are moving everything on the canvas
  private AnimationPositions? _spos    = null;  // Node starting positions
  private AnimationPositions? _epos    = null;  // Node ending positions
  private double?             _sscale  = null;  // Starting scaling factor
  private double?             _escale  = null;  // Ending scaling factor
  private double?             _sox     = null;  // Starting x-origin
  private double?             _soy     = null;  // Starting y-origin
  private double?             _eox     = null;  // Ending x-origin
  private double?             _eoy     = null;  // Ending y-origin
  private int                 _index   = 1;     // Animation index
  private const int           _timeout = 20;    // Number of milliseconds between frames
  private const double        _frames  = 10;    // Number of frames to animate (note: set to 1 to disable animation)

  /* Default constructor */
  public Animator( DrawArea da ) {
    _da   = da;
    _da.stop_animation();
    _spos = new AnimationPositions( _da );
  }

  /* Constructor for a specified node tree */
  public Animator.node( DrawArea da, Node n ) {
    _da    = da;
    _da.stop_animation();
    _node  = n;
    _spos  = new AnimationPositions.for_node( _node );
    _index = 0;
  }

  /* Constructor for a scale change */
  public Animator.scale( DrawArea da ) {
    _da     = da;
    _da.stop_animation();
    _sscale = da.get_scale_factor();
    _da.get_origin( out _sox, out _soy );
  }

  /* User method which performs the animation */
  public void animate() {
    _da.stop_animation.connect( stop_animating );
    if( _node != null ) {
      _epos = new AnimationPositions.for_node( _node );
      animate_positions();
    } else if( _sscale != null ) {
      _escale = _da.get_scale_factor();
      _da.get_origin( out _eox, out _eoy );
      animate_scaling();
    } else {
      _epos = new AnimationPositions( _da );
      animate_positions();
    }
  }

  /* Perform the animation */
  private bool animate_positions() {
    double divisor = _index / _frames;
    _index++;
    for( int i=0; i<_spos.length; i++ ) {
      double x = _spos.x( i ) + ((_epos.x( i ) - _spos.x( i )) * divisor);
      double y = _spos.y( i ) + ((_epos.y( i ) - _spos.y( i )) * divisor);
      _spos.node( i ).set_posx_only( x );
      _spos.node( i ).set_posy_only( y );
    }
    _da.queue_draw();
    if( _index <= _frames ) {
      Timeout.add( _timeout, this.animate_positions );
    }
    return( false );
  }

  /* Animates the given scaling and origin changes */
  private bool animate_scaling() {
    double divisor = _index / _frames;
    _index++;
    double scale_factor = _sscale + ((_escale - _sscale) * divisor);
    double origin_x     = _sox    + ((_eox    - _sox)    * divisor);
    double origin_y     = _soy    + ((_eoy    - _soy)    * divisor);
    _da.set_scale_factor( scale_factor );
    _da.set_origin( origin_x, origin_y );
    _da.queue_draw();
    if( _index <= _frames ) {
      Timeout.add( _timeout, this.animate_scaling );
    }
    return( false );
  }

  /* Stops any active animations */
  private void stop_animating() {
    stdout.printf( "Stopping animation, index: %d\n", _index );
    _index = (int)_frames;
  }

}

/*
 Helper class to the Animator class. This class should not
 be accessed outside of this file.
*/
public class AnimationPositions : Object {

  private Array<double?> _x;
  private Array<double?> _y;
  private Array<Node?>   _node;

  public uint length {
    private set {}
    get {
      return( _node.length );
    }
  }

  /* Default constructor */
  public AnimationPositions( DrawArea da ) {
    _x    = new Array<double?>();
    _y    = new Array<double?>();
    _node = new Array<Node?>();
    for( int i=0; i<da.get_nodes().length; i++ ) {
      gather_positions( da.get_nodes().index( i ) );
    }
  }

  /* Constructor for a single node */
  public AnimationPositions.for_node( Node n ) {
    _x    = new Array<double?>();
    _y    = new Array<double?>();
    _node = new Array<Node?>();
    gather_positions( n );
  }

  /*
   Gathers the nodes and their current positions and stores
   them into array structures.
  */
  private void gather_positions( Node n ) {
    _x.append_val( n.posx );
    _y.append_val( n.posy );
    _node.append_val( n );
    for( int i=0; i<n.children().length; i++ ) {
      gather_positions( n.children().index( i ) );
    }
  }

  /* Returns the X position at the given index */
  public double x( int index ) {
    return( _x.index( index ) );
  }

  /* Returns the Y position at the given index */
  public double y( int index ) {
    return( _y.index( index ) );
  }

  /* Returns the node at the given index */
  public Node node( int index ) {
    return( _node.index( index ) );
  }

}
