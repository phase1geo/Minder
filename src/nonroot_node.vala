using Gdk;
using Cairo;

public class NonrootNode : Node {

  public RGBA color { set; get; }

  /* Default constructor */
  public NonrootNode( RGBA color) {
    this.color = color;
  }

  /* Loads the data from the input stream */
  public override bool load( DataInputStream stream ) {
    return( false );
  }

  /* Saves the current node */
  public override bool save( DataOutputStream stream, string prefix = "" ) {
    string attrs = "";
    attrs += (" color=\"" + color.to_string() + "\"");
    return( save_node( stream, prefix, attrs, "" ) );
  }

  /* Provides the point to link to children nodes */
  protected override void link_point( out double x, out double y ) {
    x = (posx + _width + 15);
    y = (posy + 10);
  }

  /* Draws the line under the node name */
  public void draw_line( Context ctx ) {

    double padx = 15;
    double posx = this.posx - padx;
    double posy = this.posy + 10;
    double w    = _width + (padx * 2);

    /* Draw the line under the text name */
    ctx.set_source_rgba( _color.red, _color.green, _color.blue, _color.alpha );
    ctx.set_line_width( 4 );
    ctx.move_to( posx, posy );
    ctx.line_to( (posx + w), posy );
    ctx.stroke();

  }

  /* Draw the link from this node to the parent node */
  public void draw_link( Context ctx ) {

    double parent_x;
    double parent_y;

    /* Get the parent's link point */
    parent.link_point( out parent_x, out parent_y );

    ctx.set_source_rgba( _color.red, _color.green, _color.blue, _color.alpha );
    ctx.set_line_width( 4 );
    ctx.move_to( parent_x, parent_y );
    ctx.line_to( (posx - 15), (posy + 10) );
    ctx.stroke();

  }

  /* Draws this node */
  public override void draw( Context ctx ) {
    draw_name( ctx );
    draw_line( ctx );
    draw_link( ctx );
  }

}
