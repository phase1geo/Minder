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

public class MainWindow : ApplicationWindow {

  private const string DESKTOP_SCHEMA = "io.elementary.desktop";
  private const string DARK_KEY       = "prefer-dark";

  private GLib.Settings     _settings;
  private HeaderBar?        _header         = null;
  private DrawArea?         _canvas         = null;
  private Document?         _doc            = null;
  private Revealer?         _inspector      = null;
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
  private Button?           _prop_btn       = null;
  private Image?            _prop_show      = null;
  private Image?            _prop_hide      = null;
  private bool              _prefer_dark    = false;

  private const GLib.ActionEntry[] action_entries = {
    { "action_save",          action_save },
    { "action_quit",          action_quit },
    { "action_zoom_in",       action_zoom_in },
    { "action_zoom_out",      action_zoom_out },
    { "action_zoom_fit",      action_zoom_fit },
    { "action_zoom_selected", action_zoom_selected },
    { "action_zoom_actual",   action_zoom_actual },
    { "action_export",        action_export },
    { "action_print",         action_print }
  };

  private bool on_elementary = Gtk.Settings.get_default().gtk_icon_theme_name == "elementary";

  private delegate void ChangedFunc();

  /* Create the main window UI */
  public MainWindow( Gtk.Application app, GLib.Settings settings ) {

    Object( application: app );

    _settings = settings;

    /* Handle any changes to the dark mode preference setting */
    handle_prefer_dark_changes();

    var window_x = settings.get_int( "window-x" );
    var window_y = settings.get_int( "window-y" );
    var window_w = settings.get_int( "window-w" );
    var window_h = settings.get_int( "window-h" );

    /* Create the header bar */
    _header = new HeaderBar();
    _header.set_show_close_button( true );
    update_title();

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

    AccelGroup accel_group = new Gtk.AccelGroup();
    this.add_accel_group( accel_group );

    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    /* Create and pack the canvas */
    _canvas = new DrawArea( accel_group );
    _canvas.current_changed.connect( on_current_changed );
    _canvas.scale_changed.connect( change_scale );
    _canvas.show_properties.connect( show_properties );
    _canvas.hide_properties.connect( hide_properties );
    _canvas.map_event.connect( on_canvas_mapped );
    _canvas.undo_buffer.buffer_changed.connect( do_buffer_changed );
    _canvas.theme_changed.connect( on_theme_changed );
    _canvas.animator.enable = _settings.get_boolean( "enable-animations" );

    /* Create title toolbar */
    var new_btn = on_elementary
      ? new Button.from_icon_name( "document-new", IconSize.LARGE_TOOLBAR )
      : new Button.from_icon_name( "document-new-symbolic" );
    new_btn.set_tooltip_markup( _( "New File   <i>(Control-N)</i>" ) );
    new_btn.add_accelerator( "clicked", accel_group, 'n', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
    new_btn.clicked.connect( do_new_file );
    _header.pack_start( new_btn );

    var open_btn = on_elementary
      ? new Button.from_icon_name( "document-open", IconSize.LARGE_TOOLBAR )
      : new Button.from_icon_name( "document-open-symbolic" );
    open_btn.set_tooltip_markup( _( "Open File   <i>(Control-O)</i>" ) );
    open_btn.add_accelerator( "clicked", accel_group, 'o', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
    open_btn.clicked.connect( do_open_file );
    _header.pack_start( open_btn );

    var save_btn = on_elementary
      ? new Button.from_icon_name( "document-save-as", IconSize.LARGE_TOOLBAR )
      : new Button.from_icon_name( "document-save-as-symbolic" );
    save_btn.set_tooltip_markup( _( "Save File As   <i>(Control-Shift-S)</i>" ) );
    open_btn.add_accelerator( "clicked", accel_group, 's', (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK), AccelFlags.VISIBLE );
    save_btn.clicked.connect( do_save_as_file );
    _header.pack_start( save_btn );

    _undo_btn = on_elementary
      ? new Button.from_icon_name( "edit-undo", IconSize.LARGE_TOOLBAR )
      : new Button.from_icon_name( "edit-undo-symbolic" );
    _undo_btn.set_tooltip_markup( _( "Undo   <i>(Control-Z)</i>" ) );
    _undo_btn.set_sensitive( false );
    _undo_btn.add_accelerator( "clicked", accel_group, 'z', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
    _undo_btn.clicked.connect( do_undo );
    _header.pack_start( _undo_btn );

    _redo_btn = on_elementary
      ? new Button.from_icon_name( "edit-redo", IconSize.LARGE_TOOLBAR )
      : new Button.from_icon_name( "edit-redo-symbolic" );
    _redo_btn.set_tooltip_markup( _( "Redo   <i>(Control-Shift-Z)</i>" ) );
    _redo_btn.set_sensitive( false );
    _redo_btn.add_accelerator( "clicked", accel_group, 'z', (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK), AccelFlags.VISIBLE );
    _redo_btn.clicked.connect( do_redo );
    _header.pack_start( _redo_btn );

    /* Add the buttons on the right side in the reverse order */
    add_property_button( accel_group );
    add_export_button( accel_group );
    add_search_button( accel_group );
    add_zoom_button( accel_group );

    /* Create the overlay that will hold the canvas so that we can put an entry box for emoji support */
    var canvas_overlay = new Overlay();
    canvas_overlay.add( _canvas );

    /* Create the horizontal box that will contain the canvas and the properties sidebar */
    var hbox = new Box( Orientation.HORIZONTAL, 0 );
    hbox.pack_start( canvas_overlay, true,  true, 0 );
    hbox.pack_start( _inspector,     false, true, 0 );

    /* Display the UI */
    add( hbox );
    show_all();

  }

  /* Handles any changes to the dark mode preference gsettings for the desktop */
  private void handle_prefer_dark_changes() {
    var lookup = SettingsSchemaSource.get_default().lookup( DESKTOP_SCHEMA, false );
    if( lookup != null ) {
      var desktop_settings = new GLib.Settings( DESKTOP_SCHEMA );
      _prefer_dark = desktop_settings.get_boolean( DARK_KEY );
      desktop_settings.changed.connect(() => {
        _prefer_dark = desktop_settings.get_boolean( DARK_KEY );
        on_theme_changed();
      });
    }
  }

  /* Updates the title */
  private void update_title() {
    string suffix = " \u2014 Minder";
    if( (_doc == null) || !_doc.is_saved() ) {
      _header.set_title( _( "Unnamed Document" ) + suffix );
    } else {
      _header.set_title( GLib.Path.get_basename( _doc.filename ) + suffix );
    }
  }

  /* Adds keyboard shortcuts for the menu actions */
  private void add_keyboard_shortcuts( Gtk.Application app ) {

    app.set_accels_for_action( "win.action_save",        { "<Control>s" } );
    app.set_accels_for_action( "win.action_quit",        { "<Control>q" } );
    app.set_accels_for_action( "win.action_zoom_actual", { "<Control>0" } );
    app.set_accels_for_action( "win.action_zoom_in",     { "<Control>plus" } );
    app.set_accels_for_action( "win.action_zoom_out",    { "<Control>minus" } );
    app.set_accels_for_action( "win.action_print",       { "<Control>p" } );

  }

  /* Adds the zoom functionality */
  private void add_zoom_button( AccelGroup accel_group ) {

    /* Create the menu button */
    var menu_btn = new MenuButton();
    menu_btn.set_image( on_elementary
      ? new Image.from_icon_name( "zoom-fit-best", IconSize.LARGE_TOOLBAR )
      : new Image.from_icon_name( "zoom-fit-best-symbolic", IconSize.SMALL_TOOLBAR ) );
    menu_btn.set_tooltip_text( _( "Zoom" ) );
    _header.pack_end( menu_btn );

    /* Create zoom menu popover */
    Box box = new Box( Orientation.VERTICAL, 5 );

    var marks     = _canvas.get_scale_marks();
    var scale_lbl = new Label( _( "Zoom to Percent" ) );
    _zoom_scale   = new Scale.with_range( Orientation.HORIZONTAL, marks[0], marks[marks.length-1], 25 );
    foreach (double mark in marks) {
      // _zoom_scale.add_mark( mark, PositionType.BOTTOM, "'" );
      _zoom_scale.add_mark( mark, PositionType.BOTTOM, null );
    }
    _zoom_scale.has_origin = false;
    _zoom_scale.set_value( 100 );
    _zoom_scale.change_value.connect( adjust_zoom );
    _zoom_scale.format_value.connect( set_zoom_value );

    _zoom_in = new ModelButton();
    _zoom_in.text = _( "Zoom In" );
    _zoom_in.action_name = "win.action_zoom_in";

    _zoom_out = new ModelButton();
    _zoom_out.text = _( "Zoom Out" );
    _zoom_out.action_name = "win.action_zoom_out";

    var fit = new ModelButton();
    fit.text = _( "Zoom to Fit" );
    fit.action_name = "win.action_zoom_fit";

    _zoom_sel = new ModelButton();
    _zoom_sel.text = _( "Zoom to Fit Selected Node" );
    _zoom_sel.action_name = "win.action_zoom_selected";

    var actual = new ModelButton();
    actual.text = _( "Zoom to Actual Size" );
    actual.action_name = "win.action_zoom_actual";

    box.margin = 5;
    box.pack_start( scale_lbl,   false, true );
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
  private void add_search_button( AccelGroup accel_group ) {

    /* Create the menu button */
    _search_btn = new MenuButton();
    _search_btn.set_image( on_elementary
      ? new Image.from_icon_name( "edit-find", IconSize.LARGE_TOOLBAR )
      : new Image.from_icon_name( "edit-find-symbolic", IconSize.SMALL_TOOLBAR ) );
    _search_btn.set_tooltip_markup( _( "Search   <i>(Control-F)</i>" ) );
    _search_btn.add_accelerator( "clicked", accel_group, 'f', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
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
  private void add_export_button( AccelGroup accel_group ) {

    /* Create the menu button */
    var menu_btn = new MenuButton();
    menu_btn.set_image( on_elementary
      ? new Image.from_icon_name( "document-export", IconSize.LARGE_TOOLBAR )
      : new Image.from_icon_name( "document-send-symbolic", IconSize.SMALL_TOOLBAR ) );
    menu_btn.set_tooltip_text( _( "Export" ) );
    _header.pack_end( menu_btn );

    /* Create export menu */
    var box = new Box( Orientation.VERTICAL, 5 );

    var export = new ModelButton();
    export.text = _( "Export…" );
    export.action_name = "win.action_export";

    var print = new ModelButton();
    print.text = _( "Print" );
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

  /* Adds the property functionality */
  private void add_property_button( AccelGroup accel_group ) {

    /* Add the menubutton */
    _prop_show = on_elementary
      ? new Image.from_icon_name( "pane-show-symbolic", IconSize.LARGE_TOOLBAR )
      : new Image.from_icon_name( "go-previous-symbolic", IconSize.SMALL_TOOLBAR );
    _prop_hide = on_elementary
      ? new Image.from_icon_name( "pane-hide-symbolic", IconSize.LARGE_TOOLBAR )
      : new Image.from_icon_name( "go-next-symbolic", IconSize.SMALL_TOOLBAR );
    _prop_btn  = new Button();
    _prop_btn.image = _prop_show;
    _prop_btn.set_tooltip_text( _( "Properties" ) );
    _prop_btn.add_accelerator( "clicked", accel_group, '|', Gdk.ModifierType.CONTROL_MASK, AccelFlags.VISIBLE );
    _prop_btn.clicked.connect( inspector_clicked );
    _header.pack_end( _prop_btn );

    /* Create the inspector sidebar */
    var box = new Box( Orientation.VERTICAL, 20 );
    var sb  = new StackSwitcher();

    _stack = new Stack();
    _stack.set_transition_type( StackTransitionType.SLIDE_LEFT_RIGHT );
    _stack.set_transition_duration( 500 );
    _stack.add_titled( new CurrentInspector( _canvas ), "current", _("Current") );
    _stack.add_titled( new StyleInspector( _canvas ), "style", _("Style") );
    _stack.add_titled( new MapInspector( _canvas, _settings ),  "map",  _("Map") );

    _stack.add_events( EventMask.KEY_PRESS_MASK );
    _stack.key_press_event.connect( stack_keypress );

    /* If the stack switcher is clicked, save off which tab is in view */
    _stack.notify.connect((ps) => {
      if( ps.name == "visible-child" ) {
        _settings.set_boolean( "current-properties-shown", (_stack.visible_child_name == "current") );
        _settings.set_boolean( "map-properties-shown",  (_stack.visible_child_name == "map") );
        _settings.set_boolean( "style-properties-shown", (_stack.visible_child_name == "style" ) );
      }
    });

    sb.homogeneous = true;
    sb.set_stack( _stack );

    box.margin = 5;
    box.pack_start( sb,     false, true, 0 );
    box.pack_start( _stack, true,  true, 0 );
    box.show_all();

    _inspector = new Revealer();
    _inspector.set_transition_type( RevealerTransitionType.SLIDE_LEFT );
    _inspector.set_transition_duration( 500 );
    _inspector.child = box;

    /* If the settings says to display the properties, do it now */
    if( _settings.get_boolean( "current-properties-shown" ) ) {
      show_properties( "current", false );
    } else if( _settings.get_boolean( "map-properties-shown" ) ) {
      show_properties( "map", false );
    } else if( _settings.get_boolean( "style-properties-shown" ) ) {
      show_properties( "style", false );
    }

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
    if( _inspector.child_revealed ) {
      hide_properties();
    } else {
      show_properties( null, false );
    }
  }

  /* Displays the save warning dialog window */
  public void show_save_warning( string type ) {

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

    dialog.response.connect((id) => {
      dialog.destroy();
      if( id == ResponseType.ACCEPT ) {
        if( !save_file() ) {
          id = ResponseType.CANCEL;
        }
      }
      if( (id == ResponseType.CLOSE) || (id == ResponseType.ACCEPT) ) {
        switch( type ) {
          case "new"  :  create_new_file();       break;
          case "open" :  select_and_open_file();  break;
        }
      }
    });

    dialog.show_all();

  }

  /*
   Allow the user to create a new Minder file.  Checks to see if the current
   document needs to be saved and saves it (if necessary).
  */
  public void do_new_file() {

    /* Save any changes to the current document */
    if( _doc != null ) {
      if( _doc.is_saved() ) {
        _doc.auto_save();
      } else {
        show_save_warning( "new" );
        return;
      }
    }

    create_new_file();

  }

  /*
   Creates a new file
  */
  private void create_new_file() {

    /* Create a new document */
    _doc = new Document( _canvas, _settings );
    _canvas.initialize_for_new();
    _canvas.grab_focus();

    /* Set the title to indicate that we have an unnamed document */
    update_title();

  }

  /* Allow the user to open a Minder file */
  public void do_open_file() {

    /* Automatically save the current file if one exists */
    if( _doc != null ) {
      if( _doc.is_saved() ) {
        _doc.auto_save();
      } else {
        show_save_warning( "open" );
        return;
      }
    }

    select_and_open_file();

  }

  /*
   Allows the user to select a file to open and opens it in the same window.
  */
  private void select_and_open_file() {

    /* Get the file to open from the user */
    FileChooserNative dialog = new FileChooserNative( _( "Open File" ), this, FileChooserAction.OPEN, _( "Open" ), _( "Cancel" ) );

    /* Create file filters */
    var filter = new FileFilter();
    filter.set_filter_name( "Minder" );
    filter.add_pattern( "*.minder" );
    dialog.add_filter( filter );

    filter = new FileFilter();
    filter.set_filter_name( "OPML" );
    filter.add_pattern( "*.opml" );
    dialog.add_filter( filter );

    if( dialog.run() == ResponseType.ACCEPT ) {
      open_file( dialog.get_filename() );
    }

    _canvas.grab_focus();

  }

  /* Opens the file and display it in the canvas */
  public bool open_file( string fname ) {
    if( !FileUtils.test( fname, FileTest.IS_REGULAR ) ) {
      return( false );
    }
    if( fname.has_suffix( ".minder" ) ) {
      _doc = new Document( _canvas, _settings );
      _canvas.initialize_for_open();
      _doc.filename = fname;
      update_title();
      _doc.load();
      return( true );
    } else if( fname.has_suffix( ".opml" ) ) {
      _doc = new Document( _canvas, _settings );
      _canvas.initialize_for_open();
      update_title();
      ExportOPML.import( fname, _canvas );
      return( true );
    }
    return( false );
  }

  /* Perform an undo action */
  public void do_undo() {
    _canvas.undo_buffer.undo();
    _canvas.grab_focus();
  }

  /* Perform a redo action */
  public void do_redo() {
    _canvas.undo_buffer.redo();
    _canvas.grab_focus();
  }

  private bool on_canvas_mapped( Gdk.EventAny e ) {
    _canvas.queue_draw();
    return( false );
  }

  /* Called whenever the theme is changed */
  private void on_theme_changed() {
    Gtk.Settings? settings = Gtk.Settings.get_default();
    if( settings != null ) {
      settings.gtk_application_prefer_dark_theme = _prefer_dark || _canvas.get_theme().prefer_dark;
    }
  }

  /*
   Called whenever the undo buffer changes state.  Updates the state of
   the undo and redo buffer buttons.
  */
  public void do_buffer_changed() {
    _undo_btn.set_sensitive( _canvas.undo_buffer.undoable() );
    _undo_btn.set_tooltip_text( _canvas.undo_buffer.undo_tooltip() );
    _redo_btn.set_sensitive( _canvas.undo_buffer.redoable() );
    _redo_btn.set_tooltip_text( _canvas.undo_buffer.redo_tooltip() );
  }

  /* Allow the user to select a filename to save the document as */
  public bool save_file() {
    FileChooserNative dialog = new FileChooserNative( _( "Save File" ), this, FileChooserAction.SAVE, _( "Save" ), _( "Cancel" ) );
    FileFilter        filter = new FileFilter();
    bool              retval = false;
    filter.set_filter_name( _( "Minder" ) );
    filter.add_pattern( "*.minder" );
    dialog.add_filter( filter );
    if( dialog.run() == ResponseType.ACCEPT ) {
      string fname = dialog.get_filename();
      if( fname.substring( -7, -1 ) != ".minder" ) {
        fname += ".minder";
      }
      _doc.filename = fname;
      _doc.save();
      update_title();
      retval = true;
    }
    _canvas.grab_focus();
    return( retval );
  }

  /* Called when the save as button is clicked */
  public void do_save_as_file() {
    save_file();
  }

  /* Called whenever the node selection changes in the canvas */
  private void on_current_changed() {
    _zoom_sel.set_sensitive( _canvas.get_current_node() != null );
  }

  /*
   Called if the canvas changes the scale factor value. Adjusts the
   UI to match.
  */
  private void change_scale( double scale_factor ) {
    var marks       = _canvas.get_scale_marks();
    var scale_value = scale_factor * 100;
    _zoom_scale.set_value( scale_value );
    _zoom_in.set_sensitive( scale_value < marks[marks.length-1] );
    _zoom_out.set_sensitive( scale_value > marks[0] );
  }

  /* Displays the node properties panel for the current node */
  private void show_properties( string? tab, bool grab_note ) {
    if( !_inspector.reveal_child || ((tab != null) && (_stack.visible_child_name != tab)) ) {
      _prop_btn.image = _prop_hide;
      if( tab != null ) {
        _stack.visible_child_name = tab;
      }
      if( !_inspector.reveal_child ) {
        _inspector.reveal_child = true;
        _canvas.see( -300 );
      }
      _settings.set_boolean( (_stack.visible_child_name + "-properties-shown"), true );
    }
    if( grab_note && (tab != null) && (tab == "current") ) {
      (_stack.get_child_by_name( tab ) as CurrentInspector).grab_note();
    }
  }

  /* Hides the node properties panel */
  private void hide_properties() {
    if( !_inspector.reveal_child ) return;
    _prop_btn.image = _prop_show;
    _inspector.reveal_child = false;
    _canvas.grab_focus();
    _settings.set_boolean( "current-properties-shown",  false );
    _settings.set_boolean( "map-properties-shown",   false );
    _settings.set_boolean( "style-properties-shown", false );
  }

  /* Converts the given value from the scale to the zoom value to use */
  private double zoom_to_value( double value ) {
    double last = -1;
    foreach (double mark in _canvas.get_scale_marks()) {
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
    _canvas.set_scaling_factor( scale_factor );
    _canvas.queue_draw();
    return( false );
  }

  /* Returns the value to display in the zoom control */
  private string set_zoom_value( double val ) {
    return( zoom_to_value( val ).to_string() );
  }

  /* Called when the user uses the Control-s keyboard shortcut */
  private void action_save() {
    if( _doc.is_saved() ) {
      _doc.save();
    } else {
      save_file();
    }
  }

  /* Called when the user uses the Control-q keyboard shortcut */
  private void action_quit() {
    destroy();
  }

  /* Zooms into the image (makes things larger) */
  private void action_zoom_in() {
    _canvas.zoom_in();
    _canvas.grab_focus();
  }

  /* Zooms out of the image (makes things smaller) */
  private void action_zoom_out() {
    _canvas.zoom_out();
    _canvas.grab_focus();
  }

  /* Zooms to make all nodes visible within the viewer */
  private void action_zoom_fit() {
    _canvas.zoom_to_fit();
    _canvas.grab_focus();
  }

  /* Zooms to make the currently selected node and its tree put into view */
  private void action_zoom_selected() {
    _canvas.zoom_to_selected();
    _canvas.grab_focus();
  }

  /* Sets the zoom to 100% */
  private void action_zoom_actual() {
    _canvas.animator.add_scale( "action_zoom_actual" );
    _canvas.set_scaling_factor( 1.0 );
    _canvas.animator.animate();
    _canvas.grab_focus();
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
      _canvas.get_match_items(
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
    _search_items.get_iter( out it, path );
    _search_items.get( it, 2, &node, 3, &conn, -1 );
    if( node != null ) {
      _canvas.set_current_connection( null );
      _canvas.set_current_node( node );
      _canvas.see();
    } else if( conn != null ) {
      _canvas.set_current_node( null );
      _canvas.set_current_connection( conn );
      _canvas.see();
    }
    _search.closed();
    _canvas.grab_focus();
  }

  /* Exports the model to various formats */
  private void action_export() {

    FileChooserNative dialog = new FileChooserNative( _( "Export As" ), this, FileChooserAction.SAVE, _( "Export" ), _( "Cancel" ) );

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

    /* PDF */
    FileFilter pdf_filter = new FileFilter();
    pdf_filter.set_filter_name( _( "PDF" ) );
    pdf_filter.add_pattern( "*.pdf" );
    dialog.add_filter( pdf_filter );

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

    /* SVG */
    FileFilter svg_filter = new FileFilter();
    svg_filter.set_filter_name( _( "SVG" ) );
    svg_filter.add_pattern( "*.svg" );
    dialog.add_filter( svg_filter );

    if( dialog.run() == ResponseType.ACCEPT ) {

      var fname  = dialog.get_filename();
      var filter = dialog.get_filter();

      if( bmp_filter == filter ) {
        ExportImage.export( repair_filename( fname, {".bmp"} ), "bmp", _canvas );
      } else if( csv_filter == filter ) {
        ExportCSV.export( repair_filename( fname, {".csv"} ), _canvas );
      } else if( jpeg_filter == filter ) {
        ExportImage.export( repair_filename( fname, {".jpeg", ".jpg"} ), "jpeg", _canvas );
      } else if( md_filter == filter ) {
        ExportMarkdown.export( repair_filename( fname, {".md", ".markdown"} ), _canvas );
      } else if( mmd_filter == filter ) {
        ExportMermaid.export( repair_filename( fname, {".mmd"} ), _canvas );
      } else if( opml_filter == filter ) {
        ExportOPML.export( repair_filename( fname, {".opml"} ), _canvas );
      } else if( pdf_filter == filter ) {
        ExportPDF.export( repair_filename( fname, {".pdf"} ), _canvas );
      } else if( pngt_filter == filter ) {
        ExportPNG.export( repair_filename( fname, {".png"} ), _canvas, true );
      } else if( pngo_filter == filter ) {
        ExportPNG.export( repair_filename( fname, {".png"} ), _canvas, false );
      } else if( txt_filter == filter ) {
        ExportText.export( repair_filename( fname, {".txt"} ), _canvas );
      } else if( svg_filter == filter ) {
        ExportSVG.export( repair_filename( fname, {".svg"} ), _canvas );
      }
    }

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
    print.print( _canvas, this );
  }

}

