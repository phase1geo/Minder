using Gee;

public class NodeLinks {

  private HashMap<int,NodeLink> _links;
  private int                   _id = 0;
  private Regex?                _link_re;

  /* Constructor */
  public NodeLinks() {
    _links = new HashMap<int,NodeLink>();
    try {
      _link_re = new Regex( "@Node-(\\d+)" );
    } catch( RegexError e ) {
      _link_re = null;
    }
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

  /* Returns the number of links stored */
  public int num_links() {
    return( _links.size );
  }

  /*
   Populates the internal node links from the given node's note.  The doc_links
   parameter should come from the NodeLinks structure stored in the DrawArea.
  */
  private void get_links_from_note( string note, NodeLinks doc_links ) {
    if( _link_re == null ) return;
    MatchInfo match_info;
    var       start = 0;
    try {
      while( _link_re.match_full( note, -1, start, 0, out match_info ) ) {
        int s, e;
        match_info.fetch_pos( 1, out s, out e );
        var id   = int.parse( note.slice( s, e ) );
        var link = doc_links.get_node_link( id );
        if( link != null ) {
          _links.set( id, link );
        }
        start = e;
      }
    } catch( RegexError e ) {}
  }

  /* Gets the links from the given node's note */
  public void get_links_from_node( Node node, NodeLinks doc_links ) {
    get_links_from_note( node.note, doc_links );
  }

  /* Gets the links from the given connections's note */
  public void get_links_from_connection( Connection conn, NodeLinks doc_links ) {
    get_links_from_note( conn.note, doc_links );
  }

  /*
   Finds the node links in the given node and stores the node links in the document links,
   gets the new index and updates the IDs with the new IDs.
  */
  public string? set_links_in_note( string orig_note, NodeLinks doc_links ) {
    var note = orig_note;
    if( _link_re == null ) return( null );
    MatchInfo match_info;
    var       start = 0;
    try {
      while( _link_re.match_full( note, -1, start, 0, out match_info ) ) {
        int s, e;
        match_info.fetch_pos( 1, out s, out e );
        var id   = int.parse( note.slice( s, e ) );
        var link = get_node_link( id );
        if( link != null ) {
          id = doc_links.add_link( link );
          note = note.splice( s, e, id.to_string() );
        }
        start = e;
      }
      return( note );
    } catch( RegexError e ) {
      return( null );
    }
  }

  /* Extracts and updates the note text for a node with its node link information */
  public void set_links_in_node( Node node, NodeLinks doc_links ) {
    var note = set_links_in_note( node.note, doc_links );
    if( note != null ) {
      node.note = note;
    }
  }

  /* Extracts and updates the note text for a connection with its node link information */
  public void set_links_in_connection( Connection conn, NodeLinks doc_links ) {
    var note = set_links_in_note( conn.note, doc_links );
    if( note != null ) {
      conn.note = note;
    }
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
