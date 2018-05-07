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

  private DrawArea              _da;            // Reference to canvas
  private Queue<AnimatorAction> _actions;       // Queue of animation actions to perform
  private const int             _timeout = 20;  // Number of milliseconds between frames (30 fps)
  private const double          _frames  = 10;  // Number of frames to animate (note: set to 1 to disable animation)

  public bool enable { set; get; default = true; }

  /* Default constructor */
  public Animator( DrawArea da ) {
    _da      = da;
    _actions = new Queue<AnimatorAction>();
  }

  /* Animates all of the nodes on the canvas */
  public void add_nodes( string name ) {
    _actions.push_tail( new AnimatorNodes( _da, null, name ) );
  }

  /* Animates the specified node on the canvas */
  public void add_node( Node n, string name ) {
    _actions.push_tail( new AnimatorNodes( _da, n, name ) );
  }

  /* Animates a change to the canvas scale */
  public void add_scale( string name ) {
    _actions.push_tail( new AnimatorScale( _da, name ) );
  }

  /* Animates a change to the canvas scale */
  public void add_pan( string name ) {
    _actions.push_tail( new AnimatorPan( _da, name ) );
  }

  /* User method which performs the animation */
  public void animate() {
    if( !enable ) return;
    if( _actions.length == 1 ) {
      Timeout.add( _timeout, animate_action );
    }
    _actions.peek_head().capture( _da );
    _actions.peek_head().adjust( _da );
  }

  /* Perform the animation */
  private bool animate_action() {
    _actions.peek_head().adjust( _da );
    if( _actions.peek_head().done() ) {
      _actions.pop_head();
    }
    _da.queue_draw();
    return( _actions.length > 0 );
  }

}

