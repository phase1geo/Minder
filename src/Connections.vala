 /*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

public class Connections {

  private Array<Connection> _connections;

  public Array<Connection> connections {
    get {
      return( _connections );
    }
  }

  public bool hide { set; get; default = false; }

  //-------------------------------------------------------------
  // Default constructor.
  public Connections() {
    _connections = new Array<Connection>();
  }

  //-------------------------------------------------------------
  // Removes all connections.
  public void clear_all_connections() {
    _connections.remove_range( 0, _connections.length );
  }

  //-------------------------------------------------------------
  // Adds the given connection being sure not to add a connection
  // that already exists.
  public void add_connection( Connection conn ) {
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ) == conn ) {
        return;
      }
    }
    _connections.append_val( conn );
  }

  //-------------------------------------------------------------
  // Adds an array of connections.
  public void add_connections( Array<Connection> conns ) {
    for( int i=0; i<conns.length; i++ ) {
      add_connection( conns.index( i ) );
    }
  }

  //-------------------------------------------------------------
  // Removes the given connection.
  public bool remove_connection( Connection conn, bool disconnect ) {
    for( uint i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ) == conn ) {
        if( disconnect ) {
          _connections.index( i ).disconnect_from_node( true );
          _connections.index( i ).disconnect_from_node( false );
        }
        _connections.remove_index( i );
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Removes an array of connections
  public void remove_connections( Array<Connection> conns, bool disconnect ) {
    for( int i=0; i<conns.length; i++ ) {
      remove_connection( conns.index( i ), disconnect );
    }
  }

  //-------------------------------------------------------------
  // Complete the stored connections.
  public void complete_connection( int index, Node to_node ) {
    _connections.index( index ).connect_to( to_node );
  }

  //-------------------------------------------------------------
  // Returns the connection that is before or after the given
  // connection.
  public Connection? get_connection( Connection conn, int dir ) {
    if( _connections.length == 1 ) return( null );
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ) == conn ) {
        int index = ((i + dir) < 0) ? (int)(_connections.length - 1) : (int)((i + dir) % _connections.length);
        return( _connections.index( index ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the index'th connection that is attached to the
  // given node; otherwise, returns null if the node does not
  // contain a connection.
  public Connection? get_attached_connection( Node node, int index = 0 ) {
    int matches = 0;
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ).attached_to_node( node ) && (index == matches++) ) {
        return( _connections.index( i ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the associated connection if the given point is in
  // proximity to the connection's curve.
  public Connection? on_curve( double x, double y ) {
    if( !hide ) {
      for( int i=0; i<_connections.length; i++ ) {
        if( _connections.index( i ).on_curve( x, y ) ) {
          return( _connections.index( i ) );
        }
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the associated connection if the given point is
  // within the connection's title box.
  public Connection? within_title_box( double x, double y ) {
    if( !hide ) {
      for( int i=0; i<_connections.length; i++ ) {
        if( _connections.index( i ).within_title_box( x, y ) ) {
          return( _connections.index( i ) );
        }
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the associated connection if the given point is
  // within the connection's title text.
  public Connection? within_title( double x, double y ) {
    if( !hide ) {
      for( int i=0; i<_connections.length; i++ ) {
        if( _connections.index( i ).within_title( x, y ) ) {
          return( _connections.index( i ) );
        }
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Searches the connections for one which is displaying a note
  // at the given coordinates.  If a match is found, return the
  // connection; otherwise, return null.
  public Connection? within_note( double x, double y ) {
    if( !hide ) {
      for( int i=0; i<_connections.length; i++ ) {
        if( _connections.index( i ).within_note( x, y ) ) {
          return( _connections.index( i ) );
        }
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the associated connection if the given point is
  // within the drag handle.
  public Connection? within_drag_handle( double x, double y ) {
    if( !hide ) {
      for( int i=0; i<_connections.length; i++ ) {
        if( _connections.index( i ).within_drag_handle( x, y ) ) {
          return( _connections.index( i ) );
        }
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the associated connection and its component that is
  // within the given X,Y coordinates.
  public Connection? within( double x, double y, out MapItemComponent component ) {
    if( !hide ) {
      for( int i=0; i<_connections.length; i++ ) {
        var conn = _connections.index( i );
        if( conn.within_title_box( x, y ) ) {
          if( conn.within_title( x, y ) ) {
            component = MapItemComponent.TITLE;
          } else if( conn.within_note( x, y ) ) {
            component = MapItemComponent.NOTE;
          } else if( conn.within_sticker( x, y ) ) {
            component = MapItemComponent.STICKER;
          } else {
            component = MapItemComponent.TITLE_BOX;
          }
          return( conn );
        } else if( conn.within_drag_handle( x, y ) ) {
          component = MapItemComponent.DRAG_HANDLE;
          return( conn );
        } else if( conn.within_from_handle( x, y ) ) {
          component = MapItemComponent.FROM_HANDLE;
          return( conn );
        } else if( conn.within_to_handle( x, y ) ) {
          component = MapItemComponent.TO_HANDLE;
          return( conn );
        } else if( conn.on_curve( x, y ) ) {
          component = MapItemComponent.CURVE;
          return( conn );
        }
      }
    }
    component = MapItemComponent.NONE;
    return( null );
  }

  //-------------------------------------------------------------
  // Called whenever a node is deleted in the mind map.  All
  // attached connections also need to be removed.
  public void node_deleted( Node node, Array<Connection> conns ) {
    for( int i=0; i<node.children().length; i++ ) {
      node_deleted( node.children().index( i ), conns );
    }
    for( int i=((int)_connections.length - 1); i>=0; i-- ) {
      if( _connections.index( i ).attached_to_node( node ) ) {
        conns.append_val( _connections.index( i ) );
        _connections.remove_index( i );
      }
    }
  }

  //-------------------------------------------------------------
  // Called whenever a single node is deleted.  All attached
  // connections also need to be removed.
  public void node_only_deleted( Node node, Array<Connection> conns ) {
    for( int i=((int)_connections.length - 1); i>=0; i-- ) {
      if( _connections.index( i ).attached_to_node( node ) ) {
        conns.append_val( _connections.index( i ) );
        _connections.remove_index( i );
      }
    }
  }

  //-------------------------------------------------------------
  // Loads the listed connections from the given XML data.
  public void load( MindMap map, Xml.Node* node, Array<Connection>? conns, Array<Node> nodes ) {
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "connection" ) {
          var conn = new Connection.from_xml( map, it, nodes );
          if( conns != null ) {
            conns.append_val( conn );
          }
          _connections.append_val( conn );
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Saves the connection information to the given XML file.
  public void save( Xml.Node* parent ) {
    if( _connections.length > 0 ) {
      Xml.Node* n = new Xml.Node( null, "connections" );
      for( int i=0; i<_connections.length; i++ ) {
        _connections.index( i ).save( n );
      }
      parent->add_child( n );
    }
  }

  //-------------------------------------------------------------
  // Saves the connection information to the given XML node if
  // the connection is fully within the given node tree.
  public void save_if_in_node( Xml.Node* parent, Node node, NodeLinks save_links, NodeLinks doc_links ) {
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ).from_node.is_descendant_of( node ) && _connections.index( i ).to_node.is_descendant_of( node ) ) {
        _connections.index( i ).save( parent );
        save_links.get_links_from_connection( _connections.index( i ), doc_links );
      }
    }
  }

  //-------------------------------------------------------------
  // Updates the connection notes of any that connect to the
  // given node.
  public void set_links_in_notes( Node node, NodeLinks links, NodeLinks doc_links ) {
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ).from_node.is_descendant_of( node ) && _connections.index( i ).to_node.is_descendant_of( node ) ) {
        links.set_links_in_connection( _connections.index( i ), doc_links );
      }
    }
  }

  //-------------------------------------------------------------
  // Set all of the stored connections to the given style.
  public void set_all_connections_to_style( Style style ) {
    for( int i=0; i<_connections.length; i++ ) {
      _connections.index( i ).style = style;
    }
  }

  //-------------------------------------------------------------
  // Searches the connections for ones that match the given
  // pattern and search options.
  public void get_match_items(string tabname, string pattern, bool[] search_opts, ref Gtk.ListStore matches ) {
    for( int i=0; i<_connections.length; i++ ) {
      _connections.index( i ).get_match_items(tabname, pattern, search_opts, ref matches );
    }
  }

  //-------------------------------------------------------------
  // Sets the focus mode to the given value and updates the alpha
  // value of the stored connections.
  public void update_alpha() {
    for( int i=0; i<_connections.length; i++ ) {
      double from_alpha = _connections.index( i ).from_node.alpha;
      double to_alpha   = _connections.index( i ).to_node.alpha;
      _connections.index( i ).alpha = (from_alpha < to_alpha) ? from_alpha : to_alpha;
    }
  }

  //-------------------------------------------------------------
  // Takes the given extents and extends them if the connections
  // go outside of the given extents.
  public void add_extents( ref double x1, ref double y1, ref double x2, ref double y2 ) {
    for( int i=0; i<_connections.length; i++ ) {
      var conn = _connections.index( i );
      x1 = (conn.extent_x1 < x1) ? conn.extent_x1 : x1;
      y1 = (conn.extent_y1 < y1) ? conn.extent_y1 : y1;
      x2 = (conn.extent_x2 > x2) ? conn.extent_x2 : x2;
      y2 = (conn.extent_y2 > y2) ? conn.extent_y2 : y2;
    }
  }

  //-------------------------------------------------------------
  // Draws all of the connections onto the given context.
  public void draw_all( Cairo.Context ctx, Theme theme, bool exporting ) {
    if( hide ) return;
    for( int i=0; i<_connections.length; i++ ) {
      _connections.index( i ).draw( ctx, theme, exporting );
    }
  }

}
