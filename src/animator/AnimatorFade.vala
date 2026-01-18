/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

public class AnimatorFade : AnimatorAction {

  uint                      _num;
  private AnimatorPositions _pos;
  private AnimatorCallouts  _callouts;
  bool                      _fade_out;

  /* Default constructor */
  public AnimatorFade( DrawArea da, Array<Node> n, bool fade_out, string name = "unnamed" ) {
    base( name, true );
    _num      = n.length;
    _pos      = new AnimatorPositions( n, false );
    _callouts = new AnimatorCallouts( da, n, fade_out );
    _fade_out = fade_out;
  }

  /* Returns the NODES types */
  public override AnimationType type() {
    return( AnimationType.FADE );
  }

  /* Captures the end state */
  public override void capture( DrawArea da ) {
    _pos.gather_new_positions();
    _callouts.gather_new_callout_alphas( _fade_out );
  }

  /* Adjusts all of the node positions for the given frame */
  public override void adjust( DrawArea da ) {
    double divisor = index / frames;
    index++;
    for( int i=0; i<_pos.length(); i++ ) {
      double dx = _pos.new_x( i ) - _pos.old_x( i );
      double dy = _pos.new_y( i ) - _pos.old_y( i );
      double x  = _pos.old_x( i ) + (dx * divisor);
      double y  = _pos.old_y( i ) + (dy * divisor);
      _pos.node( i ).posx = x;
      _pos.node( i ).posy = y;
      _pos.node( i ).side = _pos.node( i ).layout.get_side( _pos.node( i ) );
    }
    for( int i=0; i<_callouts.length(); i++ ) {
      double dal = _callouts.new_alpha( i ) - _callouts.old_alpha( i );
      double al  = _callouts.old_alpha( i ) + (dal * divisor);
      _callouts.node( i ).callout.alpha = al;
    }
  }

  /* When the animation has completed, set the mode of all callouts to hidden */
  public override void on_completion( DrawArea da ) {
    if( _fade_out ) {
      for( int i=0; i<_callouts.length(); i++ ) {
        _callouts.node( i ).callout.mode = CalloutMode.HIDDEN;
      }
    }
  }

}

