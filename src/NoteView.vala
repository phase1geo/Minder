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

  private int          _last_lnum = -1;
  private string?      _last_url  = null;
  private Regex?       _url_re;
  public  SourceStyle  _srcstyle  = null;
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

    try {
      _url_re = new Regex( Utils.get_url_pattern() );
    } catch( RegexError e ) {
      _url_re = null;
    }

  }

  private string get_default_scheme () {
    return( "minder" );
  }

  /* Returns the string of text for the current line */
  private string current_line( TextIter cursor ) {
    var start = cursor;
    var end   = cursor;
    start.set_line( start.get_line() );
    end.forward_line();
    return( start.get_text( end ).chomp() );
  }

  /* Returns true if the specified cursor is within a parsed URL pattern */
  private bool cursor_in_url( TextIter cursor, string line, out string url ) {
    if( _url_re == null ) return( false );
    MatchInfo match_info;
    var       start  = 0;
    var       offset = cursor.get_line_offset();
    try {
      while( _url_re.match_all_full( line, -1, start, 0, out match_info ) ) {
        int s, e;
        match_info.fetch_pos( 0, out s, out e );
        if( (s <= offset) && (offset < e) ) {
          url = line.substring( s, (e - s) );
          return( true );
        }
        start = e;
      }
    } catch( RegexError e ) {}
    return( false );
  }

  /*
   If the cursor is moved in the text viewer when the control key is held down,
   check to see if the cursor is over a URL.
  */
  private bool on_motion( EventMotion e ) {
    if( (bool)(e.state & ModifierType.CONTROL_MASK) ) {
      TextIter cursor;
      get_iter_at_location( out cursor, (int)e.x, (int)e.y );
      if( _last_lnum != cursor.get_line() ) {
        string matched_url;
        _last_lnum = cursor.get_line();
        if( cursor_in_url( cursor, current_line( cursor ), out matched_url ) ) {
          _last_url = matched_url;
          stdout.printf( "Found matched_url: %s\n", matched_url );
        } else {
          _last_url = null;
        }
      }
    }
    return( false );
  }

}
