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
using Gdk;
using Granite.Widgets;

public class EmptyInspector : Box {

  public EmptyInspector( MainWindow win ) {

    var empty_lbl = new Label( "<big>" + _( "Select a node, connection or group\nto view/edit information" ) + "</big>" ) {
      halign     = Align.FILL,
      hexpand    = true,
      valign     = Align.CENTER,
      use_markup = true,
      justify    = Justification.CENTER
    };

    append( empty_lbl );

  }

  /* Returns the width of this window */
  public int get_width() {
    return( 300 );
  }

}
