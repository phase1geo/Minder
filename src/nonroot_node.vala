public class NonrootNode : Node {

  /* Default constructor */
  public NonrootNode() {

  }

  public override void detach() {

  }

  public override void attach( Node n ) {

  }

  public override void draw( Cairo.Context ctx ) {
    draw_name( ctx );
  }

}
