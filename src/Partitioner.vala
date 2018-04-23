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

/*
 This class stores a pointer to a node to partition as well as its pixel size
 that is used for balancing purposes.
*/
public class PartNode : Object {

  private Node?  _node = null;
  private double _size;

  /* Creates a single partitioner node */
  public PartNode( Node n, Layout l ) {
    double x, y, w, h;
    l.bbox( n, -1, -1, out x, out y, out w, out h );
    if( (n.side == NodeSide.LEFT) || (n.side == NodeSide.RIGHT) ) {
      _size = h;
    } else {
      _size = w;
    }
    _node = n;
    stdout.printf( "Adding PartNode, name: %s, size: %g\n", n.name, _size );
  }

  /* Returns the size required by this node */
  public double size() { return( _size ); }

  public Node? node() { return( _node ); }

  /* Updates the node based on the given information */
  public void update_node( Node root, int index, int side, Layout layout ) {
    _node.detach( _node.side, layout );
    if( (_node.side == NodeSide.LEFT) || (_node.side == NodeSide.RIGHT) ) {
      _node.side = (side == 0) ? NodeSide.LEFT : NodeSide.RIGHT;
    } else {
      _node.side = (side == 0) ? NodeSide.TOP  : NodeSide.BOTTOM;
    }
    _node.attach( root, index, layout );
  }

}

/*
 Main class used for root node balancing.  This class uses a greedy partioning
 algorithm to provide node balancing.
*/
public class Partitioner : Object {

  /* Default constructor */
  public Partitioner() {}

  /* Partitions the given root node */
  public void partition_node( Node root, Layout layout ) {
    if( root.children().length > 2 ) {
      var data = new Array<PartNode>();
      for( int i=0; i<root.children().length; i++ ) {
        var pn = new PartNode( root.children().index( i ), layout );
        data.append_val( pn );
      }
      stdout.printf( "Full list\n" );
      for( int i=0; i<data.length; i++ ) {
        stdout.printf( "  n.name: %s, size: %g\n", data.index( i ).node().name, data.index( i ).size() );
      }
      CompareFunc<PartNode> pn_cmp = (a, b) => {
        return( (a.size() < b.size()) ? 1 : ((a.size() == b.size()) ? 0 : -1) );
      };
      stdout.printf( "HERE A\n" );
      data.sort( pn_cmp );
      stdout.printf( "HERE B\n" );
      partition( root, data, layout );
      stdout.printf( "HERE C\n" );
    }
  }

  /*
   Performs a greedy algorithm for node balancing. This is not an optimal
   algorithm (unlike the KK number partioning algorithm), but it is simple
   to implement and I'm not sure that it really matters that we are completely
   optimal anyways.
  */
  protected virtual void partition( Node root, Array<PartNode> data, Layout layout ) {
    double sum0 = 0;
    double sum1 = 0;
    for( int i=0; i<data.length; i++ ) {
      if( sum0 < sum1 ) {
        sum0 += data.index( i ).size();
        data.index( i ).update_node( root, i, 0, layout );
      } else {
        sum1 += data.index( i ).size();
        data.index( i ).update_node( root, i, 1, layout );
      }
    }
  }

}
