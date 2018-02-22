using Gtk;

public class Node : Object {

  /* Member variables */
  private   Node   _parent = null;
  private   Node[] _children = {};
  private   int    _child_index = -1;
  protected int    _width = 100;  /* TBD - This should be derived */
  protected int    _height = 50;  /* TBD - This should be derived */

  /* Properties */
  public string name { get; set; default = ""; }
  public double posx { get; set; default = 0.0; }
  public double posy { get; set; default = 0.0; }
  public string note { get; set; default = ""; }

  /* Default constructor */
  public Node() {}

  /* Constructor initializing string */
  public Node.with_name( string n ) {
    this.name = n;
  }

  /* Returns true if the given cursor coordinates lies within this node */
  public bool is_within( double x, double y ) {
    return( (x >= posx) && (x < (posx + _width)) && (y >= posy) && (y < (posy + _height)) );
  }

  /* Detaches this node from its parent node */
  public virtual void detach() {
    if( _parent != null ) {
      // TEMPORARY this._parent._children.remove_index( this._child_index );
      this._parent = null;
    }
  }

  /* Attaches this node as a child of the given node */
  public virtual void attach( Node n ) {
    this._child_index = n._children.length;
    this._parent = n;
    // TEMPORARY n._children.append_val( this );
  }

  /* Draws the node font to the screen */
  public virtual void draw_name( Cairo.Context ctx ) {
    ctx.set_font_size( 12 );
    ctx.move_to( (posx + 10), (posy + 20) );
    ctx.set_source_rgba( 1, 1, 1, 1 );
    ctx.show_text( name );
  }

  /* Draws the node on the screen */
  public virtual void draw( Cairo.Context ctx ) {}

}
