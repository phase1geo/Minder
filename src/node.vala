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
using GLib;
using Gdk;
using Cairo;

public enum NodeMode {
  NONE = 0,
  SELECTED,
  EDITABLE,
  EDITED
}

public struct NodeBounds {
  double x;
  double y;
  double width;
  double height;
}

public class Node : Object {

  /* Member variables */
  protected double       _width       = 0;
  protected double       _height      = 0;
  protected double       _padx        = 0;
  protected double       _pady        = 0;
  protected double       _ipadx       = 0;
  protected double       _ipady       = 0;
  protected double       _task_radius = 5;
  protected double       _alpha       = 0.3;
  private   int          _cursor      = 0;   /* Location of the cursor when editing */
  protected Array<Node>  _children;
  private   string       _prevname    = "~";
  private   Pango.Layout _layout      = null;
  private   int          _task_count  = 0;
  private   int          _task_done   = 0;
  private   Pango.FontDescription _font_description = null;

  /* Properties */
  public string   name   { get; set; default = ""; }
  public double   posx   { get; set; default = 50.0; }
  public double   posy   { get; set; default = 50.0; }
  public string   note   { get; set; default = ""; }
  public NodeMode mode   { get; set; default = NodeMode.NONE; }
  public Node     parent { get; protected set; default = null; }
  public int      side   { get; set; default = 1; }
  public bool     folded { get; set; default = false; }

  /* Default constructor */
  public Node( Layout? layout ) {
    _children = new Array<Node>();
    set_layout( layout );
  }

  /* Constructor initializing string */
  public Node.with_name( string n, Layout? layout ) {
    name      = n;
    _children = new Array<Node>();
    set_layout( layout );
  }

  /* Returns true if the node does not have a parent */
  public bool is_root() {
    return( parent == null );
  }

  /*
   Returns true if this node is a "main branch" which is a node attached
   directly to the parent.
  */
  public bool main_branch() {
    return( (parent != null) && (parent.parent == null) );
  }

  /* Returns true if the node is a leaf node */
  public bool is_leaf() {
    return( (parent != null) && (_children.length == 0) );
  }

  /* Returns true if the given cursor coordinates lies within this node */
  public virtual bool is_within( double x, double y ) {
    double cx, cy, cw, ch;
    bbox( out cx, out cy, out cw, out ch );
    return( (cx < x) && (x < (cx + cw)) && (cy < y) && (y < (cy + ch)) );
  }

  /*
   Returns true if the given cursor coordinates lies within the task checkbutton
   area
  */
  public virtual bool is_within_task( double x, double y ) {
    if( _task_count > 0 ) {
      double tx, ty, tw, th;
      tx = posx + _padx;
      ty = posy + _pady + ((_height / 2) - _task_radius);
      tw = _task_radius * 2;
      th = _task_radius * 2;
      return( (tx < x) && (x < (tx + tw)) && (ty < y) && (y < (ty + th)) );
    } else {
      return( false );
    }
  }

  /* Returns true if the given cursor coordinates lies within the fold indicator area */
  public virtual bool is_within_fold( double x, double y ) {
    if( folded && (_children.length > 0) ) {
      double fx, fy, fw, fh;
      fold_bbox( out fx, out fy, out fw, out fh );
      return( (fx < x) && (x < (fx + fw)) && (fy < y) && (y < (fy + fh)) );
    } else {
      return( false );
    }
  }

  /* Finds the node which contains the given pixel coordinates */
  public virtual Node? contains( double x, double y ) {
    if( is_within( x, y ) || is_within_fold( x, y ) ) {
      return( this );
    } else {
      for( int i=0; i<_children.length; i++ ) {
        Node tmp = _children.index( i ).contains( x, y );
        if( tmp != null ) {
          return( tmp );
        }
      }
      return( null );
    }
  }

  /* Returns true if this node contains the given node */
  public virtual bool contains_node( Node node ) {
    if( node == this ) {
      return( true );
    } else {
      for( int i=0; i<_children.length; i++ ) {
        if( _children.index( i ).contains_node( node ) ) {
          return( true );
        }
      }
      return( false );
    }
  }

  /* Returns the children nodes of this node */
  public Array<Node> children() {
    return( _children );
  }

  /* Returns the child index of this node within its parent */
  public virtual int index() {
    for( int i=0; i<parent.children().length; i++ ) {
      if( parent.children().index( i ) == this ) {
        return i;
      }
    }
    return( -1 );
  }

