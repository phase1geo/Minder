/*
* Copyright (c) 2024 (https://github.com/phase1geo/Minder)
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

public class ModeButtons : Box {

  private int _selected = -1;

  public int selected {
    get {
      return( _selected );
    }
    set {
      if( _selected != value ) {
        _selected = value;
        var button = (CheckButton)Utils.get_child_at_index( this, value );
        button.active = true;
      }
    }
  }

  public signal void changed( int index );

  //-------------------------------------------------------------
  // Default constructor
  public ModeButtons() {
    add_css_class( Granite.STYLE_CLASS_LINKED );
  }

  //-------------------------------------------------------------
  // Add a button to this model
  public void add_button( string icon_name, string tooltip ) {

    var image = new Image.from_icon_name( icon_name );
    var button = new ToggleButton() {
      child        = image,
      tooltip_text = tooltip
    };

    button.activate.connect(() => {
      _selected = Utils.get_child_index( this, button );
      changed( _selected );
    });

    // This the checkbutton to the group
    var first = get_first_child();
    if( first != null ) {
      button.set_group( (ToggleButton)first );
    } else {
      button.active = true;
    }

    append( button );

  }

}
