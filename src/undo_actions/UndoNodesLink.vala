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

using Gtk;

public class UndoNodesLink : UndoItem {

  public class NodeLinks {
    private Node            _node;
    private Array<NodeLink> _links;
    public Node node {
      get {
        return( _node );
      }
    }
    public NodeLinks( Node node ) {
      _node  = node;
      _links = new Array<NodeLink>();
      for( int i=0; i<node.num_node_links(); i++ ) {
        _links.append_val( node.get_node_link( i ) );
      }
    }
    public void set_links() {
      for( int i=0; i<node.num_node_links(); i++ ) {
        node.remove_node_link( i );
      }
      for( int i=0; i<_links.length; i++ ) {
        node.add_node_link( _links.index( i ) );
      }
    }
  }

  Array<NodeLinks> _node_links;

  /* Constructor for a node link change */
  public UndoNodesLink( Array<Node> nodes ) {
    base( _( "node link changes" ) );
    _node_links = new Array<NodeLinks>();
    for( int i=0; i<nodes.length; i++ ) {
      _node_links.append_val( new NodeLinks( nodes.index( i ) ) );
    }
  }

  private void toggle( DrawArea da ) {
    for( int i=0; i<_node_links.length; i++ ) {
      var node_links = _node_links.index( i );
      var tmp        = new NodeLinks( node_links.node );
      node_links.set_links();
      _node_links.data[i] = tmp;
    }
    da.queue_draw();
    da.auto_save();
  }

  /* Undoes a node image change */
  public override void undo( DrawArea da ) {
    toggle( da );
  }

  /* Redoes a node image change */
  public override void redo( DrawArea da ) {
    toggle( da );
  }

}
