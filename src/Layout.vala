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

public class Layout : Object {

  protected double _rt_gap = 100;  /* Root node gaps */

  public string name        { protected set; get; default = ""; }
  public string icon        { protected set; get; default = ""; }
  public bool   balanceable { protected set; get; default = false; }

  /* Default constructor */
  public Layout() {}

  /*
   Virtual function used to map a node's side to its new side when this
   layout is applied.
  */
  public virtual NodeSide side_mapping( NodeSide side ) {
    switch( side ) {
      case NodeSide.LEFT   :  return( NodeSide.LEFT );
      case NodeSide.RIGHT  :  return( NodeSide.RIGHT );
      case NodeSide.TOP    :  return( NodeSide.LEFT );
      case NodeSide.BOTTOM :  return( NodeSide.RIGHT );
    }
    return( NodeSide.RIGHT );
  }

  /* Initializes the given node based on this layout */
  public virtual void initialize( Node parent ) {
    var list = new SList<Node>();
    parent.side = side_mapping( parent.side );
    if( parent.traversable() ) {
      for( int i=0; i<parent.children().length; i++ ) {
        var n = parent.children().index( i );
        initialize( n );
        if( !n.is_summary() ) {
          list.append( n );
        }
      }
      list.@foreach((item) => {
        item.detach( item.side );
      });
      list.@foreach((item) => {
        item.attach_init( parent, -1 );
      });
      if( parent.last_summarized() ) {
        parent.summary_node().nodes_changed( 0, 0 );
      }
    }
  }

  /* Get the bbox for the given parent to the given depth */
  public virtual NodeBounds bbox( Node parent, int side_mask ) {

    uint num_children = parent.children().length;

    double px, py, pw, ph;
    parent.bbox( out px, out py, out pw, out ph );

    var nb = new NodeBounds.with_bounds( parent.da, px, py, pw, ph );

    double x2 = nb.x + nb.width;
    double y2 = nb.y + nb.height;

    if( (num_children != 0) && !parent.folded ) {
      for( int i=0; i<parent.children().length; i++ ) {
        if( ((parent.children().index( i ).side & side_mask) != 0) && !parent.children().index( i ).is_summary() ) {
          var cb = parent.children().index( i ).tree_bbox;
          nb.x  = (nb.x < cb.x) ? nb.x : cb.x;
          nb.y  = (nb.y < cb.y) ? nb.y : cb.y;
          x2 = (x2 < (cb.x + cb.width))  ? (cb.x + cb.width)  : x2;
          y2 = (y2 < (cb.y + cb.height)) ? (cb.y + cb.height) : y2;
        }
      }
    }

    nb.width  = (x2 - nb.x);
    nb.height = (y2 - nb.y);

    return( nb );

  }

  /* Updates the tree size */
  protected void update_tree_size( Node n ) {

    /* Get the node's tree dimensions */
    var nb = bbox( n, -1 );

    /* Store the newly calculated node bounds back to the node */
    n.tree_bbox = nb;

    /* Set the tree size in the node */
    n.tree_size = n.side.horizontal() ? nb.height : nb.width;

  }

  /*
   Calculate the adjustment difference of the given node's tree.
   If the returned value is positive, it indicates a growth occurred.
  */
  public double get_adjust( Node parent ) {

    double orig_tree_size = parent.tree_size;

    update_tree_size( parent );

    return( (orig_tree_size == 0) ? 0 : (parent.tree_size - orig_tree_size) );

  }

  /* Adjusts the given tree by the given amount */
  public virtual void adjust_tree( Node parent, int child_index, int side_mask, double amount ) {

    if( !parent.traversable() ) return;

    for( int i=0; i<parent.children().length; i++ ) {
      if( i != child_index ) {
        var n = parent.children().index( i );
        if( (n.side & side_mask) != 0 ) {
          if( n.side.horizontal() ) {
            n.posy += amount;
          } else {
            n.posx += amount;
          }
        }
      } else {
        amount = 0 - amount;
      }
    }

  }

