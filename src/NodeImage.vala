/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

public class NodeImage {

  private Pixbuf?       _orig = null;
  private Pixbuf?       _buf  = null;
  private Rsvg.Handle?  _svg  = null;
  private Rsvg.Handle?  _svg_dark = null;
  private ImageSurface? _svg_cache = null;
  private int           _orig_width;
  private int           _orig_height;
  private int           _width;
  private int           _height;
  private int           _cache_width;
  private int           _cache_height;
  private int           _cache_crop_x;
  private int           _cache_crop_y;
  private int           _cache_crop_w;
  private int           _cache_crop_h;
  private bool          _cache_dark;

  public int  id     { get; set; default = -1; }
  public bool valid  { get; private set; default = false; }
  public int  crop_x { get; set; default = 0; }
  public int  crop_y { get; set; default = 0; }
  public int  crop_w { get; set; default = 0; }
  public int  crop_h { get; set; default = 0; }
  public int  orig_width {
    get {
      return( _orig_width );
    }
  }
  public int orig_height {
    get {
      return( _orig_height );
    }
  }
  public int  width  {
    get {
      return( _width );
    }
  }
  public int  height {
    get {
      return( _height );
    }
  }
  public bool resizable { get; set; default = true; }
  public bool vector {
    get {
      return( _svg != null );
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public NodeImage( ImageManager im, int id, int width ) {
    if( load( im, id, true ) ) {
      set_width( width );
    }
  }

  //-------------------------------------------------------------
  // Constructor from a URI
  public NodeImage.from_uri( ImageManager im, string uri, int width ) {
    int id = im.add_image( uri );
    if( id != -1 ) {
      if( load( im, id, true ) ) {
        set_width( width );
      } else {
        im.set_valid( id, false );
      }
    }
  }

  //-------------------------------------------------------------
  // Constructor from a pixbuf
  public NodeImage.from_pixbuf( ImageManager im, Pixbuf buf, int width ) {
    int id = im.add_pixbuf( buf );
    if( id != -1 ) {
      if( load( im, id, true ) ) {
        set_width( width );
      } else {
        im.set_valid( id, false );
      }
    }
  }

  //-------------------------------------------------------------
  // Constructor from another node image
  public NodeImage.from_node_image( ImageManager im, NodeImage ni, int width ) {
    string uri = im.get_uri( ni.id );
    if( uri != "" ) {
      int id = im.add_image( uri );
      if( id != -1 ) {
        crop_x = ni.crop_x;
        crop_y = ni.crop_y;
        crop_w = ni.crop_w;
        crop_h = ni.crop_h;
        if( load( im, id, false ) ) {
          set_width( width );
        } else {
          im.set_valid( id, false );
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Constructor from XML file
  public NodeImage.from_xml( ImageManager im, Xml.Node* n, int width ) {

    var resize = true;

    string? i = n->get_prop( "id" );
    if( i != null ) {
      id = im.get_id( int.parse( i ) );
    }

    string? x = n->get_prop( "x" );
    if( x != null ) {
      crop_x = int.parse( x );
    }

    string? y = n->get_prop( "y" );
    if( y != null ) {
      crop_y = int.parse( y );
    }

    string? w = n->get_prop( "w" );
    if( w != null ) {
      crop_w = int.parse( w );
    }

    string? h = n->get_prop( "h" );
    if( h != null ) {
      crop_h = int.parse( h );
    }

    string? s = n->get_prop( "size" );
    if( s != null ) {
      resize = false;
      width  = int.parse( s );
    }

    // Allocate the image
    if( id != -1 ) {
      if( load( im, id, false ) ) {
        set_width( width );
      }
    }

    resizable = resize;

  }

  //-------------------------------------------------------------
  // Loads the current file into this structure
  private bool load( ImageManager im, int id, bool init ) {

    this.id    = id;
    this.valid = true;
    _orig      = null;
    _buf       = null;
    _svg       = null;
    _svg_dark  = null;
    _orig_width  = 0;
    _orig_height = 0;
    _width       = 0;
    _height      = 0;
    invalidate_svg_cache();

    // Get the file into the stored pixbuf
    try {

      // Get the name of the file to read from the ImageManager
      var fname = im.get_file( id );
      if( fname == null ) {
        this.valid = false;
        return( false );
      }
      if( !load_svg( fname ) ) {
        _orig        = new Pixbuf.from_file( fname );
        _orig_width  = _orig.width;
        _orig_height = _orig.height;
      }

      // Initialize the variables
      if( init || (crop_x < 0) || (crop_y < 0) || (crop_w <= 0) || (crop_h <= 0) ||
          ((crop_x + crop_w) > orig_width) || ((crop_y + crop_h) > orig_height) ) {
        crop_x = 0;
        crop_y = 0;
        crop_w = orig_width;
        crop_h = orig_height;
      }

    } catch( Error e ) {
      this.valid = false;
    }

    return( this.valid );

  }

  //-------------------------------------------------------------
  // Loads an SVG and records its dimensions without rasterizing it.
  private bool load_svg( string filename ) {

    try {
      var file = File.new_for_path( filename );
      var svg  = new Rsvg.Handle.from_gfile_sync(
        file, Rsvg.HandleFlags.FLAG_KEEP_IMAGE_DATA
      );
      svg.set_dpi( 96.0 );

      var source = read_svg_source( filename );
      if( (source != null) && source.contains( "prefers-color-scheme" ) ) {
        try {
          svg       = load_svg_variant( file, source, false );
          _svg_dark = load_svg_variant( file, source, true );
        } catch( Error e ) {
          _svg_dark = null;
        }
      }

      double svg_width;
      double svg_height;
      if( !svg.get_intrinsic_size_in_pixels( out svg_width, out svg_height ) ) {
        bool has_width;
        bool has_height;
        bool has_viewbox;
        Rsvg.Length intrinsic_width;
        Rsvg.Length intrinsic_height;
        Rsvg.Rectangle viewbox;
        svg.get_intrinsic_dimensions(
          out has_width, out intrinsic_width, out has_height, out intrinsic_height,
          out has_viewbox, out viewbox
        );
        if( has_viewbox && (viewbox.width > 0) && (viewbox.height > 0) ) {
          svg_width  = viewbox.width;
          svg_height = viewbox.height;
        } else {
          svg_width  = 300;
          svg_height = 150;
        }
      }

      if( (svg_width <= 0) || (svg_height <= 0) ) {
        return( false );
      }

      _svg         = svg;
      _orig_width  = int.max( 1, (int)Math.ceil( svg_width ) );
      _orig_height = int.max( 1, (int)Math.ceil( svg_height ) );
      return( true );
    } catch( Error e ) {
      return( false );
    }

  }

  //-------------------------------------------------------------
  // Reads plain or gzip-compressed SVG source text.
  private string? read_svg_source( string filename ) {

    try {
      uint8[] contents;
      File.new_for_path( filename ).load_contents( null, out contents, null );
      InputStream stream = new MemoryInputStream.from_data( contents );
      if( (contents.length >= 2) && (contents[0] == 0x1f) && (contents[1] == 0x8b) ) {
        var decompressor = new ZlibDecompressor( ZlibCompressorFormat.GZIP );
        stream = new ConverterInputStream( stream, decompressor );
      }

      var input  = new DataInputStream( stream );
      var source = new StringBuilder();
      string? line;
      size_t length;
      while( (line = input.read_line( out length )) != null ) {
        source.append( line );
        source.append_c( '\n' );
      }
      return( source.str );
    } catch( Error e ) {
      return( null );
    }

  }

  //-------------------------------------------------------------
  // Loads a version of the SVG with its matching color-scheme CSS enabled.
  private Rsvg.Handle load_svg_variant( File file, string source, bool dark ) throws Error {

    var themed_source = apply_color_scheme( source, dark );
    var stream = new MemoryInputStream.from_data( themed_source.data );
    var svg = new Rsvg.Handle.from_stream_sync(
      stream, file, Rsvg.HandleFlags.FLAG_KEEP_IMAGE_DATA
    );
    svg.set_dpi( 96.0 );
    return( svg );

  }

  //-------------------------------------------------------------
  // Enables the requested prefers-color-scheme blocks for librsvg.
  private string apply_color_scheme( string source, bool dark ) {

    var output = new StringBuilder();
    var cursor = 0;

    while( cursor < source.length ) {
      var media = source.index_of( "@media", cursor );
      if( media == -1 ) break;
      var open = source.index_of_char( '{', media );
      if( open == -1 ) break;
      var close = find_closing_brace( source, open );
      if( close == -1 ) break;

      var query = source.substring( media, (open - media) ).down();
      if( query.contains( "prefers-color-scheme" ) ) {
        output.append( source.substring( cursor, (media - cursor) ) );
        if( dark ? query.contains( "dark" ) : query.contains( "light" ) ) {
          output.append( source.substring( (open + 1), (close - open - 1) ) );
        }
        cursor = close + 1;
      } else {
        output.append( source.substring( cursor, (close - cursor + 1) ) );
        cursor = close + 1;
      }
    }

    output.append( source.substring( cursor ) );
    return( output.str );

  }

  //-------------------------------------------------------------
  // Finds a CSS block's closing brace while ignoring strings and comments.
  private int find_closing_brace( string source, int open ) {

    var depth      = 0;
    var quote      = '\0';
    var in_comment = false;

    for( int index=open; index<source.length; index++ ) {
      var current = source[index];
      var next    = ((index + 1) < source.length) ? source[index + 1] : '\0';

      if( in_comment ) {
        if( (current == '*') && (next == '/') ) {
          in_comment = false;
          index++;
        }
      } else if( quote != '\0' ) {
        if( current == '\\' ) {
          index++;
        } else if( current == quote ) {
          quote = '\0';
        }
      } else if( (current == '/') && (next == '*') ) {
        in_comment = true;
        index++;
      } else if( (current == '\'') || (current == '"') ) {
        quote = current;
      } else if( current == '{' ) {
        depth++;
      } else if( current == '}' ) {
        depth--;
        if( depth == 0 ) return( index );
      }
    }

    return( -1 );

  }

  //-------------------------------------------------------------
  // Sets the width of the buffer based to the given value. We
  // will always generate the buffer from the stored surface so
  // that we don't lose resolution when scaling up.
  public void set_width( int width ) {

    if( !resizable ) return;

    if( (crop_w <= 0) || (crop_h <= 0) || (width <= 0) ) {
      return;
    }

    var scale      = (width * 1.0) / crop_w;
    var int_crop_h = (int)(crop_h * scale);
    
    // Ensure scaled height is valid for GdkPixbuf
    if( int_crop_h <= 0 ) {
      stderr.printf( "Warning: Calculated height (%d) invalid, using minimum height of 1\n", int_crop_h );
      int_crop_h = 1;
    }

    if( vector ) {
      _width  = width;
      _height = int_crop_h;
      invalidate_svg_cache();
      return;
    }

    if( _orig == null ) {
      return;
    }

    var tmp = new Pixbuf.subpixbuf( _orig, crop_x, crop_y, crop_w, crop_h );
    _buf = tmp.scale_simple( width, int_crop_h, InterpType.BILINEAR ) ?? _buf;
    if( _buf != null ) {
      _width  = _buf.width;
      _height = _buf.height;
    }

  }

  //-------------------------------------------------------------
  // Returns the original pixbuf
  public Pixbuf? get_orig_pixbuf( bool dark = false ) {
    if( !vector ) {
      return( _orig );
    }

    var max_dimension    = int.max( orig_width, orig_height );
    var target_dimension = int.min( 2048, int.max( 1024, max_dimension ) );
    var scale            = (target_dimension * 1.0) / max_dimension;
    var target_width     = int.max( 1, (int)Math.ceil( orig_width * scale ) );
    var target_height    = int.max( 1, (int)Math.ceil( orig_height * scale ) );
    return( render_svg_to_pixbuf(
      target_width, target_height, 0, 0, orig_width, orig_height, dark
    ) );
  }

  //-------------------------------------------------------------
  // Returns a pixbuf
  public Pixbuf? get_pixbuf( bool dark = false ) {
    if( vector ) {
      return( render_svg_to_pixbuf( width, height, crop_x, crop_y, crop_w, crop_h, dark ) );
    }
    return( _buf );
  }

  //-------------------------------------------------------------
  // Draws the uncropped image at its original dimensions.
  public void draw_original( Context ctx, double opacity = 1.0, bool dark = false ) {
    if( vector ) {
      draw_svg( ctx, 0, 0, orig_width, orig_height, 0, 0,
                orig_width, orig_height, opacity, dark );
    } else if( _orig != null ) {
      cairo_set_source_pixbuf( ctx, _orig, 0, 0 );
      ctx.paint_with_alpha( opacity );
    }
  }

  //-------------------------------------------------------------
  // Draws an SVG directly or from the interactive render cache.
  private void draw_svg( Context ctx, double x, double y, double width, double height,
                         int source_x, int source_y, int source_width,
                         int source_height, double opacity, bool dark ) {

    if( vector_target( ctx ) ) {
      draw_svg_direct( ctx, x, y, width, height, source_x, source_y,
                       source_width, source_height, opacity, dark );
    } else {
      draw_svg_cached( ctx, x, y, width, height, source_x, source_y,
                       source_width, source_height, opacity, dark );
    }

  }

  //-------------------------------------------------------------
  // Returns true if the target should retain vector drawing operations.
  private bool vector_target( Context ctx ) {

    switch( ctx.get_target().get_type() ) {
      case SurfaceType.PDF            :
      case SurfaceType.PS             :
      case SurfaceType.SVG            :
      case SurfaceType.WIN32_PRINTING :
      case SurfaceType.SCRIPT         :
      case SurfaceType.XML            :  return( true );
      default                         :  return( false );
    }

  }

  //-------------------------------------------------------------
  // Draws the SVG directly into the supplied Cairo context.
  private bool draw_svg_direct( Context ctx, double x, double y, double width, double height,
                                int source_x, int source_y, int source_width,
                                int source_height, double opacity, bool dark ) {

    var svg = (dark && (_svg_dark != null)) ? _svg_dark : _svg;
    if( (svg == null) || (source_width <= 0) || (source_height <= 0) ||
        (width <= 0) || (height <= 0) ) {
      return( false );
    }

    var success = true;
    var grouped = (opacity < 1.0);

    ctx.save();
    ctx.rectangle( x, y, width, height );
    ctx.clip();
    ctx.translate( x, y );
    ctx.scale( (width / source_width), (height / source_height) );
    ctx.translate( (0 - source_x), (0 - source_y) );
    if( grouped ) {
      ctx.push_group();
    }

    try {
      Rsvg.Rectangle viewport = {0, 0, orig_width, orig_height};
      svg.render_document( ctx, viewport );
    } catch( Error e ) {
      warning( "Unable to draw SVG image: %s", e.message );
      success = false;
    }

    if( grouped ) {
      ctx.pop_group_to_source();
      if( success ) {
        ctx.paint_with_alpha( opacity );
      }
    }
    ctx.restore();

    return( success );

  }

  //-------------------------------------------------------------
  // Draws the SVG from a cache matching its current screen scale.
  private void draw_svg_cached( Context ctx, double x, double y, double width, double height,
                                int source_x, int source_y, int source_width,
                                int source_height, double opacity, bool dark ) {

    const int MAX_CACHE_SIZE   = 4096;
    const int MAX_CACHE_PIXELS = 16777216;
    var matrix                 = ctx.get_matrix();
    var scale_x                = Math.sqrt( (matrix.xx * matrix.xx) + (matrix.yx * matrix.yx) );
    var scale_y                = Math.sqrt( (matrix.xy * matrix.xy) + (matrix.yy * matrix.yy) );
    double device_scale_x;
    double device_scale_y;
    ctx.get_target().get_device_scale( out device_scale_x, out device_scale_y );
    var cache_width  = int.max( 1, (int)Math.ceil( width  * scale_x * device_scale_x ) );
    var cache_height = int.max( 1, (int)Math.ceil( height * scale_y * device_scale_y ) );
    var limit_scale  = Math.fmin(
      1.0,
      Math.fmin(
        (MAX_CACHE_SIZE * 1.0) / int.max( cache_width, cache_height ),
        Math.sqrt( (MAX_CACHE_PIXELS * 1.0) / (cache_width * 1.0 * cache_height) )
      )
    );
    cache_width  = int.max( 1, (int)Math.ceil( cache_width  * limit_scale ) );
    cache_height = int.max( 1, (int)Math.ceil( cache_height * limit_scale ) );

    if( (_svg_cache == null) || (_cache_width != cache_width) ||
        (_cache_height != cache_height) || (_cache_crop_x != source_x) ||
        (_cache_crop_y != source_y) || (_cache_crop_w != source_width) ||
        (_cache_crop_h != source_height) || (_cache_dark != dark) ) {
      var surface = new ImageSurface( Format.ARGB32, cache_width, cache_height );
      var cache_context = new Context( surface );
      cache_context.scale( (cache_width / width), (cache_height / height) );
      if( !draw_svg_direct( cache_context, 0, 0, width, height, source_x, source_y,
                            source_width, source_height, 1.0, dark ) ) {
        return;
      }
      surface.flush();
      _svg_cache     = surface;
      _cache_width   = cache_width;
      _cache_height  = cache_height;
      _cache_crop_x  = source_x;
      _cache_crop_y  = source_y;
      _cache_crop_w  = source_width;
      _cache_crop_h  = source_height;
      _cache_dark    = dark;
    }

    ctx.save();
    ctx.translate( x, y );
    ctx.scale( (width / _cache_width), (height / _cache_height) );
    ctx.set_source_surface( _svg_cache, 0, 0 );
    ctx.paint_with_alpha( opacity );
    ctx.restore();

  }

  //-------------------------------------------------------------
  // Clears the interactive SVG render cache.
  private void invalidate_svg_cache() {
    _svg_cache    = null;
    _cache_width  = 0;
    _cache_height = 0;
    _cache_dark   = false;
  }

  //-------------------------------------------------------------
  // Renders an SVG region into a pixbuf on demand.
  private Pixbuf? render_svg_to_pixbuf( int target_width, int target_height,
                                        int source_x, int source_y,
                                        int source_width, int source_height,
                                        bool dark = false ) {

    if( (_svg == null) || (target_width <= 0) || (target_height <= 0) ) {
      return( null );
    }

    var surface = new ImageSurface( Format.ARGB32, target_width, target_height );
    var context = new Context( surface );
    if( !draw_svg_direct( context, 0, 0, target_width, target_height,
                          source_x, source_y, source_width, source_height, 1.0, dark ) ) {
      return( null );
    }
    surface.flush();

    try {
      var loader = new PixbufLoader.with_type( "png" );
      var status = surface.write_to_png_stream((data) => {
        try {
          loader.write( data );
          return( Status.SUCCESS );
        } catch( Error e ) {
          return( Status.WRITE_ERROR );
        }
      });
      if( status != Status.SUCCESS ) {
        return( null );
      }
      loader.close();
      var pixbuf = loader.get_pixbuf();
      return( (pixbuf == null) ? null : pixbuf.copy() );
    } catch( Error e ) {
      return( null );
    }

  }

  //-------------------------------------------------------------
  // Draws the image to the given context
  public void draw( Context ctx, double x, double y, double opacity, bool dark = false ) {
    if( vector ) {
      draw_svg( ctx, x, y, width, height, crop_x, crop_y,
                crop_w, crop_h, opacity, dark );
    } else if( _buf != null ) {
      cairo_set_source_pixbuf( ctx, _buf, x, y );
      ctx.paint_with_alpha( opacity );
    }
  }

  //-------------------------------------------------------------
  // Sets the given image widget to the stored pixbuf
  public void set_image( Picture img, bool dark = false ) {

    var scale_width  = 300.0 / width;
    var scale_height = 300.0 / height;
    var w            = 300;
    var h            = 300;

    // Calculate the width and height of the required image
    if( scale_width < scale_height ) {
      h = (int)(scale_width * height);
    } else {
      w = (int)(scale_height * width);
    }

    var buf = create_thumbnail( w, h, dark );
    if( buf == null ) {
      return;
    }

    var texture = Texture.for_pixbuf( buf );
    img.set_paintable( (Paintable)texture );

  }

  //-------------------------------------------------------------
  // Creates a cropped thumbnail for the image inspector.
  private Pixbuf? create_thumbnail( int width, int height, bool dark ) {

    if( vector ) {
      return( render_svg_to_pixbuf( width, height, crop_x, crop_y, crop_w, crop_h, dark ) );
    }

    if( _orig == null ) {
      return( null );
    }
    var source  = _orig;
    var scale_x = (source.width  * 1.0) / orig_width;
    var scale_y = (source.height * 1.0) / orig_height;
    var x       = (int)Math.floor( crop_x * scale_x );
    var y       = (int)Math.floor( crop_y * scale_y );
    var right   = (int)Math.ceil( (crop_x + crop_w) * scale_x );
    var bottom  = (int)Math.ceil( (crop_y + crop_h) * scale_y );
    x           = int.max( 0, int.min( x, source.width - 1 ) );
    y           = int.max( 0, int.min( y, source.height - 1 ) );
    right       = int.max( (x + 1), int.min( right, source.width ) );
    bottom      = int.max( (y + 1), int.min( bottom, source.height ) );

    var cropped = new Pixbuf.subpixbuf( source, x, y, (right - x), (bottom - y) );
    return( cropped.scale_simple( width, height, InterpType.BILINEAR ) );

  }

  //-------------------------------------------------------------
  // Saves the given node image in the given XML node
  public virtual void save( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "nodeimage" );

    n->new_prop( "id", id.to_string() );
    n->new_prop( "x",  crop_x.to_string() );
    n->new_prop( "y",  crop_y.to_string() );
    n->new_prop( "w",  crop_w.to_string() );
    n->new_prop( "h",  crop_h.to_string() );

    if( !resizable ) {
      n->new_prop( "size", width.to_string() );
    }

    parent->add_child( n );

  }

}
