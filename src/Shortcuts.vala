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
public enum ShortcutType {
  A,
  ALT_Down,
  ALT_Left,
  ALT_Right,
  ALT_SHIFT_Down,
  ALT_SHIFT_Right,
  ALT_SHIFT_Up,
  ALT_Up,
  BackSpace,
  C,
  CONTROL_A,
  CONTROL_C,
  CONTROL_Down,
  CONTROL_End,
  CONTROL_Home,
  CONTROL_Left,
  CONTROL_Return,
  CONTROL_Right,
  CONTROL_SHIFT_A,
  CONTROL_SHIFT_E,
  CONTROL_SHIFT_R,
  CONTROL_SHIFT_Up,
  CONTROL_Tab,
  CONTROL_Up,
  CONTROL_V,
  CONTROL_W,
  CONTROL_X,
  CONTROL_Y,
  CONTROL_period,
  D,
  Delete,
  Down,
  E,
  End,
  Escape,
  F,
  G,
  H,
  Home,
  I,
  J,
  K,
  L,
  Left,
  M,
  Menu,
  N,
  P,
  R,
  Return,
  Right,
  S,
  SHIFT_ALT_Left,
  SHIFT_C,
  SHIFT_CONTROL_Down,
  SHIFT_CONTROL_End,
  SHIFT_CONTROL_Home,
  SHIFT_CONTROL_Left,
  SHIFT_CONTROL_Right,
  SHIFT_CONTROL_V,
  SHIFT_D,
  SHIFT_Down,
  SHIFT_E,
  SHIFT_End,
  SHIFT_F,
  SHIFT_Home,
  SHIFT_I,
  SHIFT_Left,
  SHIFT_Return,
  SHIFT_Right,
  SHIFT_S,
  SHIFT_Up,
  SHIFT_X,
  SHIFT_Y,
  SHIFT_Z,
  T,
  Tab,
  U,
  Up,
  X,
  Y,
  Z,
  bar,
  bracketleft,
  bracketright,
  equal,
  minus,
  underscore
}

public class MinderShortcuts {

  DrawArea                       _da;
  HashMap<EventKey,ShortcutType> _shortcuts;

  /* Constructor */
  public MinderShortcuts( DrawArea da ) {
    _da        = da;
    _shortcuts = new HashMap( null, (a, b) => {
      return( (a.state == b.state) && (a.keyval == b.keyval) );
    });
    create_shortcuts();
  }

