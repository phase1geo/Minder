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

  private string favorites = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "favorites.xml" );

  private MainWindow    _win;
  private DrawArea?     _da = null;
  private GLib.Settings _settings;
  private SearchEntry   _search;
  private Stack         _stack;
  private FlowBox       _favorites;
  private FlowBox       _matched_box;
  private Image         _dragged_sticker;
  private double        _motion_x;
  private double        _motion_y;
  private Gtk.Menu      _menu;
  private Gtk.MenuItem  _favorite;
  private FlowBox       _clicked_category;
  private string        _clicked_sticker;

  public const Gtk.TargetEntry[] DRAG_TARGETS = {
    {"STRING", TargetFlags.SAME_APP, DragTypes.STICKER}
  };

  public StickerInspector( MainWindow win, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _win      = win;
    _settings = settings;

    /* Setup favoriting menu */
    _menu     = new Gtk.Menu();
    _menu.show.connect(() => {
      if( _clicked_category == _favorites ) {
        _favorite.label = _( "Remove From Favorites" );
        _favorite.set_sensitive( true );
      } else {
        _favorite.label = _( "Add To Favorites" );
        _favorite.set_sensitive( !is_favorite( _clicked_sticker ) );
      }
    });
    _favorite = new Gtk.MenuItem.with_label( _( "Add To Favorites" ) );
    _favorite.activate.connect( handle_favorite );
    _menu.add( _favorite );
    _menu.show_all();

    /*
     Create instruction label (this will always be visible so it will not be
     within the scrolled box
    */
    var lbl = new Label( _( "Drag and drop sticker onto a node or anywhere else in the map to add a sticker." ) );
    lbl.wrap      = true;
    lbl.wrap_mode = Pango.WrapMode.WORD;

    /* Create search field */
    _search = new SearchEntry();
    _search.placeholder_text = _( "Search Stickers" );
    _search.search_changed.connect( do_search );

    /* Create stack */
    _stack = new Stack();

    /* Create main scrollable pane */
    var box    = new Box( Orientation.VERTICAL, 0 );
    var sw     = new ScrolledWindow( null, null );
    var vp     = new Viewport( null, null );
    vp.set_size_request( 200, 600 );
    vp.add( box );
    sw.add( vp );

    /* Create search result flowbox */
    _matched_box = create_icon_box();

    var mbox = new Box( Orientation.VERTICAL, 0 );
    var msw = new ScrolledWindow( null, null );
    msw.expand = false;
    msw.get_style_context().add_class( Gtk.STYLE_CLASS_VIEW );
    msw.add( mbox );

    mbox.pack_start( _matched_box, false, false, 0 );

    _stack.add_named( sw, "all" );
    _stack.add_named( msw, "matched" );

    /* Create Favorites */
    _favorites = create_category( box, _( "Favorites" ) );
    load_favorites();

    /* Pack the elements into this widget */
    create_via_xml( box );

    /* Add the scrollable widget to the box */
    pack_start( lbl,      false, false, 5 );
    pack_start( _search,  false, false, 5 );
    pack_start( _stack,   true,  true,  5 );

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
                create_image( _matched_box, name );
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
    var fbox = create_icon_box();
    exp.add( fbox );

    box.pack_start( exp, false, false, 20 );

    return( fbox );

  }

  /* Creates the image from the given name and adds it to the flow box */
  private void create_image( FlowBox box, string name ) {
    var img = new Image.from_resource( "/com/github/phase1geo/minder/" + name );
    img.name = name;
    img.set_tooltip_text( name );
    box.add( img );
  }

  /* Creates the icon box and sets it up */
  private FlowBox create_icon_box() {
    var fbox = new FlowBox();
    fbox.homogeneous = true;
    fbox.selection_mode = SelectionMode.NONE;
    drag_source_set( fbox, Gdk.ModifierType.BUTTON1_MASK, DRAG_TARGETS, Gdk.DragAction.COPY );
    fbox.drag_begin.connect( on_drag_begin );
    fbox.drag_data_get.connect( on_drag_data_get );
    fbox.motion_notify_event.connect((e) => {
      _motion_x = e.x;
      _motion_y = e.y;
      return( true );
    });
    fbox.button_press_event.connect((e) => {
      if( e.button == Gdk.BUTTON_SECONDARY ) {
        _clicked_category = fbox;
        _clicked_sticker  = fbox.get_child_at_pos( (int)e.x, (int)e.y ).get_child().name;
        Utils.popup_menu( _menu, e );
      }
      return( true );
    });

    return( fbox );
  }

  /* Called whenever the user selects the favorite/unfavorite menu item */
  private void handle_favorite() {
    if( _clicked_category == _favorites ) {
      make_unfavorite();
    } else {
      make_favorite();
    }
  }

  /* Returns true if the given icon name is favorited */
  private bool is_favorite( string name ) {
    bool exists = false;
    _favorites.get_children().foreach((w) => {
      exists |= (w as FlowBoxChild).get_child().name == name;
    });
    return( exists );
  }

  /* Make the current sticker a favorite */
  private void make_favorite() {

    /* Add the sticker to the favorites section */
    create_image( _favorites, _clicked_sticker );
    _favorites.show_all();

    /* Save the favorited status */
    save_favorites();

  }

  /* Remove the current sticker as a favorite */
  private void make_unfavorite() {

    /* Remove the sticker from the favorites section */
    _favorites.get_children().foreach((w) => {
      if( (w as FlowBoxChild).get_child().name == _clicked_sticker ) {
        _favorites.remove( w );
      }
    });

    /* Save the favorites */
    save_favorites();

  }

  /* Save the favorited stickers to the save file */
  private void save_favorites() {
    Xml.Doc*  doc  = new Xml.Doc();
    Xml.Node* root = new Xml.Node( null, "favorites" );
    doc->set_root_element( root );
    _favorites.get_children().foreach((w) => {
      var name = (w as FlowBoxChild).get_child().name;
      Xml.Node* n = new Xml.Node( null, "sticker" );
      n->set_prop( "name", name );
      root->add_child( n );
    });
    doc->save_format_file( favorites, 1 );
    delete doc;
  }

  /* Load the favorite stickers from the file */
  private void load_favorites() {
    if( !FileUtils.test( favorites, FileTest.EXISTS ) ) return;
    Xml.Doc* doc = Xml.Parser.parse_file( favorites );
    if( doc == null ) {
      return;
    }
    for( Xml.Node* it=doc->get_root_element()->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "sticker") ) {
        create_image( _favorites, it->get_prop( "name" ) );
      }
    }
    delete doc;
  }

  /* When the sticker drag begins, set the sticker image to the dragged content */
  private void on_drag_begin( Widget widget, DragContext context ) {
    var fbox = (FlowBox)widget;
    _dragged_sticker = (Image)fbox.get_child_at_pos( (int)_motion_x, (int)_motion_y ).get_child();
    Gtk.drag_set_icon_pixbuf( context, _dragged_sticker.pixbuf, 0, 0 );
  }

  private void on_drag_data_get( Widget widget, DragContext context, SelectionData selection_data, uint target_type, uint time ) {
    if( target_type == DragTypes.STICKER ) {
      selection_data.set_text( _dragged_sticker.name, -1 );
    }
  }

  /* Performs search */
  private void do_search() {

    var search_text = _search.text;

    /* If the search field is empty, show all of the icons by category again */
    if( search_text == "" ) {
      _matched_box.invalidate_filter();
      _stack.set_visible_child_name( "all" );

    /* Otherwise, show only the currently matching icons */
    } else {
      _matched_box.set_filter_func((item) => {
        return( item.get_child().name.contains( search_text ) );
      });
      _stack.set_visible_child_name( "matched" );
    }

  }

  /* Grabbing input focus on the first UI element */
  public void grab_first() {
    _search.grab_focus();
  }

}
