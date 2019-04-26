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

public class Connections {

  private Array<Connection> _connections;

  public bool hide { set; get; default = false; }

  /* Default constructor */
  public Connections() {
    _connections = new Array<Connection>();
  }

  /* Removes all connections */
  public void clear_all_connections() {
    _connections.remove_range( 0, _connections.length );
  }

  /* Adds the given connection */
  public void add_connection( Connection conn ) {
    /* Don't add the connection if it has already been added */
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ) == conn ) {
        return;
      }
    }
    _connections.append_val( conn );
  }

  /* Removes the given connection */
  public bool remove_connection( Connection conn ) {
    for( uint i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ) == conn ) {
        _connections.index( i ).disconnect( true );
        _connections.index( i ).disconnect( false );
        _connections.remove_index( i ); 
        return( true );
      }
    }
    return( false );
  }

  /*
   Returns the associated connection if the given point is in proximity to the
   connection's curve.
  */
  public Connection? on_curve( double x, double y ) {
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ).on_curve( x, y ) ) {
        return( _connections.index( i ) );
      }
    }
    return( null );
  }

  /*
   Returns the associated connection if the given point is within the connection's
   title text.
  */
  public Connection? within_title( double x, double y ) {
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ).within_title( x, y ) ) {
        return( _connections.index( i ) );
      }
    }
    return( null );
  }

  /* Returns the associated connection if the given point is within the drag handle */
  public Connection? within_drag_handle( double x, double y ) {
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ).within_drag_handle( x, y ) ) {
        return( _connections.index( i ) );
      }
    }
    return( null );
  }

  /*
   Called whenever a node is deleted in the mind map.  All attached connections
   also need to be removed.
  */
  public void node_deleted( Node node ) {
    for( int i=0; i<node.children().length; i++ ) {
      node_deleted( node.children().index( i ) );
    }
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ).attached_to_node( node ) ) {
        _connections.remove_index( i );
      }
    }
  }

  /* Loads the listed connections from the given XML data */
  public void load( DrawArea da, Xml.Node* node ) {
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "connection" ) {
          var conn = new Connection.from_xml( da, it );
          _connections.append_val( conn );
        }
      }
    }
  }

  /* Saves the connection information to the given XML file */
  public void save( Xml.Node* parent ) {
    if( _connections.length > 0 ) {
      Xml.Node* n = new Xml.Node( null, "connections" );
      for( int i=0; i<_connections.length; i++ ) {
        _connections.index( i ).save( n );
      }
      parent->add_child( n );
    }
  }

  /* Set all of the stored connections to the given style */
  public void set_all_connections_to_style( Style style ) {
    for( int i=0; i<_connections.length; i++ ) {
      _connections.index( i ).style = style;
    }
  }

  /* Draws all of the connections onto the given context */
  public void draw_all( Cairo.Context ctx, Theme theme ) {
    if( hide ) return;
    for( int i=0; i<_connections.length; i++ ) {
      _connections.index( i ).draw( ctx, theme );
    }
  }

}
