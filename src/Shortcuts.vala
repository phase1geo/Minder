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
  Control_L,
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
  Page_Down,
  Page_Up,
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
  SHIFT_F10,
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

public class MinderShortcuts : ShortcutsBase {

  /* Constructor */
  public MinderShortcuts( DrawArea da ) {
    base( da );
  }

  /* Adds the keyboard shortcuts */
  protected override void create_shortcuts() {
    add_event( ShortcutType.A, false, false, false, Key.a );
    add_event( ShortcutType.CONTROL_Up, true, false, false, Key.Up );
    add_event( ShortcutType.C, false, false, false, Key.c );
    add_event( ShortcutType.D, false, false, false, Key.d );
    add_event( ShortcutType.E, false, false, false, Key.e );
    add_event( ShortcutType.SHIFT_Left, false, true, false, Key.Left );
    add_event( ShortcutType.F, false, false, false, Key.f );
    add_event( ShortcutType.CONTROL_Return, true, false, false, Key.Return );
    add_event( ShortcutType.Right, false, false, false, Key.Right );
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
    add_event( ShortcutType.SHIFT_F10, false, true, false, Key.F10 );
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
    add_event( ShortcutType.Page_Down, false, false, false, Key.Page_Down );
    add_event( ShortcutType.minus, false, false, false, Key.minus );
    add_event( ShortcutType.SHIFT_Z, false, true, false, Key.Z );
    add_event( ShortcutType.Up, false, false, false, Key.Up );
    add_event( ShortcutType.Return, false, false, false, Key.Return );
    add_event( ShortcutType.ALT_Left, false, false, true, Key.Left );
    add_event( ShortcutType.SHIFT_CONTROL_Down, true, true, false, Key.Down );
    add_event( ShortcutType.CONTROL_period, true, false, false, Key.period );
    add_event( ShortcutType.SHIFT_CONTROL_Home, true, true, false, Key.Home );
    add_event( ShortcutType.Control_L, false, false, false, Key.Control_L );
    add_event( ShortcutType.SHIFT_Right, false, true, false, Key.Right );
    add_event( ShortcutType.Page_Up, false, false, false, Key.Page_Up );
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
  protected override bool run_shortcut( int index, EventKey e ) {
    switch( index ) {
      case ShortcutType.A :  return( _da.select_parent_nodes() );
      case ShortcutType.CONTROL_Up :  return( _da.handle_control_up( false ) );
      case ShortcutType.C :  return( _da.select_child_node() );
      case ShortcutType.D :  return( _da.select_child_nodes() );
      case ShortcutType.E :  return( _da.edit_current_title() );
      case ShortcutType.SHIFT_Left :  return( _da.handle_left( true, true, false ) );
      case ShortcutType.F :  return( _da.handle_f( false ) );
      case ShortcutType.CONTROL_Return :  return( _da.handle_control_return() );
      case ShortcutType.Right :  return( _da.handle_right( true, false, false ) );
      case ShortcutType.G :  return( _da.add_group() );
      case ShortcutType.H :  return( _da.handle_left( false, false, false ) );
      case ShortcutType.I :  return( _da.show_current_properties( false ) );
      case ShortcutType.J :  return( _da.handle_down( false, false, false ) );
      case ShortcutType.K :  return( _da.handle_up( false, false, false ) );
      case ShortcutType.L :  return( _da.handle_right( false, false, false ) );
      case ShortcutType.M :  return( _da.select_root_node() );
      case ShortcutType.Menu :  return( _da.show_contextual_menu( e ) );
      case ShortcutType.CONTROL_SHIFT_Up :  return( _da.handle_control_up( true ) );
      case ShortcutType.N :  return( _da.handle_n() );
      case ShortcutType.ALT_SHIFT_Right :  return( _da.handle_right( true, true, true ) );
      case ShortcutType.SHIFT_CONTROL_V :  return( _da.do_paste( true ) );
      case ShortcutType.P :  return( _da.handle_p() );
      case ShortcutType.Escape :  return( _da.handle_escape() );
      case ShortcutType.R :  return( _da.redo() );
      case ShortcutType.SHIFT_F10 :  return( _da.show_contextual_menu( e ) );
      case ShortcutType.bracketright :  return( _da.align_right() );
      case ShortcutType.ALT_Up :  return( _da.handle_up( true, false, true ) );
      case ShortcutType.S :  return( _da.see() );
      case ShortcutType.T :  return( _da.handle_t() );
      case ShortcutType.U :  return( _da.undo() );
      case ShortcutType.CONTROL_Down :  return( _da.handle_control_down( false ) );
      case ShortcutType.SHIFT_C :  return( _da.center_current_node() );
      case ShortcutType.CONTROL_Home :  return( _da.handle_control_home( false ) );
      case ShortcutType.End :  return( _da.handle_end( false ) );
      case ShortcutType.bracketleft :  return( _da.align_left() );
      case ShortcutType.SHIFT_D :  return( _da.select_node_tree() );
      case ShortcutType.SHIFT_Up :  return( _da.handle_up( true, true, false ) );
      case ShortcutType.X :  return( _da.handle_x() );
      case ShortcutType.SHIFT_E :  return( _da.show_current_properties( true ) );
      case ShortcutType.SHIFT_F :  return( _da.handle_f( true ) );
      case ShortcutType.Y :  return( _da.toggle_links() );
      case ShortcutType.SHIFT_End :  return( _da.handle_end( true ) );
      case ShortcutType.Z :  return( _da.handle_z( false ) );
      case ShortcutType.CONTROL_SHIFT_A :  return( _da.deselect_all() );
      case ShortcutType.SHIFT_I :  return( _da.run_debug() );
      case ShortcutType.CONTROL_End :  return( _da.handle_control_end( false ) );
      case ShortcutType.bar :  return( _da.align_vcenter() );
      case ShortcutType.ALT_SHIFT_Up :  return( _da.handle_up( true, true, true ) );
      case ShortcutType.CONTROL_SHIFT_E :  return( _da.handle_control_E() );
      case ShortcutType.SHIFT_CONTROL_Right :  return( _da.handle_control_right( true ) );
      case ShortcutType.Tab :  return( _da.handle_tab() );
      case ShortcutType.SHIFT_CONTROL_End :  return( _da.handle_control_end( true ) );
      case ShortcutType.Down :  return( _da.handle_down( true, false, false ) );
      case ShortcutType.ALT_SHIFT_Down :  return( _da.handle_down( true, true, true ) );
      case ShortcutType.CONTROL_Left :  return( _da.handle_control_left( false ) );
      case ShortcutType.Home :  return( _da.handle_home( false ) );
      case ShortcutType.Delete :  return( _da.handle_delete() );
      case ShortcutType.CONTROL_Tab :  return( _da.handle_control_tab() );
      case ShortcutType.BackSpace :  return( _da.handle_backspace() );
      case ShortcutType.ALT_Down :  return( _da.handle_down( true, false, true ) );
      case ShortcutType.SHIFT_S :  return( _da.sort_alphabetically() );
      case ShortcutType.CONTROL_A :  return( _da.select_all() );
      case ShortcutType.equal :  return( _da.align_hcenter() );
      case ShortcutType.CONTROL_C :  return( _da.do_copy() );
      case ShortcutType.underscore :  return( _da.align_bottom() );
      case ShortcutType.SHIFT_X :  return( _da.select_attached_connection() );
      case ShortcutType.CONTROL_SHIFT_R :  return( _da.handle_control_R() );
      case ShortcutType.Left :  return( _da.handle_left( true, false, false ) );
      case ShortcutType.SHIFT_ALT_Left :  return( _da.handle_left( true, true, true ) );
      case ShortcutType.SHIFT_Y :  return( _da.select_linked_node() );
      case ShortcutType.CONTROL_Right :  return( _da.handle_control_right( false ) );
      case ShortcutType.Page_Down :  return( _da.handle_pagedn() );
      case ShortcutType.minus :  return( _da.align_top() );
      case ShortcutType.SHIFT_Z :  return( _da.handle_z( true ) );
      case ShortcutType.Up :  return( _da.handle_up( true, false, false ) );
      case ShortcutType.Return :  return( _da.handle_return( false ) );
      case ShortcutType.ALT_Left :  return( _da.handle_left( true, false, true ) );
      case ShortcutType.SHIFT_CONTROL_Down :  return( _da.handle_control_down( true ) );
      case ShortcutType.CONTROL_period :  return( _da.handle_control_period() );
      case ShortcutType.SHIFT_CONTROL_Home :  return( _da.handle_control_home( true ) );
      case ShortcutType.Control_L :  return( _da.handle_control( true ) );
      case ShortcutType.SHIFT_Right :  return( _da.handle_right( true, true, false ) );
      case ShortcutType.Page_Up :  return( _da.handle_pageup() );
      case ShortcutType.SHIFT_Return :  return( _da.handle_return( true ) );
      case ShortcutType.SHIFT_Down :  return( _da.handle_down( true, true, false ) );
      case ShortcutType.ALT_Right :  return( _da.handle_right( true, false, true ) );
      case ShortcutType.SHIFT_Home :  return( _da.handle_home( true ) );
      case ShortcutType.SHIFT_CONTROL_Left :  return( _da.handle_control_left( true ) );
      case ShortcutType.CONTROL_V :  return( _da.do_paste( false ) );
      case ShortcutType.CONTROL_W :  return( _da.handle_control_w() );
      case ShortcutType.CONTROL_X :  return( _da.do_cut() );
      case ShortcutType.CONTROL_Y :  return( _da.do_paste_node_link() );
    }
    return( false );
  }

}
