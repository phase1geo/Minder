using Gtk;

public class Minder : Gtk.Application {

  ApplicationWindow? _appwin    = null;
  Box?               _hbox      = null;
  DrawArea?          _canvas    = null;
  Revealer?          _inspector = null;
  Document?          _doc       = null;
  Button?            _opts_btn  = null;

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
    _appwin.set_default_size( 800, 600 );
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

    _opts_btn = new Button.from_icon_name( "applications-system-symbolic", IconSize.SMALL_TOOLBAR );
    _opts_btn.set_tooltip_text( _( "Preferences" ) );
    _opts_btn.clicked.connect( do_preferences );
    header.pack_end( _opts_btn );

    var xprt_btn = new Button.from_icon_name( "document-export-symbolic", IconSize.SMALL_TOOLBAR );
    xprt_btn.set_tooltip_text( _( "Export" ) );
    header.pack_end( xprt_btn );

    var zoom_btn = new Button.from_icon_name( "zoom-fit-best-symbolic", IconSize.SMALL_TOOLBAR );
    zoom_btn.set_tooltip_text( _( "Zoom" ) );
    zoom_btn.clicked.connect( do_inspector );
    header.pack_end( zoom_btn );

    /* Create hbox to pack the canvas and inspector panel */
    _hbox = new Box( Orientation.HORIZONTAL, 0 );

    /* Create and pack the canvas */
    _canvas = new DrawArea();

    /* Create the inspector sidebar */
    _inspector = new Revealer();
    _inspector.set_transition_type( RevealerTransitionType.SLIDE_LEFT );
    _inspector.set_transition_duration( 500 );

    Box ibox = new Box( Orientation.VERTICAL, 0 );

    StackSwitcher sb    = new StackSwitcher();
    Stack         stack = new Stack();
    stack.set_transition_type( StackTransitionType.SLIDE_LEFT_RIGHT );
    stack.set_transition_duration( 500 );
    stack.add_titled( new NodeInspector( _canvas ),   "node", "Node" );
    stack.add_titled( new ThemeInspector( _canvas ),  "theme", "Theme" );
    stack.add_titled( new LayoutInspector( _canvas ), "layout", "Layout" );

    sb.set_stack( stack );

    ibox.pack_start( sb,    false, false, 0 );
    ibox.pack_start( stack, false, false, 0 );
    _inspector.child = ibox;

    /* Create the document */
    _doc = new Document();

    /* Initialize the canvas */
    _canvas.initialize();

    /* Display the UI */
    _hbox.pack_start( _canvas,    true,  true, 0 );
    _hbox.pack_start( _inspector, false, true, 0 );

    _appwin.add( _hbox );
    _appwin.show_all();
    // _appwin.show();

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

  /* Displays the preference popup */
  public void do_preferences() {
    Popover p = new Popover( _opts_btn );
    // p.popup();
  }

  /* Shows or hides the inspector sidebar */
  public void do_inspector() {
    if( _inspector.child_revealed ) {
      _inspector.reveal_child = false;
    } else {
      _inspector.reveal_child = true;
    }
  }

  /* Main routine which gets everything started */
  public static int main( string[] args ) {
    var app = new Minder();
    return( app.run( args ) );
  }

}

