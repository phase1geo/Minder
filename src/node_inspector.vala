using Gtk;

public class NodeInspector : Grid {

  private Entry?    _name = null;
  private Switch?   _task = null;
  private TextView? _note = null;
  private DrawArea? _da   = null;

  public NodeInspector( DrawArea da ) {

    _da = da;

    row_spacing = 10;

    create_name( 0 );
    create_task( 1 );
    create_note( 2 );

    _da.node_changed.connect( node_changed );

    show_all();

  }

  /* Creates the name entry */
  private void create_name( int row ) {

    Box   box = new Box( Orientation.VERTICAL, 2 );
    Label lbl = new Label( _( "Name" ) );

    _name = new Entry();
    _name.activate.connect( name_changed );

    lbl.xalign = (float)0;

    box.pack_start( lbl,   true, false );
    box.pack_start( _name, true, false );

    attach( box, 0, row, 2, 1 );

  }

  /* Creates the task UI elements */
  private void create_task( int row ) {

    Label lbl = new Label( _( "Task" ) );

    lbl.xalign = (float)0;

    _task = new Switch();
    _task.state_set.connect( task_changed );

    attach( lbl,   0, row, 1, 1 );
    attach( _task, 1, row, 1, 1 );

  }

  /* Creates the note widget */
  private void create_note( int row ) {

    Box   box = new Box( Orientation.VERTICAL, 0 );
    Label lbl = new Label( _( "Note" ) );

    lbl.xalign = (float)0;

    _note = new TextView();
    _note.set_wrap_mode( Gtk.WrapMode.WORD );
    _note.buffer.text = "";
    _note.buffer.changed.connect( note_changed );

    ScrolledWindow sw = new ScrolledWindow( null, null );
    sw.min_content_width  = 300;
    sw.min_content_height = 300;
    sw.add( _note );

    box.pack_start( lbl, true, false );
    box.pack_start( sw,  true, true );

    attach( box, 0, row, 2, 1 );

  }

  /*
   Called whenever the node name is changed within the inspector.
  */
  private void name_changed() {
    Node current = _da.get_current_node();
    if( current != null ) {
      if( current.name != _name.text ) {
        _da.queue_draw();
      }
      current.name = _name.text;
    }
  }

  /* Called whenever the task enable switch is changed within the inspector */
  private bool task_changed( bool state ) {
    Node current = _da.get_current_node();
    if( current != null ) {
      current.enable_task( state );
      _da.queue_draw();
    }
    return( false );
  }

  /*
   Called whenever the text widget is changed.  Updates the current node
   and redraws the canvas when needed.
  */
  private void note_changed() {
    Node current = _da.get_current_node();
    if( current != null ) {
      if( (_note.buffer.text.length == 0) != (current.note.length == 0) ) {
        _da.queue_draw();
      }
      current.note = _note.buffer.text;
    }
  }

  /* Called whenever the user changes the current node in the canvas */
  private void node_changed() {

    Node? current = _da.get_current_node();

    if( current != null ) {
      _name.set_text( current.name );
      _task.set_active( current.task_enabled() );
      _note.buffer.text = current.note;
    } else {
      _name.set_text( "" );
      _task.set_active( false );
      _note.buffer.text = "";
    }

  }

}
