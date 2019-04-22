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

public class CanvasText : Object {

  /* Member variables */
  private   int          _cursor       = 0;   /* Location of the cursor when editing */
  private   int          _column       = 0;   /* Character column to use when moving vertically */
  private   Pango.Layout _pango_layout = null;
  private   int          _selstart     = 0;
  private   int          _selend       = 0;
  private   int          _selanchor    = 0;
  private   double       _min_width    = 50;
  private   double       _max_width    = 200;

  /* Signals */
  public signal void text_changed();
  public signal void resized( double diffw, double diffh );

  /* Properties */
  public string text   { get; set; default = ""; }
  public double posx   { get; set; default = 0; }
  public double posy   { get; set; default = 0; }
  public bool   markup { get; set; default = true; }
  public bool   edit   { get; set; default = false; }
  public Style  style  {
    get {
      return( _style );
    }
    set {
      if( _style.copy( value ) ) {
        _pango_layout.set_font_description( _style.node_font );
        _pango_layout.set_width( _style.node_width * Pango.SCALE );
        if( _layout != null ) {
          _layout.handle_update_by_edit( this );
        }
      }
    }
  }

  /* Default constructor */
  public CanvasText( DrawArea da ) {
    _pango_layout = da.create_pango_layout( null );
    _pango_layout.set_wrap( Pango.WrapMode.WORD_CHAR );
  }

  /* Constructor initializing string */
  public CanvasText.with_text( DrawArea da, string txt ) {
    text          = txt;
    _pango_layout = da.create_pango_layout( n );
    _pango_layout.set_wrap( Pango.WrapMode.WORD_CHAR );
  }

  /* Copies an existing CanvasText to this CanvasText */
  public CanvasText.copy( CanvasText ct ) {
    posx       = ct.posx;
    posy       = ct.posy;
    text       = ct.text;
    _min_width = ct._min_width;
    _max_width = ct._max_width;
  }

  /* Returns the maximum width allowed for this node */
  public int max_width() {
    return( (int)_max_width );
  }

  /* Returns true if the given coordinates are within the specified bounds */
  private bool is_within_bounds( double x, double y, double bx, double by, double bw, double bh ) {
    return( (bx < x) && (x < (bx + bw)) && (by < y) && (y < (by + bh)) );
  }

  /* Returns true if the given cursor coordinates lies within this node */
  public bool is_within( double x, double y ) {
    double cx, cy, cw, ch;
    bbox( out cx, out cy, out cw, out ch );
    return( is_within_bounds( x, y, cx, cy, cw, ch ) );
  }

