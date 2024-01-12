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
  private Gtk.Menu      _favorite_menu;
  private Gtk.Menu      _builtin_menu;
  private Gtk.Menu      _custom_menu;
  private FlowBox       _clicked_category;
  private StickerSet    _sticker_set;
  private string        _clicked_sticker;

  public const Gtk.TargetEntry[] DRAG_TARGETS = {
    {"STRING", TargetFlags.SAME_APP, DragTypes.STICKER}
  };

  public StickerInspector( MainWindow win, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _win      = win;
    _settings = settings;

    /* Setup menus */
    _favorite_menu = new Gtk.Menu();
    _builtin_menu  = new Gtk.Menu();
    _custom_menu   = new Gtk.Menu();

    /* Setup favorite menu */
    var unfavorite = new Gtk.MenuItem.with_label( _( "Remove From Favorites" ) );
    unfavorite.activate.connect( make_unfavorite );

    _favorite_menu.add( unfavorite );
    _favorite_menu.show_all();

    /* Setup built-in sticker menu */
    var bi_favorite = new Gtk.MenuItem.with_label( _( "Add To Favorites" ) );
    bi_favorite.activate.connect( make_favorite );

    _builtin_menu.add( bi_favorite );
    _builtin_menu.show_all();
    _builtin_menu.show.connect(() => {
      bi_favorite.set_sensitive( !is_favorite( _clicked_sticker ) );
    });

    /* Setup custom sticker menu */
    var cu_favorite = new Gtk.MenuItem.with_label( _( "Add To Favorites" ) );
    cu_favorite.activate.connect( make_favorite );
    
    var cu_remove = new Gtk.MenuItem.with_label( _( "Remove Custom Sticker" ) );
    cu_remove.activate.connect( handle_remove );

    _custom_menu.add( cu_favorite );
    _custom_menu.add( new SeparatorMenuItem() );
    _custom_menu.add( cu_remove );
    _custom_menu.show_all();
    _custom_menu.show.connect(() => {
      cu_favorite.set_sensitive( !is_favorite( _clicked_sticker ) );
    });


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
    var box    = new Box( Orientation.VERTICAL, 5 );
    var sw     = new ScrolledWindow( null, null );
    var vp     = new Viewport( null, null );
    vp.set_size_request( 200, 600 );
    vp.add( box );
    sw.add( vp );

    /* Create search result flowbox */
    _matched_box = create_icon_box( "" );

    var mbox = new Box( Orientation.VERTICAL, 0 );
    var msw = new ScrolledWindow( null, null );
    msw.expand = false;
    msw.get_style_context().add_class( Gtk.STYLE_CLASS_VIEW );
    msw.add( mbox );

    mbox.pack_start( _matched_box, false, false, 0 );

    _stack.add_named( sw, "all" );
    _stack.add_named( msw, "matched" );

    /* Create the sticker set */
    _sticker_set = new StickerSet();

    /* Create Favorites */
    _favorites = create_category( box, _( "Favorites" ) );
    load_favorites();

    /* Pack the elements into this widget */
    create_from_sticker_set( box );

    var show = new Button.with_label( _( "Show Custom Sticker Directory" ) );
    show.clicked.connect(() => {
      Utils.open_url( "file://" + _sticker_set.sticker_dir() );
    });

    box.pack_start( show, false, false, 0 );

    /* Add the scrollable widget to the box */
    pack_start( lbl,      false, false, 5 );
    pack_start( _search,  false, false, 5 );
    pack_start( _stack,   true,  true,  5 );

    /* Make sure all elements are visible */
    show_all();

  }

  /* Creates the rest of the UI from the stickers XML file that is stored in a gresource */
  private void create_from_sticker_set( Box box ) {

    var categories = _sticker_set.get_categories();

    for( int i=0; i<categories.length; i++ ) {
      var category = create_category( box, categories.index( i ) );
      var icons    = _sticker_set.get_category_icons( categories.index( i ) );
      for( int j=0; j<icons.length; j++ ) {
        create_image( category,     icons.index( j ).resource, icons.index( j ).tooltip, true );
        create_image( _matched_box, icons.index( j ).resource, icons.index( j ).tooltip, true );
      }
      create_import( category );
    }

  }

  /* Creates the expander flowbox for the given category name and adds it to the sidebar */
  private FlowBox create_category( Box box, string name ) {

    /* Create expander */
    var exp = new Expander( Utils.make_title( name ) ) {
      use_markup = true,
      expanded   = true
    };

    /* Create the flowbox which will contain the stickers */
    var fbox = create_icon_box( name );
    exp.add( fbox );

    box.pack_start( exp, false, false, 20 );

    return( fbox );

  }

  /* Creates the image from the given name and adds it to the flow box */
  private void create_image( FlowBox box, string name, string tooltip, bool add ) {
    var pixbuf = StickerSet.make_pixbuf( name );
    if( pixbuf != null ) {
      var img = new Image.from_pixbuf( pixbuf );
      img.name = name;
      img.set_tooltip_text( tooltip );
      if( add ) {
        box.add( img );
      } else {
        box.insert( img, (int)(box.get_children().length() - 1) );
      }
    }
  }

  /* Adds an import image button to the given category flowbox */
  private void create_import( FlowBox box ) {
    var img  = new Image.from_icon_name( "list-add-symbolic", IconSize.LARGE_TOOLBAR );
    img.name = "";
    img.set_tooltip_text( _( "Add custom stickers" ) );
    box.add( img );
  }

  /* Creates the icon box and sets it up */
  private FlowBox create_icon_box( string category ) {
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
      var int_x = (int)e.x;
      var int_y = (int)e.y;
      if( e.button == Gdk.BUTTON_PRIMARY ) {
        if( fbox.get_child_at_pos( int_x, int_y ).get_child().name == "" ) {
          import_stickers( fbox, category );
        }
      } else if( e.button == Gdk.BUTTON_SECONDARY ) {
        _clicked_category = fbox;
        _clicked_sticker  = fbox.get_child_at_pos( int_x, int_y ).get_child().name;
        if( _clicked_sticker != "" ) {
          if( _clicked_category == _favorites ) {
            Utils.popup_menu( _favorite_menu, e );
          } else if( is_custom( _clicked_sticker ) ) {
            Utils.popup_menu( _custom_menu, e );
          } else {
            Utils.popup_menu( _builtin_menu, e );
          }
        }
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

  /* Called whenever the user selects the remove menu item */
  private void handle_remove() {
    if( _sticker_set.remove_sticker( _clicked_sticker ) ) {
      make_unfavorite();
      _clicked_category.get_children().foreach((w) => {
        if( (w as FlowBoxChild).get_child().name == _clicked_sticker ) {
          _clicked_category.remove( w );
        }
      });
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

  /* Returns true if the given sticker is a custom sticker */
  private bool is_custom( string name ) {
    return( name.get_char( 0 ) == '/' );
  }

  /* Make the current sticker a favorite */
  private void make_favorite() {

    string tooltip;
    if( _sticker_set.get_icon_info( _clicked_sticker, out tooltip ) ) {

      /* Add the sticker to the favorites section */
      create_image( _favorites, _clicked_sticker, tooltip, true );
      _favorites.show_all();

      /* Save the favorited status */
      save_favorites();

    }

  }

  /* Remove the current sticker as a favorite */
  private void make_unfavorite() {
    _favorites.get_children().foreach((w) => {
      if( (w as FlowBoxChild).get_child().name == _clicked_sticker ) {
        _favorites.remove( w );
        save_favorites();
      }
    });
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
    if( doc == null ) return;
    for( Xml.Node* it=doc->get_root_element()->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "sticker") ) {
        var name = it->get_prop( "name" );
        string tooltip;
        if( _sticker_set.get_icon_info( name, out tooltip ) ) {
          create_image( _favorites, name, tooltip, true );
        }
      }
    }
    delete doc;
  }

  /* When the sticker drag begins, set the sticker image to the dragged content */
  private void on_drag_begin( Widget widget, DragContext context ) {
    var fbox  = (FlowBox)widget;
    var int_x = (int)_motion_x;
    var int_y = (int)_motion_y;
    _dragged_sticker = (Image)fbox.get_child_at_pos( int_x, int_y ).get_child();
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
        var search_keys = search_text.split(" ");
        foreach (string sk in search_keys) {
          if ( !item.get_child().get_tooltip_text().casefold().contains( sk ) ) {
            return( false );
          }
        }
        return( true );
      });
      _stack.set_visible_child_name( "matched" );
    }

  }

  /* Grabbing input focus on the first UI element */
  public void grab_first() {
    _search.grab_focus();
  }

  /* Imports one or more stickers from the filesystem and imports them into the given category */
  private void import_stickers( FlowBox fbox, string category ) {

    /* Get the file to open from the user */
    var dialog = new FileChooserNative( _( "Import Sticker(s)" ), _win, FileChooserAction.OPEN, _( "Import" ), _( "Cancel" ) ) {
      select_multiple = true
    };

    if( dialog.run() == ResponseType.ACCEPT ) {
      var stickers = dialog.get_filenames();
      stickers.foreach((sticker) => {
        var parts = Path.get_basename( sticker ).split( "." );
        if( _sticker_set.load_sticker( category, parts[0], sticker, true ) ) {
          string tooltip;
          _sticker_set.get_icon_info( sticker, out tooltip );
          create_image( fbox, sticker, tooltip, false );
          fbox.show_all();
        }
      });
    }

  }

}
