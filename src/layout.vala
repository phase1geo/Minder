public class Layout : Object {

  public string name { private set; get; }

  /* Default constructor */
  public Layout() {
    name = "Default";
  }

  /* Adjusts the specified child to be a set distance from the parent */
  public virtual void place_child_of( Node parent, Node child ) {
    double x, y, w, h;
    parent.bbox( out x, out y, out w, out h );
    child.posx = (x + w) + 50;
  }

  /* Adjusts the spacing between the siblings of the given parent node */
  public virtual void place_siblings( Node parent ) {
    double px, py, pw, ph;
    parent.bbox( out px, out py, out pw, out ph );
    foreach (Node child in parent.children()) {
      place_child_of( parent, child );
      // TBD
    }
  }

}
