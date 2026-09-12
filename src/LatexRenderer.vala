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
// Renders $$...$$ spans as inline Pango shapes while leaving all
// ordinary and Markdown-formatted text in the normal Pango layout.
public class LatexRenderer : Object {

  private class LatexImage : Object {
    public Rsvg.Handle handle        { get; private set; }
    public double      width         { get; private set; }
    public double      ascent        { get; private set; }
    public double      descent       { get; private set; }
    public double      render_width  { get; private set; }
    public double      render_height { get; private set; }
    public LatexImage( Rsvg.Handle handle, double width, double ascent, double descent,
                       double render_width, double render_height ) {
      this.handle        = handle;
      this.width         = width;
      this.ascent        = ascent;
      this.descent       = descent;
      this.render_width  = render_width;
      this.render_height = render_height;
    }
  }

  private class LatexSpan : Object {
    public int         start      { get; private set; }
    public int         end        { get; private set; }
    public string      expression { get; private set; }
    public string      key        { get; private set; }
    public double      font_size  { get; private set; }
    public LatexImage? image      { get; set; default = null; }
    public Subprocess? process    { get; set; default = null; }
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

  private class RenderJob : Object {
    public LatexRenderer owner      { get; private set; }
    public LatexSpan     span       { get; private set; }
    public int           generation { get; private set; }
    public string        latex      { get; private set; }
    public string        dvisvgm    { get; private set; }
    public RenderJob( LatexRenderer owner, LatexSpan span, int generation,
                      string latex, string dvisvgm ) {
      this.owner      = owner;
      this.span       = span;
      this.generation = generation;
      this.latex      = latex;
      this.dvisvgm    = dvisvgm;
    }
  }

  private const int MAX_SOURCE_LENGTH = 16384;
  private const int MAX_CACHE_ITEMS   = 128;
  private const int COMMAND_TIMEOUT   = 10;
  private const int MAX_ACTIVE_JOBS   = 2;

  private static HashMap<string,LatexImage>? _cache = null;
  private static GLib.Queue<RenderJob>?       _render_queue = null;
  private static int                          _active_jobs  = 0;

  private Array<LatexSpan> _spans;
  private string           _source       = "";
  private int              _font_size    = 12;
  private int              _generation   = 0;
  private double           _draw_red     = 0.0;
  private double           _draw_green   = 0.0;
  private double           _draw_blue    = 0.0;
  private double           _draw_alpha   = 1.0;

  public signal void changed();

