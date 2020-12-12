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

  private Notebook _nb;

  /* Constructor */
  public Exporter( MainWindow win, Gtk.Window parent ) {

    Object( orientation: Orientation.HORIZONTAL, spacing: 0 );

    _nb = new Notebook();
    _nb.scrollable = true;

    populate_notebook( win, parent );

    pack_start( _nb, true, true, 0 );

    show_all();

  }

  private void populate_notebook( MainWindow win, Gtk.Window parent ) {
    for( int i=0; i<win.exports.length(); i++ ) {
      if( win.exports.index( i ).exportable ) {
        add_export( win, parent, win.exports.index( i ) );
      }
    }
  }

  /* Add the given export */
  private void add_export( MainWindow win, Gtk.Window parent, Export export ) {

    /* Create the button bar at the bottom of the page */
    var ebtn  = new Button.with_label( _( "Export" ) );
    ebtn.get_style_context().add_class( "suggested-action" );
    ebtn.clicked.connect(() => {
      do_export( win, parent, export );
    });
    var bbox  = new Box( Orientation.HORIZONTAL, 0 );
    bbox.pack_end( ebtn, false, false, 5 );

    /* Add the page */
    var page = new Box( Orientation.VERTICAL, 0 );
    page.pack_end( bbox, false, true, 5 );
    page.pack_end( new Separator( Orientation.HORIZONTAL ), false, true, 5 );
    export.add_settings( page );

    var label = new Label( export.label );
    _nb.append_page( page, label );

  }

  /* Perform the export */
  private void do_export( MainWindow win, Gtk.Window parent, Export export ) {

    var dialog = new FileChooserDialog( _( "Export (%s)".printf( export.label ) ), parent, FileChooserAction.SAVE,
      _( "Cancel" ), ResponseType.CANCEL, _( "Export" ), ResponseType.ACCEPT );
    Utils.set_chooser_folder( dialog );

    /* Set the filter */
    FileFilter filter = new FileFilter();
    filter.set_filter_name( export.label );
    foreach( string pattern in export.patterns ) {
      filter.add_pattern( pattern );
    }
    dialog.set_filter( filter );

    if( dialog.run() == ResponseType.ACCEPT ) {

      /* Close the dialog and parent window */
      dialog.close();
      parent.close();

      /* Perform the export */
      var fname = dialog.get_filename();
      export.export( fname = win.repair_filename( fname, export.patterns ), win.get_current_da() );
      Utils.store_chooser_folder( fname );

      /* Generate notification to indicate that the export completed */
      win.notification( _( "Minder Export Completed" ), fname );

    } else {

      dialog.close();

    }

  }

}


