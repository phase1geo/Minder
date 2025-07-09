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

using Cairo;

public enum CalloutMode {
  NONE = 0,    // Specifies that this callout is not the current callout
  SELECTED,    // Specifies that this callout is currently selected
  EDITABLE,    // Specifies that this text is actively being edited
  HIDING,      // Specifies that the callout should be drawn but not be a part of its node's treebox
  HIDDEN;      // Specifies that the callout should not be drawn

  public bool is_selected() {
    return( this == SELECTED );
  }

  public bool is_disconnected() {
    return( (this == HIDING) || (this == HIDDEN) );
  }

}

public class Callout : Object {

  private Node        _node;
  private Style       _style;
  private CanvasText  _text;
  private CalloutMode _mode = CalloutMode.NONE;

  public signal void resized();

  public Node node {
    get {
      return( _node );
    }
  }
  public CanvasText text {
    get {
      return( _text );
    }
  }
  public double total_width {
    get {
      if( _mode.is_disconnected() ) {
        return( 0 );
      } else {
        var padding = _style.callout_padding    ?? 0;
        var plength = _style.callout_ptr_length ?? 0;
        if( is_below_node() ) {
          return( _text.width + (padding * 2) );
        } else {
          return( _text.width + (padding * 2) + plength );
        }
      }
    }
  }
  public double total_height {
    get {
      if( _mode.is_disconnected() ) {
        return( 0 );
      } else {
        var padding = _style.callout_padding    ?? 0;
        var plength = _style.callout_ptr_length ?? 0;
        if( is_below_node() ) {
          return( _text.height + (padding * 2) + plength );
        } else {
          return( _text.height + (padding * 2) );
        }
      }
    }
  }
  public CalloutMode mode {
    get {
      return( _mode );
    }
    set {
      if( _mode != value ) {
        var orig_mode = _mode;
        _mode = value;
        if( _mode == CalloutMode.EDITABLE ) {
          _text.edit = true;
          _text.set_cursor_all( false );
        } else {
          _text.edit = false;
          _text.clear_selection();
        }
        if( orig_mode.is_disconnected() || value.is_disconnected() ) {
          resized();
        }
      }
    }
  }
  public Style style {
    get {
      return( _style );
    }
    set {
      if( _style.copy( value ) ) {
        _text.set_font( _style.callout_font.get_family(), (_style.callout_font.get_size() / Pango.SCALE) );
        _text.set_text_alignment( _style.callout_text_align );
        _text.max_width = style.node_width;
        position_text( true );
        resized();
      }
    }
  }
  public double alpha { set; get; default = 1.0; }

  //-------------------------------------------------------------
  // Default constructor.
  public Callout( Node node ) {
    _node = node;
    _text = new CanvasText.with_text( node.map, _( "Callout" ) );
    _text.resized.connect( position_text_from_ct );
    _style = new Style();
    set_parsers();
  }

  //-------------------------------------------------------------
  // Adds the valid parsers.
  public void set_parsers() {
    _text.text.add_parser( _node.map.da.markdown_parser );
    _text.text.add_parser( _node.map.da.url_parser );
    _text.text.add_parser( _node.map.da.unicode_parser );
  }

  //-------------------------------------------------------------
  // Returns true if the callout should be drawn below the node;
  // otherwise, we draw it to the right of the node.
  private bool is_below_node() {
    return( _node.side.horizontal() );
  }

  //-------------------------------------------------------------
  // Called if the text has been changed from the CanvasText
  // perspective.
  private void position_text_from_ct() {
    position_text( true );
  }

  //-------------------------------------------------------------
  // Called whenever the text changes the size of the callout.
  public void position_text( bool call_resized ) {

    var margin  = _node.style.node_margin ?? 0;
    var padding = style.callout_padding ?? 0;
    var plength = style.callout_ptr_length ?? 0;

    double nx, ny, nw, nh;
    _node.node_bbox( out nx, out ny, out nw, out nh );

    if( is_below_node() ) {
      _text.posx = nx + margin + padding;
      _text.posy = (ny + nh - margin) + (plength + padding);
    } else {
      _text.posx = (nx + nw - margin) + (plength + padding);
      _text.posy = ny + margin + padding;
    }

    if( call_resized ) {
      resized();
    }

  }

  /* Returns the bounding box of this callout (minus the pointer) */
  public void bbox( out double x, out double y, out double w, out double h ) {
    var padding = style.callout_padding ?? 0;
    x = _text.posx - padding;
    y = _text.posy - padding;
    w = _text.width + (padding * 2);
    h = _text.height + (padding * 2);
  }

