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

public class Selection {

  Array<Node>       _nodes;
  Array<Connection> _conns;

  /* Default constructor */
  public Selection() {
    _nodes = new Array<Node>();
    _conns = new Array<Connection>();
  }

  /* Returns true if the given node is currently selected */
  public bool is_node_selected( Node node ) {
    return( node.mode == NodeMode.CURRENT );
  }

  /* Returns true if the given connection is currently selected */
  public bool is_sonnection_selected( Connection conn ) {
    return( conn.mode == ConnMode.SELECTED );
  }

  /* Returns true if the given node is the only selected item */
  public bool is_current_node( Node node ) {
    return( (_nodes.length == 1) && (_nodes.index( 0 ) == node) );
  }

  /* Returns true if the given connection is the only selected item */
  public bool is_current_connection( Connection conn ) {
    return( (_conns.length == 1) && (_conns.index( 0 ) == conn) );
  }

  /* Returns the currently selected node */
  public Node? current_node() {
    return( (_nodes.length == 1) ? _nodes.index( 0 ) : null );
  }

  /* Returns the currently selected connection */
  public Connection? current_connection() {
    return( (_conns.length == 1) ? _conns.index( 0 ) : null );
  }

  /* Sets the current node, clearing all other selected nodes and connections */
  public void set_current_node( Node node, double clear_alpha = 1.0 ) {
    clear( clear_alpha );
    add_node( node );
  }

  /* Sets the current connection, clearing all other selected nodes and connections */
  public void set_current_connection( Connection conn, double clear_alpha = 1.0 ) {
    clear( clear_alpha );
    add_connection( conn );
  }

  /* Adds a node to the current selection.  Returns true if the node was added. */
  public bool add_node( Node node ) {
    if( is_node_selected( node ) ) return( false );
    node.mode = NodeMode.CURRENT;
    _nodes.append_val( node );
    return( true );
  }

  /* Adds a connection to the current selection */
  public bool add_connection( Connection conn ) {
    if( is_connection_selected( conn ) ) return( false );
    conn.mode = ConnMode.SELECTED;
    _conns.append_val( conn );
    return( true );
  }

  /*
   Removes the given node from the current selection.  Returns true if the
   node is removed.
  */
  public bool remove_node( Node node, double alpha = 1.0 ) {
    if( is_node_selected( node ) ) {
      node.mode  = NodeMode.NONE;
      node.alpha = alpha;
      for( int i=0; i<_nodes.length; i++ ) {
        if( node == _nodes.index( i ) ) {
          _nodes.remove_index( i );
          return( true );
        }
      }
    }
    return( false );
  }

  /*
   Removes the given connection from the current selection.  Returns true
   if the connection is removed.
  */
  public bool remove_connection( Connection conn, double alpha = 1.0 ) {
    if( is_connection_selected( conn ) ) {
      conn.mode  = ConnMode.NONE;
      conn.alpha = alpha;
      for( int i=0; i<_conns.length; i++ ) {
        if( conn == _conns.index( i ) ) {
          _conns.remove_index( i );
          return( true );
        }
      }
    }
    return( false );
  }

  /* Clears all of the selected nodes */
  public void clear_nodes( double alpha = 1.0 ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).mode  = NodeMode.NONE;
      _nodes.index( i ).alpha = alpha;
    }
    _nodes.remove_range( 0, _nodes.length );
  }

  /* Clears all of the selected connections */
  public void clear_connections( double alpha = 1.0 ) {
    for( int i=0; i<_conns.length; i++ ) {
      _conns.index( i ).mode  = ConnMode.NONE;
      _conns.index( i ).alpha = alpha;
    }
    _conns.remove_range( 0, _conns.length );
  }

  /* Clears the current selection */
  public void clear( double alpha = 1.0 ) {
    clear_nodes( alpha );
    clear_connections( alpha );
  }

  /* Returns the number of nodes selected */
  public int num_nodes() {
    return( _nodes.length );
  }

  /* Returns the number of connections selected */
  public int num_connections() {
    return( _conns.length );
  }

  /* Returns an array of currently selected nodes */
  public Array<Node> nodes() {
    return( _nodes );
  }

  /* Returns an array of currently selected connections */
  public Array<Connection> connections() {
    return( _conns );
  }

}
