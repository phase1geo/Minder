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

  private ScrolledWindow _sw;
  private ColorButton    _color;
  private Button         _reset;
  private NoteView       _note;
  private DrawArea?      _da         = null;
  private string         _orig_note  = "";
  private Connection?    _connection = null;

  //-------------------------------------------------------------
  // Default constructor
  public ConnectionInspector( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 10 );

    /* Create the node widgets */
    create_title();
    create_color();
    create_note( win );
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

  //-------------------------------------------------------------
  // Creates the title label
  private void create_title() {

    var title = new Label( "<big>" + _( "Connection" ) + "</big>" ) {
      use_markup = true,
      justify    = Justification.CENTER
    };

    append( title );

  }

  //-------------------------------------------------------------
  // Creates the connection color widget
  private void create_color() {

    var lbl = new Label( Utils.make_title( _( "Color" ) ) ) {
      halign     = Align.START,
      xalign     = (float)0,
      use_markup = true
    };

    _color = new ColorButton() {
      hexpand = true
    };
    _color.color_set.connect(() => {
      _da.change_current_connection_color( _color.rgba );
    });

    _reset = new Button.from_icon_name( "edit-undo-symbolic" ) {
      tooltip_text = _( "Use Theme Default Color" )
    };
    _reset.clicked.connect(() => {
      _da.change_current_connection_color( null );
    });

    var bbox = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.END
    };
    bbox.append( _color );
    bbox.append( _reset );

    var box = new Box( Orientation.HORIZONTAL, 0 ) {
      homogeneous = true
    };
    box.append( lbl );
    box.append( bbox );

    append( box );

  }

  //-------------------------------------------------------------
  // Creates the note widget
  private void create_note( MainWindow win ) {

    var lbl = new Label( Utils.make_title( _( "Note" ) ) ) {
      valign = Align.START,
      xalign = (float)0,
      use_markup = true
    };

    _note = new NoteView() {
      wrap_mode = Gtk.WrapMode.WORD
    };

    _note.add_unicode_completion( win, win.unicoder );
    _note.buffer.text = "";
    _note.buffer.changed.connect( note_changed );

    var focus = new EventControllerFocus();
    _note.add_controller( focus );
    focus.enter.connect( note_focus_in );
    focus.leave.connect( note_focus_out );

    _note.node_link_added.connect( note_node_link_added );
    _note.node_link_clicked.connect( note_node_link_clicked );
    _note.node_link_hover.connect( note_node_link_hover );

    _sw = new ScrolledWindow() {
      halign             = Align.FILL,
      valign             = Align.FILL,
      min_content_width  = 300,
      min_content_height = 100,
      child              = _note
    };

    var box = new Box( Orientation.VERTICAL, 10 ) {
      halign        = Align.FILL,
      valign        = Align.FILL,
      margin_bottom = 20
    };
    box.append( lbl );
    box.append( _sw );

    append( box );

  }

  //-------------------------------------------------------------
  // Creates the node editing button grid and adds it to the popover
  private void create_buttons() {

    var grid = new Grid() {
      column_homogeneous = true,
      column_spacing     = 5
    };

    /* Create the node deletion button */
    var del_btn = new Button.from_icon_name( "edit-delete-symbolic" ) {
      tooltip_text = _( "Delete Connection" )
    };
    del_btn.clicked.connect( connection_delete );

    /* Add the buttons to the button grid */
    grid.attach( del_btn, 0, 0 );

    /* Add the button grid to the popover */
    // pack_start( grid, false, true );

  }

  /*
   Called whenever the text widget is changed.  Updates the current node
   and redraws the canvas when needed.
  */
  private void note_changed() {
    _da.change_current_connection_note( _note.buffer.text );
  }

  /* Saves the original version of the node's note so that we can */
  private void note_focus_in() {
    _connection = _da.get_current_connection();
    _orig_note  = _note.buffer.text;
  }

  /* When the note buffer loses focus, save the note change to the undo buffer */
  private void note_focus_out() {
    if( (_connection != null) && (_connection.note != _orig_note) ) {
      _da.undo_buffer.add_item( new UndoConnectionNote( _connection, _orig_note ) );
    }
  }

  /* When a node link is added, tell the current node */
  private int note_node_link_added( NodeLink link, out string text ) {
    return( _da.add_note_node_link( link, out text ) );
  }

  /* Handles a click on the node link with the given ID */
  private void note_node_link_clicked( int id ) {
    _da.note_node_link_clicked( id );
  }

  /* Handles a hover over a node link */
  private void note_node_link_hover( int id ) {
    var link = _da.node_links.get_node_link( id );
    if( link != null ) {
      _note.show_tooltip( link.get_tooltip( _da ) );
    }
  }

  /* Deletes the current connection */
  private void connection_delete() {
    _da.delete_connection();
  }

  /* Grabs the focus on the note widget */
  public void grab_note() {
    _note.grab_focus();
  }

  /* Called whenever the user changes the current node in the canvas */
  private void connection_changed() {

    Connection? current = _da.get_current_connection();

    if( current != null ) {
      var note = current.note;
      _color.rgba          = (current.color != null) ? current.color : _da.get_theme().get_color( "connection_background" );
      _color.alpha         = 65535;
      _note.buffer.text    = note;
      _reset.set_sensitive( current.color != null );
    }

  }

  /* Sets the input focus on the first widget in this inspector */
  public void grab_first() {
    _color.grab_focus();
  }

}
