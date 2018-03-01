using Cairo;
using Gtk;

public class Document : Object {

  private string _fname;

  /* Default constructor */
  public Document() {
    _fname = "";
  }

  /* Returns true if this document has been previously saved */
  public bool prev_saved() {
    return( _fname != "" );
  }

  /* Opens the given filename */
  public bool load( string fname, DrawArea da ) {
    Xml.Doc* doc = Xml.Parser.parse_file( fname );
    if( doc == null ) {
      return( false );
    }
    da.load( doc->get_root_element() );
    delete doc;
    da.changed = false;
    _fname = fname;
    return( true );
  }

  /* Saves the given node information to the specified file */
  public bool save( string? fname, DrawArea da ) {
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "minder" );
    doc->set_root_element( root );
    da.save( root );
    doc->save_format_file( fname, 1 );
    delete doc;
    da.changed = false;
    _fname = fname ?? _fname;
    return( true );
  }

  /* Draws the page to the printer */
  public void draw_page( PrintOperation op, PrintContext context, int nr ) {

    Context ctx = context.get_cairo_context();
    double  w   = context.get_width();
    double  h   = context.get_height();

    ctx.set_source_rgb( 0.5, 0.5, 1 );
    ctx.rectangle( (w * 0.1), (h * 0.1), (w * 0.8), (h * 0.8) );
    ctx.stroke();

  }

}
