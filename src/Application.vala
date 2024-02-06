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
using Gee;

public class Minder : Granite.Application {

  private const string INTERFACE_SCHEMA = "org.gnome.desktop.interface";

  private static bool                show_version = false;
  private static string?             open_file    = null;
  private static bool                new_file     = false;
  private static bool                testing      = false;
  private        MainWindow          appwin;
  private        GLib.Settings       iface_settings;
  private        GLib.Settings       touch_settings;
  private        string?             cl_import    = null;
  private        string?             cl_export    = null;
  private        HashMap<string,int> cl_options;

  public  static GLib.Settings settings;
  public  static string        version = "1.16.2";

  public Minder () {

    Object( application_id: "com.github.phase1geo.minder", flags: ApplicationFlags.HANDLES_OPEN );

    Intl.setlocale( LocaleCategory.ALL, "" );
    Intl.bindtextdomain( GETTEXT_PACKAGE, LOCALEDIR );
    Intl.bind_textdomain_codeset( GETTEXT_PACKAGE, "UTF-8" );
    Intl.textdomain( GETTEXT_PACKAGE );

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

    /* If we are exporting from the command-line, do that now */
    if( cl_export != null ) {
      return;
    }

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

    /* Initialize desktop interface settings */
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

  /* Called whenever files need to be opened */
  private void open_files( File[] files, string hint ) {
    var input_file = files[0].get_path();
    hold();
    if( cl_import != null ) {
      int retval = 1;
      if( files.length >= 1 ) {
        if( !appwin.import_file( files[0].get_path(), cl_import, ref input_file ) ) {
          stderr.printf( _( "ERROR: Unable to import file" ) + "\n" );
          Process.exit( 1 );
        }
      } else {
        stderr.printf( _( "ERROR: Import is missing filename to import" ) + "\n" );
        Process.exit( 1 );
      }
    }
    if( cl_export != null ) {
      int retval = 0;
      if( files.length == 2 ) {
        if( export_as( cl_export, cl_options, input_file, files[1].get_path() ) ) {
          retval = 1;
        }
        if( cl_import != null ) {
          appwin.close_current_tab();
          FileUtils.unlink( input_file );  // Delete the file if we were just doing a conversion
        }
      } else {
        stderr.printf( _( "ERROR: Export is missing input file and/or export output file" ) + "\n" );
      }
      Process.exit( retval );
    } else if( cl_import == null ) {
      foreach( File open_file in files ) {
        var file = open_file.get_path();
        if( !appwin.open_file( file, false ) ) {
          stdout.printf( _( "ERROR:  Unable to open file '%s'\n" ), file );
        }
      }
    }
    Gtk.main();
    release();
  }

  /* Called if we have no files to open */
  protected override void activate() {
    if( cl_export == null ) {
      hold();
      if( new_file ) {
        appwin.do_new_file();
      }
      Gtk.main();
      release();
    }
  }

  /* Parse the command-line arguments */
  private void parse_arguments( ref unowned string[] args ) {

    var context     = new OptionContext( "- Minder Options" );
    var options     = new OptionEntry[10];
    var transparent = false;
    var compression = 0;
    var quality     = 0;
    var image_links = false;
    var exports     = new Exports();
    var import_list = new Array<string>();
    var export_list = new Array<string>();

    /* Get the list of import and export formats */
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

    /* Create the command-line options */
    options[0] = {"version", 0, 0, OptionArg.NONE, ref show_version, _( "Display version number" ), null};
    options[1] = {"new", 'n', 0, OptionArg.NONE, ref new_file, _( "Starts Minder with a new file" ), null};
    options[2] = {"run-tests", 0, 0, OptionArg.NONE, ref testing, _( "Run testing" ), null};
    options[3] = {"import", 0, 0, OptionArg.STRING, ref cl_import, import_str, "FORMAT"};
    options[4] = {"export", 0, 0, OptionArg.STRING, ref cl_export, export_str, "FORMAT"};
    options[5] = {"png-transparent", 0, 0, OptionArg.NONE, ref transparent, _( "Enables a transparent background for PNG images" ), null};
    options[6] = {"png-compression", 0, 0, OptionArg.INT, ref compression,  _( "PNG compression value (0-9)" ), "INT"};
    options[7] = {"jpeg-quality", 0, 0, OptionArg.INT, ref quality, _( "JPEG quality (0-100)" ), "INT"};
    options[8] = {"markdown-include-image-links", 0, 0, OptionArg.NONE, ref image_links, _( "Enables image links in exported Markdown" ), null};
    options[9] = {null};

    /* Parse the arguments */
    try {
      context.set_help_enabled( true );
      context.add_main_entries( options, null );
      context.parse( ref args );
    } catch( OptionError e ) {
      stdout.printf( _( "ERROR: %s\n" ), e.message );
      stdout.printf( _( "Run '%s --help' to see valid options\n" ), args[0] );
      Process.exit( 1 );
    }

    /* If the version was specified, output it and then exit */
    if( show_version ) {
      stdout.printf( version + "\n" );
      Process.exit( 0 );
    }

    /* Gather the export options if needed */
    if( cl_export != null ) {
      cl_options = new HashMap<string,int>();
      cl_options.set( "transparent",         (int)transparent );
      cl_options.set( "compression",         compression );
      cl_options.set( "quality",             quality );
      cl_options.set( "include-image-links", (int)image_links );
    }

    /* If we see files on the command-line */
    if( args.length >= 2 ) {
      open_file = args[1];
    }

  }

  /* Exports the given mindmap from the command-line */
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
        var da = appwin.create_da();
        da.get_doc().load_filename( infile, false );
        if( da.get_doc().load() ) {
          return( export.export( outfile, da ) );
        } else {
          stderr.printf( _( "ERROR:  Unable to load Minder input file %s" ).printf( infile ) + "\n" );
          return( false );
        }
      }
    }

    stderr.printf( "ERROR: Unknown export format: %s\n", format );

    return( false );

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

