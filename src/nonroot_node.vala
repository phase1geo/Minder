using Gdk;
using Cairo;

public class NonrootNode : Node {

  public RGBA color { set; get; }

  /* Default constructor */
  public NonrootNode( RGBA color) {
    this.color = color;
  }

  public override void detach() {

  }

  public override void attach( Node n ) {

  }

  public void draw_line( Context ctx ) {

    /* Get the name boundaries */
    TextExtents extents;
    name_extents( ctx, out extents );

    double padx = 15;
    double posx = this.posx - padx;
    double posy = this.posy + 10;
    double w    = extents.width + (padx * 2);

    /* Draw the line under the text name */
    ctx.set_source_rgba( _color.red, _color.green, _color.blue, _color.alpha );
    ctx.set_line_width( 4 );
    ctx.move_to( posx, posy );
    ctx.line_to( (posx + w), posy );
    ctx.stroke();

  }

  public override void draw( Context ctx ) {
    draw_name( ctx );
    draw_line( ctx );
  }

}
