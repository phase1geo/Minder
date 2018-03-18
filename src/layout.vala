public class Layout : Object {

  protected double _pc_gap = 100;  /* Parent/child gap */
  protected double _sb_gap = 5;    /* Sibling gap */

  public string name { protected set; get; }
  public int    padx { protected set; get; default = 10; }
  public int    pady { protected set; get; default = 10; }

  /* Default constructor */
  public Layout() {
    name = "Default";
  }

  /* Adjusts the specified child to be a set distance from the parent */
  public virtual void add_child_of( Node parent, Node child ) {
    double x, y, w, h;
    double px, py, pw, ph;
    double cx, cy, cw, ch;
    parent.bbox( out px, out py, out pw, out ph );
    child.bbox( out cx, out cy, out cw, out ch );
    ch = 25;
    if( parent.children().length == 0 ) {
      x = px;
      y = py;
      h = 0;
    } else {
      bbox( parent, 1, out x, out y, out w, out h );
    }
    if( child.side == 0 ) {
      child.posx = (x - _pc_gap) - cw;
      child.posy = (y + h) + ((ch + _sb_gap) / 2);
    } else {
      child.posx = (x + pw) + _pc_gap;
      child.posy = (y + h)  + ((ch + _sb_gap) / 2);
    }
    adjust_tree( parent, 0, (0 - ((ch + _sb_gap) / 2)) );
  }

  /* Get the bbox for the given parent to the given depth */
  public virtual void bbox( Node parent, int depth, out double x, out double y, out double w, out double h ) {
    int num_children = parent.children().length;
    if( (depth == 0) || (num_children == 0) ) {
      parent.bbox( out x, out y, out w, out h );
    } else {
      double x0, y0, w0, h0, xl, yl, wl, hl;
      bbox( parent.children()[0],              (depth - 1), out x0, out y0, out w0, out h0 );
      bbox( parent.children()[num_children-1], (depth - 1), out xl, out yl, out wl, out hl );
      x = (parent.posx < x0) ? parent.posx : ((x0 < xl) ? x0 : xl);
      y = (parent.posy < y0) ? parent.posy : ((y0 < yl) ? y0 : yl);
      w = (x0 + w0) - x;
      h = (yl + hl) - y;
    }
  }

  /* Adjusts the given tree by the given amount */
  public virtual void adjust_tree( Node parent, double xamount, double yamount ) {
    foreach (Node child in parent.children()) {
      child.posx += xamount;
      child.posy += yamount;
      adjust_tree( child, xamount, yamount );
    }
  }

  /* Recursively sets the side property of this node and all children nodes */
  protected virtual void propagate_side( Node parent, int side ) {
    double px, py, pw, ph;
    parent.bbox( out px, out py, out pw, out ph );
    foreach (Node n in parent.children()) {
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

}
