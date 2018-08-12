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

class NodeImage {

  private Pixbuf _buf;

  /* Default constructor */
  public NodeImage.from_file( string fname ) {
    // TBD  
  }

  /* Returns the width of the stored image */
  int width() {
    return( _buf.width );
  }

  /* Returns the height of the stored image */
  int height() {
    return( _buf.height );
  }

  /* Draws the image to the given context */
  public void draw( Context ctx, double x, double y ) {
    cairo_set_source_pixbuf( ctx, _buf, x, y );
    ctx.paint();
  }

}
