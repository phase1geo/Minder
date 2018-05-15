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

public class MainWindow : ApplicationWindow {

  private GLib.Settings  _settings;
  private HeaderBar?     _header        = null;
  private DrawArea?      _canvas        = null;
  private Document?      _doc           = null;
  private Revealer?      _inspector     = null;
  private Stack?         _stack         = null;
  private Popover?       _zoom          = null;
  private Popover?       _search        = null;
  private SearchEntry?   _search_entry  = null;
  private TreeView       _search_list   = null;
  private Gtk.ListStore  _search_items  = null;
  private ScrolledWindow _search_scroll = null;
  private Popover?       _export        = null;
  private Scale?         _zoom_scale    = null;
  private ModelButton?   _zoom_in       = null;
  private ModelButton?   _zoom_out      = null;
  private ModelButton?   _zoom_sel      = null;
  private Button?        _undo_btn      = null;
  private Button?        _redo_btn      = null;
  private Button?        _search_btn    = null;

  private const GLib.ActionEntry[] action_entries = {
    { "action_new",           action_new },
    { "action_open",          action_open },
    { "action_save",          action_save },
    { "action_save_as",       action_save_as },
    { "action_undo",          action_undo },
    { "action_redo",          action_redo },
    { "action_search",        action_search },
    { "action_quit",          action_quit },
    { "action_zoom_in",       action_zoom_in },
    { "action_zoom_out",      action_zoom_out },
    { "action_zoom_fit",      action_zoom_fit },
    { "action_zoom_selected", action_zoom_selected },
    { "action_zoom_actual",   action_zoom_actual },
    { "action_export_opml",   action_export_opml },
    { "action_export_pdf",    action_export_pdf },
    { "action_export_png",    action_export_png },
    { "action_export_print",  action_export_print }
  };

  /* Create the main window UI */
  public MainWindow( Gtk.Application app, GLib.Settings settings ) {

    _settings = settings;

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
    
    /* Add keyboard shortcuts */
    add_keyboard_shortcuts( app );

    /* Create and pack the canvas */
    _canvas = new DrawArea();
    _canvas.node_changed.connect( on_node_changed );
    _canvas.scale_changed.connect( change_scale );
    _canvas.show_properties.connect( show_properties );
    _canvas.map_event.connect( on_canvas_mapped );
    _canvas.undo_buffer.buffer_changed.connect( do_buffer_changed );
    _canvas.animator.enable = _settings.get_boolean( "enable-animations" );

    /* Create title toolbar */
    var new_btn = new Button.from_icon_name( "document-new-symbolic", IconSize.SMALL_TOOLBAR );
    new_btn.set_tooltip_text( _( "New File" ) );
    new_btn.clicked.connect( do_new_file );
    _header.pack_start( new_btn );

    var open_btn = new Button.from_icon_name( "document-open-symbolic", IconSize.SMALL_TOOLBAR );
    open_btn.set_tooltip_text( _( "Open File" ) );
    open_btn.clicked.connect( do_open_file );
    _header.pack_start( open_btn );

    var save_btn = new Button.from_icon_name( "document-save-as-symbolic", IconSize.SMALL_TOOLBAR );
    save_btn.set_tooltip_text( _( "Save File As" ) );
    save_btn.clicked.connect( do_save_file );
    _header.pack_start( save_btn );

    _undo_btn = new Button.from_icon_name( "edit-undo-symbolic", IconSize.SMALL_TOOLBAR );
    _undo_btn.set_tooltip_text( _( "Undo" ) );
    _undo_btn.set_sensitive( false );
    _undo_btn.clicked.connect( do_undo );
    _header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( "edit-redo-symbolic", IconSize.SMALL_TOOLBAR );
    _redo_btn.set_tooltip_text( _( "Redo" ) );
    _redo_btn.set_sensitive( false );
    _redo_btn.clicked.connect( do_redo );
    _header.pack_start( _redo_btn );

    /* Add the buttons on the right side in the reverse order */
    add_property_button();
    add_export_button();
    add_search_button();
    add_zoom_button();

    /* Create the horizontal box that will contain the canvas and the properties sidebar */
    var hbox = new Box( Orientation.HORIZONTAL, 0 );
    hbox.pack_start( _canvas,    true,  true, 0 );
    hbox.pack_start( _inspector, false, true, 0 );

    /* Display the UI */
    add( hbox );
    show_all();

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
  
    app.set_accels_for_action( "win.action_new", "<Control>n" );
    app.set_accels_for_action( "win.action_open", "<Control>o" );
    app.set_accels_for_action( "win.action_save", "<Control>s" );
    app.set_accels_for_action( "win.action_save_as", "<Control><Shift>s" );
    app.set_accels_for_action( "win.action_undo", "<Control>z" );
    app.set_accels_for_action( "win.action_redo", "<Control><Shift>z" );
    app.set_accels_for_action( "win.action_search", "<Control>f" );
    app.set_accels_for_action( "win.action_quit", "<Control>q" );
    app.set_accels_for_action( "win.action_zoom_actual", "<Control>0" );
    app.set_accels_for_action( "win.action_zoom_in", "<Control>plus" );
    app.set_accels_for_action( "win.action_zoom_out", "<Control>minus" );
    
  }

