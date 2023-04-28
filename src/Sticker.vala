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

using Cairo;
using Gdk;

public enum StickerMode {
  NONE = 0,   // Sticker should be drawn nomrally
  SELECTED,   // Sticker has been selected
  DROPPABLE   // Sticker is a dropzone for another sticker
}

public class Sticker {

  private DrawArea _da;
  private string   _name;
  private Pixbuf   _buf;
  private double   _posx = 0.0;
  private double   _posy = 0.0;

  public StickerMode mode { get; set; default = StickerMode.NONE; }
  public double posx {
    get {
      return( _posx + _da.origin_x );
    }
    set {
      _posx = value - _da.origin_x;
    }
  }
  public double posy {
    get {
      return( _posy + _da.origin_y );
    }
    set {
      _posy = value - _da.origin_y;
    }
  }
  public double width {
    get {
      return( _buf.width );
    }
  }
  public double height {
    get {
      return( _buf.height );
    }
  }

  /* Default constructor */
  public Sticker( DrawArea da, string n, double x, double y, int width = -1 ) {
    _da   = da;
    _name = n;
    posx  = x;
    posy  = y;
    set_pixbuf( width );
  }

  /* Constructor from XML */
  public Sticker.from_xml( DrawArea da, Xml.Node* n ) {
    _da = da;
    load( n );
  }

  /* Returns the area of the resizer box */
  public void resizer_bbox( out double x, out double y, out double w, out double h ) {
    x = (posx + _buf.width) - 8;
    y = posy;
    w = 8;
    h = 8;
  }

  /* Returns true if the given coordinates are within the area of the resizer box */
  public bool is_within_resizer( double x, double y ) {
    double rx, ry, rw, rh;
    resizer_bbox( out rx, out ry, out rw, out rh );
    return( Utils.is_within_bounds( x, y, rx, ry, rw, rh ) );
  }

  /* Resizes the given image */
  public void resize( double diff ) {
    var width = (int)(_buf.width + diff);
    if( (width < 24) || (width > 256) ) return;
    var int_new_width = (int)(_buf.width + diff);
    set_pixbuf( int_new_width );
  }

  /* Saves the sticker to the XML tree */
  public Xml.Node* save() {
    Xml.Node* n = new Xml.Node( null, "sticker" );
    n->set_prop( "name",  _name );
    n->set_prop( "posx",  _posx.to_string() );
    n->set_prop( "posy",  _posy.to_string() );
    n->set_prop( "width", _buf.width.to_string() );
    return( n );
  }

  /* Loads the sticker from the XML tree */
  public void load( Xml.Node* n ) {
    var width = -1;
    string? nm = n->get_prop( "name" );
    if( nm != null ) {
      _name = nm;
    }
    string? x = n->get_prop( "posx" );
    if( x != null ) {
      _posx = double.parse( x );
    }
    string? y = n->get_prop( "posy" );
    if( y != null ) {
      _posy = double.parse( y );
    }
    string? w = n->get_prop( "width" );
    if( w != null ) {
      width = int.parse( w );
    }
    set_pixbuf( width );
  }

  /* Creates the pixbuf for the stored image */
  public void set_pixbuf( int width = -1 ) {
    _buf = new Pixbuf.from_resource_at_scale( ("/com/github/phase1geo/minder/" + _name), width, -1, true );
  }

  /* Draw the sticker on the mind map */
  public void draw( Cairo.Context ctx, Theme theme, double opacity, bool exporting ) {

    if( (mode == StickerMode.SELECTED) && !exporting ) {

      /* Draw selection box */
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "nodesel_background" ), ((opacity == 1.0) ? 0.5 : opacity) );
      ctx.rectangle( posx, posy, _buf.width, _buf.height );
      ctx.fill();

      /* Draw resize handle */
      double x, y, w, h;

      resizer_bbox( out x, out y, out w, out h );

      Utils.set_context_color( ctx, theme.get_color( "background" ) );
      ctx.set_line_width( 1 );
      ctx.rectangle( x, y, w, h );
      ctx.fill_preserve();

      Utils.set_context_color_with_alpha( ctx, theme.get_color( "foreground" ), opacity );
      ctx.stroke();

    }

    /* Draw sticker image */
    cairo_set_source_pixbuf( ctx, _buf, posx, posy );
    ctx.paint_with_alpha( opacity );

    /* Draw droppable box, if necessary */
    if( mode == StickerMode.DROPPABLE ) {
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "attachable" ), opacity );
      ctx.set_line_width( 4 );
      ctx.rectangle( posx, posy, _buf.width, _buf.height );
      ctx.stroke();
    }

  }

}
