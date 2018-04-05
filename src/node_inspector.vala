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

public class NodeInspector : Grid {

  private Entry?    _name       = null;
  private Switch?   _task       = null;
  private Switch?   _fold       = null;
  private TextView? _note       = null;
  private DrawArea? _da         = null;
  private Button?   _detach_btn = null;
  private string    _orig_note  = "";

  public NodeInspector( DrawArea da ) {

    _da = da;

    row_spacing = 10;

    create_name( 0 );
    create_task( 1 );
    create_fold( 2 );
    create_note( 3 );
    create_buttons( 4 );

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

  /* Creates the fold UI elements */
  private void create_fold( int row ) {

    Label lbl = new Label( _( "Fold" ) );

    lbl.xalign = (float)0;

    _fold = new Switch();
    _fold.state_set.connect( fold_changed );

    attach( lbl,   0, row, 1, 1 );
    attach( _fold, 1, row, 1, 1 );

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
    _note.focus_in_event.connect( note_focus_in );
    _note.focus_out_event.connect( note_focus_out );

    ScrolledWindow sw = new ScrolledWindow( null, null );
    sw.min_content_width  = 300;
    sw.min_content_height = 300;
    sw.add( _note );

    box.pack_start( lbl, true, false );
    box.pack_start( sw,  true, true );

    attach( box, 0, row, 2, 1 );

  }

  /* Creates the node editing button grid and adds it to the popover */
  private void create_buttons( int row ) {

    var grid = new Grid();
    grid.column_homogeneous = true;
    grid.column_spacing     = 10;

    /* Create the detach button */
    _detach_btn = new Button.from_icon_name( "FOOBAR", IconSize.SMALL_TOOLBAR );
    _detach_btn.set_tooltip_text( _( "Detach Node" ) );
    _detach_btn.clicked.connect( node_detach );

    /* Create the node deletion button */
    var del_btn = new Button.from_icon_name( "edit-delete-symbolic", IconSize.SMALL_TOOLBAR );
    del_btn.set_tooltip_text( _( "Delete Node" ) );
    del_btn.clicked.connect( node_delete );

    /* Add the buttons to the button grid */
    grid.attach( _detach_btn, 0, 0, 1, 1 );
    grid.attach( del_btn,     1, 0, 1, 1 );

    /* Add the button grid to the popover */
    attach( grid, 0, row, 2, 1 );

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
      string orig_name = current.name;
      current.name = _name.text;
      _da.undo_buffer.add_item( new UndoNodeName( _da, current, orig_name ) );
    }
  }

  /* Called whenever the task enable switch is changed within the inspector */
  private bool task_changed( bool state ) {
    Node current = _da.get_current_node();
    if( current != null ) {
      _da.undo_buffer.add_item( new UndoNodeTask( _da, current, state, false ) );
      current.enable_task( state );
      _da.queue_draw();
    }
    return( false );
  }

  /* Called whenever the fold switch is changed within the inspector */
  private bool fold_changed( bool state ) {
    Node current = _da.get_current_node();
    if( current != null ) {
      _da.undo_buffer.add_item( new UndoNodeFold( _da, current, state ) );
      current.folded = state;
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

  /* Saves the original version of the node's note */
  private bool note_focus_in( EventFocus e ) {
    _orig_note = _note.buffer.text;
    return( false );
  }

  private bool note_focus_out( EventFocus e ) {
    Node? current = _da.get_current_node();
    if( current != null ) {
      _da.undo_buffer.add_item( new UndoNodeNote( _da, current, _orig_note ) );
    }
    return( false );
  }

  /* Detaches the current node and makes it a parent node */
  private void node_detach() {
    _da.detach();
    _detach_btn.set_sensitive( false );
  }

  private void node_delete() {
    Node? current = _da.get_current_node();
    if( current != null ) {
      current.delete( _da.get_layout() );
    }
  }

  /* Called whenever the user changes the current node in the canvas */
  private void node_changed() {

    Node? current = _da.get_current_node();

    if( current != null ) {
      _name.set_text( current.name );
      _task.set_active( current.task_enabled() );
      if( current.children().length > 0 ) {
        _fold.set_active( current.folded );
        _fold.set_sensitive( true );
      } else {
        _fold.set_active( false );
        _fold.set_sensitive( false );
      }
      _detach_btn.set_sensitive( current.parent != null );
      _note.buffer.text = current.note;
    } else {
      _name.set_text( "" );
      _task.set_active( false );
      _fold.set_active( false );
      _note.buffer.text = "";
    }

  }

}
