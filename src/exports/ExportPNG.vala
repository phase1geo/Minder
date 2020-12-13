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
using Gtk;

public class ExportPNG : Export {

  private Switch _transparent;

  /* Constructor */
  public ExportPNG() {
    base( "png", _( "PNG" ), { ".png" }, true, false );
  }

  /* Default constructor */
  public override bool export( string fname, DrawArea da ) {

    /* Get the rectangle holding the entire document */
    double x, y, w, h;
    da.document_rectangle( out x, out y, out w, out h );

    /* Create the drawing surface */
    var surface = new ImageSurface( (_transparent.get_active() ? Format.ARGB32 : Format.RGB24), ((int)w + 20), ((int)h + 20) );
    var context = new Context( surface );

    /* Recreate the image */
    if( !_transparent.get_active() ) {
      da.get_style_context().render_background( context, 0, 0, ((int)w + 20), ((int)h + 20) );
    }

    /* Translate the image */
    context.translate( (10 - x), (10 - y) );
    da.draw_all( context );

    /* Write the image to the PNG file */
    surface.write_to_png( fname );

    return( true );

  }

  /* Indicate that settings are available */
  public override bool settings_available() {
    return( true );
  }

  /* Add the PNG settings */
  public override void add_settings( Box box ) {

    var tlbl = new Label( _( "Enable Transparent Background" ) );
    _transparent = new Switch();
    _transparent.activate.connect(() => {
      settings_changed();
    });

    var tbox = new Box( Orientation.HORIZONTAL, 10 );
    tbox.pack_start( tlbl,         false, false );
    tbox.pack_start( _transparent, false, false );

    box.pack_start( tbox );

  }

  /* Save the settings */
  public override void save_settings( Xml.Node* node ) {
    node->set_prop( "transparent", _transparent.get_active().to_string() );
  }

  /* Load the settings */
  public override void load_settings( Xml.Node* node ) {
    var t = node->get_prop( "transparent" );
    if( t != null ) {
      _transparent.set_active( bool.parse( t ) );
    }
  }

}
