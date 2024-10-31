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

public enum TabAddReason {
  NEW,
  OPEN,
  IMPORT,
  LOAD
}

public enum PropertyGrab {
  NONE,
  FIRST,
  NOTE
}

public enum SearchOptions {
  NODES,
  CONNECTIONS,
  CALLOUTS,
  GROUPS,
  TITLES,
  NOTES,
  FOLDED,
  UNFOLDED,
  TASKS,
  NONTASKS,
  NUM
}

public class MainWindow : Gtk.ApplicationWindow {

  private GLib.Settings     _settings;
  private HeaderBar         _header;
  private DynamicNotebook?  _nb             = null;
  private Revealer?         _inspector      = null;
  private Paned             _pane           = null;
  private Notebook?         _inspector_nb   = null;
  private Stack?            _stack          = null;
  private Popover?          _zoom           = null;
  private Popover?          _search         = null;
  private MenuButton?       _search_btn     = null;
  private SearchEntry?      _search_entry   = null;
  private TreeView          _search_list;
  private Gtk.ListStore     _search_items;
  private ScrolledWindow    _search_scroll;
  private CheckButton       _search_nodes;
  private CheckButton       _search_connections;
  private CheckButton       _search_callouts;
  private CheckButton       _search_groups;
  private CheckButton       _search_titles;
  private CheckButton       _search_notes;
  private CheckButton       _search_folded;
  private CheckButton       _search_unfolded;
  private CheckButton       _search_tasks;
  private CheckButton       _search_nontasks;
  private Switch            _search_all_tabs;
  private Exporter          _exporter;
  private Popover?          _export     = null;
  private MenuButton        _zoom_btn;
  private Scale?            _zoom_scale = null;
  private Button?           _zoom_in    = null;
  private Button?           _zoom_out   = null;
  private Button?           _undo_btn   = null;
  private Button?           _redo_btn   = null;
  private ToggleButton?     _focus_btn  = null;
  private ToggleButton?     _prop_btn   = null;
  private Image?            _prop_show  = null;
  private Image?            _prop_hide  = null;
  private bool              _debug      = false;
  private ThemeEditor       _themer;
  private Label             _scale_lbl;
  private int               _text_size;
  private Exports           _exports;
  private UnicodeInsert     _unicoder;

  private const GLib.ActionEntry[] action_entries = {
    { "action_save",           action_save },
    { "action_open_directory", do_open_directory },
    { "action_quit",           action_quit },
    { "action_zoom_in",        action_zoom_in },
    { "action_zoom_out",       action_zoom_out },
    { "action_zoom_fit",       action_zoom_fit },
    { "action_zoom_selected",  action_zoom_selected },
    { "action_zoom_actual",    action_zoom_actual },
  //  { "action_export",        action_export },
    { "action_print",          action_print },
    { "action_prefs",          action_prefs },
    { "action_shortcuts",      action_shortcuts },
    { "action_show_current",   action_show_current },
    { "action_show_style",     action_show_style },
    { "action_show_stickers",  action_show_stickers },
    { "action_show_map",       action_show_map },
    { "action_next_tab",       action_next_tab },
    { "action_prev_tab",       action_prev_tab }
  };

  private bool on_elementary = Gtk.Settings.get_default().gtk_icon_theme_name == "elementary";

  private delegate void ChangedFunc();

  public Themes themes { set; get; default = new Themes(); }
  public GLib.Settings settings {
    get {
      return( _settings );
    }
  }
  public int text_size {
    get {
      return( _text_size );
    }
  }
  public Exports exports {
    get {
      return( _exports );
    }
  }
  public UnicodeInsert unicoder {
    get {
      return( _unicoder );
    }
  }

  public signal void canvas_changed( DrawArea? da );

  /* Create the main window UI */
  public MainWindow( Gtk.Application app, GLib.Settings settings ) {

    Object( application: app );

    _settings = settings;

    var window_x = settings.get_int( "window-x" );
    var window_y = settings.get_int( "window-y" );
    var window_w = settings.get_int( "window-w" );
    var window_h = settings.get_int( "window-h" );

    /* Create the exports and load it */
    _exports = new Exports();

    /* Create the header bar */
    _header = new HeaderBar() {
      show_title_buttons = true,
      title_width        = new Label( _( "Minder" ) )
    };

    // Set the default window size to the last session size
    set_default_size( window_w, window_h );

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "win", actions );

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    /* Create the notebook */
    _nb = new DynamicNotebook();
    _nb.add_button_visible = false;
    _nb.tab_bar_behavior   = DynamicNotebook.TabBarBehavior.SINGLE;
    _nb.tab_switched.connect( tab_switched );
    _nb.tab_reordered.connect( tab_reordered );
    _nb.close_tab_requested.connect( close_tab_requested );
    _nb.tab_removed.connect( tab_removed );
    _nb.get_style_context().add_class( Gtk.STYLE_CLASS_INLINE_TOOLBAR );

    /* Create title toolbar */
    var new_btn = new Button.from_icon_name( get_icon_name( "document-new" ) ) {
      tooltip_markup = Utils.tooltip_with_accel( _( "New File" ), "<Control>n" ),
    };
    new_btn.clicked.connect( do_new_file );
    _header.pack_start( new_btn );

