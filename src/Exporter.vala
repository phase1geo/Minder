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

  private MenuButton _mb;
  private Revealer   _stack_reveal;
  private Stack      _stack;

  /* Constructor */
  public Exporter( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 0 );

    _mb       = new MenuButton();
    _mb.popup = new Gtk.Menu();
    _mb.image = new Image.from_icon_name( "pan-down-symbolic", IconSize.SMALL_TOOLBAR );
    _mb.image_position = PositionType.RIGHT;
    _mb.always_show_image = true;

    var export = new Button.with_label( _( "Export" ) );
    export.get_style_context().add_class( "suggested-action" );
    export.clicked.connect(() => {
      do_export( win );
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.pack_start( _mb,    true,  true );
    bbox.pack_end(   export, false, false );

    _stack = new Stack();
    _stack.transition_type = StackTransitionType.NONE;

    _stack_reveal = new Revealer();
    _stack_reveal.add( _stack );

    populate( win );

    _mb.popup.show_all();

    pack_start( bbox,          false, true, 0 );
    pack_start( _stack_reveal, true,  true, 0 );
    show_all();

    /* Initialize the UI */
    var last    = win.settings.get_string( "last-export" );
    var current = win.exports.get_by_name( last );
    handle_mb_change( win, current );

  }

  /* Populates the exporter widget with the available export types */
  private void populate( MainWindow win ) {
    for( int i=0; i<win.exports.length(); i++ ) {
      if( win.exports.index( i ).exportable ) {
        add_export( win, win.exports.index( i ) );
      }
    }
  }

  private void handle_mb_change( MainWindow win, Export export ) {
    _mb.label                  = export.label;
    _stack.visible_child_name  = export.name;
    _stack_reveal.reveal_child = export.settings_available();
    win.settings.set_string( "last-export", export.name );
  }

  /* Add the given export */
  private void add_export( MainWindow win, Export export ) {

    /* Add menu option to the menubutton */
    var mnu = new Gtk.MenuItem.with_label( export.label );
    mnu.activate.connect(() => {
      handle_mb_change( win, export );
    });
    _mb.popup.add( mnu );

    /* Add the page */
    var opts = new Box( Orientation.VERTICAL, 5 );
    opts.margin = 5;
    export.add_settings( opts );

    var label = new Label( "<i>" + "Export Options" + "</i>" );
    label.use_markup = true;

    var frame = new Frame( null );
    frame.label_widget  = label;
    frame.label_xalign  = (float)0.5;
    frame.margin_top    = 5;
    frame.margin_bottom = 5;
    frame.add( opts );

    /* Add the options to the options stack */
    _stack.add_named( frame, export.name );

  }

  /* Perform the export */
  private void do_export( MainWindow win ) {

    var name   = _stack.visible_child_name;
    var export = win.exports.get_by_name( name );
    var dialog = new FileChooserDialog( _( "Export (%s)".printf( export.label ) ), win, FileChooserAction.SAVE,
      _( "Cancel" ), ResponseType.CANCEL, _( "Export" ), ResponseType.ACCEPT );
    Utils.set_chooser_folder( dialog );

    /* Set the filter */
    FileFilter filter = new FileFilter();
    filter.set_filter_name( export.label );
    foreach( string extension in export.extensions ) {
      filter.add_pattern( "*" + extension );
    }
    dialog.set_filter( filter );

    if( dialog.run() == ResponseType.ACCEPT ) {

      /* Close the dialog and parent window */
      dialog.close();

      /* Perform the export */
      var fname = dialog.get_filename();
      export.export( fname = win.repair_filename( fname, export.extensions ), win.get_current_da() );
      Utils.store_chooser_folder( fname );

      /* Generate notification to indicate that the export completed */
      win.notification( _( "Minder Export Completed" ), fname );

    } else {

      dialog.close();

    }

  }

}


