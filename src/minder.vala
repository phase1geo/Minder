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
    app_window.set_default_size( 600, 400 );
    app_window.set_titlebar( header );
    app_window.set_border_width( 2 );
    app_window.destroy.connect( Gtk.main_quit );

    /* Create the canvas */
    GtkWidget* canvas = gtk_drawing_area_new();
    gtk_widget_set_size_request( canvas, 500, 500 );
    // g_signal_connect( canvas, "draw", G_CALLBACK( draw_callback ), NULL );

    var box = new Gtk.Box( Orientation.HORIZONTAL, 2 );
    box.pack_start( canvas );

    /*
    show_button.clicked.connect (() => {
      var notification = new Notification( _( "Hello World" ) );
      var icon = new GLib.ThemedIcon( "dialog-warning" );
      notification.set_icon( icon );
      notification.set_body( _( "This is my first notification!" ) );
      this.send_notification( "notify.app", notification );
    });
    */

    app_window.add( box );
    app_window.show_all();

    app_window.show();

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
