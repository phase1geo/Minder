 /*
* Copyright (c) 2018-2021 (https://github.com/phase1geo/Minder)
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

public class NodeLink {

  private string _fname;       // Name of file containing node to link to
  private bool   _temp_file;   // Set to true if _fname has not been saved by the user
  private string _node_title;  // Last known title node of node to link to
  private int    _node_id;     // Node ID of node to link to

  public int node_id {
    get {
      return( _node_id );
    }
  }

  /* Constructor */
  public NodeLink( Node node ) {
    _fname      = node.da.get_doc().filename;
    _temp_file  = !node.da.get_doc().is_saved();
    _node_title = node.name.text.text;
    _node_id    = node.id();
  }

  /* Constructor */
  public NodeLink.for_local( int id ) {
    _fname      = "";
    _temp_file  = false;
    _node_title = "";
    _node_id    = id;
  }

  /* Constructor from XML node */
  public NodeLink.from_xml( Xml.Node* node ) {
    _temp_file = false;
    load( node );
  }

  /* Returns true if the linked node exists in the same mindmap as the node that links to it */
  public bool is_local() {
    return( _fname == "" );
  }

  /* Returns true if this node_link can be linked to the given document */
  public bool is_linkable( string fname, int node_id ) {
    return( (fname == _fname) ? (_node_id != node_id) : !_temp_file );
  }

  /* Returns true if the specified node link matches ourselves */
  public bool matches( NodeLink other ) {
    return( (_fname == other._fname) && (_node_id == other._node_id) );
  }

  /* This should be called whenever a NodeLink is assigned to a node */
  public void normalize( DrawArea da ) {
    if( _fname == da.get_doc().filename ) {
      _fname      = "";
      _temp_file  = false;
      _node_title = "";
    }
  }

  /*
   Displays the linked node.  If the node is in a different file,
   opens the mindmap and selects the given node.
  */
  public void select( DrawArea da ) {
    if( (_fname == "") || da.win.open_file( _fname, false ) ) {
      var other_da = da.win.get_current_da();
      var node     = other_da.get_node( other_da.get_nodes(), _node_id );
      Idle.add(() => {
        if( other_da.select_node( node, false ) ) {
          other_da.queue_draw();
        } else {
          // Node was not found
        }
        return( false );
      });
    }
  }

  /* Returns the node link string to display in a tooltip */
  public string get_tooltip( DrawArea da ) {
    if( _fname == "" ) {
      var linked_node = da.get_node( da.get_nodes(), _node_id );
      if( linked_node != null ) {
        return( linked_node.name.text.text );
      } else {
        return( _( "No node found" ) );
      }
    } else {
      string title = _( "No node found" );
      Document.xml_find( _fname, _node_id, ref title );
      return( "%s\n\nFilename: %s".printf( title, _fname ) );
    }
  }

  /* Returns the text to display in a Markdown link */
  public string get_markdown_text( DrawArea da ) {
    if( _fname == "" ) {
      var linked_node = da.get_node( da.get_nodes(), _node_id );
      return( linked_node.name.text.text );
    } else {
      string title = "";
      Document.xml_find( _fname, _node_id, ref title );
      return( "%s: %s".printf( Path.get_basename( _fname ), title ) );
    }
  }

  /* Saves this node link to the XML file */
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "nodelink" );
    node->new_prop( "id",    _node_id.to_string() );
    node->new_prop( "fname", _fname );
    node->new_prop( "title", _node_title );
    return( node );
  }

  /* Loads the given NodeLink data from the given XML node */
  public void load( Xml.Node* node ) {

    var id = node->get_prop( "id" );
    if( id != null ) {
      _node_id = int.parse( id );
    }

    _fname      = node->get_prop( "fname" );
    _node_title = node->get_prop( "title" );

  }

}

