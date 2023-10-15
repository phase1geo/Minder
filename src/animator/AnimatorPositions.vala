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

/*
 Helper class to the Animator class. This class should not
 be accessed outside of this file.
*/
public class AnimatorPositions : Object {

  private Array<double?> _old_x;
  private Array<double?> _old_y;
  private Array<double?> _new_x;
  private Array<double?> _new_y;
  private Array<Node?>   _node;

  /* Default constructor */
  public AnimatorPositions( DrawArea da, Array<Node> nodes ) {
    _old_x = new Array<double?>();
    _old_y = new Array<double?>();
    _new_x = new Array<double?>();
    _new_y = new Array<double?>();
    _node  = new Array<Node?>();
    for( int i=0; i<nodes.length; i++ ) {
      gather_old_positions( nodes.index( i ) );
    }
  }

  /*
   Gathers the nodes and their current positions and stores
   them into array structures.
  */
  private void gather_old_positions( Node n ) {
    _old_x.append_val( n.posx );
    _old_y.append_val( n.posy );
    _node.append_val( n );
    if( n.traversable() ) {
      for( int i=0; i<n.children().length; i++ ) {
        gather_old_positions( n.children().index( i ) );
      }
    }
  }

  /*
   Gathers the new node positions for the stored nodes.
  */
  public void gather_new_positions() {
    for( int i=0; i<_node.length; i++ ) {
      _new_x.append_val( _node.index( i ).posx );
      _new_y.append_val( _node.index( i ).posy );
    }
  }

  /* Returns the number of nodes in this structure */
  public uint length() {
    return( _node.length );
  }

  /* Returns the old X position at the given index */
  public double old_x( int index ) {
    return( _old_x.index( index ) );
  }

  /* Returns the old Y position at the given index */
  public double old_y( int index ) {
    return( _old_y.index( index ) );
  }

  /* Returns the new X position at the given index */
  public double new_x( int index ) {
    return( _new_x.index( index ) );
  }

  /* Returns the new Y position at the given index */
  public double new_y( int index ) {
    return( _new_y.index( index ) );
  }

  /* Returns the node at the given index */
  public Node node( int index ) {
    return( _node.index( index ) );
  }

}
