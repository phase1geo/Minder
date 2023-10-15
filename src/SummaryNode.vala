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
  private double     _first_xy;
  private double     _last_xy;

  // If this is set to true, the summary line will be drawn in the attachable color to indicate that
  // releasing a node that is being moved will be a part of the summary node.
  public bool attachable { set; get; default = false; }

  /* Default constructor */
  public SummaryNode( DrawArea da, Layout? layout ) {
    base( da, layout );
    _nodes = new List<Node>();
  }

  /* Converts the given node into a summary node that summarizes its sibling nodes */
  public SummaryNode.from_node( DrawArea da, Node node, ImageManager im ) {
    base.copy( da, node, im );
    _nodes = new List<Node>();
  }

  /* Constructor from XML data */
  public SummaryNode.from_xml( DrawArea da, Layout? layout, Xml.Node* node, ref Array<Node> siblings ) {
    base( da, layout );
    _nodes = new List<Node>();
    load( da, node, false, ref siblings );
  }

  /* Connects the node to signals */
  private void connect_node( Node node ) {
    node.moved.connect( nodes_changed );
    node.resized.connect( nodes_changed );
  }

  /* Disconnects the node from signals */
  private void disconnect_node( Node node ) {
    node.moved.disconnect( nodes_changed );
    node.resized.disconnect( nodes_changed );
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
    if( side.horizontal() ) {
      return( (_first_xy <= y) && (y <= _last_xy) );
    } else {
      return( (_first_xy <= x) && (x <= _last_xy) );
    }
  }

  /* Updates the stored summarized extents based on the current layout and first/last position */
  public void update_extents() {

    double fx, fy, fw, fh;
    double lx, ly, lw, lh;
    first_node().bbox( out fx, out fy, out fw, out fh );
    last_node().bbox( out lx, out ly, out lw, out lh );

    if( side.horizontal() ) {
      _first_xy = fy;
      _last_xy  = ly + lh;
    } else {
      _first_xy = fx;
      _last_xy  = lx + lw;
    }

  }

  /* Comparison function of two double types */
  private static int compare_pos( double pos1, double pos2 ) {
    return( (pos1 == pos2) ? 0 : (pos1 < pos2) ? -1 : 1 );
  }

  /* Called whenever the first or last summarized nodes changes in position or size, we need to adjust our location */
  public void nodes_changed( double first_diffx, double first_diffy ) {

    /* Let's resort the summarized nodes in case some nodes changed location */
    if( side.horizontal() ) {
      _nodes.sort((a, b) => { return( compare_pos( a.posy, b.posy ) ); });
    } else {
      _nodes.sort((a, b) => { return( compare_pos( a.posx, b.posx ) ); });
    }

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

    var old_posx = posx;
    var old_posy = posy;

    switch( side ) {
      case NodeSide.LEFT   :  posx = (x1 - width) - margin;                posy = (((y2 - y1) / 2) - (height / 2)) + y1;  break;
      case NodeSide.RIGHT  :  posx = x2 + margin;                          posy = (((y2 - y1) / 2) - (height / 2)) + y1;  break;
      case NodeSide.TOP    :  posx = (((x2 -x1) / 2) - (width / 2)) + x1;  posy = (y1 - height) - margin;                 break;
      case NodeSide.BOTTOM :  posx = (((x2 -x1) / 2) - (width / 2)) + x1;  posy = y2 + margin;                            break;
    }

    var diffx = posx - old_posx;
    var diffy = posy - old_posy;
    moved( diffx, diffy );

  }

  /* Attach ourself to the list of nodes */
  public void attach_nodes( Array<Node> nodes, Theme? theme ) {
    for( int i=0; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      _nodes.append( node );
      node.children().append_val( this );
      connect_node( node );
    }
    _nodes.sort((a, b) => {
      return( (a.index() == b.index()) ? 0 :
              (a.index() <  b.index()) ? -1 : 1 );
    });
    parent = last_node();
    style  = last_node().style;
    if( theme != null ) {
      link_color_child = main_branch() ? theme.next_color() : parent.link_color;
    }
    update_extents();
    nodes_changed( 0, 0 );
  }

  /*
   We attach ourself to the given node and all of its siblings that are on the same side, contain no children and are not
   already summarized.
  */
  public void attach_siblings( Node node, Theme? theme ) {
    var sibling = node;
    while( (sibling != null) && sibling.is_leaf() && !sibling.is_summarized() && (sibling.side == side) ) {
      _nodes.prepend( sibling );
      sibling.children().append_val( this );
      connect_node( sibling );
      sibling = sibling.previous_sibling();
    }
    parent = last_node();
    style  = last_node().style;
    if( theme != null ) {
      link_color_child = main_branch() ? theme.next_color() : parent.link_color;
    }
    update_extents();
    nodes_changed( 0, 0 );
  }

  /* We just attach our existing nodes back to their original values (used in undo/redo operations) */
  public void attach_all() {
    foreach( var node in _nodes ) {
      node.children().append_val( this );
      connect_node( node );
    }
    update_extents();
  }

  /* We just detach ourselves from the node list */
  public void detach_all() {
    foreach( var node in _nodes ) {
      node.children().remove_index( 0 );
      disconnect_node( node );
    }
  }

  /* Adds the given node to the list of summarized nodes */
  public void add_node( Node node, int index ) {
    _nodes.insert( node, index );
    node.children().append_val( this );
    connect_node( node );
    parent = last_node();
    update_extents();
    nodes_changed( 0, 0 );
  }

  /* Moves the given node from its current location to a new location */
  public void move_node( Node node, int to_index ) {
    var from_index = _nodes.index( node );
    if( from_index != -1 ) {
      if( from_index > to_index ) {
        _nodes.remove( node );
        _nodes.insert( node, to_index );
      } else if( from_index < to_index ) {
        _nodes.remove( node );
        _nodes.insert( node, (to_index - 1) );
      }
      parent = last_node();
      update_extents();
      nodes_changed( 0, 0 );
    }
  }

  /* Removes the given node from the list of summarized nodes */
  public void remove_node( Node node ) {
    _nodes.remove( node );
    node.children().remove_range( 0, 1 );
    disconnect_node( node );
    parent = last_node();
    update_extents();
    nodes_changed( 0, 0 );
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
    var y1 = _first_xy;
    var x2 = sx - 20;
    var y2 = _last_xy;

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
    var y1 = _first_xy;
    var x2 = sx + 20;
    var y2 = _last_xy;

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

    var x1 = _first_xy;
    var y1 = sy - 10;
    var x2 = _last_xy;
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

    var x1 = _first_xy;
    var y1 = sy + 10;
    var x2 = _last_xy;
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
      case NodeSide.LEFT   :  draw_link_left( ctx );   break;
      case NodeSide.RIGHT  :  draw_link_right( ctx );  break;
      case NodeSide.TOP    :  draw_link_above( ctx );  break;
      case NodeSide.BOTTOM :  draw_link_below( ctx );  break;
    }

  }

}
