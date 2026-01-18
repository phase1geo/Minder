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

public class AnimatorFold : AnimatorAction {

  private uint               _num;
  private AnimatorPositions  _pos;
  private AnimatorNodesAlpha _nodes;
  private Array<bool?>       _folds;

  //-------------------------------------------------------------
  // Default constructor
  public AnimatorFold( DrawArea da, Array<Node> n, Array<Node> nodes, string name = "unnamed" ) {
    base( name, true );
    _num   = n.length;
    _pos   = new AnimatorPositions( n, false );
    _folds = new Array<bool?>();
    for( int i=0; i<nodes.length; i++ ) {
      _folds.append_val( !nodes.index( i ).folded );
    }
    _nodes = new AnimatorNodesAlpha( da, nodes, _folds );
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
    for( int i=0; i<_folds.length; i++ ) {
      if( _folds.index( i ) ) {
        _nodes.node( i ).folded = false;
      }
    }
    _nodes.gather_new_node_alpha( _folds );
  }

  //-------------------------------------------------------------
  // Adjusts all of the node positions for the given frame
  public override void adjust( DrawArea da ) {
    double divisor = index / frames;
    index++;
    for( int i=0; i<_pos.length(); i++ ) {
      var dx = _pos.new_x( i ) - _pos.old_x( i );
      var dy = _pos.new_y( i ) - _pos.old_y( i );
      var x  = _pos.old_x( i ) + (dx * divisor);
      var y  = _pos.old_y( i ) + (dy * divisor);
      _pos.node( i ).posx = x;
      _pos.node( i ).posy = y;
      _pos.node( i ).side = _pos.node( i ).layout.get_side( _pos.node( i ) );
    }
    for( int i=0; i<_nodes.length(); i++ ) {
      var dal  = _nodes.new_alpha( i ) - _nodes.old_alpha( i );
      var al   = _nodes.old_alpha( i ) + (dal * divisor);
      var node = _nodes.node( i );
      for( int j=0; j<node.children().length; j++ ) {
        node.children().index( j ).alpha = al;
      }
    }
  }

  //-------------------------------------------------------------
  // When the animation has completed, set the mode of all
  // callouts to hidden
  public override void on_completion( DrawArea da ) {
    for( int i=0; i<_folds.length; i++ ) {
      if( _folds.index( i ) ) {
        _nodes.node( i ).folded = true;
      }
    }
  }

}

