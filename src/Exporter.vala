/*
* Copyright (c) 2020 (https://github.com/phase1geo/Minder)
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

public class Exporter : Box {

  private Revealer _stack_reveal;
  private Stack    _stack;

  public signal void export_done();

  //-------------------------------------------------------------
  // Constructor
  public Exporter( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 0 );

    _stack = new Stack() {
      transition_type = StackTransitionType.NONE,
      hhomogeneous    = true,
      vhomogeneous    = false
    };

    // Populate the list of export types
    string[] export_types = {};
    for( int i=0; i<win.exports.length(); i++ ) {
      if( win.exports.index( i ).exportable ) {
        export_types += win.exports.index( i ).label;
        add_export( win, win.exports.index( i ) );
      }
    }

    var mb = new DropDown.from_strings( export_types ) {
      halign  = Align.FILL,
      hexpand = true
    };
    mb.notify["selected"].connect(() => {
      handle_mb_change( win.exports.index( (int)mb.selected ) );
    });

    var export = new Button.with_label( _( "Export…" ) ) {
      halign         = Align.END,
      tooltip_markup = Utils.tooltip_with_accel( _( "Export With Current Settings" ), "<Control>e" )
    };
    export.clicked.connect(() => {
      do_export( win );
      export_done();
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.append( mb );
    bbox.append( export );

    _stack_reveal = new Revealer() {
      child = _stack
    };

    append( bbox );
    append( _stack_reveal );

    /* Initialize the UI */
    var last = win.settings.get_string( "last-export" );
    mb.set_selected( win.exports.get_index_by_name( last ) );

  }

  //-------------------------------------------------------------
  // Handles a change to the export dropdown.
  private void handle_mb_change( Export export ) {
    _stack.visible_child_name  = export.name;
    _stack_reveal.reveal_child = export.settings_available();
    Minder.settings.set_string( "last-export", export.name );
  }

  //-------------------------------------------------------------
  // Add the given export
  private void add_export( MainWindow win, Export export ) {

    /* Add the page */
    var opts = new Grid() {
      margin_start       = 5,
      margin_end         = 5,
      margin_top         = 5,
      margin_bottom      = 5,
      column_homogeneous = true,
      row_spacing        = 5,
      column_spacing     = 5
    };
    export.add_all_settings( opts );

    var label = new Label( "<i>" + _( "Export Options" ) + "</i>" ) {
      use_markup = true
    };

    var frame = new Frame( null ) {
      label_widget  = label,
      label_xalign  = (float)0.5,
      margin_top    = 5,
      margin_bottom = 5,
      child         = opts
    };

    /* Add the options to the options stack */
    _stack.add_named( frame, export.name );

  }

  //-------------------------------------------------------------
  // Perform the export to a selected file.
  public void do_export_to_file( MainWindow win, Export export ) {

    var dialog = Utils.make_file_chooser( _( "Export As %s" ).printf( export.label ), _( "Export" ) );

    /* Set the default filename */
    var default_fname = Utils.rootname( win.get_current_map().doc.filename );
    dialog.set_initial_name( win.repair_filename( default_fname, export.extensions ) );

    var filters = new GLib.ListStore( typeof( FileFilter ) );

    /* Set the filter */
    FileFilter filter = new FileFilter();
    filter.set_filter_name( export.label );
    foreach( string extension in export.extensions ) {
      filter.add_pattern( "*" + extension );
    }

    dialog.set_filters( filters );

    dialog.save.begin( win, null, (obj, res) => {
      try {
        var file = dialog.save.end( res );
        if( file != null ) {
          var fname = file.get_path();
          export.export( fname = win.repair_filename( fname, export.extensions ), win.get_current_map() );
          win.notification( _( "Minder Export Completed" ), fname );
        }
      } catch( Error e ) {}
    });

  }

  //-------------------------------------------------------------
  // Perform the export to the clipboard.
  public void do_export_to_clipboard( MainWindow win, Export export ) {

    export.export( "", win.get_current_map() );
    win.notification( _( "Minder Export Completed" ), _( "Copied to clipboard" ) );

  }

  //-------------------------------------------------------------
  // Perform the export.
  public void do_export( MainWindow win ) {

    var name   = _stack.visible_child_name;
    var export = win.exports.get_by_name( name );

    if( export.send_to_clipboard() ) {
      do_export_to_clipboard( win, export );
    } else {
      do_export_to_file( win, export );
    }

  }

}