  /* Returns the number of child nodes that match the given side value */
  public virtual int side_count( int side ) {
    int count = 0;
    for( int i=0; i<children().length; i++ ) {
      if( _children.index( i ).side == side ) {
        count++;
      }
    }
    return( count );
  }

  /* Loads the name value from the given XML node */
  private void load_name( Xml.Node* n ) {
    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      name = n->children->get_content();
    }
  }

  /* Loads the note value from the given XML node */
  private void load_note( Xml.Node* n ) {
    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      note = n->children->get_content();
    }
  }

  /* Loads the file contents into this instance */
  public virtual void load( Xml.Node* n, Layout? layout ) {

    string? x = n->get_prop( "posx" );
    if( x != null ) {
      posx = double.parse( x );
    }

    string? y = n->get_prop( "posy" );
    if( y != null ) {
      posy = double.parse( y );
    }

    string? w = n->get_prop( "width" );
    if( w != null ) {
      _width = double.parse( w );
    }

    string? h = n->get_prop( "height" );
    if( h != null ) {
      _height = double.parse( h );
    }

    string? tc = n->get_prop( "task" );
    if( tc != null ) {
      _task_count = 1;
      _task_done  = int.parse( tc );
    }

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "nodename" :  load_name( it );  break;
          case "nodenote" :  load_note( it );  break;
          case "nodes"    :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                NonrootNode child = new NonrootNode( layout );
                child.load( it2, layout );
                child.attach( this, -1, null );
              }
            }
            break;
        }
      }
    }

  }

  /* Saves the current node */
  public virtual void save( Xml.Node* parent ) {
    parent->add_child( save_node() );
  }

  /* Saves the node contents to the given data output stream */
  protected Xml.Node* save_node() {

    double width  = _width  - (_padx * 2);
    double height = _height - (_pady * 2);

    Xml.Node* node = new Xml.Node( null, "node" );
    node->new_prop( "posx", posx.to_string() );
    node->new_prop( "posy", posy.to_string() );
    node->new_prop( "width", width.to_string() );
    node->new_prop( "height", height.to_string() );
    if( (_task_count > 0) && is_leaf() ) {
      node->new_prop( "task", _task_done.to_string() );
    }

    node->new_text_child( null, "nodename", name );
    node->new_text_child( null, "nodenote", note );

    if( _children.length > 0 ) {
      Xml.Node* nodes = new Xml.Node( null, "nodes" );
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).save( nodes );
      }
      node->add_child( nodes );
    }

    return( node );

  }

  /*
   Updates the width and height based on the current name.  Returns true
   if the width or height has changed since the last time these values were
   updated.
  */
  public void update_size( out double width_diff, out double height_diff ) {
    width_diff  = 0;
    height_diff = 0;
    if( (name != _prevname) && (_layout != null) ) {
      int width, height;
      _layout.set_text( name, -1 );
      _layout.get_size( out width, out height );
      if( side == 0 ) {
        posx = (posx + _width) - (width / Pango.SCALE);
      }
      width_diff  = (width  / Pango.SCALE) - _width;
      height_diff = (height / Pango.SCALE) - _height;
      _width      = (width  / Pango.SCALE);
      _height     = (height / Pango.SCALE);
      _prevname   = name;
    }
  }

  /* Returns the bounding box for this node */
  public virtual void bbox( out double x, out double y, out double w, out double h ) {
    double width_diff, height_diff;
    update_size( out width_diff, out height_diff );
    x = posx;
    y = posy;
    w = _width  + (_padx * 2) + ((_task_count > 0) ? (_ipadx + (_task_radius * 2)) : 0);
    h = _height + (_pady * 2);
  }

  /* Returns the bounding box for the fold indicator for this node */
  private void fold_bbox( out double x, out double y, out double w, out double h ) {
    bbox( out x, out y, out w, out h );
    x = x + w + _padx;
    y = y + (h / 2) - 5;
    w = 15;
    h = 10;
  }

  /* Returns the amount of internal width to draw the task checkbutton */
  protected double task_width() {
    return( (_task_count > 0) ? ((_task_radius * 2) + _ipadx) : 0 );
  }

  /* Returns the width of the note indicator */
  protected double note_width() {
    return( (note.length > 0) ? (10 + _ipadx) : 0 );
  }

  /* Moves this node into the proper position within the parent node */
  public void move_to_position( Node child, double x, double y, Layout layout ) {
    int side = child.side;
    child.detach( layout );
    for( int i=0; i<_children.length; i++ ) {
      if( side == _children.index( i ).side ) {
        /*
         TBD - This comparison needs to be run through layout as we may be
         comparing either X or Y
        */
        if( y < _children.index( i ).posy ) {
          child.attach( this, i, layout );
          return;
        }
      }
    }
    child.attach( this, -1, layout );
  }

  /* Move the cursor in the given direction */
  public void move_cursor( int dir ) {
    _cursor += dir;
    if( _cursor < 0 ) {
      _cursor = 0;
    } else if( _cursor > name.length ) {
      _cursor = name.length;
    }
    mode = NodeMode.EDITED;
  }

  /* Moves the cursor to the beginning of the name */
  public void move_cursor_to_start() {
    _cursor = 0;
    mode = NodeMode.EDITED;
  }

  /* Moves the cursor to the end of the name */
  public void move_cursor_to_end() {
    _cursor = name.length;
    mode = NodeMode.EDITED;
  }

  /* Handles a backspace key event */
  public void edit_backspace( Layout layout ) {
    if( _cursor > 0 ) {
      if( mode == NodeMode.EDITABLE ) {
        name    = "";
        _cursor = 0;
      } else {
        name = name.splice( (_cursor - 1), _cursor );
        _cursor--;
      }
    }
    mode = NodeMode.EDITED;
    layout.handle_update_by_edit( this );
  }

  /* Handles a delete key event */
  public void edit_delete( Layout layout ) {
    if( _cursor < name.length ) {
      name = name.splice( _cursor, (_cursor + 1) );
    } else if( mode == NodeMode.EDITABLE ) {
      name    = "";
      _cursor = 0;
    }
    mode = NodeMode.EDITED;
    layout.handle_update_by_edit( this );
  }

  /* Inserts the given string at the current cursor position and adjusts cursor */
  public void edit_insert( string s, Layout layout ) {
    if( mode == NodeMode.EDITABLE ) {
      name    = s;
      _cursor = 1;
    } else {
      name = name.splice( _cursor, _cursor, s );
      _cursor += s.length;
    }
    mode = NodeMode.EDITED;
    layout.handle_update_by_edit( this );
  }

  /* Detaches this node from its parent node */
  public virtual void detach( Layout? layout ) {
    if( parent != null ) {
      double x, y, w, h;
      int    idx = index();
      Node   p   = parent;
      layout.bbox( this, -1, side, out x, out y, out w, out h );
      propagate_task_info( (0 - _task_count), (0 - _task_done) );
      parent.children().remove_index( index() );
      if( layout != null ) {
        layout.handle_update_by_delete( p, idx, side, w, h );
      }
      parent = null;
    }
  }

  /* Removes this node from the node tree along with all descendents */
  public virtual void delete( Layout layout ) {
    _children.remove_range( 0, _children.length );
    detach( layout );
  }

  /* Attaches this node as a child of the given node */
  public virtual void attach( Node parent, int index, Layout? layout ) {
    this.parent = parent;
    if( (parent._children.length == 0) && (parent._task_count == 1) ) {
      parent.propagate_task_info( (0 - parent._task_count), (0 - parent._task_done) );
      parent._task_count = 0;
      parent._task_done  = 0;
    }
    if( index == -1 ) {
      index = (int)this.parent.children().length;
      parent.children().append_val( this );
    } else {
      parent.children().insert_val( index, this );
    }
    propagate_task_info( _task_count, _task_done );
    if( layout != null ) {
      layout.handle_update_by_insert( parent, this, index );
    }
  }

  /* Returns a reference to the first child of this node */
  public virtual Node? first_child() {
    if( _children.length > 0 ) {
      return( _children.index( 0 ) );
    }
    return( null );
  }

  /* Returns a reference to the last child of this node */
  public virtual Node? last_child() {
    if( _children.length > 0 ) {
      return( _children.index( _children.length - 1 ) );
    }
    return( null );
  }

  /* Returns a reference to the next child after the specified child of this node */
  public virtual Node? next_child( Node n ) {
    int idx = n.index();
    if( (idx != -1) && ((idx + 1) < _children.length) ) {
      return( _children.index( idx + 1 ) );
    }
    return( null );
  }

  /* Returns a reference to the next child after the specified child of this node */
  public virtual Node? prev_child( Node n ) {
    int idx = n.index();
    if( (idx != -1) && (idx > 0) ) {
      return( _children.index( idx - 1 ) );
    }
    return( null );
  }

  /* Propagates a change in the task_done for this node to all parent nodes */
  private void propagate_task_info( int count_adjust, int done_adjust ) {
    Node p = parent;
    while( p != null ) {
      p._task_count += count_adjust;
      p._task_done  += done_adjust;
      p = p.parent;
    }
  }

  /* Returns true if this node's task indicator is currently enabled */
  public bool task_enabled() {
    return( is_leaf() && (_task_count == 1) );
  }

  /* Returns true if this node's task indicator indicates that it is currently done */
  public bool task_done() {
    return( is_leaf() && (_task_done == 1) );
  }

  /* Sets the task enable to the given value */
  public void enable_task( bool task ) {
    if( task ) {
      _task_count = 1;
      propagate_task_info( 1, 0 );
    } else {
      _task_count = 0;
      propagate_task_info( -1, ((_task_done > 0) ? -1 : 0) );
    }
    _task_done = 0;
  }

  /*
   Sets the task done indicator to the given value (0 or 1) and propagates the
   change to all parent nodes.
  */
  public void set_task_done( int done ) {
    if( _task_done != done ) {
      _task_done = done;
      propagate_task_info( 0, (done > 0) ? 1 : -1 );
    }
  }

  /*
   Toggles the current value of task done and propagates the change to all
   parent nodes.
  */
  public void toggle_task_done() {
    set_task_done( (_task_done > 0) ? 0 : 1 );
  }

  /* Adjusts the posx and posy values */
  public virtual void pan( double origin_x, double origin_y ) {
    posx -= origin_x;
    posy -= origin_y;
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).pan( origin_x, origin_y );
    }
  }

  /* Sets the context source color to the given color value */
  protected void set_context_color( Context ctx, RGBA color ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
  }

  /*
   Sets the context source color to the given color value overriding the
   alpha value with the given value.
  */
  protected void set_context_color_with_alpha( Context ctx, RGBA color, double alpha ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, alpha );
  }

  /* Returns the link point for this node */
  protected virtual void link_point( out double x, out double y ) {
    if( side == 0 ) {
      x = posx;
      y = posy;
    } else {
      x = posx + _width;
      y = posy;
    }
  }

  /* Draws the node font to the screen */
  public virtual void draw_name( Cairo.Context ctx, Theme theme ) {

    int    hmargin = 3;
    int    vmargin = 3;
    double width_diff, height_diff;

    /* Make sure the the size is up-to-date */
    update_size( out width_diff, out height_diff );

    double twidth = task_width();

    /* Draw the selection box around the text if the node is in the 'selected' state */
    if( (mode == NodeMode.SELECTED) || (mode == NodeMode.EDITABLE) ) {
      if( mode == NodeMode.SELECTED ) {
        set_context_color( ctx, theme.nodesel_background );
      } else {
        set_context_color( ctx, theme.textsel_background );
      }
      ctx.rectangle( ((posx + _padx + twidth) - hmargin), ((posy + _pady) - vmargin), (_width + (hmargin * 2)), (_height + (vmargin * 2)) );
      ctx.fill();
    }

    /* Output the text */
    ctx.move_to( (posx + _padx + twidth), (posy + _pady) );
    switch( mode ) {
      case NodeMode.SELECTED :  set_context_color( ctx, theme.nodesel_foreground );  break;
      case NodeMode.EDITABLE :  set_context_color( ctx, theme.textsel_foreground );  break;
      default                :  set_context_color( ctx, (parent == null) ? theme.root_foreground : theme.foreground );  break;
    }
    Pango.cairo_show_layout( ctx, _layout );

    /* Draw the insertion cursor if we are in the 'editable' state */
    if( (mode == NodeMode.EDITABLE) || (mode == NodeMode.EDITED) ) {
      var rect = _layout.index_to_pos( _cursor );
      set_context_color( ctx, theme.text_cursor );
      double ix, iy;
      ix = (posx + _padx + twidth) + (rect.x / Pango.SCALE) - 1;
      iy = (posy + _pady) + (rect.y / Pango.SCALE);
      ctx.rectangle( ix, iy, 1, (rect.height / Pango.SCALE) );
      ctx.fill();
    }

  }

  protected virtual void draw_leaf_task( Context ctx, RGBA color ) {

    if( _task_count > 0 ) {

      double x = posx + _padx + _task_radius;
      double y = posy + _pady + (_height / 2);

      set_context_color( ctx, color );
      ctx.new_path();
      ctx.set_line_width( 1 );
      ctx.arc( x, y, _task_radius, 0, (2 * Math.PI) );

      if( _task_done == 0 ) {
        ctx.stroke();
      } else {
        ctx.fill();
      }

    }

  }

  /* Draws the task checkbutton */
  protected virtual void draw_acc_task( Context ctx, RGBA color ) {

    if( _task_count > 0 ) {

      double x        = posx + _padx + _task_radius;
      double y        = posy + _pady + (_height / 2);
      double complete = _task_done / (_task_count * 1.0);
      double angle    = ((complete * 360) + 270) * (Math.PI / 180.0);

      /* Draw circle outline */
      if( complete < 1 ) {
        set_context_color_with_alpha( ctx, color, _alpha );
        ctx.new_path();
        ctx.set_line_width( 1 );
        ctx.arc( x, y, _task_radius, 0, (2 * Math.PI) );
        ctx.stroke();
      }

      /* Draw completeness pie */
      if( _task_done > 0 ) {
        set_context_color( ctx, color );
        ctx.new_path();
        ctx.set_line_width( 1 );
        ctx.arc( x, y, _task_radius, (1.5 * Math.PI), angle );
        ctx.line_to( x, y );
        ctx.arc( x, y, _task_radius, (1.5 * Math.PI), (1.5 * Math.PI) );
        ctx.line_to( x, y );
        ctx.fill();
      }

    }

  }

  /* Draws the icon indicating that a note is associated with this node */
  protected virtual void draw_common_note( Context ctx, RGBA color ) {

    if( note.length > 0 ) {

      double x = posx + _padx + task_width() + _width + _ipadx;
      double y = posy + _pady + (_height / 2) - 5;

      set_context_color_with_alpha( ctx, color, _alpha );
      ctx.new_path();
      ctx.set_line_width( 1 );
      ctx.move_to( (x + 2), y );
      ctx.line_to( (x + 10), y );
      ctx.stroke();
      ctx.move_to( x, (y + 3) );
      ctx.line_to( (x + 10), (y + 3) );
      ctx.stroke();
      ctx.move_to( x, (y + 6) );
      ctx.line_to( (x + 10), (y + 6) );
      ctx.stroke();
      ctx.move_to( x, (y + 9) );
      ctx.line_to( (x + 10), (y + 9) );
      ctx.stroke();

    }

  }

  /* Draw the fold indicator */
  public virtual void draw_common_fold( Context ctx, RGBA bg_color, RGBA fg_color ) {

    if( folded && (_children.length > 0) ) {

      double fx, fy, fw, fh;

      fold_bbox( out fx, out fy, out fw, out fh );

      /* Draw the fold rectangle */
      set_context_color( ctx, bg_color );
      ctx.new_path();
      ctx.set_line_width( 1 );
      ctx.rectangle( fx, fy, fw, fh );
      ctx.fill();

      /* Draw circles */
      set_context_color( ctx, fg_color );
      ctx.new_path();
      ctx.arc( (fx + 5), (fy + 5), 1, 0, (2 * Math.PI) );
      ctx.fill();
      ctx.new_path();
      ctx.arc( (fx + 10), (fy + 5), 1, 0, (2 * Math.PI) );
      ctx.fill();

    }

  }

  /* Draws the node on the screen */
  public virtual void draw( Context ctx, Theme theme ) {}

  /* Draw this node and all child nodes */
  public void draw_all( Context ctx, Theme theme ) {
    if( _layout == null ) {
      _layout = Pango.cairo_create_layout( ctx );
      _layout.set_font_description( _font_description );
      _layout.set_width( 200 * Pango.SCALE );
      _layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    }
    if( !folded ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).draw_all( ctx, theme );
      }
    }
    draw( ctx, theme );
  }

  /* Called whenever the user changes the layout */
  public void set_layout( Layout? layout ) {
    if( layout == null ) return;
    _padx             = layout.padx;
    _pady             = layout.pady;
    _ipadx            = layout.ipadx;
    _ipady            = layout.ipady;
    _font_description = layout.get_font_description();
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).set_layout( layout );
    }
  }

}
