public class Layout : Object {

  protected double                _pc_gap = 100;  /* Parent/child gap */
  protected double                _sb_gap = 8;    /* Sibling gap */
  protected Pango.FontDescription _font_description = null;

  public string name  { protected set; get; }
  public int    padx  { protected set; get; default = 10; }
  public int    pady  { protected set; get; default = 5; }
  public int    ipadx { protected set; get; default = 6; }
  public int    ipady { protected set; get; default = 3; }
  public int    default_text_height { set; get; default = 0; }

  /* Default constructor */
  public Layout() {
    name = "Default";
    _font_description = new Pango.FontDescription();
    _font_description.set_family( "Sans" );
    _font_description.set_size( 11 * Pango.SCALE );
  }

  /* Get the bbox for the given parent to the given depth */
  public virtual void bbox( Node parent, int depth, int side, out double x, out double y, out double w, out double h ) {
    uint num_children = parent.children().length;
    parent.bbox( out x, out y, out w, out h );
    if( (depth != 0) && (num_children != 0) ) {
      double cx, cy, cw, ch;
      double mw, mh;
      for( int i=0; i<parent.children().length; i++ ) {
        if( parent.children().index( i ).side == side ) {
          bbox( parent.children().index( i ), (depth - 1), side, out cx, out cy, out cw, out ch );
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

  /* Adjusts the given tree by the given amount */
  public virtual void adjust_tree( Node parent, int child_index, int side, bool both, double xamount, double yamount ) {
    for( int i=0; i<parent.children().length; i++ ) {
      if( i != child_index ) {
        Node n = parent.children().index( i );
        n.posx += xamount;
        n.posy += yamount;
        adjust_tree( n, -1, side, both, xamount, yamount );
      } else {
        xamount = 0 - xamount;
        yamount = 0 - yamount;
      }
    }
  }

  /* Adjust the entire tree */
  public virtual void adjust_tree_all( Node parent, int child_index, bool both, double xamount, double yamount ) {
    do {
      adjust_tree( parent, child_index, parent.children().index( child_index ).side, both, xamount, yamount );
      child_index = parent.index();
      parent      = parent.parent;
    } while( parent != null );
  }

  /* Recursively sets the side property of this node and all children nodes */
  protected virtual void propagate_side( Node parent, int side ) {
    double px, py, pw, ph;
    parent.bbox( out px, out py, out pw, out ph );
    for( int i=0; i<parent.children().length; i++ ) {
      Node n = parent.children().index( i );
      if( n.side != side ) {
        n.side = side;
        if( side == 0 ) {
          double cx, cy, cw, ch;
          n.bbox( out cx, out cy, out cw, out ch );
          n.posx = px - _pc_gap - cw;
        } else {
          n.posx = px + pw + _pc_gap;
        }
        propagate_side( n, side );
      }
    }
  }

  /* Sets the side values of the given node */
  public virtual void set_side( Node current ) {
    Node parent = current.parent;
    if( parent != null ) {
      double px, py, pw, ph;
      double cx, cy, cw, ch;
      while( parent.parent != null ) {
        parent = parent.parent;
      }
      parent.bbox(  out px, out py, out pw, out ph );
      current.bbox( out cx, out cy, out cw, out ch );
      int side = ((cx + (cw / 2)) > (px + (pw / 2))) ? 1 : 0;
      if( current.side != side ) {
        current.side = side;
        propagate_side( current, side );
      }
    }
  }

  /* Updates the layout when necessary when a node is edited */
  public virtual void handle_update_by_edit( Node n ) {
    double width_diff, height_diff;
    n.update_size( out width_diff, out height_diff );
    if( (n.parent != null) && (height_diff > 0) ) {
      adjust_tree_all( n.parent, n.index(), false, 0, height_diff );
    }
  }

  /* Adjusts the gap between the parent and child noes */
  private void set_pc_gap( Node n ) {
    double px, py, pw, ph;
    n.parent.bbox( out px, out py, out pw, out ph );
    if( n.side == 0 ) {
      double cx, cy, cw, ch;
      n.bbox( out cx, out cy, out cw, out ch );
      n.posx = px - (cw + _pc_gap);
    } else {
      n.posx = px + (pw + _pc_gap);
    }
  }

  /* Called when we are inserting a node within a parent */
  public virtual void handle_update_by_insert( Node parent, Node child, int pos ) {
    double cx, cy, cw, ch;
    double adjust;
    child.bbox( out cx, out cy, out cw, out ch );
    if( ch == 0 ) { ch = default_text_height + (pady * 2); }
    adjust = (ch + _sb_gap) / 2;
    set_pc_gap( child );
    if( parent.side_count( child.side ) == 1 ) {
      double px, py, pw, ph;
      parent.bbox( out px, out py, out pw, out ph );
      child.posy = py + ((ph / 2) - (ch / 2));
      return;
    } else if( ((pos + 1) == parent.children().length) || (parent.children().index( pos + 1 ).side != child.side) ) {
      double sx, sy, sw, sh;
      bbox( parent.children().index( pos - 1 ), -1, child.side, out sx, out sy, out sw, out sh );
      child.posy = sy + sh + _sb_gap - adjust;
    } else {
      double sx, sy, sw, sh;
      bbox( parent.children().index( pos + 1 ), -1, child.side, out sx, out sy, out sw, out sh );
      child.posy = sy - adjust;
    }
    adjust_tree_all( parent, pos, true, 0, (0 - adjust) );
  }

  /* Called to layout the leftover children of a parent node when a node is deleted */
  public virtual void handle_update_by_delete( Node parent, int index, int side, double xamount, double yamount ) {
    double adjust = (yamount + _sb_gap) / 2;
    for( int i=0; i<parent.children().length; i++ ) {
      if( parent.children().index( i ).side == side ) {
        if( i == index ) { adjust = (0 - adjust); }
        parent.children().index( i ).posy += adjust;
        adjust_tree_all( parent, i, true, 0, adjust );
      }
    }
  }

  public virtual void reposition( Node n, int from_index, int from_side ) {
    double x, y, w, h;
    Node parent   = n.parent;
    int  to_index = n.index();
    int  to_side  = n.side;
    bbox( n, -1, from_side, out x, out y, out w, out h );
    if( from_side != to_side ) {
      handle_update_by_delete( parent, from_index, from_side, 0, (h / 2) );
      handle_update_by_insert( parent, n, to_index );
    } else {
      /* TBD */
    }
  }

  public Pango.FontDescription get_font_description() {
    return( _font_description );
  }

}
