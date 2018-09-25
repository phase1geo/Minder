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

  private static Array<LinkType>   _link_types;
  private static Array<NodeBorder> _node_borders;
  private        Array<Style>      _styles;

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

    /* Allocate styles for each level */
    _styles = new Array<Style>();
    for( int i=0; i<=10; i++ ) {
      var style = new Style();
      style.link_type  = lt_straight;
      style.link_width = 4;
      if( i == 0 ) {
        style.node_border = nb_rounded;
      } else {
        style.node_border = nb_underlined;
      }
      style.node_width       = 200;
      style.node_borderwidth = 4;
      _styles.append_val( style );
    }

  }

  /* Sets all nodes in the mind-map to the given link style */
  public void set_all_to_style( Array<Node> nodes, Style style ) {
    _styles.index( 10 ).copy( style );
    set_all_to_style_helper( nodes, style );
  }

  /* Updates the nodes */
  private void set_all_to_style_helper( Array<Node> nodes, Style style ) {
    for( int i=0; i<nodes.length; i++ ) {
      set_node_to_style( nodes.index( i ), style );
      set_all_to_style_helper( nodes.index( i ).children(), style );
    }
  }

  /* Sets all nodes at the specified levels to the given link style */
  public void set_levels_to_style( Array<Node> nodes, int levels, Style style ) {
    for( int i=0; i<10; i++ ) {
      if( (levels & (1 << i)) != 0 ) {
        _styles.index( i ).copy( style );
      }
    }
    set_levels_to_style_helper( nodes, levels, style, 0 );
  }

  /* Helper function for the set_levels_to_style */
  private void set_levels_to_style_helper( Array<Node> nodes, int levels, Style style, int level ) {
    for( int i=0; i<nodes.length; i++ ) {
      if( (levels & (1 << level)) != 0 ) {
        set_node_to_style( nodes.index( i ), style );
      }
      set_levels_to_style_helper( nodes.index( i ).children(), levels, style, (level + 1) );
    }
  }

  /* Sets the given node's link style to the given style */
  public void set_node_to_style( Node node, Style style ) {
    node.style.copy( style );
  }

  /* Returns the link type with the given name */
  public LinkType? get_link_type( string name ) {
    for( int i=0; i<_link_types.length; i++ ) {
      var link_type = _link_types.index( i );
      if( link_type.name() == name ) {
        return( link_type );
      }
    }
    return( null );
  }

  /* Returns the list of available link types */
  public Array<LinkType> get_link_types() {
    return( _link_types );
  }

  /* Returns the node border with the given name */
  public NodeBorder? get_node_border( string name ) {
    for( int i=0; i<_node_borders.length; i++ ) {
      var node_border = _node_borders.index( i );
      if( node_border.name() == name ) {
        return( node_border );
      }
    }
    return( null );
  }

  /* Return the list of available node borders */
  public Array<NodeBorder> get_node_borders() {
    return( _node_borders );
  }

}
