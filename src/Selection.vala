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
  private Array<Sticker>    _stickers;
  private Array<NodeGroup>  _groups;
  private Array<Callout>    _callouts;

  public signal void selection_changed();

  /* Default constructor */
  public Selection( DrawArea da ) {
    _da       = da;
    _nodes    = new Array<Node>();
    _conns    = new Array<Connection>();
    _stickers = new Array<Sticker>();
    _groups   = new Array<NodeGroup>();
    _callouts = new Array<Callout>();
  }

  /* Returns true if the given node is currently selected */
  public bool is_node_selected( Node node ) {
    return( node.mode.is_selected() );
  }

  /* Returns true if the given connection is currently selected */
  public bool is_connection_selected( Connection conn ) {
    return( conn.mode == ConnMode.SELECTED );
  }

  /* Returns true if the given sticker is currently selected */
  public bool is_sticker_selected( Sticker sticker ) {
    return( sticker.mode == StickerMode.SELECTED );
  }

  /* Returns true if the given group is currently selected */
  public bool is_group_selected( NodeGroup group ) {
    return( group.mode == GroupMode.SELECTED );
  }

  public bool is_callout_selected( Callout callout ) {
    return( callout.mode.is_selected() );
  }

  /* Returns true if the given node is the only selected item */
  public bool is_current_node( Node node ) {
    return( (_nodes.length == 1) && (_nodes.index( 0 ) == node) );
  }

  /* Returns true if the given connection is the only selected item */
  public bool is_current_connection( Connection conn ) {
    return( (_conns.length == 1) && (_conns.index( 0 ) == conn) );
  }

  /* Returns true if the given sticker is the only selected item */
  public bool is_current_sticker( Sticker sticker ) {
    return( (_stickers.length == 1) && (_stickers.index( 0 ) == sticker) );
  }

  /* Returns true if the given group is the only selected item */
  public bool is_current_group( NodeGroup group ) {
    return( (_groups.length == 1) && (_groups.index( 0 ) == group ) );
  }

  /* Returns true if the given callout is the only selected item */
  public bool is_current_callout( Callout callout ) {
    return( (_callouts.length == 1) && (_callouts.index( 0 ) == callout) );
  }

  /* Returns the currently selected node */
  public Node? current_node() {
    return( (_nodes.length == 1) ? _nodes.index( 0 ) : null );
  }

  /* Returns the currently selected connection */
  public Connection? current_connection() {
    return( (_conns.length == 1) ? _conns.index( 0 ) : null );
  }

  /* Returns the currently selected sticker */
  public Sticker? current_sticker() {
    return( (_stickers.length == 1) ? _stickers.index( 0 ) : null );
  }

  /* Returns the currently selected group */
  public NodeGroup? current_group() {
    return( (_groups.length == 1) ? _groups.index( 0 ) : null );
  }

  /* Returns the currently selected callout */
  public Callout? current_callout() {
    return( (_callouts.length == 1) ? _callouts.index( 0 ) : null );
  }

  /* Sets the current node, clearing all other selected items */
  public void set_current_node( Node node, double clear_alpha = 1.0 ) {
    clear( false, clear_alpha );
    add_node( node );
  }

  /* Sets the current connection, clearing all other selected items */
  public void set_current_connection( Connection conn, double clear_alpha = 1.0 ) {
    clear( false, clear_alpha );
    add_connection( conn );
  }

  /* Sets the current sticker, clearing all other selected items */
  public void set_current_sticker( Sticker sticker, double clear_alpha = 1.0 ) {
    clear( false, clear_alpha );
    add_sticker( sticker );
  }

  /* Sets the current group, clearing all other selected items */
  public void set_current_group( NodeGroup group, double clear_alpha = 1.0 ) {
    clear( false, clear_alpha );
    add_group( group );
  }

  /* Sets the current callout, clearing all other selected items */
  public void set_current_callout( Callout callout, double clear_alpha = 1.0 ) {
    clear( false, clear_alpha );
    add_callout( callout );
  }

  /* Adds a node to the current selection.  Returns true if the node was added. */
  public bool add_node( Node node, bool signal_change = true ) {
    if( is_node_selected( node ) || ((node.parent != null) && node.parent.folded) ) return( false );
    _da.set_node_mode( node, ((_nodes.length == 0) ? NodeMode.CURRENT : NodeMode.SELECTED) );
    if( _nodes.length == 1 ) {
      _da.set_node_mode( _nodes.index( 0 ), NodeMode.SELECTED );
    }
    _nodes.append_val( node );
    if( signal_change ) {
      selection_changed();
    }
    return( true );
  }

  /* Adds the children nodes of the current node */
  public bool add_child_nodes( Node node, bool signal_change = true ) {
    var children = node.children();
    var changed  = false;
    for( int i=0; i<children.length; i++ ) {
      changed |= add_node( children.index( i ), false );
    }
    if( changed && signal_change ) {
      selection_changed();
    }
    return( changed );
  }

  /* Adds the entire node tree to the selection */
  public bool add_node_tree( Node node, bool signal_change = true ) {
    if( add_node_tree_helper( node ) ) {
      if( signal_change ) {
        selection_changed();
      }
      return( true );
    }
    return( false );
  }

  /* Helper method to add the entire node tree to the selection */
  private bool add_node_tree_helper( Node node ) {
    var children = node.children();
    var changed  = add_node( node, false );
    for( int i=0; i<children.length; i++ ) {
      changed |= add_node_tree_helper( children.index( i ) );
    }
    return( changed );
  }

  /* Adds all of the nodes at the specified node's level to the selection */
  public bool add_nodes_at_level( Node node, bool signal_change = true ) {
    var level = node.get_level();
    var root  = node.get_root();
    if( add_nodes_at_level_helper( root, level, 0 ) && signal_change ) {
      if( signal_change ) {
        selection_changed();
      }
      return( true );
    }
    return( false );
  }

  private bool add_nodes_at_level_helper( Node node, uint level, uint curr_level ) {
    if( level == curr_level ) {
      return( add_node( node, false ) );
    } else {
      var children = node.children();
      var changed  = false;
      for( int i=0; i<children.length; i++ ) {
        changed |= add_nodes_at_level_helper( children.index( i ), level, (curr_level + 1) );
      }
      return( changed );
    }
  }

  /* Adds a connection to the current selection */
  public bool add_connection( Connection conn ) {
    if( is_connection_selected( conn ) ) return( false );
    _da.set_connection_mode( conn, ConnMode.SELECTED );
    _conns.append_val( conn );
    selection_changed();
    return( true );
  }

  /* Adds a sticker to the current selection */
  public bool add_sticker( Sticker sticker ) {
    if( is_sticker_selected( sticker ) ) return( false );
    sticker.mode = StickerMode.SELECTED;
    _stickers.append_val( sticker );
    selection_changed();
    return( true );
  }

  /* Adds a sticker to the current selection */
  public bool add_group( NodeGroup group ) {
    if( is_group_selected( group ) ) return( false );
    group.mode = GroupMode.SELECTED;
    _groups.append_val( group );
    selection_changed();
    return( true );
  }

  /* Adds a callout to the current selection */
  public bool add_callout( Callout callout ) {
    if( is_callout_selected( callout ) ) return( false );
    callout.mode = CalloutMode.SELECTED;
    _callouts.append_val( callout );
    selection_changed();
    return( true );
  }

  /*
   Removes the given node from the current selection.  Returns true if the
   node is removed.
  */
  public bool remove_node( Node node, double alpha = 1.0, bool signal_change = true ) {
    if( is_node_selected( node ) ) {
      _da.set_node_mode( node, NodeMode.NONE );
      node.alpha = alpha;
      for( int i=0; i<_nodes.length; i++ ) {
        if( node == _nodes.index( i ) ) {
          _nodes.remove_index( i );
          if( _nodes.length == 1 ) {
            _da.set_node_mode( _nodes.index( 0 ), NodeMode.CURRENT );
          }
          if( signal_change ) {
            selection_changed();
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
      retval |= remove_node( children.index( i ), alpha, false );
    }
    if( retval ) {
      selection_changed();
    }
    return( retval );
  }

  /* Removes an entire node tree from the selection */
  public bool remove_node_tree( Node node, double alpha = 1.0 ) {
    if( remove_node_tree_helper( node, alpha ) ) {
      selection_changed();
      return( true );
    }
    return( false );
  }

  /* Removes an entire node tree from the selection */
  public bool remove_node_tree_helper( Node node, double alpha = 1.0 ) {
    var children = node.children();
    var retval   = remove_node( node, alpha, false );
    for( int i=0; i<children.length; i++ ) {
      retval |= remove_node_tree_helper( children.index( i ), alpha );
    }
    return( retval );
  }

  /* Adds all of the nodes at the specified node's level to the selection */
  public bool remove_nodes_at_level( Node node, double alpha = 1.0 ) {
    var level = node.get_level();
    var root  = node.get_root();
    if( remove_nodes_at_level_helper( root, alpha, level, 0 ) ) {
      selection_changed();
      return( true );
    }
    return( false );
  }

  /* Helper function for remove_nodes_at_level */
  private bool remove_nodes_at_level_helper( Node node, double alpha, uint level, uint curr_level ) {
    if( level == curr_level ) {
      return( remove_node( node, alpha, false ) );
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
      _da.set_connection_mode( conn, ConnMode.NONE );
      conn.alpha = alpha;
      for( int i=0; i<_conns.length; i++ ) {
        if( conn == _conns.index( i ) ) {
          _conns.remove_index( i );
          selection_changed();
          return( true );
        }
      }
    }
    return( false );
  }

  /*
   Removes the given sticker from the current selection.  Returns true
   if the sticker is removed.
  */
  public bool remove_sticker( Sticker sticker, double alpha = 1.0 ) {
    if( is_sticker_selected( sticker ) ) {
      sticker.mode = StickerMode.NONE;
      for( int i=0; i<_stickers.length; i++ ) {
        if( sticker == _stickers.index( i ) ) {
          _stickers.remove_index( i );
          selection_changed();
          return( true );
        }
      }
    }
    return( false );
  }

  /*
   Removes the given group from the current selection.  Returns true
   if the group is removed.
  */
  public bool remove_group( NodeGroup group, double alpha = 1.0 ) {
    if( is_group_selected( group ) ) {
      group.mode = GroupMode.NONE;
      for( int i=0; i<_groups.length; i++ ) {
        if( group == _groups.index( i ) ) {
          _groups.remove_index( i );
          selection_changed();
          return( true );
        }
      }
    }
    return( false );
  }

  /*
   Removes the given callout from the current selection.  Returns true
   if the callout is removed.
  */
  public bool remove_callout( Callout callout, double alpha = 1.0 ) {
    if( is_callout_selected( callout ) ) {
      callout.mode = CalloutMode.NONE;
      for( int i=0; i<_callouts.length; i++ ) {
        if( callout == _callouts.index( i ) ) {
          _callouts.remove_index( i );
          selection_changed();
          return( true );
        }
      }
    }
    return( false );
  }

  /* Clears all of the selected nodes */
  public bool clear_nodes( bool signal_change = true, double alpha = 1.0 ) {
    var num = _nodes.length;
    for( int i=0; i<num; i++ ) {
      _da.set_node_mode( _nodes.index( i ), NodeMode.NONE );
      _nodes.index( i ).alpha = alpha;
    }
    _nodes.remove_range( 0, num );
    if( (num > 0) && signal_change ) {
      selection_changed();
    }
    return( num > 0 );
  }

  /* Clears all of the selected connections */
  public bool clear_connections( bool signal_change = true, double alpha = 1.0 ) {
    var num = _conns.length;
    for( int i=0; i<num; i++ ) {
      _da.set_connection_mode( _conns.index( i ), ConnMode.NONE );
      _conns.index( i ).alpha = alpha;
    }
    _conns.remove_range( 0, num );
    if( (num > 0) && signal_change ) {
      selection_changed();
    }
    return( num > 0 );
  }

  /* Clears all of the selected stickers */
  public bool clear_stickers( bool signal_change = true ) {
    var num = _stickers.length;
    for( int i=0; i<num; i++ ) {
      _stickers.index( i ).mode = StickerMode.NONE;
    }
    _stickers.remove_range( 0, num );
    if( (num > 0) && signal_change ) {
      selection_changed();
    }
    return( num > 0 );
  }

  /* Clears all of the selected groups */
  public bool clear_groups( bool signal_change = true ) {
    var num = _groups.length;
    for( int i=0; i<num; i++ ) {
      _groups.index( i ).mode = GroupMode.NONE;
    }
    _groups.remove_range( 0, num );
    if( (num > 0) && signal_change ) {
      selection_changed();
    }
    return( num > 0 );
  }

  /* Clears all of the selected callouts */
  public bool clear_callouts( bool signal_change = true, double alpha = 1.0 ) {
    var num = _callouts.length;
    for( int i=0; i<num; i++ ) {
      _da.set_callout_mode( _callouts.index( i ), CalloutMode.NONE );
      _callouts.index( i ).alpha = alpha;
    }
    _callouts.remove_range( 0, num );
    if( (num > 0) && signal_change ) {
      selection_changed();
    }
    return( num > 0 );
  }

  /* Clears the current selection */
  public bool clear( bool signal_change = true, double alpha = 1.0 ) {
    var changed = false;
    changed |= clear_nodes( false, alpha );
    changed |= clear_connections( false, alpha );
    changed |= clear_stickers( false );
    changed |= clear_groups( false );
    changed |= clear_callouts( false, alpha );
    if( changed && signal_change ) {
      selection_changed();
    }
    return( changed );
  }

  /* Returns the number of nodes selected */
  public int num_nodes() {
    return( (int)_nodes.length );
  }

  /* Returns the number of connections selected */
  public int num_connections() {
    return( (int)_conns.length );
  }

  /* Returns the number of stickers selected */
  public int num_stickers() {
    return( (int)_stickers.length );
  }

  /* Returns the number of groups selected */
  public int num_groups() {
    return( (int)_groups.length );
  }

  /* Returns the number of callouts selected */
  public int num_callouts() {
    return( (int)_callouts.length );
  }

  /* Returns an array of currently selected nodes */
  public Array<Node> nodes() {
    return( _nodes );
  }

  /* Returns a copy of the given nodes array */
  public Array<Node> nodes_copy() {
    var nodes = new Array<Node>();
    for( int i=0; i<_nodes.length; i++ ) {
      nodes.append_val( _nodes.index( i ) );
    }
    return( nodes );
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
      if( node.traversable() ) {
        ordered_nodes_helper( node.children(), ref nodes );
      }
      if( is_node_selected( node ) ) {
        nodes.append_val( node );
      }
    }
  }

  /* Returns an array of currently selected connections */
  public Array<Connection> connections() {
    return( _conns );
  }

  /* Returns an array of currently selected stickers */
  public Array<Sticker> stickers() {
    return( _stickers );
  }

  /* Returns an array of currently selected groups */
  public Array<NodeGroup> groups() {
    return( _groups );
  }

  /* Returns an array of currently selected callouts */
  public Array<Callout> callouts() {
    return( _callouts );
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
