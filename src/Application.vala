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
using GLib;

public class Minder : Granite.Application {

  private static bool    version   = false;
  private static string? open_file = null;
  private static bool    new_file  = false;

  public Minder () {
    Object( application_id: "com.github.phase1geo.Minder", flags: ApplicationFlags.FLAGS_NONE );
  }

  protected override void activate() {

    /* Create the main window */
    var appwin = new MainWindow( this );

    /* Handle the command-line options */
    if( open_file != null ) {
      if( !appwin.open_file( open_file ) ) {
        stdout.printf( "ERROR:  Unable to open file '%s'\n", open_file );
        Process.exit( 1 );
      }
    } else if( new_file ) {
      appwin.do_new_file();
    } else {
      /* TBD - Load the last file */
    }

    /* Run the main loop */
    Gtk.main();

  }

  /* Parse the command-line arguments */
  void parse_arguments( ref unowned string[] args ) {

    var context = new OptionContext( "- Minder Options" );
    var options = new OptionEntry[4];

    /* Create the command-line options */
    options[0] = {"version", 0, 0, OptionArg.NONE, ref version, "Display version number", null};
    options[1] = {"open", 'o', 0, OptionArg.FILENAME, ref open_file, "Open filename", "FILENAME"};
    options[2] = {"new", 'n', 0, OptionArg.NONE, ref new_file, "Starts Minder with a new file", null};
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
    if( version ) {
      stdout.printf( "1.0\n" );
      Process.exit( 0 );
    }

  }

  /* Main routine which gets everything started */
  public static int main( string[] args ) {
    var app = new Minder();
    app.parse_arguments( ref args );
    return( app.run( args ) );
  }

}