  /* Adjust the entire tree */
  public virtual void adjust_tree_all( Node n, NodeBounds p, double amount, string msg ) {

    var parent = n.parent;
    var last   = n;
    var index  = n.index();
    var nodes  = n.da.get_nodes();
    var prev   = new NodeBounds.copy( p );

    while( parent != null ) {
      adjust_tree( parent, index, n.side, amount );
      prev.copy_from( parent.tree_bbox );
      amount = 0 - (get_adjust( parent ) / 2);
      index  = parent.index();
      last   = parent;
      parent = parent.parent;
    }

    for( int i=0; i<nodes.length; i++ ) {
      if( nodes.index( i ) == last ) {
        n.da.handle_tree_overlap( prev );
      }
    }

  }

  /* Recursively sets the side property of this node and all children nodes */
  public virtual void propagate_side( Node parent, NodeSide side ) {

    if( !parent.traversable() ) return;

    double px, py, pw, ph;
    var margin = parent.style.branch_margin;

    parent.bbox( out px, out py, out pw, out ph );

    for( int i=0; i<parent.children().length; i++ ) {
      Node n = parent.children().index( i );
      if( n.side != side ) {
        n.side = side;
        switch( side ) {
          case NodeSide.LEFT :
            double cx, cy, cw, ch;
            n.bbox( out cx, out cy, out cw, out ch );
            n.posx = px - margin - cw;
            break;
          case NodeSide.RIGHT :
            n.posx = px + pw + margin;
            break;
          case NodeSide.TOP :
            double cx, cy, cw, ch;
            n.bbox( out cx, out cy, out cw, out ch );
            n.posy = py - margin - ch;
            break;
          case NodeSide.BOTTOM :
            n.posy = py + ph + margin;
            break;
        }
        propagate_side( n, side );
      }
    }

  }

  /* Returns the side of the given node relative to its root */
  public virtual NodeSide get_side( Node n ) {
    double rx, ry, rw, rh;
    double nx, ny, nw, nh;
    n.get_root().bbox( out rx, out ry, out rw, out rh );
    n.bbox( out nx, out ny, out nw, out nh );
    if( n.side.horizontal() ) {
      return( ((nx + (nw / 2)) > (rx + (rw / 2))) ? NodeSide.RIGHT : NodeSide.LEFT );
    } else {
      return( ((ny + (nh / 2)) > (ry + (rh / 2))) ? NodeSide.BOTTOM : NodeSide.TOP );
    }
  }

  /* Sets the side values of the given node */
  public virtual void set_side( Node current ) {
    if( !current.is_root() ) {
      NodeSide side = get_side( current );
      if( current.side != side ) {
        current.side = side;
        propagate_side( current, side );
      }
    }
  }

  /* Adjusts the gap between the parent and child nodes */
  public void apply_margin( Node n ) {
    if( n.parent == null ) return;
    double px, py, pw, ph;
    var margin = n.parent.style.branch_margin;
    n.parent.bbox( out px, out py, out pw, out ph );
    switch( n.side ) {
      case NodeSide.LEFT :
        double cx, cy, cw, ch;
        n.bbox( out cx, out cy, out cw, out ch );
        n.posx = px - (cw + margin);
        break;
      case NodeSide.RIGHT :
        n.posx = px + (pw + margin) - n.parent.task_width();
        break;
      case NodeSide.TOP :
        double cx, cy, cw, ch;
        n.bbox( out cx, out cy, out cw, out ch );
        n.posy = py - (ch + margin);
        break;
      case NodeSide.BOTTOM :
        n.posy = py + (ph + margin);
        break;
    }
  }

