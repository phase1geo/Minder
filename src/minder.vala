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

    /* Create title toolbar */
    var new_btn = new Button.from_icon_name( "document-new-symbolic", IconSize.SMALL_TOOLBAR );
    new_btn.set_tooltip_text( "New File" );
    header.pack_start( new_btn );

    var open_btn = new Button.from_icon_name( "document-open-symbolic", IconSize.SMALL_TOOLBAR );
    open_btn.set_tooltip_text( "Open File" );
    header.pack_start( open_btn );

    var save_btn = new Button.from_icon_name( "document-save-as-symbolic", IconSize.SMALL_TOOLBAR );
    save_btn.set_tooltip_text( "Save File As" );
    header.pack_start( save_btn );

    var opts_btn = new Button.from_icon_name( "applications-system-symbolic", IconSize.SMALL_TOOLBAR );
    opts_btn.set_tooltip_text( "Preferences" );
    header.pack_end( opts_btn );

    var xprt_btn = new Button.from_icon_name( "document-export-symbolic", IconSize.SMALL_TOOLBAR );
    xprt_btn.set_tooltip_text( "Export" );
    header.pack_end( xprt_btn );

    var zoom_btn = new Button.from_icon_name( "zoom-fit-best-symbolic", IconSize.SMALL_TOOLBAR );
    zoom_btn.set_tooltip_text( "Zoom" );
    header.pack_end( zoom_btn );

    /* Create the canvas */
    DrawArea da = new DrawArea();

    var box = new Gtk.ScrolledWindow( null, null );
    box.add_with_viewport( da );

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
