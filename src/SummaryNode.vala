/*
* Copyright (c) 2018-2021 (https://github.com/phase1geo/Minder)
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

public class SummaryNode : Node {

  private List<Node> _nodes;
  private double?    _first_xy = null;
  private double?    _last_xy  = null;

  /*
   If this is set to true, the summary line will be drawn in the attachable color to indicate that
   releasing a node that is being moved will be a part of the summary node.
  */
  public bool attachable { set; get; default = false; }

  /* Remembers the last selected summarized node when the selection changed to us */
  public Node? last_selected_node { get; set; default = null; }

  /* Default constructor */
  public SummaryNode( MindMap map, Layout? layout ) {
    base( map, layout );
    _nodes = new List<Node>();
  }

  /* Converts the given node into a summary node that summarizes its sibling nodes */
  public SummaryNode.from_node( MindMap map, Node node, ImageManager im ) {
    base.copy( map, node, im );
    _nodes = new List<Node>();
  }

  /* Constructor from XML data */
  public SummaryNode.from_xml( MindMap map, Layout? layout, Xml.Node* node, ref Array<Node> siblings ) {
    base( map, layout );
    _nodes = new List<Node>();
    load( map, node, false, null, ref siblings );
  }

  /* Connects the node to signals */
  private void connect_node( Node node ) {
    node.moved.connect( nodes_changed_moved );
    node.resized.connect( nodes_changed_resized );
  }

  /* Disconnects the node from signals */
  private void disconnect_node( Node node ) {
    node.moved.disconnect( nodes_changed_moved );
    node.resized.disconnect( nodes_changed_resized );
  }

  /* Returns the number of nodes that this node summarizes */
  public int summarized_count() {
    return( (int)_nodes.length() );
  }

  /* Returns the first node that is summarized */
  public Node first_node() {
    return( _nodes.first().data );
  }

  /* Returns the last node that is summarized */
  public Node last_node() {
    return( _nodes.last().data );
  }

  /* Returns the index of the given node in the list of summarized nodes.  Returns -1 if the node could not be found. */
  public int node_index( Node node ) {
    return( _nodes.index( node ) );
  }

  /* Returns true to indicate that this is a summary node */
  public override bool is_summary() {
    return( true );
  }

  /* Returns true if the given coordinates is within the horizontal/vertical extents of the list of summarized nodes */
  public bool is_within_summarized( double x, double y ) {
    if( _first_xy == null ) return( false );
    if( side.horizontal() ) {
      return( ((_first_xy + map.origin_y) <= y) && (y <= (_last_xy + map.origin_y)) );
    } else {
      return( ((_first_xy + map.origin_x) <= x) && (x <= (_last_xy + map.origin_x)) );
    }
  }

  /* Clears the extents */
  public void clear_extents() {
    _first_xy = null;
    _last_xy  = null;
  }

  /* Returns the top/bottom or left/right extents of the summarized nodes */
  public void get_extents( out double xy1, out double xy2 ) {

    if( _nodes.length() == 0 ) {
      xy1 = 0;
      xy2 = 0;
      return;
    }

    double fx, fy, fw, fh;
    double lx, ly, lw, lh;
    first_node().bbox( out fx, out fy, out fw, out fh );
    last_node().bbox( out lx, out ly, out lw, out lh );

    xy1 = side.horizontal() ? fy : fx;
    xy2 = side.horizontal() ? (ly + lh) : (lx + lw);

  }

  /* Updates the stored summarized extents based on the current layout and first/last position */
  public void set_extents() {

    /* If we don't have any nodes, this is bad */
    assert( _nodes.length() > 0 );

    double xy1, xy2;
    get_extents( out xy1, out xy2 );

    var first_margin = first_node().style.node_margin;
    var last_margin  = last_node().style.node_margin;
    var origin       = side.horizontal() ? map.origin_y : map.origin_x;

    _first_xy = (xy1 + first_margin) - origin;
    _last_xy  = (xy2 - last_margin)  - origin;

  }

  /* Comparison function of two double types */
  private static int compare_pos( double pos1, double pos2 ) {
    return( (pos1 == pos2) ? 0 : (pos1 < pos2) ? -1 : 1 );
  }

  private void nodes_changed_moved( double fx, double fy ) {
    // nodes_changed( fx, fy, "moved" );
  }

  private void nodes_changed_resized( double fx, double fy ) {
    nodes_changed( fx, fy, "resized" );
  }

  /* Called whenever the first or last summarized nodes changes in position or size, we need to adjust our location */
  public void nodes_changed( double fx, double fy, string msg = "" ) {

    var margin = style.branch_margin ?? 0;
    var x1     = first_node().posx;
    var y1     = first_node().posy;
    var x2     = first_node().posx + first_node().width;
    var y2     = first_node().posy + first_node().height;

    foreach( var node in _nodes ) {
      if( x1 > node.posx )                 { x1 = node.posx; }
      if( y1 > node.posy )                 { y1 = node.posy; }
      if( x2 < (node.posx + node.width) )  { x2 = (node.posx + node.width); }
      if( y2 < (node.posy + node.height) ) { y2 = (node.posy + node.height); }
    }

    stdout.printf( "In nodes_changed, side: %s, fx: %g, fy: %g, x1: %g, y1: %g, x2: %g, y2: %g, msg: %s\n", side.to_string(), fx, fy, x1, y1, x2, y2, msg );

    switch( side ) {
      case NodeSide.LEFT   :  
        posx = (fx == 0) ? posx : (x1 - width) - margin;
        posy = (fy == 0) ? posy : (((y2 - y1) / 2) - (height / 2)) + y1;
        break;
      case NodeSide.RIGHT  :  
        posx = (fx == 0) ? posx : x2 + margin;
        posy = (fy == 0) ? posy : (((y2 - y1) / 2) - (height / 2)) + y1;
        break;
      case NodeSide.TOP    :  
        posx = (fx == 0) ? posx : (((x2 -x1) / 2) - (width / 2)) + x1;
        posy = (fy == 0) ? posy : (y1 - height) - margin;
        break;
      case NodeSide.BOTTOM :  
        posx = (fx == 0) ? posx : (((x2 -x1) / 2) - (width / 2)) + x1;
        posy = (fy == 0) ? posy : y2 + margin;
        break;
    }

  }

  /* Attach ourself to the list of nodes */
  public void attach_nodes( Node p, Array<Node> nodes, bool sort, Theme? theme ) {
    assert( nodes.length > 0 );
    for( int i=0; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      _nodes.append( node );
      node.children().append_val( this );
      connect_node( node );
    }
    p.moved.connect( parent_moved );
    if( sort ) {
      sort_nodes();
    } else {
      parent = last_node();
      update_tree_bboxes();
    }
    layout.handle_update_by_insert( parent, this, -1 );
    style  = last_node().style;
    /*
    if( layout != null ) {
      layout.handle_update_by_insert( parent, this, -1 );
    }
    */
    if( theme != null ) {
      link_color_child = main_branch() ? theme.next_color() : parent.link_color;
    }
  }

  /*
   We attach ourself to the given node and all of its siblings that are on the same side, contain no children and are not
   already summarized.
  */
  public void attach_siblings( Node node, Theme? theme ) {
    var sibling = node;
    var nodes   = new Array<Node>();
    while( (sibling != null) && sibling.is_leaf() && !sibling.is_summarized() && (sibling.side == side) ) {
      nodes.prepend_val( sibling );
      sibling = sibling.previous_sibling();
    }
    attach_nodes( node.parent, nodes, false, theme );
  }

  /* We just attach our existing nodes back to their original values (used in undo/redo operations) */
  public void attach_all() {
    foreach( var node in _nodes ) {
      node.children().append_val( this );
      connect_node( node );
    }
    first_node().parent.moved.connect( parent_moved );
    parent = last_node();
  }

  /* We just detach ourselves from the node list */
  public void detach_all() {
    first_node().parent.moved.disconnect( parent_moved );
    foreach( var node in _nodes ) {
      node.children().remove_index( 0 );
      disconnect_node( node );
    }
    parent = null;
  }

  /* Overrides the standard detachment */
  public override void detach( NodeSide side ) {
    detach_all();
    /*
    if( layout != null ) {
      layout.handle_update_by_delete( parent, idx, side, tree_size );
    }
    */
  }

  /* Update the tree_bbox structures of the summarized nodes */
  private void update_tree_bboxes() {
    foreach( var node in _nodes ) {
      node.tree_bbox = layout.bbox( node, -1, "update_tree_bboxes" );
      node.tree_size = side.horizontal() ? node.tree_bbox.height : node.tree_bbox.width;
    }
  }

  /* Re-sorts nodes that are fixed in their location and updates the parent */
  private void sort_nodes() {
    _nodes.sort((a, b) => {
      return( (a.index() == b.index()) ? 0 :
              (a.index() <  b.index()) ? -1 : 1 );
    });
    parent = last_node();
    update_tree_bboxes();
  }

  /* Adds the given node to the list of summarized nodes */
  public void add_node( Node node ) {

    _nodes.append( node );
    node.children().append_val( this );
    connect_node( node );
    sort_nodes();

    // nodes_changed( 1, 1, "add_nodes" );

  }

  /* Moves the given node from its current location to a new location */
  public void node_moved( Node node ) {

    sort_nodes();

    // nodes_changed( 1, 1, "node_moved" );

  }

  /* Removes the given node from the list of summarized nodes */
  public void remove_node( Node node ) {

    var update_color = (node == parent);

    _nodes.remove( node );
    node.children().remove_range( 0, 1 );
    disconnect_node( node );
    sort_nodes();

    if( update_color ) {
      link_color_child = parent.link_color;
    }

    // nodes_changed( 1, 1, "remove_node" );

  }

  /* Removes all summarized nodes from this node so that it can be deleted */
  public override void delete() {
    detach_all();
  }

  /* Draws the link to the left of the summarized nodes */
  private void draw_link_left( Context ctx ) {

    double x, y, w, h;
    node_bbox( out x, out y, out w, out h );

    /* Get the smallest X value */
    var sx = first_node().posx;
    foreach( var node in _nodes ) {
      if( sx > node.posx ) {
        sx = node.posx;
      }
    }

    var x1 = sx - 10;
    var y1 = ((_first_xy == null) ? first_node().posy : (_first_xy + map.origin_x)) + first_node().style.node_margin;
    var x2 = sx - 20;
    var y2 = ((_last_xy == null) ? (last_node().posy + last_node().height) : (_last_xy + map.origin_y)) - last_node().style.node_margin;

    ctx.move_to( x1, y1 );
    ctx.line_to( x2, y1 );
    ctx.line_to( x2, y2 );
    ctx.line_to( x1, y2 );
    ctx.stroke();

    var margin = style.node_margin;
    h = (style.node_border.name() == "underlined") ? (h - margin) : (h / 2);

    Utils.set_context_color_with_alpha( ctx, link_color, ((_nodes.length() == 1) ? parent.alpha : alpha) );
    ctx.move_to( x2, (((y2 - y1) / 2) + y1) );
    ctx.line_to( (x + w - margin), (y + h) );
    ctx.stroke();

  }

  /* Draws the link to the right of the summarized nodes */
  private void draw_link_right( Context ctx ) {

    double x, y, w, h;
    node_bbox( out x, out y, out w, out h );

    /* Get the smallest X value */
    var sx = first_node().posx;
    foreach( var node in _nodes ) {
      if( sx < (node.posx + node.total_width) ) {
        sx = node.posx + node.total_width;
      }
    }

    var x1 = sx + 10;
    var y1 = ((_first_xy == null) ? first_node().posy : (_first_xy + map.origin_y)) + first_node().style.node_margin;
    var x2 = sx + 20;
    var y2 = ((_last_xy == null) ? (last_node().posy + last_node().height) : (_last_xy + map.origin_y)) - last_node().style.node_margin;

    ctx.move_to( x1, y1 );
    ctx.line_to( x2, y1 );
    ctx.line_to( x2, y2 );
    ctx.line_to( x1, y2 );
    ctx.stroke();

    var margin = style.node_margin;
    h = (style.node_border.name() == "underlined") ? (h - margin) : (h / 2);

    Utils.set_context_color_with_alpha( ctx, link_color, ((_nodes.length() == 1) ? parent.alpha : alpha) );
    ctx.move_to( x2, (((y2 - y1) / 2) + y1) );
    ctx.line_to( (x + margin), (y + h) );
    ctx.stroke();

  }

  /* Draws the summary bracket above the nodes */
  private void draw_link_above( Context ctx ) {

    double x, y, w, h;
    node_bbox( out x, out y, out w, out h );

    /* Get the smallest X value */
    var sy = first_node().posy;
    foreach( var node in _nodes ) {
      if( sy > node.posy ) {
        sy = node.posy;
      }
    }

    var x1 = ((_first_xy == null) ? first_node().posx : (_first_xy + map.origin_x)) + first_node().style.node_margin;
    var y1 = sy - 10;
    var x2 = ((_last_xy == null) ? (last_node().posx + last_node().width) : (_last_xy + map.origin_x)) - last_node().style.node_margin;
    var y2 = sy - 20;

    ctx.move_to( x1, y1 );
    ctx.line_to( x1, y2 );
    ctx.line_to( x2, y2 );
    ctx.line_to( x2, y1 );
    ctx.stroke();

    var margin = style.node_margin;

    Utils.set_context_color_with_alpha( ctx, link_color, ((_nodes.length() == 1) ? parent.alpha : alpha) );
    ctx.move_to( (((x2 - x1) / 2) + x1), y2 );
    ctx.line_to( ((w / 2) + x), (y + h - margin) );
    ctx.stroke();

  }

  /* Draws the summary bracket above the nodes */
  private void draw_link_below( Context ctx ) {

    double x, y, w, h;
    node_bbox( out x, out y, out w, out h );

    /* Get the smallest X value */
    var sy = first_node().posy;
    foreach( var node in _nodes ) {
      if( sy < (node.posy + node.total_height) ) {
        sy = (node.posy + node.total_height);
      }
    }

    var x1 = ((_first_xy == null) ? first_node().posx : (_first_xy + map.origin_x)) + first_node().style.node_margin;
    var y1 = sy + 10;
    var x2 = ((_last_xy == null) ? (last_node().posx + last_node().width) : (_last_xy + map.origin_x)) - last_node().style.node_margin;
    var y2 = sy + 20;

    ctx.move_to( x1, y1 );
    ctx.line_to( x1, y2 );
    ctx.line_to( x2, y2 );
    ctx.line_to( x2, y1 );
    ctx.stroke();

    var margin = style.node_margin;

    Utils.set_context_color_with_alpha( ctx, link_color, ((_nodes.length() == 1) ? parent.alpha : alpha) );
    ctx.move_to( (((x2 - x1) / 2) + x1), y2 );
    ctx.line_to( ((w / 2) + x), (y + margin) );
    ctx.stroke();

  }

  /* Draw the summary link that spans the first and last node */
  public override void draw_link( Context ctx, Theme theme ) {

    var color = link_color;

    if( attachable ) {
      color = theme.get_color( "attachable" );
    }

    Utils.set_context_color_with_alpha( ctx, color, ((_nodes.length() == 1) ? parent.alpha : alpha) );
    ctx.set_line_cap( LineCap.ROUND );
    ctx.set_line_width( parent.style.link_width );

    switch( side ) {
      case NodeSide.LEFT   : draw_link_left( ctx );   break;
      case NodeSide.RIGHT  : draw_link_right( ctx );  break;
      case NodeSide.TOP    : draw_link_above( ctx );  break;
      case NodeSide.BOTTOM : draw_link_below( ctx );  break;
    }

  }

}
