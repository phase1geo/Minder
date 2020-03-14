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

  private DrawArea          _da;
  private Array<Node>       _nodes;
  private Array<Connection> _conns;

  /* Default constructor */
  public Selection( DrawArea da ) {
    _da    = da;
    _nodes = new Array<Node>();
    _conns = new Array<Connection>();
  }

  /* Returns true if the given node is currently selected */
  public bool is_node_selected( Node node ) {
    return( (node.mode == NodeMode.CURRENT) || (node.mode == NodeMode.SELECTED) );
  }

  /* Returns true if the given connection is currently selected */
  public bool is_connection_selected( Connection conn ) {
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
    node.mode = (_nodes.length == 0) ? NodeMode.CURRENT : NodeMode.SELECTED;
    if( _nodes.length == 1 ) {
      _nodes.index( 0 ).mode = NodeMode.SELECTED;
    }
    _nodes.append_val( node );
    return( true );
  }

  /* Adds the children nodes of the current node */
  public void add_child_nodes( Node node ) {
    var children = node.children();
    for( int i=0; i<children.length; i++ ) {
      add_node( children.index( i ) );
    }
  }

  /* Adds the entire node tree to the selection */
  public void add_node_tree( Node node ) {
    var children = node.children();
    add_node( node );
    for( int i=0; i<children.length; i++ ) {
      add_node_tree( children.index( i ) );
    }
  }

  /* Adds all of the nodes at the specified node's level to the selection */
  public void add_nodes_at_level( Node node ) {
    var level = node.get_level();
    var root  = node.get_root();
    add_nodes_at_level_helper( root, level, 0 );
  }

  private void add_nodes_at_level_helper( Node node, uint level, uint curr_level ) {
    if( level == curr_level ) {
      add_node( node );
    } else {
      var children = node.children();
      for( int i=0; i<children.length; i++ ) {
        add_nodes_at_level_helper( children.index( i ), level, (curr_level + 1) );
      }
    }
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
          if( _nodes.length == 1 ) {
            _nodes.index( 0 ).mode = NodeMode.CURRENT;
          }
          return( true );
        }
      }
    }
    return( false );
  }

  /* Removes child nodes of the given parent from the selection */
  public bool remove_child_nodes( Node node, double alpha = 1.0 ) {
    var children = node.children();
    var retval   = false;
    for( int i=0; i<children.length; i++ ) {
      retval |= remove_node( children.index( i ), alpha );
    }
    return( retval );
  }

  /* Removes an entire node tree from the selection */
  public bool remove_node_tree( Node node, double alpha = 1.0 ) {
    var children = node.children();
    var retval   = remove_node( node, alpha );
    for( int i=0; i<children.length; i++ ) {
      retval |= remove_node_tree( children.index( i ), alpha );
    }
    return( retval );
  }

  /* Adds all of the nodes at the specified node's level to the selection */
  public bool remove_nodes_at_level( Node node, double alpha = 1.0 ) {
    var level = node.get_level();
    var root  = node.get_root();
    return( remove_nodes_at_level_helper( root, alpha, level, 0 ) );
  }

  /* Helper function for remove_nodes_at_level */
  private bool remove_nodes_at_level_helper( Node node, double alpha, uint level, uint curr_level ) {
    if( level == curr_level ) {
      return( remove_node( node, alpha ) );
    } else {
      var children = node.children();
      var retval   = false;
      for( int i=0; i<children.length; i++ ) {
        retval |= remove_nodes_at_level_helper( children.index( i ), alpha, level, (curr_level + 1) );
      }
      return( retval );
    }
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
    return( (int)_nodes.length );
  }

  /* Returns the number of connections selected */
  public int num_connections() {
    return( (int)_conns.length );
  }

  /* Returns an array of currently selected nodes */
  public Array<Node> nodes() {
    return( _nodes );
  }

  /* Returns an array of currently selected nodes in index order */
  public Array<Node> ordered_nodes() {
    var nodes = new Array<Node>();
    ordered_nodes_helper( _da.get_nodes(), ref nodes );
    return( nodes );
  }

  /* Helper method for the ordered_nodes method */
  private void ordered_nodes_helper( Array<Node> children, ref Array<Node> nodes ) {
    for( int i=0; i<children.length; i++ ) {
      var node = children.index( i );
      ordered_nodes_helper( node.children(), ref nodes );
      if( is_node_selected( node ) ) {
        nodes.append_val( node );
      }
    }
  }

  /* Returns an array of currently selected connections */
  public Array<Connection> connections() {
    return( _conns );
  }

  /*
   Returns all of the selected nodes that do not have ancestors that are also selected.  The
   parent array must be allocated prior to calling this function.
  */
  public void get_parents( ref Array<Node> parents ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      if( node.is_root() ) {
        parents.append_val( node );
      } else {
        var parent = node.parent;
        while( (parent != null) && !is_node_selected( parent ) ) {
          parent = parent.parent;
        }
        if( parent == null ) {
          parents.append_val( node );
        }
      }
    }
  }

  /*
   Iterates through the selections, create a list of subtrees containing only selected
   nodes but maintaining their hierarchy.
  */
  public void get_subtrees( ref Array<Node> subtrees, ImageManager im ) {

    /* Get the list of all parent nodes */
    var parents = new Array<Node>();
    get_parents( ref parents );

    for( int i=0; i<parents.length; i++ ) {
      var old_parent = parents.index( i );
      var node       = new Node( _da, old_parent.layout );
      node.copy_variables( old_parent, im );
      subtrees.append_val( node );
      get_subtrees_helper( old_parent, node, im );
    }

  }

  /*
   Helper function for the get_subtrees method.
  */
  private void get_subtrees_helper( Node old_parent, Node new_parent, ImageManager im ) {

    for( int i=0; i<old_parent.children().length; i++ ) {
      var old_child = old_parent.children().index( i );
      if( is_node_selected( old_child ) ) {
        var node = new Node( _da, old_child.layout );
        node.copy_variables( old_child, im );
        node.attach( new_parent, -1, null );
        get_subtrees_helper( old_child, node, im );
      } else {
        get_subtrees_helper( old_child, new_parent, im );
      }
    }

  }

}
