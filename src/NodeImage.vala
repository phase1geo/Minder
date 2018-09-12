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

public class NodeImage {

  public const int EDIT_WIDTH  = 600;
  public const int EDIT_HEIGHT = 600;

  private ImageSurface _surface;
  private Pixbuf       _buf;

  public string fname  { get; set; default = ""; }
  public bool   valid  { get; private set; default = false; }
  public int    crop_x { get; set; default = 0; }
  public int    crop_y { get; set; default = 0; }
  public int    crop_w { get; set; default = 0; }
  public int    crop_h { get; set; default = 0; }
  public int    width  {
    get {
      return( _buf.width );
    }
  }
  public int    height {
    get {
      return( _buf.height );
    }
  }

  /* Default constructor */
  public NodeImage.from_file( string fn ) {
    if( load( fn, true ) ) {
      set_width( 200 );
    }
  }

  /* Constructor from XML file */
  public NodeImage.from_xml( Xml.Node* n ) {

    string? f = n->get_prop( "fname" );
    if( f != null ) {
      fname = f;
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

    /* Allocate the image */
    if( fname != "" ) {
      if( load( fname, false ) ) {
        set_width( 200 );
      }
    }

  }

  /* Creates a new NodeImage from the given NodeImage */
  public NodeImage.from_node_image( NodeImage ni ) {
    copy_from( ni );
  }

  /* Copy the node image from the given parameter */
  public void copy_from( NodeImage ni ) {

    var s = ni.get_surface();

    /* Initialize the values */
    fname  = ni.fname;
    valid  = ni.valid;
    crop_x = ni.crop_x;
    crop_y = ni.crop_y;
    crop_w = ni.crop_w;
    crop_h = ni.crop_h;

    /* Copy the surface */
    _surface = new ImageSurface.for_data( s.get_data(), s.get_format(), s.get_width(), s.get_height(), s.get_stride() );

    /* Update the pixbuf using the width */
    set_width( ni.get_pixbuf().width );

  }

  /* Loads the current file into this structure */
  public bool load( string fn, bool init ) {

    fname = fn;
    valid = true;

    /* Get the file into the stored pixbuf */
    try {

      /* Read in the file into the given buffer */
      var buf = new Pixbuf.from_file_at_size( fname, EDIT_WIDTH, EDIT_HEIGHT );
      _surface = new ImageSurface( Cairo.Format.ARGB32, buf.width, buf.height );
      var ctx = new Context( _surface );
      cairo_set_source_pixbuf( ctx, buf, 0, 0 );
      ctx.paint();

      /* Initialize the variables */
      if( init ) {
        crop_x = 0;
        crop_y = 0;
        crop_w = _surface.get_width();
        crop_h = _surface.get_height();
      }

    } catch( Error e ) {
      valid = false;
    }

    return( valid );

  }

  /*
   Sets the width of the buffer based to the given value. We will always generate
   the buffer from the stored surface so that we don't lose resolution when scaling
   up.
  */
  public void set_width( int width ) {

    var scale = (width * 1.0) / crop_w;
    var buf   = pixbuf_get_from_surface( _surface, crop_x, crop_y, crop_w, crop_h );

    _buf = buf.scale_simple( width, (int)(crop_h * scale), InterpType.BILINEAR );

  }

  /* Returns the original pixbuf */
  public ImageSurface? get_surface() {
    return( _surface );
  }

  /* Returns a pixbuf */
  public Pixbuf? get_pixbuf() {
    return( _buf );
  }

  /* Draws the image to the given context */
  public void draw( Context ctx, double x, double y, double opacity ) {
    cairo_set_source_pixbuf( ctx, _buf, x, y );
    ctx.paint_with_alpha( opacity );
  }


  /* Sets the given image widget to the stored pixbuf */
  public void set_image( Image img ) {

    var scale_width  = 200.0 / _buf.width;
    var scale_height = 200.0 / _buf.height;
    var w            = 200;
    var h            = 200;

    /* Calculate the width and height of the required image */
    if( scale_width < scale_height ) {
      h = (int)(scale_width * _buf.height);
    } else {
      w = (int)(scale_height * _buf.width);
    }

    /* Create the pixbuf thumbnail and set it in the given image widget */
    var buf = _buf.scale_simple( w, h, InterpType.BILINEAR );
    img.set_from_pixbuf( buf );

  }

  /* Saves the given node image in the given XML node */
  public virtual void save( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "nodeimage" );

    n->new_prop( "fname", fname );
    n->new_prop( "x",     crop_x.to_string() );
    n->new_prop( "y",     crop_y.to_string() );
    n->new_prop( "w",     crop_w.to_string() );
    n->new_prop( "h",     crop_h.to_string() );

    parent->add_child( n );

  }

  /* Allows the user to choose an image file */
  public static string? choose_image_file( Gtk.Window parent ) {

    string? fn = null;

    FileChooserDialog dialog = new FileChooserDialog( _( "Select Image" ), parent, FileChooserAction.OPEN,
      _( "Cancel" ), ResponseType.CANCEL, _( "Select" ), ResponseType.ACCEPT );

    /* Allow pixbuf image types */
    FileFilter filter = new FileFilter();
    filter.set_filter_name( _( "Images" ) );
    filter.add_pattern( "*.bmp" );
    filter.add_pattern( "*.png" );
    filter.add_pattern( "*.jpg" );
    filter.add_pattern( "*.jpeg" );
    dialog.add_filter( filter );

    if( dialog.run() == ResponseType.ACCEPT ) {
      fn = dialog.get_filename();
    }

    /* Close the dialog */
    dialog.destroy();

    return( fn );

  }

  /* Returns the web pathname used to store downloaded images */
  private static string get_web_path() {
    return( GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "images" ) );
  }

  /* Returns true if the given image filename is one that came from the web */
  public bool is_from_web() {
    return( fname.has_prefix( get_web_path() ) );
  }

  /* Returns the path for the file associated with the given URI */
  public static string? get_fname_from_uri( string uri ) {
    var rfile = File.new_for_uri( uri );
    if( uri.has_prefix( "file://" ) ) {
      return( rfile.get_path() );
    } else {
      var dir = get_web_path();
      if( DirUtils.create_with_parents( dir, 0775 ) == 0 ) {
        var parts = uri.split( "." );
        var ext   = parts[parts.length - 1];
        if( (ext == "bmp") || (ext == "png") || (ext == "jpg") || (ext == "jpeg") ) {
          ext = "." + ext;
        } else {
          ext = "";
        }
        var id    = Minder.get_image_id();
        var lfile = File.new_for_path( GLib.Path.build_filename( dir, "img%06d%s".printf( id, ext ) ) );
        try {
          rfile.copy( lfile, FileCopyFlags.OVERWRITE );
          return( lfile.get_path() );
        } catch( Error e ) {
          return( null );
        }
      }
      return( null );
    }
  }

}
