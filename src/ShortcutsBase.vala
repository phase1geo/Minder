/*
* Copyright (c) 2018-21 (https://github.com/phase1geo/Minder)
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

using Gee;
using Gdk;

public class ShortcutsBase {

  protected DrawArea          _da;
  private   HashMap<uint,int> _shortcuts;

  /* Constructor */
  public ShortcutsBase( DrawArea da ) {
    _da        = da;
    _shortcuts = new HashMap<int,int>();
    create_shortcuts();
  }

  /* Adds the keyboard shortcuts */
  protected virtual void create_shortcuts() {}

  /* Runs the given keyboard shortcut */
  protected virtual bool run_shortcut( int index, EventKey e ) {
    return( false );
  }

  /* Creates a new event from the given values */
  private uint create_event( bool control, bool shift, bool alt, uint keyval ) {
    var e = keyval & 0xffff;
    if( control ) {
      e |= 0x10000;
    }
    if( shift ) {
      e |= 0x20000;
    }
    if( alt ) {
      e |= 0x40000;
    }
    return( e );
  }

  /* Adds a new event-method to the list of available keyboard shortcuts */
  protected void add_event( ShortcutType index, bool control, bool shift, bool alt, uint keyval ) {
    var e = create_event( control, shift, alt, keyval );
    _shortcuts.set( e, index );
  }

  /*
   Called whenever the key is pressed.  Looks up the given key to see if it corresponds to a keyboard shortcut.
   If a shortcut is found, it is run and we return true.  If no shortcut matches, we will return false.
  */
  public bool key_pressed( EventKey ek ) {

    var control = (bool)(ek.state & ModifierType.CONTROL_MASK);
    var shift   = (bool)(ek.state & ModifierType.SHIFT_MASK);
    var alt     = (bool)(ek.state & ModifierType.MOD1_MASK);

    /* Convert the hardware keycode to a list of possible keys */
    var keymap = Keymap.get_for_display( Display.get_default() );
    uint[] kvs = {};
    keymap.get_entries_for_keycode( ek.hardware_keycode, null, out kvs );

    for( int i=(kvs.length-1); i>=0; i-- ) {
      var e = create_event( control, shift, alt, kvs[i] );
      if( _shortcuts.has_key( e ) ) {
        return( run_shortcut( _shortcuts.get( e ), ek ) );
      }
    }

    return( false );

  }

}
