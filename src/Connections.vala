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

  /* Draws all of the connections onto the given context */
  public void draw_all( Cairo.Context ctx, Theme theme ) {
    for( int i=0; i<_connections.length; i++ ) {
      _connections.index( i ).draw( ctx, theme );
    }
  }

}
