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

using WebP;
using Cairo;
using Gdk;
using Gtk;

public class ExportWebP : Export {

  public ExportWebP() {
    base( "webp", _( "WebP" ), { ".webp" }, true, true, false, false );
  }

  //-------------------------------------------------------------
  // Default constructor
  public override bool export( string fname, MindMap map ) {

    // Get the rectangle holding the entire document
    double x, y, w, h;
    map.model.document_rectangle( out x, out y, out w, out h );

    // Create the drawing surface
    var surface = new ImageSurface( Format.RGB24, ((int)w + 20), ((int)h + 20) );
    var context = new Context( surface );

    // Recreate the image
    map.canvas.get_style_context().render_background( context, 0, 0, ((int)w + 20), ((int)h + 20) );
    context.translate( (10 - x), (10 - y) );
    map.model.draw_all( context, true, false );

    // Write the pixbuf to the file
    var pixbuf = pixbuf_get_from_surface( surface, 0, 0, ((int)w + 20), ((int)h + 20) );
    pixbuf = pixbuf.add_alpha( false, 0, 0, 0 );

    uint8* output_buffer = null;
    size_t buffer_size   = 0;

    buffer_size = WebP.encode_lossless_rgba( pixbuf.get_pixels(), pixbuf.get_width(), pixbuf.get_height(), pixbuf.get_rowstride(), out output_buffer );

    if( buffer_size == 0 ) {
      stdout.printf( "Failed to encode WebP image.\n" );
      return( false );
    }

    try {
      uint8[] obuf = {};
      for( int i=0; i<buffer_size; i++ ) {
        obuf += output_buffer[i];
      }
      WebP.free( output_buffer );
      var file = File.new_for_path( fname );
      var output_stream = file.replace( null, false, FileCreateFlags.NONE, null );
      output_stream.write( obuf );
      output_stream.close();
      stdout.printf( "Successfully exported %s\n", fname );
    } catch (IOError e) {
      stdout.printf( "Error saving WebP file: %s", e.message );
      return( false );
    }

    return( true );

  }

}
