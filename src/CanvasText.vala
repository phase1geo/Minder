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
using GLib;
using Gdk;
using Cairo;
using Pango;

public class CanvasText : Object {

  /* Member variables */
  private string       _text         = "";
  private bool         _markup       = true;
  private bool         _edit         = false;
  private int          _cursor       = 0;   /* Location of the cursor when editing */
  private int          _column       = 0;   /* Character column to use when moving vertically */
  private Pango.Layout _pango_layout = null;
  private int          _selstart     = 0;
  private int          _selend       = 0;
  private int          _selanchor    = 0;
  private double       _min_width    = 50;
  private double       _max_width    = 200;
  private double       _width        = 0;
  private double       _height       = 0;

  /* Signals */
  public signal void resized();

  /* Properties */
  public string text {
    get {
      return( _text );
    }
    set {
      if( _text != value ) {
        _text = value;
        update_size( true );
      }
    }
  }
  public double posx   { get; set; default = 0; }
  public double posy   { get; set; default = 0; }
  public double width  {
    get {
      return( _width );
    }
  }
  public double height {
    get {
      return( _height );
    }
  }
  public bool markup {
    get {
      return( _markup );
    }
    set {
      if( _markup != value ) {
        _markup = value;
        update_size( true );
      }
    }
  }
  public bool edit {
    get {
      return( _edit );
    }
    set {
      if( _edit != value ) {
        _edit = value;
        update_size( true );
      }
    }
  }

  /* Default constructor */
  public CanvasText( DrawArea da ) {
    _pango_layout = da.create_pango_layout( null );
    _pango_layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    _pango_layout.set_width( (int)_max_width * Pango.SCALE );
    update_size( false );
  }

  /* Constructor initializing string */
  public CanvasText.with_text( DrawArea da, string txt ) {
    _pango_layout = da.create_pango_layout( txt );
    _pango_layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    _pango_layout.set_width( (int)_max_width * Pango.SCALE );
    _text         = txt;
    update_size( false );
  }

  /* Copies an existing CanvasText to this CanvasText */
  public void copy( CanvasText ct ) {
    posx       = ct.posx;
    posy       = ct.posy;
    _min_width = ct._min_width;
    _max_width = ct._max_width;
    _text      = ct.text;
    _pango_layout.set_font_description( ct._pango_layout.get_font_description() );
    update_size( true );
  }

  /* Returns the maximum width allowed for this node */
  public int max_width() {
    return( (int)_max_width );
  }

  /* Sets the font description to the given value */
  public void set_font( FontDescription font ) {
    _pango_layout.set_font_description( font );
    update_size( true );
  }

  /* Returns true if the text is currently wrapped */
  public bool is_wrapped() {
    return( _pango_layout.is_wrapped() );
  }

  /* Returns true if the given cursor coordinates lies within this node */
  public bool is_within( double x, double y ) {
    return( (posx < x) && (x < (posx + _width)) && (posy < y) && (y < (posy + _height)) );
  }

