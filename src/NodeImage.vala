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

  private Pixbuf _buf;

  public string fname  { get; set; default = ""; }
  public bool   valid  { get; private set; default = false; }
  public double posx   { get; set; default = 0; }
  public double posy   { get; set; default = 0; }
  public int    width  { get; set; default = 0; }
  public int    height { get; set; default = 0; }
  public int    rotate { get; set; default = 0; }

  /* Default constructor */
  public NodeImage.from_file( string fn ) {

    fname = fn;
    valid = load( 200 );

  }

  /* Constructor from XML file */
  public NodeImage.from_xml( Xml.Node* n ) {

    double width  = 0;
    double height = 0;

    string? f = n->get_prop( "fname" );
    if( f != null ) {
      fname = f;
    }

    string? r = n->get_prop( "rotate" );
    if( r != null ) {
      rotate = int.parse( r );
    }

    string? x = n->get_prop( "posx" );
    if( x != null ) {
      posx = double.parse( x );
    }

    string? y = n->get_prop( "posy" );
    if( y != null ) {
      posy = double.parse( y );
    }

    string? w = n->get_prop( "width" );
    if( w != null ) {
      width = double.parse( w );
    }

    string? h = n->get_prop( "height" );
    if( h != null ) {
      height = double.parse( h );
    }

    /* Allocate the image */
    if( (fname != "") && (width > 0) ) {
      valid = load( (int)width );
    }

  }

  /* Creates a new NodeImage from the given NodeImage */
  public NodeImage.from_node_image( NodeImage ni ) {
    _buf   = ni.get_pixbuf().copy();
    fname  = ni.fname;
    valid  = ni.valid;
    posx   = ni.posx;
    posy   = ni.posy;
    rotate = ni.rotate;
  }

  /* Add the image */
  private void draw_image( Context ctx, ImageSurface image ) {

    var w = image.get_width();
    var h = image.get_height();

    ctx.translate( (w * 0.5), (h * 0.5) );
    ctx.rotate( rotate * Math.PI / 180 );
    ctx.translate( (w * -0.5), (h * -0.5) );
    ctx.set_source_surface( image, 0, 0 );
    ctx.paint();

  }

  /* Loads the current file into this structure */
  private bool load( int req_width ) {

    int act_width, act_height;
    int req_height = 400;

    /* Get the file information */
    Pixbuf.get_file_info( fname, out act_width, out act_height );

    /*
    if( act_width < 200 ) {
      req_width = act_width;
    }
    */

    /* Get the file into the current pixbuf */
    try {
      var buf     = new Pixbuf.from_file_at_size( fname, req_width, req_height );
      var image   = (ImageSurface)cairo_surface_create_from_pixbuf( buf, 0, null );
      var surface = new ImageSurface( image.get_format(), image.get_width(), image.get_height() );
      var context = new Context( surface );
      draw_image( context, image );
      _buf = pixbuf_get_from_surface( surface, (int)posx, (int)posy, width, height );
    } catch( Error e ) {
      return( false );
    }

    /* Calculate the scaling factor */
    posx = 0;
    posy = 0;

    return( true );

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

    img.set_from_pixbuf( _buf );

  }

  /* Sets the buffer from the given surface */
  public void set_from_surface( Surface surface, int x, int y, int width, int height ) {

    posx = x;
    posy = y;

    _buf = pixbuf_get_from_surface( surface, x, y, width, height );

  }

  /* Sets the width of the image to the given value */
  public void set_image_width( int width ) {

    load( width );

  }

  /* Saves the given node image in the given XML node */
  public virtual void save( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "nodeimage" );

    n->new_prop( "fname",  fname );
    n->new_prop( "rotate", rotate.to_string() );
    n->new_prop( "posx",   posx.to_string() );
    n->new_prop( "posy",   posy.to_string() );
    n->new_prop( "width",  _buf.width.to_string() );
    n->new_prop( "height", _buf.height.to_string() );

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

}