    var open_btn = new Button.from_icon_name( get_icon_name( "document-open" ), get_icon_size() );
    open_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Open File" ), "<Control>o" ) );
    open_btn.add_accelerator( "clicked", _accel_group, 'o', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
    open_btn.clicked.connect( do_open_file );
    _header.pack_start( open_btn );

    var save_btn = new Button.from_icon_name( get_icon_name( "document-save-as" ), get_icon_size() );
    save_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Save File As" ), "<Control><Shift>s" ) );
    save_btn.add_accelerator( "clicked", _accel_group, 's', (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK), AccelFlags.VISIBLE );
    save_btn.clicked.connect( do_save_as_file );
    _header.pack_start( save_btn );

    _undo_btn = new Button.from_icon_name( get_icon_name( "edit-undo" ), get_icon_size() );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Undo" ), "<Control>z" ) );
    _undo_btn.set_sensitive( false );
    _undo_btn.add_accelerator( "clicked", _accel_group, 'z', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
    _undo_btn.clicked.connect( do_undo );
    _header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( get_icon_name( "edit-redo" ), get_icon_size() );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Redo" ), "<Control><Shift>z" ) );
    _redo_btn.set_sensitive( false );
    _redo_btn.add_accelerator( "clicked", _accel_group, 'z', (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK), AccelFlags.VISIBLE );
    _redo_btn.clicked.connect( do_redo );
    _header.pack_start( _redo_btn );

    /* Create unicode inserter */
    _unicoder = new UnicodeInsert();

    /* Add the buttons on the right side in the reverse order */
    add_property_button();
    add_miscellaneous_button();
    add_export_button();
    add_search_button();
    add_zoom_button();
    add_focus_button();

    /* Create the panel so that we can resize */
    _pane = new Paned( Orientation.HORIZONTAL );
    _pane.pack1( _nb, true, true );
    _pane.move_handle.connect(() => {
      return( false );
    });
    _pane.button_release_event.connect((e) => {
      if( e.window == _pane.get_handle_window() ) {
        _settings.set_int( "properties-width", ((_pane.get_allocated_width() - _pane.position) - 11) );
      }
      return( false );
    });

    var top_box = new Box( Orientation.VERTICAL, 0 );
    top_box.pack_start( _header, false, true, 0 );
    top_box.pack_start( _pane, true, true, 0 );

    /* Display the UI */
    add( top_box );
    show_all();

    /* If the settings says to display the properties, do it now */
    if( _settings.get_boolean( "current-properties-shown" ) ) {
      show_properties( "current", PropertyGrab.NONE );
    } else if( _settings.get_boolean( "map-properties-shown" ) ) {
      show_properties( "map", PropertyGrab.NONE );
    } else if( _settings.get_boolean( "style-properties-shown" ) ) {
      show_properties( "style", PropertyGrab.NONE );
    } else if( _settings.get_boolean( "sticker-properties-shown" ) ) {
      show_properties( "sticker", PropertyGrab.NONE );
    }

    /* Look for any changes to the settings */
    _text_size = settings.get_boolean( "text-field-use-custom-font-size" ) ? settings.get_int( "text-field-custom-font-size" ) : -1;
    settings.changed.connect((key) => {
      switch( key ) {
        case "text-field-use-custom-font-size" :
        case "text-field-custom-font-size"     :  setting_changed_text_size();       break;
        case "enable-animations"               :  setting_changed_animations();      break;
        case "enable-ui-animations"            :  setting_changed_ui_animations();   break;
        case "auto-parse-embedded-urls"        :  setting_changed_embedded_urls();   break;
        case "enable-markdown"                 :  setting_changed_markdown();        break;
        case "enable-unicode-input"            :  setting_changed_unicode_input();   break;
      }
    });

    /* If we receive focus, update the titlebar */
    focus_in_event.connect((e) => {
      var da = get_current_da();
      update_title( da );
      return( false );
    });

    /* Load the exports data */
    _exports.load();

  }

  static construct {
    Hdy.init();
  }

  /* Returns the name of the icon to use for a headerbar icon */
  private string get_icon_name( string icon_name ) {
    return( "%s%s".printf( icon_name, (on_elementary ? "" : "-symbolic") ) );
  }

  private void setting_changed_text_size() {
    var value = settings.get_boolean( "text-field-use-custom-font-size" ) ? settings.get_int( "text-field-custom-font-size" ) : -1;
    _text_size = value;
    foreach( Tab tab in _nb.tabs ) {
      var bin = (Gtk.Bin)tab.page;
      var da  = (DrawArea)bin.get_child();
      da.update_css();
    }
  }

  /* Called whenever the enable-ui-animations glib setting is changed */
  private void setting_changed_ui_animations() {
    var duration = settings.get_boolean( "enable-ui-animations" ) ? 500 : 0;
    var current  = (_stack.get_child_by_name( "current" ) as CurrentInspector);
    _stack.set_transition_duration( duration );
    current.set_transition_duration( duration );
  }

  private void setting_changed_animations() {
    var value = settings.get_boolean( "enable-animations" );
    foreach( Tab tab in _nb.tabs ) {
      var bin = (Gtk.Bin)tab.page;
      var da  = (DrawArea)bin.get_child();
      da.animator.enable = value;
    }
  }

  private void setting_changed_embedded_urls() {
    var value = settings.get_boolean( "auto-parse-embedded-urls" );
    foreach( Tab tab in _nb.tabs ) {
      var bin = (Gtk.Bin)tab.page;
      var da  = (DrawArea)bin.get_child();
      da.url_parser.enable = value;
    }
  }

  private void setting_changed_markdown() {
    var value = settings.get_boolean( "enable-markdown" );
    foreach( Tab tab in _nb.tabs ) {
      var bin = (Gtk.Bin)tab.page;
      var da  = (DrawArea)bin.get_child();
      da.markdown_parser.enable = value;
    }
  }

  private void setting_changed_unicode_input() {
    var value = settings.get_boolean( "enable-unicode-input" );
    foreach( Tab tab in _nb.tabs ) {
      var bin = (Gtk.Bin)tab.page;
      var da  = (DrawArea)bin.get_child();
      da.unicode_parser.enable = value;
    }
  }

  /* Called whenever the current tab is switched in the notebook */
  private void tab_switched( Tab? old_tab, Tab new_tab ) {
    tab_changed( new_tab );
  }

  /* This needs to be called whenever the tab is changed */
  private void tab_changed( Tab tab ) {
    var bin = (Gtk.Bin)tab.page;
    var da  = bin.get_child() as DrawArea;
    do_buffer_changed( da.current_undo_buffer() );
    on_current_changed( da );
    update_title( da );
    canvas_changed( da );
    save_tab_state( tab );
  }

  /* Called whenever the current tab is moved to a new position */
  private void tab_reordered( Tab? tab, int new_pos ) {
    save_tab_state( tab );
  }

  /* Updates all of the node sizes in all tabs */
  public void update_node_sizes() {
    foreach( Tab tab in _nb.tabs ) {
      var bin = (Gtk.Bin)tab.page;
      var da  = (DrawArea)bin.get_child();
      da.update_node_sizes();
    }
  }

  /* Closes the current tab */
  public void close_current_tab() {
    _nb.current.close();
  }

  /* Closes the tab associated with the given drawing area */
  private void close_tab_with_da( DrawArea da ) {
    foreach( Tab tab in _nb.tabs ) {
      var bin     = (Gtk.Bin)tab.page;
      var curr_da = (DrawArea)bin.get_child();
      if( da == curr_da ) {
        tab.close();
        return;
      }
    }
  }

  /* Called whenever the user clicks on the close button and the tab is unnamed */
  private bool close_tab_requested( Tab tab ) {
    var bin = (Gtk.Bin)tab.page;
    var da  = bin.get_child() as DrawArea;
    var ret = (_nb.n_tabs > 1) && (!da.is_loaded || da.get_doc().is_saved() || show_save_warning( da ));
    return( ret );
  }

  /* This should be called when the tab page is actually gone */
  private void tab_removed( Tab tab ) {
    save_tab_state( _nb.current );
  }

  /* Creates a draw area */
  public DrawArea create_da() {
    var da = new DrawArea( this, _settings );
    return( da );
  }

  /* Adds a new tab to the notebook */
  public DrawArea add_tab( string? fname, TabAddReason reason ) {

    /* Create and pack the canvas */
    var da = new DrawArea( this, _settings );
    da.current_changed.connect( on_current_changed );
    da.scale_changed.connect( change_scale );
    da.scroll_changed.connect( change_origin );
    da.show_properties.connect( show_properties );
    da.hide_properties.connect( hide_properties );
    da.map_event.connect( on_canvas_mapped );
    da.undo_buffer.buffer_changed.connect( do_buffer_changed );
    da.undo_text.buffer_changed.connect( do_buffer_changed );
    da.theme_changed.connect( on_theme_changed );
    da.animator.enable = _settings.get_boolean( "enable-animations" );

    if( fname != null ) {
      da.get_doc().load_filename( fname, (reason == TabAddReason.OPEN) );
    }

    /* Create the overlay that will hold the canvas so that we can put an entry box for emoji support */
    var overlay = new Overlay();
    overlay.add( da );

    var tab = new Tab( da.get_doc().label, null, overlay );
    tab.pinnable = false;
    tab.tooltip  = fname;

    /* Update the titlebar */
    update_title( da );

    /* Make the drawing area new */
    if( reason == TabAddReason.NEW ) {
      da.initialize_for_new();
    } else {
      da.initialize_for_open();
    }

    /* Add the page to the notebook */
    _nb.insert_tab( tab, _nb.n_tabs );

    /* Indicate that the tab has changed */
    if( reason != TabAddReason.LOAD ) {
      _nb.current = tab;
    }

    da.grab_focus();

    return( da );

  }

  /*
   Closes all tabs that contain documents that have not been changed.
  */
  private void close_unchanged_tabs() {
    foreach( Tab tab in _nb.tabs ) {
      var bin = (Gtk.Bin)tab.page;
      var da  = (DrawArea)bin.get_child();
      if( !da.is_loaded ) {
        tab.close();
        return;
      }
    }
  }

  /*
   Searches the current tabs for an unchanged tab.  If one is found, make it the
   current tab.
  */
  private bool find_unchanged_tab() {
    foreach( Tab tab in _nb.tabs ) {
      var bin = (Gtk.Bin)tab.page;
      var da  = (DrawArea)bin.get_child();
      if( !da.is_loaded ) {
        _nb.current = tab;
        da.grab_focus();
        return( true );
      }
    }
    return( false );
  }

  /*
   Checks to see if any other tab contains the given filename.  If the filename
   is already found, refresh the tab with the file contents and make it the current
   tab; otherwise, add the new tab and populate it.
  */
  private DrawArea add_tab_conditionally( string? fname, TabAddReason reason ) {

    foreach( Tab tab in _nb.tabs ) {
      var bin = (Gtk.Bin)tab.page;
      var da  = (DrawArea)bin.get_child();
      if( da.get_doc().filename == fname ) {
        da.initialize_for_open();
        _nb.current = tab;
        return( da );
      }
    }

    return( add_tab( fname, reason ) );

  }

  public void next_tab() {
    _nb.next_page();
  }

  public void previous_tab() {
    _nb.previous_page();
  }

  /* Returns the current drawing area */
  public DrawArea? get_current_da( string? caller = null ) {
    if( _debug && (caller != null) ) {
      stdout.printf( "get_current_da called from %s\n", caller );
    }
    if( _nb.current == null ) { return( null ); }
    var bin = (Gtk.Bin)_nb.current.page;
    return( (DrawArea)bin.get_child() );
  }

  /* Updates the title */
  private void update_title( DrawArea? da ) {
    var suffix = " \u2014 Minder";
    if( (da == null) || !da.get_doc().is_saved() ) {
      _header.set_title( _( "Unnamed Document" ) + suffix );
    } else {
      if( da.get_doc().readonly ) {
        suffix = " [%s]%s".printf( _( "Read-Only" ), suffix );
      }
      _header.set_title( GLib.Path.get_basename( da.get_doc().filename ) + suffix );
    }
    _header.set_subtitle( _focus_btn.active ? _( "Focus Mode" ) : null );
  }

  /* Adds keyboard shortcuts for the menu actions */
  private void add_keyboard_shortcuts( Gtk.Application app ) {

    app.set_accels_for_action( "win.action_save",           { "<Control>s" } );
    app.set_accels_for_action( "win.action_open_directory", { "<Control><Shift>o" } );
    app.set_accels_for_action( "win.action_quit",           { "<Control>q" } );
    app.set_accels_for_action( "win.action_zoom_actual",    { "<Control>0" } );
    app.set_accels_for_action( "win.action_zoom_fit",       { "<Control>1" } );
    app.set_accels_for_action( "win.action_zoom_selected",  { "<Control>2" } );
    app.set_accels_for_action( "win.action_zoom_in",        { "<Control>plus" } );
    app.set_accels_for_action( "win.action_zoom_in",        { "<Control>equal" } );
    app.set_accels_for_action( "win.action_zoom_out",       { "<Control>minus" } );
    app.set_accels_for_action( "win.action_export",         { "<Control>e" } );
    app.set_accels_for_action( "win.action_print",          { "<Control>p" } );
    app.set_accels_for_action( "win.action_prefs",          { "<Control>comma" } );
    app.set_accels_for_action( "win.action_shortcuts",      { "<Control>question" } );
    app.set_accels_for_action( "win.action_show_current",   { "<Control>6" } );
    app.set_accels_for_action( "win.action_show_style",     { "<Control>7" } );
    app.set_accels_for_action( "win.action_show_stickers",  { "<Control>8" } );
    app.set_accels_for_action( "win.action_show_map",       { "<Control>9" } );
    app.set_accels_for_action( "win.action_next_tab",       { "<Control>Tab" } );
    app.set_accels_for_action( "win.action_prev_tab",       { "<Control><Shift>Tab" } );

  }

  /* Adds the zoom functionality */
  private void add_zoom_button() {

    var zoom_item = new GLib.MenuItem( null, null );
    zoom_item.set_attribute( "custom", "s", "scale" );

    var scale_menu = new GLib.Menu();
    scale_menu.append_item( zoom_item );

    var fit_menu = new GLib.Menu();
    fit_menu.append( _( "Zoom to Fit" ),                    "win.action_zoom_fit" );
    fit_menu.append( _( "Zoom to Fit Selected Node Tree" ), "win.action_zoom_selected" );
    fit_menu.append( _( "Zoom to Actual Size" ),            "win.action_zoom_actual" );

    var menu = new GLib.Menu();
    menu.append_section( null, scale_menu );
    menu.append_section( null, fit_menu );

    // Create scale UI in menu
    var marks   = DrawArea.get_scale_marks();
    _scale_lbl  = new Label( _( "Zoom to Percent" ) );
    _zoom_scale = new Scale.with_range( Orientation.HORIZONTAL, marks[0], marks[marks.length-1], 25 ) {
      has_origin = false,
      set_value  =  100
    };
    foreach (double mark in marks) {
      _zoom_scale.add_mark( mark, PositionType.BOTTOM, null );
    }
    _zoom_scale.change_value.connect( adjust_zoom );
    _zoom_scale.format_value.connect( set_zoom_value );

    _zoom_in = new Button.from_icon_name( "zoom-in-symbolic" ) {
      has_frame = false,
      can_focus = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Zoom In" ), "<Control>plus" )
    };
    _zoom_in.clicked.connect( action_zoom_in );

    _zoom_out = new Button.from_icon_name( "zoom-out-symbolic" ) {
      has_frame = false,
      can_focus = false,
      tooltip_markup = Utils.tooltip_with_accel( _( "Zoom Out" ), "<Control>minus" )
    };
    _zoom_out.clicked.connect( action_zoom_out );

    var zoom_box = new Box( Orientation.HORIZONTAL, 5 );
    zoom_box.append( _zoom_out );
    zoom_box.append( _zoom_scale );
    zoom_box.append( _zoom_in );

    var zbox = new Box( Orientation.VERTICAL, 5 );
    zbox.append( _scale_lbl );
    zbox.append( zoom_box );

    /* Create zoom menu popover */
    Box box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    box.append( _scale_lbl,  false, true );
    box.append( zoom_box,    true,  true );
    box.append( new Separator( Orientation.HORIZONTAL ), false, true );
    box.show_all();

    var popover = new PopoverMenu.from_model( menu );
    popover.add_child( zbox, "scale" );

    /* Create the menu button */
    _zoom_btn = new MenuButton() {
      icon_name    = get_icon_name( "zoom-fit-best" ),
      tooltip_text = _( "Zoom (%d%%)" ).printf( 100 ),
      popover      = popover
    };
    _header.pack_end( _zoom_btn );

  }

  /* Adds the search functionality */
  private void add_search_button() {

    /* Create the search entry field */
    _search_entry = new SearchEntry() {
      placeholder_text = _( "Search Nodes, Callouts and Connections" ),
      width_chars      = 60
    };
    _search_entry.search_changed.connect( on_search_change );

    _search_items = new Gtk.ListStore( 8, typeof(string), typeof(string), typeof(Node), typeof(Connection), typeof(Callout), typeof(NodeGroup), typeof(string), typeof(string) );

    /* Create the treeview */
    _search_list  = new TreeView.with_model( _search_items );
    var type_cell = new CellRendererText();
    var str_cell  = new CellRendererText();
    var tab_cell  = new CellRendererText();
    type_cell.xalign       = 1;
    str_cell.ellipsize     = Pango.EllipsizeMode.END;
    str_cell.ellipsize_set = true;
    str_cell.width_chars   = 50;
    _search_list.insert_column_with_attributes( -1, null, type_cell, "markup", 0, null );
    _search_list.insert_column_with_attributes( -1, null, str_cell,  "markup", 1, null );
    _search_list.insert_column_with_attributes( -1, null, tab_cell,  "markup", 7, null );
    _search_list.headers_visible = false;
    _search_list.activate_on_single_click = true;
    _search_list.enable_search = false;
    _search_list.row_activated.connect( on_search_clicked );

    /* Create the scrolled window for the treeview */
    _search_scroll = new ScrolledWindow() {
      height_request    = 200,
      hscrollbar_policy = PolicyType.EXTERNAL,
      child             = _search_list
    };

    var search_opts = new Expander( _( "Search Criteria" ) ) {
      child = create_search_options_box()
    };

    var search_all_label = new Label( _( "Search all tabs" ) ) {
      halign = Align.START
    };

    _search_all_tabs = new Switch() {
      halign = Align.END,
      active = _settings.get_boolean( "search-opt-all-tabs" )
    };
    _search_all_tabs.notify["active"].connect(() => {
      _settings.set_boolean( "search-opt-all-tabs", !_search_all_tabs.active );
      on_search_change();
    });

    var search_all_box = new Box( Orientation.HORIZONTAL, 0 );
    search_all_box.append( search_all_label );
    search_all_box.append( _search_all_tabs );

    // Create search popover
    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    box.append( _search_entry );
    box.append( _search_scroll );
    box.append( new Separator( Orientation.HORIZONTAL ) );
    box.append( search_opts );
    box.append( new Separator( Orientation.HORIZONTAL ) );
    box.append( search_all_box );

    /* Create the popover and associate it with the menu button */
    _search = new Popover() {
      child = box
    };

    /* Create the menu button */
    _search_btn = new MenuButton() {
      icon_name      = (on_elementary ? "minder-search" : "edit-find-symbolic"),
      tooltip_markup = Utils.tooltip_with_accel( _( "Search" ), "<Control>f" ),
      popover        = _search
    };
    // TODO - _search_btn.clicked.connect( on_search_change );
    _header.pack_end( _search_btn );

  }

  /* Creates the UI for the search criteria box */
  private Grid create_search_options_box() {

    _search_nodes       = new CheckButton.with_label( _( "Nodes" ) );
    _search_connections = new CheckButton.with_label( _( "Connections" ) );
    _search_callouts    = new CheckButton.with_label( _( "Callouts" ) );
    _search_groups      = new CheckButton.with_label( _( "Groups" ) );
    _search_titles      = new CheckButton.with_label( _( "Titles" ) );
    _search_notes       = new CheckButton.with_label( _( "Notes" ) );
    _search_folded      = new CheckButton.with_label( _( "Folded" ) );
    _search_unfolded    = new CheckButton.with_label( _( "Unfolded" ) );
    _search_tasks       = new CheckButton.with_label( _( "Tasks" ) );
    _search_nontasks    = new CheckButton.with_label( _( "Non-tasks" ) );

    /* Set the active values from the settings */
    _search_nodes.active       = _settings.get_boolean( "search-opt-nodes" );
    _search_connections.active = _settings.get_boolean( "search-opt-connections" );
    _search_callouts.active    = _settings.get_boolean( "search-opt-callouts" );
    _search_groups.active      = _settings.get_boolean( "search-opt-groups" );
    _search_titles.active      = _settings.get_boolean( "search-opt-titles" );
    _search_notes.active       = _settings.get_boolean( "search-opt-notes" );
    _search_folded.active      = _settings.get_boolean( "search-opt-folded" );
    _search_unfolded.active    = _settings.get_boolean( "search-opt-unfolded" );
    _search_tasks.active       = _settings.get_boolean( "search-opt-tasks" );
    _search_nontasks.active    = _settings.get_boolean( "search-opt-nontasks" );

    /* Set the checkbutton sensitivity */
    _search_nodes.set_sensitive( _search_callouts.active || _search_connections.active || _search_groups.active );
    _search_connections.set_sensitive( _search_nodes.active || _search_callouts.active || _search_groups.active );
    _search_callouts.set_sensitive( _search_nodes.active || _search_connections.active || _search_groups.active );
    _search_groups.set_sensitive( _search_nodes.active || _search_connections.active || _search_callouts.active );
    _search_titles.set_sensitive( _search_notes.active );
    _search_notes.set_sensitive( _search_titles.active );
    _search_folded.set_sensitive( _search_nodes.active && _search_unfolded.active );
    _search_unfolded.set_sensitive( _search_nodes.active && _search_folded.active );
    _search_tasks.set_sensitive( _search_nodes.active && _search_nontasks.active );
    _search_nontasks.set_sensitive( _search_nodes.active && _search_tasks.active );

    _search_nodes.toggled.connect(() => {
      bool nodes = _search_nodes.active;
      _settings.set_boolean( "search-opt-nodes", _search_nodes.active );
      _search_connections.set_sensitive( nodes || _search_callouts.active || _search_groups.active );
      _search_callouts.set_sensitive( nodes || _search_connections.active || _search_groups.active );
      _search_groups.set_sensitive( nodes || _search_connections.active || _search_callouts.active );
      _search_folded.set_sensitive( nodes );
      _search_unfolded.set_sensitive( nodes );
      _search_tasks.set_sensitive( nodes );
      _search_nontasks.set_sensitive( nodes );
      on_search_change();
    });
    _search_connections.toggled.connect(() => {
      _settings.set_boolean( "search-opt-connections", _search_connections.active );
      _search_nodes.set_sensitive( _search_connections.active || _search_callouts.active || _search_groups.active );
      _search_callouts.set_sensitive( _search_connections.active || _search_nodes.active || _search_groups.active );
      _search_groups.set_sensitive( _search_connections.active || _search_nodes.active || _search_callouts.active );
      on_search_change();
    });
    _search_callouts.toggled.connect(() => {
      _settings.set_boolean( "search-opt-callouts", _search_callouts.active );
      _search_nodes.set_sensitive( _search_callouts.active || _search_connections.active || _search_groups.active );
      _search_connections.set_sensitive( _search_callouts.active || _search_nodes.active || _search_groups.active );
      _search_groups.set_sensitive( _search_callouts.active || _search_connections.active || _search_nodes.active );
      on_search_change();
    });
    _search_groups.toggled.connect(() => {
      _settings.set_boolean( "search-opt-groups", _search_groups.active );
      _search_nodes.set_sensitive( _search_callouts.active || _search_connections.active || _search_groups.active );
      _search_connections.set_sensitive( _search_callouts.active || _search_nodes.active || _search_groups.active );
      _search_callouts.set_sensitive( _search_nodes.active || _search_connections.active || _search_groups.active );
      on_search_change();
    });
    _search_titles.toggled.connect(() => {
      _settings.set_boolean( "search-opt-titles", _search_titles.active );
      _search_notes.set_sensitive( _search_titles.active );
      on_search_change();
    });
    _search_notes.toggled.connect(() => {
      _settings.set_boolean( "search-opt-notes", _search_notes.active );
      _search_titles.set_sensitive( _search_notes.active );
      on_search_change();
    });
    _search_folded.toggled.connect(() => {
      _settings.set_boolean( "search-opt-folded", _search_folded.active );
      _search_unfolded.set_sensitive( _search_folded.active );
      on_search_change();
    });
    _search_unfolded.toggled.connect(() => {
      _settings.set_boolean( "search-opt-unfolded", _search_unfolded.active );
      _search_folded.set_sensitive( _search_unfolded.active );
      on_search_change();
    });
    _search_tasks.toggled.connect(() => {
      _settings.set_boolean( "search-opt-tasks", _search_tasks.active );
      _search_nontasks.set_sensitive( _search_tasks.active );
      on_search_change();
    });
    _search_nontasks.clicked.connect(() => {
      _settings.set_boolean( "search-opt-nontasks", _search_nontasks.active );
      _search_tasks.set_sensitive( _search_nontasks.active );
      on_search_change();
    });

    var grid = new Grid() {
      margin_top         = 10,
      column_homogeneous = true,
      column_spacing     = 10
    };
    grid.attach( _search_nodes,       0, 0 );
    grid.attach( _search_connections, 0, 1 );
    grid.attach( _search_callouts,    0, 2 );
    grid.attach( _search_groups,      0, 3 );
    grid.attach( _search_titles,      1, 0 );
    grid.attach( _search_notes,       1, 1 );
    grid.attach( _search_folded,      2, 0 );
    grid.attach( _search_unfolded,    2, 1 );
    grid.attach( _search_tasks,       3, 0 );
    grid.attach( _search_nontasks,    3, 1 );

    return( grid );

  }

  /* Adds the export functionality */
  private void add_export_button() {

    /* Create the menu button */
    var menu_btn = new MenuButton();
    menu_btn.set_image( new Image.from_icon_name( (on_elementary ? "document-export" : "document-send-symbolic"), get_icon_size() ) );
    menu_btn.set_tooltip_text( _( "Export" ) );
    _header.pack_end( menu_btn );

    /* Create export menu */
    _exporter = new Exporter( this );
    _exporter.export_done.connect(() => {
      Utils.hide_popover( menu_btn.popover );
    });

    /* Create print menu */
    var print = new ModelButton();
    print.get_child().destroy();
    print.add( new Granite.AccelLabel.from_action_name( _( "Print…" ), "win.action_print" ) );
    print.action_name = "win.action_print";

    var box = new Box( Orientation.VERTICAL, 5 );
    box.margin = 5;
    box.pack_start( _exporter, false, true );
    box.pack_start( new Separator( Orientation.HORIZONTAL ), false, true );
    box.pack_start( print,  false, true );
    box.show_all();

    /* Create the popover and associate it with clicking on the menu button */
    _export = new Popover( null );
    _export.add( box );
    menu_btn.popover = _export;

  }

  /* Adds the focus mode button to the headerbar */
  private void add_focus_button() {

    _focus_btn       = new ToggleButton();
    _focus_btn.image = new Image.from_icon_name( (on_elementary ? "minder-focus" : "media-optical-symbolic"), get_icon_size() );
    _focus_btn.draw_indicator = true;
    _focus_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Focus Mode" ), "<Control><Shift>f" ) );
    _focus_btn.add_accelerator( "clicked", _accel_group, 'f', (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK), AccelFlags.VISIBLE );
    _focus_btn.clicked.connect((e) => {
      var da = get_current_da();
      update_title( da );
      da.set_focus_mode( _focus_btn.active );
      da.grab_focus();
    });

    _header.pack_end( _focus_btn );

  }

  /* Adds the miscellaneous functionality */
  private void add_miscellaneous_button() {

    /* Create the menu button */
    var misc_btn = new MenuButton();
    misc_btn.set_image( new Image.from_icon_name( get_icon_name( "open-menu" ), get_icon_size() ) );

    /* Create export menu */
    var box = new Box( Orientation.VERTICAL, 5 );

    var prefs = new ModelButton();
    prefs.get_child().destroy();
    prefs.add( new Granite.AccelLabel.from_action_name( _( "Preferences" ), "win.action_prefs" ) );
    prefs.action_name = "win.action_prefs";

    var shortcuts = new ModelButton();
    shortcuts.get_child().destroy();
    shortcuts.add( new Granite.AccelLabel.from_action_name( _( "Shortcuts Cheatsheet" ), "win.action_shortcuts" ) );
    shortcuts.action_name = "win.action_shortcuts";

    var about = new ModelButton();
    about.text = _( "About Minder" );
    about.clicked.connect(() => {
      var about_win = new About( this );
      about_win.present();
    });

    box.margin = 5;
    box.pack_start( prefs,     false, true );
    box.pack_start( shortcuts, false, true );
    if( !on_elementary ) {
      box.pack_start( new Separator( Orientation.HORIZONTAL ), false, true );
      box.pack_start( about, false, true );
    }
    box.show_all();

    /* Create the popover and associate it with clicking on the menu button */
    var misc_pop = new Popover( null );
    misc_pop.add( box );
    misc_btn.popover = misc_pop;

    _header.pack_end( misc_btn );

  }

  /* Adds the property functionality */
  private void add_property_button() {

    /* Add the menubutton */
    _prop_show = new Image.from_icon_name( (on_elementary ? "minder-sidebar-open"  : "minder-sidebar-symbolic"), get_icon_size() );
    _prop_hide = new Image.from_icon_name( (on_elementary ? "minder-sidebar-close" : "minder-sidebar-symbolic"), get_icon_size() );
    _prop_btn  = new ToggleButton();
    _prop_btn.image  = _prop_show;
    _prop_btn.active = false;
    _prop_btn.set_tooltip_text( _( "Show Property Sidebar" ) );
    _prop_btn.add_accelerator( "clicked", _accel_group, Key.F9, 0, AccelFlags.VISIBLE );
    _prop_btn.toggled.connect( inspector_clicked );
    _header.pack_end( _prop_btn );

    /* Create the inspector sidebar */
    _inspector_nb = new Notebook();
    _inspector_nb.show_tabs = false;

    var box = new Box( Orientation.VERTICAL, 20 );
    var sb  = new StackSwitcher();

    _stack = new Stack();
    _stack.set_transition_type( StackTransitionType.SLIDE_LEFT_RIGHT );
    _stack.set_transition_duration( 500 );
    _stack.add_titled( new CurrentInspector( this ), "current", _("Current") );
    _stack.add_titled( new StyleInspector( this, _settings ), "style", _("Style") );
    _stack.add_titled( new StickerInspector( this, _settings ), "sticker", _("Stickers") );
    _stack.add_titled( new MapInspector( this, _settings ),  "map",  _("Map") );

    _stack.add_events( EventMask.KEY_PRESS_MASK );
    _stack.key_press_event.connect( stack_keypress );

    /* If the stack switcher is clicked, save off which tab is in view */
    _stack.notify.connect((ps) => {
      if( ps.name == "visible-child" ) {
        _settings.set_boolean( "current-properties-shown", (_stack.visible_child_name == "current") );
        _settings.set_boolean( "style-properties-shown",   (_stack.visible_child_name == "style" ) );
        _settings.set_boolean( "sticker-properties-shown", (_stack.visible_child_name == "sticker" ) );
        _settings.set_boolean( "map-properties-shown",     (_stack.visible_child_name == "map") );
      }
    });

    /* Handle the enable-ui-animations value */
    setting_changed_ui_animations();

    sb.homogeneous = true;
    sb.set_stack( _stack );

    box.margin = 5;
    box.pack_start( sb,     false, true, 0 );
    box.pack_start( _stack, true,  true, 0 );
    box.show_all();

    _themer = new ThemeEditor( this );

    _inspector_nb.append_page( box );
    _inspector_nb.append_page( _themer );

  }

  private bool stack_keypress( EventKey e ) {
    if( e.keyval == 65307 ) {  /* Escape key pressed */
      hide_properties();
      return( false );
    }
    return( true );
  }

  /* Show or hides the inspector sidebar */
  private void inspector_clicked() {
    if( _inspector_nb.get_mapped() ) {
      hide_properties();
    } else {
      show_properties( null, PropertyGrab.NONE );
    }
  }

  /* Displays the save warning dialog window */
  public bool show_save_warning( DrawArea da ) {

    var dialog = new Granite.MessageDialog.with_image_from_icon_name(
      _( "Save current unnamed document?" ),
      _( "Changes will be permanently lost if not saved." ),
      "dialog-warning",
      ButtonsType.NONE
    );

    var dont = new Button.with_label( _( "Discard Changes" ) );
    dialog.add_action_widget( dont, ResponseType.CLOSE );

    var cancel = new Button.with_label( _( "Cancel" ) );
    dialog.add_action_widget( cancel, ResponseType.CANCEL );

    var save = new Button.with_label( _( "Save" ) );
    save.set_can_default( true );
    save.get_style_context().add_class( STYLE_CLASS_SUGGESTED_ACTION );
    dialog.add_action_widget( save, ResponseType.ACCEPT );

    dialog.set_transient_for( this );
    dialog.set_default_response( ResponseType.ACCEPT );
    dialog.set_title( "" );

    dialog.show_all();

    var res = dialog.run();

    dialog.destroy();

    switch( res ) {
      case ResponseType.ACCEPT :  return( save_file( da ) );
      case ResponseType.CLOSE  :  return( da.get_doc().remove() );
    }

    return( false );

  }

  /* Displays the overwrite warning dialog window.
   * Returns true when overwrite is wanted and false when reload is wanted. */
  public bool ask_modified_overwrite( DrawArea da ) {

    var dialog = new Granite.MessageDialog.with_image_from_icon_name(
      _( "The file %s was modified outside of the application." ).printf( da.get_doc().filename ),
      _( "What do you want to do?" ),
      "dialog-warning",
      ButtonsType.NONE
    );

    var dont = new Button.with_label( _( "Discard Changes and reload" ) );
    dialog.add_action_widget( dont, ResponseType.CLOSE );

    var save = new Button.with_label( _( "Save local version and overwrite" ) );
    dialog.add_action_widget( save, ResponseType.ACCEPT );

    dialog.set_transient_for( this );
    dialog.set_title( "Overwrite or reload?" );

    dialog.show_all();

    var res = dialog.run();

    dialog.destroy();

    switch( res ) {
      case ResponseType.ACCEPT :  return true;
      case ResponseType.CLOSE  :  return false;
    }

    return( false );
  }

  /*
   Creates a new file
  */
  public void do_new_file() {

    /* Close any unchanged tabs */
    if( find_unchanged_tab() ) return;

    var da = add_tab( null, TabAddReason.NEW );

    /* Set the title to indicate that we have an unnamed document */
    update_title( da );

  }

  public void do_open_file() {
    do_open( false );
  }

  public void do_open_directory() {
    do_open( true );
  }

  /*
   Allows the user to select a file to open and opens it in the same window.
  */
  public void do_open( bool dir ) {

    /* Get the file to open from the user */
    var dialog   = new FileChooserNative(
      (dir ? _( "Open Directory" ) : _( "Open File" )),
      this,
      (dir ? FileChooserAction.SELECT_FOLDER : FileChooserAction.OPEN),
      _( "Open" ),
      _( "Cancel" )
    );
    // Utils.set_chooser_folder( dialog );

    /* Create file filters */
    if( !dir ) {
      var filter = new FileFilter();
      filter.set_filter_name( "Minder" );
      filter.add_pattern( "*.minder" );
      dialog.add_filter( filter );
    }

    for( int i=0; i<exports.length(); i++ ) {
      if( exports.index( i ).importable && (exports.index( i ).dir == dir) ) {
        var filter = new FileFilter();
        filter.set_filter_name( exports.index( i ).label );
        foreach( string extension in exports.index( i ).extensions ) {
          filter.add_pattern( "*" + extension );
        }
        dialog.add_filter( filter );
      }
    }

    if( dialog.run() == ResponseType.ACCEPT ) {
      var filename = dialog.get_filename();
      open_file( filename, dir );
      Utils.store_chooser_folder( filename, dir );
    }

    get_current_da( "do_open" ).grab_focus();

  }

  /* Opens the file and display it in the canvas */
  public bool open_file( string fname, bool dir ) {
    if( ( dir && !FileUtils.test( fname, FileTest.IS_DIR )) ||
        (!dir && !FileUtils.test( fname, FileTest.IS_REGULAR )) ) {
      return( false );
    }
    close_unchanged_tabs();
    if( fname.has_suffix( ".minder" ) ) {
      var da = add_tab_conditionally( fname, TabAddReason.OPEN );
      update_title( da );
      if( da.get_doc().load() ) {
        save_tab_state( _nb.current );
      }
      return( true );
    } else {
      for( int i=0; i<exports.length(); i++ ) {
        if( exports.index( i ).importable && (exports.index( i ).dir == dir) ) {
          string new_fname;
          if( exports.index( i ).filename_matches( fname, out new_fname ) ) {
            new_fname += ".minder";
            var da = add_tab_conditionally( new_fname, TabAddReason.IMPORT );
            update_title( da );
            if( exports.index( i ).import( fname, da ) ) {
              save_tab_state( _nb.current );
              return( true );
            }
            close_current_tab();
          }
        }
      }
    }
    return( false );
  }

  /* Imports the given file based on the export name */
  public bool import_file( string fname, string export_name, ref string new_fname ) {
    close_unchanged_tabs();
    for( int i=0; i<exports.length(); i++ ) {
      if( exports.index( i ).name == export_name ) {
        var da = add_tab_conditionally( null, TabAddReason.IMPORT );
        new_fname = da.get_doc().filename;
        update_title( da );
        if( exports.index( i ).import( fname, da ) ) {
          return( true );
        }
        close_current_tab();
      }
    }
    return( false );
  }

  /* Perform an undo action */
  public void do_undo() {
    var da = get_current_da( "do_undo" );
    da.current_undo_buffer().undo();
    da.grab_focus();
  }

  /* Perform a redo action */
  public void do_redo() {
    var da = get_current_da( "do_redo" );
    da.current_undo_buffer().redo();
    da.grab_focus();
  }

  private bool on_canvas_mapped( Gdk.EventAny e ) {
    get_current_da( "on_canvas_mapped" ).queue_draw();
    return( false );
  }

  /* Called whenever the theme is changed */
  private void on_theme_changed( DrawArea da ) {
    Gtk.Settings? settings = Gtk.Settings.get_default();
    if( settings != null ) {
      settings.gtk_application_prefer_dark_theme = da.get_theme().prefer_dark;
    }
  }

  /*
   Called whenever the undo buffer changes state.  Updates the state of
   the undo and redo buffer buttons.
  */
  public void do_buffer_changed( UndoBuffer buf ) {
    _undo_btn.set_sensitive( buf.undoable() );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buf.undo_tooltip(), "<Control>z" ) );
    _redo_btn.set_sensitive( buf.redoable() );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buf.redo_tooltip(), "<Control><Shift>z" ) );
  }

  /* Converts the given node name to an appropriate filename */
  private string convert_name_to_filename( string name ) {

    /* If the name contains newline characters, just use the first line */
    var first_line = name.split( "\n" )[0];
    var base_name  = first_line.delimit( "~!@#$%^&*+`={}[]|\\/,.<>?;:\"' \t", '-' );

    /* Remove consecutive - characters with a single dash */
    try {
      var re1 = new Regex( "-+" );
      var re2 = new Regex( "^-|-$" );
      base_name = re1.replace( base_name, base_name.length, 0, "-" );
      base_name = re2.replace( base_name, base_name.length, 0, "" );
    } catch( RegexError err ) {}

    return( base_name );

  }

  /* Allow the user to select a filename to save the document as */
  public bool save_file( DrawArea da ) {

    var dialog = new FileChooserNative( _( "Save File" ), this, FileChooserAction.SAVE, _( "Save" ), _( "Cancel" ) );
    Utils.set_chooser_folder( dialog );

    var filter = new FileFilter();
    var retval = false;
    filter.set_filter_name( _( "Minder" ) );
    filter.add_pattern( "*.minder" );
    dialog.add_filter( filter );
    if( da.get_doc().is_saved() ) {
      dialog.set_filename( da.get_doc().filename );
    } else {
      dialog.set_current_name( da.get_doc().label );
      if( da.get_nodes().length > 0 ) {
        var root_str = da.get_nodes().index( 0 ).name.text.text.strip();
        if( root_str != "" ) {
          dialog.set_current_name( convert_name_to_filename( root_str ) );
        }
      }
    }
    if( dialog.run() == ResponseType.ACCEPT ) {
      var fname = dialog.get_filename();
      if( fname.substring( -7, -1 ) != ".minder" ) {
        fname += ".minder";
      }
      da.get_doc().filename = fname;
      da.get_doc().save();
      _nb.current.label = da.get_doc().label;
      _nb.current.tooltip = fname;
      update_title( da );
      save_tab_state( _nb.current );
      retval = true;
      Utils.store_chooser_folder( fname, false );
    }
    da.grab_focus();
    return( retval );
  }

  /* Called when the save as button is clicked */
  public void do_save_as_file() {
    var da = get_current_da( "do_save_as_file" );
    save_file( da );
  }

  /* Called whenever the node selection changes in the canvas */
  private void on_current_changed( DrawArea da ) {
    set_action_enabled( "win.action_zoom_selected", (da.get_current_node() != null) );
    _focus_btn.active = da.get_focus_mode();
  }

  /*
   Called if the canvas changes the scale factor value. Adjusts the
   UI to match.
  */
  private void change_scale( double scale_factor ) {
    var marks       = DrawArea.get_scale_marks();
    var scale_value = scale_factor * 100;
    var int_value   = (int)scale_value;
    _zoom_btn.set_tooltip_text( _( "Zoom (%d%%)" ).printf( int_value ) );
    _zoom_scale.set_value( scale_value );
    _zoom_in.set_sensitive( scale_value < marks[marks.length-1] );
    _zoom_out.set_sensitive( scale_value > marks[0] );
    save_tab_state( _nb.current );
  }

  /* Called whenever the DrawArea origin changes in the current tab */
  private void change_origin() {
    save_tab_state( _nb.current );
  }

  /* Displays the node properties panel for the current node */
  private void show_properties( string? tab, PropertyGrab grab_type ) {
    if( !_inspector_nb.get_mapped() || ((tab != null) && (_stack.visible_child_name != tab)) ) {
      _prop_btn.image = _prop_hide;
      _prop_btn.set_tooltip_text( _( "Hide Property Sidebar" ) );
      _prop_btn.active = true;
      if( tab != null ) {
        _stack.visible_child_name = tab;
      }
      if( !_inspector_nb.get_mapped() ) {
        _pane.pack2( _inspector_nb, false, false );
        var prop_width = _settings.get_int( "properties-width" );
        var pane_width = _pane.get_allocated_width();
        if( pane_width <= 1 ) {
          pane_width = _settings.get_int( "window-w" ) + 4;
        }
        _pane.set_position( pane_width - (prop_width + 11) );
        if( get_current_da( "show_properties 1" ) != null ) {
          get_current_da( "show_properties 2" ).see( true, -300 );
        }
        _pane.show_all();
      }
      _settings.set_boolean( (_stack.visible_child_name + "-properties-shown"), true );
    }
    switch( grab_type ) {
      case PropertyGrab.FIRST :
        switch( _stack.visible_child_name ) {
          case "current" :  (_stack.get_child_by_name( "current" ) as CurrentInspector).grab_first();  break;
          case "style"   :  (_stack.get_child_by_name( "style" )   as StyleInspector).grab_first();    break;
          case "sticker" :  (_stack.get_child_by_name( "sticker" ) as StickerInspector).grab_first();  break;
          case "map"     :  (_stack.get_child_by_name( "map" )     as MapInspector).grab_first();      break;
        }
        break;
      case PropertyGrab.NOTE  :
        if( (tab != null) && (tab == "current") ) {
          var ci = _stack.get_child_by_name( tab ) as CurrentInspector;
          if( ci != null ) {
            ci.grab_note();
          }
        }
        break;
    }

  }

  /* Displays the theme editor pane */
  public void show_theme_editor( bool edit ) {
    _themer.initialize( get_current_da().get_theme(), edit );
    _inspector_nb.page = 1;
  }

  /* Hides the theme editor pane */
  public void hide_theme_editor() {
    _inspector_nb.page = 0;
  }

  /* Hides the node properties panel */
  private void hide_properties() {
    if( !_inspector_nb.get_mapped() ) return;
    _prop_btn.image         = _prop_show;
    _prop_btn.set_tooltip_text( _( "Show Property Sidebar" ) );
    _prop_btn.active        = false;
    _pane.position_set      = false;
    _pane.remove( _inspector_nb );
    get_current_da( "hide_properties" ).grab_focus();
    _settings.set_boolean( "current-properties-shown", false );
    _settings.set_boolean( "map-properties-shown",     false );
    _settings.set_boolean( "style-properties-shown",   false );
    _settings.set_boolean( "sticker-properties-shown", false );
  }

  /* Converts the given value from the scale to the zoom value to use */
  private double zoom_to_value( double value ) {
    double last = -1;
    foreach (double mark in DrawArea.get_scale_marks()) {
      if( last != -1 ) {
        if( value < ((mark + last) / 2) ) {
          return( last );
        }
      }
      last = mark;
    }
    return( last );
  }

  /* Sets the scale factor for the level of zoom to perform */
  private bool adjust_zoom( ScrollType scroll, double new_value ) {
    var value        = zoom_to_value( new_value );
    var scale_factor = value / 100;
    var da           = get_current_da( "adjust_zoom" );
    da.set_scaling_factor( scale_factor );
    da.queue_draw();
    return( false );
  }

  /* Returns the value to display in the zoom control */
  private string set_zoom_value( double val ) {
    return( zoom_to_value( val ).to_string() );
  }

  /* Called when the user uses the Control-s keyboard shortcut */
  private void action_save() {
    var da = get_current_da( "action_save" );
    if( da.get_doc().is_saved() ) {
      da.get_doc().save();
    } else {
      save_file( da );
    }
  }

  /* Called when the user uses the Control-q keyboard shortcut */
  private void action_quit() {
    destroy();
  }

  /* Zooms into the image (makes things larger) */
  private void action_zoom_in() {
    var da = get_current_da( "action_zoom_in" );
    da.zoom_in();
  }

  /* Zooms out of the image (makes things smaller) */
  private void action_zoom_out() {
    var da = get_current_da( "action_zoom_out" );
    da.zoom_out();
  }

  /* Zooms to make all nodes visible within the viewer */
  private void action_zoom_fit() {
    var da = get_current_da( "action_zoom_fit" );
    da.zoom_to_fit();
    da.grab_focus();
  }

  /* Zooms to make the currently selected node and its tree put into view */
  private void action_zoom_selected() {
    var da = get_current_da( "action_zoom_selected" );
    da.zoom_to_selected();
    da.grab_focus();
  }

  /* Sets the zoom to 100% */
  private void action_zoom_actual() {
    var da = get_current_da( "action_zoom_actual" );
    da.zoom_actual();
    da.grab_focus();
  }

  /* Display matched items to the search within the search popover */
  private void on_search_change() {
    var search_opts = new bool[SearchOptions.NUM];
    search_opts[SearchOptions.NODES]       = _search_nodes.active;
    search_opts[SearchOptions.CONNECTIONS] = _search_connections.active;
    search_opts[SearchOptions.CALLOUTS]    = _search_callouts.active;
    search_opts[SearchOptions.GROUPS]      = _search_groups.active;
    search_opts[SearchOptions.TITLES]      = _search_titles.active;
    search_opts[SearchOptions.NOTES]       = _search_notes.active;
    search_opts[SearchOptions.FOLDED]      = _search_folded.active;
    search_opts[SearchOptions.UNFOLDED]    = _search_unfolded.active;
    search_opts[SearchOptions.TASKS]       = _search_tasks.active;
    search_opts[SearchOptions.NONTASKS]    = _search_nontasks.active;
    _search_items.clear();
    var all_tabs = _settings.get_boolean( "search-opt-all-tabs" );
    var current  = get_current_da( "on_search_change" );
    var text     = _search_entry.get_text().casefold();
    var name     = all_tabs ? _nb.current.label : "";
    if( text == "" ) return;
    current.get_match_items( name, text, search_opts, ref _search_items );
    if( all_tabs ) {
      foreach (var tab in _nb.tabs ) {
        var bin = (Gtk.Bin)tab.page;
        var da = (DrawArea)bin.get_child();
        if( da != current ) {
          da.get_match_items( tab.label, text, search_opts, ref _search_items );
        }
      }
    }
  }

  /*
   Called when the user selects an item in the search list.  The current node
   will be set to the node associated with the selection.
  */
  private void on_search_clicked( TreePath path, TreeViewColumn col ) {
    TreeIter    it;
    string      tabname = "";
    Node?       node    = null;
    Connection? conn    = null;
    Callout?    callout = null;
    NodeGroup?  group   = null;
    DrawArea    da      = get_current_da( "on_search_clicked" );
    _search_items.get_iter( out it, path );
    _search_items.get( it, 2, &node, 3, &conn, 4, &callout, 5, &group, 6, &tabname, -1 );
    foreach (var tab in _nb.tabs ) {
      if(tab.label == tabname) {
        var bin = (Gtk.Bin)tab.page;
        da = (DrawArea)bin.get_child();
        _nb.current = tab;
        break;
      }
    }
    if( node != null ) {
      da.set_current_node( node );
      da.see();
    } else if( conn != null ) {
      da.set_current_connection( conn );
      da.see();
    } else if( callout != null ) {
      da.set_current_callout( callout );
      da.see();
    } else if( group != null ) {
      da.set_current_group( group );
      da.see();
    }
    _search.closed();
    da.grab_focus();
  }

  /*
   Checks the given filename to see if it contains any of the given suffixes.
   If a valid suffix is found, return the filename without modification; otherwise,
   returns the filename with the extension added.
  */
  public string repair_filename( string fname, string[] extensions ) {
    foreach (string ext in extensions) {
      if( fname.has_suffix( ext ) ) {
        return( fname );
      }
    }
    return( fname + extensions[0] );
  }

  /* Exports the model to the printer */
  private void action_print() {
    var print = new ExportPrint();
    print.print( get_current_da( "action_print" ), this );
  }

  /* Displays the preferences dialog */
  private void action_prefs() {
    var prefs = new Preferences( this, _settings );
    prefs.show_all();
  }

  /* Displays the shortcuts cheatsheet */
  private void action_shortcuts() {

    var builder = new Builder.from_resource( "/com/github/phase1geo/minder/shortcuts.ui" );
    var win     = builder.get_object( "shortcuts" ) as ShortcutsWindow;
    var da      = get_current_da();

    win.transient_for = this;
    win.view_name     = null;

    /* Display the most relevant information based on the current state */
    if( da.is_node_editable() || da.is_connection_editable() ) {
      win.section_name = "text-editing";
    } else if( da.is_node_selected() ) {
      win.section_name = "node";
    } else if( da.is_connection_selected() ) {
      win.section_name = "connection";
    } else {
      win.section_name = "general";
    }

    win.show();

  }

  /* Displays the current sidebar tab */
  private void action_show_current() {
    show_properties( "current", PropertyGrab.FIRST );
  }

  /* Displays the style sidebar tab */
  private void action_show_style() {
    show_properties( "style", PropertyGrab.FIRST );
  }

  /* Displays the stickers sidebar tab */
  private void action_show_stickers() {
    show_properties( "sticker", PropertyGrab.FIRST );
  }

  /* Displays the map sidebar tab */
  private void action_show_map() {
    show_properties( "map", PropertyGrab.FIRST );
  }

  /* Shows the next tab in the tabbar */
  private void action_next_tab() {
    _nb.next_page();
  }

  /* Shows the previous tab in the tabbar */
  private void action_prev_tab() {
    _nb.previous_page();
  }

  /* Save the current tab state */
  private void save_tab_state( Tab current_tab ) {

    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder" );

    if( DirUtils.create_with_parents( dir, 0775 ) != 0 ) {
      return;
    }

    var       fname        = GLib.Path.build_filename( dir, "tab_state.xml" );
    var       selected_tab = -1;
    var       i            = 0;
    Xml.Doc*  doc          = new Xml.Doc( "1.0" );
    Xml.Node* root         = new Xml.Node( null, "tabs" );

    doc->set_root_element( root );

    _nb.tabs.foreach((tab) => {
      var       bin  = (Gtk.Bin)tab.page;
      var       da   = (DrawArea)bin.get_child();
      Xml.Node* node = new Xml.Node( null, "tab" );
      node->new_prop( "path",  da.get_doc().filename );
      node->new_prop( "saved", da.get_doc().is_saved().to_string() );
      node->new_prop( "origin-x", da.origin_x.to_string() );
      node->new_prop( "origin-y", da.origin_y.to_string() );
      node->new_prop( "scale", da.sfactor.to_string() );
      root->add_child( node );
      if( tab == current_tab ) {
        selected_tab = i;
      }
      i++;
    });

    if( selected_tab > -1 ) {
      root->new_prop( "selected", selected_tab.to_string() );
    }

    /* Save the file */
    doc->save_format_file( fname, 1 );

    delete doc;

  }

  /* Loads the tab state */
  public void load_tab_state() {

    var tab_state = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "tab_state.xml" );
    if( !FileUtils.test( tab_state, FileTest.EXISTS ) ) {
      do_new_file();
      return;
    }

    Xml.Doc* doc  = Xml.Parser.parse_file( tab_state );
    var      tabs = 0;
    var      tab_skipped = false;

    if( doc == null ) {
      do_new_file();
      return;
    }

    var root = doc->get_root_element();
    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tab") ) {
        var fname = it->get_prop( "path" );
        if( FileUtils.test( fname, FileTest.EXISTS ) ) {
          var saved    = it->get_prop( "saved" );
          var origin_x = it->get_prop( "origin-x" );
          var origin_y = it->get_prop( "origin-y" );
          var sfactor  = it->get_prop( "scale" );
          var da = add_tab( fname, TabAddReason.LOAD );
          if( origin_x != null ) {
            da.origin_x = int.parse( origin_x );
          }
          if( origin_y != null ) {
            da.origin_y = int.parse( origin_y );
          }
          if( sfactor != null ) {
            da.sfactor = double.parse( sfactor );
            change_scale( da.sfactor );
          }
          da.get_doc().load_filename( fname, bool.parse( saved ) );
          if( da.get_doc().load() ) {
            tabs++;
          }
        } else {
          tab_skipped = true;
        }
      }
    }

    if( tabs == 0 ) {
      do_new_file();
    } else if( !tab_skipped ) {
      var s = root->get_prop( "selected" );
      if( s != null ) {
        _nb.current = _nb.get_tab_by_index( int.parse( s ) );
        tab_changed( _nb.current );
      }
    }

    // Save the tab state if we did something
    if( tab_skipped ) {
      save_tab_state( _nb.current );
    }

    delete doc;

  }

  /* Returns the height of a single line label */
  public int get_label_height() {
    int min_height, nat_height;
    _scale_lbl.get_preferred_height( out min_height, out nat_height );
    return( nat_height );
  }

  /* Generate a notification */
  public void notification( string title, string msg, NotificationPriority priority = NotificationPriority.NORMAL ) {
    GLib.Application? app = null;
    @get( "application", ref app );
    if( app != null ) {
      var notification = new Notification( title );
      notification.set_body( msg );
      notification.set_priority( priority );
      app.send_notification( "com.github.phase1geo.minder", notification );
    }
  }

}