  /* Updates the layout when necessary when a node is edited */
  public virtual void handle_update_by_edit( Node n, double diffw, double diffh ) {
    double adjust = 0 - (get_adjust( n ) / 2);
    if( n.side.horizontal() ) {
      if( diffh != 0 ) {
        n.adjust_posy_only( 0 - (diffh / 2) );
      }
      if( diffw != 0 ) {
        if( n.is_root() ) {
          n.adjust_posx_only( 0 - (diffw / 2) );
          for( int i=0; i<n.children().length; i++ ) {
            var child = n.children().index( i );
            if( child.side == NodeSide.LEFT ) {
              child.posx -= (diffw / 2);
            } else {
              child.posx += (diffw / 2);
            }
          }
        } else if( n.side == NodeSide.LEFT ) {
          n.posx -= diffw;
        } else {
          for( int i=0; i<n.children().length; i++ ) {
            n.children().index( i ).posx += diffw;
          }
        }
      }
    } else {
      if( diffw != 0 ) {
        n.adjust_posx_only( 0 - (diffw / 2) );
      }
      if( diffh != 0 ) {
        if( n.is_root() ) {
          n.posy -= (diffh / 2);
          for( int i=0; i<n.children().length; i++ ) {
            var child = n.children().index( i );
            if( n.side == NodeSide.TOP ) {
              child.posy -= (diffh / 2);
            } else {
              child.posy += (diffh / 2);
            }
          }
        } else if( n.side == NodeSide.TOP ) {
          n.posy -= diffh;
        } else {
          for( int i=0; i<n.children().length; i++ ) {
            n.children().index( i ).posy += diffh;
          }
        }
      }
    }
    adjust_tree_all( n, n.tree_bbox, adjust, "by_edit" );
  }

  /* Called when a node's fold indicator changes */
  public virtual void handle_update_by_fold( Node n ) {
    adjust_tree_all( n, n.tree_bbox, (0 - (get_adjust( n ) / 2)), "by_fold" );
  }

  /* Returns the adjustment value */
  protected virtual double get_insert_adjust( Node child ) {
    return( child.tree_size / 2 );
  }

  /* Called when we are inserting a node within a parent */
  public virtual void handle_update_by_insert( Node parent, Node child, int pos ) {

    double ox, oy, ow, oh;
    double adjust;

    update_tree_size( child );

    var cb = child.tree_bbox;

    child.bbox( out ox, out oy, out ow, out oh );
    apply_margin( child );
    adjust = get_insert_adjust( child );

    /*
     If we are the only child on our side, place ourselves on the same plane as the
     parent node
    */
    if( parent.side_count( child.side ) == 1 ) {
      double px, py, pw, ph;
      parent.bbox( out px, out py, out pw, out ph );
      if( child.side.horizontal() ) {
        child.posy = py + ((ph / 2) - (oh / 2));
      } else {
        child.posx = px + ((pw / 2) - (ow / 2));
      }

    /*
     If we are at the end of the list of children with the matching side as ours,
     place ourselves just below the next to last sibling.
    */
    } else if( ((pos + 1) == parent.children().length) || (parent.children().index( pos + 1 ).side != child.side) ) {
      var sb = bbox( parent.children().index( pos - 1 ), child.side );
      if( child.side.horizontal() ) {
        child.posy = (sb.y + sb.height + (oy - cb.y)) - adjust;
      } else {
        child.posx = (sb.x + sb.width + (ox - cb.x)) - adjust;
      }

    /* Otherwise, place ourselves just above the next sibling */
    } else {
      var sb = bbox( parent.children().index( pos + 1 ), child.side );
      if( child.side.horizontal() ) {
        child.posy = sb.y + (oy - cb.y) - adjust;
      } else {
        child.posx = sb.x + (ox - cb.x) - adjust;
      }
    }

    adjust_tree_all( child, child.tree_bbox, (0 - adjust), "by_insert" );

  }

  /* Called to layout the leftover children of a parent node when a node is deleted */
  public virtual void handle_update_by_delete( Node parent, int index, NodeSide side, double size ) {

    double adjust = size / 2;

    /* Adjust the parent's descendants */
    for( int i=0; i<parent.children().length; i++ ) {
      Node n = parent.children().index( i );
      if( n.side == side ) {
        double current_adjust = (i >= index) ? (0 - adjust) : adjust;
        if( n.side.horizontal() ) {
          n.posy += current_adjust;
        } else {
          n.posx += current_adjust;
        }
      }
    }

    /* Adjust the rest of the tree */
    adjust_tree_all( parent, parent.tree_bbox, (0 - (get_adjust( parent ) / 2)), "by_delete" );

  }

  /* Positions the given root node based on the position of the last node */
  public virtual void position_root( Node last, Node n ) {
    var nb = last.tree_bbox;
    n.posx = last.posx;
    n.posy = nb.y + nb.height + _rt_gap;
  }

}
