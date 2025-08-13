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
  private MindMap       _map;
  private double        _posx         = 0.0;
  private double        _posy         = 0.0;
  private FormattedText _text;
  private bool          _edit         = false;
  private int           _cursor       = 0;   /* Location of the cursor when editing */
  private int           _column       = 0;   /* Character column to use when moving vertically */
  private Pango.Layout  _pango_layout = null;
  private Pango.Layout  _line_layout  = null;
  private int           _selstart     = 0;
  private int           _selend       = 0;
  private int           _selanchor    = 0;
  private double        _max_width    = 200;
  private double        _width        = 0;
  private double        _height       = 0;
  private bool          _debug        = false;
  private int           _font_size    = 12;

  /* Signals */
  public signal void resized();
  public signal void select_mode( bool mode );
  public signal void cursor_changed();

  /* Properties */
  public FormattedText text {
    get {
      return( _text );
    }
  }
  public double posx {
    get {
      return( _posx + _map.origin_x );
    }
    set {
      _posx = value - _map.origin_x;
    }
  }
  public double posy {
    get {
      return( _posy + _map.origin_y );
    } 
    set {
      _posy = value - _map.origin_y;
    }
  }
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
  public double max_width {
    get {
      return( _max_width );
    }
    set {
      if( _max_width != value ) {
        int int_value = (int)value;
        _max_width = value;
        _pango_layout.set_width( int_value * Pango.SCALE );
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
        if( !_edit ) {
          clear_selection( "edit" );
        }
        update_size( true );
      }
    }
  }
  public int cursor {
    get {
      return( text.text.index_of_nth_char( _cursor ) );
    }
  }
  public int selstart {
    get {
      return( text.text.index_of_nth_char( _selstart ) );
    }
  }
  public int selend {
    get {
      return( text.text.index_of_nth_char( _selend ) );
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public CanvasText( MindMap map ) {
    int int_max_width = (int)_max_width;
    _map          = map;
    _text         = new FormattedText( map );
    _text.changed.connect( text_changed );
    _line_layout  = map.canvas.create_pango_layout( "M" );
    _pango_layout = map.canvas.create_pango_layout( null );
    _pango_layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    _pango_layout.set_width( int_max_width * Pango.SCALE );
    initialize_font_description();
    update_size( false );
  }

  //-------------------------------------------------------------
  // Constructor initializing string
  public CanvasText.with_text( MindMap map, string txt ) {
    int int_max_width = (int)_max_width;
    _map          = map;
    _text         = new FormattedText.with_text( map, txt );
    _text.changed.connect( text_changed );
    _line_layout  = map.canvas.create_pango_layout( "M" );
    _pango_layout = map.canvas.create_pango_layout( txt );
    _pango_layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    _pango_layout.set_width( int_max_width * Pango.SCALE );
    initialize_font_description();
    update_size( false );
  }

  //-------------------------------------------------------------
  // Allocates and initializes the font description for the layouts
  private void initialize_font_description() {
    var fd = new Pango.FontDescription();
    fd.set_size( _font_size * Pango.SCALE );
    _line_layout.set_font_description( fd );
    _pango_layout.set_font_description( fd );
  }

  //-------------------------------------------------------------
  // Copies an existing CanvasText to this CanvasText
  public void copy( CanvasText ct ) {
    int int_max_width = (int)_max_width;
    posx       = ct.posx;
    posy       = ct.posy;
    _max_width = ct._max_width;
    _font_size = ct._font_size;
    _text.copy( ct.text );
    _line_layout.set_font_description( ct._pango_layout.get_font_description() );
    _pango_layout.set_font_description( ct._pango_layout.get_font_description() );
    _pango_layout.set_alignment( ct._pango_layout.get_alignment() );
    _pango_layout.set_width( int_max_width * Pango.SCALE );
    update_size( true );
  }

  //-------------------------------------------------------------
  // Returns the font description set for this text
  public FontDescription get_font_fd() {
    return( _line_layout.get_font_description() );
  }

  //-------------------------------------------------------------
  // Sets the font size to the given size
  public void set_font( string? family = null, int? size = null, double zoom_factor = 1.0 ) {
    var fd = _line_layout.get_font_description();
    if( family != null ) {
      fd.set_family( family );
    }
    if( size != null ) {
      _font_size = size;
    }
    var int_fsize = (int)((_font_size * zoom_factor) * Pango.SCALE);
    fd.set_size( int_fsize );
    _line_layout.set_font_description( fd );
    _pango_layout.set_font_description( fd );
    update_size( true );
  }

  //-------------------------------------------------------------
  // Sets the text alignment to the given value.
  public void set_text_alignment( Pango.Alignment? text_align ) {
    if( text_align == null ) return;
    _line_layout.set_alignment( text_align );
    _pango_layout.set_alignment( text_align );
    update_size( true );
  }

  //-------------------------------------------------------------
  // Returns true if the text is currently wrapped
  public bool is_wrapped() {
    return( _pango_layout.is_wrapped() );
  }

  //-------------------------------------------------------------
  // Returns the string which contains newlines to mimic layout
  public string get_wrapped_text() {
    unowned SList<LayoutLine> lines = _pango_layout.get_lines_readonly();
    string str   = "";
    lines.@foreach((item) => {
      str += (text.text.substring( item.start_index, item.length ) + "\n");
    });
    return( str );
  }

  //-------------------------------------------------------------
  // Returns true if the given cursor coordinates lies within
  // this node
  public bool is_within( double x, double y ) {
    return( Utils.is_within_bounds( x, y, posx, posy, _width, _height ) );
  }

  //-------------------------------------------------------------
  // Returns true if the given coordinates within a URL and
  // returns the matching URL.
  public bool is_within_clickable( double x, double y, out FormatTag tag, out string extra ) {
    int adjusted_x = (int)(x - posx) * Pango.SCALE;
    int adjusted_y = (int)(y - posy) * Pango.SCALE;
    int cursor, trailing;
    tag   = FormatTag.URL;
    extra = "";
    if( _pango_layout.xy_to_index( adjusted_x, adjusted_y, out cursor, out trailing ) ) {
      var cindex = text.text.char_count( cursor + trailing );
      FormatTag[] tags = { FormatTag.URL };
      foreach( FormatTag t in tags ) {
        var e = text.get_extra( t, cindex );
        if( e != null ) {
          tag   = t;
          extra = e;
          return( true );
        }
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if text is currently selected
  public bool is_selected() {
    return( _selstart != _selend );
  }

  //-------------------------------------------------------------
  // Saves the current instace into the given XML tree
  public virtual Xml.Node* save( string title ) {

    Xml.Node* n = new Xml.Node( null, title );

    n->set_prop( "maxwidth", _max_width.to_string() );
    n->add_child( _text.save() );

    return( n );

  }

  //-------------------------------------------------------------
  // Returns the plain text string stored in the given XML node
  public static string xml_text( Xml.Node* n ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "text" ) )  {
        return( FormattedText.xml_text( it ) );
      }
    }
    return( _( "No text found" ) );
  }

  //-------------------------------------------------------------
  // Loads the file contents into this instance
  public virtual void load( Xml.Node* n ) {

    string? mw = n->get_prop( "maxwidth" );
    if( mw != null ) {
      _max_width = double.parse( mw );
      var int_max_width = (int)_max_width;
      _pango_layout.set_width( int_max_width * Pango.SCALE );
    }

    /* Load the text and formatting */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "text" ) )  {
        _text.load( it );
        update_size( false );
      }
    }

  }

  //-------------------------------------------------------------
  // Returns the height of a single line of text
  public double get_line_height() {
    return( Utils.get_line_height( _pango_layout ) );
  }

  //-------------------------------------------------------------
  // Returns the number of pixels to include on the current page
  // of this text item
  public double get_page_include_size( int page_size ) {
    Pango.Rectangle ink_rect, log_rect;
    var line_count = _pango_layout.get_line_count();
    for( int i=0; i<line_count; i++ ) {
      _pango_layout.get_line_readonly( i ).get_pixel_extents( out ink_rect, out log_rect );
      var ly = (int)log_rect.y;
      var lh = (int)log_rect.height;
      if( (ly / page_size) != ((ly + lh) / page_size) ) {
        return( ly );
      }
    }
    return( _height );
  }

  //-------------------------------------------------------------
  // Called whenever the text changes
  private void text_changed() {
    update_size( true );
  }

  //-------------------------------------------------------------
  // Updates the width and height based on the current text.
  public void update_size( bool call_resized = true ) {
    if( _pango_layout != null ) {
      int text_width, text_height;
      _pango_layout.set_text( _text.text, -1 );
      _pango_layout.set_attributes( _text.get_attributes() );
      _pango_layout.get_size( out text_width, out text_height );
      _width  = (text_width  / Pango.SCALE);
      _height = (text_height / Pango.SCALE);
      if( call_resized ) {
        resized();
      }
    }
  }

  //-------------------------------------------------------------
  // Updates the canvas item with the given theme
  public void update_attributes() {
    if( _pango_layout != null ) {
      _pango_layout.set_attributes( _text.get_attributes() );
    }
  }

  //-------------------------------------------------------------
  // Resizes the node width by the given amount
  public virtual void resize( double diff ) {
    _max_width += diff;
    var int_max_width = (int)_max_width;
    _pango_layout.set_width( int_max_width * Pango.SCALE );
    update_size( true );
  }

  //-------------------------------------------------------------
  // Updates the column value
  private void update_column() {
    int line;
    var cpos = text.text.index_of_nth_char( _cursor );
    _pango_layout.index_to_line_x( cpos, false, out line, out _column );
  }

  //-------------------------------------------------------------
  // Only sets the cursor location to the given value
  public void set_cursor_only( int cursor ) {
    var orig_cursor = _cursor;
    _cursor = cursor;
    update_column();
    if( orig_cursor != _cursor ) {
      cursor_changed();
    }
  }

  //-------------------------------------------------------------
  // Sets the cursor from the given mouse coordinates
  public void set_cursor_at_char( double x, double y, bool motion ) {
    int cursor, trailing;
    int adjusted_x = (int)(x - posx) * Pango.SCALE;
    int adjusted_y = (int)(y - posy) * Pango.SCALE;
    if( !_pango_layout.xy_to_index( adjusted_x, adjusted_y, out cursor, out trailing ) ) {
      cursor   = text.text.index_of_nth_char( text.text.char_count() );
      trailing = 0;
    }
    var cindex = text.text.char_count( cursor + trailing );
    if( motion ) {
      if( cindex > _selanchor ) {
        change_selection( null, cindex, "set_cursor_at_char A" );
      } else if( cindex < _selanchor ) {
        change_selection( cindex, null, "set_cursor_at_char B" );
      } else {
        change_selection( cindex, cindex, "set_cursor_at_char C" );
      }
    } else {
      change_selection( cindex, cindex, "set_cursor_at_char D" );
      _selanchor = cindex;
    }
    set_cursor_only( _selend );
  }

  //-------------------------------------------------------------
  // Selects the word at the current x/y position in the text
  public void set_cursor_at_word( double x, double y, bool motion ) {
    int cursor, trailing;
    int adjusted_x = (int)(x - posx) * Pango.SCALE;
    int adjusted_y = (int)(y - posy) * Pango.SCALE;
    if( _pango_layout.xy_to_index( adjusted_x, adjusted_y, out cursor, out trailing ) ) {
      cursor += trailing;
      var word_start = text.text.substring( 0, cursor ).last_index_of( " " );
      var word_end   = text.text.index_of( " ", cursor );
      int? sstart    = null;
      int? send      = null;
      if( word_start == -1 ) {
        sstart = 0;
      } else {
        var windex = text.text.char_count( word_start );
        if( !motion || (windex < _selanchor) ) {
          sstart = windex + 1;
        }
      }
      if( word_end == -1 ) {
        send = text.text.char_count();
      } else {
        var windex = text.text.char_count( word_end );
        if( !motion || (windex > _selanchor) ) {
          send = windex;
        }
      }
      change_selection( sstart, send, "set_cursor_at_word" );
      set_cursor_only( _selend );
    }
  }

  //-------------------------------------------------------------
  // Called after the cursor has been moved, clears the selection
  public void clear_selection( string? msg = null ) {
    if( _debug && (msg != null) ) {
      stdout.printf( "In clear_selection, msg: %s\n", msg );
    }
    change_selection( _cursor, _cursor, "clear_selection" );
  }

  //-------------------------------------------------------------
  // Called after the cursor has been moved, adjusts the selection
  // to include the cursor.
  private void adjust_selection( int last_cursor ) {
    if( last_cursor == _selstart ) {
      if( _cursor <= _selend ) {
        change_selection( _cursor, null, "adjust_selection A" );
      } else {
        change_selection( null, _cursor, "adjust_selection B" );
      }
    } else {
      if( _cursor >= _selstart ) {
        change_selection( null, _cursor, "adjust_selection C" );
      } else {
        change_selection( _cursor, null, "adjust_selection D" );
      }
    }
  }

  //-------------------------------------------------------------
  // Deselects all of the text
  public void set_cursor_none() {
    clear_selection( "set_cursor_none" );
  }

  //-------------------------------------------------------------
  // Selects all of the text and places the cursor at the end of
  // the name string
  public void set_cursor_all( bool motion ) {
    if( !motion ) {
      change_selection( 0, text.text.char_count(), "set_cursor_all" );
      _selanchor = _selend;
      set_cursor_only( _selend );
    }
  }

  //-------------------------------------------------------------
  // The parameter dir assumes left-to-right; however, if the
  // current layout is a right-to-left language, we will invert
  // the value.
  private int calc_direction( int dir ) {
    var ldir = _pango_layout.get_direction( text.text.index_of_nth_char( _cursor ) );
    return( (ldir == Pango.Direction.RTL) ? (0 - dir) : dir );
  }

  //-------------------------------------------------------------
  // Adjusts the cursor by the given amount of characters
  private void cursor_by_char( int dir ) {
    var cpos = _cursor;
    if( _selstart != _selend ) {
      if( calc_direction( dir ) > 0 ) {
        cpos = _selend;
      } else {
        cpos = _selstart;
      }
    } else {
      var last      = text.text.char_count();
      var next_byte = false;
      do {
        cpos += calc_direction( dir );
        next_byte = false;
        if( cpos < 0 ) {
          cpos = 0;
        } else if( cpos > last ) {
          cpos = last;
        } else {
          var ch = text.text.get_char( text.text.index_of_nth_char( cpos ) );
          next_byte = !ch.isprint();
        }
      } while( next_byte );
    }
    set_cursor_only( cpos );
  }

  //-------------------------------------------------------------
  // Move the cursor in the given direction
  public void move_cursor( int dir ) {
    cursor_by_char( dir );
    clear_selection( "move_cursor" );
  }

  //-------------------------------------------------------------
  // Adjusts the selection by the given cursor
  public void selection_by_char( int dir ) {
    var last_cursor = _cursor;
    cursor_by_char( dir );
    adjust_selection( last_cursor );
  }

  //-------------------------------------------------------------
  // Moves the cursor up/down the text by a line
  private void cursor_by_line( int dir ) {
    int line, x;
    var cpos = text.text.index_of_nth_char( _cursor );
    _pango_layout.index_to_line_x( cpos, false, out line, out x );
    line += dir;
    if( line < 0 ) {
      set_cursor_only( 0 );
    } else if( line >= _pango_layout.get_line_count() ) {
      set_cursor_only( text.text.char_count() );
    } else {
      int index, trailing;
      var line_layout = _pango_layout.get_line( line );
      line_layout.x_to_index( _column, out index, out trailing );
      set_cursor_only( text.text.char_count( index + trailing ) );
    }
  }

  //-------------------------------------------------------------
  // Moves the cursor in the given vertical direction, clearing the
  // selection.
  public void move_cursor_vertically( int dir ) {
    cursor_by_line( dir );
    clear_selection( "move_cursor_vertically" );
  }

  //-------------------------------------------------------------
  // Adjusts the selection in the vertical direction
  public void selection_vertically( int dir ) {
    var last_cursor = _cursor;
    cursor_by_line( dir );
    adjust_selection( last_cursor );
  }

  //-------------------------------------------------------------
  // Finds the start or end character of a line
  private int find_line_extent( bool start ) {
    int line, line2, column;
    _pango_layout.index_to_line_x( text.text.index_of_nth_char( _cursor ), false, out line, out column );
    var line_layout = _pango_layout.get_line_readonly( line );
    if( start ) {
      return( text.text.char_count( line_layout.start_index ) );
    } else {
      var eol = line_layout.start_index + line_layout.length;
      _pango_layout.index_to_line_x( eol, false, out line2, out column );
      return( text.text.char_count( eol ) - ((line != line2) ? 1 : 0) );
    }
  }

  //-------------------------------------------------------------
  // Moves the cursor to the beginning of the current line
  public void move_cursor_to_start_of_line() {
    set_cursor_only( find_line_extent( true ) );
    clear_selection( "move_cursor_to_start_of_line" );
  }

  //-------------------------------------------------------------
  // Moves the cursor to the end of the name
  public void move_cursor_to_end_of_line() {
    set_cursor_only( find_line_extent( false ) );
    clear_selection( "move_cursor_to_end_of_line" );
  }

  //-------------------------------------------------------------
  // Causes the selection to continue from the start of the line
  public void selection_to_start_of_line( bool home ) {
    int line_start = find_line_extent( true );
    if( (_selstart == _selend) || home ) {
      change_selection( line_start, _cursor, "selection_to_line_start A" );
      if( !home ) {
        set_cursor_only( line_start );
      }
    } else {
      change_selection( _cursor, null, "selection_to_line_start B" );
      set_cursor_only( line_start );
    }
  }

  //-------------------------------------------------------------
  // Causes the selection to continue to the end of the line
  public void selection_to_end_of_line( bool end ) {
    int line_end = find_line_extent( false );
    if( (_selstart == _selend) || end ) {
      change_selection( _cursor, line_end, "selection_to_end A" );
      if( !end ) {
        set_cursor_only( line_end );
      }
    } else {
      change_selection( null, line_end, "selection_to_end B" );
      set_cursor_only( line_end );
    }
  }

  //-------------------------------------------------------------
  // Moves the cursor to the beginning of the name
  public void move_cursor_to_start() {
    set_cursor_only( 0 );
    clear_selection( "move_cursor_to_start" );
  }

  //-------------------------------------------------------------
  // Moves the cursor to the end of the name
  public void move_cursor_to_end() {
    set_cursor_only( text.text.char_count() );
    clear_selection( "move_cursor_to_end" );
  }

  //-------------------------------------------------------------
  // Causes the selection to continue from the start of the text
  public void selection_to_start( bool home ) {
    if( (_selstart == _selend) || home ) {
      change_selection( 0, _cursor, "selection_to_start A" );
      if( !home ) {
        set_cursor_only( 0 );
      }
    } else {
      change_selection( 0, null, "selection_to_start B" );
      set_cursor_only( 0 );
    }
  }

  //-------------------------------------------------------------
  // Causes the selection to continue to the end of the text
  public void selection_to_end( bool end ) {
    if( (_selstart == _selend) || end ) {
      change_selection( _cursor, text.text.char_count(), "selection_to_end A" );
      if( !end ) {
        set_cursor_only( text.text.char_count() );
      }
    } else {
      change_selection( null, text.text.char_count(), "selection_to_end B" );
      set_cursor_only( text.text.char_count() );
    }
  }

  //-------------------------------------------------------------
  // Finds the next/previous word boundary
  private int find_word( int start, int dir ) {
    bool alnum_found = false;
    if( calc_direction( dir ) == 1 ) {
      for( int i=start; i<text.text.char_count(); i++ ) {
        int index = text.text.index_of_nth_char( i );
        if( text.text.get_char( index ).isalnum() ) {
          alnum_found = true;
        } else if( alnum_found ) {
          return( i );
        }
      }
      return( text.text.char_count() );
    } else {
      for( int i=(start - 1); i>=0; i-- ) {
        int index = text.text.index_of_nth_char( i );
        if( text.text.get_char( index ).isalnum() ) {
          alnum_found = true;
        } else if( alnum_found ) {
          return( i + 1 );
        }
      }
      return( 0 );
    }
  }

  //-------------------------------------------------------------
  // Moves the cursor to the next or previous word beginning
  public void move_cursor_by_word( int dir ) {
    set_cursor_only( find_word( _cursor, dir ) );
    clear_selection( "move_cursor_by_word" );
  }

  //-------------------------------------------------------------
  // Change the selection by a word in the given direction
  public void selection_by_word( int dir ) {
    if( _cursor == _selstart ) {
      set_cursor_only( find_word( _cursor, dir ) );
      if( _cursor <= _selend ) {
        change_selection( _cursor, null, "selection_by_word A" );
      } else {
        change_selection( _selend, _cursor, "selection_by_word B" );
      }
    } else {
      set_cursor_only( find_word( _cursor, dir ) );
      if( _cursor >= _selstart ) {
        change_selection( null, _cursor, "selection_by_word C" );
      } else {
        change_selection( _cursor, _selstart, "selection_by_word D" );
      }
    }
  }

  //-------------------------------------------------------------
  // Handles a backspace key event
  public void backspace( UndoTextBuffer undo_buffer ) {
    var cur = _cursor;
    if( _selstart != _selend ) {
      var spos = text.text.index_of_nth_char( _selstart );
      var epos = text.text.index_of_nth_char( _selend );
      var str  = text.text.slice( spos, epos );
      var tags = text.get_tags_in_range( spos, epos );
      set_cursor_only( _selstart );
      change_selection( null, _selstart, "backspace" );
      text.remove_text( spos, (epos - spos) );
      undo_buffer.add_delete( spos, str, tags, cur );
    } else if( _cursor > 0 ) {
      var spos = text.text.index_of_nth_char( _cursor - 1 );
      var epos = text.text.index_of_nth_char( _cursor );
      var str  = text.text.slice( spos, epos );
      var tags = text.get_tags_in_range( spos, epos );
      set_cursor_only( _cursor - 1 );
      text.remove_text( spos, (epos - spos) );
      undo_buffer.add_delete( spos, str, tags, cur );
    }
  }

  //-------------------------------------------------------------
  // Handles a backspace to wordstart key event
  public void backspace_word( UndoTextBuffer undo_buffer ) {
    if( _cursor > 0 ) {
      var cur  = _cursor;
      var epos = text.text.index_of_nth_char( _cursor );
      var wpos = Utils.find_word( text.text, _cursor, true );
      wpos = (wpos == -1) ? 0 : text.text.char_count( wpos );
      var spos = text.text.index_of_nth_char( wpos );
      var str  = text.text.slice( spos, epos );
      var tags = text.get_tags_in_range( spos, epos );
      set_cursor_only( spos );
      text.remove_text( spos, (epos - spos) );
      undo_buffer.add_delete( spos, str, tags, cur );
      if( _selstart < wpos ) {
        change_selection( null, wpos, "backspace_word1" );
      } else if( _selend > cur ) {
        change_selection( wpos, (_selend - (cur - wpos)), "backspace_word2" );
      } else {
        change_selection( wpos, wpos, "backspace_word3" );
      }
    }
  }

  //-------------------------------------------------------------
  // Handles a delete key event
  public void delete( UndoTextBuffer undo_buffer ) {
    var cur = _cursor;
    if( _selstart != _selend ) {
      var spos = text.text.index_of_nth_char( _selstart );
      var epos = text.text.index_of_nth_char( _selend );
      var str  = text.text.slice( spos, epos );
      var tags = text.get_tags_in_range( spos, epos );
      set_cursor_only( _selstart );
      change_selection( null, _selstart, "delete" );
      text.remove_text( spos, (epos - spos) );
      undo_buffer.add_delete( spos, str, tags, cur );
    } else if( _cursor < text.text.char_count() ) {
      var spos = text.text.index_of_nth_char( _cursor );
      var epos = text.text.index_of_nth_char( _cursor + 1 );
      var str  = text.text.slice( spos, epos );
      var tags = text.get_tags_in_range( spos, epos );
      text.remove_text( spos, (epos - spos) );
      undo_buffer.add_delete( spos, str, tags, cur );
    }
  }

  //-------------------------------------------------------------
  // Deletes all characters in the given range
  public void delete_range( int startpos, int endpos, UndoTextBuffer undo_buffer ) {
    var cur  = _cursor;
    var spos = text.text.index_of_nth_char( startpos );
    var epos = text.text.index_of_nth_char( endpos );
    var str  = text.text.slice( spos, epos );
    var tags = text.get_tags_in_range( spos, epos );
    set_cursor_only( startpos );
    text.remove_text( spos, (epos - spos) );
    undo_buffer.add_delete( spos, str, tags, cur );
  }

  //-------------------------------------------------------------
  // Handles a delete to end of word key event
  public void delete_word( UndoTextBuffer undo_buffer ) {
    if( _cursor < text.text.length ) {
      var spos = text.text.index_of_nth_char( _cursor );
      var wpos = Utils.find_word( text.text, cursor, false );
      wpos = (wpos == -1) ? text.text.char_count() : text.text.char_count( wpos );
      var epos = text.text.index_of_nth_char( wpos );
      var str  = text.text.slice( spos, epos );
      var tags = text.get_tags_in_range( spos, epos );
      text.remove_text( spos, (epos - spos) );
      undo_buffer.add_delete( spos, str, tags, _cursor );
      if( _selstart < _cursor ) {
        change_selection( null, _cursor, "delete_word1" );
      } else if( _selend > wpos ) {
        change_selection( _cursor, (_selend - (wpos - _cursor)), "delete_word2" );
      } else {
        change_selection( _cursor, _cursor, "delete_word3" );
      }
    }
  }

  //-------------------------------------------------------------
  // Inserts the given string at the current cursor position and
  // adjusts cursor
  public void insert( string s, UndoTextBuffer undo_buffer ) {
    var slen = s.char_count();
    var cur  = _cursor;
    if( _selstart != _selend ) {
      var spos = text.text.index_of_nth_char( _selstart );
      var epos = text.text.index_of_nth_char( _selend );
      var str  = text.text.slice( spos, epos );
      var tags = text.get_tags_in_range( spos, epos );
      text.replace_text( spos, (epos - spos), s );
      set_cursor_only( _selstart + slen );
      change_selection( _cursor, _cursor, "insert A" );
      undo_buffer.add_replace( spos, str, s, tags, cur );
    } else {
      var cpos = text.text.index_of_nth_char( _cursor );
      text.insert_text( cpos, s );
      set_cursor_only( _cursor + slen );
      change_selection( _cursor, _cursor, "insert B" );
      undo_buffer.add_insert( cpos, s, cur );
    }
  }

  //-------------------------------------------------------------
  // Inserts the given string at the given position
  public void insert_at_pos( int start, string s, UndoTextBuffer undo_buffer ) {
    var slen = s.char_count();
    var cur  = _cursor;
    var spos = text.text.index_of_nth_char( start );
    text.insert_text( spos, s );
    if( start <= cursor ) {
      set_cursor_only( _cursor + slen );
    }
    change_selection( _cursor, _cursor, "insert_at_pos" );
    undo_buffer.add_insert( spos, s, cur );
  }

  //-------------------------------------------------------------
  // Inserts the given formatted text at the current cursor position
  public void insert_formatted_text( FormattedText t, UndoTextBuffer undo_buffer ) {
    var slen  = t.text.char_count();
    var ttags = t.get_tags_in_range( 0, slen );
    var cur   = _cursor;
    if( _selstart != _selend ) {
      var spos = text.text.index_of_nth_char( _selstart );
      var epos = text.text.index_of_nth_char( _selend );
      var str  = text.text.slice( spos, epos );
      var tags = text.get_tags_in_range( spos, epos );
      text.replace_text( spos, (epos - spos), t.text );
      for( int i=0; i<ttags.length; i++ ) {
        var ttag = ttags.index( i );
        var ftag = (FormatTag)ttag.tag;
        text.add_tag( ftag, (ttag.start + spos), (ttag.end + spos), ttag.parsed, ttag.extra );
      }
      set_cursor_only( _selstart + slen );
      change_selection( _cursor, _cursor, "insert_formatted_text A" );
      undo_buffer.add_replace( spos, str, t.text, tags, cur );
    } else {
      var cpos = text.text.index_of_nth_char( _cursor );
      text.insert_text( cpos, t.text );
      for( int i=0; i<ttags.length; i++ ) {
        var ttag = ttags.index( i );
        var ftag = (FormatTag)ttag.tag;
        text.add_tag( ftag, (ttag.start + cpos), (ttag.end + cpos), ttag.parsed, ttag.extra );
      }
      set_cursor_only( _cursor + slen );
      change_selection( _cursor, _cursor, "insert_formatted_text A" );
      undo_buffer.add_insert( cpos, t.text, cur );
    }
  }

  //-------------------------------------------------------------
  // Inserts a range of text messages
  public void insert_ranges( Array<InsertText?> its, UndoTextBuffer undo_buffer ) {
    var cur = _cursor;
    for( int i=(int)(its.length - 1); i>=0; i-- ) {
      var it   = its.index( i );
      var slen = it.text.char_count();
      text.insert_text( it.start, it.text );
      if( it.start < cursor ) {
        set_cursor_only( _cursor + slen );
      }
      if( it.start < selstart ) {
        change_selection( (_selstart + slen), (_selend + slen), "insert" );
      }
    }
    undo_buffer.add_inserts( its, cur );
  }

  //-------------------------------------------------------------
  // Replaces the given range with the specified string
  public void replace( int start, int end, string s, UndoTextBuffer undo_buffer ) {
    var slen = s.char_count();
    var cur  = _cursor;
    var str  = text.text.slice( start, end );
    var tags = text.get_tags_in_range( start, end );
    text.replace_text( start, (end - start), s );
    set_cursor_only( text.text.char_count( start ) + slen );
    change_selection( null, _selstart, "replace" );
    undo_buffer.add_replace( start, str, s, tags, cur );
  }

  //-------------------------------------------------------------
  // Returns the currently selected text or, if no text is
  // currently selected, returns null.
  public string? get_selected_text() {
    if( _selstart != _selend ) {
      var spos = text.text.index_of_nth_char( _selstart );
      var epos = text.text.index_of_nth_char( _selend );
      return( text.text.slice( spos, epos ) );
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the current cursor, selection start and selection
  // end values.
  public void get_cursor_info( out int cursor, out int start, out int end ) {
    cursor = _cursor;
    start  = _selstart;
    end    = _selend;
  }

  //-------------------------------------------------------------
  // Returns the current cursor position
  public void get_cursor_pos( out int x, out int ytop, out int ybot ) {
    var index = text.text.index_of_nth_char( _cursor );
    var rect  = _pango_layout.index_to_pos( index );
    x    = (int)(posx + (rect.x / Pango.SCALE));
    ytop = (int)(posy + (rect.y / Pango.SCALE));
    ybot = ytop + (int)(rect.height / Pango.SCALE);
  }

  //-------------------------------------------------------------
  // Returns the x and y position of the given character position
  public void get_char_pos( int pos, out double left, out double top, out double bottom, out int line ) {
    var index = text.text.index_of_nth_char( pos );
    var rect  = _pango_layout.index_to_pos( index );
    left   = posx + (rect.x / Pango.SCALE);
    top    = posy + (rect.y / Pango.SCALE);
    bottom = top + (rect.height / Pango.SCALE);
    int x_pos;
    _pango_layout.index_to_line_x( index, false, out line, out x_pos );
  }

  //-------------------------------------------------------------
  // Returns a populated FormattedText instance containing the
  // selected text range
  public FormattedText? get_selected_formatted_text( MindMap map ) {
    if( _selstart != _selend ) {
      var spos = text.text.index_of_nth_char( _selstart );
      var epos = text.text.index_of_nth_char( _selend );
      return( new FormattedText.copy_range( map, text, spos, epos ) );
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Add tag to selected area
  public void add_tag( FormatTag tag, string? extra, bool parsed, UndoTextBuffer undo_buffer ) {
    var spos = is_selected() ? text.text.index_of_nth_char( _selstart ) : 0;
    var epos = is_selected() ? text.text.index_of_nth_char( _selend )   : text.text.length;
    text.add_tag( tag, spos, epos, parsed, extra );
    undo_buffer.add_tag_add( spos, epos, tag, extra, parsed, _cursor );
  }

  //-------------------------------------------------------------
  // Removes the specified tag for the selected range
  public void remove_tag( FormatTag tag, UndoTextBuffer undo_buffer ) {
    string? extra  = null;
    bool    parsed = false;
    var spos   = is_selected() ? text.text.index_of_nth_char( _selstart ) : 0;
    var epos   = is_selected() ? text.text.index_of_nth_char( _selend )   : text.text.length;
    text.get_extra_parsed( tag, spos, out extra, out parsed );
    text.remove_tag( tag, spos, epos );
    undo_buffer.add_tag_remove( spos, epos, tag, extra, parsed, _cursor );
  }

  //-------------------------------------------------------------
  // Removes the specified tag for the selected range
  public void remove_all_tags( UndoTextBuffer undo_buffer ) {
    var spos = is_selected() ? text.text.index_of_nth_char( _selstart ) : 0;
    var epos = is_selected() ? text.text.index_of_nth_char( _selend )   : text.text.length;
    var tags = text.get_tags_in_range( spos, epos );
    text.remove_all_tags( spos, epos );
    undo_buffer.add_tag_clear( spos, epos, tags, _cursor );
  }

  //-------------------------------------------------------------
  // Call this method to change the current selection.  If a
  // parameter is specified as null, this selection index will
  // not change value.
  public void change_selection( int? selstart, int? selend, string? msg = null ) {

    if( _debug && (msg != null) ) {
      stdout.printf( "In change_selection, msg: %s\n", msg );
    }

    /* Get the selection state prior to changing it */
    var old_selected = (_selstart != _selend);

    /* Update the selection range */
    _selstart = selstart ?? _selstart;
    _selend   = selend   ?? _selend;

    /* Get the selection state after the change */
    var new_selected = (_selstart != _selend);

    /* Update the selection tag */
    if( new_selected ) {
      _text.replace_tag( FormatTag.SELECT, text.text.index_of_nth_char( _selstart ), text.text.index_of_nth_char( _selend ), false );
    } else if( old_selected ) {
      _text.remove_tag_all( FormatTag.SELECT );
    }

    /* Alert anyone listening if the selection mode changed */
    if( old_selected && !new_selected ) {
      select_mode( false );
    } else if( !old_selected && new_selected ) {
      select_mode( true );
    }

  }

  //-------------------------------------------------------------
  // Draws the node font to the screen
  public void draw( Cairo.Context ctx, Theme theme, RGBA fg, double alpha, bool copy_layout ) {

    var layout = _pango_layout;

    if( copy_layout ) {
      layout = _pango_layout.copy();
      layout.set_attributes( _text.get_attributes_from_theme( theme ) );
    }

    if( alpha < 1.0 ) {
      layout = _pango_layout.copy();
      var attrs      = layout.get_attributes();
      var alpha_val  = (uint16)(65536 * alpha);
      var alpha_attr = Pango.attr_foreground_alpha_new( alpha_val );
      alpha_attr.start_index = 0;
      alpha_attr.end_index   = _text.text.length;
      attrs.change( (owned)alpha_attr );
      layout.set_attributes( attrs );
    }

    Pango.Rectangle ink_rect, log_rect;
    layout.get_extents( out ink_rect, out log_rect );

    /* Output the text */
    ctx.move_to( (posx - (log_rect.x / Pango.SCALE)), posy );
    Utils.set_context_color_with_alpha( ctx, fg, alpha );
    Pango.cairo_show_layout( ctx, layout );
    ctx.new_path();

    /* Draw the insertion cursor if we are in the 'editable' state */
    if( edit && !copy_layout ) {
      var cpos = text.text.index_of_nth_char( _cursor );
      var rect = layout.index_to_pos( cpos );
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "text_cursor" ), alpha );
      double ix, iy;
      ix = (posx + (rect.x / Pango.SCALE) - 1) - (log_rect.x / Pango.SCALE);
      iy = posy + (rect.y / Pango.SCALE);
      ctx.rectangle( ix, iy, 1, (rect.height / Pango.SCALE) );
      ctx.fill();
    }

  }

}
