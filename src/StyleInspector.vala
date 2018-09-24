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

public class StyleInspector : Box {

  private DrawArea      _da;
  private GLib.Settings _settings;
  private Links         _links;

  private Granite.Widgets.ModeButton _link_types;

  public StyleInspector( DrawArea da, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _da       = da;
    _settings = settings;
    _links    = new Links();

    /* Create the UI */
    add_line_ui();

  }

  /* Adds the options to manipulate line options */
  private void add_line_ui() {

    var box = new Box( Orientation.VERTICAL, 0 );
    var lbl = new Label( _( "<b>Line Options</b>" ) );
    lbl.use_markup = true;

    lbl.xalign = (float)0;

    var ltbox  = new Box( Orientation.HORIZONTAL, 0 );
    ltbox.border_width = 10;

    var link_types_lbl = new Label( _( "Line Type" ) );

    /* Create the line types mode button */
    _link_types = new Granite.Widgets.ModeButton();
    _link_types.has_tooltip = true;
    var links = _links.get_links();
    for( int i=0; i<links.length; i++ ) {
      _link_types.append_icon( links.index( i ).icon_name(), IconSize.SMALL_TOOLBAR );
    }
    _link_types.button_release_event.connect( link_type_changed );
    _link_types.query_tooltip.connect( link_type_show_tooltip );

    ltbox.pack_start( link_types_lbl, false, false );
    ltbox.pack_end(   _link_types,    false, false );

    box.pack_start( lbl,   false, true, 0 );
    box.pack_start( ltbox, false, true, 0 );

    pack_start( box, false, true );

  }

  /* Called whenever the user changes the current layout */
  private bool link_type_changed( Gdk.EventButton e ) {
    var links = _links.get_links();
    if( _link_types.selected < links.length ) {
      var link = links.index( _link_types.selected );
      _links.set_all_to_link( _da.get_nodes(), link );
      _da.queue_draw();
    }
    return( false );
  }

  /* Called whenever the tooltip needs to be displayed for the layout selector */
  private bool link_type_show_tooltip( int x, int y, bool keyboard, Tooltip tooltip ) {
    if( keyboard ) {
      return( false );
    }
    var links = _links.get_links();
    int button_width = (int)(_link_types.get_allocated_width() / links.length);
    if( (x / button_width) < links.length ) {
      tooltip.set_text( links.index( x / button_width ).name() );
      return( true );
    }
    return( false );
  }

}
