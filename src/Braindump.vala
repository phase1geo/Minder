/*
* Copyright (c) 2024-2025 (https://github.com/phase1geo/Minder)
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

public enum BraindumpChangeType {
  ADD,
  REMOVE,
  CLEAR
}

public class Idea : Object{
  public string text { get; set; default = ""; }
  public Idea( string text ) {
    this.text = text;
  }
}

public class Braindump : Box {

  private MainWindow _win;
  private Entry      _entry;
  private ListBox    _ideas;
  private int        _current_index;

  public signal void ideas_changed( BraindumpChangeType change, string name_index );

  //-------------------------------------------------------------
  // Constructor
  public Braindump( MainWindow win ) {

    Object( orientation:Orientation.VERTICAL, spacing:5 );

    _win = win;

    _entry = new Entry() {
      halign           = Align.FILL,
      placeholder_text = _( "Enter Idea" ),
      width_chars      = 30,
      margin_top       = 5,
      margin_start     = 5,
      margin_end       = 5
    };

    _entry.activate.connect(() => {
      add_idea( _entry.text );
      ideas_changed( BraindumpChangeType.ADD, _entry.text );
      _entry.text = "";
    });

    _ideas = new ListBox() {
      halign          = Align.FILL,
      selection_mode  = SelectionMode.SINGLE,
      show_separators = true
    };

    var key = new EventControllerKey();
    key.key_pressed.connect((keyval, keycode, state) => {
      var current = _ideas.get_selected_row();
      if( current != null ) {
        if( keyval == Gdk.Key.Delete ) {
          var index = current.get_index();
          _ideas.remove( current );
          ideas_changed( BraindumpChangeType.REMOVE, index.to_string() );
          return( true );
        }
      }
      return( false );
    });

    _ideas.add_controller( key );

    var sw = new ScrolledWindow() {
      vscrollbar_policy = PolicyType.AUTOMATIC,
      hscrollbar_policy = PolicyType.NEVER,
      halign            = Align.FILL,
      valign            = Align.FILL,
      margin_start      = 5,
      margin_end        = 5,
      vexpand           = true,
      child             = _ideas
    };

    var remove_btn = new Button.with_label( _( "Clear Idea List" ) ) {
      halign = Align.CENTER,
      hexpand = true
    };

    remove_btn.clicked.connect(() => {
      _ideas.remove_all();
      ideas_changed( BraindumpChangeType.CLEAR, "" );
    });

    ideas_changed.connect((change, idea) => {
      remove_btn.sensitive = (_ideas.get_row_at_index( 0 ) != null);
    });

    var bbar = new Box( Orientation.HORIZONTAL, 5 ) {
      margin_bottom = 5,
      margin_start  = 5,
      margin_end    = 5
    };
    bbar.append( remove_btn );

    append( _entry );
    append( sw );
    append( bbar );

  }

  //-------------------------------------------------------------
  // Adds a new item to the ideas listbox.
  private void add_idea( string text ) {

    var label = new Label( text ) {
      wrap          = true,
      wrap_mode     = Pango.WrapMode.WORD,
      halign        = Align.START,
      hexpand       = true,
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 10,
      margin_bottom = 10
    };

    _ideas.append( label );

    var drag = new DragSource() {
      actions = DragAction.MOVE
    };

    label.add_controller( drag );

    drag.set_icon( create_icon( label, text ), 10, 10 );

    drag.prepare.connect((x, y) => {
      var val = new Value( typeof(Idea) );
      val.set_object( new Idea( text ) );
      var provider = new ContentProvider.for_value( val );
      return( provider );
    });

    drag.drag_begin.connect((d) => {
      var row = (ListBoxRow)label.get_parent();
      _current_index = row.get_index();
      _ideas.remove( row );
    });

    drag.drag_cancel.connect((d) => {
      return( false );
    });

    drag.drag_end.connect((d, del) => {
      ideas_changed( BraindumpChangeType.REMOVE, _current_index.to_string() );
    });

  }

  //-------------------------------------------------------------
  // Creates the icon that will be displayed when dragging and dropping
  // the given text from the brainstorm list.
  private Paintable create_icon( Label label, string text ) {
    
    Pango.Rectangle log, ink;

    var theme = _win.get_current_map().model.get_theme();

    var layout = label.create_pango_layout( text );
    layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    layout.set_width( 200 * Pango.SCALE );
    layout.get_extents( out ink, out log );

    var padding = 10;
    var alpha   = 0.5;
    var width   = (log.width  / Pango.SCALE) + (padding * 2);
    var height  = (log.height / Pango.SCALE) + (padding * 2);

    var rect = Graphene.Rect.alloc();
    rect.init( (float)0.0, (float)0.0, (float)width, (float)height );

    var snapshot = new Gtk.Snapshot();
    var context  = snapshot.append_cairo( rect );

    Utils.set_context_color_with_alpha( context, theme.get_color( "root_background" ), alpha );
    context.rectangle( 0, 0, width, height );
    context.fill();

    Utils.set_context_color_with_alpha( context, theme.get_color( "root_foreground" ), alpha );
    context.move_to( (padding - (log.x / Pango.SCALE)), padding );
    Pango.cairo_show_layout( context, layout );
    context.new_path();

    return( snapshot.free_to_paintable( null ) );

  }

  //-------------------------------------------------------------
  // Make sure that the entry field receives the focus if the box
  // is given focus.
  public override bool grab_focus() {

    return( _entry.grab_focus() );

  }

  //-------------------------------------------------------------
  // Sets the current brainstorm list to the given array of strings.
  public void set_list( Array<string> list ) {
    _ideas.remove_all();
    for( int i=0; i<list.length; i++ ) {
      add_idea( list.index( i ) );
    }
  }

}