  //-------------------------------------------------------------
  // Default constructor.
  public LatexRenderer() {
    _spans = new Array<LatexSpan>();
    if( _cache == null ) {
      _cache = new HashMap<string,LatexImage>();
    }
    if( _render_queue == null ) {
      _render_queue = new GLib.Queue<RenderJob>();
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
      var start = LatexSpanParser.find_delimiter( source, offset );
      if( start == -1 ) {
        break;
      }
      var close = LatexSpanParser.find_delimiter( source, start + 2 );
      if( close == -1 ) {
        break;
      }
      var end        = close + 2;
      var expression = source.substring( start + 2, close - start - 2 ).strip();
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

    var latex   = Environment.find_program_in_path( "latex" );
    var dvisvgm = Environment.find_program_in_path( "dvisvgm" );
    if( (latex == null) || (dvisvgm == null) ) {
      return;
    }

    for( int i=0; i<_spans.length; i++ ) {
      var span = _spans.index( i );
      if( span.image == null ) {
        _render_queue.push_tail( new RenderJob( this, span, _generation, latex, dvisvgm ) );
      }
    }
    dispatch_jobs();
  }

  //-------------------------------------------------------------
  // Starts queued jobs without allowing a large document to launch
  // an unbounded number of TeX processes at once.
  private static void dispatch_jobs() {
    while( (_active_jobs < MAX_ACTIVE_JOBS) && !_render_queue.is_empty() ) {
      var job = _render_queue.pop_head();
      if( (job.generation == job.owner._generation) && (job.span.image == null) ) {
        start_job( job );
      }
    }
  }

  //-------------------------------------------------------------
  // Runs one queued job and releases its slot on completion.
  private static void start_job( RenderJob job ) {
    _active_jobs++;
    job.owner.render.begin(
      job.span, job.generation, job.latex, job.dvisvgm,
      (obj, result) => {
        job.owner.render.end( result );
        _active_jobs--;
        dispatch_jobs();
      }
    );
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
  // Draws the image represented by a shape callback.
  private void draw_image( Cairo.Context ctx, LatexImage image ) {
    double x, baseline;
    ctx.get_current_point( out x, out baseline );
    var y     = baseline - image.render_height + image.descent;
    var red   = (int)(_draw_red   * 255.0);
    var green = (int)(_draw_green * 255.0);
    var blue  = (int)(_draw_blue  * 255.0);
    var css   = "* { fill: rgb(%d, %d, %d) !important; }".printf( red, green, blue );

    try {
      image.handle.set_stylesheet( css.data );
      Rsvg.Rectangle viewport = {x, y, image.render_width, image.render_height};
      ctx.save();
      if( _draw_alpha < 1.0 ) {
        ctx.push_group();
      }
      image.handle.render_document( ctx, viewport );
      if( _draw_alpha < 1.0 ) {
        ctx.pop_group_to_source();
        ctx.paint_with_alpha( _draw_alpha );
      }
      ctx.restore();
    } catch( Error e ) {
      warning( "Unable to draw inline LaTeX: %s", e.message );
    }
  }

  //-------------------------------------------------------------
  // Cancels active renders and invalidates their callbacks.
  private void cancel() {
    _generation++;
    for( int i=0; i<_spans.length; i++ ) {
      var process = _spans.index( i ).process;
      if( process != null ) {
        process.force_exit();
      }
    }
    _spans.remove_range( 0, _spans.length );
  }

  //-------------------------------------------------------------
  // Creates a small document containing exactly one math expression.
  private static string make_document( string expression, double font_size ) {
    var line_height = font_size * 1.2;
    return( """\documentclass{article}
\usepackage{amsmath}
\usepackage{amssymb}
\pagestyle{empty}
\begin{document}
\fontsize{%.2fpt}{%.2fpt}\selectfont
\setbox0=\hbox{\(\displaystyle
%s
\)}
\typeout{MINDER-METRICS:\number\wd0,\number\ht0,\number\dp0}
\noindent\box0
\end{document}
""".printf( font_size, line_height, expression ) );
  }

  //-------------------------------------------------------------
  // Reads TeX box dimensions from the renderer log and converts
  // scaled points to the CSS pixels used by librsvg at 96 DPI.
  private static bool parse_metrics( string log, out double width,
                                     out double ascent, out double descent ) {
    const string prefix = "MINDER-METRICS:";
    width = ascent = descent = 0.0;
    var start = log.index_of( prefix );
    if( start == -1 ) {
      return( false );
    }
    start += prefix.length;
    var end = log.index_of( "\n", start );
    var line = ((end == -1) ? log.substring( start ) : log.substring( start, end - start )).strip();
    var values = line.split( "," );
    if( (values.length != 3) ||
        !Regex.match_simple( "^[0-9]+$", values[0] ) ||
        !Regex.match_simple( "^[0-9]+$", values[1] ) ||
        !Regex.match_simple( "^[0-9]+$", values[2] ) ) {
      return( false );
    }

    const double SP_TO_CSS_PIXEL = 96.0 / (72.27 * 65536.0);
    width   = int64.parse( values[0] ) * SP_TO_CSS_PIXEL;
    ascent  = int64.parse( values[1] ) * SP_TO_CSS_PIXEL;
    descent = int64.parse( values[2] ) * SP_TO_CSS_PIXEL;
    return( (width > 0.0) && ((ascent + descent) > 0.0) );
  }

  //-------------------------------------------------------------
  // Runs LaTeX and dvisvgm for one formula span.
  private async void render( LatexSpan span, int generation, string latex, string dvisvgm ) {
    string? temp_dir = null;
    try {
      temp_dir = DirUtils.make_tmp( "minder-latex-XXXXXX" );
      var tex_file = GLib.Path.build_filename( temp_dir, "formula.tex" );
      FileUtils.set_contents( tex_file, make_document( span.expression, span.font_size ) );

      string command_error;
      string[] latex_argv = {
        latex,
        "-interaction=nonstopmode",
        "-halt-on-error",
        "-no-shell-escape",
        "formula.tex"
      };
      if( !(yield run_command( span, temp_dir, latex_argv, generation, out command_error )) ) {
        fail( generation, command_error );
        return;
      }
      if( generation != _generation ) {
        return;
      }

      string log;
      double tex_width   = 0.0;
      double tex_ascent  = 0.0;
      double tex_descent = 0.0;
      var log_file = GLib.Path.build_filename( temp_dir, "formula.log" );
      if( !FileUtils.get_contents( log_file, out log ) ||
          !parse_metrics( log, out tex_width, out tex_ascent, out tex_descent ) ) {
        fail( generation, _( "Unable to read LaTeX formula dimensions" ) );
        return;
      }

      string[] svg_argv = {
        dvisvgm,
        "--no-fonts=0",
        "--exact-bbox",
        "--bbox=min",
        "--no-specials",
        "--verbosity=0",
        "--output=formula.svg",
        "formula.dvi"
      };
      if( !(yield run_command( span, temp_dir, svg_argv, generation, out command_error )) ) {
        fail( generation, command_error );
        return;
      }
      if( generation != _generation ) {
        return;
      }

      var handle = new Rsvg.Handle.from_file( GLib.Path.build_filename( temp_dir, "formula.svg" ) );
      handle.set_dpi( 96.0 );
      double render_width, render_height;
      if( !handle.get_intrinsic_size_in_pixels( out render_width, out render_height ) ||
          (render_width <= 0) || (render_height <= 0) ) {
        fail( generation, _( "The generated LaTeX SVG has no usable size" ) );
        return;
      }

      // The SVG is tightly cropped to painted glyphs, while Pango needs the
      // logical TeX box for spacing and line height.  Keep both measurements:
      // the former for drawing and the latter for layout and its true baseline.
      var width   = Math.fmax( tex_width, render_width );
      var descent = Math.fmin( tex_descent, render_height );
      var ascent  = Math.fmax( tex_ascent, render_height - descent );
      var image   = new LatexImage(
        handle, width, ascent, descent, render_width, render_height
      );
      if( _cache.size >= MAX_CACHE_ITEMS ) {
        _cache.clear();
      }
      _cache.set( span.key, image );
      if( generation == _generation ) {
        span.image   = image;
        span.process = null;
        changed();
      }
    } catch( Error e ) {
      fail( generation, e.message );
    } finally {
      if( temp_dir != null ) {
        remove_temp_dir( temp_dir );
      }
    }
  }

  //-------------------------------------------------------------
  // Runs one renderer command with a timeout and restricted TeX IO.
  private async bool run_command( LatexSpan span, string working_dir, string[] argv,
                                  int generation, out string command_error ) {
    command_error = "";
    string? stdout_buf = null;
    string? stderr_buf = null;
    bool timed_out = false;

    try {
      var flags    = SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE;
      var launcher = new SubprocessLauncher( flags );
      launcher.set_cwd( working_dir );
      launcher.setenv( "openin_any",  "p", true );
      launcher.setenv( "openout_any", "p", true );
      launcher.setenv( "TEXMFOUTPUT", working_dir, true );
      var process = launcher.spawnv( argv );
      span.process = process;

      uint timeout_id = Timeout.add_seconds( COMMAND_TIMEOUT, () => {
        timed_out = true;
        process.force_exit();
        return( Source.REMOVE );
      });

      try {
        yield process.communicate_utf8_async( null, null, out stdout_buf, out stderr_buf );
      } finally {
        if( !timed_out ) {
          Source.remove( timeout_id );
        }
      }

      if( span.process == process ) {
        span.process = null;
      }
      if( generation != _generation ) {
        command_error = _( "LaTeX rendering was cancelled" );
        return( false );
      }
      if( timed_out ) {
        command_error = _( "LaTeX rendering timed out" );
        return( false );
      }
      if( !process.get_successful() ) {
        command_error = compact_error( stderr_buf ?? stdout_buf ?? _( "LaTeX rendering failed" ) );
        return( false );
      }
      return( true );
    } catch( Error e ) {
      command_error = e.message;
      return( false );
    }
  }

  //-------------------------------------------------------------
  // Keeps command diagnostics useful without retaining a full TeX log.
  private static string compact_error( string message ) {
    var stripped = message.strip();
    var chars = stripped.char_count();
    if( chars <= 500 ) {
      return( stripped );
    }
    return( stripped.substring( stripped.index_of_nth_char( chars - 500 ) ) );
  }

  //-------------------------------------------------------------
  // Reports a render failure only if it belongs to current source.
  private void fail( int generation, string message ) {
    if( generation == _generation ) {
      warning( "Unable to render LaTeX: %s", message );
      changed();
    }
  }

  //-------------------------------------------------------------
  // Removes only files created inside our private temporary directory.
  private static void remove_temp_dir( string path ) {
    try {
      var dir = Dir.open( path );
      unowned string? name;
      while( (name = dir.read_name()) != null ) {
        FileUtils.remove( GLib.Path.build_filename( path, name ) );
      }
    } catch( FileError e ) {}
    DirUtils.remove( path );
  }

}
