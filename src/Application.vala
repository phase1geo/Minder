/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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
using Gee;

public class Minder : Gtk.Application {

  private const string INTERFACE_SCHEMA = "org.gnome.desktop.interface";

  private        MainWindow          appwin;
  private        GLib.Settings       iface_settings;
  private        GLib.Settings       touch_settings;

  public  static GLib.Settings settings;
  public  static string        version       = "2.0.0";
  public  static bool          debug         = false;
  public  static bool          debug_advance = false;
  public  static int           debug_count   = 0;

  //-------------------------------------------------------------
  // Default constructor
  public Minder () {

    Object( application_id: "com.github.phase1geo.minder", flags: ApplicationFlags.HANDLES_COMMAND_LINE );

    Intl.setlocale( LocaleCategory.ALL, "" );
    Intl.bindtextdomain( GETTEXT_PACKAGE, LOCALEDIR );
    Intl.bind_textdomain_codeset( GETTEXT_PACKAGE, "UTF-8" );
    Intl.textdomain( GETTEXT_PACKAGE );

    startup.connect( start_application );
    command_line.connect( handle_command_line );

  }

  //-------------------------------------------------------------
  // First method called in the startup process.
  private void start_application() {

    // Initialize the settings
    settings = new GLib.Settings( "com.github.phase1geo.minder" );

    // Add the application-specific icons
    weak IconTheme default_theme = IconTheme.get_for_display( Gdk.Display.get_default() );
    default_theme.add_resource_path( "/com/github/phase1geo/minder" );

    // Create the main window
    appwin = new MainWindow( this, settings );

    // Load the tab data
    appwin.load_tab_state();

    // Initialize desktop interface settings
    string[] names = {"font-name", "text-scaling-factor"};
    iface_settings = new GLib.Settings( INTERFACE_SCHEMA );
    foreach( string name in names ) {
      iface_settings.changed[name].connect(() => {
        Timeout.add( 500, () => {
          appwin.update_node_sizes();
          return( Source.REMOVE );
        });
      });
    }

  }

  //-------------------------------------------------------------
  // Called when the command-line argument handler exits.
  private int end_cl( ApplicationCommandLine cl, int status ) {
    // If we are the primary instance, exit now
    if( !cl.get_is_remote() ) {
      Process.exit( status );
    } else {
      cl.set_exit_status( status );
      cl.done();
    }
    return( status );
  }

