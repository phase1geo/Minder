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
  public PartNode( Node n ) {
    var nb = n.tree_bbox;
    if( (n.side == NodeSide.LEFT) || (n.side == NodeSide.RIGHT) ) {
      _size = nb.height;
    } else {
      _size = nb.width;
    }
    _node = n;
  }

  /* Returns the size required by this node */
  public double size() { return( _size ); }

  /* Returns the stored node */
  public Node? node() { return( _node ); }

  /* Updates the node based on the given information */
  public void update_node( Node root, int index, int side ) {
    NodeSide orig_side = _node.side;
    if( (_node.side == NodeSide.LEFT) || (_node.side == NodeSide.RIGHT) ) {
      _node.side = (side == 0) ? NodeSide.LEFT : NodeSide.RIGHT;
    } else {
      _node.side = (side == 0) ? NodeSide.TOP  : NodeSide.BOTTOM;
    }
    if( orig_side != _node.side ) {
      _node.layout.propagate_side( _node, _node.side );
    }
    _node.attach_init( root, index );
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
  public void partition_node( Node root ) {
    if( root.children().length > 1 ) {
      var data = new SList<PartNode>();
      for( int i=0; i<root.children().length; i++ ) {
        var node = root.children().index( i );
        var pn   = new PartNode( node );
        data.append( pn );
      }
      CompareFunc<PartNode> pn_cmp1 = (a, b) => {
        return( (a.node().id() < b.node().id()) ? 1 : -1 );
      };
      CompareFunc<PartNode> pn_cmp2 = (a, b) => {
        return( (a.size() < b.size()) ? 1 : ((a.size() == b.size()) ? 0 : -1) );
      };
      data.sort( pn_cmp1 );
      data.sort( pn_cmp2 );
      partition( root, data );
    }
  }

  /*
   Performs a greedy algorithm for node balancing. This is not an optimal
   algorithm (unlike the KK number partioning algorithm), but it is simple
   to implement and I'm not sure that it really matters that we are completely
   optimal anyways.
  */
  protected virtual void partition( Node root, SList<PartNode> data ) {

    double sum0  = 0;
    double sum1  = 0;
    int    size0 = 0;

    /* Detach all of the nodes */
    data.@foreach((item) => {
      item.node().detach( item.node().side );
    });

    /* Attach the nodes according to the side */
    var last_side = -1;
    data.@foreach((item) => {
      var place_node = !item.node().is_summarized() || item.node().first_summarized();
      if( place_node ? (sum0 < sum1) : (last_side == 0) ) {
        sum0 += item.size();
        item.update_node( root, size0, 0 );
        size0++;
        last_side = 0;
      } else {
        sum1 += item.size();
        item.update_node( root, -1, 1 );
        last_side = 1;
      }
    });

  }

}
