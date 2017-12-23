int main( string[] args ) {

  Gtk.init( ref args );

  /* Create the main window */
  var win = new Gtk.Window();
  win.title = "Minder";
  win.set_border_width( 12 );
  win.set_position( Gtk.WindowPosition.CENTER );
  win.set_default_size( 600, 400 );
  win.destroy.connect( Gtk.main_quit );
  win.show_all();

  Gtk.main();

  return( 0 );

}
