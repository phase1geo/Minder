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

public class AnimatorFold : AnimatorAction {

  uint                      _num;
  private AnimatorPositions _pos;
  private AnimatorNodeAlpha _node;
  bool                      _fade_out;
  bool                      _deep;

  //-------------------------------------------------------------
  // Default constructor
  public AnimatorFold( DrawArea da, Array<Node> n, Node node, bool fade_out, bool deep, string name = "unnamed" ) {
    base( name, true );
    _num      = n.length;
    _pos      = new AnimatorPositions( n, false );
    _node     = new AnimatorNodeAlpha( da, node, fade_out, deep );
    _fade_out = fade_out;
    _deep     = deep;
  }

  //-------------------------------------------------------------
  // Returns the NODES types
  public override AnimationType type() {
    return( AnimationType.FOLD );
  }

  //-------------------------------------------------------------
  // Captures the end state
  public override void capture( DrawArea da ) {
    _pos.gather_new_positions();
    if( _fade_out ) {
      _node.node.folded = !_fade_out;
    }
    _node.gather_new_node_alpha( _fade_out );
  }

  //-------------------------------------------------------------
  // Adjusts all of the node positions for the given frame
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
    double dal = _node.new_alpha - _node.old_alpha;
    double al  = _node.old_alpha + (dal * divisor);
    for( int i=0; i<_node.node.children().length; i++ ) {
      _node.node.children().index( i ).alpha = al;
    }
  }

  //-------------------------------------------------------------
  // When the animation has completed, set the mode of all
  // callouts to hidden
  public override void on_completion( DrawArea da ) {
    if( _fade_out ) {
      _node.node.folded = _fade_out;
    }
  }

}

