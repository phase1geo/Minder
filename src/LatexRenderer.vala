/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation; either version 2 of
* the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

using Cairo;
using Gdk;
using Gee;
using GLib;

//-------------------------------------------------------------
// Renders $...$ and $$...$$ spans as inline Pango shapes while leaving all
// ordinary and Markdown-formatted text in the normal Pango layout.
public class LatexRenderer : Object {

  private class LatexImage : Object {
    public Cairo.Surface surface { get; private set; }
    public double        width   { get; private set; }
    public double        ascent  { get; private set; }
    public double        descent { get; private set; }
    public LatexImage( Cairo.Surface surface, double width, double ascent, double descent ) {
      this.surface = surface;
      this.width   = width;
      this.ascent  = ascent;
      this.descent = descent;
    }
  }

  private class LatexSpan : Object {
    public int         start      { get; private set; }
    public int         end        { get; private set; }
    public string      expression { get; private set; }
    public string      key        { get; private set; }
    public double      font_size  { get; private set; }
    public LatexImage? image      { get; set; default = null; }
    public LatexSpan( int start, int end, string expression, string key, double font_size ) {
      this.start      = start;
      this.end        = end;
      this.expression = expression;
      this.key        = key;
      this.font_size  = font_size;
    }
  }

  private class ShapeData : Object {
    public LatexRenderer owner { get; private set; }
    public LatexImage?   image { get; private set; }
    public bool          draw  { get; private set; }
    public ShapeData( LatexRenderer owner, LatexImage? image, bool draw ) {
      this.owner = owner;
      this.image = image;
      this.draw  = draw;
    }
  }

  private const int    MAX_SOURCE_LENGTH = 16384;
  private const int    MAX_CACHE_ITEMS   = 128;
  private const double LASEM_BASE_SIZE   = 12.0;        // Lasem lays formulas out at 12pt
  private const double CSS_PX_PER_PT     = 96.0 / 72.0;

  private static HashMap<string,LatexImage>? _cache = null;

  private Array<LatexSpan> _spans;
  private Array<int>       _escaped_dollars;
  private string           _source       = "";
  private int              _font_size    = 12;
  private double           _draw_red     = 0.0;
  private double           _draw_green   = 0.0;
  private double           _draw_blue    = 0.0;
  private double           _draw_alpha   = 1.0;

  // Kept so existing listeners still compile.  Rendering is now synchronous,
  // so this is no longer emitted.
  public signal void changed();

  //-------------------------------------------------------------
  // Default constructor.
  public LatexRenderer() {
    _spans           = new Array<LatexSpan>();
    _escaped_dollars = new Array<int>();
    if( _cache == null ) {
      _cache = new HashMap<string,LatexImage>();
    }
  }

  //-------------------------------------------------------------
  // Installs the one shape callback used by this Pango context.
  public void attach( Pango.Context context ) {
    Pango.cairo_context_set_shape_renderer( context, draw_shape );
  }

  //-------------------------------------------------------------
  // Updates the list of inline formulas and starts missing renders.
  public void update( FormattedText formatted, int font_size ) {
    var source = formatted.text;
    var size   = int.max( 6, font_size );
    if( (source == _source) && (size == _font_size) ) {
      return;
    }

    cancel();
    _source    = source;
    _font_size = size;

    if( source.length > MAX_SOURCE_LENGTH ) {
      return;
    }

    var offset = 0;
    while( offset < source.length ) {
      int start, close, delimiter_length;
      if( !LatexSpanParser.find_span(
            source, offset, out start, out close, out delimiter_length
          ) ) {
        break;
      }
      var end        = close + delimiter_length;
      var expression = source.substring(
        start + delimiter_length,
        close - start - delimiter_length
      ).strip();
      if( expression == "" ) {
        offset = end;
        continue;
      }

      // Markdown code spans remain ordinary text, including any dollar signs.
      if( !formatted.is_tag_applied_at_index( FormatTag.CODE, start ) ) {
        var span_size = Math.fmax( 6.0, size * formatted.get_font_scale_at_index( start ) );
        var key       = "%.2f\x1f%s".printf( span_size, expression );
        var span      = new LatexSpan( start, end, expression, key, span_size );
        if( _cache.has_key( key ) ) {
          span.image = _cache.get( key );
        }
        _spans.append_val( span );
      }
      offset = end;
    }

    offset = source.index_of( "$" );
    while( offset != -1 ) {
      if( LatexSpanParser.is_escaped_dollar( source, offset ) &&
          !LatexSpanParser.is_latex_at( source, offset ) ) {
        var escape = offset - 1;
        _escaped_dollars.append_val( escape );
      }
      offset = source.index_of( "$", offset + 1 );
    }

    // Rendering takes milliseconds, so do it inline.  A span that fails to
    // render (bad syntax) keeps its source text visible, as before.
    for( int i=0; i<_spans.length; i++ ) {
      var span = _spans.index( i );
      if( span.image == null ) {
        span.image = render_formula( span );
      }
    }
  }

