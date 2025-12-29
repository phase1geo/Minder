/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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

//-------------------------------------------------------------
// Helper class to the Animator class. This class should not
// be accessed outside of this file.
public class AnimatorNodesAlpha : Object {

  private Array<double> _old_alpha;
  private Array<double> _new_alpha;
  private Array<Node>   _nodes;

  //-------------------------------------------------------------
  // Default constructor
  public AnimatorNodesAlpha( DrawArea da, Array<Node> nodes, Array<bool?> fade_out ) {
    _old_alpha = new Array<double>();
    _new_alpha = new Array<double>();
    _nodes     = new Array<Node>();
    for( int i=0; i<nodes.length; i++ ) {
      _old_alpha.append_val( fade_out.index( i ) ? nodes.index( i ).alpha : 0.0 );
      _nodes.append_val( nodes.index( i ) );
    }
  }

  //-------------------------------------------------------------
  // Gathers the new node positions for the stored nodes.
  public void gather_new_node_alpha( Array<bool?> fade_out ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _new_alpha.append_val( fade_out.index( i ) ? 0.0 : _nodes.index( i ).alpha );
    }
  }

  //-------------------------------------------------------------
  // Returns the number of nodes stored.
  public int length() {
    return( (int)_nodes.length );
  }

  //-------------------------------------------------------------
  // Returns the old alpha value of the given node index.
  public double old_alpha( int index ) {
    return( _old_alpha.index( index ) );
  }

  //-------------------------------------------------------------
  // Returns the new alpha value of the given node index.
  public double new_alpha( int index ) {
    return( _new_alpha.index( index ) );
  }

  //-------------------------------------------------------------
  // Returns the node at the given index.
  public Node node( int index ) {
    return( _nodes.index( index ) );
  }

}
