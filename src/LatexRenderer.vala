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
// Converts text containing LaTeX spans to SVG and renders it to Cairo.
public class LatexRenderer : Object {

  private class LatexImage : Object {
    public Rsvg.Handle handle { get; private set; }
    public double      width  { get; private set; }
    public double      height { get; private set; }
    public LatexImage( Rsvg.Handle handle, double width, double height ) {
      this.handle = handle;
      this.width  = width;
      this.height = height;
    }
  }

  private const int MAX_SOURCE_LENGTH = 16384;
  private const int MAX_CACHE_ITEMS   = 128;
  private const int COMMAND_TIMEOUT   = 10;

  private static HashMap<string,LatexImage>? _cache = null;

  private LatexImage? _image      = null;
  private Subprocess? _process    = null;
  private string      _key        = "";
  private int         _generation = 0;
  private bool        _rendering  = false;
  private string?     _error      = null;

  public bool valid {
    get {
      return( _image != null );
    }
  }
  public bool rendering {
    get {
      return( _rendering );
    }
  }
  public double width {
    get {
      return( (_image == null) ? 0.0 : _image.width );
    }
  }
  public double height {
    get {
      return( (_image == null) ? 0.0 : _image.height );
    }
  }
  public string? error {
    get {
      return( _error );
    }
  }

  public signal void changed();

  //-------------------------------------------------------------
  // Escapes ordinary node text before it is included in the small
  // TeX document surrounding the formula spans.
  private static void append_text( StringBuilder output, string text ) {
    int index = 0;
    unichar c;
    while( text.get_next_char( ref index, out c ) ) {
      switch( c ) {
        case '\\' :  output.append( "\\textbackslash{}" );     break;
        case '{'  :  output.append( "\\{" );                  break;
        case '}'  :  output.append( "\\}" );                  break;
        case '$'  :  output.append( "\\$" );                  break;
        case '&'  :  output.append( "\\&" );                  break;
        case '#'  :  output.append( "\\#" );                  break;
        case '%'  :  output.append( "\\%" );                  break;
        case '_'  :  output.append( "\\_" );                  break;
        case '^'  :  output.append( "\\textasciicircum{}" );  break;
        case '~'  :  output.append( "\\textasciitilde{}" );   break;
        case '\n' :  output.append( "\\strut\\\\\n" );      break;
        case '\r' :                                            break;
        default   :  output.append_unichar( c );                break;
      }
    }
  }

  //-------------------------------------------------------------
  // Converts one or more $$...$$ spans into a safe TeX document body.
  // Text outside the spans is treated as literal text, not TeX source.
  public static bool parse_source( string source, out string document_body ) {
    var output       = new StringBuilder( "\\noindent\\strut " );
    var offset       = 0;
    var formula_seen = false;

    while( offset < source.length ) {
      var start = source.index_of( "$$", offset );
      if( start == -1 ) {
        append_text( output, source.substring( offset ) );
        break;
      }

      append_text( output, source.substring( offset, (start - offset) ) );
      var end = source.index_of( "$$", (start + 2) );
      if( end == -1 ) {
        document_body = "";
        return( false );
      }

      var expression = source.substring( (start + 2), (end - start - 2) ).strip();
      if( expression == "" ) {
        document_body = "";
        return( false );
      }

      output.append( "\\(\\displaystyle\n" );
      output.append( expression );
      output.append( "\n\\)" );
      formula_seen = true;
      offset = end + 2;
    }

    document_body = output.str;
    return( formula_seen );
  }

  //-------------------------------------------------------------
  // Returns true if the supplied text is a display LaTeX expression.
  public static bool is_latex_source( string source ) {
    string document_body;
    return( parse_source( source, out document_body ) );
  }

  //-------------------------------------------------------------
  // Returns true when a byte position is inside an opened $$ span.
  // This also handles the span while its closing delimiter is pending.
  public static bool is_latex_at( string source, int position ) {
    var offset  = 0;
    var in_math = false;
    while( offset < source.length ) {
      var delimiter = source.index_of( "$$", offset );
      if( delimiter == -1 ) {
        return( in_math );
      }
      if( position < delimiter ) {
        return( in_math );
      }
      in_math = !in_math;
      offset = delimiter + 2;
    }
    return( in_math );
  }

  //-------------------------------------------------------------
  // Updates the rendered image. Rendering runs asynchronously so a
  // complex expression cannot block canvas interaction.
  public void update( string source, int font_size ) {
    string document_body;
    if( !parse_source( source, out document_body ) ) {
      clear();
      return;
    }

    var size = int.max( 6, font_size );
    var key  = "%d\x1f%s".printf( size, source );
    if( key == _key ) {
      return;
    }

    cancel();
    _key   = key;
    _error = null;

    if( _cache == null ) {
      _cache = new HashMap<string,LatexImage>();
    }
    if( _cache.has_key( key ) ) {
      _image = _cache.get( key );
      changed();
      return;
    }

    if( source.length > MAX_SOURCE_LENGTH ) {
      fail( key, _generation, _( "LaTeX expression is too long" ) );
      return;
    }

    var latex   = Environment.find_program_in_path( "latex" );
    var dvisvgm = Environment.find_program_in_path( "dvisvgm" );
    if( (latex == null) || (dvisvgm == null) ) {
      fail( key, _generation, _( "LaTeX rendering requires the latex and dvisvgm commands" ) );
      return;
    }

    _rendering = true;
    render.begin( document_body, size, key, _generation, latex, dvisvgm );
  }

