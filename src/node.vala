using Gtk;
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
  protected double _width = 0;
  protected double _height = 0;
  private   int    _cursor = 0;   /* Location of the cursor when editing */
  private   Node[] _children;

  /* Properties */
  public string   name     { get; set; default = ""; }
  public double   posx     { get; set; default = 50.0; }
  public double   posy     { get; set; default = 50.0; }
  public string   note     { get; set; default = ""; }
  public double   task     { get; set; default = -1.0; }
  public NodeMode mode     { get; set; default = NodeMode.NONE; }
  public Node     parent   { get; protected set; default = null; }

  /* Default constructor */
  public Node() {}

  /* Constructor initializing string */
  public Node.with_name( string n ) {
    name = n;
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
    return( (x >= posx) && (x < (posx + _width)) && (y >= (posy - _height)) && (y < posy) );
  }

  /* Finds the node which contains the given pixel coordinates */
  public virtual Node? contains( double x, double y ) {
    if( is_within( x, y ) ) {
      return( this );
    } else {
      foreach (Node n in _children) {
        Node tmp = n.contains( x, y );
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
      foreach (Node n in _children) {
        if( n.contains_node( node ) ) {
          return( true );
        }
      }
      return( false );
    }
  }

  /* Returns the children nodes of this node */
  public Node[] children() {
    return( _children );
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
                child.attach( this );
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

    Xml.Node* node = new Xml.Node( null, "node" );
    node->new_prop( "posx", posx.to_string() );
    node->new_prop( "posy", posy.to_string() );
    node->new_prop( "width", _width.to_string() );
    node->new_prop( "height", _height.to_string() );
    if( task >= 0 ) {
      node->new_prop( "task", task.to_string() );
    }

    node->new_text_child( null, "nodename", name );
    node->new_text_child( null, "nodenote", note );

    if( _children.length > 0 ) {
      Xml.Node* nodes = new Xml.Node( null, "nodes" );
      foreach (Node n in _children) {
        n.save( nodes );
      }
      node->add_child( nodes );
    }

    return( node );

  }

  /* Returns the bounding box for this node */
  public virtual void bbox( out double x, out double y, out double w, out double h ) {
    x = posx;
    y = posy;
    w = _width;
    h = _height;
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
  public void edit_backspace() {
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
  }

  /* Handles a delete key event */
  public void edit_delete() {
    if( _cursor < name.length ) {
      name = name.splice( _cursor, (_cursor + 1) );
    } else if( mode == NodeMode.EDITABLE ) {
      name    = "";
      _cursor = 0;
    }
    mode = NodeMode.EDITED;
  }

  /* Inserts the given string at the current cursor position and adjusts cursor */
  public void edit_insert( string s ) {
    if( mode == NodeMode.EDITABLE ) {
      name    = s;
      _cursor = 1;
    } else {
      name = name.splice( _cursor, _cursor, s );
      _cursor += s.length;
    }
    mode = NodeMode.EDITED;
  }

  /* Detaches this node from its parent node */
  public virtual void detach() {
    if( parent != null ) {
      Node[] tmp = {};
      foreach (Node n in parent._children) {
        if( n != this ) {
          tmp += n;
        }
      }
      parent._children = tmp;
      parent = null;
    }
  }

  /* Removes this node from the node tree along with all descendents */
  public virtual void delete() {
    detach();
    _children = {};
  }

  /* Attaches this node as a child of the given node */
  public virtual void attach( Node parent ) {
    this.parent = parent;
    this.parent._children += this;
  }

  /* Returns a reference to the first child of this node */
  public virtual Node? first_child() {
    if( _children.length > 0 ) {
      return( _children[0] );
    }
    return( null );
  }

  /* Returns a reference to the last child of this node */
  public virtual Node? last_child() {
    if( _children.length > 0 ) {
      return( _children[_children.length-1] );
    }
    return( null );
  }

  /* Returns a reference to the next child after the specified child of this node */
  public virtual Node? next_child( Node n ) {
    int i = 0;
    foreach (Node c in _children) {
      if( c == n ) {
        if( (i + 1) < _children.length ) {
          return( _children[i+1] );
        } else {
          return( null );
        }
      }
      i++;
    }
    return( null );
  }

  /* Returns a reference to the next child after the specified child of this node */
  public virtual Node? prev_child( Node n ) {
    int i = 0;
    foreach (Node c in _children) {
      if( c == n ) {
        if( i > 0 ) {
          return( _children[i-1] );
        } else {
          return( null );
        }
      }
      i++;
    }
    return( null );
  }

  /* Calculates the boundaries of the given string */
  private void text_extents( Context ctx, string s, out TextExtents extents ) {
    if( s == "" ) {
      ctx.text_extents( "I", out extents );
      extents.width = 0;
    } else {
      string txt     = s;
      string chomped = s.chomp();
      int    diff    = txt.length - chomped.length;
      if( diff > 0 ) {
        txt = chomped + "i".ndup( diff );
      }
      ctx.text_extents( txt, out extents );
    }
  }

  /* Returns the extents of the given node name */
  protected void name_extents( Context ctx, out TextExtents extents ) {
    ctx.set_font_size( 14 );
    text_extents( ctx, name, out extents );
  }

  /* Adjusts the posx and posy values */
  public virtual void pan( double origin_x, double origin_y ) {
    posx -= origin_x;
    posy -= origin_y;
    foreach (Node n in _children) {
      n.pan( origin_x, origin_y );
    }
  }

  /* Sets the context source color to the given color value */
  protected void set_context_color( Context ctx, RGBA color ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
  }

  public static void output_context_color( RGBA color ) {
    stdout.printf( "red: %g, green: %g, blue: %g, alpha: %g\n", color.red, color.green, color.blue, color.alpha );
  }

  /* Returns the link point for this node */
  protected virtual void link_point( out double x, out double y ) {
    x = posx;
    y = posy;
  }

  /* Draws the node font to the screen */
  public virtual void draw_name( Context ctx, Theme theme, Layout layout ) {

    TextExtents name_extents;
    double      hmargin = 3;
    double      vmargin = 5;

    ctx.set_font_size( 14 );
    text_extents( ctx, name, out name_extents );

    _width  = name_extents.width;
    _height = name_extents.height;

    /* Draw the selection box around the text if the node is in the 'selected' state */
    if( (mode == NodeMode.SELECTED) || (mode == NodeMode.EDITABLE) ) {
      if( mode == NodeMode.SELECTED ) {
        set_context_color( ctx, theme.nodesel_background );
      } else {
        set_context_color( ctx, theme.textsel_background );
      }
      ctx.rectangle( (posx - hmargin), ((posy - vmargin) - name_extents.height), (name_extents.width + (hmargin * 2)), (name_extents.height + (vmargin * 2)) );
      ctx.fill();
    }

    /* Output the text */
    ctx.move_to( posx, posy );
    switch( mode ) {
      case NodeMode.SELECTED :  set_context_color( ctx, theme.nodesel_foreground );  break;
      case NodeMode.EDITABLE :  set_context_color( ctx, theme.textsel_foreground );  break;
      default                :  set_context_color( ctx, theme.foreground );          break;
    }
    ctx.show_text( name );

    /* Draw the insertion cursor if we are in the 'editable' state */
    if( (mode == NodeMode.EDITABLE) || (mode == NodeMode.EDITED) ) {
      TextExtents extents;
      text_extents( ctx, name.substring( 0, _cursor ), out extents );
      set_context_color( ctx, theme.text_cursor );
      ctx.rectangle( (posx + 1 + extents.width), ((posy - vmargin) - name_extents.height), 1, (name_extents.height + (vmargin * 2)) );
      ctx.fill();
    }

  }

  /* Draws the node on the screen */
  public virtual void draw( Context ctx, Theme theme, Layout layout ) {}

  /* Draw this node and all child nodes */
  public void draw_all( Context ctx, Theme theme, Layout layout ) {
    stdout.printf( "In draw_all\n" );
    draw( ctx, theme, layout );
    stdout.printf( "Calling draw\n" );
    foreach (Node n in _children) {
      n.draw_all( ctx, theme, layout );
    }
  }

}
