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

  private ScrolledWindow _sw;
  private NoteView       _note;
  private MindMap?       _map       = null;
  private string         _orig_note = "";
  private NodeGroup?     _group     = null;

  public GroupInspector( MainWindow win ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    /* Create the group widgets */
    create_title();
    create_note( win );

    win.canvas_changed.connect( tab_changed );

  }

  /* Called whenever the tab in the main window changes */
  private void tab_changed( MindMap? map ) {
    if( _map != null ) {
      _map.current_changed.disconnect( group_changed );
    }
    _map = map;
    if( map != null ) {
      map.current_changed.connect( group_changed );
    }
  }

  /* Sets the width of this inspector to the given value */
  public void set_width( int width ) {
    _sw.width_request = width;
  }

  //-------------------------------------------------------------
  // Creates the title widget
  private void create_title() {

    var title = new Label( "<big>" + _( "Group" ) + "</big>" ) {
      use_markup = true,
      justify    = Justification.CENTER
    };

    append( title );

  }

  //-------------------------------------------------------------
  // Creates the note widget
  private void create_note( MainWindow win ) {

    Label lbl = new Label( _( "Note" ) ) {
      xalign = (float)0,
    };
    lbl.add_css_class( "titled" );

    _note = new NoteView() {
      vexpand   = true,
      wrap_mode = Gtk.WrapMode.WORD
    };
    _note.add_unicode_completion( win, win.unicoder );
    _note.buffer.text = "";

    var focus = new EventControllerFocus();
    _note.add_controller( focus );
    focus.enter.connect( note_focus_in );
    focus.leave.connect( note_focus_out );

    _note.node_link_added.connect( note_node_link_added );
    _note.node_link_clicked.connect( note_node_link_clicked );
    _note.node_link_hover.connect( note_node_link_hover );

    _sw = new ScrolledWindow() {
      min_content_width  = 300,
      min_content_height = 100,
      child              = _note
    };

    var box = new Box( Orientation.VERTICAL, 10 ) {
      margin_bottom = 5
    };
    box.append( lbl );
    box.append( _sw );

    append( box );

  }

  /* Saves the original version of the node's note so that we can */
  private void note_focus_in() {
    _group     = _map.get_current_group();
    _orig_note = _note.buffer.text;
  }

  /* When the note buffer loses focus, save the note change to the undo buffer */
  private void note_focus_out() {
    if( (_group != null) && (_note.buffer.text != _orig_note) ) {
      _group.note = _note.buffer.text;
      _map.add_undo( new UndoGroupNote( _group, _orig_note ) );
      _map.auto_save();
    }
  }

  /* When a node link is added, tell the current node */
  private int note_node_link_added( NodeLink link, out string text ) {
    return( _map.model.add_note_node_link( link, out text ) );
  }

  /* Handles a click on the node link with the given ID */
  private void note_node_link_clicked( int id ) {
    _map.model.note_node_link_clicked( id );
  }

  /* Handles a hover over a node link */
  private void note_node_link_hover( int id ) {
    var link = _map.model.node_links.get_node_link( id );
    if( link != null ) {
      _note.show_tooltip( link.get_tooltip( _map ) );
    }
  }

  /* Grabs the focus on the note widget */
  public void grab_note() {
    _note.grab_focus();
  }

  /* Called whenever the user changes the current node in the canvas */
  private void group_changed() {

    NodeGroup? current = _map.get_current_group();

    if( current != null ) {
      var note = current.note;
      _note.buffer.text = note;
    }

  }

  /* Sets the input focus on the first widget in this inspector */
  public void grab_first() {
    grab_note();
  }

}
