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
  protected double       _width    = 0;
  protected double       _height   = 0;
  protected double       _padx     = 0;
  protected double       _pady     = 0;
  private   int          _cursor   = 0;   /* Location of the cursor when editing */
  protected Array<Node>  _children;
  private   string       _prevname = "~";
  private   Pango.Layout _layout   = null;

  /* Properties */
  public string   name     { get; set; default = ""; }
  public double   posx     { get; set; default = 50.0; }
  public double   posy     { get; set; default = 50.0; }
  public string   note     { get; set; default = ""; }
  public double   task     { get; set; default = -1.0; }
  public NodeMode mode     { get; set; default = NodeMode.NONE; }
  public Node     parent   { get; protected set; default = null; }
  public int      side     { get; set; default = 1; }

  /* Default constructor */
  public Node() {
    _children = new Array<Node>();
  }

  /* Constructor initializing string */
  public Node.with_name( string n ) {
    name = n;
    _children = new Array<Node>();
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

  /* Finds the node which contains the given pixel coordinates */
  public virtual Node? contains( double x, double y ) {
    if( is_within( x, y ) ) {
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
  public virtual void load( Xml.Node* n ) {

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

    string? t = n->get_prop( "task" );
    if( t != null ) {
      task = double.parse( t );
    }

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "nodename" :  load_name( it );  break;
          case "nodenote" :  load_note( it );  break;
          case "nodes"    :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                NonrootNode child = new NonrootNode();
                child.load( it2 );
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
    if( task >= 0 ) {
      node->new_prop( "task", task.to_string() );
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
    w = _width  + (_padx * 2);
    h = _height + (_pady * 2);
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
    if( index == -1 ) {
      index = (int)this.parent.children().length;
      parent.children().append_val( this );
    } else {
      parent.children().insert_val( index, this );
    }
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
  public virtual void draw_name( Cairo.Context ctx, Theme theme, Layout layout ) {

    int    hmargin = 3;
    int    vmargin = 3;
    double width_diff, height_diff;

    /* Make sure the the size is up-to-date */
    update_size( out width_diff, out height_diff );

    _padx = layout.padx;
    _pady = layout.pady;

    /* Draw the selection box around the text if the node is in the 'selected' state */
    if( (mode == NodeMode.SELECTED) || (mode == NodeMode.EDITABLE) ) {
      if( mode == NodeMode.SELECTED ) {
        set_context_color( ctx, theme.nodesel_background );
      } else {
        set_context_color( ctx, theme.textsel_background );
      }
      ctx.rectangle( ((posx + _padx) - hmargin), ((posy + _pady) - vmargin), (_width + (hmargin * 2)), (_height + (vmargin * 2)) );
      ctx.fill();
    }

    /* Output the text */
    ctx.move_to( (posx + _padx), (posy + _pady) );
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
      ix = (posx + _padx) + (rect.x / Pango.SCALE) - 1;
      iy = (posy + _pady) + (rect.y / Pango.SCALE);
      ctx.rectangle( ix, iy, 1, (rect.height / Pango.SCALE) );
      ctx.fill();
    }

  }

  /* Draws the node on the screen */
  public virtual void draw( Context ctx, Theme theme, Layout layout ) {}

  /* Draw this node and all child nodes */
  public void draw_all( Context ctx, Theme theme, Layout layout ) {
    if( _layout == null ) {
      _layout = Pango.cairo_create_layout( ctx );
      _layout.set_font_description( layout.get_font_description() );
      _layout.set_width( 200 * Pango.SCALE );
      _layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).draw_all( ctx, theme, layout );
    }
    draw( ctx, theme, layout );
  }

}
