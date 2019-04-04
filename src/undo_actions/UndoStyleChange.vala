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

  private StyleAffects _affects;
  private Node?        _node;
  private Connection?  _conn;

  private enum StyleChangeType {
    LOAD = 0,
    UNDO,
    REDO
  }

  /* Constructor for a node name change */
  public UndoStyleChange( StyleAffects affects, DrawArea da ) {
    base( _( "style change" ) );
    _affects = affects;
    _node    = da.get_current_node();
    _conn    = da.get_current_connection();
  }

  protected void load_styles( DrawArea da ) {
    traverse_styles( da, StyleChangeType.LOAD );
  }

  private void traverse_styles( DrawArea da, StyleChangeType change_type ) {
    int index = 1;
    switch( _affects ) {
      case StyleAffects.ALL         :
        for( int i=0; i<da.get_nodes().length; i++ ) {
          set_style_for_tree( da.get_nodes().index( i ), change_type, ref index );
        }
        break;
      case StyleAffects.LEVEL0      :
      case StyleAffects.LEVEL1      :
      case StyleAffects.LEVEL2      :
      case StyleAffects.LEVEL3      :
      case StyleAffects.LEVEL4      :
      case StyleAffects.LEVEL5      :
      case StyleAffects.LEVEL6      :
      case StyleAffects.LEVEL7      :
      case StyleAffects.LEVEL8      :
      case StyleAffects.LEVEL9      :
        for( int i=0; i<da.get_nodes().length; i++ ) {
          set_style_for_level( da.get_nodes().index( i ), (int)_affects.level(), change_type, ref index, 0 );
        }
        break;
      case StyleAffects.CURRENT     :
        if( _node != null ) {
          set_style( _node.style, change_type, ref index );
        } else {
          set_style( _conn.style, change_type, ref index );
        }
        break;
      case StyleAffects.CURRTREE    :
        set_style_for_tree( _node.get_root(), change_type, ref index );
        break;
      case StyleAffects.CURRSUBTREE :
        set_style_for_tree( _node, change_type, ref index );
        break;
    }
    da.changed();
    da.queue_draw();
  }

  private void set_style( Style style, StyleChangeType change_type, ref int index ) {
    switch( change_type ) {
      case StyleChangeType.LOAD :
        load_style_value( style );
        store_style_value( style, 0 );
        break;
      case StyleChangeType.UNDO :
        store_style_value( style, index++ );
        break;
      case StyleChangeType.REDO :
        store_style_value( style, 0 );
        break;
    }
  }

  private void set_style_for_tree( Node node, StyleChangeType change_type, ref int index ) {
    set_style( node.style, change_type, ref index );
    for( int i=0; i<node.children().length; i++ ) {
      set_style_for_tree( node.children().index( i ), change_type, ref index );
    }
  }

  private void set_style_for_level( Node node, int levels, StyleChangeType change_type, ref int index, int level ) {
    if( (levels & (1 << level)) != 0 ) {
      set_style( node.style, change_type, ref index );
    }
    for( int i=0; i<node.children().length; i++ ) {
      set_style_for_level( node.children().index( i ), levels, change_type, ref index, ((level == 9) ? 9 : (level + 1)) );
    }
  }

  protected virtual void load_style_value( Style style ) {
    /* This method will be overridden */
  }

  protected virtual void store_style_value( Style style, int index ) {
    /* This method will be overridden */
  }

  /* Undoes a node name change */
  public override void undo( DrawArea da ) {
    traverse_styles( da, StyleChangeType.UNDO );
  }

  /* Redoes a node name change */
  public override void redo( DrawArea da ) {
    traverse_styles( da, StyleChangeType.REDO );
  }

}
