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

  private StyleAffects      _affects;
  private Array<Node>       _nodes;
  private Array<Connection> _conns;
  private Array<Callout>    _callouts;

  private enum StyleChangeType {
    LOAD = 0,
    UNDO,
    REDO
  }

  /* Constructor for a node name change */
  public UndoStyleChange( StyleAffects affects, MindMap map ) {
    base( _( "style change" ) );
    _affects  = affects;
    _nodes    = map.get_selected_nodes();
    _conns    = map.get_selected_connections();
    _callouts = map.get_selected_callouts();
  }

  /* Returns true if the given undo item matches our item */
  protected override bool matches( UndoItem item ) {
    UndoStyleChange other = (UndoStyleChange)item;
    if( (_affects == other._affects) && (_nodes.length == other._nodes.length) && (_conns.length == other._conns.length) && (_callouts.length == other._callouts.length) ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) != other._nodes.index( i ) ) {
          return( false );
        }
      }
      for( int i=0; i<_conns.length; i++ ) {
        if( _conns.index( i ) != other._conns.index( i ) ) {
          return( false );
        }
      }
      for( int i=0; i<_callouts.length; i++ ) {
        if( _callouts.index( i ) != other._callouts.index( i ) ) {
          return( false );
        }
      }
    }
    return( false );
  }

  protected void load_styles( MindMap map ) {
    traverse_styles( map, StyleChangeType.LOAD );
  }

  private void traverse_styles( MindMap map, StyleChangeType change_type ) {
    var index    = 1;
    var selected = map.selected;
    switch( _affects ) {
      case StyleAffects.ALL         :
        {
          var nodes = map.get_nodes();
          var conns = map.connections.connections;
          for( int i=0; i<nodes.length; i++ ) {
            set_style_for_tree( nodes.index( i ), change_type, ref index );
          }
          for( int i=0; i<conns.length; i++ ) {
            set_connection_style( conns.index( i ), change_type, ref index );
          }
          if( change_type == StyleChangeType.LOAD ) {
            Style new_style = new Style.templated();
            store_style_value( new_style, 0 );
            StyleInspector.styles.set_all_to_style( new_style );
          }
        }
        break;
      case StyleAffects.SELECTED_NODES :
        var nodes = selected.nodes();
        for( int i=0; i<nodes.length; i++ ) {
          set_node_style( nodes.index( i ), change_type, ref index );
        }
        break;
      case StyleAffects.SELECTED_CONNECTIONS :
        var conns = selected.connections();
        for( int i=0; i<conns.length; i++ ) {
          set_connection_style( conns.index( i ), change_type, ref index );
        }
        break;
      case StyleAffects.SELECTED_CALLOUTS :
        var callouts = selected.callouts();
        for( int i=0; i<callouts.length; i++ ) {
          set_callout_style( callouts.index( i ), change_type, ref index );
        }
        break;
    }
    map.current_changed( map );
    map.auto_save();
    map.queue_draw();
  }

  private void set_style( Style old_style, Style new_style, StyleChangeType change_type, ref int index ) {
    switch( change_type ) {
      case StyleChangeType.LOAD :
        load_style_value( old_style );
        store_style_value( new_style, 0 );
        break;
      case StyleChangeType.UNDO :
        store_style_value( new_style, index++ );
        break;
      case StyleChangeType.REDO :
        store_style_value( new_style, 0 );
        break;
    }
  }

  private void set_node_style( Node node, StyleChangeType change_type, ref int index ) {
    Style new_style = new Style.templated();
    set_style( node.style, new_style, change_type, ref index );
    node.style = new_style;
  }

  private void set_connection_style( Connection conn, StyleChangeType change_type, ref int index ) {
    Style new_style = new Style.templated();
    set_style( conn.style, new_style, change_type, ref index );
    conn.style = new_style;
  }

  private void set_callout_style( Callout callout, StyleChangeType change_type, ref int index ) {
    Style new_style = new Style.templated();
    set_style( callout.style, new_style, change_type, ref index );
    callout.style = new_style;
  }

  private void set_style_for_tree( Node node, StyleChangeType change_type, ref int index ) {
    set_node_style( node, change_type, ref index );
    if( node.callout != null ) {
      set_callout_style( node.callout, change_type, ref index );
    }
    for( int i=0; i<node.children().length; i++ ) {
      set_style_for_tree( node.children().index( i ), change_type, ref index );
    }
  }

  private void set_style_for_level( Node node, int levels, StyleChangeType change_type, ref int index, int level ) {
    if( (levels & (1 << level)) != 0 ) {
      set_node_style( node, change_type, ref index );
      if( node.callout != null ) {
        set_callout_style( node.callout, change_type, ref index );
      }
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
  public override void undo( MindMap map ) {
    traverse_styles( map, StyleChangeType.UNDO );
  }

  /* Redoes a node name change */
  public override void redo( MindMap map ) {
    traverse_styles( map, StyleChangeType.REDO );
  }

  public override string to_string() {
    return( base.to_string() + ", affects: %s".printf( _affects.to_string() )  );
  }

}
