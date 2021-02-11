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

using Cairo;

public class ExportPDF : Export {

  /* Constructor */
  public ExportPDF() {
    base( "pdf", _( "PDF" ), { ".pdf" }, true, false );
  }

  /* Default constructor */
  public override bool export( string fname, DrawArea da ) {

    /* Get the width and height of the page */
    double page_width  = 8.5 * 72;
    double page_height = 11  * 72;
    double margin      = 0.5 * 72;

    /* Create the drawing surface */
    var surface = new PdfSurface( fname, page_width, page_height );
    var context = new Context( surface );

    /* Get the rectangle holding the entire document */
    double x, y, w, h;
    da.document_rectangle( out x, out y, out w, out h );

    /* Calculate the required scaling factor to get the document to fit */
    double width  = (page_width  - (2 * margin)) / w;
    double height = (page_height - (2 * margin)) / h;
    double sf     = (width < height) ? width : height;

    /* Scale and translate the image */
    context.scale( sf, sf );
    context.translate( ((0 - x) + (margin / sf)), ((0 - y) + (margin / sf)) );

    /* Draw background */
    da.get_style_context().render_background( context, x, y, w, h );

    /* Recreate the image */
    da.draw_all( context );

    /* Draw the page to the PDF file */
    context.show_page();

    return( true );

  }

}
