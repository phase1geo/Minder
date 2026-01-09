/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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

  private Pixbuf _orig;
  private Pixbuf _buf;

  public int  id     { get; set; default = -1; }
  public bool valid  { get; private set; default = false; }
  public int  crop_x { get; set; default = 0; }
  public int  crop_y { get; set; default = 0; }
  public int  crop_w { get; set; default = 0; }
  public int  crop_h { get; set; default = 0; }
  public int  orig_width {
    get {
      return( _orig.width );
    }
  }
  public int orig_height {
    get {
      return( _orig.height );
    }
  }
  public int  width  {
    get {
      return( _buf.width );
    }
  }
  public int  height {
    get {
      return( _buf.height );
    }
  }
  public bool resizable { get; set; default = true; }

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

    var resize = false;

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
      resize = true;
      width  = int.parse( s );
    }

    // Allocate the image
    if( id != -1 ) {
      stdout.printf( "id: %d, resize: %s, width: %d\n", id, resize.to_string(), width );
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

    // Get the file into the stored pixbuf
    try {

      // Get the name of the file to read from the ImageManager
      var fname = im.get_file( id );
      stdout.printf( "fname: %s\n", (fname ?? "NA") );
      if( fname == null ) {
        this.valid = false;
        return( false );
      }

      // Read in the file into the given buffer
      _orig = new Pixbuf.from_file( fname );

      // Initialize the variables
      if( init ) {
        crop_x = 0;
        crop_y = 0;
        stdout.printf( "orig.width: %d\n", _orig.width );
        crop_w = _orig.width;
        crop_h = _orig.height;
      }

    } catch( Error e ) {
      this.valid = false;
    }

    return( this.valid );

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

    stdout.printf( "width: %d, orig.width: %d, crop_x: %d, crop_y: %d, crop_w: %d, crop_h: %d\n", width, _orig.get_width(), crop_x, crop_y, crop_w, crop_h );

    var tmp = new Pixbuf.subpixbuf( _orig, crop_x, crop_y, crop_w, crop_h );
    if( (tmp == null) || (int_crop_h <= 0) ) {
      return;
    }

    _buf = tmp.scale_simple( width, int_crop_h, InterpType.BILINEAR ) ?? _buf;

  }

  //-------------------------------------------------------------
  // Returns the original pixbuf
  public Pixbuf? get_orig_pixbuf() {
    return( _orig );
  }

  //-------------------------------------------------------------
  // Returns a pixbuf
  public Pixbuf? get_pixbuf() {
    return( _buf );
  }

  //-------------------------------------------------------------
  // Draws the image to the given context
  public void draw( Context ctx, double x, double y, double opacity ) {
    cairo_set_source_pixbuf( ctx, _buf, x, y );
    ctx.paint_with_alpha( opacity );
  }

  //-------------------------------------------------------------
  // Sets the given image widget to the stored pixbuf
  public void set_image( Picture img ) {

    var scale_width  = 300.0 / _buf.width;
    var scale_height = 300.0 / _buf.height;
    var w            = 300;
    var h            = 300;

    // Calculate the width and height of the required image
    if( scale_width < scale_height ) {
      h = (int)(scale_width * _buf.height);
    } else {
      w = (int)(scale_height * _buf.width);
    }

    var tmp = new Pixbuf.subpixbuf( _orig, crop_x, crop_y, crop_w, crop_h );
    if( tmp == null ) {
      return;
    }

    // Create the pixbuf thumbnail and set it in the given image widget
    var buf     = tmp.scale_simple( w, h, InterpType.BILINEAR );
    var texture = Texture.for_pixbuf( buf );
    img.set_paintable( (Paintable)texture );

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
      n->new_prop( "size", _buf.width.to_string() );
    }

    parent->add_child( n );

  }

}