  /* Adds the keyboard shortcuts */
  private void create_shortcuts() {
    add_event( ShortcutType.A, false, false, false, Key.a );
    add_event( ShortcutType.CONTROL_Up, true, false, false, Key.Up );
    add_event( ShortcutType.C, false, false, false, Key.c );
    add_event( ShortcutType.D, false, false, false, Key.d );
    add_event( ShortcutType.E, false, false, false, Key.e );
    add_event( ShortcutType.SHIFT_Left, false, true, false, Key.Left );
    add_event( ShortcutType.CONTROL_Return, true, false, false, Key.Return );
    add_event( ShortcutType.Right, false, false, false, Key.Right );
    add_event( ShortcutType.F, false, false, false, Key.f );
    add_event( ShortcutType.G, false, false, false, Key.g );
    add_event( ShortcutType.H, false, false, false, Key.h );
    add_event( ShortcutType.I, false, false, false, Key.i );
    add_event( ShortcutType.J, false, false, false, Key.j );
    add_event( ShortcutType.K, false, false, false, Key.k );
    add_event( ShortcutType.L, false, false, false, Key.l );
    add_event( ShortcutType.M, false, false, false, Key.m );
    add_event( ShortcutType.Menu, false, false, false, Key.Menu );
    add_event( ShortcutType.CONTROL_SHIFT_Up, true, true, false, Key.Up );
    add_event( ShortcutType.N, false, false, false, Key.n );
    add_event( ShortcutType.ALT_SHIFT_Right, false, true, true, Key.Right );
    add_event( ShortcutType.SHIFT_CONTROL_V, true, true, false, Key.V );
    add_event( ShortcutType.P, false, false, false, Key.p );
    add_event( ShortcutType.Escape, false, false, false, Key.Escape );
    add_event( ShortcutType.R, false, false, false, Key.r );
    add_event( ShortcutType.bracketright, false, false, false, Key.bracketright );
    add_event( ShortcutType.ALT_Up, false, false, true, Key.Up );
    add_event( ShortcutType.S, false, false, false, Key.s );
    add_event( ShortcutType.T, false, false, false, Key.t );
    add_event( ShortcutType.U, false, false, false, Key.u );
    add_event( ShortcutType.CONTROL_Down, true, false, false, Key.Down );
    add_event( ShortcutType.SHIFT_C, false, true, false, Key.C );
    add_event( ShortcutType.CONTROL_Home, true, false, false, Key.Home );
    add_event( ShortcutType.End, false, false, false, Key.End );
    add_event( ShortcutType.bracketleft, false, false, false, Key.bracketleft );
    add_event( ShortcutType.SHIFT_D, false, true, false, Key.D );
    add_event( ShortcutType.SHIFT_Up, false, true, false, Key.Up );
    add_event( ShortcutType.X, false, false, false, Key.x );
    add_event( ShortcutType.SHIFT_E, false, true, false, Key.E );
    add_event( ShortcutType.SHIFT_F, false, true, false, Key.F );
    add_event( ShortcutType.Y, false, false, false, Key.y );
    add_event( ShortcutType.SHIFT_End, false, true, false, Key.End );
    add_event( ShortcutType.Z, false, false, false, Key.z );
    add_event( ShortcutType.CONTROL_SHIFT_A, true, true, false, Key.A );
    add_event( ShortcutType.SHIFT_I, false, true, false, Key.I );
    add_event( ShortcutType.CONTROL_End, true, false, false, Key.End );
    add_event( ShortcutType.bar, false, false, false, Key.bar );
    add_event( ShortcutType.ALT_SHIFT_Up, false, true, true, Key.Up );
    add_event( ShortcutType.CONTROL_SHIFT_E, true, true, false, Key.E );
    add_event( ShortcutType.SHIFT_CONTROL_Right, true, true, false, Key.Right );
    add_event( ShortcutType.Tab, false, false, false, Key.Tab );
    add_event( ShortcutType.SHIFT_CONTROL_End, true, true, false, Key.End );
    add_event( ShortcutType.Down, false, false, false, Key.Down );
    add_event( ShortcutType.ALT_SHIFT_Down, false, true, true, Key.Down );
    add_event( ShortcutType.CONTROL_Left, true, false, false, Key.Left );
    add_event( ShortcutType.Home, false, false, false, Key.Home );
    add_event( ShortcutType.Delete, false, false, false, Key.Delete );
    add_event( ShortcutType.CONTROL_Tab, true, false, false, Key.Tab );
    add_event( ShortcutType.BackSpace, false, false, false, Key.BackSpace );
    add_event( ShortcutType.ALT_Down, false, false, true, Key.Down );
    add_event( ShortcutType.SHIFT_S, false, true, false, Key.S );
    add_event( ShortcutType.CONTROL_A, true, false, false, Key.a );
    add_event( ShortcutType.equal, false, false, false, Key.equal );
    add_event( ShortcutType.CONTROL_C, true, false, false, Key.c );
    add_event( ShortcutType.underscore, false, false, false, Key.underscore );
    add_event( ShortcutType.SHIFT_X, false, true, false, Key.X );
    add_event( ShortcutType.CONTROL_SHIFT_R, true, true, false, Key.R );
    add_event( ShortcutType.Left, false, false, false, Key.Left );
    add_event( ShortcutType.SHIFT_ALT_Left, false, true, true, Key.Left );
    add_event( ShortcutType.SHIFT_Y, false, true, false, Key.Y );
    add_event( ShortcutType.CONTROL_Right, true, false, false, Key.Right );
    add_event( ShortcutType.minus, false, false, false, Key.minus );
    add_event( ShortcutType.SHIFT_Z, false, true, false, Key.Z );
    add_event( ShortcutType.Up, false, false, false, Key.Up );
    add_event( ShortcutType.Return, false, false, false, Key.Return );
    add_event( ShortcutType.ALT_Left, false, false, true, Key.Left );
    add_event( ShortcutType.SHIFT_CONTROL_Down, true, true, false, Key.Down );
    add_event( ShortcutType.CONTROL_period, true, false, false, Key.period );
    add_event( ShortcutType.SHIFT_CONTROL_Home, true, true, false, Key.Home );
    add_event( ShortcutType.SHIFT_Right, false, true, false, Key.Right );
    add_event( ShortcutType.SHIFT_Return, false, true, false, Key.Return );
    add_event( ShortcutType.SHIFT_Down, false, true, false, Key.Down );
    add_event( ShortcutType.ALT_Right, false, false, true, Key.Right );
    add_event( ShortcutType.SHIFT_Home, false, true, false, Key.Home );
    add_event( ShortcutType.SHIFT_CONTROL_Left, true, true, false, Key.Left );
    add_event( ShortcutType.CONTROL_V, true, false, false, Key.v );
    add_event( ShortcutType.CONTROL_W, true, false, false, Key.w );
    add_event( ShortcutType.CONTROL_X, true, false, false, Key.x );
    add_event( ShortcutType.CONTROL_Y, true, false, false, Key.y );
  }

