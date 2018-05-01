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

  private DrawArea           _da;
  private Node?              _node;
  private AnimationPositions _pos0;
  private AnimationPositions _pos1;
  private int.               _index;
  
  /* Default constructor */
  public Animator( DrawArea da ) {
    _da    = da;
    _node  = null;
    _pos0  = new AnimationPositions( _da );
    _index = 0;
  }
  
  /* Constructor for a specified node tree */
  public Animator.node( DrawArea da, Node n ) {
    _da.   = da;
    _node  = n;
    _pos0  = new AnimationPositions.node( _node );
    _index = 0;
  }
  
  /* User method which performs the animation */
  public void animate() {
    if( _node == null ) {
      _pos1 = new AnimationPositions( _da );
    } else {
      _pos1 = new AnimationPositions.node( _node );
    }
    animate_positions();
  }
  
  /* Perform the animation */
  private bool animate_positions() {
    double divisor = _index / 5.0;
    _index++;
    for( int i=0; i<pos0.length; i++ ) {
      double x = pos0.x( i ) + ((pos1.x( i ) - pos0.x( i )) * divisor);
      double y = pos0.y( i ) + ((pos1.y( i ) - pos0.y( i )) * divisor);
      pos0.node( i ).set_posx_only( x );
      pos0.node( i ).set_posy_only( y );
    }
    _da.queue_draw();
    Timeout.add( 100, this.animate_positions );
    return( false );
  }
  
}

/*
 Helper class to the Animator class. This class should not
 be accessed outside of this file.
*/
public class AnimationPositions : Object {

  private Array<double> _x;
  private Array<double> _y;
  private Array<Node>   _node;
  
  /* Default constructor */
  public AnimationPositions( DrawArea da ) {
    _x    = new Array<double>();
    _y    = new Array<double>();
    _node = new Array<Node>();
    for( int i=0; i<da.nodes().length; i++ ) {
      gather_positions( da.nodes().index( i ) );
    }
  }
  
  /* Constructor for a single node */
  public AnimationPositions( Node n ) {
    _x    = new Array<double>();
    _y    = new Array<double>();
    _node = new Array<node>();
    gather_positions( n );
  }
  
  /*
   Gathers the nodes and their current positions and stores
   them into array structures.
  */
  private gather_positions( Node n ) {
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
  public double node( int index ) {
    return( _node.index( index ) );
  }
  
}