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

using Gdk;

public class ColorPalette : Object {

  // private int  _index = 0;
  private RGBA   _color;
  private RGBA[] _colors;
  private int    _index = 0;

  public ColorPalette() {
    /*
    _color.red   = 0;
    _color.green = 0;
    _color.blue  = 0;
    _color.alpha = 1;
    */
    RGBA color = {0.0, 0.0, 0.0, 1.0};
    color.parse( "red" );     _colors += color;
    color.parse( "orange" );  _colors += color;
    color.parse( "yellow" );  _colors += color;
    color.parse( "green" );   _colors += color;
    color.parse( "blue" );    _colors += color;
    color.parse( "purple" );  _colors += color;
  }

  /* Returns the next color to use */
  public RGBA next() {
    RGBA color = _colors[_index];
    _index = (_index + 1) % _colors.length;
    return( color );
  }

}
