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

  private Array<double?> _x;
  private Array<double?> _y;
  private Array<Node?>   _node;

  /* Default constructor */
  public AnimatorPositions( DrawArea da, Node? n ) {
    _x    = new Array<double?>();
    _y    = new Array<double?>();
    _node = new Array<Node?>();
    if( n == null ) {
      for( int i=0; i<da.get_nodes().length; i++ ) {
        gather_positions( da.get_nodes().index( i ) );
      }
    } else {
      gather_positions( n );
    }
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

  /* Returns the number of nodes in this structure */
  public uint length() {
    return( _node.length );
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
