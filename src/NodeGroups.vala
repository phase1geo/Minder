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

public struct UndoNodeGroups {
  Node              node;
  Array<NodeGroup?> groups;
  public UndoNodeGroups( Node n, Array<NodeGroup?> g ) {
    node   = n;
    groups = g;
  }
}

public class NodeGroups {

  private DrawArea         _da;
  private Array<NodeGroup> _groups;

  /* Default constructor */
  public NodeGroups( DrawArea da ) {
    _da     = da;
    _groups = new Array<NodeGroup>();
  }

  /* Creates a new group for the array of nodes */
  public void add_group( Array<Node> nodes ) {
    _groups.append_val( new NodeGroup( _da, nodes ) );
  }

  /* Checks to see if this group contains the given node and removes it if found */
  public void remove_node( Node node, ref UndoNodeGroups? affected ) {
    var groups = new Array<NodeGroup>();
    for( int i=0; i<_groups.length; i++ ) {
      if( _groups.index( i ).remove_node( node ) ) {
        groups.append_val( _groups.index( i ) );
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

  /* Applies the given undo */
  public void apply_undo( UndoNodeGroups? g ) {
    if( g != null ) {
      for( int i=0; i<g.groups.length; i++ ) {
        g.groups.index( i ).add_node( g.node );
      }
    }
  }

  /* Applies the given list of undos */
  public void apply_undos( Array<UndoNodeGroups?> g ) {
    for( int i=0; i<g.length; i++ ) {
      apply_undo( g.index( i ) );
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

  /* Loads the given group information */
  public void load( DrawArea da, Xml.Node* g ) {
    for( Xml.Node* it = g->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "group") ) {
        _groups.append_val( new NodeGroup.from_xml( da, it ) );
      }
    }
  }

  /* Draws a group around the stored set of nodes from this structure */
  public void draw_all( Context ctx ) {
    for( int i=0; i<_groups.length; i++ ) {
      _groups.index( i ).draw( ctx );
    }
  }

}
