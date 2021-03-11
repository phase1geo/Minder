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

  private Node _first;
  private Node _last;

  public Node first_node {
    get {
      return( _first );
    }
  }
  public Node last_node {
    get {
      return( _last );
    }
  }

  /* Default constructor */
  public SummaryNode( DrawArea da, Node first_node, Node last_node, Layout? layout ) {
    base( da, layout );
    _first = first_node;
    _last  = last_node;
    attach( _first, -1, null );
  }

  /* Returns true to indicate that this is a summary node */
  public override bool is_summary() {
    return( true );
  }

  /* Draw the summary link that spans the first and last node */
  public override void draw_link( Context ctx, Theme theme ) {

    var fb = _first.tree_bbox;
    var lb = _last.tree_bbox;

    var x1 = 0.0;
    var y1 = 0.0;
    var x2 = 0.0;
    var y2 = 0.0;

    switch( side ) {
      case NodeSide.LEFT :
        x1 = Math.fmin( fb.x1(), lb.x1() ) - 20;  y1 = fb.y1();
        x2 = x1;                                  y2 = lb.y2();
        break;
      case NodeSide.RIGHT :
        x1 = Math.fmax( fb.x2(), lb.x2() ) + 20;  y1 = fb.y1();
        x2 = x1;                                  y2 = fb.y2();
        break;
      case NodeSide.TOP :
        x1 = fb.x1();  y1 = Math.fmin( fb.y1(), lb.y1()) - 20;
        x2 = fb.x2();  y2 = y1;
        break;
      case NodeSide.BOTTOM :
        x1 = fb.x1();  y1 = Math.fmax( fb.y2(), lb.y2() ) + 20;
        x2 = lb.x2();  y2 = y1;
        break;
    }

    Utils.set_context_color_with_alpha( ctx, link_color, ((parent.alpha != 1.0) ? parent.alpha : alpha) );
    ctx.set_line_cap( LineCap.ROUND );
    ctx.set_line_width( parent.style.link_width );
    ctx.move_to( x1, y1 );
    ctx.line_to( x2, y2 );
    ctx.stroke();

  }

}
