public class Connections {

  private Array<Connection> _connections;

  /* Default constructor */
  public Connections() {
    _connections = new Array<Connection>();
  }

  /* Adds the given connection */
  public void add_connection( Connection conn ) {
    _connections.append_val( conn );
  }

  /* Removes the given connection */
  public void remove_connection( Connection conn ) {
    for( uint i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ) == conn ) {
        _connections.remove_index( i ); 
      }
    }
  }

  /* Returns true if the given point is within the drag handle */
  public Connection? within_drag_handle( double x, double y ) {
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ).within_drag_handle( x, y ) ) {
        return( _connections.index( i ) );
      }
    }
    return( null );
  }

  /* Adjusts the connections based on the amount of panning that occurred */
  public void pan( double diff_x, double diff_y ) {
    for( int i=0; i<_connections.length; i++ ) {
      _connections.index( i ).pan( diff_x, diff_y );
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
  public void draw_all( Cairo.Context ctx, Theme theme, Connection? current ) {
    for( int i=0; i<_connections.length; i++ ) {
      if( _connections.index( i ) != current ) {
        _connections.index( i ).draw( ctx, theme );
      }
    }
  }

}
