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

public class GroupInspector : Box {

  private const Gtk.TargetEntry[] DRAG_TARGETS = {
    {"text/uri-list", 0, 0}
  };

  private ScrolledWindow _sw;
  private NoteView       _note;
  private DrawArea?      _da        = null;
  private string         _orig_note = "";
  private NodeGroup?     _group     = null;

  public GroupInspector( MainWindow win ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    /* Create the group widgets */
    create_title();
    create_note();

    win.canvas_changed.connect( tab_changed );

    show_all();

  }

  /* Called whenever the tab in the main window changes */
  private void tab_changed( DrawArea? da ) {
    if( _da != null ) {
      _da.current_changed.disconnect( group_changed );
    }
    if( da != null ) {
      da.current_changed.connect( group_changed );
    }
    _da = da;
  }

  /* Sets the width of this inspector to the given value */
  public void set_width( int width ) {
    _sw.width_request = width;
  }

  private void create_title() {

    var title = new Label( "<big>" + _( "Group" ) + "</big>" );
    title.use_markup = true;
    title.justify    = Justification.CENTER;

    pack_start( title, false, true );

  }

  /* Creates the note widget */
  private void create_note() {

    Box   box = new Box( Orientation.VERTICAL, 10 );
    Label lbl = new Label( Utils.make_title( _( "Note" ) ) );

    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _note = new NoteView();
    _note.set_wrap_mode( Gtk.WrapMode.WORD );
    _note.buffer.text = "";
    _note.focus_in_event.connect( note_focus_in );
    _note.focus_out_event.connect( note_focus_out );

    _sw = new ScrolledWindow( null, null );
    _sw.min_content_width  = 300;
    _sw.min_content_height = 100;
    _sw.add( _note );

    box.pack_start( lbl, false, false );
    box.pack_start( _sw,  true,  true );

    box.margin_bottom = 20;

    pack_start( box, true, true );

  }

  /* Saves the original version of the node's note so that we can */
  private bool note_focus_in( EventFocus e ) {
    _group     = _da.get_current_group();
    _orig_note = _note.buffer.text;
    return( false );
  }

  /* When the note buffer loses focus, save the note change to the undo buffer */
  private bool note_focus_out( EventFocus e ) {
    if( (_group != null) && (_note.buffer.text != _orig_note) ) {
      _group.note = _note.buffer.text;
      _da.undo_buffer.add_item( new UndoGroupNote( _group, _orig_note ) );
      _da.auto_save();
    }
    return( false );
  }

  /* Grabs the focus on the note widget */
  public void grab_note() {
    _note.grab_focus();
  }

  /* Called whenever the user changes the current node in the canvas */
  private void group_changed() {

    NodeGroup? current = _da.get_current_group();

    if( current != null ) {
      _note.buffer.text = current.note;
    }

  }

  /* Sets the input focus on the first widget in this inspector */
  public void grab_first() {
    grab_note();
  }

}
