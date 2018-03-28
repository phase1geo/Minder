using Gtk;

public class Minder : Gtk.Application {

  ApplicationWindow? _appwin    = null;
  DrawArea?          _canvas    = null;
  Document?          _doc       = null;
  Popover?           _inspector = null;
  MenuButton?        _opts_btn  = null;

  public Minder () {
    Object( application_id: "com.github.phase1geo.Minder", flags: ApplicationFlags.FLAGS_NONE );
  }

  protected override void activate() {

    var header = new HeaderBar();
    header.set_title( _( "Minder" ) );
    header.set_subtitle( _( "Mind-Mapping Application" ) );
    header.set_show_close_button( true );

    _appwin = new ApplicationWindow( this );
    _appwin.title = _( "Minder" );
    _appwin.set_position( Gtk.WindowPosition.CENTER );
    _appwin.set_default_size( 1000, 800 );
    _appwin.set_titlebar( header );
    _appwin.set_border_width( 2 );
    _appwin.destroy.connect( Gtk.main_quit );

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

    var zoom_btn = new Button.from_icon_name( "zoom-fit-best-symbolic", IconSize.SMALL_TOOLBAR );
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

    /* Create the document */
    _doc = new Document();

    /* Initialize the canvas */
    _canvas.initialize();

    /* Display the UI */
    _appwin.add( _canvas );
    _appwin.show_all();

    Gtk.main();

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
    _appwin.add( _canvas );
  }

  /* Allow the user to open a Minder file */
  public void do_open_file() {
    FileChooserDialog dialog = new FileChooserDialog( _( "Open File" ), _appwin, FileChooserAction.OPEN,
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
    FileChooserDialog dialog = new FileChooserDialog( _( "Save File" ), _appwin, FileChooserAction.SAVE,
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
    } else {
      _opts_btn.popover = null;
    }
  }

  /* Main routine which gets everything started */
  public static int main( string[] args ) {
    var app = new Minder();
    return( app.run( args ) );
  }

}