  //-------------------------------------------------------------
  // Clears any current or pending render.
  private void clear() {
    if( (_key == "") && (_image == null) && !_rendering && (_error == null) ) {
      return;
    }
    cancel();
    _key   = "";
    _image = null;
    _error = null;
    changed();
  }

  //-------------------------------------------------------------
  // Cancels the current subprocess and invalidates its callbacks.
  private void cancel() {
    _generation++;
    if( _process != null ) {
      _process.force_exit();
      _process = null;
    }
    _rendering = false;
    _image     = null;
  }

  //-------------------------------------------------------------
  // Creates the small standalone TeX document used by latex.
  private static string make_document( string document_body, int font_size ) {
    var line_height = font_size * 1.2;
    return( """\documentclass{article}
\usepackage{amsmath}
\usepackage{amssymb}
\pagestyle{empty}
\begin{document}
\fontsize{%dpt}{%.2fpt}\selectfont
%s
\end{document}
""".printf( font_size, line_height, document_body ) );
  }

  //-------------------------------------------------------------
  // Runs latex followed by dvisvgm and loads the resulting SVG.
  private async void render( string document_body, int font_size, string key, int generation,
                             string latex, string dvisvgm ) {
    string? temp_dir = null;
    try {
      temp_dir = DirUtils.make_tmp( "minder-latex-XXXXXX" );
      var tex_file = GLib.Path.build_filename( temp_dir, "formula.tex" );
      FileUtils.set_contents( tex_file, make_document( document_body, font_size ) );

      string command_error;
      string[] latex_argv = {
        latex,
        "-interaction=nonstopmode",
        "-halt-on-error",
        "-no-shell-escape",
        "formula.tex"
      };
      if( !(yield run_command( temp_dir, latex_argv, generation, out command_error )) ) {
        fail( key, generation, command_error );
        return;
      }
      if( generation != _generation ) {
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
      if( !(yield run_command( temp_dir, svg_argv, generation, out command_error )) ) {
        fail( key, generation, command_error );
        return;
      }
      if( generation != _generation ) {
        return;
      }

      var handle = new Rsvg.Handle.from_file( GLib.Path.build_filename( temp_dir, "formula.svg" ) );
      handle.set_dpi( 96.0 );
      double width, height;
      if( !handle.get_intrinsic_size_in_pixels( out width, out height ) || (width <= 0) || (height <= 0) ) {
        fail( key, generation, _( "The generated LaTeX SVG has no usable size" ) );
        return;
      }

      var image = new LatexImage( handle, width, height );
      if( _cache.size >= MAX_CACHE_ITEMS ) {
        _cache.clear();
      }
      _cache.set( key, image );
      if( (generation == _generation) && (key == _key) ) {
        _image     = image;
        _rendering = false;
        _error     = null;
        changed();
      }
    } catch( Error e ) {
      fail( key, generation, e.message );
    } finally {
      if( temp_dir != null ) {
        remove_temp_dir( temp_dir );
      }
    }
  }

  //-------------------------------------------------------------
  // Runs one renderer command with a timeout and restricted TeX IO.
  private async bool run_command( string working_dir, string[] argv, int generation, out string command_error ) {
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
      _process = process;

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

      if( _process == process ) {
        _process = null;
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
  // Records a render failure if it still belongs to the active source.
  private void fail( string key, int generation, string message ) {
    if( (generation == _generation) && (key == _key) ) {
      _image     = null;
      _rendering = false;
      _error     = message;
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

  //-------------------------------------------------------------
  // Renders the cached SVG at the requested canvas location and color.
  public void draw( Context ctx, double x, double y, double draw_width, double draw_height,
                    RGBA color, double alpha ) {
    if( _image == null ) return;

    var red   = (int)(color.red   * 255.0);
    var green = (int)(color.green * 255.0);
    var blue  = (int)(color.blue  * 255.0);
    var css   = "* { fill: rgb(%d, %d, %d) !important; }".printf( red, green, blue );

    try {
      _image.handle.set_stylesheet( css.data );
      Rsvg.Rectangle viewport = {x, y, draw_width, draw_height};
      ctx.save();
      if( alpha < 1.0 ) {
        ctx.push_group();
      }
      _image.handle.render_document( ctx, viewport );
      if( alpha < 1.0 ) {
        ctx.pop_group_to_source();
        ctx.paint_with_alpha( alpha );
      }
      ctx.restore();
      ctx.new_path();
    } catch( Error e ) {
      warning( "Unable to draw LaTeX SVG: %s", e.message );
    }
  }

}
