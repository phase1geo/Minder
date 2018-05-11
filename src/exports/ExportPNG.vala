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

public class ExportPNG : Object {

  /* Default constructor */
  public static void export( string fname, DrawArea da ) {

    /* Get the rectangle holding the entire document */
    double x, y, w, h;
    da.document_rectangle( out x, out y, out w, out h );

    /* Create the drawing surface */
    var surface = new ImageSurface( Format.ARGB32, w, h );
    var context = new Context( surface );

    /* Translate the image */
    context.translate( (0 - x), (0 - y) );

    /* Recreate the image */
    da.draw_all( context );

    /* Write the image to the PNG file */
    surface.write_to_png( fname );

  }

}