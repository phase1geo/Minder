/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using Gtk;
using Gdk;
using GLib;

public class Minder : Granite.Application {

  private static bool          show_version = false;
  private static string?       open_file    = null;
  private static bool          new_file     = false;
  private static bool          testing      = false;
  private        MainWindow    appwin;

  public  static GLib.Settings settings;
  public  static string        version = "1.12.3";

  public Minder () {

    Object( application_id: "com.github.phase1geo.minder", flags: ApplicationFlags.HANDLES_OPEN );

    startup.connect( start_application );
    open.connect( open_files );

  }

  /* First method called in the startup process */
  private void start_application() {

    /* Initialize the settings */
    settings = new GLib.Settings( "com.github.phase1geo.minder" );

    /* Add the application-specific icons */
    weak IconTheme default_theme = IconTheme.get_default();
    default_theme.add_resource_path( "/com/github/phase1geo/minder" );

    /* Create the main window */
    appwin = new MainWindow( this, settings );

    /* Load the tab data */
    appwin.load_tab_state();

    /* Handle any changes to the position of the window */
    appwin.configure_event.connect(() => {
      int root_x, root_y;
      int size_w, size_h;
      appwin.get_position( out root_x, out root_y );
      appwin.get_size( out size_w, out size_h );
      settings.set_int( "window-x", root_x );
      settings.set_int( "window-y", root_y );
      settings.set_int( "window-w", size_w );
      settings.set_int( "window-h", size_h );
      return( false );
    });

  }

  /* Called whenever files need to be opened */
  private void open_files( File[] files, string hint ) {
    hold();
    foreach( File open_file in files ) {
      var file = open_file.get_path();
      if( !appwin.open_file( file ) ) {
        stdout.printf( "ERROR:  Unable to open file '%s'\n", file );
      }
    }
    Gtk.main();
    release();
  }

  /* Called if we have no files to open */
  protected override void activate() {
    hold();
    if( new_file ) {
      appwin.do_new_file();
    }
    Gtk.main();
    release();
  }

  /* Parse the command-line arguments */
  private void parse_arguments( ref unowned string[] args ) {

    var context = new OptionContext( "- Minder Options" );
    var options = new OptionEntry[4];

    /* Create the command-line options */
    options[0] = {"version", 0, 0, OptionArg.NONE, ref show_version, "Display version number", null};
    options[1] = {"new", 'n', 0, OptionArg.NONE, ref new_file, "Starts Minder with a new file", null};
    options[2] = {"run-tests", 0, 0, OptionArg.NONE, ref testing, "Run testing", null};
    options[3] = {null};

    /* Parse the arguments */
    try {
      context.set_help_enabled( true );
      context.add_main_entries( options, null );
      context.parse( ref args );
    } catch( OptionError e ) {
      stdout.printf( "ERROR: %s\n", e.message );
      stdout.printf( "Run '%s --help' to see valid options\n", args[0] );
      Process.exit( 1 );
    }

    /* If the version was specified, output it and then exit */
    if( show_version ) {
      stdout.printf( version + "\n" );
      Process.exit( 0 );
    }

    /* If we see files on the command-line */
    if( args.length >= 2 ) {
      open_file = args[1];
    }

  }

  /* Main routine which gets everything started */
  public static int main( string[] args ) {

    var app = new Minder();
    app.parse_arguments( ref args );

    if( testing ) {
      Gtk.init( ref args );
      var testing = new App.Tests.Testing( args );
      Idle.add(() => {
        testing.run();
        Gtk.main_quit();
        return( false );
      });
      Gtk.main();
      return( 0 );
    } else {
      return( app.run( args ) );
    }

  }

}

