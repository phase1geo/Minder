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

public class Stickers {

  private Array<Sticker> _stickers;

  /* Constructor */
  public Stickers() {
    _stickers = new Array<Sticker>();
  }

  /* Clears all of the stored stickers */
  public void clear() {
    _stickers.remove_range( 0, _stickers.length );
  }

  /* Adds the given sticker to our list */
  public void add_sticker( Sticker sticker ) {
    _stickers.append_val( sticker );
  }

  /* Deletes the given sticker from this list */
  public void remove_sticker( Sticker sticker ) {
    for( int i=0; i<_stickers.length; i++ ) {
      if( _stickers.index( i ) == sticker ) {
        _stickers.remove_index( i );
        return;
      }
    }
  }

  /* This should be called whenever we select a sticker */
  public void select_sticker( Sticker sticker ) {
    remove_sticker( sticker );
    add_sticker( sticker );
  }

  /* Returns the sticker located at the given cursor position */
  public Sticker? is_within( double x, double y ) {
    for( int i=(int)(_stickers.length - 1); i>=0; i-- ) {
      var s = _stickers.index( i );
      if( Utils.is_within_bounds( x, y, s.posx, s.posy, s.width, s.height ) ) {
        return( s );
      }
    }
    return( null );
  }

  /* Handles a pan of the canvas */
  public void pan( double diff_x, double diff_y ) {
    for( int i=0; i<_stickers.length; i++ ) {
      var s = _stickers.index( i );
      s.posx += diff_x;
      s.posy += diff_y;
    }
  }

  /* Saves the sticker to the XML tree */
  public Xml.Node* save() {
    Xml.Node* n = new Xml.Node( null, "stickers" );
    for( int i=0; i<_stickers.length; i++ ) {
      n->add_child( _stickers.index( i ).save() );
    }
    return( n );
  }

  /* Loads the sticker from the XML tree */
  public void load( Xml.Node* n ) {
    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "sticker") ) {
        var sticker = new Sticker.from_xml( it );
        _stickers.append_val( sticker );
      }
    }
  }

  /* Draw the sticker on the mind map */
  public void draw_all( Cairo.Context ctx, Theme theme, double opacity ) {
    for( int i=0; i<_stickers.length; i++ ) {
      _stickers.index( i ).draw( ctx, theme, opacity );
    }
  }

}
