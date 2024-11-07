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
  private Picture       _dragged_sticker;
  private GLib.Menu     _favorite_menu;
  private GLib.Menu     _builtin_menu;
  private GLib.Menu     _custom_menu;
  private FlowBox       _clicked_category;
  private StickerSet    _sticker_set;
  private string        _clicked_sticker;

  public StickerInspector( MainWindow win, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _win      = win;
    _settings = settings;

    /* Setup menus */
    _favorite_menu = new GLib.Menu();
    _favorite_menu.append( _( "Remove From Favorites" ), "sticker.action_make_unfavorite" );

    _builtin_menu = new GLib.Menu();
    _builtin_menu.append( _( "Add To Favorites" ), "sticker.action_make_favorite" );

    var custom_fav_menu = new GLib.Menu();
    custom_fav_menu.append( _( "Add To Favorites" ), "sticker.action_make_favorite" );

    var custom_del_menu = new GLib.Menu();
    custom_del_menu.append( _( "Remove Custom Sticker" ), "sticker.action_remove" );

    _custom_menu = new GLib.Menu();
    _custom_menu.append_section( null, custom_fav_menu );
    _custom_menu.append_section( null, custom_del_menu );

    /* TODO
    _da.
    _builtin_menu.show.connect(() => {
      bi_favorite.set_sensitive( !is_favorite( _clicked_sticker ) );
    });

    _custom_menu.show.connect(() => {
      cu_favorite.set_sensitive( !is_favorite( _clicked_sticker ) );
    });
    *?


    /*
     Create instruction label (this will always be visible so it will not be
     within the scrolled box
    */
    var lbl = new Label( _( "Drag and drop sticker onto a node or anywhere else in the map to add a sticker." ) ) {
      wrap      = true,
      wrap_mode = Pango.WrapMode.WORD
    };

    /* Create search field */
    _search = new SearchEntry() {
      placeholder_text = _( "Search Stickers" )
    };
    _search.search_changed.connect( do_search );

    /* Create main scrollable pane */
    var box = new Box( Orientation.VERTICAL, 20 );
    var sw  = new ScrolledWindow() {
      child = box
    };
    var vp = (Viewport)sw.child;
    vp.set_size_request( 200, 600 );

    /* Create search result flowbox */
    _matched_box = create_icon_box( "" );

    var mbox = new Box( Orientation.VERTICAL, 0 );
    mbox.append( _matched_box );

    var msw = new ScrolledWindow() {
      child = mbox
    };
    msw.add_css_class( Granite.STYLE_CLASS_VIEW );

    /* Create stack */
    _stack = new Stack() {
      vexpand = true
    };
    _stack.add_named( sw,  "all" );
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

    box.append( show );

    /* Add the scrollable widget to the box */
    append( lbl );
    append( _search );
    append( _stack );

  }

  /* Creates the rest of the UI from the stickers XML file that is stored in a gresource */
  private void create_from_sticker_set( Box box ) {

    var categories = _sticker_set.get_categories();

    for( int i=0; i<categories.length; i++ ) {
      var category = create_category( box, categories.index( i ) );
      var icons    = _sticker_set.get_category_icons( categories.index( i ) );
      for( int j=0; j<icons.length; j++ ) {
        create_image( category,     icons.index( j ).resource, icons.index( j ).tooltip );
        create_image( _matched_box, icons.index( j ).resource, icons.index( j ).tooltip );
      }
      create_import( category );
    }

  }

  /* Creates the expander flowbox for the given category name and adds it to the sidebar */
  private FlowBox create_category( Box box, string name ) {

    /* Create the flowbox which will contain the stickers */
    var fbox = create_icon_box( name );

    /* Create expander */
    var exp = new Expander( Utils.make_title( name ) ) {
      use_markup = true,
      expanded   = true,
      child      = fbox
    };

    box.append( exp );

    return( fbox );

  }

  /* Creates the image from the given name and adds it to the flow box */
  private void create_image( FlowBox fbox, string name, string tooltip ) {
    var pixbuf = StickerSet.make_pixbuf( name );
    if( pixbuf != null ) {
      var texture = Texture.for_pixbuf( pixbuf );
      var img     = new Picture.for_paintable( texture ) {
        can_shrink   = false,
        name         = name,
        tooltip_text = tooltip
      };
      fbox.append( img );
    }
  }

  /* Adds an import image button to the given category flowbox */
  private void create_import( FlowBox box ) {
    var img = new Image.from_icon_name( "list-add-symbolic" ) {
      name = "",
      tooltip_text = _( "Add custom stickers" )
    };
    box.append( img );
  }

  /* Creates the icon box and sets it up */
  private FlowBox create_icon_box( string category ) {
    var fbox = new FlowBox() {
      homogeneous = true,
      selection_mode = SelectionMode.NONE
    };

    var drag = new DragSource() {
      actions = Gdk.DragAction.COPY
    };
    fbox.add_controller( drag );

    drag.prepare.connect((x, y) => {

      // Set icon
      _dragged_sticker = (Picture)fbox.get_child_at_pos( (int)x, (int)y ).get_child();
      drag.set_icon( _dragged_sticker.paintable, 0, 0 );

      // Set content to the name of the selected sticker
      var val = Value( typeof( Sticker ) );
      val.set_string( _dragged_sticker.name );
      var content = new ContentProvider.for_value( val );

      return( content );

    });

    var primary_click = new GestureClick() {
      button = Gdk.BUTTON_PRIMARY
    };
    fbox.add_controller( primary_click );
    primary_click.pressed.connect((n_press, x, y) => {
      if( fbox.get_child_at_pos( (int)x, (int)y ).get_child().name == "" ) {
        import_stickers( fbox, category );
      }
    });

    var secondary_click = new GestureClick() {
      button = Gdk.BUTTON_SECONDARY
    };
    fbox.add_controller( secondary_click );
    secondary_click.pressed.connect((n_press, x, y) => {
      var sticker = fbox.get_child_at_pos( (int)x, (int)y );
      _clicked_category = fbox;
      _clicked_sticker  = sticker.get_child().name;
      if( _clicked_sticker != "" ) {
        PopoverMenu popover;
        if( _clicked_category == _favorites ) {
          popover = new PopoverMenu.from_model( _favorite_menu );
        } else if( is_custom( _clicked_sticker ) ) {
          popover = new PopoverMenu.from_model( _custom_menu );
        } else {
          popover = new PopoverMenu.from_model( _builtin_menu );
        }
        popover.set_parent( sticker );
        popover.popup();
      }
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
      var index = 0;
      var w     = Utils.get_child_at_index( _clicked_category, index++ );
      while( w != null ) {
        if( (w as FlowBoxChild).get_child().name == _clicked_sticker ) {
          _clicked_category.remove( w );
          return;
        }
        w = Utils.get_child_at_index( _clicked_category, index++ );
      }
    }
  }

  /* Returns true if the given icon name is favorited */
  private bool is_favorite( string name ) {
    var index = 0;
    var w     = Utils.get_child_at_index( _favorites, index++ );
    while( w != null ) {
      if( (w as FlowBoxChild).get_child().name == name ) {
        return( true );
      }
    }
    return( false );
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
      create_image( _favorites, _clicked_sticker, tooltip );

      /* Save the favorited status */
      save_favorites();

    }

  }

  /* Remove the current sticker as a favorite */
  private void make_unfavorite() {
    var index = 0;
    var w     = Utils.get_child_at_index( _favorites, index++ );
    while( w != null ) {
      if( (w as FlowBoxChild).get_child().name == _clicked_sticker ) {
        _favorites.remove( w );
        save_favorites();
        return;
      }
      w = Utils.get_child_at_index( _favorites, index++ );
    }
  }

  /* Save the favorited stickers to the save file */
  private void save_favorites() {
    Xml.Doc*  doc  = new Xml.Doc();
    Xml.Node* root = new Xml.Node( null, "favorites" );
    doc->set_root_element( root );
    var index = 0;
    var w     = Utils.get_child_at_index( _favorites, index++ );
    while( w != null ) {
      var name = (w as FlowBoxChild).get_child().name;
      Xml.Node* n = new Xml.Node( null, "sticker" );
      n->set_prop( "name", name );
      root->add_child( n );
      w = Utils.get_child_at_index( _favorites, index++ );
    }
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
          create_image( _favorites, name, tooltip );
        }
      }
    }
    delete doc;
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

    var dialog = Utils.make_file_chooser( _( "Import Sticker(s)" ), _( "Import" ) );

    dialog.open_multiple.begin( _win, null, (obj, res) => {
      try {
        var files = dialog.open_multiple.end( res );
        if( files != null ) {
          for( int i=0; i<files.get_n_items(); i++ ) {
            var file    = (File)files.get_item( i );
            var sticker = file.get_path();
            var parts   = Path.get_basename( sticker ).split( "." );
            if( _sticker_set.load_sticker( category, parts[0], sticker, true ) ) {
              string tooltip;
              _sticker_set.get_icon_info( sticker, out tooltip );
              create_image( fbox, sticker, tooltip );
            }
          }
        }
      } catch( Error e ) {}
    });

  }

}
