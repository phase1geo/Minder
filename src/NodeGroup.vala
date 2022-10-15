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
  public string    note  { get; set; default = ""; }
  public Array<Node> nodes {
    get {
      return( _nodes );
    }
  }

  /* Default constructor */
  public NodeGroup( DrawArea da, Node node ) {
    color  = node.link_color ?? da.get_theme().get_color( "root_background" );
    _nodes = new Array<Node>();
    add_node( node );
  }

  /* Constructor */
  public NodeGroup.array( DrawArea da, Array<Node> nodes ) {
    color  = nodes.index( 0 ).link_color ?? da.get_theme().get_color( "root_background" );
    _nodes = new Array<Node>();
    for( int i=0; i<nodes.length; i++ ) {
      add_node( nodes.index( i ) );
    }
  }

  /* Copy constructor */
  public NodeGroup.copy( NodeGroup group ) {
    color  = group.color;
    _nodes = new Array<Node>();
    for( int i=0; i<group._nodes.length; i++ ) {
      _nodes.append_val( group._nodes.index( i ) );
    }
  }

  /* Constructor from XML */
  public NodeGroup.from_xml( DrawArea da, Xml.Node* n ) {
    _nodes = new Array<Node>();
    load( da, n );
  }

  /* Adds the given node to this node group */
  public void add_node( Node node ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var n = _nodes.index( i );
      if( n.is_descendant_of( node ) ) {
        _nodes.index( i ).group = false;
        _nodes.remove_index( i );
      } else if( node.is_descendant_of( n ) ) {
        return;
      }
    }
    node.group = true;
    _nodes.append_val( node );
  }

  /* Checks to see if this group contains the given node and removes it if found */
  public bool remove_node( Node node ) {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ) == node ) {
        node.group = false;
        _nodes.remove_index( i );
        return( true );
      }
    }
    return( false );
  }

  /* Merges the other node group into this one */
  public void merge( NodeGroup other ) {
    for( int i=0; i<other._nodes.length; i++ ) {
      add_node( other._nodes.index( i ) );
    }
  }

  /* Returns true if the given coordinates are within a group */
  public bool is_within( double x, double y ) {
    var cursor = new NodePoint( x, y );
    var points = new Array<NodePoint?>();
    var hull   = new Array<NodePoint?>();
    points.append_val( cursor );
    for( int i=0; i<_nodes.length; i++ ) {
      get_tree_points( _nodes.index( i ), _nodes.index( i ), points );
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
    g->new_text_child( null, "groupnote", note );
    return( g );
  }

  /* Loads the given group information */
  public void load( DrawArea da, Xml.Node* g ) {
    string? c = g->get_prop( "color" );
    if( c != null ) {
      RGBA clr = {1.0, 1.0, 1.0, 1.0};
      clr.parse( c );
      color = clr;
    }
    for( Xml.Node* it = g->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch (it->name ) {
          case "node"      :  load_node( da, it );  break;
          case "groupnote" :  load_note( it );      break;
        }
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
        node.group = true;
        _nodes.append_val( node );
      }
    }
  }

  /* Loads the note value from the given XML node */
  private void load_note( Xml.Node* n ) {
    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      note = n->children->get_content();
    }
  }

  /* Draws a group around the stored set of nodes from this structure */
  public void draw( Context ctx, Theme theme ) {
    var points   = new Array<NodePoint?>();
    var selected = mode == GroupMode.SELECTED;
    var alpha    = 0.0;
    for( int i=0; i<_nodes.length; i++ ) {
      get_tree_points( _nodes.index( i ), _nodes.index( i ), points );
      alpha = (_nodes.index( i ).alpha > alpha) ? _nodes.index( i ).alpha : alpha;
    }
    draw_cloud( ctx, (selected ? theme.get_color( "nodesel_background" ) : color), selected, alpha, points );
  }

  /* Draws a group around this given node's tree */
  public static void draw_tree( Context ctx, Node node, Theme theme ) {
    var points = new Array<NodePoint?>();
    get_tree_points( node, node, points );
    draw_cloud( ctx, node.link_color, false, node.alpha, points );
  }

  /* Draws the cloud associated with this group */
  private static void draw_cloud( Context ctx, RGBA color, bool selected, double alpha, Array<NodePoint?> points ) {

    /* Calculate the hull points */
    var hull = new Array<NodePoint?>();
    get_convex_hull( points, hull );

    /* If there is nothing to draw, return */
    if( hull.length == 0 ) return;

    /* Draw the fill */
    Utils.set_context_color_with_alpha( ctx, color, (alpha * 0.3) );
    ctx.move_to( hull.index( 0 ).x, hull.index( 0 ).y );
    for( int i=0; i<hull.length; i++ ) {
      ctx.line_to( hull.index( i ).x, hull.index( i ).y );
    }
    ctx.close_path();

    /* Draw the stroke */
    if( selected ) {
      ctx.fill_preserve();
      Utils.set_context_color_with_alpha( ctx, color, alpha );
      ctx.stroke();
    } else {
      ctx.fill();
    }

  }

  /* Add the given node points to the points array */
  public static void add_node_points( Array<NodePoint?> points, Node node, int pad = 0 ) {

    var x1  = node.posx - pad;
    var y1  = node.posy - pad;
    var x2  = node.posx + node.width + pad;
    var y2  = node.posy + node.height + pad;

    if( node.folded ) {
      double fx, fy, fw, fh;
      node.fold_bbox( out fx, out fy, out fw, out fh );
      switch( node.side ) {
        case NodeSide.LEFT   :  x1 = fx - pad;       break;
        case NodeSide.RIGHT  :  x2 = fx + fw + pad;  break;
        case NodeSide.TOP    :  y1 = fy - pad;       break;
        case NodeSide.BOTTOM :  y2 = fy + fh + pad;  break;
      }
    }

    points.append_val( new NodePoint( x1, y1 ) );
    points.append_val( new NodePoint( x2, y1 ) );
    points.append_val( new NodePoint( x1, y2 ) );
    points.append_val( new NodePoint( x2, y2 ) );

  }

  /* Gets the set of all points in the given node tree */
  public static void get_tree_points( Node origin, Node node, Array<NodePoint?> points ) {
    if( node.folded_ancestor() == null ) {
      var pad = node.groups_between( origin ) * 5;
      add_node_points( points, node, pad );
      for( int i=0; i<node.children().length; i++ ) {
        get_tree_points( origin, node.children().index( i ), points );
      }
    }
  }

  /* Gets the array of all points necessary to draw a tight perimeter around the given set of node points */
  public static void get_convex_hull( Array<NodePoint?> points, Array<NodePoint?> hull ) {

    var n = (int)points.length;

    if( n == 0 ) return;

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
