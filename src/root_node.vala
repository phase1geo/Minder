using Cairo;

public class RootNode : Node {

  /* Default constructor */
  public RootNode( Layout? layout ) {
    base( layout );
  }

  /* Constructor which initializes name */
  public RootNode.with_name( string name, Layout? layout ) {
    base.with_name( name, layout );
  }

  /* Returns -1 to indicate that this node is not a child of a parent node */
  public override int index() {
    return( -1 );
  }

  /* Calculates the point on the parent node to start a link */
  protected override void link_point( out double x, out double y ) {
    x = posx + (_width / 2);
    y = posy + (_height / 2);
  }

  /* Draws the rectangle around the root node */
  public void draw_rectangle( Context ctx, Theme theme ) {

    double r = 10.0;
    double h = _height + (_pady * 2);
    double w = _width  + (_padx * 2) + task_width() + note_width();

    /* Draw the rounded box around the text */
    set_context_color( ctx, theme.root_background );
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
    ctx.fill();

  }

  public void draw_task( Context ctx, Theme theme ) {
    draw_acc_task( ctx, theme.root_foreground );
  }

  public void draw_note( Context ctx, Theme theme ) {
    draw_common_note( ctx, theme.root_foreground );
  }

  /* Draws this node to the given canvas */
  public override void draw( Context ctx, Theme theme ) {
    draw_rectangle( ctx, theme );
    draw_name( ctx, theme );
    draw_task( ctx, theme );
    draw_note( ctx, theme );
  }

}
