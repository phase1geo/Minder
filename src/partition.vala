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
using Gee;

public class Partition : Object {

  public Partition() {}

  /* Make a partition of nodes from a graph, according to 'disjoin' and 'join' edges */
  private static void mk_part_II( Array<Array<int>> disjoin, Array<Array<int>> join, ref Array<int> p1, ref Array<int> p2, int? node ) {
    p1.append_val( node );
    for( int j=0; j<join[node].length; j++ ) {
      join[j].remove_index( node );
      mk_part_II( disjoin, join, ref p1, ref p2, j );
    }
    for( int j=0; j<join[node].length; j++ ) {
      disjoin[j].remove_index( node );
      mk_part_II( disjoin, join, ref p2, ref p1, j );
    }
  }

  /* Perform depth-first search for number partitioning, based on differencing method */
  private static void npp_dfs( int n, Array<int> label, ref Array<int> disjoin, ref Array<int> join, int remain, int bestobj, int LB ) {

    /*
    Arguments:
      n - number of items (on the current list)
      label - sorted list with pairs [(wi,i),...], where wi is the weight of item i
      disjoin - edges [(i,j),...] indicating that i and j must be in different partitions
      join - edges [(i,j),...] indicating that i and j must be in the same partition
      bestobj - objective value for the best known solution
      remain - sum of weights for current list of items
      LB - known lower bound (0 for even sum of weights, 1 for odd)
    */

    var opt = true;

    /* Check if current branch can be cut */
    d1,i1 = label.pop()
    slack = ((2 * d1) - remain);	// difference between largest item and sum of others

    if( (slack >= 0) or (abs(slack) == LB) ) {	// first item is larger that the sum of the others

      /* best solution that can be achieved = slack */
      if( slack >= bestobj ) {
        return opt, Infinity, None, None
      }

      /* First item must be in a partition, and remaining items in another */
      while( label != [] ) {
        d2,i2 = label.pop()
        disjoin.append( (i1,i2) );
      }

      /* Optimal solution found: first element == sum others */
      if( abs(slack) == LB ) {
        return opt, LB, disjoin, join
      }

      return opt, slack, disjoin, join;

    }

    d2,i2 = label.pop()

    /* Copy data structures */
    label_orig   = list(label)
    disjoin_orig = list(disjoin)
    join_orig    = list(join)

    /* FIRST BRANCH: try the same as differencing heuristic */
    insort( label, (d1-d2, i1) );
    disjoin.append( (i1,i2) ); 	// edge will force the two items in different partitions
    opt,obj1,disjoin1,join1 = npp_dfs( n-1, label, disjoin, join, remain-2*d2, bestobj, LB );	 // -(d1+d2)+(d1-d2) = -2*d2

    if( obj1 < bestobj ) {
      bestobj = obj1;
      if( bestobj <= LB ) {
        return opt,obj1,disjoin1,join1
      }
    }

    /* for 4 or less items, differencing is exact */
    if( (n <= 4) || !opt ) {
      return opt,obj1,disjoin1,join1
    }

    /* SECOND BRANCH: try the other possibility: put i1 and i2 on the same partition */
    insort( label_orig, (d1+d2, i1) );
    join_orig.append( (i1,i2) );	// to assure i1 and i2 will be in same partition
    opt,obj2,disjoin2,join2 = npp_dfs( n-1, label_orig, ref disjoin_orig, ref join_orig, remain, bestobj, LB );

    if( obj1 <= obj2 ) {
      return opt,obj1,disjoin1,join1
    }

    return opt,obj2,disjoin2,join2

  }

  /* Sums the remaining items in the data array */
  private static int sum( Array<int> data ) {
    var sum = 0;
    for( int i=0; i<data.length; i++ ) {
      sum += data.index( i );
    }
    return( sum );
  }

  public static void partition( Array<int> data, ref d1, ref d2 ) {

    /* Copy and sort data by decreasing order */
    data.sort((a,b) => {
      return( (a < b) ? b : a );
    });

    /* Initialize data for the differencing method's graph */
    var bestobj = 0xffffffff;
    var disjoin = new Array<int>(); 	// edges that force vertices to be in separate partitions
    var join    = new Array<int>();		// edges that force vertices to be in the same partition
    var remain  = sum( data );      	// remaining items/differences
    var LB      = remain & 1;       	// LB=1 for odd sums, 0 for even

    /* Call the depth-first recursion */
    npp_dfs( n, label, ref disjoin, ref join, remain, bestobj, LB );

    /* Make the partition, based on the disjoin/join edges */
    var p1 = new Array<int>();
    var p2 = new Array<int>();
    mk_part_II( adjacent( range(n), disjoin ), adjacent( range(n), join ), ref p1, ref p2, null );

    /* Make a list with the weights for each partition */
    d1 = [data[i] for i in p1]
    d2 = [data[i] for i in p2]
    return opt, obj, d1, d2

  }

}
