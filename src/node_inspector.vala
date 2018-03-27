using Gtk;

public class NodeInspector : Grid {

  private Entry?    _name = null;
  private Switch?   _task = null;
  private TextView? _note = null;
  private DrawArea? _da   = null;

  public NodeInspector( DrawArea da ) {

    _da   = da;
    _name = new Entry();
    _task = new Switch();
    _note = new TextView();

    Label          name_lbl = new Label( "Name" );
    Label          task_lbl = new Label( "Enable Task" );
    Label          note_lbl = new Label( "Note" );
    ScrolledWindow sw       = new ScrolledWindow( null, null );

    _note.set_wrap_mode( Gtk.WrapMode.WORD );
    _note.buffer.text = "";

    sw.min_content_width  = 300;
    sw.min_content_height = 300;
    sw.add( _note );

    attach( name_lbl, 0, 0, 1, 1 );
    attach( _name,    0, 1, 4, 1 );
    attach( _task,    0, 2, 1, 1 );
    attach( task_lbl, 1, 2, 1, 1 );
    attach( note_lbl, 0, 3, 1, 1 );
    attach( sw,       0, 4, 4, 1 );

    _name.activate.connect( name_changed );
    _task.activate.connect( task_changed );
    _note.buffer.changed.connect( note_changed );

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
  private void task_changed() {
    stdout.printf( "In task_changed, active: %s\n", _task.get_active().to_string() );
    Node current = _da.get_current_node();
    if( current != null ) {
      current.enable_task( _task.get_active() );
      _da.queue_draw();
    }
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

}
