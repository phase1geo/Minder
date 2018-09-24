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

public class Styles {

  private Array<LinkType>   _link_types;
  private Array<NodeBorder> _node_borders;

  /* Default constructor */
  public Styles() {

    /* Create the link types */
    var lt_straight = new LinkTypeStraight();
    var lt_squared  = new LinkTypeSquared();
    var lt_curved   = new LinkTypeCurved();

    /* Add the link types to the list */
    _link_types = new Array<LinkType>();
    _link_types.append_val( lt_straight );
    _link_types.append_val( lt_squared );
    _link_types.append_val( lt_curved );

    /* Create the node borders */
    var nb_underlined = new NodeBorderUnderlined();
    var nb_squared    = new NodeBorderSquared();
    var nb_rounded    = new NodeBorderRounded();
    var nb_pilled     = new NodeBorderPill();

    _node_borders = new Array<NodeBorder>();
    _node_borders.append_val( nb_underlined );
    _node_borders.append_val( nb_squared );
    _node_borders.append_val( nb_rounded );
    _node_borders.append_val( nb_pilled );

  }

  /* Sets all nodes in the mind-map to the given link style */
  public void set_all_to_link( Array<Node> nodes, Style link ) {
    for( int i=0; i<nodes.length; i++ ) {
      set_node_to_style( nodes.index( i ), style );
      set_all_to_style( nodes.index( i ).children(), style );
    }
  }

  /* Sets all nodes at the specified levels to the given link style */
  public void set_levels_to_style( Array<Node> nodes, int levels, Style style, int level=0 ) {
    for( int i=0; i<nodes.length; i++ ) {
      if( (levels & (1 << level)) != 0 ) {
        set_node_to_style( nodes.index( i ), style );
      }
      set_levels_to_style( nodes.index( i ).children(), levels, style, (level + 1) );
    }
  }

  /* Sets the given node's link style to the given style */
  public void set_node_to_style( Node node, Style style ) {
    node.style = style;
  }

  /* Returns the list of available link types */
  public Array<LinkTypes> get_link_types() {
    return( _link_types );
  }

}