  /* Returns the bounding box of the resizer */
  private void resizer_bbox( out double x, out double y, out double w, out double h ) {

    double cx, cy, cw, ch;
    bbox( out cx, out cy, out cw, out ch );

    x = _node.resizer_on_left() ? cx : (cx + cw - 8);
    y = cy;
    w = 8;
    h = 8;

  }

  //-------------------------------------------------------------
  // Returns true if the given coordinates are within this callout.
  public bool contains( double x, double y ) {
    double cx, cy, cw, ch;
    bbox( out cx, out cy, out cw, out ch );
    return( Utils.is_within_bounds( x, y, cx, cy, cw, ch ) );
  }

  //-------------------------------------------------------------
  // Returns true if the pixel coordinates is within the resizer.
  public bool is_within_resizer( double x, double y ) {
    if( mode == CalloutMode.SELECTED ) {
      double rx, ry, rw, rh;
      resizer_bbox( out rx, out ry, out rw, out rh );
      return( Utils.is_within_bounds( x, y, rx, ry, rw, rh ) );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if the given coordinates lies within the callout
  // text.
  public bool is_within_title( double x, double y ) {
    return( (_text != null) && _text.is_within( x, y ) );
  }

  //-------------------------------------------------------------
  // Resizes the width (and potentially height).
  public void resize( double diff ) {
    diff = _node.resizer_on_left() ? (0 - diff) : diff;
    _text.resize( diff );
  }

  //-------------------------------------------------------------
  // Saves the callout information in XML format.
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "callout" );
    node->add_child( _text.save( "text" ) );
    style.save_callout( node ); 
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the style information from the given XML node.
  private void load_style( Xml.Node* n ) {
    _style.load_node( n );
    _text.set_font( _style.callout_font.get_family(), (_style.callout_font.get_size() / Pango.SCALE) );
  }

  //-------------------------------------------------------------
  // Loads the callback information from XML format.
  public void load( Xml.Node* node ) {

    /* Make sure the style has a default value */
    _style.copy( StyleInspector.styles.get_style_for_level( (_node.is_root() ? 0 : 1), null ) );

    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "text"  :  _text.load( it );  break;
          case "style" :  load_style( it );  break;
        }
      }
    }

  }

  //-------------------------------------------------------------
  // Draws this callout to the screen.
  public void draw( Context ctx, Theme theme, bool exporting ) {

    if( _mode == CalloutMode.HIDDEN ) return;

    var background = theme.get_color( "callout_background" );
    var foreground = Granite.contrasting_foreground_color( background );
    var pwidth     = style.callout_ptr_width  ?? 0;
    var plength    = style.callout_ptr_length ?? 0;
    var padding    = style.callout_padding    ?? 0;

    if( (mode == CalloutMode.SELECTED) && !exporting ) {
      background = theme.get_color( "nodesel_background" );
      foreground = theme.get_color( "nodesel_foreground" );
    }

    Utils.set_context_color_with_alpha( ctx, background, alpha );
    ctx.set_line_width( 1 );

    double x, y, w, h;
    bbox( out x, out y, out w, out h );

    /* Draws a rounded rectangle on the given context */
    Utils.draw_rounded_rectangle( ctx, x, y, w, h, padding );
    ctx.fill();

    /* Draw the shape */
    if( is_below_node() ) {
      y++;
      ctx.move_to( (x + padding), y );
      ctx.line_to( (x + padding), (y - plength) );
      ctx.line_to( (x + padding + pwidth), y );
    } else {
      x++;
      ctx.move_to( x, (y + padding) );
      ctx.line_to( (x - plength), (y + padding) );
      ctx.line_to( x, (y + padding + pwidth) );
    }
    ctx.close_path();
    ctx.fill();

    /* Draw resizer, if necessary */
    if( (mode == CalloutMode.SELECTED) && !exporting ) {

      resizer_bbox( out x, out y, out w, out h );

      Utils.set_context_color( ctx, theme.get_color( "background" ) );
      ctx.set_line_width( 1 );
      ctx.rectangle( x, y, w, h );
      ctx.fill_preserve();

      Utils.set_context_color_with_alpha( ctx, theme.get_color( "foreground" ), alpha );
      ctx.stroke();

    }

    /* Draw the text */
    _text.draw( ctx, theme, foreground, alpha, exporting );

  }

}
