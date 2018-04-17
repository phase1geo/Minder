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

public class ThemeInspector : Box {

  private DrawArea? _da = null;

  public ThemeInspector( DrawArea da ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _da = da;

    /* Create the UI */
    var lbl = new Label( _( "Themes" ) );
    var sw  = new ScrolledWindow( null, null );
    var vp  = new Viewport( null, null );
    var box = new Box( Orientation.VERTICAL, 20 );
    vp.set_size_request( 200, 600 );
    vp.add( box );
    sw.add( vp );

    /* Get the theme information to display */
    var names = new Array<string>();
    var icons = new Array<Gtk.Image>();

    _da.themes.names( ref names );
    _da.themes.icons( ref icons );

    /* Add the themes */
    for( int i=0; i<names.length; i++ ) {
      var ebox  = new EventBox();
      var item  = new Box( Orientation.VERTICAL, 5 );
      var label = new Label( names.index( i ) );
      item.pack_start( icons.index( i ), false, false, 5 );
      item.pack_start( label,            false, true );
      ebox.button_press_event.connect((w, e) => {
        Gdk.RGBA c = {1.0, 1.0, 1.0, 1.0};
        c.parse( "Blue" );
        w.override_background_color( StateFlags.NORMAL, c );
        _da.set_theme( label.label );
        return( false );
      });
      ebox.add( item );
      box.pack_start( ebox, false, true );
    }

    /* Pack the panel */
    pack_start( lbl, false, true );
    pack_start( sw,  true,  true );

  }

}
