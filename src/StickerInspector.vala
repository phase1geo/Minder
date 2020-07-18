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

  public StickerInspector( MainWindow win, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _win      = win;
    _settings = settings;

    /* Create a scrollable pane */
    var box    = new Box( Orientation.VERTICAL, 0 );
    var sw     = new ScrolledWindow( null, null );
    var vp     = new Viewport( null, null );
    vp.set_size_request( 200, 600 );
    vp.add( box );
    sw.add( vp );

    /* Pack the elements into this widget */
    create_via_xml( box );

    /* Add the scrollable widget to the box */
    pack_start( sw, true, true, 10 );

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
                create_image( category, it2->get_prop( "title" ) );
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
    var img = new Image.from_resource( ("/com/github/phase1geo/minder/" + name) );
    img.set_tooltip_text( name.slice( 0, (name.length - 4) ).replace( "_", "-" ) );
    box.add( img );
    drag_source_set( img, ModifierType.BUTTON1_MASK, DrawArea.DRAG_TARGETS, DragAction.COPY );
    img.drag_data_get.connect( on_drag_data_get );
  }

  private void on_drag_data_get( DragContext context, SelectionData selection_data, uint target_type, uint time ) {
    string string_data = "test";
    if( target_type == 1 ) {
      selection_data.set_text( string_data, string_data.length );
    } else {
      assert_not_reached();
    }
  }

}