  //-------------------------------------------------------------
  // Parse the command-line arguments.
  private int handle_command_line( ApplicationCommandLine cl ) {

    string? open_file = null;
    string? cl_import = null;
    string? cl_export = null;

    var context      = new OptionContext( "[files]" );
    var options      = new OptionEntry[10];
    var transparent  = false;
    var compression  = 0;
    var quality      = 90;
    var image_links  = false;
    var exports      = new Exports();
    var import_list  = new Array<string>();
    var export_list  = new Array<string>();
    var show_version = false;
    var show_help    = false;
    var new_file     = false;

    // Get the list of import and export formats
    for( int i=0; i<exports.length(); i++ ) {
      var export = exports.index( i );
      if( export.importable ) {
        import_list.append_val( export.name );
      }
      if( export.exportable ) {
        export_list.append_val( export.name );
      }
    }

    var import_str = _( "Import file from format (%s)" ).printf( string.joinv( ",", import_list.data ) );
    var export_str = _( "Export mindmap as format (%s)" ).printf( string.joinv( ",", export_list.data ) );

    var args = cl.get_arguments();

    // Create the command-line options
    options[0] = {"version", 0, 0, OptionArg.NONE, ref show_version, _( "Display version number" ), null};
    options[1] = {"help", 0, 0, OptionArg.NONE, ref show_help, _( "Display help" ), null};
    options[2] = {"new", 'n', 0, OptionArg.NONE, ref new_file, _( "Starts Minder with a new file" ), null};
    options[3] = {"import", 0, 0, OptionArg.STRING, ref cl_import, import_str, "FORMAT"};
    options[4] = {"export", 0, 0, OptionArg.STRING, ref cl_export, export_str, "FORMAT"};
    options[5] = {"png-transparent", 0, 0, OptionArg.NONE, ref transparent, _( "Enables a transparent background for PNG images.  Default is no transparency." ), null};
    options[6] = {"png-compression", 0, 0, OptionArg.INT, ref compression,  _( "PNG compression value (0-9). Default is 0." ), "INT"};
    options[7] = {"jpeg-quality", 0, 0, OptionArg.INT, ref quality, _( "JPEG quality (0-100). Default is 90." ), "INT"};
    options[8] = {"markdown-include-image-links", 0, 0, OptionArg.NONE, ref image_links, _( "Enables image links in exported Markdown" ), null};
    options[9] = {null};

    // Parse the arguments
    try {
      context.set_help_enabled( false );
      context.add_main_entries( options, null );
      context.parse_strv( ref args );
    } catch( OptionError e ) {
      stdout.printf( _( "ERROR: %s\n" ), e.message );
      stdout.printf( _( "Run '%s --help' to see valid options\n" ), args[0] );
      return( end_cl( cl, 1 ) );
    }

    if( show_help ) {
      stdout.printf( context.get_help( true, null ) );
      return( end_cl( cl, 0 ) );
    }

    // If the version was specified, output it and then exit
    if( show_version ) {
      stdout.printf( version + "\n" );
      return( end_cl( cl, 0 ) );
    }

    // If we see files on the command-line
    if( args.length >= 2 ) {
      open_file = args[1];
    }

    if( cl_import != null ) {
      if( args.length >= 2 ) {
        if( !appwin.import_file( open_file, cl_import, ref open_file ) ) {
          stderr.printf( _( "ERROR: Unable to import file" ) + "\n" );
          return( end_cl( cl, 1 ) );
        }
      } else {
        stderr.printf( _( "ERROR: Import is missing filename to import" ) + "\n" );
        return( end_cl( cl, 1 ) );
      }
    }

    if( cl_export != null ) {
      int retval = 0;
      var cl_options = new HashMap<string,int>();
      cl_options.set( "transparent",         (int)transparent );
      cl_options.set( "compression",         compression );
      cl_options.set( "quality",             quality );
      cl_options.set( "include-image-links", (int)image_links );
      if( args.length == 3 ) {
        if( export_as( cl_export, cl_options, open_file, args[2] ) ) {
          stdout.printf( "Successfully exported %s!\n", args[2] );
        } else {
          retval = 1;
        }
        if( cl_import != null ) {
          appwin.close_current_tab();
          FileUtils.unlink( open_file );  // Delete the file if we were just doing a conversion
        }
      } else {
        stderr.printf( _( "ERROR: Export is missing input file and/or export output file" ) + "\n" );
      }
      return( end_cl( cl, retval ) );
    } else if( cl_import == null ) {
      if( new_file ) {
        appwin.do_new_file();
      } else {
        for( int i=1; i<args.length; i++ ) {
          var file = args[i];
          if( !appwin.open_file( file, false ) ) {
            stdout.printf( _( "ERROR:  Unable to open file '%s'\n" ), file );
          }
        }
      }
      appwin.present();
    }

    return( 0 );

  }

  //-------------------------------------------------------------
  // Exports the given mindmap from the command-line.
  private bool export_as( string format, HashMap<string,int> options, string infile, string outfile ) {

    var exports = appwin.exports;

    for( int i=0; i<exports.length(); i++ ) {
      var export = exports.index( i );
      if( export.name == format ) {
        options.map_iterator().foreach((key,value) => {
          if( export.is_bool_setting( key ) ) {
            export.set_bool( key, (value > 0) );
          } else if( export.is_scale_setting( key ) ) {
            export.set_scale( key, value );
          }
          return( true );
        });
        var map = appwin.create_map();
        map.doc.load_filename( infile, false );
        map.doc.load( true, (loaded) => {
          if( loaded ) {
            export.export( outfile, map );
          } else {
            stderr.printf( _( "ERROR:  Unable to load Minder input file %s" ).printf( infile ) + "\n" );
          }
        });
      }
    }

    stderr.printf( "ERROR: Unknown export format: %s\n", format );

    return( false );

  }

  //-------------------------------------------------------------
  // Main routine which gets everything started.
  public static int main( string[] args ) {

    // Initialize the GtkSource infrastructure
    GtkSource.init();

    var app = new Minder();
    return( app.run( args ) );

  }

}

