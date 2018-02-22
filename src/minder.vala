using Gtk;

public class Minder : Gtk.Application {

  public Minder () {
    Object( application_id: "com.github.phase1geo.Minder", flags: ApplicationFlags.FLAGS_NONE );
  }

  protected override void activate () {

    var header = new HeaderBar();
    header.set_title( _( "Minder" ) );
    header.set_subtitle( _( "Mind-Mapping Application" ) );
    header.set_show_close_button( true );

    var app_window = new ApplicationWindow( this );
    app_window.title = _( "Minder" );
    app_window.set_position( Gtk.WindowPosition.CENTER );
    app_window.set_default_size( 800, 600 );
    app_window.set_titlebar( header );
    app_window.set_border_width( 2 );
    app_window.destroy.connect( Gtk.main_quit );

    /* Create the canvas */
    DrawArea da = new DrawArea();

    var box = new Gtk.Box( Orientation.HORIZONTAL, 2 );
    box.pack_start( da, true, true, 0 );

    /* Display the UI */
    app_window.add( box );
    app_window.show_all();
    app_window.show();

    /* Allow the loop to run */
    Gtk.main();

  }

  public static int main( string[] args ) {

    var app = new Minder();

    return app.run( args );

  }

}

/*
int main( string[] args ) {

  Gtk.init( ref args );

  // Create the main window
  win.show_all();

  Gtk.main();

  return( 0 );

}
*/
