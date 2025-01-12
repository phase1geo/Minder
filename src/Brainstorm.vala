/*
* Copyright (c) 2024 (https://github.com/phase1geo/Minder)
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

public class Brainstorm : Box {

  private MainWindow _win;
  private Entry      _entry;
  private ListBox    _ideas;

  //-------------------------------------------------------------
  // Constructor
  public Brainstorm( MainWindow win ) {

    Object( orientation:Orientation.VERTICAL, spacing:5 );

    _win = win;

    _entry = new Entry() {
      placeholder_text = _( "Enter Idea" ),
      margin_top       = 5,
      margin_start     = 5,
      margin_end       = 5
    };

    _entry.activate.connect(() => {
      add_idea( _entry.text );
      _entry.text = "";
    });

    _ideas = new ListBox() {
      selection_mode  = SelectionMode.NONE,
      show_separators = true
    };

    var sw = new ScrolledWindow() {
      vscrollbar_policy = PolicyType.AUTOMATIC,
      hscrollbar_policy = PolicyType.NEVER,
      margin_bottom = 5,
      margin_start  = 5,
      margin_end    = 5,
      valign  = Align.FILL,
      vexpand = true,
      child   = _ideas
    };

    append( _entry );
    append( sw );

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

    drag.set_icon( create_icon( label, text ), 10, 10 );

    label.add_controller( drag );

    drag.prepare.connect((x, y) => {
      var val = new Value( typeof(string) );
      val.set_string( text );
      var provider = new ContentProvider.for_value( val );
      return( provider );
    });

    drag.drag_end.connect((d, del) => {
      if( del ) {
        _ideas.remove( label.get_parent() ); 
      }
    });

  }

  //-------------------------------------------------------------
  // Creates the icon that will be displayed when dragging and dropping
  // the given text from the brainstorm list.
  private Paintable create_icon( Label label, string text ) {
    
    Pango.Rectangle log, ink;

    var theme = _win.get_current_da().get_theme();

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

}
