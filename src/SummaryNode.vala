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

  /* Default constructor */
  public SummaryNode( DrawArea da, Array<Node> nodes, Layout? layout ) {
    base( da, layout );
    _nodes = new List<Node>();
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
    parent = first_node();
    style  = first_node().style;
    nodes_changed( 0, 0 );
  }

  /* Converts the given node into a summary node that summarizes its sibling nodes */
  public SummaryNode.from_sibling( DrawArea da, Node node, ImageManager im ) {
    base.copy( da, node, im );
    _nodes = new List<Node>();
    var sibling = node.previous_sibling();
    while( (sibling != null) && (sibling.children().length == 0) && !sibling.is_summarized() && (sibling.side == node.side) ) {
      _nodes.prepend( sibling );
      sibling.children().append_val( this );
      sibling = node.previous_sibling();
      connect_node( sibling );
    }
    parent = first_node();
    style  = first_node().style;
    nodes_changed( 0, 0 );
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

  /* Returns true to indicate that this is a summary node */
  public override bool is_summary() {
    return( true );
  }

  private static int compare_pos( double pos1, double pos2 ) {
    return( (pos1 == pos2) ? 0 : (pos1 < pos2) ? -1 : 1 );
  }

  /* Called whenever the first or last summarized nodes changes in position or size, we need to adjust our location */
  private void nodes_changed( double first_diffx, double first_diffy ) {

    /* Let's resort the summarized nodes in case some nodes changed location */
    if( (side & NodeSide.horizontal()) != 0 ) {
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

  /* Attaches this node to its parent node */
  /*
  protected override void attach_common( int index, Theme? theme ) {
    lastparent.children().append_val( this );
    parent.moved.connect( this.parent_moved );
    if( layout != null ) {
      layout.handle_update_by_insert( parent, this, index );
    }
    if( theme != null ) {
      link_color_child = main_branch() ? theme.next_color() : parent.link_color;
    }
    attached = true;
  }
  */

  /* Draws the link to the left of the summarized nodes */
  private void draw_link_left( Context ctx ) {

    double x, y, w, h;
    node_bbox( out x, out y, out w, out h );

    /* Get the smallest X value */
    var sx = first_node().posx;
    foreach( var node in _nodes ) {
      if( sx < node.posx ) {
        sx = node.posx;
      }
    }

    var x1 = sx - 10;
    var y1 = first_node().posy;
    var x2 = sx - 20;
    var y2 = last_node().posy + last_node().height;

    ctx.move_to( x1, y1 );
    ctx.line_to( x2, y1 );
    ctx.line_to( x2, y2 );
    ctx.line_to( x1, y2 );
    ctx.stroke();

    ctx.move_to( x2, (((y2 - y1) / 2) + y1) );
    ctx.line_to( (x + w), ((h / 2) + y) );
    ctx.stroke();

  }

  /* Draws the link to the right of the summarized nodes */
  private void draw_link_right( Context ctx ) {

    double x, y, w, h;
    node_bbox( out x, out y, out w, out h );

    /* Get the smallest X value */
    var sx = first_node().posx;
    foreach( var node in _nodes ) {
      if( sx < (node.posx + node.width) ) {
        sx = node.posx + node.width;
      }
    }

    var x1 = sx + 10;
    var y1 = first_node().posy;
    var x2 = sx + 20;
    var y2 = last_node().posy + last_node().height;

    ctx.move_to( x1, y1 );
    ctx.line_to( x2, y1 );
    ctx.line_to( x2, y2 );
    ctx.line_to( x1, y2 );
    ctx.stroke();

    ctx.move_to( x2, (((y2 - y1) / 2) + y1) );
    ctx.line_to( x, ((h / 2) + y) );
    ctx.stroke();

  }

  /* Draws the summary bracket above the nodes */
  private void draw_link_above( Context ctx ) {

    double x, y, w, h;
    node_bbox( out x, out y, out w, out h );

    /* Get the smallest X value */
    var sy = first_node().posy;
    foreach( var node in _nodes ) {
      if( sy < node.posy ) {
        sy = node.posy;
      }
    }

    var x1 = first_node().posx;
    var y1 = sy - 10;
    var x2 = last_node().posx + last_node().width;
    var y2 = sy - 20;

    ctx.move_to( x1, y1 );
    ctx.line_to( x1, y2 );
    ctx.line_to( x2, y2 );
    ctx.line_to( x2, y1 );
    ctx.stroke();

    ctx.move_to( (((x2 - x1) / 2) + x1), y2 );
    ctx.line_to( ((w / 2) + x), y );
    ctx.stroke();

  }

  /* Draws the summary bracket above the nodes */
  private void draw_link_below( Context ctx ) {

    double x, y, w, h;
    node_bbox( out x, out y, out w, out h );

    /* Get the smallest X value */
    var sy = first_node().posy;
    foreach( var node in _nodes ) {
      if( sy < node.posy ) {
        sy = node.posy;
      }
    }

    var x1 = first_node().posx;
    var y1 = sy + 10;
    var x2 = last_node().posx + last_node().width;
    var y2 = sy + 20;

    ctx.move_to( x1, y1 );
    ctx.line_to( x1, y2 );
    ctx.line_to( x2, y2 );
    ctx.line_to( x2, y1 );
    ctx.stroke();

    var mx = (w / 2) + x;
    ctx.move_to( (((y2 - y1) / 2) + y1), y2 );
    ctx.line_to( ((w / 2) + x), y );
    ctx.stroke();

  }

  /* Draw the summary link that spans the first and last node */
  public override void draw_link( Context ctx, Theme theme ) {

    Utils.set_context_color_with_alpha( ctx, theme.get_color( "callout_background" ), ((parent.alpha != 1.0) ? parent.alpha : alpha) );
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
