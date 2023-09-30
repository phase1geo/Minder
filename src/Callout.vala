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
  EDITABLE;    // Specifies that this text is actively being edited

  public bool is_selected() {
    return( this == SELECTED );
  }
}

public class Callout {

  private Node        _node;
  private Style       _style;
  private CanvasText  _text;
  private CalloutMode _mode = CalloutMode.NONE;

  public signal void resized();

  public CanvasText text {
    get {
      return( _text );
    }
  }
  public double total_width {
    get {
      var padding = _style.callout_padding    ?? 0;
      var plength = _style.callout_ptr_length ?? 0;
      if( is_above_node() ) {
        return( _text.width + (padding * 2) );
      } else {
        return( _text.width + (padding * 2) + plength );
      }
    }
  }
  public double total_height {
    get {
      var padding = _style.callout_padding    ?? 0;
      var plength = _style.callout_ptr_length ?? 0;
      if( is_above_node() ) {
        return( _text.height + (padding * 2) + plength );
      } else {
        return( _text.height + (padding * 2) );
      }
    }
  }
  public CalloutMode mode {
    get {
      return( _mode );
    }
    set {
      if( _mode != value ) {
        _mode = value;
        if( _mode == CalloutMode.EDITABLE ) {
          _text.edit = true;
          _text.set_cursor_all( false );
        } else {
          _text.edit = false;
          _text.clear_selection();
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
        _text.max_width = style.node_width;
        position_text();
        resized();
      }
    }
  }

  /* Default constructor */
  public Callout( Node node ) {
    _node = node;
    _text = new CanvasText.with_text( node.da, _( "Callout" ) );
    _text.resized.connect( position_text );
    _style = new Style();
  }

  /* Returns true if the callout should be drawn above the node; otherwise, we draw it to the right of the node */
  private bool is_above_node() {
    return( (_node.side & NodeSide.horizontal()) != 0 );
  }

  /* Called whenever the text changes the size of the callout */
  public void position_text() {

    var margin  = style.node_margin     ?? 0;
    var padding = style.callout_padding ?? 0;
    var plength = style.callout_ptr_length ?? 0;

    double nx, ny, nw, nh;
    _node.node_bbox( out nx, out ny, out nw, out nh );

    if( is_above_node() ) {
      _text.posx = nx + margin + padding;
      _text.posy = ny - plength - padding - _text.height;
    } else {
      _text.posx = nx + nw + plength + padding;
      _text.posy = ny + margin + padding;
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

  /* Returns true if the given coordinates are within this callout */
  public bool contains( double x, double y ) {
    double cx, cy, cw, ch;
    bbox( out cx, out cy, out cw, out ch );
    return( Utils.is_within_bounds( x, y, cx, cy, cw, ch ) );
  }

  /* Saves the callout information in XML format */
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "callout" );
    node->add_child( _text.save( "text" ) );
    style.save_callout( node ); 
    return( node );
  }

  /* Loads the style information from the given XML node */
  private void load_style( Xml.Node* n ) {
    _style.load_node( n );
    _text.set_font( _style.callout_font.get_family(), (_style.callout_font.get_size() / Pango.SCALE) );
  }

  /* Loads the callback information from XML format */
  public void load( Xml.Node* node ) {

    /* Make sure the style has a default value */
    _style.copy( StyleInspector.styles.get_style_for_level( (_node.is_root() ? 0 : 1), null ) );

    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "callout-text") ) {
        switch( it->name ) {
          case "text"  :  _text.load( it );  break;
          case "style" :  load_style( it );  break;
        }
      }
    }

  }

  /* Draws this callout to the screen */
  public void draw( Context ctx, Theme theme, bool exporting ) {

    var background = theme.get_color( "callout_background" );
    var foreground = Granite.contrasting_foreground_color( background );
    var pwidth     = style.callout_ptr_width  ?? 0;
    var plength    = style.callout_ptr_length ?? 0;

    if( mode == CalloutMode.SELECTED ) {
      background = theme.get_color( "nodesel_background" );
      foreground = theme.get_color( "nodesel_foreground" );
    }

    Utils.set_context_color_with_alpha( ctx, background, _node.alpha );
    ctx.set_line_width( 1 );

    double x, y, w, h;
    bbox( out x, out y, out w, out h );

    /* Draw the shape */
    if( is_above_node() ) {
      ctx.move_to( x, y );
      ctx.line_to( (x + w), y );
      ctx.line_to( (x + w), (y + h) );
      ctx.line_to( (x + pwidth), (y + h) );
      ctx.line_to( (x + (pwidth / 2)), (y + h + plength) );
      ctx.line_to( x, (y + h) );
    } else {
      ctx.move_to( x, y );
      ctx.move_to( (x + w), y );
      ctx.move_to( (x + w), (y + h) );
      ctx.move_to( x, (y + h) );
      ctx.move_to( (x - plength), (y + (pwidth / 2)) );
    }
    ctx.close_path();
    ctx.fill();

    /* Draw the text */
    _text.draw( ctx, theme, foreground, _node.alpha, exporting );

  }

}