  /* Runs the given keyboard shortcut */
  private void run_shortcut( ShortcutType index, EventKey e ) {
    switch( index ) {
      case ShortcutType.A :  _da.select_parent_nodes();;  break;
      case ShortcutType.CONTROL_Up :  _da.handle_control_up( false );;  break;
      case ShortcutType.C :  _da.select_child_node();;  break;
      case ShortcutType.D :  _da.select_child_nodes();;  break;
      case ShortcutType.E :  _da.edit_current_title();;  break;
      case ShortcutType.SHIFT_Left :  _da.handle_left( true, false );;  break;
      case ShortcutType.CONTROL_Return :  _da.handle_control_return();;  break;
      case ShortcutType.Right :  _da.handle_right( false, false );;  break;
      case ShortcutType.F :  _da.toggle_current_fold( false );;  break;
      case ShortcutType.G :  _da.add_group();;  break;
      case ShortcutType.H :  _da.handle_left( false, false );;  break;
      case ShortcutType.I :  _da.show_properties( "current", PropertyGrab.FIRST );;  break;
      case ShortcutType.J :  _da.handle_down( false, false );;  break;
      case ShortcutType.K :  _da.handle_up( false, false );;  break;
      case ShortcutType.L :  _da.handle_right( false, false );;  break;
      case ShortcutType.M :  _da.select_root_node();;  break;
      case ShortcutType.Menu :  _da.show_contextual_menu( e );;  break;
      case ShortcutType.CONTROL_SHIFT_Up :  _da.handle_control_up( true );;  break;
      case ShortcutType.N :  _da.select_sibling_node( 1 );;  break;
      case ShortcutType.ALT_SHIFT_Right :  _da.handle_right( true, true );;  break;
      case ShortcutType.SHIFT_CONTROL_V :  _da.do_paste( true );;  break;
      case ShortcutType.P :  _da.select_sibling_node( -1 );;  break;
      case ShortcutType.Escape :  _da.handle_escape();;  break;
      case ShortcutType.R :  if( _da.undo_buffer.redoable() ) _da.undo_buffer.redo();;  break;
      case ShortcutType.bracketright :  if( _da.nodes_alignable() ) NodeAlign.align_right( _da, _da.selected.nodes() );;  break;
      case ShortcutType.ALT_Up :  _da.handle_up( false, true );;  break;
      case ShortcutType.S :  _da.see();;  break;
      case ShortcutType.T :  _da.toggle_task_done_indicator();;  break;
      case ShortcutType.U :  if( _da.undo_buffer.undoable() ) _da.undo_buffer.undo();;  break;
      case ShortcutType.CONTROL_Down :  _da.handle_control_down( false );;  break;
      case ShortcutType.SHIFT_C :  _da.center_current_node();;  break;
      case ShortcutType.CONTROL_Home :  _da.handle_control_home( false );;  break;
      case ShortcutType.End :  _da.handle_end( false );;  break;
      case ShortcutType.bracketleft :  if( _da.nodes_alignable() ) NodeAlign.align_left( _da, _da.selected.nodes() );;  break;
      case ShortcutType.SHIFT_D :  _da.select_node_tree();;  break;
      case ShortcutType.SHIFT_Up :  _da.handle_up( true, false );;  break;
      case ShortcutType.X :  _da.start_connection( true, false );;  break;
      case ShortcutType.SHIFT_E :  _da.show_properties( "current", PropertyGrab.NOTE );;  break;
      case ShortcutType.SHIFT_F :  _da.toggle_current_fold( true );;  break;
      case ShortcutType.Y :  _da.toggle_links();;  break;
      case ShortcutType.SHIFT_End :  _da.handle_end( true );;  break;
      case ShortcutType.Z :  _da.zoom_out();;  break;
      case ShortcutType.CONTROL_SHIFT_A :  _da.deselect_all();;  break;
      case ShortcutType.SHIFT_I :  _da.run_debug();;  break;
      case ShortcutType.CONTROL_End :  _da.handle_control_end( false );;  break;
      case ShortcutType.bar :  if( _da.nodes_alignable() ) NodeAlign.align_vcenter( _da, _da.selected.nodes() );;  break;
      case ShortcutType.ALT_SHIFT_Up :  _da.handle_up( true, true );;  break;
      case ShortcutType.CONTROL_SHIFT_E :  _da.handle_control_E();;  break;
      case ShortcutType.SHIFT_CONTROL_Right :  _da.handle_control_right( true );;  break;
      case ShortcutType.Tab :  _da.handle_tab();;  break;
      case ShortcutType.SHIFT_CONTROL_End :  _da.handle_control_end( true );;  break;
      case ShortcutType.Down :  _da.handle_down( false, false );;  break;
      case ShortcutType.ALT_SHIFT_Down :  _da.handle_down( true, true );;  break;
      case ShortcutType.CONTROL_Left :  _da.handle_control_left( false );;  break;
      case ShortcutType.Home :  _da.handle_home( false );;  break;
      case ShortcutType.Delete :  _da.handle_delete();;  break;
      case ShortcutType.CONTROL_Tab :  _da.handle_control_tab();;  break;
      case ShortcutType.BackSpace :  _da.handle_backspace();;  break;
      case ShortcutType.ALT_Down :  _da.handle_down( false, true );;  break;
      case ShortcutType.SHIFT_S :  _da.sort_alphabetically();;  break;
      case ShortcutType.CONTROL_A :  _da.select_all();;  break;
      case ShortcutType.equal :  if( _da.nodes_alignable() ) NodeAlign.align_hcenter( _da, _da.selected.nodes() );;  break;
      case ShortcutType.CONTROL_C :  _da.do_copy();;  break;
      case ShortcutType.underscore :  if( _da.nodes_alignable() ) NodeAlign.align_bottom( _da, _da.selected.nodes() );;  break;
      case ShortcutType.SHIFT_X :  _da.select_attached_connection();;  break;
      case ShortcutType.CONTROL_SHIFT_R :  _da.handle_control_R();;  break;
      case ShortcutType.Left :  _da.handle_left( false, false );;  break;
      case ShortcutType.SHIFT_ALT_Left :  _da.handle_left( true, true );;  break;
      case ShortcutType.SHIFT_Y :  _da.select_linked_node();;  break;
      case ShortcutType.CONTROL_Right :  _da.handle_control_right( false );;  break;
      case ShortcutType.minus :  if( _da.nodes_alignable() ) NodeAlign.align_top( _da, _da.selected.nodes() );;  break;
      case ShortcutType.SHIFT_Z :  _da.zoom_in();;  break;
      case ShortcutType.Up :  _da.handle_up( false, false );;  break;
      case ShortcutType.Return :  _da.handle_return( false );;  break;
      case ShortcutType.ALT_Left :  _da.handle_left( false, true );;  break;
      case ShortcutType.SHIFT_CONTROL_Down :  _da.handle_control_down( true );;  break;
      case ShortcutType.CONTROL_period :  _da.handle_control_period();;  break;
      case ShortcutType.SHIFT_CONTROL_Home :  _da.handle_control_home( true );;  break;
      case ShortcutType.SHIFT_Right :  _da.handle_right( true, false );;  break;
      case ShortcutType.SHIFT_Return :  _da.handle_return( true );;  break;
      case ShortcutType.SHIFT_Down :  _da.handle_down( true, false );;  break;
      case ShortcutType.ALT_Right :  _da.handle_right( false, true );;  break;
      case ShortcutType.SHIFT_Home :  _da.handle_home( true );;  break;
      case ShortcutType.SHIFT_CONTROL_Left :  _da.handle_control_left( true );;  break;
      case ShortcutType.CONTROL_V :  _da.do_paste( false );;  break;
      case ShortcutType.CONTROL_W :  _da.handle_control_w();;  break;
      case ShortcutType.CONTROL_X :  _da.do_cut();;  break;
      case ShortcutType.CONTROL_Y :  _da.do_paste_node_link();;  break;
    }
  }

