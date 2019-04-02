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

public class UndoStyleChange : UndoItem {

  StyleAffects _affects;
  Style        _old_style;
  Style        _new_style;
  Node?        _node;
  Connection?  _conn;

  /* Constructor for a node name change */
  public UndoStyleChange( StyleAffects affects, Style style, Node? node, Connection? conn ) {
    base( _( "style change" ) );
    _affects   = affects;
    _new_style = new Style.templated();
    _old_style = new Style.templated();
    _node      = node;
    _conn      = conn;
    switch( affects ) {
      case StyleAffects.ALL         :  _old_style.copy_alias( style, StyleInspector.styles.get_global_style() );  break;
      case StyleAffects.LEVEL0      :
      case StyleAffects.LEVEL1      :
      case StyleAffects.LEVEL2      :
      case StyleAffects.LEVEL3      :
      case StyleAffects.LEVEL4      :
      case StyleAffects.LEVEL5      :
      case StyleAffects.LEVEL6      :
      case StyleAffects.LEVEL7      :
      case StyleAffects.LEVEL8      :
      case StyleAffects.LEVEL9      :  _old_style.copy_alias( style, StyleInspector.styles.get_style_for_level( affects.level() ) );  break;
      case StyleAffects.CURRENT     :  _old_style.copy_alias( style, ((_node != null) ? _node.style : _conn.style) );  break;
      case StyleAffects.CURRTREE    :  _old_style.copy_alias( style, _node.get_root().style );  break;
      case StyleAffects.CURRSUBTREE :  _old_style.copy_alias( style, _node.style );  break;
    }
    _new_style.copy( style );
  }

  /* Undoes a node name change */
  public override void undo( DrawArea da ) {
    StyleInspector.apply_style_change( da, _affects, _old_style, _node, _conn );
  }

  /* Redoes a node name change */
  public override void redo( DrawArea da ) {
    StyleInspector.apply_style_change( da, _affects, _new_style, _node, _conn );
  }

}
