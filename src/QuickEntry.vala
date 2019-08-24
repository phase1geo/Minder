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

public class QuickEntry : Window {

  private TextView _entry;

  public QuickEntry( DrawArea da ) {

    /* Configure the window */
    default_width   = 500;
    default_height  = 500;
    modal           = true;
    deletable       = false;
    title           = _( "Quick Entry" );
    transient_for   = da.win;
    window_position = WindowPosition.CENTER_ON_PARENT;

    /* Add window elements */
    var box = new Box( Orientation.VERTICAL, 5 );

    _entry = new TextView();
    _entry.set_wrap_mode( Gtk.WrapMode.WORD );

    var bbox = new Box( Orientation.HORIZONTAL, 5 );

    var cancel = new Button.with_label( _( "Cancel" ) );
    cancel.clicked.connect(() => {
      close();
    });

    var ins = new Button.with_label( _( "Insert" ) );
    ins.get_style_context().add_class( STYLE_CLASS_SUGGESTED_ACTION );
    ins.clicked.connect(() => {
      ExportText.import_text( _entry.buffer.text, 8, da, false );
      close();
    });

    bbox.pack_end( ins,    false, false );
    bbox.pack_end( cancel, false, false );

    box.pack_start( _entry, true,  true );
    box.pack_end(   bbox,   false, true );

    add( box );

    show_all();

  }

}
