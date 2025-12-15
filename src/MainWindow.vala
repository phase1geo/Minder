/*
* Copyright (c) 2018-2024 (https://github.com/phase1geo/Minder)
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

public class ShortcutTooltip {
  private Widget _widget;
  private string _label;
  public ShortcutTooltip( Widget w, string l ) {
    _widget = w;
    _label  = l;
  }
  public void set_tooltip( Shortcut? shortcut ) {
    _widget.tooltip_markup = (shortcut == null) ? _label : Utils.tooltip_with_accel( _label, shortcut.get_accelerator() );
  }
}

public delegate void AfterLoadTabFunc();

public class MainWindow : Gtk.ApplicationWindow {

  private GLib.Settings     _settings;
  private HeaderBar         _header;
  private Label             _title;
  private Notebook?         _nb             = null;
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
  private MenuButton        _zoom_btn;
  private Scale?            _zoom_scale = null;
  private Button?           _zoom_in    = null;
  private Button?           _zoom_out   = null;
  private Button?           _undo_btn   = null;
  private Button?           _redo_btn   = null;
  private ToggleButton?     _brain_btn  = null;
  private ToggleButton?     _focus_btn  = null;
  private ToggleButton?     _prop_btn   = null;
  private string            _prop_show;
  private string            _prop_hide;
  private bool              _debug      = false;
  private ThemeEditor       _themer;
  private Label             _scale_lbl;
  private int               _text_size;
  private Exports           _exports;
  private UnicodeInsert     _unicoder;
  private Braindump         _brain;
  private Shortcuts         _shortcuts;
  private SimpleActionGroup _actions;
  private Gee.HashMap<KeyCommand,ShortcutTooltip> _shortcut_widgets;
  private Templates                               _templates;

  private bool on_elementary = Utils.on_elementary();

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
  public Braindump braindump {
    get {
      return( _brain );
    }
  }
  public Shortcuts shortcuts {
    get {
      return( _shortcuts );
    }
  }
  public Templates templates {
    get {
      return( _templates );
    }
  }

  public delegate void OverwriteFunc( bool overwrite );

  public signal void canvas_changed( MindMap? map );

  //-------------------------------------------------------------
  // Create the main window UI.
  public MainWindow( Gtk.Application app, GLib.Settings settings ) {

    Object( application: app );

    _settings = settings;

    // Create the templates
    _templates = new Templates();

    var window_w = settings.get_int( "window-w" );
    var window_h = settings.get_int( "window-h" );

    // Create the exports and load it
    _exports = new Exports();

    // Create the header bar
    _header = new HeaderBar() {
      show_title_buttons = true,
      title_widget       = new Label( _( "Minder" ) )
    };
    set_titlebar( _header );

    // Set the default window size to the last session size
    set_default_size( window_w, window_h );

    // Load the user shortcuts
    _shortcuts = new Shortcuts();
    _shortcuts.shortcut_changed.connect( shortcut_changed );

    _shortcut_widgets = new Gee.HashMap<KeyCommand, ShortcutTooltip>();

    // Set the stage for menu actions
    _actions = new SimpleActionGroup ();
    insert_action_group( "win", _actions );

    // Create the notebook
    _nb = new Notebook() {
      halign     = Align.FILL,
      hexpand    = true,
      valign     = Align.FILL,
      vexpand    = true,
      scrollable = true
    };
    _nb.switch_page.connect( tab_switched );
    _nb.page_reordered.connect( tab_reordered );
    _nb.page_removed.connect( tab_removed );

    // Set shortcuts until we have a tab menu
    set_action_for_command( KeyCommand.TAB_GOTO_NEXT );
    set_action_for_command( KeyCommand.TAB_GOTO_PREV );
    set_action_for_command( KeyCommand.TAB_CLOSE_CURRENT );

    // Create the braindump pane
    _brain = new Braindump( this ) {
      halign  = Align.START,
      hexpand_set = true,
      valign  = Align.FILL,
      vexpand = true,
      visible = false
    };

    _brain.ideas_changed.connect((change, name_index) => {
      var map = get_current_map();
      switch( change ) {
        case BraindumpChangeType.ADD    :  map.model.braindump.append_val( name_index );  break;
        case BraindumpChangeType.REMOVE :  map.model.braindump.remove_index( int.parse( name_index ) );  break;
        case BraindumpChangeType.CLEAR  :  map.model.braindump.remove_range( 0, map.model.braindump.length );  break;
      }
      map.auto_save();
    });

    var content = new Box( Orientation.HORIZONTAL, 0 );
    content.append( _nb );
    content.append( _brain );

    // Create title toolbar
    var new_btn = new Button.from_icon_name( get_icon_name( "document-new" ) );
    register_widget_for_shortcut( new_btn, KeyCommand.FILE_NEW, _( "New File" ) );
    new_btn.clicked.connect(() => { execute_command( KeyCommand.FILE_NEW ); });
    _header.pack_start( new_btn );

    var open_btn = new Button.from_icon_name( get_icon_name( "document-open" ) );
    register_widget_for_shortcut( open_btn, KeyCommand.FILE_OPEN, _( "Open File" ) );
    open_btn.clicked.connect(() => { execute_command( KeyCommand.FILE_OPEN ); });
    _header.pack_start( open_btn );

    var save_btn = new Button.from_icon_name( get_icon_name( "document-save-as" ) );
    register_widget_for_shortcut( save_btn, KeyCommand.FILE_SAVE_AS, _( "Save File As" ) );
    save_btn.clicked.connect(() => { execute_command( KeyCommand.FILE_SAVE_AS ); });
    _header.pack_start( save_btn );

    _undo_btn = new Button.from_icon_name( get_icon_name( "edit-undo" ) ) {
      sensitive = false
    };
    register_widget_for_shortcut( _undo_btn, KeyCommand.UNDO_ACTION, _( "Undo" ) );
    _undo_btn.clicked.connect(() => { execute_command( KeyCommand.UNDO_ACTION ); });
    _header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( get_icon_name( "edit-redo" ) ) {
      sensitive = false
    };
    register_widget_for_shortcut( _redo_btn, KeyCommand.REDO_ACTION, _( "Redo" ) );
    _redo_btn.clicked.connect(() => { execute_command( KeyCommand.REDO_ACTION ); });
    _header.pack_start( _redo_btn );

    // Create unicode inserter
    _unicoder = new UnicodeInsert();

    // Add the buttons on the right side in the reverse order
    add_property_button();
    add_miscellaneous_button();
    add_export_button();
    add_search_button();
    add_zoom_button();
    add_focus_button();
    add_braindump_button();
    add_debug_button();

    // Create the panel so that we can resize
    _pane = new Paned( Orientation.HORIZONTAL ) {
      halign           = Align.FILL,
      valign           = Align.FILL,
      start_child      = content,
      resize_end_child = false,
      shrink_end_child = false,
      position         = _settings.get_int( "properties-width" )
    };
    _pane.move_handle.connect(() => {
      return( false );
    });

    _pane.notify["position"].connect(() => {
      _settings.set_int( "properties-width", _pane.position );
    });

    // Display the UI
    child = _pane;

    // If the settings says to display the properties, do it now
    if( _settings.get_boolean( "current-properties-shown" ) ) {
      show_properties( "current", PropertyGrab.NONE );
    } else if( _settings.get_boolean( "style-properties-shown" ) ) {
      show_properties( "style", PropertyGrab.NONE );
    } else if( _settings.get_boolean( "tag-properties-shown" ) ) {
      show_properties( "tag", PropertyGrab.NONE );
    } else if( _settings.get_boolean( "sticker-properties-shown" ) ) {
      show_properties( "sticker", PropertyGrab.NONE );
    } else if( _settings.get_boolean( "map-properties-shown" ) ) {
      show_properties( "map", PropertyGrab.NONE );
    }

    // Look for any changes to the settings
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

    // Handle any changes to the system default
    var granite_settings  = Granite.Settings.get_default();
    granite_settings.notify["prefers-color-scheme"].connect(() => {
      on_dark_mode_changed( granite_settings.prefers_color_scheme == Granite.Settings.ColorScheme.DARK );
    });

    // If we receive focus, update the titlebar
    var focus = new EventControllerFocus();
    _pane.add_controller( focus );
    focus.enter.connect(() => {
      var map = get_current_map();
      update_title( map );
    });

    // Load the exports data
    _exports.load();

    // Load the templates
    _templates.load();

    close_request.connect(() => {
      save_window_size();
      save_tabs();
      return( false );
    });

    // Set shortcuts that don't have a UI element
    set_action_for_command( KeyCommand.FILE_SAVE );
    set_action_for_command( KeyCommand.QUIT );

    // Set the window size based on gsettings
    set_window_size();

  }

  //-------------------------------------------------------------
  // Returns the name of the icon to use for a headerbar icon.
  private string get_icon_name( string icon_name ) {
    return( "%s%s".printf( icon_name, (on_elementary ? "" : "-symbolic") ) );
  }

  //-------------------------------------------------------------
  // Returns the DrawingArea associated with the given notebook
  // page index.
  private MindMap get_map( int page ) {
    var ol = (Overlay)_nb.get_nth_page( page );
    var da = (DrawArea)ol.child;
    return( da.map );
  }

  //-------------------------------------------------------------
  // Returns the tab label associated with the given notebook page.
  private string get_tab_label_name( int page_num ) {
    var page = _nb.get_nth_page( page_num );
    var tab  = _nb.get_tab_label( page );
    var label = (Label)Utils.get_child_at_index( tab, 1 );
    return( label.label );
  }

  //-------------------------------------------------------------
  // Sets the tab label name and tooltip to the given values.
  private void set_tab_label_info( int page_num, bool editable, string label, string tooltip ) {
    var page = _nb.get_nth_page( page_num );
    var tab  = _nb.get_tab_label( page );
    var lock = (Image)Utils.get_child_at_index( tab, 0 );
    var lbl  = (Label)Utils.get_child_at_index( tab, 1 );
    lock.visible     = !editable;
    lbl.label        = label;
    lbl.tooltip_text = tooltip;
  }

  //-------------------------------------------------------------
  // Called whenever the text size setting value changes.
  private void setting_changed_text_size() {
    var value = settings.get_boolean( "text-field-use-custom-font-size" ) ? settings.get_int( "text-field-custom-font-size" ) : -1;
    _text_size = value;
    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var map = get_map( i );
      map.model.update_css();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the enable-ui-animations glib setting is
  // changed.
  private void setting_changed_ui_animations() {
    var duration = settings.get_boolean( "enable-ui-animations" ) ? 500 : 0;
    var current  = (_stack.get_child_by_name( "current" ) as CurrentInspector);
    _stack.set_transition_duration( duration );
    current.set_transition_duration( duration );
  }

  //-------------------------------------------------------------
  // Called whenever the animation enable setting is changed.
  private void setting_changed_animations() {
    var value = settings.get_boolean( "enable-animations" );
    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var map = get_map( i );
      map.animator.enable = value;
    }
  }

  //-------------------------------------------------------------
  // Called whenever the auto-parse embedded URLs setting is changed.
  private void setting_changed_embedded_urls() {
    var value = settings.get_boolean( "auto-parse-embedded-urls" );
    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var map = get_map( i );
      map.url_parser.enable = value;
    }
  }

  //-------------------------------------------------------------
  // Called whenever the enable Markdown setting is changed.
  private void setting_changed_markdown() {
    var value = settings.get_boolean( "enable-markdown" );
    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var map = get_map( i );
      map.markdown_parser.enable = value;
    }
  }

  //-------------------------------------------------------------
  // Called whenever the enable unicode input setting is changed.
  private void setting_changed_unicode_input() {
    var value = settings.get_boolean( "enable-unicode-input" );
    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var map = get_map( i );
      map.unicode_parser.enable = value;
    }
  }

  //-------------------------------------------------------------
  // Called whenever the current tab is switched in the notebook
  private void tab_switched( Widget page, uint page_num ) {
    tab_changed( (int)page_num );
  }

  //-------------------------------------------------------------
  // This needs to be called whenever the tab is changed
  private void tab_changed( int page_num ) {
    var map = get_map( page_num );
    do_buffer_changed( map.current_undo_buffer() );
    on_current_changed( map );
    update_title( map );
    canvas_changed( map );
    _brain.set_list( map.model.braindump );
    _brain_btn.sensitive = map.editable;
    set_braindump_ui( map, map.model.braindump_shown );
    save_tab_state( page_num );
  }

  //-------------------------------------------------------------
  // Called whenever the current tab is moved to a new position
  private void tab_reordered( Widget w, uint page_num ) {
    save_tab_state( (int)page_num );
  }

  //-------------------------------------------------------------
  // Updates all of the node sizes in all tabs
  public void update_node_sizes() {
    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var map = get_map( i );
      map.model.update_node_sizes();
    }
  }

  //-------------------------------------------------------------
  // Closes the current tab
  public void close_current_tab() {
    close_tab( _nb.page );
  }

  //-------------------------------------------------------------
  // Closes the tab associated with the given drawing area
  private void close_tab( int page_num ) {
    var map = get_map( page_num );
    if( map.doc.is_saved() ) {
      map.close();
      remove_tab( page_num );
    } else {
      show_save_warning( map );
    }
  }

  //-------------------------------------------------------------
  // Removes the specified tab from the notebook.  If this leaves
  // the notebook in an empty state, add a blank tab.
  private void remove_tab( int? page_num ) {
    _nb.detach_tab( _nb.get_nth_page( page_num ?? _nb.page ) );
    if( _nb.get_n_pages() == 0 ) {
      add_tab( null, TabAddReason.NEW );
    }
  }

  //-------------------------------------------------------------
  // This should be called when the tab page is actually gone
  private void tab_removed( Widget w, uint page_num ) {
    save_tab_state( _nb.page );
  }

  //-------------------------------------------------------------
  // Creates a new mindmap.
  public MindMap create_map() {
    var map = new MindMap( this, _settings );
    return( map );
  }

  //-------------------------------------------------------------
  // Adds a new tab to the notebook
  public MindMap add_tab( string? fname, TabAddReason reason ) {

    /* Create and pack the canvas */
    var map = new MindMap( this, _settings );
    map.current_changed.connect( on_current_changed );
    map.scale_changed.connect( change_scale );
    map.scroll_changed.connect( change_origin );
    map.show_properties.connect( show_properties );
    map.hide_properties.connect( hide_properties );
    map.undo_buffer.buffer_changed.connect( do_buffer_changed );
    map.undo_text.buffer_changed.connect( do_buffer_changed );
    // map.theme_changed.connect( on_theme_changed );
    map.editable_changed.connect( on_editable_changed );
    map.highlighted.changed.connect(() => { on_tag_highlight_changed( map ); });
    map.animator.enable = _settings.get_boolean( "enable-animations" );

    if( fname != null ) {
      map.doc.load_filename( fname, (reason == TabAddReason.OPEN) );
    }

    /* Create the overlay that will hold the canvas so that we can put an entry box for emoji support */
    var overlay = new Overlay() {
      child = map.canvas
    };

    var tab_lock = new Image.from_icon_name( "system-lock-screen-symbolic" ) {
      halign        = Align.START,
      visible       = !map.editable,
      margin_start  = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    tab_lock.add_css_class( "tab" );

    var tab_label = new Label( map.doc.label ) {
      halign        = Align.CENTER,
      hexpand       = true,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5,
      tooltip_text  = map.doc.label
    };
    tab_label.add_css_class( "tab" );

    var tab_close = new Button.from_icon_name( "window-close-symbolic" ) {
      has_frame     = false,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    tab_close.add_css_class( "tab" );

    map.doc.save_changed.connect(() => {
      tab_close.icon_name = (map.doc.save_needed ? "media-record-symbolic" : "window-close-symbolic" );
    });

    var tab_revealer = new Revealer() {
      halign          = Align.END,
      reveal_child    = true,
      transition_type = RevealerTransitionType.CROSSFADE,
      child           = tab_close
    };

    var tab_box = new Box( Orientation.HORIZONTAL, 5 );
    tab_box.append( tab_lock );
    tab_box.append( tab_label );
    tab_box.append( tab_revealer );

    var tab_motion = new EventControllerMotion();
    tab_box.add_controller( tab_motion );

    // Add the tab
    var tab_index = _nb.append_page( overlay, tab_box );

    tab_motion.enter.connect((x, y) => {
      tab_revealer.reveal_child = true; // (_nb.get_n_pages() > 1);
    });
    tab_motion.leave.connect(() => {
      tab_revealer.reveal_child = (_nb.page == tab_index);
    });

    tab_close.clicked.connect(() => {
      close_tab( tab_index );
    });

    /* Update the titlebar */
    update_title( map );

    /* Make the drawing area new */
    if( reason == TabAddReason.NEW ) {
      map.initialize_for_new();
    } else {
      map.initialize_for_open();
    }

    /* Indicate that the tab has changed */
    if( reason != TabAddReason.LOAD ) {
      if( reason == TabAddReason.OPEN ) {
        map.editable = true;
      }
      _nb.page = tab_index;
    }

    map.canvas.grab_focus();

    return( map );

  }

  //-------------------------------------------------------------
  // Closes all tabs that contain documents that have not been changed.
  private void close_unchanged_tabs() {
    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var map = get_map( i );
      if( !map.model.is_loaded ) {
        _nb.detach_tab( _nb.get_nth_page( i ) );
        return;
      }
    }
  }

  //-------------------------------------------------------------
  // Searches the current tabs for an unchanged tab.  If one is
  // found, make it the current tab.
  private bool find_unchanged_tab() {
    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var map = get_map( i );
      if( !map.model.is_loaded ) {
        _nb.page = i;
        map.canvas.grab_focus();
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Checks to see if any other tab contains the given filename.
  // If the filename is already found, refresh the tab with the
  // file contents and make it the current tab; otherwise, add the
  // new tab and populate it.
  private MindMap add_tab_conditionally( string? fname, TabAddReason reason ) {

    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var map = get_map( i );
      if( map.doc.filename == fname ) {
        map.initialize_for_open();
        _nb.page = i;
        return( map );
      }
    }

    return( add_tab( fname, reason ) );

  }

  //-------------------------------------------------------------
  // Returns the next tab in the tabbar.
  public void next_tab() {
    _nb.next_page();
  }

  //-------------------------------------------------------------
  // Returns the previous tab in the tabbar.
  public void previous_tab() {
    _nb.prev_page();
  }

  //-------------------------------------------------------------
  // Returns the current drawing area.
  public MindMap? get_current_map( string? caller = null ) {
    if( _debug && (caller != null) ) {
      stdout.printf( "get_current_map called from %s\n", caller );
    }
    if( _nb.page == -1 ) { return( null ); }
    return( get_map( _nb.page ) );
  }

  //-------------------------------------------------------------
  // Updates the title.
  private void update_title( MindMap? map ) {
    var label = " \u2014 Minder";
    if( (map != null) && (map.highlighted.size() > 0) ) {
      label += " (%s)".printf( _( "Tag Highlight Mode" ) );
    } else if( _focus_btn.active ) {
      label += " (%s)".printf( _( "Focus Mode" ) );
    }
    if( (map == null) || !map.doc.is_saved() ) {
      label = _( "Unnamed Document" ) + label;
    } else {
      if( map.doc.read_only || !map.editable ) {
        label += " [%s]".printf( _( "Read-Only" ) );
      }
      label = GLib.Path.get_basename( map.doc.filename ) + label;
    }
    var lbl = (Label)_header.title_widget;
    lbl.label = label;
  }

  //-------------------------------------------------------------
  // Adds the zoom functionality.
  private void add_zoom_button() {

    var zoom_item = new GLib.MenuItem( null, null );
    zoom_item.set_attribute( "custom", "s", "scale" );

    var scale_menu = new GLib.Menu();
    scale_menu.append_item( zoom_item );

    var fit_menu = new GLib.Menu();
    append_menu_item( fit_menu, KeyCommand.ZOOM_FIT,      _( "Zoom to Fit" ) );
    append_menu_item( fit_menu, KeyCommand.ZOOM_SELECTED, _( "Zoom to Fit Selected Node Tree" ) );
    append_menu_item( fit_menu, KeyCommand.ZOOM_ACTUAL,   _( "Zoom to Actual Size" ) );

    var menu = new GLib.Menu();
    menu.append_section( null, scale_menu );
    menu.append_section( null, fit_menu );

    // Create scale UI in menu
    var marks   = DrawArea.get_scale_marks();
    _scale_lbl  = new Label( _( "Zoom to Percent" ) );
    _zoom_scale = new Scale.with_range( Orientation.HORIZONTAL, marks[0], marks[marks.length-1], 25 ) {
      hexpand = true,
      has_origin = false
    };
    _zoom_scale.set_value( 100 );
    foreach (double mark in marks) {
      _zoom_scale.add_mark( mark, PositionType.BOTTOM, null );
    }
    _zoom_scale.change_value.connect( adjust_zoom );

    _zoom_in = new Button.from_icon_name( "zoom-in-symbolic" ) {
      has_frame = false,
      can_focus = false
    };
    register_widget_for_shortcut( _zoom_in, KeyCommand.ZOOM_IN, _( "Zoom In" ) );
    _zoom_in.clicked.connect(() => { execute_command( KeyCommand.ZOOM_IN ); });

    _zoom_out = new Button.from_icon_name( "zoom-out-symbolic" ) {
      has_frame = false,
      can_focus = false
    };
    register_widget_for_shortcut( _zoom_out, KeyCommand.ZOOM_OUT, _( "Zoom Out" ) );
    _zoom_out.clicked.connect(() => { execute_command( KeyCommand.ZOOM_OUT ); });

    var zoom_box = new Box( Orientation.HORIZONTAL, 5 );
    zoom_box.append( _zoom_out );
    zoom_box.append( _zoom_scale );
    zoom_box.append( _zoom_in );

    var zbox = new Box( Orientation.VERTICAL, 5 );
    zbox.append( _scale_lbl );
    zbox.append( zoom_box );

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

  //-------------------------------------------------------------
  // Adds the search functionality.
  private void add_search_button() {

    /* Create the search entry field */
    _search_entry = new SearchEntry() {
      placeholder_text = _( "Search Nodes, Callouts and Connections" ),
      width_chars      = 60
    };
    _search_entry.search_changed.connect( on_search_change );

    var search_key = new EventControllerKey();
    _search_entry.add_controller( search_key );

    search_key.key_pressed.connect((keyval, keycode, state) => {
      if( keyval == Gdk.Key.Escape ) {
        _search_btn.active = false;
        return( true );
      }
      return( false );
    });

    _search_items = new Gtk.ListStore( 8, typeof(string), typeof(string), typeof(Node), typeof(Connection), typeof(Callout), typeof(NodeGroup), typeof(string), typeof(string) );

    // Create the treeview
    _search_list  = new TreeView.with_model( _search_items ) {
      headers_visible          = false,
      activate_on_single_click = true,
      enable_search            = false,
    };
    var type_cell = new CellRendererText() {
      xalign = 1
    };
    var str_cell = new CellRendererText() {
      ellipsize     = Pango.EllipsizeMode.END,
      ellipsize_set = true,
      width_chars   = 50,
    };
    var tab_cell = new CellRendererText();
    _search_list.insert_column_with_attributes( -1, null, type_cell, "markup", 0, null );
    _search_list.insert_column_with_attributes( -1, null, str_cell,  "markup", 1, null );
    _search_list.insert_column_with_attributes( -1, null, tab_cell,  "markup", 7, null );
    _search_list.row_activated.connect( on_search_clicked );

    // Create the scrolled window for the treeview
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

    var search_all_box = new Box( Orientation.HORIZONTAL, 10 );
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
      icon_name = (on_elementary ? "minder-search" : "edit-find-symbolic"),
      popover   = _search
    };
    register_widget_for_shortcut( _search_btn, KeyCommand.SHOW_FIND, _( "Search" ) );
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
    _search_nontasks.toggled.connect(() => {
      _settings.set_boolean( "search-opt-nontasks", _search_nontasks.active );
      _search_tasks.set_sensitive( _search_nontasks.active );
      on_search_change();
    });

    var grid = new Grid() {
      margin_top         = 10,
      column_homogeneous = true,
      column_spacing     = 10,
      row_spacing        = 10
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

  //-------------------------------------------------------------
  // Adds the export functionality
  private void add_export_button() {

    var export_item = new GLib.MenuItem( null, null );
    export_item.set_attribute( "custom", "s", "export" );

    var export_menu = new GLib.Menu();
    export_menu.append_item( export_item );

    var print_menu = new GLib.Menu();
    append_menu_item( print_menu, KeyCommand.FILE_PRINT, _( "Print…" ) );

    var menu = new GLib.Menu();
    menu.append_section( null, export_menu );
    menu.append_section( null, print_menu );
    
    /* Create the popover and associate it with clicking on the menu button */
    var popover = new PopoverMenu.from_model( menu ) {
      cascade_popdown = false
    };

    /* Create export menu */
    _exporter = new Exporter( this ) {
      margin_start = 5,
      margin_end   = 5
    };
    _exporter.export_done.connect(() => {
      popover.popdown();
    });

    popover.add_child( _exporter, "export" );

    /* Create the menu button */
    var menu_btn = new MenuButton() {
      icon_name    = (on_elementary ? "document-export" : "document-send-symbolic"),
      tooltip_text = _( "Export" ),
      popover      = popover
    };
    _header.pack_end( menu_btn );

  }

  //-------------------------------------------------------------
  // Adds the braindump button to the headerbar
  private void add_braindump_button() {

    _brain_btn = new ToggleButton() {
      icon_name = "minder-braindump-light-symbolic",
    };
    register_widget_for_shortcut( _brain_btn, KeyCommand.TOGGLE_BRAINDUMP, _( "Brain Dump" ) );

    _brain_btn.clicked.connect((e) => {
      set_braindump_ui( get_current_map(), !_brain.visible );
      save_tab_state( _nb.page );
    });

    _header.pack_end( _brain_btn );

  }

  //-------------------------------------------------------------
  // Shows or hides the braindump UI.
  public void set_braindump_ui( MindMap map, bool show ) {

    var show_ui = show && map.editable;

    map.model.braindump_shown = show;

    _brain.visible    = show_ui;
    _brain_btn.active = show_ui;

    if( show_ui ) {
      _brain.grab_focus();
    } else {
      map.canvas.grab_focus();
    }

  }

  //-------------------------------------------------------------
  // In debug mode, this button
  private void add_debug_button() {

    if( !Minder.debug ) return;

    var btn = new Button.from_icon_name( "media-playback-start-symbolic" );
    btn.clicked.connect(() => {
      Minder.debug_advance = true;
      var map = get_current_map();
      if( map != null ) {
        map.canvas.grab_focus();
      }
    });

    _header.pack_end( btn );

  }

  //-------------------------------------------------------------
  // Adds the focus mode button to the headerbar
  private void add_focus_button() {

    _focus_btn = new ToggleButton() {
      icon_name = (on_elementary ? "minder-focus" : "media-optical-symbolic")
    };
    register_widget_for_shortcut( _focus_btn, KeyCommand.TOGGLE_FOCUS_MODE, _( "Focus Mode" ) );

    _focus_btn.clicked.connect((e) => {
      var map = get_current_map();
      update_title( map );
      map.focus_mode = _focus_btn.active;
      map.canvas.grab_focus();
    });

    _header.pack_end( _focus_btn );

  }

  //-------------------------------------------------------------
  // Adds the miscellaneous functionality
  private void add_miscellaneous_button() {

    GLib.Menu menu;

    var misc_menu = new GLib.Menu();
    append_menu_item( misc_menu, KeyCommand.SHOW_PREFERENCES, _( "Preferences" ) );
    append_menu_item( misc_menu, KeyCommand.SHOW_SHORTCUTS,   _( "Shortcuts Cheatsheet" ) );

    var about_menu = new GLib.Menu();
    append_menu_item( about_menu, KeyCommand.SHOW_ABOUT, _( "About Minder" ) );

    menu = new GLib.Menu();
    menu.append_section( null, misc_menu );
    menu.append_section( null, about_menu );

    /* Create the menu button */
    var misc_btn = new MenuButton() {
      icon_name  = get_icon_name( "open-menu" ),
      menu_model = menu
    };
    _header.pack_end( misc_btn );

  }

  //-------------------------------------------------------------
  // Adds the property functionality
  private void add_property_button() {

    // Keep the show/hide sidebar icon names
    _prop_show = (on_elementary ? "minder-sidebar-open"  : "minder-sidebar-light-symbolic");
    _prop_hide = (on_elementary ? "minder-sidebar-close" : "minder-sidebar-light-symbolic");

    /* Add the menubutton */
    _prop_btn  = new ToggleButton() {
      icon_name    = _prop_show,
      active       = false,
      tooltip_text = _( "Show Property Sidebar" )
    };
    _prop_btn.toggled.connect( inspector_clicked );
    _header.pack_end( _prop_btn );

    _stack = new Stack() {
      halign              = Align.FILL,
      valign              = Align.FILL,
      transition_type     = StackTransitionType.SLIDE_LEFT_RIGHT,
      transition_duration = 500
    };
    _stack.add_titled( new CurrentInspector( this ),            "current", _("Current") );
    _stack.add_titled( new StyleInspector( this, _settings ),   "style",   _("Style") );
    _stack.add_titled( new TagInspector( this ),                "tag",     _("Tags") );
    _stack.add_titled( new StickerInspector( this, _settings ), "sticker", _("Stickers") );
    _stack.add_titled( new MapInspector( this, _settings ),     "map",     _("Map") );

    var key = new EventControllerKey();
    _stack.add_controller( key );
    key.key_pressed.connect( stack_keypress );

    /* If the stack switcher is clicked, save off which tab is in view */
    _stack.notify.connect((ps) => {
      if( ps.name == "visible-child" ) {
        _settings.set_boolean( "current-properties-shown", (_stack.visible_child_name == "current") );
        _settings.set_boolean( "style-properties-shown",   (_stack.visible_child_name == "style" ) );
        _settings.set_boolean( "tag-properties-shown",     (_stack.visible_child_name == "tag" ) );
        _settings.set_boolean( "sticker-properties-shown", (_stack.visible_child_name == "sticker" ) );
        _settings.set_boolean( "map-properties-shown",     (_stack.visible_child_name == "map") );
        switch( _stack.visible_child_name ) {
          case "current" :  (_stack.visible_child as CurrentInspector).grab_first();  break;
          case "style"   :  (_stack.visible_child as StyleInspector).grab_first();    break;
          case "tag"     :  (_stack.visible_child as TagInspector).grab_first();      break;
          case "sticker" :  (_stack.visible_child as StickerInspector).grab_first();  break;
          case "map"     :  (_stack.visible_child as MapInspector).grab_first();      break;
          default        :  break;
        }
      }
    });

    // Set shortcuts
    set_action_for_command( KeyCommand.SHOW_CURRENT_SIDEBAR );
    set_action_for_command( KeyCommand.SHOW_STYLE_SIDEBAR );
    set_action_for_command( KeyCommand.SHOW_TAG_SIDEBAR );
    set_action_for_command( KeyCommand.SHOW_STICKER_SIDEBAR );
    set_action_for_command( KeyCommand.SHOW_MAP_SIDEBAR );

    // Handle the enable-ui-animations value
    setting_changed_ui_animations();

    var sidebar_switcher = new ModeButtons() {
      halign = Align.CENTER
    };

    sidebar_switcher.add_stack_tab( _( "Current" ) );
    sidebar_switcher.add_stack_tab( _( "Style" ) );
    sidebar_switcher.add_stack_tab( _( "Tags" ) );
    sidebar_switcher.add_stack_tab( _( "Stickers" ) );
    sidebar_switcher.add_stack_tab( _( "Map" ) );

    sidebar_switcher.changed.connect((index) => {
      switch( index ) {
        case 0 :  _stack.visible_child_name = "current";  break;
        case 1 :  _stack.visible_child_name = "style";    break;
        case 2 :  _stack.visible_child_name = "tag";      break;
        case 3 :  _stack.visible_child_name = "sticker";  break;
        case 4 :  _stack.visible_child_name = "map";      break;
      }
    });

    _stack.notify["visible-child-name"].connect(() => {
      switch( _stack.visible_child_name ) {
        case "current" :  sidebar_switcher.selected = 0;  break;
        case "style"   :  sidebar_switcher.selected = 1;  break;
        case "tag"     :  sidebar_switcher.selected = 2;  break;
        case "sticker" :  sidebar_switcher.selected = 3;  break;
        case "map"     :  sidebar_switcher.selected = 4;  break;
      }
    });

    // Make sure that the tabs are displayed nicely
    Utils.set_switcher_tab_widths( sidebar_switcher );

    var box = new Box( Orientation.VERTICAL, 20 ) {
      halign        = Align.FILL,
      valign        = Align.FILL,
      margin_start  = 10,
      margin_end    = 10,
      margin_top    = 5,
      margin_bottom = 5
    };
    box.append( sidebar_switcher );
    box.append( _stack );

    _themer = new ThemeEditor( this );

    // Create the inspector sidebar
    _inspector_nb = new Notebook() {
      show_tabs = false
    };
    _inspector_nb.append_page( box );
    _inspector_nb.append_page( _themer );

  }

  //-------------------------------------------------------------
  // Handles an escape key press in the inspector widget to hide
  // the sidebar.
  private bool stack_keypress( uint keyval, uint keycode, ModifierType state ) {
    if( keyval == Key.Escape ) {
      hide_properties();
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Show or hides the inspector sidebar
  private void inspector_clicked() {
    if( _inspector_nb.get_mapped() ) {
      hide_properties();
    } else {
      show_properties( null, PropertyGrab.NONE );
    }
  }

  //-------------------------------------------------------------
  // Displays the save warning dialog window
  public void show_save_warning( MindMap map ) {

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
    save.add_css_class( Granite.STYLE_CLASS_SUGGESTED_ACTION );
    dialog.add_action_widget( save, ResponseType.ACCEPT );

    dialog.set_transient_for( this );
    dialog.set_default_response( ResponseType.ACCEPT );
    dialog.set_title( "" );

    dialog.response.connect((id) => {
      switch( id ) {
        case ResponseType.ACCEPT :
          save_file( map, true );
          break;
        case ResponseType.CLOSE  :  
          map.close();
          map.doc.remove();
          remove_tab( null );
          break;
      }
      dialog.close();
    });

    dialog.show();

  }

  //-------------------------------------------------------------
  // Displays the overwrite warning dialog window.  Returns true
  // when overwrite is wanted and false when reload is wanted.
  public void ask_modified_overwrite( MindMap map, OverwriteFunc func ) {

    var dialog = new Granite.MessageDialog.with_image_from_icon_name(
      _( "The file %s was modified outside of the application." ).printf( map.doc.filename ),
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

    dialog.response.connect((id) => {
      func( id == ResponseType.ACCEPT );
      dialog.close();
    });

    dialog.show();

  }

  //-------------------------------------------------------------
  // Creates a new file
  public void do_new_file() {

    /* Close any unchanged tabs */
    if( find_unchanged_tab() ) return;

    var map = add_tab( null, TabAddReason.NEW );

    /* Set the title to indicate that we have an unnamed document */
    update_title( map );

  }

  //-------------------------------------------------------------
  // Opens an existing file.
  public void do_open_file() {
    do_open( false );
  }

  //-------------------------------------------------------------
  // Opens a directory.
  public void do_open_directory() {
    do_open( true );
  }

  //-------------------------------------------------------------
  // Allows the user to select a file to open and opens it in the
  // same window.
  public void do_open( bool dir ) {

    var dialog = Utils.make_file_chooser( (dir ? _( "Open Directory" ) : _( "Open File" )), _( "Open" ) );

    var filters = new GLib.ListStore( typeof( FileFilter ) );

    /* Create file filters */
    if( !dir ) {
      var filter = new FileFilter();
      filter.set_filter_name( "Minder" );
      filter.add_pattern( "*.minder" );
      filters.append( filter );
    }

    for( int i=0; i<exports.length(); i++ ) {
      if( exports.index( i ).importable && (exports.index( i ).dir == dir) ) {
        var filter = new FileFilter();
        filter.set_filter_name( exports.index( i ).label );
        foreach( string extension in exports.index( i ).extensions ) {
          filter.add_pattern( "*" + extension );
        }
        filters.append( filter );
      }
    }

    dialog.set_filters( filters );

    if( dir ) {
      dialog.select_folder.begin( this, null, (obj, res) => {
        try {
          var file = dialog.select_folder.end( res );
          if( file != null ) {
            open_file( file.get_path(), dir );
            Utils.store_chooser_folder( file.get_path(), dir );
            get_current_map( "do_open" ).canvas.grab_focus();
          }
        } catch( Error e ) {}
      });
    } else {
      dialog.open.begin( this, null, (obj, res) => {
        try {
          var file = dialog.open.end( res );
          if( file != null ) {
            open_file( file.get_path(), dir );
            Utils.store_chooser_folder( file.get_path(), dir );
            get_current_map( "do_open" ).canvas.grab_focus();
          }
        } catch( Error e ) {}
      });
    }

  }

  //-------------------------------------------------------------
  // Opens the file and display it in the canvas
  public bool open_file( string fname, bool dir ) {
    if( ( dir && !FileUtils.test( fname, FileTest.IS_DIR )) ||
        (!dir && !FileUtils.test( fname, FileTest.IS_REGULAR )) ) {
      return( false );
    }
    close_unchanged_tabs();
    if( fname.has_suffix( ".minder" ) ) {
      var map = add_tab_conditionally( fname, TabAddReason.OPEN );
      update_title( map );
      map.doc.load( false, (valid, msg) => {
        if( valid ) {
          save_tab_state( _nb.page );
        } else {
          close_current_tab();
        }
      });
      return( true );
    } else {
      for( int i=0; i<exports.length(); i++ ) {
        if( exports.index( i ).importable && (exports.index( i ).dir == dir) ) {
          string new_fname;
          if( exports.index( i ).filename_matches( fname, out new_fname ) ) {
            new_fname += ".minder";
            var map = add_tab_conditionally( new_fname, TabAddReason.IMPORT );
            update_title( map );
            if( exports.index( i ).import( fname, map ) ) {
              save_tab_state( _nb.page );
              return( true );
            }
            close_current_tab();
          }
        }
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Imports the given file based on the export name
  public bool import_file( string fname, string export_name, ref string new_fname ) {
    close_unchanged_tabs();
    for( int i=0; i<exports.length(); i++ ) {
      if( exports.index( i ).name == export_name ) {
        var map = add_tab_conditionally( null, TabAddReason.IMPORT );
        new_fname = map.doc.filename;
        update_title( map );
        if( exports.index( i ).import( fname, map ) ) {
          return( true );
        }
        close_current_tab();
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Perform an undo action
  public void do_undo() {
    var map = get_current_map( "do_undo" );
    map.current_undo_buffer().undo();
    map.canvas.grab_focus();
  }

  //-------------------------------------------------------------
  // Perform a redo action
  public void do_redo() {
    var map = get_current_map( "do_redo" );
    map.current_undo_buffer().redo();
    map.canvas.grab_focus();
  }

  //-------------------------------------------------------------
  // Called whenever the theme is changed
  private void on_dark_mode_changed( bool dark_mode ) {
    var gtk_settings = Gtk.Settings.get_default();
    if( gtk_settings != null ) {
      gtk_settings.gtk_application_prefer_dark_theme = dark_mode;
    }
    _brain_btn.icon_name = dark_mode ? "minder-braindump-dark-symbolic" : "minder-braindump-light-symbolic";
    if( !on_elementary ) {
      _prop_btn.icon_name = dark_mode ? "minder-sidebar-dark-symbolic"   : "minder-sidebar-light-symbolic";
    }
    (_stack.get_child_by_name( "current" ) as CurrentInspector).update_icons();
    (_stack.get_child_by_name( "style" )   as StyleInspector).update_icons();
    (_stack.get_child_by_name( "tag" )     as TagInspector).update_icons();
    (_stack.get_child_by_name( "map" )     as MapInspector).update_icons();
  }

  //-------------------------------------------------------------
  // Called when the editable attribute changes within the mindmap.
  private void on_editable_changed( MindMap map ) {
    _brain_btn.sensitive = map.editable;
    set_braindump_ui( map, map.model.braindump_shown );
    (_stack.get_child_by_name( "current" ) as CurrentInspector).editable_changed();
    (_stack.get_child_by_name( "style" )   as StyleInspector).editable_changed();
    (_stack.get_child_by_name( "tag" )     as TagInspector).editable_changed();
    (_stack.get_child_by_name( "map" )     as MapInspector).editable_changed();
    var label = map.doc.label;
    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      if( get_map( i ) == map ) {
        set_tab_label_info( i, map.editable, label, map.doc.filename );
        break;
      }
    }
    update_title( map );
  }

  //-------------------------------------------------------------
  // Handles any changes in the highlight tag mode.
  private void on_tag_highlight_changed( MindMap map ) {
    update_title( map );
  }

  //-------------------------------------------------------------
  // Called whenever the undo buffer changes state.  Updates the
  // state of the undo and redo buffer buttons.
  public void do_buffer_changed( UndoBuffer buf ) {
    _undo_btn.set_sensitive( buf.undoable() );
    _undo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buf.undo_tooltip(), get_accelerator( KeyCommand.UNDO_ACTION ) ) );
    _redo_btn.set_sensitive( buf.redoable() );
    _redo_btn.set_tooltip_markup( Utils.tooltip_with_accel( buf.redo_tooltip(), get_accelerator( KeyCommand.REDO_ACTION ) ) );
  }

  //-------------------------------------------------------------
  // Converts the given node name to an appropriate filename
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

  //-------------------------------------------------------------
  // Allow the user to select a filename to save the document as
  public void save_file( MindMap map, bool remove_after_save ) {

    var dialog  = Utils.make_file_chooser( _( "Save File" ), _( "Save" ) );
    var filters = new GLib.ListStore( typeof( FileFilter ) );

    var filter = new FileFilter();
    filter.set_filter_name( _( "Minder" ) );
    filter.add_pattern( "*.minder" );
    filters.append( filter );
    if( map.doc.is_saved() ) {
      var fname = File.new_for_path( map.doc.filename );
      dialog.set_initial_file( fname ); 
    } else {
      dialog.set_initial_name( map.doc.label );
      if( map.get_nodes().length > 0 ) {
        var root_str = map.get_nodes().index( 0 ).name.text.text.strip();
        if( root_str != "" ) {
          dialog.set_initial_name( convert_name_to_filename( root_str ) );
        }
      }
    }

    dialog.set_filters( filters );

    dialog.save.begin( this, null, (obj, res) => {
      try {
        var file = dialog.save.end( res );
        if( file != null ) {
          var fname = file.get_path();
          if( !fname.has_suffix( ".minder" ) ) {
            fname += ".minder";
          }
          map.doc.filename = fname;
          map.doc.save();
          if( remove_after_save ) {
            map.close();
            remove_tab( null );
          } else {
            set_tab_label_info( _nb.page, map.editable, map.doc.label, fname );
            update_title( map );
            save_tab_state( _nb.page );
            Utils.store_chooser_folder( fname, false );
            map.canvas.grab_focus();
          }
        }
      } catch( Error e ) {}
    });

  }

  //-------------------------------------------------------------
  // Called when the save as button is clicked
  public void do_save_as_file() {
    var map = get_current_map( "do_save_as_file" );
    save_file( map, false );
  }

  //-------------------------------------------------------------
  // Called whenever the node selection changes in the canvas
  private void on_current_changed( MindMap map ) {
    action_set_enabled( "win.action_zoom_selected", (map.get_current_node() != null) );
    _focus_btn.active = map.focus_mode;
    map.model.update_css();
  }

  //-------------------------------------------------------------
  // Called if the canvas changes the scale factor value. Adjusts the
  // UI to match.
  private void change_scale( double scale_factor ) {
    var marks       = DrawArea.get_scale_marks();
    var scale_value = scale_factor * 100;
    var int_value   = (int)scale_value;
    _zoom_btn.set_tooltip_text( _( "Zoom (%d%%)" ).printf( int_value ) );
    _zoom_scale.set_value( scale_value );
    _zoom_in.set_sensitive( scale_value < marks[marks.length-1] );
    _zoom_out.set_sensitive( scale_value > marks[0] );
    save_tab_state( _nb.page );
  }

  //-------------------------------------------------------------
  // Called whenever the DrawArea origin changes in the current tab
  private void change_origin() {
    save_tab_state( _nb.page );
  }

  //-------------------------------------------------------------
  // Forces all of the opened documents in the tabs to automatically
  // save their state before we allow the application to exit.
  private void save_tabs() {
    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var map = get_map( i );
      if( map.editable ) {
        map.close();
      }
    }
  }

  //-------------------------------------------------------------
  // Displays the node properties panel for the current node
  private void show_properties( string? tab, PropertyGrab grab_type ) {
    if( !_inspector_nb.get_mapped() || ((tab != null) && (_stack.visible_child_name != tab)) ) {
      _prop_btn.icon_name    = _prop_hide;
      _prop_btn.tooltip_text = _( "Hide Property Sidebar" );
      _prop_btn.active       = true;
      if( tab != null ) {
        _stack.visible_child_name = tab;
      }
      if( !_inspector_nb.get_mapped() ) {
        _pane.end_child = _inspector_nb;
        _pane.position  = _settings.get_int( "properties-width" );
        if( get_current_map( "show_properties 1" ) != null ) {
          get_current_map( "show_properties 2" ).canvas.see( true, -300 );
        }
      }
      _settings.set_boolean( (_stack.visible_child_name + "-properties-shown"), true );
    }
    switch( grab_type ) {
      case PropertyGrab.FIRST :
        switch( _stack.visible_child_name ) {
          case "current" :  (_stack.get_child_by_name( "current" ) as CurrentInspector).grab_first();  break;
          case "style"   :  (_stack.get_child_by_name( "style" )   as StyleInspector).grab_first();    break;
          case "tag"     :  (_stack.get_child_by_name( "tag" )     as TagInspector).grab_first();      break;
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

  //-------------------------------------------------------------
  // Displays the theme editor pane
  public void show_theme_editor( bool edit ) {
    _themer.initialize( get_current_map().get_theme(), edit );
    _inspector_nb.page = 1;
  }

  //-------------------------------------------------------------
  // Hides the theme editor pane
  public void hide_theme_editor() {
    _inspector_nb.page = 0;
  }

  //-------------------------------------------------------------
  // Hides the node properties panel
  private void hide_properties() {
    if( !_inspector_nb.get_mapped() ) return;
    _prop_btn.icon_name    = _prop_show;
    _prop_btn.tooltip_text = _( "Show Property Sidebar" );
    _prop_btn.active       = false;
    _pane.position_set     = false;
    _pane.end_child        = null;
    get_current_map( "hide_properties" ).canvas.grab_focus();
    _settings.set_boolean( "current-properties-shown", false );
    _settings.set_boolean( "style-properties-shown",   false );
    _settings.set_boolean( "tag-properties-shown",     false );
    _settings.set_boolean( "sticker-properties-shown", false );
    _settings.set_boolean( "map-properties-shown",     false );
  }

  //-------------------------------------------------------------
  // Converts the given value from the scale to the zoom value to
  // use.
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

  //-------------------------------------------------------------
  // Sets the scale factor for the level of zoom to perform
  private bool adjust_zoom( ScrollType scroll, double new_value ) {
    var value        = zoom_to_value( new_value );
    var scale_factor = value / 100;
    var map          = get_current_map( "adjust_zoom" );
    map.canvas.set_scaling_factor( scale_factor );
    map.canvas.queue_draw();
    return( false );
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-n keyboard shortcut
  private void action_new() {
    do_new_file();
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-o keyboard shortcut
  private void action_open() {
    do_open_file();
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-s keyboard shortcut
  private void action_save() {
    var map = get_current_map( "action_save" );
    if( map.doc.is_saved() ) {
      map.doc.save();
    } else {
      save_file( map, false );
    }
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-Shift-s keyboard shortcut
  private void action_save_as() {
    do_save_as_file();
  }

  //-------------------------------------------------------------
  // Saves the window size to gsettings.
  private void save_window_size() {
    Minder.settings.set_int( "window-w", get_width() );
    Minder.settings.set_int( "window-h", get_height() );
  }

  //-------------------------------------------------------------
  // Restores the window size from gsettings.
  private void set_window_size() {
    set_default_size( Minder.settings.get_int( "window-w" ), Minder.settings.get_int( "window-h" ) );
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-q keyboard shortcut
  private void action_quit() {
    save_window_size();
    save_tabs();
    destroy();
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-z keyboard shortcut
  private void action_undo() {
    do_undo();
  }

  //-------------------------------------------------------------
  // Called when the user uses the Control-Shift-z keyboard shortcut
  private void action_redo() {
    do_redo();
  }

  //-------------------------------------------------------------
  // Zooms into the image (makes things larger)
  private void action_zoom_in() {
    var map = get_current_map( "action_zoom_in" );
    map.canvas.zoom_in();
  }

  //-------------------------------------------------------------
  // Zooms out of the image (makes things smaller)
  private void action_zoom_out() {
    var map = get_current_map( "action_zoom_out" );
    map.canvas.zoom_out();
  }

  //-------------------------------------------------------------
  // Zooms to make all nodes visible within the viewer
  private void action_zoom_fit() {
    var map = get_current_map( "action_zoom_fit" );
    map.canvas.zoom_to_fit();
    map.canvas.grab_focus();
  }

  //-------------------------------------------------------------
  // Zooms to make the currently selected node and its tree put
  // into view.
  private void action_zoom_selected() {
    var map = get_current_map( "action_zoom_selected" );
    map.canvas.zoom_to_selected();
    map.canvas.grab_focus();
  }

  //-------------------------------------------------------------
  // Sets the zoom to 100%.
  private void action_zoom_actual() {
    var map = get_current_map( "action_zoom_actual" );
    map.canvas.zoom_actual();
    map.canvas.grab_focus();
  }

  //-------------------------------------------------------------
  // Display matched items to the search within the search popover.
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
    var current  = get_current_map( "on_search_change" );
    var text     = _search_entry.get_text().casefold();
    var name     = all_tabs ? get_tab_label_name( _nb.page ) : "";
    if( text == "" ) return;
    current.model.get_match_items( name, text, search_opts, ref _search_items );
    if( all_tabs ) {
      for( int i=0; i<_nb.get_n_pages(); i++ ) {
        var map = get_map( i );
        if( map != current ) {
          map.model.get_match_items( get_tab_label_name( i ), text, search_opts, ref _search_items );
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Called when the user selects an item in the search list.
  // The current node will be set to the node associated with the
  // selection.
  private void on_search_clicked( TreeView view, TreePath path, TreeViewColumn? col ) {
    TreeIter    it;
    string      tabname = "";
    Node?       node    = null;
    Connection? conn    = null;
    Callout?    callout = null;
    NodeGroup?  group   = null;
    var         map     = get_current_map( "on_search_clicked" );
    _search_items.get_iter( out it, path );
    _search_items.get( it, 2, &node, 3, &conn, 4, &callout, 5, &group, 6, &tabname, -1 );
    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      if( get_tab_label_name( i ) == tabname ) {
        map = get_map( i );
        _nb.page = i;
        break;
      }
    }
    if( node != null ) {
      map.set_current_node( node );
      map.canvas.see();
    } else if( conn != null ) {
      map.set_current_connection( conn );
      map.canvas.see();
    } else if( callout != null ) {
      map.set_current_callout( callout );
      map.canvas.see();
    } else if( group != null ) {
      map.set_current_group( group );
      map.canvas.see();
    }
    _search.closed();
    map.canvas.grab_focus();
  }

  //-------------------------------------------------------------
  // Checks the given filename to see if it contains any of the
  // given suffixes.  If a valid suffix is found, return the
  // filename without modification; otherwise, returns the filename
  // with the extension added.
  public string repair_filename( string fname, string[] extensions ) {
    foreach (string ext in extensions) {
      if( fname.has_suffix( ext ) ) {
        return( fname );
      }
    }
    return( fname + extensions[0] );
  }

  //-------------------------------------------------------------
  // Exports the model to the printer
  private void action_print() {
    var print = new ExportPrint();
    print.print( get_current_map( "action_print" ), this );
  }

  //-------------------------------------------------------------
  // Displays the preferences dialog
  private void action_prefs() {
    var prefs = new Preferences( this );
    prefs.present();
  }

  //-------------------------------------------------------------
  // Displays the shortcuts cheatsheet
  private void action_shortcuts() {

    var ui_str  = shortcuts.get_ui_string();
    var builder = new Builder.from_string( ui_str, ui_str.length );
    // var builder = new Builder.from_resource( "/com/github/phase1geo/minder/shortcuts.ui" );
    var win     = builder.get_object( "shortcuts" ) as ShortcutsWindow;
    var map     = get_current_map();

    win.transient_for = this;
    win.view_name     = null;

    /* Display the most relevant information based on the current state */
    if( map.is_node_editable() || map.is_connection_editable() ) {
      win.section_name = "editing";
    } else if( map.is_node_selected() ) {
      win.section_name = "node";
    } else if( map.is_connection_selected() ) {
      win.section_name = "connection";
    } else if( map.is_callout_selected() ) {
      win.section_name = "callout";
    } else if( map.is_group_selected() ) {
      win.section_name = "group";
    } else {
      win.section_name = "general";
    }

    win.show();

  }

  //-------------------------------------------------------------
  // Displays the current sidebar tab
  private void action_show_current() {
    show_properties( "current", PropertyGrab.FIRST );
  }

  //-------------------------------------------------------------
  // Displays the style sidebar tab
  private void action_show_style() {
    show_properties( "style", PropertyGrab.FIRST );
  }

  //-------------------------------------------------------------
  // Displays the stickers sidebar tab
  private void action_show_stickers() {
    show_properties( "sticker", PropertyGrab.FIRST );
  }

  //-------------------------------------------------------------
  // Displays the map sidebar tab
  private void action_show_map() {
    show_properties( "map", PropertyGrab.FIRST );
  }

  //-------------------------------------------------------------
  // Shows the next tab in the tabbar
  private void action_next_tab() {
    _nb.next_page();
  }

  //-------------------------------------------------------------
  // Shows the previous tab in the tabbar
  private void action_prev_tab() {
    _nb.prev_page();
  }

  //-------------------------------------------------------------
  // Displays the about dialog window.
  private void action_about() {
    var about_win = new About( this );
    about_win.show();
  }

  //-------------------------------------------------------------
  // Toggles the braindump toggle button
  public void toggle_braindump() {
    _brain_btn.clicked();
  }

  //-------------------------------------------------------------
  // Toggles the focus toggle button
  public void toggle_focus_mode() {
    _focus_btn.clicked();
  }

  //-------------------------------------------------------------
  // Toggles the find toggle button
  public void show_find() {
    _search_btn.activate();
  }

  //-------------------------------------------------------------
  // Closes the curren tab
  private void action_close_current_tab() {
    close_current_tab();
  }

  //-------------------------------------------------------------
  // Save the current tab state
  private void save_tab_state( uint current_page ) {

    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder" );

    if( DirUtils.create_with_parents( dir, 0775 ) != 0 ) {
      return;
    }

    var       fname = GLib.Path.build_filename( dir, "tab_state.xml" );
    Xml.Doc*  doc   = new Xml.Doc( "1.0" );
    Xml.Node* root  = new Xml.Node( null, "tabs" );

    doc->set_root_element( root );

    for( int i=0; i<_nb.get_n_pages(); i++ ) {
      var       map  = get_map( i );
      Xml.Node* node = new Xml.Node( null, "tab" );
      node->new_prop( "path",      map.doc.filename );
      node->new_prop( "saved",     map.doc.is_saved().to_string() );
      node->new_prop( "origin-x",  map.canvas.origin_x.to_string() );
      node->new_prop( "origin-y",  map.canvas.origin_y.to_string() );
      node->new_prop( "scale",     map.canvas.sfactor.to_string() );
      node->new_prop( "braindump", map.model.braindump_shown.to_string() );
      node->new_prop( "readonly",  (!map.editable).to_string() );
      root->add_child( node );
    }

    root->new_prop( "selected", current_page.to_string() );
    root->new_prop( "version",  "2" );

    /* Save the file */
    doc->save_format_file( fname, 1 );

    delete doc;

  }

  //-------------------------------------------------------------
  // Returns the filepath of the tab_state.xml file.
  private string get_tab_state_path() {
    return( GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "tab_state.xml" ) );
  }

  //-------------------------------------------------------------
  // Loads the tab state
  public void load_tab_state() {

    var tab_state = get_tab_state_path();
    if( !FileUtils.test( tab_state, FileTest.EXISTS ) ) {
      do_new_file();
      return;
    }

    Xml.Doc* doc  = Xml.Parser.parse_file( tab_state );

    if( doc == null ) {
      do_new_file();
      return;
    }

    var root    = doc->get_root_element();
    var version = root->get_prop( "version" );

    delete doc;

    if( version == null ) {
      Idle.add(() => {
        request_upgrade_action(() => {
          load_tab_state_xml();
        });
        return( false );
      });
    } else {
      load_tab_state_xml();
    }

  }

  //-------------------------------------------------------------
  // Displays the UI that will allow the user to specify the
  // upgrade action to use.
  private void request_upgrade_action( AfterLoadTabFunc func ) {

    var dialog = new Granite.MessageDialog.with_image_from_icon_name(
      _( "File upgrades needed" ),
      _( "All previously opened tabs contain Minder files that need to be upgraded to be edited by this version of Minder.\n\nSelect an upgrade option below." ),
      "system-software-update",
      ButtonsType.NONE
    );

    var exit  = new Button.with_label( _( "Quit Minder" ) );
    dialog.add_action_widget( exit, ResponseType.CLOSE );

    var apply = new Button.with_label( _( "Apply" ) );
    dialog.add_action_widget( apply, ResponseType.APPLY );

    var options = new DropDown.from_strings( UpgradeAction.tab_labels() ) {
      halign = Align.START,
      selected = -1
    };

    var description = new Label( "" ) {
      halign = Align.FILL,
      hexpand = true,
      use_markup = true,
      max_width_chars = 0,
      wrap = true,
      margin_start = 20
    };

    var desc_exp = new Expander( _( "Detail" ) ) {
      child = description,
      expanded = false,
      margin_bottom = 10
    };

    options.notify["selected"].connect(() => {
      switch( options.selected ) {
        case 0 :  description.label = _( "<small>Upgrades each Minder file which had a tab opened for it in the last Minder session.  This action is irreversible as older versions of Minder cannot read the upgraded format.</small>" );  break;
        case 1 :  description.label = _( "<small>Upgrades each Minder file which had a tab opened for it in the last Minder session, but saves a copy of the older, original file in its original directory.</small>" );  break;
        case 2 :  description.label = _( "<small>Leaves each Minder file in the original format, but opens each tab as read-only.  Read-only mindmaps can be viewed but cannot be changed.  To change a read-only mindmap, you can use the 'Save As' button in the header bar to write it to the newer format.</small>" );  break;
      }
    });

    options.selected = settings.get_int( "upgrade-action" );

    var remember = new CheckButton();
    var rem_description = new Label( _( "Use the selected option when future older Minder files are opened" ) ) {
      halign = Align.START
    };
    var rem_info = new Label( _( "<small>This can be changed in preferences</small>" ) ) {
      halign     = Align.START,
      use_markup = true
    };
    var grid = new Grid() {
      row_spacing  = 10,
      margin_top   = 20,
      margin_start = 20
    };

    grid.attach( options,         0, 0, 2 );
    grid.attach( desc_exp,        0, 1, 2 );
    grid.attach( remember,        0, 2 );
    grid.attach( rem_description, 1, 2 );
    grid.attach( rem_info,        1, 3 );

    var box = dialog.get_content_area();
    box.append( grid );

    dialog.set_transient_for( this );
    dialog.set_modal( true );
    dialog.set_default_response( ResponseType.APPLY );
    dialog.set_title( _( "Upgrades Needed" ) );

    dialog.response.connect((id) => {
      if( id == ResponseType.APPLY ) {
        var action = (UpgradeAction)options.selected;
        settings.set_int( "upgrade-action", action );
        settings.set_boolean( "ask-for-upgrade-action", !remember.active );
        if( func != null ) {
          func();
        }
      } else if( id == ResponseType.CLOSE ) {
        destroy();
      }
      dialog.close();
    });

    dialog.present();

  }

  //-------------------------------------------------------------
  // Loads the tab state after the upgrade action has been established.
  private void load_tab_state_xml() {

    Xml.Doc* doc  = Xml.Parser.parse_file( get_tab_state_path() );

    if( doc == null ) {
      return;
    }

    var root        = doc->get_root_element();
    var tabs        = 0;
    var tab_skipped = false;

    UpgradeAction? upgrade_action = null;
    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tab") ) {
        var fname = it->get_prop( "path" );
        if( FileUtils.test( fname, FileTest.EXISTS ) ) {
          var saved     = it->get_prop( "saved" );
          var origin_x  = it->get_prop( "origin-x" );
          var origin_y  = it->get_prop( "origin-y" );
          var sfactor   = it->get_prop( "scale" );
          var braindump = it->get_prop( "braindump" );
          var read_only = it->get_prop( "readonly" );
          var map       = add_tab( fname, TabAddReason.LOAD );
          if( origin_x != null ) {
            map.canvas.origin_x = int.parse( origin_x );
          }
          if( origin_y != null ) {
            map.canvas.origin_y = int.parse( origin_y );
          }
          if( sfactor != null ) {
            map.canvas.sfactor = double.parse( sfactor );
            change_scale( map.canvas.sfactor );
          }
          if( braindump != null ) {
            map.model.braindump_shown = bool.parse( braindump );
          }
          if( read_only != null ) {
            map.editable = !bool.parse( read_only );
          }
          map.doc.load_filename( fname, bool.parse( saved ) );
          map.doc.load( true, null );
          tabs++;
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
        _nb.page = int.parse( s );
        tab_changed( _nb.page );
      }
    }

    // Save the tab state if we did something
    if( (tabs == 0) || tab_skipped ) {
      save_tab_state( _nb.page );
    }

    delete doc;

  }

  //-------------------------------------------------------------
  // Returns the height of a single line label
  public int get_label_height() {
    Requisition min, nat;
    _scale_lbl.get_preferred_size( out min, out nat );
    return( nat.height );
  }

  //-------------------------------------------------------------
  // Generate a notification
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

  //-------------------------------------------------------------
  // SHORTCUT HANDLING
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Adds and action for the given command.
  private void set_action_for_command( KeyCommand command ) {

    // Create action to execute
    var action = new SimpleAction( command.to_string(), null );
    action.activate.connect((v) => {
      var func = command.get_func();
      func( get_current_map() );
    });
    _actions.add_action( action );

    var shortcut = shortcuts.get_shortcut( command );
    if( shortcut != null ) {
      application.set_accels_for_action( "win.%s".printf( command.to_string() ), { shortcut.get_accelerator() } );
    }

  }

  //-------------------------------------------------------------
  // Appends a command with the given command to the specified menu.
  private void append_menu_item( GLib.Menu menu, KeyCommand command, string label ) {
    menu.append( label, "win.%s".printf( command.to_string() ) );
    set_action_for_command( command );
  }

  //-------------------------------------------------------------
  // Registers a widget when only a tooltip label update
  // is needed.
  public void register_widget_for_tooltip( Gtk.Widget w, KeyCommand command, string label ) {
    var tooltip = new ShortcutTooltip( w, label );
    _shortcut_widgets.set( command, tooltip );
    var shortcut = shortcuts.get_shortcut( command );
    if( shortcut != null ) {
      tooltip.set_tooltip( shortcut );
    }
  }

  //-------------------------------------------------------------
  // Updates registers for shortcuts
  public void register_widget_for_shortcut( Gtk.Widget w, KeyCommand command, string label ) {
    register_widget_for_tooltip( w, command, label );
    set_action_for_command( command );
  }

  //-------------------------------------------------------------
  // Handles any changes to shortcuts.  If a shortcut is used by
  // the main window, update the shortcut and associated tooltips.
  private void shortcut_changed( KeyCommand command, Shortcut? shortcut ) {
    var action = _actions.lookup_action( command.to_string() );
    if( action != null ) {
      var detail_name = "win.%s".printf( command.to_string() );
      if( shortcut == null ) {
        application.set_accels_for_action( detail_name, {} );
      } else {
        application.set_accels_for_action( detail_name, { shortcut.get_accelerator() } );
      }
    }
    if( _shortcut_widgets.has_key( command ) ) {
      _shortcut_widgets.get( command ).set_tooltip( shortcut );
    }
  }

  //-------------------------------------------------------------
  // Returns the shortcut accelerator associated with the given
  // key command.
  private string get_accelerator( KeyCommand command ) {
    var shortcut = shortcuts.get_shortcut( command );
    if( shortcut != null ) {
      return( shortcut.get_accelerator() );
    }
    return( "" );
  }

  //-------------------------------------------------------------
  // Execute command.
  public void execute_command( KeyCommand command ) {
    var func = command.get_func();
    func( get_current_map() );
  }

}

