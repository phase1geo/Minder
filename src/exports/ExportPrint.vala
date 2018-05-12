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

public class ExportPrint : Object {

  private DrawArea _da;

  /* Default constructor */
  public ExportPrint() {}

  /* Perform print operation */
  public void print( DrawArea da, MainWindow main ) {

    _da = da;

    var op       = new PrintOperation();
    // var settings = new PrintSettings().from_file( fname );
    var settings = new PrintSettings();
    op.set_print_settings( settings );
    op.set_n_pages( 1 );
    op.set_unit( Unit.MM );

    /* Connect to the draw_page signal */
    op.draw_page.connect( draw_page );

    try {
      var res = op.run( PrintOperationAction.PRINT_DIALOG, main );
      switch( res ) {
        case PrintOperationResult.APPLY :
          settings = op.get_print_settings();
          // Save the settings to a file - settings.to_file( fname );
          break;
        case PrintOperationResult.ERROR :
          /* TBD - Display the print error */
          break;
        case PrintOperationResult.IN_PROGRESS :
          /* TBD */
          break;
      }
    } catch( GLib.Error e ) {
      /* TBD */
    }

  }

  /* Draws the page */
  public void draw_page( PrintOperation op, PrintContext context, int page_nr ) {

    var ctx         = context.get_cairo_context();
    var page_width  = context.get_width();
    var page_height = context.get_height();
    var margin_x    = 0.5 * context.get_dpi_x();
    var margin_y    = 0.5 * context.get_dpi_y();

    /* Get the rectangle holding the entire document */
    double x, y, w, h;
    _da.document_rectangle( out x, out y, out w, out h );

    /* Calculate the required scaling factor to get the document to fit */
    double width  = (page_width  - (2 * margin_x)) / w;
    double height = (page_height - (2 * margin_y)) / h;
    double sf     = (width < height) ? width : height;

    /* Scale and translate the image */
    ctx.scale( sf, sf );
    ctx.translate( ((0 - x) + margin_x), ((0 - y) + margin_y) );

    /* Draw the map */
    _da.draw_all( ctx );

  }

}