  /* Adds the zoom functionality */
  private void add_zoom_button() {

    /* Create the menu button */
    var menu_btn = new MenuButton();
    menu_btn.set_image( new Image.from_icon_name( "zoom-fit-best-symbolic", IconSize.SMALL_TOOLBAR ) );
    menu_btn.set_tooltip_text( _( "Zoom" ) );
    _header.pack_end( menu_btn );

    /* Create zoom menu popover */
    Box box = new Box( Orientation.VERTICAL, 5 );

    var marks     = _canvas.get_scale_marks();
    var scale_lbl = new Label( _( "Zoom to Percent" ) );
    _zoom_scale   = new Scale.with_range( Orientation.HORIZONTAL, marks[0], marks[marks.length-1], 25 );
    foreach (double mark in marks) {
      _zoom_scale.add_mark( mark, PositionType.BOTTOM, "'" );
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
    _zoom_sel.set_sensitive( false );

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
  private void add_search_button() {

    /* Create the menu button */
    _search_btn = new MenuButton();
    _search_btn.set_image( new Image.from_icon_name( "edit-find-symbolic", IconSize.SMALL_TOOLBAR ) );
    _search_btn.set_tooltip_text( _( "Search" ) );
    _header.pack_end( _search_btn );

    /* Create search popover */
    var box = new Box( Orientation.VERTICAL, 5 );

    /* Create the search entry field */
    _search_entry = new SearchEntry();
    _search_entry.placeholder_text = _( "Search Nodes" );
    _search_entry.search_changed.connect( on_search_change );

    _search_items = new Gtk.ListStore( 2, typeof(string), typeof(Node) );

    /* Create the treeview */
    _search_list = new TreeView.with_model( _search_items );
    _search_list.insert_column_with_attributes( -1, null, new CellRendererText(), "markup", 0 );
    _search_list.headers_visible = false;
    _search_list.activate_on_single_click = true;
    _search_list.row_activated.connect( on_search_clicked );

    /* Create the scrolled window for the treeview */
    _search_scroll = new ScrolledWindow( null, null );
    _search_scroll.height_request = 200;
    _search_scroll.hscrollbar_policy = PolicyType.EXTERNAL;
    _search_scroll.add( _search_list );

    box.pack_start( _search_entry,  false, true );
    box.pack_start( _search_scroll, true,  true );
    box.show_all();

    /* Create the popover and associate it with the menu button */
    _search = new Popover( null );
    _search.add( box );
    _search_btn.popover = _search;

  }

  /* Adds the export functionality */
  private void add_export_button() {

    /* Create the menu button */
    var menu_btn = new MenuButton();
    menu_btn.set_image( new Image.from_icon_name( "document-export-symbolic", IconSize.SMALL_TOOLBAR ) );
    menu_btn.set_tooltip_text( _( "Export" ) );
    _header.pack_end( menu_btn );

    /* Create export menu */
    var box = new Box( Orientation.VERTICAL, 5 );

    var opml = new ModelButton();
    opml.text = _( "Export To OPML" );
    opml.action_name = "win.action_export_opml";

    var pdf = new ModelButton();
    pdf.text = _( "Export to PDF" );
    pdf.action_name = "win.action_export_pdf";
    pdf.set_sensitive( false );
    
    var png = new ModelButton();
    png.text = _( "Export to PNG" );
    png.action_name = "win.action_export_png";
    png.set_sensitive( false );

    var print = new ModelButton();
    print.text = _( "Print" );
    print.action_name = "win.action_export_print";
    print.set_sensitive( false );

    box.pack_start( opml,  false, true );
    box.pack_start( pdf,   false, true );
    box.pack_start( png,   false, true );
    box.pack_start( print, false, true );
    box.show_all();

    /* Create the popover and associate it with clicking on the menu button */
    _export = new Popover( null );
    _export.add( box );
    menu_btn.popover = _export;

  }

  /* Adds the property functionality */
  private void add_property_button() {

    /* Add the menubutton */
    var menu_btn = new Button.from_icon_name( "document-properties-symbolic", IconSize.SMALL_TOOLBAR );
    menu_btn.set_tooltip_text( _( "Properties" ) );
    menu_btn.clicked.connect( inspector_clicked );
    _header.pack_end( menu_btn );

    /* Create the inspector sidebar */
    var box   = new Box( Orientation.VERTICAL, 20 );
    var sb    = new StackSwitcher();

    _stack = new Stack();
    _stack.set_transition_type( StackTransitionType.SLIDE_LEFT_RIGHT );
    _stack.set_transition_duration( 500 );
    _stack.add_titled( new NodeInspector( _canvas ), "node", "Node" );
    _stack.add_titled( new MapInspector( _canvas, _settings ),  "map",  "Map" );

    /* If the stack switcher is clicked, save off which tab is in view */
    _stack.notify.connect((ps) => {
      if( ps.name == "visible-child" ) {
        _settings.set_boolean( "node-properties-shown", (_stack.visible_child_name == "node") );
        _settings.set_boolean( "map-properties-shown",  (_stack.visible_child_name == "map") );
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
    if( _settings.get_boolean( "node-properties-shown" ) ) {
      show_properties( "node" );
    } else if( _settings.get_boolean( "map-properties-shown" ) ) {
      show_properties( "map" );
    }

  }

  /* Show or hides the inspector sidebar */
  private void inspector_clicked() {
    if( _inspector.child_revealed ) {
      hide_properties();
    } else {
      show_properties( null );
    }
  }

  /*
   Allow the user to create a new Minder file.  Checks to see if the current
   document needs to be saved and saves it (if necessary).
  */
  public void do_new_file() {

    /* Save any changes to the current document */
    if( _doc != null ) {
      _doc.auto_save();
    }

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
      _doc.auto_save();
    }

    /* Get the file to open from the user */
    FileChooserDialog dialog = new FileChooserDialog( _( "Open File" ), this, FileChooserAction.OPEN,
      _( "Cancel" ), ResponseType.CANCEL, _( "Open" ), ResponseType.ACCEPT );

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

    dialog.close();
    _canvas.grab_focus();

  }

  /* Opens the file and display it in the canvas */
  public bool open_file( string fname ) {
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
  public void do_save_file() {
    FileChooserDialog dialog = new FileChooserDialog( _( "Save File" ), this, FileChooserAction.SAVE,
      _( "Cancel" ), ResponseType.CANCEL, _( "Save" ), ResponseType.ACCEPT );
    FileFilter        filter = new FileFilter();
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
    }
    dialog.close();
    _canvas.grab_focus();
  }

  /* Called whenever the node selection changes in the canvas */
  private void on_node_changed() {
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
  private void show_properties( string? tab ) {
    if( _inspector.reveal_child && ((tab == null) || (_stack.visible_child_name == tab)) ) return;
    if( tab != null ) {
      _stack.visible_child_name = tab;
    }
    if( !_inspector.reveal_child ) {
      _inspector.reveal_child = true;
      _canvas.see( -300 );
    }
    _settings.set_boolean( (_stack.visible_child_name + "-properties-shown"), true );
  }

  /* Hides the node properties panel */
  private void hide_properties() {
    if( !_inspector.reveal_child ) return;
    _inspector.reveal_child = false;
    _settings.set_boolean( "node-properties-shown", false );
    _settings.set_boolean( "map-properties-shown",  false );
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
  
  /* Called when the user uses the Control-n keyboard shortcut */
  private void action_new() {
    do_new_file();
  }
  
  /* Called when the user uses the Control-o keyboard shortcut */
  private void action_open() {
    do_open_file();
  }
  
  /* Called when the user uses the Control-s keyboard shortcut */
  private void action_save() {
    _doc.save();
  }
  
  /* Called when the user uses the Control-S keyboard shortcut */
  private void action_save_as() {
    do_save_file();
  }
  
  /* Called when the user uses the Control-z keyboard shortcut */
  private void action_undo() {
    do_undo();
  }
  
  /* Called when the user uses the Control-Z keyboard shortcut */
  private void action_redo() {
    do_redo();
  }
  
  /* Called when the user uses the Control-f keyboard shortcut */
  private void action_search() {
    _search_btn.clicked();
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
    _search_items.clear();
    if( _search_entry.get_text() != "" ) {
      _canvas.get_match_items( _search_entry.get_text().casefold(), ref _search_items );
    }
  }

  /*
   Called when the user selects an item in the search list.  The current node
   will be set to the node associated with the selection.
  */
  private void on_search_clicked( TreePath path, TreeViewColumn col ) {
    TreeIter it;
    Node?    node = null;
    _search_items.get_iter( out it, path );
    _search_items.get( it, 1, &node, -1 );
    if( node != null ) {
      _canvas.set_current_node( node );
    }
    _search.closed();
    _canvas.grab_focus();
  }

  /* Exports the model in OPML format */
  private void action_export_opml() {
    FileChooserDialog dialog = new FileChooserDialog( _( "Export OPML File" ), this, FileChooserAction.SAVE,
      _( "Cancel" ), ResponseType.CANCEL, _( "Export" ), ResponseType.ACCEPT );
    FileFilter        filter = new FileFilter();
    filter.set_filter_name( _( "OPML" ) );
    filter.add_pattern( "*.opml" );
    dialog.add_filter( filter );
    if( dialog.run() == ResponseType.ACCEPT ) {
      string fname = dialog.get_filename();
      if( fname.substring( -5, -1 ) != ".opml" ) {
        fname += ".opml";
      }
      ExportOPML.export( fname, _canvas );
    }
    dialog.close();
  }

  /* Exports the model in PDF format */
  private void action_export_pdf() {
    FileChooserDialog dialog = new FileChooserDialog( _( "Export PDF File" ), this, FileChooserAction.SAVE,
      _( "Cancel" ), ResponseType.CANCEL, _( "Export" ), ResponseType.ACCEPT );
    FileFilter        filter = new FileFilter();
    filter.set_filter_name( _( "PDF" ) );
    filter.add_pattern( "*.pdf" );
    dialog.add_filter( filter );
    if( dialog.run() == ResponseType.ACCEPT ) {
      string fname = dialog.get_filename();
      if( fname.substring( -4, -1 ) != ".pdf" ) {
        fname += ".pdf";
      }
      ExportPDF.export( fname, _canvas );
    }
    dialog.close();
  }
  
  /* Exports the model in PNG format */
  private void action_export_png() {
    FileChooserDialog dialog = new FileChooserDialog( _( "Export PNG File" ), this, FileChooserAction.SAVE,
      _( "Cancel" ), ResponseType.CANCEL, _( "Export" ), ResponseType.ACCEPT );
    FileFilter        filter = new FileFilter();
    filter.set_filter_name( _( "PNG" ) );
    filter.add_pattern( "*.png" );
    dialog.add_filter( filter );
    if( dialog.run() == ResponseType.ACCEPT ) {
      string fname = dialog.get_filename();
      if( fname.substring( -4, -1 ) != ".png" ) {
        fname += ".png";
      }
      ExportPNG.export( fname, _canvas );
    }
    dialog.close();
  }

  /* Exports the model to the printer */
  private void action_export_print() {
    var print = new ExportPrint();
    print.print( _canvas, this );
  }

}

