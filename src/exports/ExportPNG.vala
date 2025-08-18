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
using Cairo;

public class ExportPNG : Export {

  /* Constructor */
  public ExportPNG() {
    base( "png", _( "PNG" ), { ".png" }, true, false, false, true );
  }

  /* Default constructor */
  public override bool export( string fname, MindMap map ) {

    var transparent = get_bool( "transparent" );
    var scale       = get_zoom( "zoom" ) / 100.0;

    /* Get the rectangle holding the entire document */
    double x, y, w, h;
    map.model.document_rectangle( out x, out y, out w, out h );

    w *= scale;
    h *= scale;

    /* Create the drawing surface */
    var surface = new ImageSurface( (transparent ? Format.ARGB32 : Format.RGB24), ((int)w + 20), ((int)h + 20) );
    var context = new Context( surface );

    /* Recreate the image */
    if( !transparent ) {
      map.canvas.get_style_context().render_background( context, 0, 0, ((int)w + 20), ((int)h + 20) );
    }

    /* Translate the image */
    context.translate( (10 - x), (10 - y) );

    /* Scale the image */
    context.scale( scale, scale );

    /* Draw the image */
    map.model.draw_all( context, true, false );

    /* Write the pixbuf to the file */
    var pixbuf = pixbuf_get_from_surface( surface, 0, 0, ((int)w + 20), ((int)h + 20) );

    string[] option_keys   = {};
    string[] option_values = {};

    var value = get_scale( "compression" );
    option_keys += "compression";  option_values += value.to_string();

    try {
      if( send_to_clipboard() ) {
        uint8[] img_data;
        pixbuf.save_to_bufferv( out img_data, "png", option_keys, option_values );
        MinderClipboard.copy_image_buffer( img_data );
      } else {
        pixbuf.savev( fname, "png", option_keys, option_values );
      }
    } catch( Error e ) {
      stdout.printf( "Error writing %s: %s\n", name, e.message );
      return( false );
    }

    return( true );

  }

  /* Add the PNG settings */
  public override void add_settings( Grid grid ) {
    add_setting_zoom( "zoom", grid, _( "Zoom %" ), null, 50, 500, 25, 100 ); 
    add_setting_bool( "transparent", grid, _( "Enable Transparent Background" ), null, false );
    add_setting_scale( "compression", grid, _( "Compression" ), null, 0, 9, 1, 5 );
  }

  /* Save the settings */
  public override void save_settings( Xml.Node* node ) {
    node->set_prop( "zoom",        get_zoom( "zoom" ).to_string() );
    node->set_prop( "transparent", get_bool( "transparent" ).to_string() );
    node->set_prop( "compression", get_scale( "compression" ).to_string() );
  }

  /* Load the settings */
  public override void load_settings( Xml.Node* node ) {

    var z = node->get_prop( "zoom" );
    if( z != null ) {
      set_zoom( "zoom", int.parse( z ) );
    }

    var t = node->get_prop( "transparent" );
    if( t != null ) {
      set_bool( "transparent", bool.parse( t ) );
    }

    var c = node->get_prop( "compression" );
    if( c != null ) {
      set_scale( "compression", int.parse( c ) );
    }

  }

}
