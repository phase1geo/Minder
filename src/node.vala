using Gtk;
using Cairo;

public enum NodeMode {
  NONE = 0,
  SELECTED,
  EDITABLE
}

public class Node : Object {

  /* Member variables */
  private   Node   _parent = null;
  private   Node[] _children = {};
  private   int    _child_index = -1;
  protected int    _width = 100;  /* TBD - This should be derived */
  protected int    _height = 50;  /* TBD - This should be derived */

  /* Properties */
  public string   name { get; set; default = ""; }
  public double   posx { get; set; default = 0.0; }
  public double   posy { get; set; default = 0.0; }
  public string   note { get; set; default = ""; }
  public NodeMode mode { get; set; default = NodeMode.NONE; }

  /* Default constructor */
  public Node() {}

  /* Constructor initializing string */
  public Node.with_name( string n ) {
    this.name = n;
  }

  /* Returns true if the node does not have a parent */
  public bool is_root() {
    return( _parent == null );
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
  public virtual void draw_name( Context ctx ) {

    if( mode == NodeMode.SELECTED ) {
      ctx.set_source_rgba( 0.5, 0.5, 1, 1 );
      ctx.rectangle( posx, posy, 100, 30 );
      ctx.fill();
    }

    /* Output the text */
    ctx.set_font_size( 12 );
    ctx.move_to( (posx + 10), (posy + 20) );
    ctx.set_source_rgba( 1, 1, 1, 1 );
    ctx.show_text( name );

    if( mode == NodeMode.EDITABLE ) {
      ctx.show_text( "|" );
    }

  }

  /* Draws the node on the screen */
  public virtual void draw( Context ctx ) {}

}
