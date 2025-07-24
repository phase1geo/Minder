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

using Cairo;
using Gdk;
using Gee;

public struct UndoNodeGroups {
  Node              node;
  Array<NodeGroup?> groups;
  public UndoNodeGroups( Node n, Array<NodeGroup?> g ) {
    node   = n;
    groups = g;
  }
}

public class NodeGroups {

  private Array<NodeGroup> _groups;

  /* Default constructor */
  public NodeGroups() {
    _groups = new Array<NodeGroup>();
  }

  /* Removes all stored groups from memory */
  public void clear() {
    _groups.remove_range( 0, _groups.length );
  }

  /* Creates a new group for the array of nodes */
  public void add_group( NodeGroup group ) {
    _groups.append_val( group );
  }

  /* Removes the given group from this list */
  public void remove_group( NodeGroup group ) {
    for( int i=0; i<_groups.length; i++ ) {
      if( _groups.index( i ) == group ) {
        _groups.remove_index( i );
        return;
      }
    }
  }

  /* Checks to see if this group contains the given node and removes it if found */
  public void remove_node( Node node, ref UndoNodeGroups? affected ) {
    var groups = new Array<NodeGroup>();
    for( int i=(int)(_groups.length - 1); i>=0; i-- ) {
      if( _groups.index( i ).remove_node( node ) ) {
        groups.append_val( _groups.index( i ) );
        if( _groups.index( i ).nodes.length == 0 ) {
          _groups.remove_index( i );
        }
      }
    }
    if( groups.length > 0 ) {
      affected = new UndoNodeGroups( node, groups );
    }
  }

  /* Removes the given nodes from this group, if found */
  public void remove_nodes( Array<Node> nodes, out Array<UndoNodeGroups?> affected ) {
    affected = new Array<UndoNodeGroups?>();
    for( int i=0; i<nodes.length; i++ ) {
      UndoNodeGroups? a = null;
      remove_node( nodes.index( i ), ref a );
      if( a != null ) {
        affected.append_val( a );
      }
    }
  }

  /* Merges the specifies groups into a single group */
  public NodeGroup? merge_groups( Array<NodeGroup> groups ) {
    if( groups.length == 0 ) return( null );
    var group = new NodeGroup.copy( groups.index( 0 ) );
    remove_group( groups.index( 0 ) );
    for( int i=1; i<groups.length; i++ ) {
      group.merge( groups.index( i ) );
      remove_group( groups.index( i ) );
    }
    add_group( group );
    return( group );
  }

  /* Returns true if the specified node group exists in this list */
  private bool group_exists( NodeGroup group ) {
    for( int i=0; i<_groups.length; i++ ) {
      if( _groups.index( i ) == group ) {
        return( true );
      }
    }
    return( false );
  }

  /* Applies the given undo */
  public void apply_undo( UndoNodeGroups? g ) {
    if( g != null ) {
      for( int i=0; i<g.groups.length; i++ ) {
        g.groups.index( i ).add_node( g.node );
        if( !group_exists( g.groups.index( i ) ) ) {
          _groups.append_val( g.groups.index( i ) );
        }
      }
    }
  }

  /* Applies the given list of undos */
  public void apply_undos( Array<UndoNodeGroups?> g ) {
    for( int i=0; i<g.length; i++ ) {
      apply_undo( g.index( i ) );
    }
  }

  /* Returns the node group that contains the given cursor */
  public NodeGroup? node_group_containing( double x, double y ) {
    for( int i=(int)(_groups.length - 1); i>=0; i-- ) {
      if( _groups.index( i ).is_within( x, y ) ) {
        return( _groups.index( i ) );
      }
    }
    return( null );
  }

  /* Searches the groups for ones that match the given pattern and search options */
  public void get_match_items(string tabname, string pattern, bool[] search_opts, ref Gtk.ListStore matches ) {
    for( int i=0; i<_groups.length; i++ ) {
      _groups.index( i ).get_match_items( tabname, pattern, search_opts, ref matches );
    }
  }

  /* Saves the current group in Minder XML format */
  public Xml.Node* save() {
    Xml.Node* g = new Xml.Node( null, "groups" );
    for( int i=0; i<_groups.length; i++ ) {
      g->add_child( _groups.index( i ).save() );
    }
    return( g );
  }

  //-------------------------------------------------------------
  // Adds the node groups that are descendants of the given node
  // to the specified XML parent node.
  public void save_if_in_node( Xml.Node* parent, Node node ) {
    for( int i=0; i<_groups.length; i++ ) {
      if( _groups.index( i ).within_node( node ) ) {
        parent->add_child( _groups.index( i ).save() );
      }
    }
  }

  //-------------------------------------------------------------
  // Loads the given group information.
  public void load( MindMap map, Xml.Node* g, Array<NodeGroup>? groups, Array<Node> nodes ) {
    for( Xml.Node* it = g->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "group") ) {
        var group = new NodeGroup.from_xml( map, it, nodes );
        if( groups != null ) {
          groups.append_val( group );
        }
        _groups.append_val( group );
      }
    }
  }

  //-------------------------------------------------------------
  // Draws a group around the stored set of nodes from this structure.
  public void draw_all( Context ctx, Theme theme, bool exporting ) {
    for( int i=0; i<_groups.length; i++ ) {
      _groups.index( i ).draw( ctx, theme, exporting );
    }
  }

}