  /* Loads the file contents into this instance */
  public virtual void load( Xml.Node* n ) {

    string? x = n->get_prop( "posx" );
    if( x != null ) {
      posx = double.parse( x );
    }

    string? y = n->get_prop( "posy" );
    if( y != null ) {
      posy = double.parse( y );
    }

    string? mw = n->get_prop( "maxwidth" );
    if( mw != null ) {
      _max_width = double.parse( mw );
      _pango_layout.set_width( (int)_max_width * Pango.SCALE );
    }

    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      text = n->children->get_content();
    }

  }

  /*
   Helper function for converting an RGBA color value to a stringified color
   that can be used by a markup parser.
  */
  private string color_from_rgba( RGBA rgba ) {
    return( "#%02x%02x%02x".printf( (int)(rgba.red * 255), (int)(rgba.green * 255), (int)(rgba.blue * 255) ) );
  }

  /* Removes < and > characters */
  private string unmarkup( string markup ) {
    return( markup.replace( "<", "&lt;" ).replace( ">", "&gt;" ) );
  }

  /* Generates the marked up name that will be displayed in the node */
  private string name_markup( Theme? theme ) {
    if( (_selstart != _selend) && (theme != null) ) {
      var fg      = color_from_rgba( theme.textsel_foreground );
      var bg      = color_from_rgba( theme.textsel_background );
      var spos    = text.index_of_nth_char( _selstart );
      var epos    = text.index_of_nth_char( _selend );
      var begtext = unmarkup( text.slice( 0, spos ) );
      var endtext = unmarkup( text.slice( epos, text.char_count() ) );
      var seltext = "<span foreground=\"" + fg + "\" background=\"" + bg + "\">" + unmarkup( text.slice( spos, epos ) ) + "</span>";
      return( begtext + seltext + endtext );
    }
    return( (markup || edit) ? text : unmarkup( text ) );
  }

  /*
   Updates the width and height based on the current text.
  */
  public void update_size( bool call_resized ) {
    if( _pango_layout != null ) {
      int text_width, text_height;
      _pango_layout.set_markup( name_markup( null ), -1 );
      _pango_layout.get_size( out text_width, out text_height );
      _width  = (text_width  / Pango.SCALE);
      _height = (text_height / Pango.SCALE);
      if( call_resized ) {
        resized();
      }
    }
  }

  /* Resizes the node width by the given amount */
  public virtual void resize( double diff ) {
    _max_width += diff;
    _pango_layout.set_width( (int)_max_width * Pango.SCALE );
    update_size( true );
  }

  /* Updates the column value */
  private void update_column() {
    int line;
    var cpos = text.index_of_nth_char( _cursor );
    _pango_layout.index_to_line_x( cpos, false, out line, out _column );
  }

  /* Sets the cursor from the given mouse coordinates */
  public void set_cursor_at_char( double x, double y, bool motion ) {
    int cursor, trailing;
    int adjusted_x = (int)(x - posx) * Pango.SCALE;
    int adjusted_y = (int)(y - posy) * Pango.SCALE;
    if( _pango_layout.xy_to_index( adjusted_x, adjusted_y, out cursor, out trailing ) ) {
      var cindex = text.char_count( cursor + trailing );
      if( motion ) {
        if( cindex > _selanchor ) {
          _selend = cindex;
        } else if( cindex < _selanchor ) {
          _selstart = cindex;
        } else {
          _selstart = cindex;
          _selend   = cindex;
        }
      } else {
        _selstart  = cindex;
        _selend    = cindex;
        _selanchor = cindex;
      }
      _cursor = _selend;
      update_column();
    }
  }

  /* Selects the word at the current x/y position in the text */
  public void set_cursor_at_word( double x, double y, bool motion ) {
    int cursor, trailing;
    int adjusted_x = (int)(x - posx) * Pango.SCALE;
    int adjusted_y = (int)(y - posy) * Pango.SCALE;
    if( _pango_layout.xy_to_index( adjusted_x, adjusted_y, out cursor, out trailing ) ) {
      cursor += trailing;
      var word_start = text.substring( 0, cursor ).last_index_of( " " );
      var word_end   = text.index_of( " ", cursor );
      if( word_start == -1 ) { _selstart = 0; } else { var windex = text.char_count( word_start ); if( !motion || (windex < _selanchor) ) { _selstart = windex + 1; } }
      if( word_end == -1 ) {
        _selend = text.char_count();
      } else {
        var windex = text.char_count( word_end );
        if( !motion || (windex > _selanchor) ) {
          _selend = windex;
        }
      }
      _cursor = _selend;
      update_column();
    }
  }

  /* Called after the cursor has been moved, clears the selection */
  public void clear_selection() {
    _selstart = _selend = _cursor;
  }

  /*
   Called after the cursor has been moved, adjusts the selection
   to include the cursor.
  */
  private void adjust_selection( int last_cursor ) {
    if( last_cursor == _selstart ) {
      if( _cursor <= _selend ) {
        _selstart = _cursor;
      } else {
        _selend = _cursor;
      }
    } else {
      if( _cursor >= _selstart ) {
        _selend = _cursor;
      } else {
        _selstart = _cursor;
      }
    }
  }

  /* Deselects all of the text */
  public void set_cursor_none() {
    clear_selection();
  }

  /* Selects all of the text and places the cursor at the end of the name string */
  public void set_cursor_all( bool motion ) {
    if( !motion ) {
      _selstart  = 0;
      _selend    = text.char_count();
      _selanchor = _selend;
      _cursor    = _selend;
    }
  }

  /* Adjusts the cursor by the given amount of characters */
  private void cursor_by_char( int dir ) {
    var last = text.char_count();
    _cursor += dir;
    if( _cursor < 0 ) {
      _cursor = 0;
    } else if( _cursor > last ) {
      _cursor = last;
    }
    update_column();
  }

  /* Move the cursor in the given direction */
  public void move_cursor( int dir ) {
    cursor_by_char( dir );
    clear_selection();
  }

  /* Adjusts the selection by the given cursor */
  public void selection_by_char( int dir ) {
    var last_cursor = _cursor;
    cursor_by_char( dir );
    adjust_selection( last_cursor );
  }

  /* Moves the cursor up/down the text by a line */
  private void cursor_by_line( int dir ) {
    int line, x;
    var cpos = text.index_of_nth_char( _cursor );
    _pango_layout.index_to_line_x( cpos, false, out line, out x );
    line += dir;
    if( line < 0 ) {
      _cursor = 0;
    } else if( line >= _pango_layout.get_line_count() ) {
      _cursor = text.char_count();
    } else {
      int index, trailing;
      var line_layout = _pango_layout.get_line( line );
      line_layout.x_to_index( _column, out index, out trailing );
      _cursor = text.char_count( index + trailing );
    }
  }

  /*
   Moves the cursor in the given vertical direction, clearing the
   selection.
  */
  public void move_cursor_vertically( int dir ) {
    cursor_by_line( dir );
    clear_selection();
  }

  /* Adjusts the selection in the vertical direction */
  public void selection_vertically( int dir ) {
    var last_cursor = _cursor;
    cursor_by_line( dir );
    adjust_selection( last_cursor );
  }

  /* Moves the cursor to the beginning of the name */
  public void move_cursor_to_start() {
    _cursor = 0;
    clear_selection();
  }

  /* Moves the cursor to the end of the name */
  public void move_cursor_to_end() {
    _cursor = text.char_count();
    clear_selection();
  }

  /* Causes the selection to continue from the start of the text */
  public void selection_to_start() {
    if( _selstart == _selend ) {
      _selstart = 0;
      _selend   = _cursor;
      _cursor   = 0;
    } else {
      _selstart = 0;
      _cursor   = 0;
    }
  }

  /* Causes the selection to continue to the end of the text */
  public void selection_to_end() {
    if( _selstart == _selend ) {
      _selstart = _cursor;
      _selend   = text.char_count();
      _cursor   = text.char_count();
    } else {
      _selend = text.char_count();
      _cursor = text.char_count();
    }
  }

  /* Finds the next/previous word boundary */
  private int find_word( int start, int dir ) {
    bool alnum_found = false;
    if( dir == 1 ) {
      for( int i=start; i<text.char_count(); i++ ) {
        int index = text.index_of_nth_char( i );
        if( text.get_char( index ).isalnum() ) {
          alnum_found = true;
        } else if( alnum_found ) {
          return( i );
        }
      }
      return( text.char_count() );
    } else {
      for( int i=(start - 1); i>=0; i-- ) {
        int index = text.index_of_nth_char( i );
        if( text.get_char( index ).isalnum() ) {
          alnum_found = true;
        } else if( alnum_found ) {
          return( i + 1 );
        }
      }
      return( 0 );
    }
  }

  /* Moves the cursor to the next or previous word beginning */
  public void move_cursor_by_word( int dir ) {
    _cursor = find_word( _cursor, dir );
    _selend = _selstart;
  }

  /* Change the selection by a word in the given direction */
  public void selection_by_word( int dir ) {
    if( _cursor == _selstart ) {
      _cursor = find_word( _cursor, dir );
      if( _cursor <= _selend ) {
        _selstart = _cursor;
      } else {
        _selstart = _selend;
        _selend   = _cursor;
      }
    } else {
      _cursor = find_word( _cursor, dir );
      if( _cursor >= _selstart ) {
        _selend = _cursor;
      } else {
        _selend   = _selstart;
        _selstart = _cursor;
      }
    }
  }

  /* Handles a backspace key event */
  public void backspace() {
    if( _cursor > 0 ) {
      if( _selstart != _selend ) {
        var spos = text.index_of_nth_char( _selstart );
        var epos = text.index_of_nth_char( _selend );
        text     = text.splice( spos, epos );
        _cursor  = _selstart;
        _selend  = _selstart;
      } else {
        var spos = text.index_of_nth_char( _cursor - 1 );
        var epos = text.index_of_nth_char( _cursor );
        text     = text.splice( spos, epos );
        _cursor--;
      }
    }
  }

  /* Handles a delete key event */
  public void delete() {
    if( _cursor < text.length ) {
      if( _selstart != _selend ) {
        var spos = text.index_of_nth_char( _selstart );
        var epos = text.index_of_nth_char( _selend );
        text    = text.splice( spos, epos );
        _cursor = _selstart;
        _selend = _selstart;
      } else {
        var spos = text.index_of_nth_char( _cursor );
        var epos = text.index_of_nth_char( _cursor + 1 );
        text = text.splice( spos, epos );
      }
    }
  }

  /* Inserts the given string at the current cursor position and adjusts cursor */
  public void insert( string s ) {
    var slen = s.char_count();
    if( _selstart != _selend ) {
      var spos = text.index_of_nth_char( _selstart );
      var epos = text.index_of_nth_char( _selend );
      text    = text.splice( spos, epos, s );
      _cursor = _selstart + slen;
      _selend = _selstart;
    } else {
      var cpos = text.index_of_nth_char( _cursor );
      text = text.splice( cpos, cpos, s );
      _cursor += slen;
    }
  }

  /*
   Returns the currently selected text or, if no text is currently selected,
   returns null.
  */
  public string? get_selected_text() {
    if( _selstart != _selend ) {
      var spos = text.index_of_nth_char( _selstart );
      var epos = text.index_of_nth_char( _selend );
      return( text.slice( spos, epos ) );
    }
    return( null );
  }

  /* Draws the node font to the screen */
  public void draw( Cairo.Context ctx, Theme theme, RGBA fg, double alpha ) {

    /* Make sure the the size is up-to-date */
    _pango_layout.set_markup( name_markup( theme ), -1 );

    /* Output the text */
    ctx.move_to( posx, posy );
    Utils.set_context_color_with_alpha( ctx, fg, alpha );
    Pango.cairo_show_layout( ctx, _pango_layout );
    ctx.new_path();

    /* Draw the insertion cursor if we are in the 'editable' state */
    if( edit ) {
      var cpos = text.index_of_nth_char( _cursor );
      var rect = _pango_layout.index_to_pos( cpos );
      Utils.set_context_color_with_alpha( ctx, theme.text_cursor, alpha );
      double ix, iy;
      ix = posx + (rect.x / Pango.SCALE) - 1;
      iy = posy + (rect.y / Pango.SCALE);
      ctx.rectangle( ix, iy, 1, (rect.height / Pango.SCALE) );
      ctx.fill();
    }

  }

}
