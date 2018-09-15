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
  public string uri    { get; private set; default = ""; }
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
  public NodeImage( string fname, string uri, int width ) {
    if( load( fname, uri, true ) ) {
      set_width( width );
    }
  }

  public NodeImage.from_uri( ImageManager im, string uri, int width ) {
    string? fn = im.add_image( uri );
    if( (fn != null) && load( fn, uri, true ) ) {
      set_width( width );
    } else {
      im.set_valid_for_uri( uri, false );
    }
  }

  /* Constructor from XML file */
  public NodeImage.from_xml( ImageManager im, Xml.Node* n, int width ) {

    string? f = n->get_prop( "fname" );
    if( f != null ) {
      fname = f;
    }

    string? u = n->get_prop( "uri" );
    if( u != null ) {
      uri = u;
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
      if( load( fname, uri, false ) ) {
        set_width( width );
      }
    }

    /* Add ourselves to the image manager */
    im.add_node_image( this );

  }

  /* Loads the current file into this structure */
  private bool load( string fname, string uri, bool init ) {

    this.fname = fname;
    this.uri   = uri;
    this.valid = true;

    /* Get the file into the stored pixbuf */
    try {

      /* Read in the file into the given buffer */
      var buf = new Pixbuf.from_file_at_size( fname, EDIT_WIDTH, EDIT_HEIGHT );
      _surface = (ImageSurface)cairo_surface_create_from_pixbuf( buf, 1, null );

      /* Initialize the variables */
      if( init ) {
        crop_x = 0;
        crop_y = 0;
        crop_w = _surface.get_width();
        crop_h = _surface.get_height();
      }

    } catch( Error e ) {
      this.valid = false;
    }

    return( this.valid );

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

    var scale_width  = 300.0 / _buf.width;
    var scale_height = 300.0 / _buf.height;
    var w            = 300;
    var h            = 300;

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
    n->new_prop( "uri",   uri );
    n->new_prop( "x",     crop_x.to_string() );
    n->new_prop( "y",     crop_y.to_string() );
    n->new_prop( "w",     crop_w.to_string() );
    n->new_prop( "h",     crop_h.to_string() );

    parent->add_child( n );

  }

}