  //-------------------------------------------------------------
  // Adds inline formula shapes to a normal Pango attribute list.
  public void apply_attributes( string source, ref Pango.AttrList attrs ) {
    for( int i=0; i<_spans.length; i++ ) {
      var span = _spans.index( i );
      if( span.image == null ) {
        continue;
      }

      var first_end = span.start;
      unichar first_character;
      if( !source.get_next_char( ref first_end, out first_character ) || (first_end > span.end) ) {
        continue;
      }

      var width   = (int)Math.ceil( span.image.width * Pango.SCALE );
      var ascent  = (int)Math.ceil( span.image.ascent * Pango.SCALE );
      var descent = (int)Math.ceil( span.image.descent * Pango.SCALE );
      Pango.Rectangle rectangle = {0, -ascent, width, ascent + descent};
      var visible_data = new ShapeData( this, span.image, true );
      var visible = new Pango.AttrShape<ShapeData>.with_data(
        rectangle, rectangle, visible_data, copy_shape_data
      );
      visible.start_index = (uint)span.start;
      visible.end_index   = (uint)first_end;
      attrs.insert( (owned)visible );

      // The first character owns the formula width and drawing.  The rest of
      // the source is replaced by zero-width shapes, preserving byte offsets.
      if( first_end < span.end ) {
        Pango.Rectangle hidden_rectangle = {0, 0, 0, 0};
        var hidden_data = new ShapeData( this, null, false );
        var hidden = new Pango.AttrShape<ShapeData>.with_data(
          hidden_rectangle, hidden_rectangle, hidden_data, copy_shape_data
        );
        hidden.start_index = (uint)first_end;
        hidden.end_index   = (uint)span.end;
        attrs.insert( (owned)hidden );
      }

      var no_breaks = Pango.attr_allow_breaks_new( false );
      no_breaks.start_index = (uint)span.start;
      no_breaks.end_index   = (uint)span.end;
      attrs.insert( (owned)no_breaks );

      var no_hyphens = Pango.attr_insert_hyphens_new( false );
      no_hyphens.start_index = (uint)span.start;
      no_hyphens.end_index   = (uint)span.end;
      attrs.insert( (owned)no_hyphens );
    }

    for( int i=0; i<_escaped_dollars.length; i++ ) {
      var start = _escaped_dollars.index( i );
      Pango.Rectangle hidden_rectangle = {0, 0, 0, 0};
      var hidden_data = new ShapeData( this, null, false );
      var hidden = new Pango.AttrShape<ShapeData>.with_data(
        hidden_rectangle, hidden_rectangle, hidden_data, copy_shape_data
      );
      hidden.start_index = (uint)start;
      hidden.end_index   = (uint)(start + 1);
      attrs.insert( (owned)hidden );
    }
  }

  //-------------------------------------------------------------
  // Stores the color used by the next Pango draw operation.
  public void prepare_draw( RGBA color, double alpha ) {
    _draw_red   = color.red;
    _draw_green = color.green;
    _draw_blue  = color.blue;
    _draw_alpha = alpha;
  }

  //-------------------------------------------------------------
  // Copies the data attached to a shape when Pango copies a layout.
  private static ShapeData copy_shape_data( ShapeData data ) {
    return( new ShapeData( data.owner, data.image, data.draw ) );
  }

