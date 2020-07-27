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

public struct NodePoint {
  double x;
  double y;
  public NodePoint( double x, double y ) {
    this.x = x;
    this.y = y;
  }
}

public enum GroupMode {
  NONE = 0,
  SELECTED
}

public class NodeGroup {

  private Array<Node> _nodes;

  public GroupMode mode  { get; set; default = GroupMode.NONE; }
  public RGBA      color { get; set; }
  public double    alpha { get; set; default = 1.0; }

  /* Default constructor */
  public NodeGroup( DrawArea da, Array<Node> nodes ) {
    _nodes = new Array<Node>();
    color  = da.get_theme().get_color( "tag" );
    for( int i=0; i<nodes.length; i++ ) {
      _nodes.append_val( nodes.index( i ) );
    }
  }

  /* Constructor from XML */
  public NodeGroup.from_xml( DrawArea da, Xml.Node* n ) {
    _nodes = new Array<Node>();
    color  = da.get_theme().get_color( "tag" );
    load( da, n );
  }

  /* Adds the given node to this node group */
  public void add_node( Node node ) {
    _nodes.append_val( node );
  }

  /* Checks to see if this group contains the given node and removes it if found */
  public bool remove_node( Node node ) {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ) == node ) {
        _nodes.remove_index( i );
        return( true );
      }
    }
    return( false );
  }

  /* Returns true if the given coordinates are within a group */
  public bool is_within( double x, double y ) {
    var cursor = new NodePoint( x, y );
    var points = new Array<NodePoint?>();
    var hull   = new Array<NodePoint?>();
    points.append_val( cursor );
    for( int i=0; i<_nodes.length; i++ ) {
      add_node_points( points, _nodes.index( i ) );
    }
    get_convex_hull( points, hull );
    for( int i=0; i<hull.length; i++ ) {
      if( (cursor.x == hull.index( i ).x) && (cursor.y == hull.index( i ).y) ) {
        return( false );
      }
    }
    return( true );
  }

  /* Saves the current group in Minder XML format */
  public Xml.Node* save() {
    Xml.Node* g = new Xml.Node( null, "group" );
    g->set_prop( "color", Utils.color_from_rgba( color ) );
    for( int i=0; i<_nodes.length; i++ ) {
      Xml.Node* n = new Xml.Node( null, "node" );
      n->set_prop( "id", _nodes.index( i ).id().to_string() );
      g->add_child( n );
    }
    return( g );
  }

  /* Loads the given group information */
  public void load( DrawArea da, Xml.Node* g ) {
    string? c = g->get_prop( "color" );
    if( c != null ) {
      color.parse( c );
    }
    for( Xml.Node* it = g->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        load_node( da, it );
      }
    }
  }

  /* Loads the given node */
  private void load_node( DrawArea da, Xml.Node* n ) {
    string? i = n->get_prop( "id" );
    if( i != null ) {
      var id   = int.parse( i );
      var node = da.get_node( da.get_nodes(), id );
      if( node != null ) {
        _nodes.append_val( node );
      }
    }
  }

  /* Draws a group around the stored set of nodes from this structure */
  public void draw( Context ctx, Theme theme ) {
    var points   = new Array<NodePoint?>();
    var selected = mode == GroupMode.SELECTED;
    for( int i=0; i<_nodes.length; i++ ) {
      add_node_points( points, _nodes.index( i ) );
    }
    draw_cloud( ctx, (selected ? theme.get_color( "nodesel_background" ) : color), selected, alpha, points );
  }

  /* Draws a group around this given node's tree */
  public static void draw_tree( Context ctx, Node node, Theme theme ) {
    var points = new Array<NodePoint?>();
    get_tree_points( node, node, points );
    draw_cloud( ctx, node.link_color, false, node.alpha, points );
  }

  private static void draw_cloud( Context ctx, RGBA color, bool selected, double alpha, Array<NodePoint?> points ) {

    /* Calculate the hull points */
    var hull = new Array<NodePoint?>();
    get_convex_hull( points, hull );

    /* Draw the fill */
    Utils.set_context_color_with_alpha( ctx, color, ((alpha == 1.0) ? 0.3 : alpha) );
    ctx.move_to( hull.index( 0 ).x, hull.index( 0 ).y );
    for( int i=0; i<hull.length; i++ ) {
      ctx.line_to( hull.index( i ).x, hull.index( i ).y );
    }
    ctx.close_path();
    ctx.fill();

    /* Draw the stroke */
    if( selected ) {
      Utils.set_context_color_with_alpha( ctx, color, alpha );
      ctx.move_to( hull.index( 0 ).x, hull.index( 0 ).y );
      ctx.set_line_width( 2 );
      for( int i=0; i<hull.length; i++ ) {
        ctx.line_to( hull.index( i ).x, hull.index( i ).y );
      }
      ctx.close_path();
      ctx.stroke();
    }

  }

  /* Add the given node points to the points array */
  public static void add_node_points( Array<NodePoint?> points, Node node, int pad = 0 ) {

    var x1  = node.posx - pad;
    var y1  = node.posy - pad;
    var x2  = node.posx + node.width + pad;
    var y2  = node.posy + node.height + pad;

    points.append_val( new NodePoint( x1, y1 ) );
    points.append_val( new NodePoint( x2, y1 ) );
    points.append_val( new NodePoint( x1, y2 ) );
    points.append_val( new NodePoint( x2, y2 ) );

  }

  /* Gets the set of all points in the given node tree */
  public static void get_tree_points( Node origin, Node node, Array<NodePoint?> points ) {
    var pad = node.groups_between( origin ) * 5;
    add_node_points( points, node, pad );
    for( int i=0; i<node.children().length; i++ ) {
      get_tree_points( origin, node.children().index( i ), points );
    }
  }

  /* Gets the array of all points necessary to draw a tight perimeter around the given set of node points */
  public static void get_convex_hull( Array<NodePoint?> points, Array<NodePoint?> hull ) {

    var n = (int)points.length;

    /* Get the left-most point */
    var l = 0;
    for( int i=1; i<n; i++ ) {
      if( points.index( i ).x < points.index( l ).x ) l = i;
    }

    var p = l;

    do {
      hull.append_val( points.index( p ) );
      var q = (p + 1) % n;
      for( int i=0; i<n; i++ ) {
        if( calc_orientation( points.index( p ), points.index( i ), points.index( q ) ) == 2 ) q = i;
      }
      p = q;
    } while( p != l );

  }

  /* Returns the side of the line that point 'r' lands on */
  public static int calc_orientation( NodePoint p, NodePoint q, NodePoint r ) {
    var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
    if( val == 0 ) return( 0 );
    return( (val > 0) ? 1 : 2 );
  }

}
