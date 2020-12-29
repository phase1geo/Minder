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
using Granite.Widgets;

public class ConnectionInspector : Box {

  private const Gtk.TargetEntry[] DRAG_TARGETS = {
    {"text/uri-list", 0, 0}
  };

  private ScrolledWindow _sw;
  private ColorButton    _color;
  private Button         _reset;
  private TextView       _note;
  private TextView       _text;
  private DrawArea?      _da         = null;
  private string         _orig_note  = "";
  private Connection?    _connection = null;

  public ConnectionInspector( MainWindow win ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    /* Create the node widgets */
    create_color();
    create_note();
    create_buttons();

    win.canvas_changed.connect( tab_changed );

    show_all();

  }

  /* Called whenever the tab in the main window changes */
  private void tab_changed( DrawArea? da ) {
    if( _da != null ) {
      _da.current_changed.disconnect( connection_changed );
    }
    if( da != null ) {
      da.current_changed.connect( connection_changed );
    }
    _da = da;
  }

  /* Sets the width of this inspector to the given value */
  public void set_width( int width ) {
    _sw.width_request = width;
  }

  private void create_color() {

    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( Utils.make_title( _( "Color" ) ) );

    box.homogeneous = true;
    lbl.xalign      = (float)0;
    lbl.use_markup  = true;

    var bbox = new Box( Orientation.HORIZONTAL, 5 );

    _color = new ColorButton();
    _color.color_set.connect(() => {
      _da.change_current_connection_color( _color.rgba );
    });

    _reset = new Button.from_icon_name( "edit-undo-symbolic", IconSize.SMALL_TOOLBAR );
    _reset.set_tooltip_text( _( "Use Theme Default Color" ) );
    _reset.clicked.connect(() => {
      _da.change_current_connection_color( null );
    });

    bbox.pack_start( _color, true,  true,  0 );
    bbox.pack_start( _reset, false, false, 0 );

    box.pack_start( lbl,  false, true, 0 );
    box.pack_end(   bbox, true,  true, 0 );

    pack_start( box, false, true );

  }

  /* Creates the note widget */
  private void create_note() {

    Box   box = new Box( Orientation.VERTICAL, 10 );
    Label lbl = new Label( Utils.make_title( _( "Note" ) ) );

    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _note = new TextView();
    _note.set_wrap_mode( Gtk.WrapMode.WORD );
    _note.buffer.text = "";
    _note.buffer.changed.connect( note_changed );
    _note.focus_in_event.connect( note_focus_in );
    _note.focus_out_event.connect( note_focus_out );

    _sw = new ScrolledWindow( null, null );
    _sw.min_content_width  = 300;
    _sw.min_content_height = 100;
    _sw.add( _note );

    box.pack_start( lbl, false, false );
    box.pack_start( _sw,  true,  true );

    pack_start( box, true, true );

  }

  /* Creates the node editing button grid and adds it to the popover */
  private void create_buttons() {

    var grid = new Grid();
    grid.column_homogeneous = true;
    grid.column_spacing     = 5;

    /* Create the node deletion button */
    var del_btn = new Button.from_icon_name( "edit-delete-symbolic", IconSize.SMALL_TOOLBAR );
    del_btn.set_tooltip_text( _( "Delete Connection" ) );
    del_btn.clicked.connect( connection_delete );

    /* Add the buttons to the button grid */
    grid.attach( del_btn, 0, 0, 1, 1 );

    /* Add the button grid to the popover */
    pack_start( grid, false, true );

  }

  /*
   Called whenever the text widget is changed.  Updates the current node
   and redraws the canvas when needed.
  */
  private void note_changed() {
    _da.change_current_connection_note( _note.buffer.text );
  }

  /* Saves the original version of the node's note so that we can */
  private bool note_focus_in( EventFocus e ) {
    _connection = _da.get_current_connection();
    _orig_note  = _note.buffer.text;
    return( false );
  }

  /* When the note buffer loses focus, save the note change to the undo buffer */
  private bool note_focus_out( EventFocus e ) {
    if( (_connection != null) && (_connection.note != _orig_note) ) {
      _da.undo_buffer.add_item( new UndoConnectionNote( _connection, _orig_note ) );
    }
    return( false );
  }

  /* Deletes the current connection */
  private void connection_delete() {
    _da.delete_connection();
  }

  /* Grabs the focus on the note widget */
  public void grab(PropertyGrab prop_grab) {
    switch (prop_grab) {
      case PropertyGrab.NOTE:
        _note.grab_focus();
      break;
      case PropertyGrab.TEXT:
        _text.grab_focus();
      break;
      default:
      break;
    }
  }

  /* Called whenever the user changes the current node in the canvas */
  private void connection_changed() {

    Connection? current = _da.get_current_connection();

    if( current != null ) {
      _color.rgba          = (current.color != null) ? current.color : _da.get_theme().get_color( "connection_background" );
      _color.alpha         = 65535;
      _note.buffer.text    = current.note;
      _reset.set_sensitive( current.color != null );
    }

  }

  /* Sets the input focus on the first widget in this inspector */
  public void grab_first() {
    _color.grab_focus();
  }

}
