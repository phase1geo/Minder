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

  private string _fname;
  private Pixbuf _buf;

  /* Default constructor */
  public NodeImage.from_file( string fname ) {
    _fname = fname;
    try {
      _buf = new Pixbuf.from_file_at_size( fname, 400, 200 );
      stdout.printf( "HERE! size: %d\n", _buf.get_pixels().length );
    } catch( Error e ) {
      // TBD
    }
  }

  /* Constructor from XML file */
  public NodeImage.from_xml( Xml.Node* n ) {

    Colorspace cspace = Colorspace.RGB;
    bool       alpha  = false;
    int        bps    = 0;
    int        width  = 0;
    int        height = 0;
    int        stride = 0;

    string? f = n->get_prop( "fname" );
    if( f != null ) {
      _fname = f;
    }

    string? cs = n->get_prop( "colorspace" );
    if( cs != null ) {
      cspace = (Colorspace)int.parse( cs );
    }

    string? a = n->get_prop( "alpha" );
    if( a != null ) {
      alpha = bool.parse( a );
    }

    string? b = n->get_prop( "bps" );
    if( b != null ) {
      bps = int.parse( b );
    }

    string? w = n->get_prop( "width" );
    if( w != null ) {
      width = int.parse( w );
    }

    string? h = n->get_prop( "height" );
    if( h != null ) {
      height = int.parse( h );
    }

    string? r = n->get_prop( "rowstride" );
    if( r != null ) {
      stride = int.parse( r );
    }

    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      var pixels = Base64.decode( n->children->get_content() );
      _buf = new Pixbuf.from_data( pixels, cspace, alpha, bps, width, height, stride );
    }

  }

  /* Returns the width of the stored image */
  public double width() {
    return( _buf.width );
  }

  /* Returns the height of the stored image */
  public double height() {
    return( _buf.height );
  }

  /* Draws the image to the given context */
  public void draw( Context ctx, double x, double y ) {
    cairo_set_source_pixbuf( ctx, _buf, x, y );
    ctx.paint();
  }

  /* Saves the given node image in the given XML node */
  public virtual void save( Xml.Node* parent ) {
    Xml.Node* n = parent->new_text_child( null, "nodeimage", Base64.encode( _buf.get_pixels() ) );
    n->new_prop( "fname",      _fname );
    n->new_prop( "colorspace", _buf.colorspace.to_string() );
    n->new_prop( "alpha",      _buf.has_alpha.to_string() );
    n->new_prop( "bps",        _buf.bits_per_sample.to_string() );
    n->new_prop( "width",      _buf.width.to_string() );
    n->new_prop( "height",     _buf.height.to_string() );
    n->new_prop( "rowstride",  _buf.rowstride.to_string() );
  }

  /* Allows the user to choose an image file */
  public static string? choose_image_file( Gtk.Window parent ) {

    string? fname = null;

    FileChooserDialog dialog = new FileChooserDialog( _( "Select Image" ), parent, FileChooserAction.OPEN,
      _( "Cancel" ), ResponseType.CANCEL, _( "Select" ), ResponseType.ACCEPT );

    /* BMP */
    FileFilter filter = new FileFilter();
    filter.set_filter_name( _( "Images" ) );
    filter.add_pattern( "*.bmp" );
    filter.add_pattern( "*.png" );
    filter.add_pattern( "*.jpg" );
    filter.add_pattern( "*.jpeg" );
    dialog.add_filter( filter );

    if( dialog.run() == ResponseType.ACCEPT ) {
      fname = dialog.get_filename();
    }

    /* Close the dialog */
    dialog.destroy();

    return( fname );

  }

}
