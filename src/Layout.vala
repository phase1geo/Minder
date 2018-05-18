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

  protected double                _pc_gap = 50;   /* Parent/child gap */
  protected double                _sb_gap = 8;    /* Sibling gap */
  protected double                _rt_gap = 100;  /* Root node gaps */
  protected Pango.FontDescription _font_description = null;

  public string name        { protected set; get; default = ""; }
  public string icon        { protected set; get; default = ""; }
  public bool   balanceable { protected set; get; default = false; }
  public int    padx        { protected set; get; default = 10; }
  public int    pady        { protected set; get; default = 5; }
  public int    ipadx       { protected set; get; default = 6; }
  public int    ipady       { protected set; get; default = 3; }
  public int    default_text_height { set; get; default = 0; }

  /* Default constructor */
  public Layout() {
    _font_description = new Pango.FontDescription();
    _font_description.set_family( "Sans" );
    _font_description.set_size( 11 * Pango.SCALE );
  }

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
  public void initialize( Node parent ) {
    var list = new SList<Node>();
    for( int i=0; i<parent.children().length; i++ ) {
      Node n = parent.children().index( i );
      initialize( n );
      n.side = side_mapping( n.side );
      list.append( n );
    }
    list.@foreach((item) => {
      item.detach( item.side, this );
    });
    list.@foreach((item) => {
      item.attach( parent, -1, this );
    });
  }

  /* Get the bbox for the given parent to the given depth */
  public virtual void bbox( Node parent, int side_mask, out double x, out double y, out double w, out double h ) {

    uint num_children = parent.children().length;

    parent.bbox( out x, out y, out w, out h );

    if( (num_children != 0) && !parent.folded ) {
      double cx, cy, cw, ch;
      double mw, mh;
      for( int i=0; i<parent.children().length; i++ ) {
        if( (parent.children().index( i ).side & side_mask) != 0 ) {
          bbox( parent.children().index( i ), side_mask, out cx, out cy, out cw, out ch );
          x  = (x < cx) ? x : cx;
          y  = (y < cy) ? y : cy;
          mw = (cx + cw) - x;
          mh = (cy + ch) - y;
          w  = (w < mw) ? mw : w;
          h  = (h < mh) ? mh : h;
        }
      }
    }

  }

  /*
   Calculate the adjustment difference of the given node's tree.
   If the returned value is positive, it indicates a growth occurred.
  */
  public double get_adjust( Node parent ) {

    /* Get the original tree size */
    double orig_tree_size = parent.tree_size;

    /* Calculate the new tree size, set it and get the size of the node itself */
    double x, y, w, h;
    bbox( parent, -1, out x, out y, out w, out h );
    parent.tree_size = ((parent.side & NodeSide.horizontal()) != 0) ? h : w;

    /* Return the growth difference */
    return( (orig_tree_size == 0) ? 0 : (parent.tree_size - orig_tree_size) );

  }

  /* Adjusts the given tree by the given amount */
  public virtual void adjust_tree( Node parent, int child_index, int side_mask, double amount ) {
    for( int i=0; i<parent.children().length; i++ ) {
      if( i != child_index ) {
        Node n = parent.children().index( i );
        if( (n.side & side_mask) != 0 ) {
          if( (n.side & NodeSide.horizontal()) != 0 ) {
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
  public virtual void adjust_tree_all( Node n, double amount ) {
    Node parent = n.parent;
    int  index  = n.index();
    while( parent != null ) {
      adjust_tree( parent, index, n.side, amount );
      amount = 0 - (get_adjust( parent ) / 2);
      index  = parent.index();
      parent = parent.parent;
    }
  }

  /* Recursively sets the side property of this node and all children nodes */
  public virtual void propagate_side( Node parent, NodeSide side ) {
    double px, py, pw, ph;
    parent.bbox( out px, out py, out pw, out ph );
    for( int i=0; i<parent.children().length; i++ ) {
      Node n = parent.children().index( i );
      if( n.side != side ) {
        n.side = side;
        switch( side ) {
          case NodeSide.LEFT :
            double cx, cy, cw, ch;
            n.bbox( out cx, out cy, out cw, out ch );
            n.posx = px - _pc_gap - cw;
            break;
          case NodeSide.RIGHT :
            n.posx = px + pw + _pc_gap;
            break;
          case NodeSide.TOP :
            double cx, cy, cw, ch;
            n.bbox( out cx, out cy, out cw, out ch );
            n.posy = py - _pc_gap - ch;
            break;
          case NodeSide.BOTTOM :
            n.posy = py + ph + _pc_gap;
            break;
        }
        propagate_side( n, side );
      }
    }
  }

  /* Returns the side of the given node relative to its parent */
  public virtual NodeSide get_side( Node n ) {
    double rx, ry, rw, rh;
    double nx, ny, nw, nh;
    n.get_root().bbox( out rx, out ry, out rw, out rh );
    n.bbox( out nx, out ny, out nw, out nh );
    if( (n.side & NodeSide.horizontal()) != 0 ) {
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

  /* Updates the layout when necessary when a node is edited */
  public virtual void handle_update_by_edit( Node n ) {
    double width_diff, height_diff;
    n.update_size( null, out width_diff, out height_diff );
    double adjust = 0 - (get_adjust( n ) / 2);
    if( (n.side & NodeSide.horizontal()) != 0 ) {
      if( (n.parent != null) && (height_diff != 0) ) {
        n.adjust_posy_only( 0 - (height_diff / 2) );
        adjust_tree_all( n, adjust );  // , (0 - (height_diff / 2)) );
      }
      if( width_diff != 0 ) {
        if( n.side == NodeSide.LEFT ) {
          n.posx -= width_diff;
        } else {
          for( int i=0; i<n.children().length; i++ ) {
            n.children().index( i ).posx += width_diff;
          }
        }
      }
    } else {
      if( (n.parent != null) && (width_diff != 0) ) {
        n.adjust_posx_only( 0 - (width_diff / 2) );
        adjust_tree_all( n, adjust ); // , (0 - (width_diff / 2)) );
      }
      if( height_diff != 0 ) {
        if( n.side == NodeSide.TOP ) {
          n.posy -= height_diff;
        } else {
          for( int i=0; i<n.children().length; i++ ) {
            n.children().index( i ).posy += height_diff;
          }
        }
      }
    }
  }

  /* Called when a node's fold indicator changes */
  public virtual void handle_update_by_fold( Node n ) {
    adjust_tree_all( n, (0 - (get_adjust( n ) / 2)) );
  }

  /* Adjusts the gap between the parent and child nodes */
  private void set_pc_gap( Node n ) {
    double px, py, pw, ph;
    n.parent.bbox( out px, out py, out pw, out ph );
    switch( n.side ) {
      case NodeSide.LEFT :
        double cx, cy, cw, ch;
        n.bbox( out cx, out cy, out cw, out ch );
        n.posx = px - (cw + _pc_gap);
        break;
      case NodeSide.RIGHT :
        n.posx = px + (pw + _pc_gap);
        break;
      case NodeSide.TOP :
        double cx, cy, cw, ch;
        n.bbox( out cx, out cy, out cw, out ch );
        n.posy = py - (ch + _pc_gap);
        break;
      case NodeSide.BOTTOM :
        n.posy = py + (ph + _pc_gap);
        break;
    }
  }

  /* Called when we are inserting a node within a parent */
  public virtual void handle_update_by_insert( Node parent, Node child, int pos ) {

    double ox, oy, ow, oh;
    double cx, cy, cw, ch;
    double adjust = (get_adjust( parent ) + _sb_gap) / 2;

    child.bbox( out ox, out oy, out ow, out oh );
    // if( oh == 0 ) { oh = default_text_height + (pady * 2); }
    bbox( child, child.side, out cx, out cy, out cw, out ch );
    // if( ch == 0 ) { ch = default_text_height + (pady * 2); }
    set_pc_gap( child );

    /*
     If we are the only child on our side, place ourselves on the same plane as the
     parent node
    */
    if( parent.side_count( child.side ) == 1 ) {
      double px, py, pw, ph;
      parent.bbox( out px, out py, out pw, out ph );
      if( (child.side & NodeSide.horizontal()) != 0 ) {
        child.posy = py + ((ph / 2) - (oh / 2));
      } else {
        child.posx = px + ((pw / 2) - (ow / 2));
      }
      return;

    /*
     If we are at the end of the list of children with the matching side as ours,
     place ourselves just below the next to last sibling.
    */
    } else if( ((pos + 1) == parent.children().length) || (parent.children().index( pos + 1 ).side != child.side) ) {
      double sx, sy, sw, sh;
      bbox( parent.children().index( pos - 1 ), child.side, out sx, out sy, out sw, out sh );
      if( (child.side & NodeSide.horizontal()) != 0 ) {
        child.posy = (sy + sh + _sb_gap + (oy - cy)) - adjust;
      } else {
        child.posx = (sx + sw + _sb_gap + (ox - cx)) - adjust;
      }

    /* Otherwise, place ourselves just above the next sibling */
    } else {
      double sx, sy, sw, sh;
      bbox( parent.children().index( pos + 1 ), child.side, out sx, out sy, out sw, out sh );
      if( (child.side & NodeSide.horizontal()) != 0 ) {
        child.posy = sy + (oy - cy) - adjust;
      } else {
        child.posx = sx + (ox - cx) - adjust;
      }
    }

    adjust_tree_all( child, (0 - adjust) );

  }

  /* Called to layout the leftover children of a parent node when a node is deleted */
  public virtual void handle_update_by_delete( Node parent, int index, NodeSide side ) {
    double adjust = (get_adjust( parent ) + _sb_gap) / 2;
    for( int i=0; i<parent.children().length; i++ ) {
      Node n = parent.children().index( i );
      if( n.side == side ) {
        double current_adjust = (i >= index) ? (0 - adjust) : adjust;
        if( (n.side & NodeSide.horizontal()) != 0 ) {
          n.posy += current_adjust;
        } else {
          n.posx += current_adjust;
        }
      }
    }
    if( parent.parent != null ) {
      adjust_tree_all( parent, adjust );
    }
  }

  /* Positions the given root node based on the position of the last node */
  public virtual void position_root( Node last, Node n ) {
    double x, y, w, h;
    bbox( last, -1, out x, out y, out w, out h );
    n.posx = last.posx;
    n.posy = y + h + _rt_gap;
  }

  /* Returns the font description associated with the layout */
  public Pango.FontDescription get_font_description() {
    return( _font_description );
  }

}
