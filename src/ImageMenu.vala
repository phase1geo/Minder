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

public class ImageMenu : Box {

  private MenuButton _mb;
  private Box        _box;
  private int        _size     = 0;
  private int        _selected = -1;
  private int        _current  = 0;

  public int selected {
    get {
      return( _selected );
    }
    set {
      if( _selected != value ) {
        _selected = value;
        var picture = (Picture)Utils.get_child_at_index( _box, _selected );
        _mb.child = new Picture.for_paintable( picture.paintable );
      }
    }
  }

  public signal void changed( int index );

  public signal void update_icons();

  //-------------------------------------------------------------
  // Default constructor
  public ImageMenu() {

    _box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start = 5,
      margin_end   = 5
    };

    var popover = new Popover() {
      child = _box
    };

    _mb = new MenuButton() {
      valign  = Align.CENTER,
      popover = popover
    };

    _mb.activate.connect(() => {
      var picture = (Picture)Utils.get_child_at_index( _box, 0 );
      _current = 0;
      picture.add_css_class( Granite.STYLE_CLASS_VIEW );
    });

    var key = new EventControllerKey();
    _mb.add_controller( key );
    key.key_pressed.connect((keyval, keycode, state) => {
      var index = _current;
      switch( keyval ) {
        case Gdk.Key.Down   :  index = ((_current == (_size - 1)) ? _current : (_current + 1));  break;
        case Gdk.Key.Up     :  index = ((_current == 0)           ? _current : (_current - 1));  break;
        case Gdk.Key.Return :
        case Gdk.Key.space  :
          selected = _current;
          changed( _current );
          _mb.popover.popdown();
          break;
        case Gdk.Key.Escape :
          _mb.popover.popdown();
          break;
      }
      var before = (Picture)Utils.get_child_at_index( _box, _current );
      before.remove_css_class( Granite.STYLE_CLASS_VIEW );
      if( index != _current ) {
        var after  = (Picture)Utils.get_child_at_index( _box, index );
        after.add_css_class( Granite.STYLE_CLASS_VIEW );
      }
      return( false );
    });


    append( _mb );

  }

  //-------------------------------------------------------------
  // Add a button to this model
  public void add_image( Gdk.Paintable light_image, Gdk.Paintable dark_image ) {

    var entry = new Picture.for_paintable( light_image );
    var index = _size++;

    update_icons.connect(() => {
      entry.paintable = Utils.use_dark_mode( this ) ? dark_image : light_image;      
      if( index == selected ) {
        _mb.child = new Picture.for_paintable( entry.paintable );
      }
    });

    var click = new GestureClick();
    entry.add_controller( click );
    click.pressed.connect((n_press, x, y) => {
      selected = index;
      _mb.popover.popdown();
      changed( index );
    });

    var motion = new EventControllerMotion();
    entry.add_controller( motion );
    motion.enter.connect(() => {
      entry.add_css_class( Granite.STYLE_CLASS_VIEW );
    });
    motion.leave.connect(() => {
      entry.remove_css_class( Granite.STYLE_CLASS_VIEW );
    });

    _box.append( entry );

  }

}
