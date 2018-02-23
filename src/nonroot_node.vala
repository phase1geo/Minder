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
    ctx.set_source_rgba( _color.red, _color.green, _color.blue, _color.alpha );
    ctx.set_line_width( 4 );
    ctx.move_to( posx, (posy + 30) );
    ctx.line_to( (posx + 100), (posy + 30) );
    ctx.stroke();
  }

  public override void draw( Context ctx ) {
    draw_name( ctx );
    draw_line( ctx );
  }

}
