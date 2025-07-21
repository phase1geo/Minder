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

public class ExportSVG : Export {

  /* Constructor */
  public ExportSVG() {
    base( "svg", _( "SVG" ), { ".svg" }, true, false, false );
  }

  /* Default constructor */
  public override bool export( string fname, MindMap map ) {

    /* Get the rectangle holding the entire document */
    double x, y, w, h;
    map.model.document_rectangle( out x, out y, out w, out h );

    /* Create the drawing surface */
    var surface = new SvgSurface( fname, ((int)w + 20), ((int)h + 20) );
    var context = new Context( surface );

    surface.restrict_to_version( SvgVersion.VERSION_1_1 );

    /* Translate the image */
    context.translate( (10 - x), (10 - y) );

    /* Recreate the image */
    map.model.draw_all( context, true, false );

    /* Draw the page to the PDF file */
    context.show_page();

    return( true );

  }

}