  //-------------------------------------------------------------
  // Draws an inline SVG at the current Pango baseline.
  private static void draw_shape( Cairo.Context ctx, Pango.AttrShape attribute, bool do_path ) {
    unowned Pango.AttrShape<ShapeData> shape = (Pango.AttrShape<ShapeData>)attribute;
    var data = shape.data;
    if( do_path || !data.draw || (data.image == null) ) {
      return;
    }
    data.owner.draw_image( ctx, data.image );
  }

  //-------------------------------------------------------------
  // Draws the cached formula at the current Pango baseline.  The formula is
  // stored as a vector recording; using it as a mask lets us paint it in the
  // current text color and alpha without re-rendering.
  private void draw_image( Cairo.Context ctx, LatexImage image ) {
    double x, baseline;
    ctx.get_current_point( out x, out baseline );
    ctx.save();
    ctx.set_source_rgba( _draw_red, _draw_green, _draw_blue, _draw_alpha );
    ctx.mask_surface( image.surface, x, baseline - image.ascent );
    ctx.restore();
  }

  //-------------------------------------------------------------
  // Forgets the current spans.
  private void cancel() {
    _spans.remove_range( 0, _spans.length );
    _escaped_dollars.remove_range( 0, _escaped_dollars.length );
  }

  //-------------------------------------------------------------
  // The itex converter rejects bare < and > (it wants \lt and \gt) and does
  // not know the amsmath align environment (aligned is equivalent here).
  private static string prepare_itex( string expression ) {
    var builder = new StringBuilder();
    unichar prev = 0;
    unichar c;
    for( int i = 0; expression.get_next_char( ref i, out c ); ) {
      if( (c == '<') && (prev != '\\') ) {
        builder.append( "\\lt " );
      } else if( (c == '>') && (prev != '\\') ) {
        builder.append( "\\gt " );
      } else {
        builder.append_unichar( c );
      }
      prev = c;
    }
    return( builder.str
      .replace( "\\begin{align*}", "\\begin{aligned}" )
      .replace( "\\end{align*}",   "\\end{aligned}" )
      .replace( "\\begin{align}",  "\\begin{aligned}" )
      .replace( "\\end{align}",    "\\end{aligned}" ) );
  }

  //-------------------------------------------------------------
  // Lays out one formula with Lasem and records it as a vector surface.
  // Returns null if the expression cannot be parsed.
  private static LatexImage? render_formula( LatexSpan span ) {
    try {
      // \displaystyle matches the previous LaTeX pipeline (limits above and
      // below sums, full-size fractions).
      var doc = Lsm.MathmlDocument.from_itex( "$\\displaystyle " + prepare_itex( span.expression ) + "$" );
      if( doc == null ) {
        return( null );
      }

      // Lasem measures in points at a 12pt base size.  Its resolution scales
      // the result, so choose it to land on the requested size in CSS pixels.
      var view  = new Lsm.MathmlView( doc );
      var ppi   = 72.0 * (span.font_size * CSS_PX_PER_PT) / LASEM_BASE_SIZE;
      var scale = ppi / 72.0;
      view.set_resolution( ppi );

      double width_pt, height_pt, baseline_pt;
      view.get_size( out width_pt, out height_pt, out baseline_pt );
      if( (width_pt <= 0.0) || (height_pt <= 0.0) ) {
        return( null );
      }

      var surface = new Cairo.RecordingSurface( Cairo.Content.COLOR_ALPHA, null );
      var ctx     = new Cairo.Context( surface );
      view.render( ctx, 0, 0 );

      var image = new LatexImage(
        surface,
        width_pt * scale,
        baseline_pt * scale,
        (height_pt - baseline_pt) * scale
      );
      if( _cache.size >= MAX_CACHE_ITEMS ) {
        _cache.clear();
      }
      _cache.set( span.key, image );
      return( image );
    } catch( Error e ) {
      debug( "Unable to render LaTeX '%s': %s", span.expression, e.message );
      return( null );
    }
  }

}
