/* * Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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
  private bool                  _running = false;
  private uint                  _id      = 0;   // ID of current Timeout call queued to run

  public bool enable { set; get; default = true; }

  /* Default constructor */
  public Animator( DrawArea da ) {
    _da      = da;
    _actions = new Queue<AnimatorAction>();
    _running = false;
  }

  /* Returns true if there is currently an animation in progress */
  public bool is_running() {
    return( _running );
  }

  /* Animates all of the specified nodes */
  public void add_nodes( Array<Node> n, string name ) {
    if( (_actions.length == 0) || (_actions.peek_tail().type() != AnimationType.NODES) ) {
      _actions.push_tail( new AnimatorNodes( _da, n, name ) );
    }
  }

  /* Animates the specified node on the canvas */
  public void add_node( Node n, string name ) {
    if( (_actions.length == 0) || (_actions.peek_tail().type() != AnimationType.NODE) ) {
      var ns = new Array<Node>();
      ns.append_val( n );
      _actions.push_tail( new AnimatorNodes( _da, ns, name ) );
    }
  }

  /* Animates a fade in/out on the given set of callouts */
  public void add_callouts_fade( Array<Node> n, bool fade_out, string name ) {
    if( (_actions.length == 0) || (_actions.peek_tail().type() != AnimationType.FADE) ) {
      _actions.push_tail( new AnimatorFade( _da, n, fade_out, name ) );
    }
  }

  /* Animates a change to the canvas scale */
  public void add_scale( string name ) {
    if( (_actions.length == 0) || (_actions.peek_tail().type() != AnimationType.SCALE) ) {
      _actions.push_tail( new AnimatorScale( _da, name ) );
    }
  }

  /* Animates a change to the canvas pan */
  public void add_pan( string name ) {
    if( (_actions.length == 0) || (_actions.peek_tail().type() != AnimationType.PAN) ) {
      _actions.push_tail( new AnimatorPan( _da, name ) );
    }
  }

  /* Animates a change to both the canvas scale and pan */
  public void add_pan_scale( string name ) {
    if( (_actions.length == 0) || (_actions.peek_tail().type() != AnimationType.PANSCALE) ) {
      _actions.push_tail( new AnimatorPanScale( _da, name ) );
    }
  }

  /* Animates a change to both the canvas scale while keeping a screen location stable */
  public void add_scale_in_place( string name, double ssx, double ssy ) {
    if( (_actions.length == 0) || (_actions.peek_tail().type() != AnimationType.PANSCALE) ) {
      _actions.push_tail( new AnimatorScaleInPlace( _da, name, ssx, ssy ) );
    }
  }

  /* Cancels the last add operation */
  public void cancel_last_add() {
    if( _actions.length > 0 ) {
      _actions.pop_tail();
    }
  }

  /*
   This should be called whenever the drawing area wants to queue an immediate draw.
   This function will force all of the queued animations to complete immediately.
  */
  public void flush() {
    if( _id > 0 ) {
      Source.remove( _id );
      _id = 0;
    }
    if( !_actions.is_empty() ) {
      var save_needed = false;
      while( !_actions.is_empty() ) {
        var action = _actions.pop_head();
        action.flush( _da );
        save_needed |= action.save();
      }
      _running = false;
      if( save_needed ) {
        _da.auto_save();
      }
      _da.queue_draw();
    }
  }

  /* User method which performs the animation */
  public void animate() {
    if( !enable ) {
      var save_needed = false;
      while( !_actions.is_empty() ) {
        var action = _actions.pop_head();
        save_needed |= action.save();
        action.on_completion( _da );
      }
      if( save_needed ) {
        _da.auto_save();
      }
      _da.queue_draw();
      return;
    }
    if( !_running ) {
      _running = true;
      _id = Timeout.add( _timeout, animate_action );
    }
    _actions.peek_tail().capture( _da );
    _actions.peek_tail().adjust( _da );
  }

  /* Perform the animation */
  private bool animate_action() {
    _actions.peek_head().adjust( _da );
    if( _actions.peek_head().done() ) {
      _actions.peek_head().on_completion( _da );
      if( _actions.peek_head().save() ) {
        _da.auto_save();
      }
      _actions.pop_head();
    }
    _da.queue_draw();
    if( _actions.length == 0 ) {
      _id = 0;
    }
    return( _running = (_actions.length > 0) );
  }

}

