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
    l.bbox( n, -1, out x, out y, out w, out h );
    if( (n.side == NodeSide.LEFT) || (n.side == NodeSide.RIGHT) ) {
      _size = h;
    } else {
      _size = w;
    }
    _node = n;
  }

  /* Returns the size required by this node */
  public double size() { return( _size ); }

  /* Returns the stored node */
  public Node? node() { return( _node ); }

  /* Updates the node based on the given information */
  public void update_node( Node root, int index, int side, Layout layout ) {
    NodeSide orig_side = _node.side;
    if( (_node.side == NodeSide.LEFT) || (_node.side == NodeSide.RIGHT) ) {
      _node.side = (side == 0) ? NodeSide.LEFT : NodeSide.RIGHT;
    } else {
      _node.side = (side == 0) ? NodeSide.TOP  : NodeSide.BOTTOM;
    }
    if( orig_side != _node.side ) {
      layout.propagate_side( _node, _node.side );
    }
    _node.attach( root, index, null, layout );
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
      var data = new SList<PartNode>();
      for( int i=0; i<root.children().length; i++ ) {
        var node = root.children().index( i );
        var pn   = new PartNode( node, layout );
        data.append( pn );
      }
      CompareFunc<PartNode> pn_cmp = (a, b) => {
        return( (a.size() < b.size()) ? 1 : ((a.size() == b.size()) ? 0 : -1) );
      };
      data.sort( pn_cmp );
      partition( root, data, layout );
    }
  }

  /*
   Performs a greedy algorithm for node balancing. This is not an optimal
   algorithm (unlike the KK number partioning algorithm), but it is simple
   to implement and I'm not sure that it really matters that we are completely
   optimal anyways.
  */
  protected virtual void partition( Node root, SList<PartNode> data, Layout layout ) {

    double sum0  = 0;
    double sum1  = 0;
    int    size0 = 0;

    /* Detach all of the nodes */
    data.@foreach((item) => {
      item.node().detach( item.node().side, layout );
    });

    /* Attach the nodes according to the side */
    data.@foreach((item) => {
      if( sum0 < sum1 ) {
        sum0 += item.size();
        item.update_node( root, size0, 0, layout );
        size0++;
      } else {
        sum1 += item.size();
        item.update_node( root, -1, 1, layout );
      }
    });

  }

}
