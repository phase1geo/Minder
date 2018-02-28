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
    try {
      var file        = File.new_for_path( fname );
      var file_stream = file.read();
      var data_stream = new DataInputStream( file_stream );
      da.load( data_stream );
      da.changed = false;
      _fname = fname;
    } catch( Error e ) {
      stderr.printf( "Error: %s\n", e.message );
      return( false );
    }
    return( true );
  }

  /* Saves the given node information to the specified file */
  public bool save( string? fname, DrawArea da ) {
    try {
      var file = File.new_for_path( fname ?? _fname );
      {
        var file_stream = file.create( FileCreateFlags.NONE );
        var data_stream = new DataOutputStream( file_stream );
        da.save( data_stream );
        da.changed = false;
        _fname = fname ?? _fname;
      }
    } catch( Error e ) {
      stderr.printf( "Error: %s\n", e.message );
      return( false );
    }
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
