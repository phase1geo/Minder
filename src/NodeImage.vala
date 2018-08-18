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

  public string fname { get; set; default = ""; }
  public bool   valid { get; private set; default = false; }
  public double scale { get; set; default = 1; }
  public double posx  { get; set; }
  public double posy  { get; set; }

  /* Default constructor */
  public NodeImage.from_file( string fname ) {

    valid = load_from_file( fname );

  }

  /* Constructor from XML file */
  public NodeImage.from_xml( Xml.Node* n ) {

    double width, height;

    string? f = n->get_prop( "fname" );
    if( f != null ) {
      valid = load_from_file( f );
    }

    string? s = n->get_prop( "scale" );
    if( s != null ) {
      scale = double.parse( s );
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

  }

  /* Loads the current file into this structure */
  private bool load_from_file( string fn ) {

    int act_width, act_height;
    int req_width  = 200;
    int req_height = 400;

    /* Get the file information */
    Pixbuf.get_file_info( fn, out act_width, out act_height );

    if( act_width < 200 ) {
      req_width = act_width;
    }

    /* Get the file into the current pixbuf */
    try {
      _buf = new Pixbuf.from_file_at_size( fn, req_width, req_height );
    } catch( Error e ) {
      return( false );
    }

    /* Calculate the scaling factor */
    fname = fn;
    scale = _buf.width / (double)act_width;
    posx  = 0;
    posy  = 0;

    return( true );

  }

  /* Returns the width of the stored image */
  public double width() {
    return( _buf.width );
  }

  /* Returns the height of the stored image */
  public double height() {
    return( _buf.height );
  }

  /* Returns a pixbuf */
  public Pixbuf? get_pixbuf() {
    return( _buf );
  }

  /* Draws the image to the given context */
  public void draw( Context ctx, double x, double y, int opacity=255 ) {

    var buf = _buf;

    if( opacity < 255 ) {
      buf = new Pixbuf( _buf.colorspace, true, _buf.bits_per_sample, _buf.width, _buf.height );
      buf.fill( (uint32)0xffffff32 );
      _buf.composite( buf, 0, 0, _buf.width, _buf.height, 0, 0, 1, 1, InterpType.BILINEAR, opacity );
    }

    cairo_set_source_pixbuf( ctx, buf, x, y );
    ctx.paint();

  }


  /* Sets the given image widget to the stored pixbuf */
  public void set_image( Image img ) {

    img.set_from_pixbuf( _buf );

  }

  /* Saves the given node image in the given XML node */
  public virtual void save( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "nodeimage" );

    n->new_prop( "fname",  fname );
    n->new_prop( "scale",  scale.to_string() );
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
