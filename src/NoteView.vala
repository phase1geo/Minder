/*
* Copyright (c) 2017 Lains
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
*/

using Gtk;
using Gdk;

/*
 This class is a slightly modified version of Lains Quilter SourceView.vala
 file.  The above header was kept in tact to indicate this.
*/
public class NoteView : Gtk.SourceView {

  public  SourceStyle  _srcstyle = null;
  public  SourceBuffer _buffer;

  public string text {
    set {
      buffer.text = value;
    }
    owned get {
      return( buffer.text );
    }
  }

  public bool modified {
    set {
      buffer.set_modified( value );
    }
    get {
      return( buffer.get_modified() );
    }
  }

  public NoteView() {

    var manager       = Gtk.SourceLanguageManager.get_default();
    var language      = manager.guess_language( null, "text/markdown" );
    var style_manager = Gtk.SourceStyleSchemeManager.get_default();
    var style         = style_manager.get_scheme( get_default_scheme() );

    _buffer = new Gtk.SourceBuffer.with_language( language );
    _buffer.highlight_syntax = true;
    _buffer.set_max_undo_levels( 20 );
    _buffer.set_style_scheme( style );
    set_buffer( _buffer );

    modified = false;

    _buffer.changed.connect (() => {
      modified = true;
    });
    this.motion_notify_event.connect( on_motion );

    expand      = true;
    has_focus   = true;
    auto_indent = true;
    set_wrap_mode( Gtk.WrapMode.WORD );
    set_tab_width( 4 );
    set_insert_spaces_instead_of_tabs( true );

  }

  private string get_default_scheme () {
    return( "minder" );
  }

  /*
   If the cursor is moved in the text viewer when the control key is held down,
   check to see if the cursor is over a URL.
  */
  private bool on_motion( EventMotion e ) {
    if( (bool)(e.state & ModifierType.CONTROL_MASK) ) {
      TextIter it;
      get_iter_at_location( out it, (int)e.x, (int)e.y );

      stdout.printf( "it, offset: %d\n", start.get_offset() );
      var end = start;
      if( _buffer.iter_backward_to_context_class_toggle( start, "no-spell-check" ) ) {
        stdout.printf( "  start, offset: %d\n", start.get_offset() );
        if( _buffer.iter_forward_to_context_class_toggle( end, "no-spell-check" ) ) {
          stdout.printf( "  end, offset: %d\n", end.get_offset() );
          var str = _buffer.get_text( start, end, true );
          stdout.printf( "str: %s\n", str );
        }
      }
    }
    return( false );
  }

}
