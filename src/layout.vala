public class Layout : Object {

  protected double                _pc_gap = 100;  /* Parent/child gap */
  protected double                _sb_gap = 8;    /* Sibling gap */
  protected Pango.FontDescription _font_description = null;

  public string name { protected set; get; }
  public int    padx { protected set; get; default = 10; }
  public int    pady { protected set; get; default = 5; }
  public int    default_text_height { set; get; default = 0; }

  /* Default constructor */
  public Layout() {
    name = "Default";
    _font_description = new Pango.FontDescription();
    _font_description.set_family( "Sans" );
    _font_description.set_size( 11 * Pango.SCALE );
  }

  /* Adjusts the specified child to be a set distance from the parent */
  public virtual void add_child_of( Node parent, Node child ) {
    double x, y, w, h;
    double px, py, pw, ph;
    double cx, cy, cw, ch;
    double adjust;
    parent.bbox( out px, out py, out pw, out ph );
    child.bbox( out cx, out cy, out cw, out ch );
    if( ch == 0 ) {
      ch = default_text_height + (pady * 2);
    }
    adjust = 0 - ((ch + _sb_gap) / 2);
    if( parent.children().length == 0 ) {
      x = px;
      y = py;
      h = 0;
    } else {
      bbox( parent, 1, child.side, out x, out y, out w, out h );
    }
    if( child.side == 0 ) {
      child.posx = (x - _pc_gap) - cw;
      child.posy = y + h + (_sb_gap / 2) + adjust;
    } else {
      child.posx = (x + pw) + _pc_gap;
      child.posy = y + h + (_sb_gap / 2) + adjust;
    }
    do {
      adjust_tree( parent, child, child.side, 0, adjust );
      child  = parent;
      parent = parent.parent;
    } while( parent != null );
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
  public virtual void adjust_tree( Node parent, Node? child, int side, double xamount, double yamount ) {
    for( int i=0; i<parent.children().length; i++ ) {
      Node n = parent.children().index( i );
      if( (child != n) && (n.side == side) ) {
        n.posx += xamount;
        n.posy += yamount;
        adjust_tree( n, child, side, xamount, yamount );
      }
    }
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

  public Pango.FontDescription get_font_description() {
    return( _font_description );
  }

}
