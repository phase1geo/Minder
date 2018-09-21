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

public class Links {

  private Array<Link> _links;

  /* Default constructor */
  public Links() {
    _links.append_val( new LinkStraight() );
    _links.append_val( new LinkSquared() );
    _links.append_val( new LinkCurved() );
  }

  public set_all_to_link( Array<Node> nodes, Link link ) {
    for( int i=0; i<nodes.length; i++ ) {
      set_node_to_link( nodes.index( i ), link );
      set_all_to_link( ndoes.index( i ).children(), link );
    }
  }

  /* Sets all nodes in the document to the given link style */
  public set_levels_to_link( Array<Node> nodes, int levels, Link link, int level=0 ) {
    for( int i=0; i<nodes.length; i++ ) {
      if( (levels & (1 << level)) != 0 ) {
        set_node_to_link( nodes.index( i ), link );
      }
      set_levels_to_link( nodes.index( i ).children(), levels, link, (level + 1) );
    }
  }

  /* Sets the give node's link style to the given style */
  public set_node_to_link( Node node, Link link ) {
    node.link = link;
  }

}
