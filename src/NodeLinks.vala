using Gee;

public class NodeLinks {

  private HashMap<int,NodeLink> _links;
  private int                   _id = 0;

  /* Constructor */
  public NodeLinks() {
    _links = new HashMap<int,NodeLink>();
  }

  /* Adds the given node link to our node list */
  public int add_link( NodeLink link ) {

    var id = -1;

    _links.map_iterator().foreach((k, v) => {
      if( v.matches( link ) ) {
        id = k;
        return( false );
      }
      return( true );
    });

    if( id == -1 ) {
      id = _id++;
      _links.set( id, link );
    }

    return( id );

  }

  /* Returns the node link for the given ID */
  public NodeLink? get_node_link( int id ) {
    if( _links.has_key( id ) ) {
      return( _links.get( id ) );
    }
    return( null );
  }

  /* Saves the node link information to the document */
  public Xml.Node* save() {

    Xml.Node* node = new Xml.Node( null, "nodelinks" );

    node->set_prop( "id", _id.to_string() );

    _links.map_iterator().foreach((k, v) => {
      Xml.Node* link = v.save();
      link->set_prop( "doc-id", k.to_string() );
      node->add_child( link );
      return( true );
    });

    return( node );

  }

  /* Loads the node link information from the document */
  public void load( Xml.Node* node ) {

    var i = node->get_prop( "id" );
    if( i != null ) {
      _id = int.parse( i );
    }

    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "nodelink") ) {
        var link = new NodeLink.from_xml( it );
        var id   = it->get_prop( "doc-id" );
        if( id != null ) {
          _links.set( int.parse( id ), link );
        }
      }
    }

  }

}
