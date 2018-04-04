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

using Gdk;
using Cairo;

public class NonrootNode : Node {

  public int color_index { set; get; default = 0; }

  /* Default constructor */
  public NonrootNode( Layout? layout ) {
    base( layout );
  }

  /* Forces all children nodes to use the same color index as the parent node. */
  private void propagate_color() {
    color_index = (parent as NonrootNode).color_index;
    for( int i=0; i<_children.length; i++ ) {
      NonrootNode n = (_children.index( i ) as NonrootNode);
      n.propagate_color();
    }
  }

  /*
   Performs a child attachment to a parent node, assumes the color
   index of the parent
  */
  public override void attach( Node parent, int index, Layout? layout ) {
    base.attach( parent, index, layout );
    if( !parent.is_root() ) {
      propagate_color();
    }
  }

  /* Loads the data from the input stream */
  public override void load( Xml.Node* n, Layout? layout ) {

    /* Allow the base class to parse the node */
    base.load( n, layout );

    /* Load the color value */
    string? c = n->get_prop( "color" );
    if( c != null ) {
      color_index = int.parse( c );
    }

  }

  /* Saves the current node */
  public override void save( Xml.Node* parent ) {
    Xml.Node* node = save_node();
    node->new_prop( "color", color_index.to_string() );
    parent->add_child( node );
  }

  /* Provides the point to link to children nodes */
  protected override void link_point( out double x, out double y ) {
    switch( side ) {
      case NodeSide.LEFT :
        x = posx;
        y = posy + _height + (_pady * 2);
        break;
      case NodeSide.RIGHT :
        x = posx + _width  + (_padx * 2);
        y = posy + _height + (_pady * 2);
        break;
      case NodeSide.TOP :
        x = posx + (_width / 2) + _padx;
        y = posy;
        break;
      default :
        x = posx + (_width / 2) + _padx;
        y = posy + _height + (_pady * 2);
        break;
    }
  }

  /* Draws the line under the node name */
  public void draw_line( Context ctx, Theme theme ) {

    double posx  = this.posx;
    double posy  = this.posy + _height + (_pady * 2);
    double w     = _width + (_padx * 2) + task_width() + note_width();
    RGBA   color = theme.link_color( color_index );

    /* Draw the line under the text name */
    set_context_color( ctx, color );
    ctx.set_line_width( 4 );
    ctx.set_line_cap( LineCap.ROUND );
    ctx.move_to( posx, posy );
    ctx.line_to( (posx + w), posy );
    ctx.stroke();

  }

  /* Draw the link from this node to the parent node */
  public void draw_link( Context ctx, Theme theme ) {

    double parent_x;
    double parent_y;
    RGBA   color = theme.link_color( color_index );

    /* Get the parent's link point */
    parent.link_point( out parent_x, out parent_y );

    set_context_color( ctx, color );
    ctx.set_line_width( 4 );
    ctx.set_line_cap( LineCap.ROUND );
    ctx.move_to( parent_x, parent_y );
    switch( side ) {
      case NodeSide.LEFT :
        ctx.line_to( (posx + _width + task_width() + (_padx * 2)), (posy + _height + (_pady * 2)) );
        break;
      case NodeSide.RIGHT :
        ctx.line_to( posx, (posy + _height + (_pady * 2)) );
        break;
      case NodeSide.TOP :
        ctx.line_to( (posx + (_width / 2) + (task_width() / 2) + _padx), posy );
        break;
      case NodeSide.BOTTOM :
        ctx.line_to( (posx + (_width / 2) + (task_width() / 2) + _padx), (posy + _height + (_pady * 2)) );
        break;
    }
    ctx.stroke();

  }

  /* Draws the task checkbutton */
  public void draw_task( Context ctx, Theme theme ) {
    if( _children.length == 0 ) {
      draw_leaf_task( ctx, theme.link_color( color_index ) );
    } else {
      draw_acc_task( ctx, theme.link_color( color_index ) );
    }
  }

  /* Draws the note icon, if necessary */
  public void draw_note( Context ctx, Theme theme ) {
    draw_common_note( ctx, theme.foreground );
  }

  /* Draws the fold indicator, if necessary */
  public void draw_fold( Context ctx, Theme theme ) {
    draw_common_fold( ctx, theme.link_color( color_index ), theme.foreground );
  }

  /* Draws this node */
  public override void draw( Context ctx, Theme theme ) {
    draw_name( ctx, theme );
    draw_task( ctx, theme );
    draw_note( ctx, theme );
    draw_line( ctx, theme );
    draw_link( ctx, theme );
    draw_fold( ctx, theme );
  }

}
