public class RootNode : Node {

  /* Default constructor */
  public RootNode() {
    // super.Node();
  }

  /* Constructor which initializes name */
  public RootNode.with_name( string name ) {
    base.with_name( name );
  }

  /* Draws the rectangle around the root node */
  public void draw_rectangle( Cairo.Context ctx ) {
    double r = 10.0;
    double h = _height;
    double w = _width;
    ctx.set_source_rgba( 0, 0, 0, 1 );
    ctx.set_line_width( 1 );
    ctx.move_to(posx+r,posy);                                  // Move to A
    ctx.line_to(posx+w-r,posy);                                // Straight line to B
    ctx.curve_to(posx+w,posy,posx+w,posy,posx+w,posy+r);       // Curve to C, Control points are both at Q
    ctx.line_to(posx+w,posy+h-r);                              // Move to D
    ctx.curve_to(posx+w,posy+h,posx+w,posy+h,posx+w-r,posy+h); // Curve to E
    ctx.line_to(posx+r,posy+h);                                // Line to F
    ctx.curve_to(posx,posy+h,posx,posy+h,posx,posy+h-r);       // Curve to G
    ctx.line_to(posx,posy+r);                                  // Line to H
    ctx.curve_to(posx,posy,posx,posy,posx+r,posy);             // Curve to A
    // ctx.close_path();
    ctx.stroke();
  }

  /* Draws this node to the given canvas */
  public override void draw( Cairo.Context ctx ) {
    draw_rectangle( ctx );
    draw_name( ctx );
  }

}
