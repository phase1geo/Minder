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

public class MainWindow : ApplicationWindow {

  private const string DESKTOP_SCHEMA = "io.elementary.desktop";
  private const string DARK_KEY       = "prefer-dark";

  private GLib.Settings     _settings;
  private HeaderBar?        _header         = null;
  private Gtk.AccelGroup?   _accel_group    = null;
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
  private CheckButton       _search_titles;
  private CheckButton       _search_notes;
  private CheckButton       _search_folded;
  private CheckButton       _search_unfolded;
  private CheckButton       _search_tasks;
  private CheckButton       _search_nontasks;
  private Popover?          _export         = null;
  private Scale?            _zoom_scale     = null;
  private ModelButton?      _zoom_in        = null;
  private ModelButton?      _zoom_out       = null;
  private ModelButton?      _zoom_sel       = null;
  private Button?           _undo_btn       = null;
  private Button?           _redo_btn       = null;
  private ToggleButton?     _focus_btn      = null;
  private Button?           _prop_btn       = null;
  private Image?            _prop_show      = null;
  private Image?            _prop_hide      = null;
  private bool              _prefer_dark    = false;
  private bool              _debug          = false;
  private ThemeEditor       _themer;
  private Label             _scale_lbl;
  private int               _text_size;

  private const GLib.ActionEntry[] action_entries = {
    { "action_save",          action_save },
    { "action_quit",          action_quit },
    { "action_zoom_in",       action_zoom_in },
    { "action_zoom_out",      action_zoom_out },
    { "action_zoom_fit",      action_zoom_fit },
    { "action_zoom_selected", action_zoom_selected },
    { "action_zoom_actual",   action_zoom_actual },
    { "action_export",        action_export },
    { "action_print",         action_print },
    { "action_prefs",         action_prefs },
    { "action_shortcuts",     action_shortcuts },
    { "action_show_current",  action_show_current },
    { "action_show_style",    action_show_style },
    { "action_show_stickers", action_show_stickers },
    { "action_show_map",      action_show_map }
  };

  private bool     on_elementary = Gtk.Settings.get_default().gtk_icon_theme_name == "elementary";
  private IconSize icon_size;

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

  public signal void canvas_changed( DrawArea? da );

  /* Create the main window UI */
  public MainWindow( Gtk.Application app, GLib.Settings settings ) {

    Object( application: app );

    _settings = settings;
    icon_size = on_elementary ? IconSize.LARGE_TOOLBAR : IconSize.SMALL_TOOLBAR;

    /* Handle any changes to the dark mode preference setting */
    handle_prefer_dark_changes();

    var window_x = settings.get_int( "window-x" );
    var window_y = settings.get_int( "window-y" );
    var window_w = settings.get_int( "window-w" );
    var window_h = settings.get_int( "window-h" );

    /* Create the header bar */
    _header = new HeaderBar();
    _header.set_show_close_button( true );

    /* Set the main window data */
    title = _( "Minder" );
    if( (window_x == -1) && (window_y == -1) ) {
      set_position( Gtk.WindowPosition.CENTER );
    } else {
      move( window_x, window_y );
    }
    set_default_size( window_w, window_h );
    set_titlebar( _header );
    set_border_width( 2 );
    destroy.connect( Gtk.main_quit );

    /* Set the stage for menu actions */
    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "win", actions );

    /* Create the accelerator group for the window */
    _accel_group = new Gtk.AccelGroup();
    this.add_accel_group( _accel_group );

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    /* Create the notebook */
    _nb = new DynamicNotebook();
    _nb.add_button_visible = false;
    _nb.tab_bar_behavior   = DynamicNotebook.TabBarBehavior.SINGLE;
    _nb.tab_switched.connect( tab_switched );
    _nb.tab_reordered.connect( tab_reordered );
    _nb.close_tab_requested.connect( close_tab_requested );
    _nb.get_style_context().add_class( Gtk.STYLE_CLASS_INLINE_TOOLBAR );

