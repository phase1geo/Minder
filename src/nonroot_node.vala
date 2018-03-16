using Gdk;
using Cairo;

public class NonrootNode : Node {

  public int color_index { set; get; default = 0; }

  /* Default constructor */
  public NonrootNode() {}

  /* Loads the data from the input stream */
  public override void load( Xml.Node* n ) {

    /* Allow the base class to parse the node */
    base.load( n );

    /* Load the color value */
    string? c = n->get_prop( "color" );
    if( c != null ) {
      color_index = int.parse( c );
    }

  }

  /* Saves the current node */
  public override void save( Xml.Node* parent ) {
    Xml.Node* node = save_node();
    node->new_prop( "color", color_index.to_string() );
    parent->add_child( node );
  }

  /* Provides the point to link to children nodes */
  protected override void link_point( out double x, out double y ) {
    if( side == 0 ) {
      x = (posx - 15);
    } else {
      x = (posx + _width + 15);
    }
    y = (posy + 10);
  }

  /* Draws the line under the node name */
  public void draw_line( Context ctx, Theme theme, Layout layout ) {

    double padx  = 15;
    double posx  = this.posx - padx;
    double posy  = this.posy + 10;
    double w     = _width + (padx * 2);
    RGBA   color = theme.link_color( color_index );

    /* Draw the line under the text name */
    set_context_color( ctx, color );
    ctx.set_line_width( 4 );
    ctx.move_to( posx, posy );
    ctx.line_to( (posx + w), posy );
    ctx.stroke();

  }

  /* Draw the link from this node to the parent node */
  public void draw_link( Context ctx, Theme theme, Layout layout ) {

    double parent_x;
    double parent_y;
    RGBA   color = theme.link_color( color_index );

    /* Get the parent's link point */
    parent.link_point( out parent_x, out parent_y );

    set_context_color( ctx, color );
    ctx.set_line_width( 4 );
    ctx.move_to( parent_x, parent_y );
    if( side == 0 ) {
      ctx.line_to( (posx + _width + 15), (posy + 10) );
    } else {
      ctx.line_to( (posx - 15), (posy + 10) );
    }
    ctx.stroke();

  }

  /* Draws this node */
  public override void draw( Context ctx, Theme theme, Layout layout ) {
    draw_name( ctx, theme, layout );
    draw_line( ctx, theme, layout );
    draw_link( ctx, theme, layout );
  }

}
