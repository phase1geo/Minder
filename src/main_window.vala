using Gtk;

public class MainWindow : ApplicationWindow {

  private DrawArea?    _canvas     = null;
  private Document?    _doc        = null;
  private Popover?     _inspector  = null;
  private Popover?     _zoom       = null;
  private MenuButton?  _opts_btn   = null;
  private Scale?       _zoom_scale = null;
  private ModelButton? _zoom_sel   = null;

  private const GLib.ActionEntry[] action_entries = {
    { "action_zoom_fit",      action_zoom_fit },
    { "action_zoom_selected", action_zoom_selected },
    { "action_zoom_actual",   action_zoom_actual }
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

    _opts_btn = new MenuButton();
    _opts_btn.set_image( new Image.from_icon_name( "document-properties-symbolic", IconSize.SMALL_TOOLBAR ) );
    _opts_btn.set_tooltip_text( _( "Settings" ) );
    header.pack_end( _opts_btn );

    var xprt_btn = new Button.from_icon_name( "document-export-symbolic", IconSize.SMALL_TOOLBAR );
    xprt_btn.set_tooltip_text( _( "Export" ) );
    header.pack_end( xprt_btn );

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

    Box zbox = new Box( Orientation.VERTICAL, 5 );

    var zoom_scale_lbl = new Label( _( "Zoom to Percent" ) );

    _zoom_scale = new Scale.with_range( Orientation.HORIZONTAL, 25, 400, 25 );
    double[] marks = {25, 50, 100, 200, 400};
    foreach (double mark in marks) {
      _zoom_scale.add_mark( mark, PositionType.BOTTOM, "|" );
    }
    _zoom_scale.has_origin = false;
    _zoom_scale.set_value( 100 );
    _zoom_scale.value_changed.connect( set_zoom_scale );

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

    /* Create the document */
    _doc = new Document();

    /* Initialize the canvas */
    _canvas.initialize();

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
    _doc    = new Document();
    _canvas = new DrawArea();
    _canvas.initialize();
    add( _canvas );
  }

  /* Allow the user to open a Minder file */
  public void do_open_file() {
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

  /* Sets the scale factor for the level of zoom to perform */
  private void set_zoom_scale() {
    double scale_factor = 100 / _zoom_scale.get_value();
    _canvas.set_scaling_factor( scale_factor );
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

}

