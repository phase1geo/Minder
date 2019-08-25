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

public class QuickEntry : Gtk.Window {

  private TextView _entry;

  public QuickEntry( DrawArea da ) {

    /* Configure the window */
    default_width   = 500;
    default_height  = 500;
    modal           = true;
    deletable       = false;
    title           = _( "Quick Entry" );
    transient_for   = da.win;
    window_position = WindowPosition.CENTER_ON_PARENT;

    /* Add window elements */
    var box = new Box( Orientation.VERTICAL, 0 );

    /* Create the text entry area */
    _entry = new TextView();
    _entry.border_width = 5;
    _entry.set_wrap_mode( Gtk.WrapMode.WORD );
    _entry.key_press_event.connect( on_keypress );

    /* Create the scrolled window for the text entry area */
    var sw = new ScrolledWindow( null, null );
    sw.add( _entry );

    var bbox = new Box( Orientation.HORIZONTAL, 5 );
    bbox.border_width = 5;

    var cancel = new Button.with_label( _( "Cancel" ) );
    cancel.clicked.connect(() => {
      close();
    });

    var ins = new Button.with_label( _( "Insert" ) );
    ins.get_style_context().add_class( STYLE_CLASS_SUGGESTED_ACTION );
    ins.clicked.connect(() => {
      ExportText.import_text( _entry.buffer.text, 8, da, false );
      close();
    });

    bbox.pack_end( ins,    false, false );
    bbox.pack_end( cancel, false, false );

    box.pack_start( sw,   true,  true );
    box.pack_end(   bbox, false, true );

    add( box );

    show_all();

  }

  private bool on_keypress( EventKey e ) {

    switch( e.keyval ) {
      case 32    :  return( handle_space() );
      case 65293 :  return( handle_return() );
      case 65289 :  return( handle_tab() );
    }

    return( false );

  }

  /* Returns the text from the start of the current line to the current insertion cursor */
  private string get_line_text( int adjust ) {

    TextIter current;
    TextIter startline;
    TextIter endline;
    var      buf = _entry.buffer;

    buf.get_iter_at_mark( out current, buf.get_insert() );

    /* Adjust the line */
    if( adjust < 0 ) {
      current.backward_lines( 0 - adjust );
    } else if( adjust > 0 ) {
      current.backward_lines( adjust );
    }

    buf.get_iter_at_line( out startline, current.get_line() );
    buf.get_iter_at_line( out endline,   current.get_line() + 1 );

    return( buf.get_text( startline, endline, true ) );

  }

  /* Returns the text from the start of the current line to the current insertion cursor */
  private string get_start_to_current_text() {

    TextIter startline;
    TextIter endline;
    var      buf = _entry.buffer;

    /* Get the text on the current line */
    buf.get_iter_at_mark( out endline,   buf.get_insert() );
    buf.get_iter_at_line( out startline, endline.get_line() );

    return( buf.get_text( startline, endline, true ) );

  }

  /* Returns the whitespace at the beginning of the current line */
  private bool get_whitespace( string line, out string wspace ) {

    wspace = "";

    try {

      MatchInfo match_info;
      var       re = new Regex( "^([ \\t]*)" );

      if( re.match( line, 0, out match_info ) ) {
        wspace = match_info.fetch( 1 );
        return( true );
      }

    } catch( RegexError err ) {
      return( false );
    }

    return( false );

  }

  /* Converts the given whitespace to all spaces */
  private string tabs_to_spaces( string wspace ) {

    var tspace = string.nfill( 8, ' ' );

    return( wspace.replace( "\t", tspace ) );

  }

  /* If the user attempts to hit the space bar when adding front-end whitespace, don't insert it */
  private bool handle_space() {

    return( get_start_to_current_text().strip() == "" );

  }

  /* If the return key is pressed, we will automatically indent the next line */
  private bool handle_return() {

    string wspace;

    if( get_whitespace( get_line_text( 0 ), out wspace ) ) {
      var ins = "\n" + wspace;
      _entry.buffer.insert_at_cursor( ins, ins.length );
      return( true );
    }

    return( false );

  }

  /* If the Tab key is pressed, only allow it if it is valid to do so */
  private bool handle_tab() {

    TextIter current;
    var      prev = "";
    var      curr = "";

    _entry.buffer.get_iter_at_mark( out current, _entry.buffer.get_insert() );

    if( current.get_line() == 0 ) {
      return( true );
    } else if( get_whitespace( get_line_text( 0 ), out curr ) && get_whitespace( get_line_text( -1 ), out prev ) ) {
      return( tabs_to_spaces( curr ).length > tabs_to_spaces( prev ).length );
    }

    return( false );

  }

}
