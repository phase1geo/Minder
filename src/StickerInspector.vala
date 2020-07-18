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

public class StickerInspector : Box {

  private MainWindow    _win;
  private DrawArea?     _da = null;
  private GLib.Settings _settings;
  private SearchEntry   _search;
  private Array<string> _names;
  private Revealer      _all;
  private Revealer      _matched;
  private FlowBox       _matched_box;

  public StickerInspector( MainWindow win, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _win      = win;
    _settings = settings;
    _names    = new Array<string>();

    _all = new Revealer();
    _all.reveal_child = true;
    _all.transition_duration = 0;

    _matched = new Revealer();
    _matched.reveal_child = false;
    _matched.transition_duration = 0;

    /*
     Create instruction label (this will always be visible so it will not be
     within the scrolled box
    */
    var lbl = new Label( _( "Drag and drop sticker to a node or anywhere else in the map to add a sticker." ) );
    lbl.wrap      = true;
    lbl.wrap_mode = Pango.WrapMode.WORD;

    /* Create search field */
    _search = new SearchEntry();
    _search.placeholder_text = _( "Search Stickers" );
    _search.search_changed.connect( do_search );

    /* Create main scrollable pane */
    var box    = new Box( Orientation.VERTICAL, 0 );
    var sw     = new ScrolledWindow( null, null );
    var vp     = new Viewport( null, null );
    vp.set_size_request( 200, 600 );
    vp.add( box );
    sw.add( vp );
    _all.add( sw );

    /* Create search result flowbox */
    _matched_box = new FlowBox();
    _matched_box.homogeneous = true;
    _matched_box.selection_mode = SelectionMode.NONE;

    var msw = new ScrolledWindow( null, null );
    var mvp = new Viewport( null, null );
    mvp.set_size_request( 200, 600 );
    mvp.add( _matched_box );
    msw.add( mvp );
    _matched.add( msw );

    /* Pack the elements into this widget */
    create_via_xml( box );

    /* Add the scrollable widget to the box */
    pack_start( lbl,      false, false, 5 );
    pack_start( _search,  false, false, 5 );
    pack_start( _all,     true,  true,  5 );
    pack_start( _matched, false, true,  5 );

    /* Make sure all elements are visible */
    show_all();

  }

  /* Creates the rest of the UI from the stickers XML file that is stored in a gresource */
  private void create_via_xml( Box box ) {

    try {
      var template = resources_lookup_data( "/com/github/phase1geo/minder/stickers.xml", ResourceLookupFlags.NONE);
      var contents = (string)template.get_data();
      Xml.Doc* doc = Xml.Parser.parse_memory( contents, contents.length );
      if( doc != null ) {
        for( Xml.Node* it=doc->get_root_element()->children; it!=null; it=it->next ) {
          if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "category") ) {
            var category = create_category( box, it->get_prop( "name" ) );
            for( Xml.Node* it2=it->children; it2!=null; it2=it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "img") ) {
                var name = it2->get_prop( "title" );
                create_image( category, name );
                _names.append_val( name );

              }
            }
          }
        }
        delete doc;
      }
    } catch( Error e ) {
      warning( "Failed to load sticker XML template: %s", e.message );
    }

  }

  /* Creates the expander flowbox for the given category name and adds it to the sidebar */
  private FlowBox create_category( Box box, string name ) {

    /* Create expander */
    var exp  = new Expander( Utils.make_title( name ) );
    exp.use_markup = true;
    exp.expanded   = true;

    /* Create the flowbox which will contain the stickers */
    var fbox = new FlowBox();
    fbox.homogeneous = true;
    exp.add( fbox );

    box.pack_start( exp, false, false, 20 );

    return( fbox );

  }

  /* Creates the image from the given name and adds it to the flow box */
  private void create_image( FlowBox box, string name ) {

    /* Create the icon and give it a tooltip */
    var img = new Image.from_resource( "/com/github/phase1geo/minder/" + name );
    img.set_tooltip_text( name );
    box.add( img );

    /* Add support for being a drag source */
    drag_source_set( img, ModifierType.BUTTON1_MASK, DrawArea.DRAG_TARGETS, DragAction.COPY );
    img.drag_begin.connect((c) => {
      stdout.printf( "Drag started\n" );
    });
    img.drag_data_get.connect( on_drag_data_get );
    img.drag_end.connect((c) => {
      stdout.printf( "Drag ended\n" );
    });

  }

  private void on_drag_data_get( DragContext context, SelectionData selection_data, uint target_type, uint time ) {
    string string_data = "test";
    if( target_type == 1 ) {
      selection_data.set_text( string_data, string_data.length );
    } else {
      assert_not_reached();
    }
  }

  /* Performs search */
  private void do_search() {

    var search_text = _search.text;

    if( search_text == "" ) {

      _matched.reveal_child = false;
      _all.reveal_child = true;

    } else {

      _matched.reveal_child = true;
      _all.reveal_child = false;

      /* Clear the matched flowbox */
      foreach( Widget w in _matched_box.get_children() ) {
        _matched_box.remove( w );
      }

      /* Add the matching stickers */
      for( int i=0; i<_names.length; i++ ) {
        stdout.printf( "name: %s, search_Text: %s\n", _names.index( i ), search_text );
        if( _names.index( i ).contains( search_text ) ) {
          stdout.printf( "  MATCH FOUND!\n" );
          create_image( _matched_box, _names.index( i ) );
        }
      }

      _matched_box.show_all();

    }

  }

}
