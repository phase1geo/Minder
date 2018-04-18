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

public class MapInspector : Box {

  private DrawArea?                   _da      = null;
  private Granite.Widgets.ModeButton? _layouts = null;

  public MapInspector( DrawArea da ) {

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

    /* Create the modebutton to select the current layout */
    var llbl = new Label( _( "Node Layouts" ) );
    _layouts = new Granite.Widgets.ModeButton();
    _layouts.has_tooltip = true;
    _layouts.append_icon( "minder-layout-manual-symbolic",     IconSize.SMALL_TOOLBAR );
    _layouts.append_icon( "minder-layout-vertical-symbolic",   IconSize.SMALL_TOOLBAR );
    _layouts.append_icon( "minder-layout-horizontal-symbolic", IconSize.SMALL_TOOLBAR );
    _layouts.append_icon( "minder-layout-left-symbolic",       IconSize.SMALL_TOOLBAR );
    _layouts.append_icon( "minder-layout-right-symbolic",      IconSize.SMALL_TOOLBAR );
    _layouts.append_icon( "minder-layout-up-symbolic",         IconSize.SMALL_TOOLBAR );
    _layouts.append_icon( "minder-layout-down-symbolic",       IconSize.SMALL_TOOLBAR );
    _layouts.mode_changed.connect( layout_changed );
    _layouts.query_tooltip.connect( layout_show_tooltip );

    /* Pack the panel */
    pack_start( llbl,     false, true );
    pack_start( _layouts, false, true );
    pack_start( lbl,      false, true );
    pack_start( sw,       true,  true );

  }

  /* Called whenever the user changes the current layout */
  private void layout_changed() {

    switch( _layouts.selected ) {
      case 0  :  _da.set_layout( new LayoutManual() );      break;
      case 1  :  _da.set_layout( new LayoutVertical() );    break;
      case 2  :  _da.set_layout( new LayoutHorizontal() );  break;
      case 3  :  _da.set_layout( new LayoutLeft() );        break;
      case 4  :  _da.set_layout( new LayoutRight() );       break;
      case 5  :  _da.set_layout( new LayoutUp() );          break;
      case 6  :  _da.set_layout( new LayoutDown() );        break;
      default :  _da.set_layout( new LayoutHorizontal() );  break;
    }

  }

  /* Called whenever the tooltip needs to be displayed for the layout selector */
  private bool layout_show_tooltip( int x, int y, bool keyboard, Tooltip tooltip ) {
    if( keyboard ) {
      return( false );
    }
    int button_width = _layouts.get_allocated_width() / 7;
    switch( x / button_width ) {
      case 0  :  tooltip.set_text( _( "Manual" ) );      break;
      case 1  :  tooltip.set_text( _( "Vertical" ) );    break;
      case 2  :  tooltip.set_text( _( "Horizontal" ) );  break;
      case 3  :  tooltip.set_text( _( "To left" ) );     break;
      case 4  :  tooltip.set_text( _( "To right" ) );    break;
      case 5  :  tooltip.set_text( _( "Upwards" ) );     break;
      case 6  :  tooltip.set_text( _( "Downwards" ) );   break;
      default :  return( false );
    }
    return( true );
  }

}