  /* Loads the name value from the given XML node */
  private void load_text( Xml.Node* n ) {
    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      text = n->children->get_content();
    }
  }

  /* Loads the style information from the given XML node */
  private void load_style( Xml.Node* n ) {
    // TBD - _style.load_node( n );
    // TBD - _pango_layout.set_font_description( _style.node_font );
  }

  /* Loads the file contents into this instance */
  public virtual void load( DrawArea da, Xml.Node* n, bool isroot ) {

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

    /* Make sure the style has a default value */
    style.copy( StyleInspector.styles.get_style_for_level( isroot ? 0 : 1 ) );

  }

  /* Saves the current node */
  public virtual void save( Xml.Node* parent ) {
    parent->add_child( save_node() );
  }

  /* Saves the node contents to the given data output stream */
  protected Xml.Node* save_node() {

    Xml.Node* node = new Xml.Node( null, "text" );
    node->new_prop( "posx", posx.to_string() );
    node->new_prop( "posy", posy.to_string() );
    node->new_prop( "maxwidth", _max_width.to_string() );

    // TBD - style.save_node( node );

    // TBD - node->new_text_child( null, "nodename", name );

    return( node );

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
    return( (!(markup || edit) ? unmarkup( text ) : text );
  }

  /*
   Updates the width and height based on the current name.
  */
  public void update_size( Theme? theme, out double width_diff, out double height_diff ) {
    width_diff  = 0;
    height_diff = 0;
    if( _pango_layout != null ) {
      int text_width, text_height;
      double orig_width  = _width;
      double orig_height = _height;
      _pango_layout.set_markup( name_markup( theme ), -1 );
      _pango_layout.get_size( out text_width, out text_height );
      _width  = (text_width  / Pango.SCALE);
      _height = (text_height / Pango.SCALE);
      width_diff  = _width  - orig_width;
      height_diff = _height - orig_height;
      if( (width_diff != 0) || (height_diff != 0) ) {
        resized( width_diff, height_diff );
      }
    }
  }

  /* Resizes the node width by the given amount */
  public virtual void resize( double diff ) {
    if( (diff < 0) ? ((_max_width + diff) <= _min_width) : !_pango_layout.is_wrapped() ) return;
    _max_width += diff;
    _pango_layout.set_width( (int)_max_width * Pango.SCALE );
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
    int adjusted_x = (int)x * Pango.SCALE;
    int adjusted_y = (int)y * Pango.SCALE;
    if( _pango_layout.xy_to_index( adjusted_x, adjusted_y, out cursor, out trailing ) ) {
      var cindex = name.char_count( cursor + trailing );
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
    int img_height = (_image != null) ? (int)(_image.height + style.node_padding) : 0;
    int adjusted_x = (int)x * Pango.SCALE;
    int adjusted_y = (int)y * Pango.SCALE;
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
  private void clear_selection() {
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
    text_changed();
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
    text_changed();
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
    text_changed();
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

  /* Sets the context source color to the given color value */
  protected void set_context_color( Context ctx, RGBA color ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
  }

  /*
   Sets the context source color to the given color value overriding the
   alpha value with the given value.
  */
  protected void set_context_color_with_alpha( Context ctx, RGBA color, double alpha ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, alpha );
  }

  /* Draws the node font to the screen */
  public void draw( Cairo.Context ctx, Theme theme, bool motion ) {

    int    hmargin    = 3;
    int    vmargin    = 3;
    double img_height = (_image != null) ? (_image.height + style.node_padding) : 0;
    double width_diff, height_diff;

    /* Make sure the the size is up-to-date */
    update_size( theme, out width_diff, out height_diff );

    /* Get the widget of the task icon */
    double twidth = task_width();

    /* Draw the selection box around the text if the node is in the 'selected' state */
    if( mode == NodeMode.CURRENT ) {
      set_context_color_with_alpha( ctx, theme.nodesel_background, (motion ? 0.2 : 1) );
      ctx.rectangle( ((posx + style.node_padding + style.node_margin) - hmargin), ((posy + style.node_padding + style.node_margin) - vmargin), ((_width - (style.node_padding * 2) - (style.node_margin * 2)) + (hmargin * 2)), ((_height - (style.node_padding * 2) - (style.node_margin * 2)) + (vmargin * 2)) );
      ctx.fill();
    }

    /* Output the text */
    ctx.move_to( (posx + style.node_padding + style.node_margin + twidth), (posy + style.node_padding + style.node_margin + img_height) );
    switch( mode ) {
      case NodeMode.CURRENT  :  set_context_color( ctx, theme.nodesel_foreground );  break;
      default                :  set_context_color( ctx, (parent == null)    ? theme.root_foreground :
                                                        style.is_fillable() ? theme.background :
                                                                              theme.foreground );  break;
    }
    Pango.cairo_show_layout( ctx, _pango_layout );

    /* Draw the insertion cursor if we are in the 'editable' state */
    if( mode == NodeMode.EDITABLE ) {
      var cpos = name.index_of_nth_char( _cursor );
      var rect = _pango_layout.index_to_pos( cpos );
      set_context_color( ctx, (style.is_fillable() ? theme.background : theme.text_cursor) );
      double ix, iy;
      ix = (posx + style.node_padding + style.node_margin + twidth) + (rect.x / Pango.SCALE) - 1;
      iy = (posy + style.node_padding + style.node_margin + img_height) + (rect.y / Pango.SCALE);
      ctx.rectangle( ix, iy, 1, (rect.height / Pango.SCALE) );
      ctx.fill();
    }

  }

}
