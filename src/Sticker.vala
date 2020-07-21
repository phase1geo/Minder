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
  NONE = 0,
  SELECTED
}

public class Sticker {

  private string _name;
  private Pixbuf _buf;

  public StickerMode mode { get; set; default = StickerMode.NONE; }
  public double posx { get; set; default = 0.0; }
  public double posy { get; set; default = 0.0; }
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
  public Sticker( string n, double x, double y ) {
    _name = n;
    posx  = x;
    posy  = y;
    set_pixbuf();
  }

  /* Constructor from XML */
  public Sticker.from_xml( Xml.Node* n ) {
    load( n );
  }

  /* Saves the sticker to the XML tree */
  public Xml.Node* save() {
    Xml.Node* n = new Xml.Node( null, "sticker" );
    n->set_prop( "name", _name );
    n->set_prop( "posx", posx.to_string() );
    n->set_prop( "posy", posy.to_string() );
    return( n );
  }

  /* Loads the sticker from the XML tree */
  public void load( Xml.Node* n ) {
    string? nm = n->get_prop( "name" );
    if( nm != null ) {
      _name = nm;
      set_pixbuf();
    }
    string? x = n->get_prop( "posx" );
    if( x != null ) {
      posx = double.parse( x );
    }
    string? y = n->get_prop( "posy" );
    if( y != null ) {
      posy = double.parse( y );
    }
  }

  private void set_pixbuf() {
    _buf = new Pixbuf.from_resource( "/com/github/phase1geo/minder/" + _name );
  }

  /* Draw the sticker on the mind map */
  public void draw( Cairo.Context ctx, Theme theme, double opacity ) {
    if( mode == StickerMode.SELECTED ) {
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "nodesel_background" ), opacity );
      ctx.rectangle( (posx - 2), (posy - 2), (_buf.width + 4), (_buf.height + 4) );
      ctx.fill();
    }
    cairo_set_source_pixbuf( ctx, _buf, posx, posy );
    ctx.paint_with_alpha( opacity );
  }

}
