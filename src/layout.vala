public class Layout : Object {

  public string name { private set; get; }

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
    // child.bbox( out cx, out cy, out cw, out ch );
    ch = 25;
    bbox( parent, 1, out x, out y, out w, out h );
    child.posx = (x + pw) + 100;
    child.posy = (y + h)  + ((ch + 5) / 2);
    adjust_tree( parent, 0, (0 - ((ch + 5) / 2)) );
  }

  /* Get the bbox for the given parent to the given depth */
  public virtual void bbox( Node parent, int depth, out double x, out double y, out double w, out double h ) {
    int num_children = parent.children().length;
    if( (depth == 0) || (num_children == 0) ) {
      parent.bbox( out x, out y, out w, out h );
    } else {
      double x0, w0, h0, xl, yl, wl, hl;
      bbox( parent.children()[0],              (depth - 1), out x0, out y,  out w0,  out h0 );
      bbox( parent.children()[num_children-1], (depth - 1), out xl, out yl, out wl, out hl );
      x = parent.posx;
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

}