  /* Creates a new event from the given values */
  private EventKey create_event( bool control, bool shift, bool alt, uint keyval ) {
    var e = new Event( EventType.KEY_PRESS );
    if( control ) {
      e.key.state |= ModifierType.CONTROL_MASK;
    }
    if( shift ) {
      e.key.state |= ModifierType.SHIFT_MASK;
    }
    if( alt ) {
      e.key.state |= ModifierType.MOD1_MASK;
    }
    e.key.keyval = keyval;
    return( e.key );
  }

  /* Adds a new event-method to the list of available keyboard shortcuts */
  private void add_event( ShortcutType index, bool control, bool shift, bool alt, uint keyval ) {
    var e = create_event( control, shift, alt, keyval );
    _shortcuts.set( e, index );
  }

  /*
   Called whenever the key is pressed.  Looks up the given key to see if it corresponds to a keyboard shortcut.
   If a shortcut is found, it is run and we return true.  If no shortcut matches, we will return false. 
  */
  public bool key_pressed( EventKey ek ) {

    var e = ek.copy();

    /* Convert the hardware keycode to a list of possible keys */
    var keymap = Keymap.get_for_display( Display.get_default() );
    uint[] kvs = {};
    keymap.get_entries_for_keycode( ek.hardware_keycode, null, out kvs );

    for( int i=(kvs.length-1); i>=0; i-- ) {
      e.key.keyval = kvs[i];
      if( _shortcuts.has_key( e.key ) ) {
        run_shortcut( _shortcuts.get( e.key ), ek );
        return( true );
      }
    }

    return( false );

  }

}
