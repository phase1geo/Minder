using Gtk;

public class Minder : Gtk.Application {

  public Minder () {
    Object( application_id: "com.github.phase1geo.Minder", flags: ApplicationFlags.FLAGS_NONE );
  }

  protected override void activate() {

    /* Create the main window */
    var appwin = new MainWindow( this );

    /* Run the main loop */
    Gtk.main();

  }

  /* Main routine which gets everything started */
  public static int main( string[] args ) {
    var app = new Minder();
    return( app.run( args ) );
  }

}

