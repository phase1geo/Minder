public class Node : Object {

  /* Member variables */
  private Node _parent = null;
  private Node _children[] = {};
  private int  _child_index = -1;
  private int  _width = 0;
  private int  _height = 0;

  /* Properties */
  public string name { get; set; default = ""; }
  public double posx { get; set; default = 0.0; }
  public double posy { get; set; default = 0.0; }

  /* Default constructor */
  public Node() {}

  /* Constructor initializing string */
  public Node.with_name( string n ) {
    this.name = n;
  }

  /* Detaches this node from its parent node */
  public virtual void detach() {
    if( _parent != null ) {
      this._parent._children.remove_index( this._child_index );
      this._parent = null;
    }
  }

  /* Attaches this node as a child of the given node */
  public virtual void attach( Node n ) {
    this._child_index = n._children.length;
    this._parent = n;
    n._children.append_val( this );
  }

  /* Draws the node on the screen */
  public virtual void draw() {}

}
