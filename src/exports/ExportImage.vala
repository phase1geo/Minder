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
using Gdk;
using Gtk;

public class ExportImage : Export {

  public ExportImage( string type, string label, string[] extensions ) {
    base( type, label, extensions, true, false, false, true );
  }

  /* Default constructor */
  public override bool export( string fname, MindMap map ) {

    var scale = get_zoom( "zoom" ) / 100.0;

    /* Get the rectangle holding the entire document */
    double x, y, w, h;
    map.model.document_rectangle( out x, out y, out w, out h );

    w *= scale;
    h *= scale;

    /* Create the drawing surface */
    var surface = new ImageSurface( Format.RGB24, ((int)w + 20), ((int)h + 20) );
    var context = new Context( surface );

    /* Recreate the image */
    map.canvas.get_style_context().render_background( context, 0, 0, ((int)w + 20), ((int)h + 20) );
    context.translate( (10 - x), (10 - y) );
    context.scale( scale, scale );
    map.model.draw_all( context, true, false );

    /* Write the pixbuf to the file */
    var pixbuf = pixbuf_get_from_surface( surface, 0, 0, ((int)w + 20), ((int)h + 20) );

    string[] option_keys   = {};
    string[] option_values = {};

    switch( name ) {
      case "jpeg" :
        var value = get_scale( "quality" );
        option_keys += "quality";  option_values += value.to_string();
        break;
    }

    try {
      if( get_bool( "clipboard" ) ) {
        uint8[] img_data;
        pixbuf.save_to_bufferv( out img_data, name, option_keys, option_values );
        MinderClipboard.copy_image_buffer( img_data );
      } else {
        pixbuf.savev( fname, name, option_keys, option_values );
      }
    } catch( Error e ) {
      stdout.printf( "Error writing %s: %s\n", name, e.message );
      return( false );
    }

    return( true );

  }

  public override void add_settings( Grid grid ) {
    add_setting_zoom( "zoom", grid, _( "Zoom %" ), null, 50, 500, 25, 100 );
    switch( name ) {
      case "jpeg" :  add_settings_jpeg( grid );  break;
    }
  }

  private void add_settings_jpeg( Grid grid ) {
    add_setting_scale( "quality", grid, _( "Quality" ), null, 0, 100, 1, 90 );
  }

  /* Save the settings */
  public override void save_settings( Xml.Node* node ) {

    node->set_prop( "zoom", get_zoom( "zoom" ).to_string() );

    switch( name ) {
      case "jpeg" :  save_settings_jpeg( node );  break;
    }

  }

  private void save_settings_jpeg( Xml.Node* node ) {
    var value = get_scale( "quality" );
    node->set_prop( "quality", value.to_string() );
  }

  /* Load the settings */
  public override void load_settings( Xml.Node* node ) {

    var z = node->get_prop( "zoom" );
    if( z != null ) {
      set_zoom( "zoom", int.parse( z ) );
    }

    switch( name ) {
      case "jpeg" :  load_settings_jpeg( node );  break;
    }

  }

  private void load_settings_jpeg( Xml.Node* node ) {
    var q = node->get_prop( "quality" );
    if( q != null ) {
      var value = int.parse( q );
      set_scale( "quality", value );
    }
  }

}
