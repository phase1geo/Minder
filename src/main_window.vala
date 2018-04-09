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

  private DrawArea?      _canvas        = null;
  private Document?      _doc           = null;
  private Popover?       _inspector     = null;
  private Popover?       _zoom          = null;
  private Popover?       _search        = null;
  private SearchEntry?   _search_entry  = null;
  private TreeView       _search_list   = null;
  private Gtk.ListStore  _search_items  = null;
  private ScrolledWindow _search_scroll = null;
  private Popover?       _export        = null;
  private MenuButton?    _opts_btn      = null;
  private Scale?         _zoom_scale    = null;
  private ModelButton?   _zoom_sel      = null;
  private Button?        _undo_btn      = null;
  private Button?        _redo_btn      = null;

  private const GLib.ActionEntry[] action_entries = {
    { "action_zoom_fit",      action_zoom_fit },
    { "action_zoom_selected", action_zoom_selected },
    { "action_zoom_actual",   action_zoom_actual },
    { "action_export_opml",   action_export_opml },
    { "action_export_pdf",    action_export_pdf },
    { "action_export_print",  action_export_print }
  };

  /* Create the main window UI */
  public MainWindow( Gtk.Application app ) {

    var header = new HeaderBar();
    header.set_title( _( "Minder" ) );
    header.set_subtitle( _( "Mind-Mapping Application" ) );
    header.set_show_close_button( true );

    title = _( "Minder" );
    set_position( Gtk.WindowPosition.CENTER );
    set_default_size( 1000, 800 );
    set_titlebar( header );
    set_border_width( 2 );
    destroy.connect( Gtk.main_quit );

    var actions = new SimpleActionGroup ();
    actions.add_action_entries( action_entries, this );
    insert_action_group( "win", actions );

    /* Create title toolbar */
    var new_btn = new Button.from_icon_name( "document-new-symbolic", IconSize.SMALL_TOOLBAR );
    new_btn.set_tooltip_text( _( "New File" ) );
    new_btn.clicked.connect( do_new_file );
    header.pack_start( new_btn );

    var open_btn = new Button.from_icon_name( "document-open-symbolic", IconSize.SMALL_TOOLBAR );
    open_btn.set_tooltip_text( _( "Open File" ) );
    open_btn.clicked.connect( do_open_file );
    header.pack_start( open_btn );

    var save_btn = new Button.from_icon_name( "document-save-as-symbolic", IconSize.SMALL_TOOLBAR );
    save_btn.set_tooltip_text( _( "Save File As" ) );
    save_btn.clicked.connect( do_save_file );
    header.pack_start( save_btn );

    _undo_btn = new Button.from_icon_name( "edit-undo-symbolic", IconSize.SMALL_TOOLBAR );
    _undo_btn.set_tooltip_text( _( "Undo" ) );
    _undo_btn.set_sensitive( false );
    _undo_btn.clicked.connect( do_undo );
    header.pack_start( _undo_btn );

    _redo_btn = new Button.from_icon_name( "edit-redo-symbolic", IconSize.SMALL_TOOLBAR );
    _redo_btn.set_tooltip_text( _( "Redo" ) );
    _redo_btn.set_sensitive( false );
    _redo_btn.clicked.connect( do_redo );
    header.pack_start( _redo_btn );

    _opts_btn = new MenuButton();
    _opts_btn.set_image( new Image.from_icon_name( "document-properties-symbolic", IconSize.SMALL_TOOLBAR ) );
    _opts_btn.set_tooltip_text( _( "Settings" ) );
    header.pack_end( _opts_btn );

    var export_btn = new MenuButton();
    export_btn.set_image( new Image.from_icon_name( "document-export-symbolic", IconSize.SMALL_TOOLBAR ) );
    export_btn.set_tooltip_text( _( "Export" ) );
    header.pack_end( export_btn );

    var search_btn = new MenuButton();
    search_btn.set_image( new Image.from_icon_name( "edit-find-symbolic", IconSize.SMALL_TOOLBAR ) );
    search_btn.set_tooltip_text( _( "Search" ) );
    header.pack_end( search_btn );

    var zoom_btn = new MenuButton();
    zoom_btn.set_image( new Image.from_icon_name( "zoom-fit-best-symbolic", IconSize.SMALL_TOOLBAR ) );
    zoom_btn.set_tooltip_text( _( "Zoom" ) );
    header.pack_end( zoom_btn );

    /* Create and pack the canvas */
    _canvas = new DrawArea();
    _canvas.node_changed.connect( on_node_changed );

    /* Create the inspector sidebar */
    Box ibox = new Box( Orientation.VERTICAL, 0 );

    StackSwitcher sb    = new StackSwitcher();
    Stack         stack = new Stack();
    stack.set_transition_type( StackTransitionType.SLIDE_LEFT_RIGHT );
    stack.set_transition_duration( 500 );
    stack.add_titled( new NodeInspector( _canvas ),   "node", "Node" );
    stack.add_titled( new ThemeInspector( _canvas ),  "theme", "Theme" );
    stack.add_titled( new LayoutInspector( _canvas ), "layout", "Layout" );

    sb.set_stack( stack );

    ibox.margin = 5;
    ibox.pack_start( sb,    false, true,  0 );
    ibox.pack_start( stack, false, false, 0 );
    ibox.show_all();

    _inspector = new Popover( null );
    _inspector.add( ibox );

    /* Create zoom menu popover */
    Box zbox = new Box( Orientation.VERTICAL, 5 );

    var zoom_scale_lbl = new Label( _( "Zoom to Percent" ) );

    _zoom_scale = new Scale.with_range( Orientation.HORIZONTAL, 10, 400, 25 );
    double[] marks = {10, 25, 50, 75, 100, 150, 200, 300, 400};
    foreach (double mark in marks) {
      _zoom_scale.add_mark( mark, PositionType.BOTTOM, "'" );
    }
    _zoom_scale.has_origin = false;
    _zoom_scale.set_value( 100 );
    _zoom_scale.value_changed.connect( set_zoom_scale );
    _zoom_scale.format_value.connect( set_zoom_value );

    var zoom_fit = new ModelButton();
    zoom_fit.text = _( "Zoom to Fit" );
    zoom_fit.action_name = "win.action_zoom_fit";

    _zoom_sel = new ModelButton();
    _zoom_sel.text = _( "Zoom to Fit Selected Node" );
    _zoom_sel.action_name = "win.action_zoom_selected";
    _zoom_sel.set_sensitive( false );

    var zoom_actual = new ModelButton();
    zoom_actual.text = _( "Zoom to Actual Size" );
    zoom_actual.action_name = "win.action_zoom_actual";

    zbox.margin = 5;
    zbox.pack_start( zoom_scale_lbl, false, true );
    zbox.pack_start( _zoom_scale,    false, true );
    zbox.pack_start( new Separator( Orientation.HORIZONTAL ), false, true );
    zbox.pack_start( zoom_fit,       false, true );
    zbox.pack_start( _zoom_sel,      false, true );
    zbox.pack_start( zoom_actual,    false, true );
    zbox.show_all();

    _zoom = new Popover( null );
    _zoom.add( zbox );
    zoom_btn.popover = _zoom;

    /* Create search popover */
    var sbox = new Box( Orientation.VERTICAL, 5 );

    /* Create the search entry field */
    _search_entry = new SearchEntry();
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

    sbox.pack_start( _search_entry,  false, true );
    sbox.pack_start( _search_scroll, true,  true );
    sbox.show_all();

    _search = new Popover( null );
    _search.add( sbox );
    search_btn.popover = _search;

    /* Create export menu */
    var ebox = new Box( Orientation.VERTICAL, 5 );

    var export_opml = new ModelButton();
    export_opml.text = _( "Export To OPML" );
    export_opml.action_name = "win.action_export_opml";

    var export_pdf = new ModelButton();
    export_pdf.text = _( "Export to PDF" );
    export_pdf.action_name = "win.action_export_pdf";

    var export_print = new ModelButton();
    export_print.text = _( "Print" );
    export_print.action_name = "win.action_export_print";

    ebox.pack_start( export_opml,  false, true );
    ebox.pack_start( export_pdf,   false, true );
    ebox.pack_start( export_print, false, true );
    ebox.show_all();

    _export = new Popover( null );
    _export.add( ebox );
    export_btn.popover = _export;

    /* Create the document */
    _doc = new Document();

    /* Initialize the canvas */
    _canvas.map_event.connect( on_canvas_mapped );
    _canvas.undo_buffer.buffer_changed.connect( do_buffer_changed );

    /* Display the UI */
    add( _canvas );
    show_all();

  }

  /*
   Allow the user to create a new Minder file.  Checks to see if the current
   document needs to be saved and saves it (if necessary).
  */
  public void do_new_file() {
    if( _canvas.changed ) {
      _doc.save( null, _canvas );
    }
    _doc = new Document();
    _canvas.initialize();
    add( _canvas );
  }

  /* Allow the user to open a Minder file */
  public void do_open_file() {
    if( _canvas.changed ) {
      _doc.save( null, _canvas );
    }
    FileChooserDialog dialog = new FileChooserDialog( _( "Open File" ), this, FileChooserAction.OPEN,
      _( "Cancel" ), ResponseType.CANCEL, _( "Open" ), ResponseType.ACCEPT );
    FileFilter        filter = new FileFilter();
    filter.set_filter_name( _( "Minder" ) );
    filter.add_pattern( "*.minder" );
    dialog.add_filter( filter );
    if( dialog.run() == ResponseType.ACCEPT ) {
      _doc.load( dialog.get_filename(), _canvas );
    }
    dialog.close();
  }

  /* Perform an undo action */
  public void do_undo() {
    _canvas.undo_buffer.undo();
  }

  /* Perform a redo action */
  public void do_redo() {
    _canvas.undo_buffer.redo();
  }

  /* Called when the canvas is displayed */
  private bool on_canvas_mapped( Gdk.EventAny e ) {
    _canvas.initialize();
    return( false );
  }

  /*
   Called whenever the undo buffer changes state.  Updates the state of
   the undo and redo buffer buttons.
  */
  public void do_buffer_changed() {
    _undo_btn.set_sensitive( _canvas.undo_buffer.undoable() );
    _redo_btn.set_sensitive( _canvas.undo_buffer.redoable() );
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
      _doc.save( fname, _canvas );
    }
    dialog.close();
  }

  private void on_node_changed() {
    if( _canvas.get_current_node() != null ) {
      _opts_btn.popover = _inspector;
      _zoom_sel.set_sensitive( true );
    } else {
      _opts_btn.popover = null;
      _zoom_sel.set_sensitive( false );
    }
  }

  /* Converts the given value from the scale to the zoom value to use */
  private double zoom_to_value( double value ) {
    if( value < 17.50 )     { return( 10 ); }
    else if( value < 37.5 ) { return( 25 ); }
    else if( value < 62.5 ) { return( 50 ); }
    else if( value < 87.5 ) { return( 75 ); }
    else if( value < 125 )  { return( 100 ); }
    else if( value < 175 )  { return( 150 ); }
    else if( value < 250 )  { return( 200 ); }
    else if( value < 350 )  { return( 300 ); }
    return( 400 );
  }

  /* Sets the scale factor for the level of zoom to perform */
  private void set_zoom_scale() {
    double value = zoom_to_value( _zoom_scale.get_value() );
    double scale_factor = 100 / value;
    _zoom_scale.set_value( value );
    _canvas.set_scaling_factor( scale_factor );
  }

  /* Returns the value to display in the zoom control */
  private string set_zoom_value( double val ) {
    return( zoom_to_value( val ).to_string() );
  }

  /* Zooms to make all nodes visible within the viewer */
  private void action_zoom_fit() {
    double scale_factor = _canvas.get_scaling_factor_to_fit();
    if( scale_factor > 0 ) {
      _zoom_scale.set_value( 100 / scale_factor );
    }
  }

  /* Zooms to make the currently selected node and its tree put into view */
  private void action_zoom_selected() {
    double scale_factor = _canvas.get_scaling_factor_selected();
    if( scale_factor > 0 ) {
      _zoom_scale.set_value( 100 / scale_factor );
    }
  }

  /* Sets the zoom to 100% */
  private void action_zoom_actual() {
    _zoom_scale.set_value( 100 );
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
    // TBD
  }

  /* Exports the model in PDF format */
  private void action_export_pdf() {
    // TBD
  }

  /* Exports the model to the printer */
  private void action_export_print() {
    // TBD
  }

}

