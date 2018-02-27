using Cairo;

public class RootNode : Node {

  /* Default constructor */
  public RootNode() {}

  /* Constructor which initializes name */
  public RootNode.with_name( string name ) {
    base.with_name( name );
  }

  protected override void link_point( out double x, out double y ) {
    x = (posx - 15) + _width + 40;
    y = (posy - _height - 15) + ((_height / 2) + 10);
  }

  /* Draws the rectangle around the root node */
  public void draw_rectangle( Context ctx ) {

    double padx = 15;
    double pady = 15;
    double posx = this.posx - padx;
    double posy = (this.posy - _height) - pady;
    double r    = 10.0;
    double h    = _height + (pady * 2);
    double w    = _width  + (padx * 2);

    /* Draw the rounded box around the text */
    ctx.set_source_rgba( 1, 1, 1, 1 );
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
    ctx.stroke();

  }

  /* Draws this node to the given canvas */
  public override void draw( Context ctx ) {
    draw_name( ctx );
    draw_rectangle( ctx );
  }

}