    /* Create title toolbar */
    var new_btn = new Button.from_icon_name( (on_elementary ? "document-new" : "document-new-symbolic"), icon_size );
    new_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "New File" ), "<Control>n" ) );
    new_btn.add_accelerator( "clicked", _accel_group, 'n', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
    new_btn.clicked.connect( do_new_file );
    _header.pack_start( new_btn );

    var open_btn = new Button.from_icon_name( (on_elementary ? "document-open" : "document-open-symbolic"), icon_size );
    open_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Open File" ), "<Control>o" ) );
    open_btn.add_accelerator( "clicked", _accel_group, 'o', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
    open_btn.clicked.connect( do_open_file );
    _header.pack_start( open_btn );

    var save_btn = new Button.from_icon_name( (on_elementary ? "document-save-as" : "document-save-as-symbolic"), icon_size );
    save_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Save File As" ), "<Control><Shift>s" ) );
    save_btn.add_accelerator( "clicked", _accel_group, 's', (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK), AccelFlags.VISIBLE );
    save_btn.clicked.connect( do_save_as_file );
    _header.pack_start( save_btn );

    _undo_btn = new Button.from_icon_name( (on_elementary ? "edit-undo" : "edit-undo-symbolic"), icon_size );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Undo" ), "<Control>z" ) );
    _undo_btn.set_sensitive( false );
    _undo_btn.add_accelerator( "clicked", _accel_group, 'z', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
    _undo_btn.clicked.connect( do_undo );
    _header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( (on_elementary ? "edit-redo" : "edit-redo-symbolic"), icon_size );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Redo" ), "<Control><Shift>z" ) );
    _redo_btn.set_sensitive( false );
    _redo_btn.add_accelerator( "clicked", _accel_group, 'z', (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK), AccelFlags.VISIBLE );
    _redo_btn.clicked.connect( do_redo );
    _header.pack_start( _redo_btn );

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
      _settings.set_int( "properties-width", ((_pane.get_allocated_width() - _pane.position) - 11) );
      return( false );
    });

    /* Display the UI */
    add( _pane );
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
    settings.changed.connect(() => {
      var ts = settings.get_boolean( "text-field-use-custom-font-size" ) ? settings.get_int( "text-field-custom-font-size" ) : -1;
      var ae = settings.get_boolean( "enable-animations" );
      var ap = settings.get_boolean( "auto-parse-embedded-urls" );
      var em = settings.get_boolean( "enable-markdown" );
      _text_size = ts;
      foreach( Tab tab in _nb.tabs ) {
        var bin = (Gtk.Bin)tab.page;
        var da  = (DrawArea)bin.get_child();
        da.update_css();
        da.animator.enable = ae;
        da.url_parser.enable = ap;
        da.markdown_parser.enable = em;
      }
    });

  }

  /* Called whenever the current tab is switched in the notebook */
  private void tab_switched( Tab? old_tab, Tab new_tab ) {
    tab_changed( new_tab );
  }

  /* This needs to be called whenever the tab is changed */
  private void tab_changed( Tab tab ) {
    var bin = (Gtk.Bin)tab.page;
    var da  = bin.get_child() as DrawArea;
    do_buffer_changed( da.undo_buffer );
    on_current_changed( da );
    update_title( da );
    canvas_changed( da );
    save_tab_state( tab );
  }

  /* Called whenever the current tab is moved to a new position */
  private void tab_reordered( Tab? tab, int new_pos ) {
    save_tab_state( tab );
  }

  /* Closes the current tab */
  public void close_current_tab() {
    if( _nb.n_tabs == 1 ) return;
    _nb.current.close();
  }

  /* Called whenever the user clicks on the close button and the tab is unnamed */
  private bool close_tab_requested( Tab tab ) {
    var bin = (Gtk.Bin)tab.page;
    var da  = bin.get_child() as DrawArea;
    var ret = da.get_doc().is_saved() || show_save_warning( da );
    return( ret );
  }

  /* Adds a new tab to the notebook */
  public DrawArea add_tab( string? fname, TabAddReason reason ) {

    /* Create and pack the canvas */
    var da = new DrawArea( this, _settings, _accel_group );
    da.current_changed.connect( on_current_changed );
    da.scale_changed.connect( change_scale );
    da.show_properties.connect( show_properties );
    da.hide_properties.connect( hide_properties );
    da.map_event.connect( on_canvas_mapped );
    da.undo_buffer.buffer_changed.connect( do_buffer_changed );
    da.theme_changed.connect( on_theme_changed );
    da.animator.enable = _settings.get_boolean( "enable-animations" );

    if( fname != null ) {
      da.get_doc().filename = fname;
    }

    /* Create the overlay that will hold the canvas so that we can put an entry box for emoji support */
    var overlay = new Overlay();
    overlay.add( da );

    var tab = new Tab( da.get_doc().label, null, overlay );
    tab.pinnable = false;
    tab.tooltip  = fname;

    /* Add the page to the notebook */
    _nb.insert_tab( tab, _nb.n_tabs );

    /* Update the titlebar */
    update_title( da );

    /* Make the drawing area new */
    if( reason == TabAddReason.NEW ) {
      da.initialize_for_new();
    } else {
      da.initialize_for_open();
    }

    /* Indicate that the tab has changed */
    if( reason != TabAddReason.LOAD ) {
      _nb.current = tab;
    }

    da.grab_focus();

    return( da );

  }

  /*
   Checks to see if any other tab contains the given filename.  If the filename
   is already found, refresh the tab with the file contents and make it the current
   tab; otherwise, add the new tab and populate it.
  */
  private DrawArea add_tab_conditionally( string fname, TabAddReason reason ) {

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

  /* Returns the current drawing area */
  public DrawArea? get_current_da( string? caller = null ) {
    if( _debug && (caller != null) ) {
      stdout.printf( "get_current_da called from %s\n", caller );
    }
    if( _nb.current == null ) { return( null ); }
    var bin = (Gtk.Bin)_nb.current.page;
    return( (DrawArea)bin.get_child() );
  }

  /* Handles any changes to the dark mode preference gsettings for the desktop */
  private void handle_prefer_dark_changes() {
    var lookup = SettingsSchemaSource.get_default().lookup( DESKTOP_SCHEMA, false );
    if( lookup != null ) {
      var desktop_settings = new GLib.Settings( DESKTOP_SCHEMA );
      _prefer_dark = desktop_settings.get_boolean( DARK_KEY );
      desktop_settings.changed.connect(() => {
        _prefer_dark = desktop_settings.get_boolean( DARK_KEY );
        on_theme_changed( get_current_da( "handle_prefer_dark_changes" ) );
      });
    }
  }

  /* Updates the title */
  private void update_title( DrawArea? da ) {
    var suffix = " \u2014 Minder";
    if( (da == null) || !da.get_doc().is_saved() ) {
      _header.set_title( _( "Unnamed Document" ) + suffix );
    } else {
      _header.set_title( GLib.Path.get_basename( da.get_doc().filename ) + suffix );
    }
    _header.set_subtitle( _focus_btn.active ? _( "Focus Mode" ) : null );
  }

  /* Adds keyboard shortcuts for the menu actions */
  private void add_keyboard_shortcuts( Gtk.Application app ) {

    app.set_accels_for_action( "win.action_save",          { "<Control>s" } );
    app.set_accels_for_action( "win.action_quit",          { "<Control>q" } );
    app.set_accels_for_action( "win.action_zoom_actual",   { "<Control>0" } );
    app.set_accels_for_action( "win.action_zoom_fit",      { "<Control>1" } );
    app.set_accels_for_action( "win.action_zoom_in",       { "<Control>plus" } );
    app.set_accels_for_action( "win.action_zoom_out",      { "<Control>minus" } );
    app.set_accels_for_action( "win.action_export",        { "<Control>e" } );
    app.set_accels_for_action( "win.action_print",         { "<Control>p" } );
    app.set_accels_for_action( "win.action_prefs",         { "<Control>comma" } );
    app.set_accels_for_action( "win.action_shortcuts",     { "F1" } );
    app.set_accels_for_action( "win.action_show_current",  { "<Control>6" } );
    app.set_accels_for_action( "win.action_show_style",    { "<Control>7" } );
    app.set_accels_for_action( "win.action_show_stickers", { "<Control>8" } );
    app.set_accels_for_action( "win.action_show_map",      { "<Control>9" } );

  }

  /* Adds the zoom functionality */
  private void add_zoom_button() {

    /* Create the menu button */
    var menu_btn = new MenuButton();
    menu_btn.set_image( new Image.from_icon_name( (on_elementary ? "zoom-fit-best" : "zoom-fit-best-symbolic"), icon_size ) );
    menu_btn.set_tooltip_text( _( "Zoom" ) );
    _header.pack_end( menu_btn );

    /* Create zoom menu popover */
    Box box = new Box( Orientation.VERTICAL, 5 );

    var marks   = DrawArea.get_scale_marks();
    _scale_lbl  = new Label( _( "Zoom to Percent" ) );
    _zoom_scale = new Scale.with_range( Orientation.HORIZONTAL, marks[0], marks[marks.length-1], 25 );
    foreach (double mark in marks) {
      _zoom_scale.add_mark( mark, PositionType.BOTTOM, null );
    }
    _zoom_scale.has_origin = false;
    _zoom_scale.set_value( 100 );
    _zoom_scale.change_value.connect( adjust_zoom );
    _zoom_scale.format_value.connect( set_zoom_value );

    _zoom_in = new ModelButton();
    _zoom_in.get_child().destroy();
    _zoom_in.add( new Granite.AccelLabel.from_action_name( _( "Zoom In" ), "win.action_zoom_in" ) );
    _zoom_in.action_name = "win.action_zoom_in";

    _zoom_out = new ModelButton();
    _zoom_out.get_child().destroy();
    _zoom_out.add( new Granite.AccelLabel.from_action_name( _( "Zoom Out" ), "win.action_zoom_out" ) );
    _zoom_out.action_name = "win.action_zoom_out";

    var fit = new ModelButton();
    fit.get_child().destroy();
    fit.add( new Granite.AccelLabel.from_action_name( _( "Zoom to Fit" ), "win.action_zoom_fit" ) );
    fit.action_name = "win.action_zoom_fit";

    _zoom_sel = new ModelButton();
    _zoom_sel.get_child().destroy();
    _zoom_sel.add( new Granite.AccelLabel.from_action_name( _( "Zoom to Fit Selected Node" ), "win.action_zoom_selected" ) );
    _zoom_sel.action_name = "win.action_zoom_selected";

    var actual = new ModelButton();
    actual.get_child().destroy();
    actual.add( new Granite.AccelLabel.from_action_name( _( "Zoom to Actual Size" ), "win.action_zoom_actual" ) );
    actual.action_name = "win.action_zoom_actual";

    box.margin = 5;
    box.pack_start( _scale_lbl,  false, true );
    box.pack_start( _zoom_scale, false, true );
    box.pack_start( new Separator( Orientation.HORIZONTAL ), false, true );
    box.pack_start( _zoom_in,    false, true );
    box.pack_start( _zoom_out,   false, true );
    box.pack_start( new Separator( Orientation.HORIZONTAL ), false, true );
    box.pack_start( fit,         false, true );
    box.pack_start( _zoom_sel,   false, true );
    box.pack_start( actual,      false, true );
    box.show_all();

    _zoom = new Popover( null );
    _zoom.add( box );
    menu_btn.popover = _zoom;

  }

  /* Adds the search functionality */
  private void add_search_button() {

    /* Create the menu button */
    _search_btn = new MenuButton();
    _search_btn.set_image( new Image.from_icon_name( "minder-search", icon_size ) );
    _search_btn.set_tooltip_markup( Utils.tooltip_with_accel( _( "Search" ), "<Control>f" ) );
    _search_btn.add_accelerator( "clicked", _accel_group, 'f', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
    _search_btn.clicked.connect( on_search_change );
    _header.pack_end( _search_btn );

    /* Create search popover */
    var box = new Box( Orientation.VERTICAL, 5 );

    /* Create the search entry field */
    _search_entry = new SearchEntry();
    _search_entry.placeholder_text = _( "Search Nodes and Connections" );
    _search_entry.width_chars = 60;
    _search_entry.search_changed.connect( on_search_change );

    _search_items = new Gtk.ListStore( 4, typeof(string), typeof(string), typeof(Node), typeof(Connection) );

    /* Create the treeview */
    _search_list  = new TreeView.with_model( _search_items );
    var type_cell = new CellRendererText();
    type_cell.xalign = 1;
    _search_list.insert_column_with_attributes( -1, null, type_cell,              "markup", 0, null );
    _search_list.insert_column_with_attributes( -1, null, new CellRendererText(), "markup", 1, null );
    _search_list.headers_visible = false;
    _search_list.activate_on_single_click = true;
    _search_list.enable_search = false;
    _search_list.row_activated.connect( on_search_clicked );

    /* Create the scrolled window for the treeview */
    _search_scroll = new ScrolledWindow( null, null );
    _search_scroll.height_request = 200;
    _search_scroll.hscrollbar_policy = PolicyType.EXTERNAL;
    _search_scroll.add( _search_list );

    var search_opts = new Expander( _( "Search Criteria" ) );
    search_opts.add( create_search_options_box() );

    box.margin = 5;
    box.pack_start( _search_entry,  false, true );
    box.pack_start( _search_scroll, true,  true );
    box.pack_start( new Separator( Orientation.HORIZONTAL ) );
    box.pack_start( search_opts,    false, true, 5 );
    box.show_all();

    /* Create the popover and associate it with the menu button */
    _search = new Popover( null );
    _search.add( box );
    _search_btn.popover = _search;

  }

  /* Creates the UI for the search criteria box */
  private Grid create_search_options_box() {

    var grid = new Grid();

    _search_nodes       = new CheckButton.with_label( _( "Nodes" ) );
    _search_connections = new CheckButton.with_label( _( "Connections" ) );
    _search_titles      = new CheckButton.with_label( _( "Titles" ) );
    _search_notes       = new CheckButton.with_label( _( "Notes" ) );
    _search_folded      = new CheckButton.with_label( _( "Folded" ) );
    _search_unfolded    = new CheckButton.with_label( _( "Unfolded" ) );
    _search_tasks       = new CheckButton.with_label( _( "Tasks" ) );
    _search_nontasks    = new CheckButton.with_label( _( "Non-tasks" ) );

    /* Set the active values from the settings */
    _search_nodes.active       = _settings.get_boolean( "search-opt-nodes" );
    _search_connections.active = _settings.get_boolean( "search-opt-connections" );
    _search_titles.active      = _settings.get_boolean( "search-opt-titles" );
    _search_notes.active       = _settings.get_boolean( "search-opt-notes" );
    _search_folded.active      = _settings.get_boolean( "search-opt-folded" );
    _search_unfolded.active    = _settings.get_boolean( "search-opt-unfolded" );
    _search_tasks.active       = _settings.get_boolean( "search-opt-tasks" );
    _search_nontasks.active    = _settings.get_boolean( "search-opt-nontasks" );

    /* Set the checkbutton sensitivity */
    _search_nodes.set_sensitive( _search_connections.active );
    _search_connections.set_sensitive( _search_nodes.active );
    _search_titles.set_sensitive( _search_notes.active );
    _search_notes.set_sensitive( _search_titles.active );
    _search_folded.set_sensitive( _search_nodes.active && _search_unfolded.active );
    _search_unfolded.set_sensitive( _search_nodes.active && _search_folded.active );
    _search_tasks.set_sensitive( _search_nodes.active && _search_nontasks.active );
    _search_nontasks.set_sensitive( _search_nodes.active && _search_tasks.active );

    _search_nodes.toggled.connect(() => {
      bool nodes = _search_nodes.active;
      _settings.set_boolean( "search-opt-nodes", _search_nodes.active );
      _search_connections.set_sensitive( nodes );
      _search_folded.set_sensitive( nodes );
      _search_unfolded.set_sensitive( nodes );
      _search_tasks.set_sensitive( nodes );
      _search_nontasks.set_sensitive( nodes );
      on_search_change();
    });
    _search_connections.toggled.connect(() => {
      _settings.set_boolean( "search-opt-connections", _search_connections.active );
      _search_nodes.set_sensitive( _search_connections.active );
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

    grid.margin_top         = 10;
    grid.column_homogeneous = true;
    grid.column_spacing     = 10;
    grid.attach( _search_nodes,       0, 0, 1, 1 );
    grid.attach( _search_connections, 0, 1, 1, 1 );
    grid.attach( _search_titles,      1, 0, 1, 1 );
    grid.attach( _search_notes,       1, 1, 1, 1 );
    grid.attach( _search_folded,      2, 0, 1, 1 );
    grid.attach( _search_unfolded,    2, 1, 1, 1 );
    grid.attach( _search_tasks,       3, 0, 1, 1 );
    grid.attach( _search_nontasks,    3, 1, 1, 1 );

    return( grid );

  }

  /* Adds the export functionality */
  private void add_export_button() {

    /* Create the menu button */
    var menu_btn = new MenuButton();
    menu_btn.set_image( new Image.from_icon_name( (on_elementary ? "document-export" : "document-send-symbolic"), icon_size ) );
    menu_btn.set_tooltip_text( _( "Export" ) );
    _header.pack_end( menu_btn );

    /* Create export menu */
    var box = new Box( Orientation.VERTICAL, 5 );

    var export = new ModelButton();
    export.get_child().destroy();
    export.add( new Granite.AccelLabel.from_action_name( _( "Export…" ), "win.action_export" ) );
    export.action_name = "win.action_export";

    var print = new ModelButton();
    print.get_child().destroy();
    print.add( new Granite.AccelLabel.from_action_name( _( "Print…" ), "win.action_print" ) );
    print.action_name = "win.action_print";

    box.margin = 5;
    box.pack_start( export, false, true );
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
    _focus_btn.image = new Image.from_icon_name( "minder-focus", icon_size );
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
    misc_btn.set_image( new Image.from_icon_name( (on_elementary ? "open-menu" : "open-menu-symbolic"), icon_size ) );

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

    box.margin = 5;
    box.pack_start( prefs,     false, true );
    box.pack_start( new Separator( Orientation.HORIZONTAL ), false, true );
    box.pack_start( shortcuts, false, true );
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
    _prop_show = new Image.from_icon_name( "minder-sidebar-open",  icon_size );
    _prop_hide = new Image.from_icon_name( "minder-sidebar-close", icon_size );
    _prop_btn  = new Button();
    _prop_btn.image = _prop_show;
    _prop_btn.set_tooltip_text( _( "Properties" ) );
    _prop_btn.add_accelerator( "clicked", _accel_group, '|', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
    _prop_btn.clicked.connect( inspector_clicked );
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
        _settings.set_boolean( "style-properties-shown", (_stack.visible_child_name == "style" ) );
        _settings.set_boolean( "sticker-properties-shown", (_stack.visible_child_name == "sticker" ) );
        _settings.set_boolean( "map-properties-shown",  (_stack.visible_child_name == "map") );
      }
    });

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

  /*
   Creates a new file
  */
  public void do_new_file() {

    var da = add_tab( null, TabAddReason.NEW );

    /* Set the title to indicate that we have an unnamed document */
    update_title( da );

  }

  /*
   Allows the user to select a file to open and opens it in the same window.
  */
  public void do_open_file() {

    /* Get the file to open from the user */
    FileChooserNative dialog = new FileChooserNative( _( "Open File" ), this, FileChooserAction.OPEN, _( "Open" ), _( "Cancel" ) );

    /* Create file filters */
    var filter = new FileFilter();
    filter.set_filter_name( "Minder" );
    filter.add_pattern( "*.minder" );
    dialog.add_filter( filter );

    filter = new FileFilter();
    filter.set_filter_name( "Freemind / Freeplane" );
    filter.add_pattern( "*.mm" );
    dialog.add_filter( filter );

    filter = new FileFilter();
    filter.set_filter_name( "OPML" );
    filter.add_pattern( "*.opml" );
    dialog.add_filter( filter );

    filter = new FileFilter();
    filter.set_filter_name( "Outliner" );
    filter.add_pattern( "*.outliner" );
    dialog.add_filter( filter );

    filter = new FileFilter();
    filter.set_filter_name( _( "PlainText" ) );
    filter.add_pattern( "*.txt" );
    dialog.add_filter( filter );

    filter = new FileFilter();
    filter.set_filter_name( _( "PlantUML" ) );
    filter.add_pattern( "*.puml" );
    dialog.add_filter( filter );

    filter = new FileFilter();
    filter.set_filter_name( _( "Portable Minder" ) );
    filter.add_pattern( "*.pminder" );
    dialog.add_filter( filter );

    filter = new FileFilter();
    filter.set_filter_name( _( "XMind 8" ) );
    filter.add_pattern( "*.xmind" );
    dialog.add_filter( filter );

    if( dialog.run() == ResponseType.ACCEPT ) {
      open_file( dialog.get_filename() );
    }

    get_current_da( "do_open_file" ).grab_focus();

  }

  /* Opens the file and display it in the canvas */
  public bool open_file( string fname ) {
    if( !FileUtils.test( fname, FileTest.IS_REGULAR ) ) {
      return( false );
    }
    if( fname.has_suffix( ".minder" ) ) {
      var da = add_tab_conditionally( fname, TabAddReason.OPEN );
      update_title( da );
      da.get_doc().load();
      return( true );
    } else if( fname.has_suffix( ".opml" ) ) {
      var new_fname = fname.substring( 0, (fname.length - 5) ) + ".minder";
      var da        = add_tab_conditionally( new_fname, TabAddReason.IMPORT );
      update_title( da );
      ExportOPML.import( fname, da );
      return( true );
    } else if( fname.has_suffix( ".mm" ) ) {
      var new_fname = fname.substring( 0, (fname.length - 3) ) + ".minder";
      var da        = add_tab_conditionally( new_fname, TabAddReason.IMPORT );
      update_title( da );
      ExportFreeplane.import( fname, da );
      return( true );
    } else if( fname.has_suffix( ".txt" ) ) {
      var new_fname = fname.substring( 0, (fname.length - 4) ) + ".minder";
      var da        = add_tab_conditionally( new_fname, TabAddReason.IMPORT );
      update_title( da );
      ExportText.import( fname, da );
    } else if( fname.has_suffix( ".outliner" ) ) {
      var new_fname = fname.substring( 0, (fname.length - 9) ) + ".minder";
      var da        = add_tab_conditionally( new_fname, TabAddReason.IMPORT );
      update_title( da );
      ExportOutliner.import( fname, da );
    } else if( fname.has_suffix( ".pminder" ) ) {
      var new_fname = fname.substring( 0, (fname.length - 8) ) + ".minder";
      var da        = add_tab_conditionally( new_fname, TabAddReason.IMPORT );
      update_title( da );
      ExportPortableMinder.import( fname, da );
    } else if( fname.has_suffix( ".xmind" ) ) {
      var new_fname = fname.substring( 0, (fname.length - 6) ) + ".minder";
      var da        = add_tab_conditionally( new_fname, TabAddReason.IMPORT );
      update_title( da );
      ExportXMind.import( fname, da );
    } else if( fname.has_suffix( ".puml" ) ) {
      var new_fname = fname.substring( 0, (fname.length - 5) ) + ".minder";
      var da        = add_tab_conditionally( new_fname, TabAddReason.IMPORT );
      update_title( da );
      ExportPlantUML.import( fname, da );
    }
    return( false );
  }


  /* Perform an undo action */
  public void do_undo() {
    var da = get_current_da( "do_undo" );
    da.undo_buffer.undo();
    da.grab_focus();
  }

  /* Perform a redo action */
  public void do_redo() {
    var da = get_current_da( "do_redo" );
    da.undo_buffer.redo();
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
      settings.gtk_application_prefer_dark_theme = _prefer_dark || da.get_theme().prefer_dark;
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
    var filter = new FileFilter();
    var retval = false;
    filter.set_filter_name( _( "Minder" ) );
    filter.add_pattern( "*.minder" );
    dialog.add_filter( filter );
    if( da.get_doc().is_saved() ) {
      dialog.set_filename( da.get_doc().filename );
    } else {
      dialog.set_current_name( convert_name_to_filename( da.get_nodes().index( 0 ).name.text.text.strip() ) );
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
    _zoom_sel.set_sensitive( da.get_current_node() != null );
    if( da.get_focus_mode() ) {
      _focus_btn.active = true;
      _focus_btn.set_sensitive( true );
    } else {
      _focus_btn.active = false;
      _focus_btn.set_sensitive( da.get_current_node() != null );
    }
  }

  /*
   Called if the canvas changes the scale factor value. Adjusts the
   UI to match.
  */
  private void change_scale( double scale_factor ) {
    var marks       = DrawArea.get_scale_marks();
    var scale_value = scale_factor * 100;
    _zoom_scale.set_value( scale_value );
    _zoom_in.set_sensitive( scale_value < marks[marks.length-1] );
    _zoom_out.set_sensitive( scale_value > marks[0] );
  }

  /* Displays the node properties panel for the current node */
  private void show_properties( string? tab, PropertyGrab grab_type ) {
    if( !_inspector_nb.get_mapped() || ((tab != null) && (_stack.visible_child_name != tab)) ) {
      _prop_btn.image = _prop_hide;
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
          get_current_da( "show_properties 2" ).see( -300 );
        }
        _pane.show_all();
      }
      _settings.set_boolean( (_stack.visible_child_name + "-properties-shown"), true );
    }
    switch( grab_type ) {
      case PropertyGrab.FIRST :
        if( tab != null ) {
          var box = (Box)_stack.get_child_by_name( tab );
          box.get_children().foreach((item) => {
            if( item.can_focus ) {
              item.grab_focus();
              return;
            }
          });
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
    da.grab_focus();
  }

  /* Zooms out of the image (makes things smaller) */
  private void action_zoom_out() {
    var da = get_current_da( "action_zoom_out" );
    da.zoom_out();
    da.grab_focus();
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
    bool[] search_opts = {
      _search_nodes.active,       // 0
      _search_connections.active, // 1
      _search_titles.active,      // 2
      _search_notes.active,       // 3
      _search_folded.active,      // 4
      _search_unfolded.active,    // 5
      _search_tasks.active,       // 6
      _search_nontasks.active     // 7
    };
    _search_items.clear();
    if( _search_entry.get_text() != "" ) {
      get_current_da( "on_search_change" ).get_match_items(
        _search_entry.get_text().casefold(),
        search_opts,
        ref _search_items
      );
    }
  }

  /*
   Called when the user selects an item in the search list.  The current node
   will be set to the node associated with the selection.
  */
  private void on_search_clicked( TreePath path, TreeViewColumn col ) {
    TreeIter    it;
    Node?       node = null;
    Connection? conn = null;
    var         da   = get_current_da( "on_search_clicked" );
    _search_items.get_iter( out it, path );
    _search_items.get( it, 2, &node, 3, &conn, -1 );
    if( node != null ) {
      da.set_current_connection( null );
      da.set_current_node( node );
      da.see();
    } else if( conn != null ) {
      da.set_current_node( null );
      da.set_current_connection( conn );
      da.see();
    }
    _search.closed();
    da.grab_focus();
  }

  /* Exports the model to various formats */
  private void action_export() {

    // FileChooserNative dialog = new FileChooserNative( _( "Export As" ), this, FileChooserAction.SAVE, _( "Export" ), _( "Cancel" ) );
    FileChooserDialog dialog = new FileChooserDialog( _( "Export As" ), this, FileChooserAction.SAVE,
      _( "Cancel" ), ResponseType.CANCEL, _( "Export" ), ResponseType.ACCEPT );

    /* BMP */
    FileFilter bmp_filter = new FileFilter();
    bmp_filter.set_filter_name( _( "BMP" ) );
    bmp_filter.add_pattern( "*.bmp" );
    dialog.add_filter( bmp_filter );

    /* CSV */
    FileFilter csv_filter = new FileFilter();
    csv_filter.set_filter_name( _( "CSV" ) );
    csv_filter.add_pattern( "*.csv" );
    dialog.add_filter( csv_filter );

    /* FreeMind */
    FileFilter fm_filter = new FileFilter();
    fm_filter.set_filter_name( _( "Freemind" ) );
    fm_filter.add_pattern( "*.mm" );
    dialog.add_filter( fm_filter );

    /* Freeplane */
    FileFilter fp_filter = new FileFilter();
    fp_filter.set_filter_name( _( "Freeplane" ) );
    fp_filter.add_pattern( "*.mm" );
    dialog.add_filter( fp_filter );

    /* JPEG */
    FileFilter jpeg_filter = new FileFilter();
    jpeg_filter.set_filter_name( _( "JPEG" ) );
    jpeg_filter.add_pattern( "*.jpeg" );
    jpeg_filter.add_pattern( "*.jpg" );
    dialog.add_filter( jpeg_filter );

    /* Markdown */
    FileFilter md_filter = new FileFilter();
    md_filter.set_filter_name( _( "Markdown" ) );
    md_filter.add_pattern( "*.md" );
    md_filter.add_pattern( "*.markdown" );
    dialog.add_filter( md_filter );

    /* Mermaid */
    FileFilter mmd_filter = new FileFilter();
    mmd_filter.set_filter_name( _( "Mermaid" ) );
    mmd_filter.add_pattern( "*.mmd" );
    dialog.add_filter( mmd_filter );

    /* OPML */
    FileFilter opml_filter = new FileFilter();
    opml_filter.set_filter_name( _( "OPML" ) );
    opml_filter.add_pattern( "*.opml" );
    dialog.add_filter( opml_filter );

    /* Org-Mode */
    FileFilter org_filter = new FileFilter();
    org_filter.set_filter_name( _( "Org-Mode" ) );
    org_filter.add_pattern( "*.org" );
    dialog.add_filter( org_filter );

    /* Outliner */
    FileFilter outliner_filter = new FileFilter();
    outliner_filter.set_filter_name( _( "Outliner" ) );
    outliner_filter.add_pattern( "*.outliner" );
    dialog.add_filter( outliner_filter );

    /* PDF */
    FileFilter pdf_filter = new FileFilter();
    pdf_filter.set_filter_name( _( "PDF" ) );
    pdf_filter.add_pattern( "*.pdf" );
    dialog.add_filter( pdf_filter );

    /* PlantUML */
    FileFilter puml_filter = new FileFilter();
    puml_filter.set_filter_name( _( "PlantUML" ) );
    puml_filter.add_pattern( ".puml" );
    dialog.add_filter( puml_filter );

    /* PNG (transparent) */
    FileFilter pngt_filter = new FileFilter();
    pngt_filter.set_filter_name( _( "PNG (Transparent)" ) );
    pngt_filter.add_pattern( "*.png" );
    dialog.add_filter( pngt_filter );

    /* PNG (opaque) */
    FileFilter pngo_filter = new FileFilter();
    pngo_filter.set_filter_name( _( "PNG (Opaque)" ) );
    pngo_filter.add_pattern( "*.png" );
    dialog.add_filter( pngo_filter );

    /* PlainText */
    FileFilter txt_filter = new FileFilter();
    txt_filter.set_filter_name( _( "PlainText" ) );
    txt_filter.add_pattern( "*.txt" );
    dialog.add_filter( txt_filter );

    /* PortableMinder */
    FileFilter pmind_filter = new FileFilter();
    pmind_filter.set_filter_name( _( "Portable Minder" ) );
    pmind_filter.add_pattern( "*.pminder" );
    dialog.add_filter( pmind_filter );

    /* SVG */
    FileFilter svg_filter = new FileFilter();
    svg_filter.set_filter_name( _( "SVG" ) );
    svg_filter.add_pattern( "*.svg" );
    dialog.add_filter( svg_filter );

    /* XMind */
    FileFilter xmind_filter = new FileFilter();
    xmind_filter.set_filter_name( _( "XMind 8" ) );
    xmind_filter.add_pattern( "*.xmind" );
    dialog.add_filter( xmind_filter );

    /* yEd */
    FileFilter yed_filter = new FileFilter();
    yed_filter.set_filter_name( _( "yEd" ) );
    yed_filter.add_pattern( "*.graphml" );
    dialog.add_filter( yed_filter );

    if( dialog.run() == ResponseType.ACCEPT ) {

      var fname  = dialog.get_filename();
      var filter = dialog.get_filter();
      var da     = get_current_da( "action_export" );

      if( bmp_filter == filter ) {
        ExportImage.export( fname = repair_filename( fname, {".bmp"} ), "bmp", da );
      } else if( csv_filter == filter ) {
        ExportCSV.export( fname = repair_filename( fname, {".csv"} ), da );
      } else if( fm_filter == filter ) {
        ExportFreemind.export( fname = repair_filename( fname, {".mm"} ), da );
      } else if( fp_filter == filter ) {
        ExportFreeplane.export( fname = repair_filename( fname, {".mm"} ), da );
      } else if( jpeg_filter == filter ) {
        ExportImage.export( fname = repair_filename( fname, {".jpeg", ".jpg"} ), "jpeg", da );
      } else if( md_filter == filter ) {
        ExportMarkdown.export( fname = repair_filename( fname, {".md", ".markdown"} ), da );
      } else if( mmd_filter == filter ) {
        ExportMermaid.export( fname = repair_filename( fname, {".mmd"} ), da );
      } else if( opml_filter == filter ) {
        ExportOPML.export( fname = repair_filename( fname, {".opml"} ), da );
      } else if( org_filter == filter ) {
        ExportOrgMode.export( fname = repair_filename( fname, {".org"} ), da );
      } else if( outliner_filter == filter ) {
        ExportOutliner.export( fname = repair_filename( fname, {".outliner"} ), da );
      } else if( pdf_filter == filter ) {
        ExportPDF.export( fname = repair_filename( fname, {".pdf"} ), da );
      } else if( puml_filter == filter ) {
        ExportPlantUML.export( fname = repair_filename( fname, {".puml"} ), da );
      } else if( pngt_filter == filter ) {
        ExportPNG.export( fname = repair_filename( fname, {".png"} ), da, true );
      } else if( pngo_filter == filter ) {
        ExportPNG.export( fname = repair_filename( fname, {".png"} ), da, false );
      } else if( pmind_filter == filter ) {
        ExportPortableMinder.export( fname = repair_filename( fname, {".pminder"} ), da );
      } else if( txt_filter == filter ) {
        ExportText.export( fname = repair_filename( fname, {".txt"} ), da );
      } else if( svg_filter == filter ) {
        ExportSVG.export( fname = repair_filename( fname, {".svg"} ), da );
      } else if( xmind_filter == filter ) {
        ExportXMind.export( fname = repair_filename( fname, {".xmind"} ), da );
      } else if( yed_filter == filter ) {
        ExportYed.export( fname = repair_filename( fname, {".graphml"} ), da );
      }

      /* Generate notification to indicate that the export completed */
      notification( _( "Minder Export Completed" ), fname );

    }

    dialog.close();

  }

  /*
   Checks the given filename to see if it contains any of the given suffixes.
   If a valid suffix is found, return the filename without modification; otherwise,
   returns the filename with the extension added.
  */
  private string repair_filename( string fname, string[] extensions ) {
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
  public bool load_tab_state() {

    var      tab_state = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "tab_state.xml" );
    Xml.Doc* doc       = Xml.Parser.parse_file( tab_state );

    if( doc == null ) { return( false ); }

    var root = doc->get_root_element();
    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tab") ) {
        var fname = it->get_prop( "path" );
        var saved = it->get_prop( "saved" );
        var da    = add_tab( fname, TabAddReason.LOAD );
        da.get_doc().load_filename( fname, bool.parse( saved ) );
        da.get_doc().load();
      }
    }

    var s = root->get_prop( "selected" );
    if( s != null ) {
      _nb.current = _nb.get_tab_by_index( int.parse( s ) );
      tab_changed( _nb.current );
    }

    delete doc;

    return( _nb.n_tabs > 0 );

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

