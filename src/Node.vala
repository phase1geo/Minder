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

/* Enumeration describing the different modes a node can be in */
public enum NodeMode {
  NONE = 0,   // Specifies that this node is not the current node
  CURRENT,    // Specifies that this node is the current node and is not being edited
  EDITABLE,   // Specifies that this node's text has been and currently is actively being edited
  ATTACHABLE  // Specifies that this node is the currently attachable node (affects display)
}

public enum NodeSide {
  LEFT   = 1,  // Specifies that this node is to the left of the root node
  TOP    = 2,  // Specifies that this node is above the root node
  RIGHT  = 4,  // Specifies that this node is to the right of the root node
  BOTTOM = 8;  // Specifies that this node is below the root node

  /* Displays the string value of this NodeSide */
  public string to_string() {
    switch( this ) {
      case LEFT   :  return( "left" );
      case TOP    :  return( "top" );
      case RIGHT  :  return( "right" );
      case BOTTOM :  return( "bottom" );
      default     :  assert_not_reached();
    }
  }

  /* Translates a string from to_string() to a NodeSide value */
  public static NodeSide parse( string val ) {
    switch( val ) {
      case "left"   :  return( LEFT );
      case "top"    :  return( TOP );
      case "right"  :  return( RIGHT );
      case "bottom" :  return( BOTTOM );
      default       :  assert_not_reached();
    }
  }

  /* Generates the value of the ANY mask value */
  public static int any() {
    return( LEFT + RIGHT + TOP + BOTTOM );
  }

  /* Generates the value of the VERTICAL mask value */
  public static int vertical() {
    return( TOP + BOTTOM );
  }

  /* Generates the value of the HORIZONTAL mask value */
  public static int horizontal() {
    return( LEFT + RIGHT );
  }
}

public struct NodeBounds {
  double x;
  double y;
  double width;
  double height;
}

public class Node : Object {

  private static int _next_id = 0;

  /* Member variables */
  protected int          _id;
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
  private   NodeMode     _mode        = NodeMode.NONE;
  private   int          _task_count  = 0;
  private   int          _task_done   = 0;
  private   bool         _folded      = false;
  private   Pango.Layout _layout      = null;
  private   double       _posx        = 0;
  private   double       _posy        = 0;
  private   int          _selstart    = 0;
  private   int          _selend      = 0;
  private   int          _selanchor   = 0;
  private   RGBA         _link_color;

  /* Properties */
  public string name { get; set; default = ""; }
  public double posx {
    get {
      return( _posx );
    }
    set {
      double diffx = (value - _posx);
      if( diffx != 0 ) {
        for( int i=0; i<_children.length; i++ ) {
          _children.index( i ).posx += diffx;
        }
        _posx = value;
      }
    }
  }
  public double posy {
    get {
      return( _posy );
    }
    set {
      double diffy = (value - _posy);
      if( diffy != 0 ) {
        for( int i=0; i<_children.length; i++ ) {
          _children.index( i ).posy += diffy;
        }
        _posy = value;
      }
    }
  }
  public string   note { get; set; default = ""; }
  public NodeMode mode {
    get {
      return( _mode );
    }
    set {
      _mode      = value;
      _selstart  = 0;
      _selend    = (_mode == NodeMode.EDITABLE) ? name.length : 0;
      _selanchor = 0;
      _cursor    = _selend;
    }
    default = NodeMode.NONE;
  }
  public Node?    parent     { get; protected set; default = null; }
  public NodeSide side       { get; set; default = NodeSide.RIGHT; }
  public bool     folded {
    get {
      return( _folded );
    }
    set {
      _folded = value;
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).folded = value;
      }
    }
  }
  public double   tree_size  { get; set; default = 0; }
  public RGBA     link_color {
    get {
      return( _link_color );
    }
    set {
      if( !is_root() ) {
        _link_color = value;
        for( int i=0; i<_children.length; i++ ) {
          _children.index( i ).link_color = value;
        }
      }
    }
  }
  public bool     attached   { get; set; default = false; }

  /* Default constructor */
  public Node( DrawArea da, Layout? layout ) {
    _id       = _next_id++;
    _children = new Array<Node>();
    _layout   = da.create_pango_layout( null );
    _layout.set_width( 200 * Pango.SCALE );
    _layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    set_layout( layout );
  }

  /* Constructor initializing string */
  public Node.with_name( DrawArea da, string n, Layout? layout ) {
    name      = n;
    _id       = _next_id++;
    _children = new Array<Node>();
    _layout   = da.create_pango_layout( n );
    _layout.set_width( 200 * Pango.SCALE );
    _layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    set_layout( layout );
  }

  /* Copies an existing node to this node */
  public Node.copy( Node n ) {
    _id       = _next_id++;
    copy_variables( n );
    mode      = NodeMode.NONE;
    _children = n._children;
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).parent = this;
    }
  }

  /* Copies an existing node tree to this node */
  public Node.copy_tree( Node n ) {
    _id       = _next_id++;
    copy_variables( n );
    mode      = NodeMode.NONE;
    _children = new Array<Node>();
    for( int i=0; i<n._children.length; i++ ) {
      Node child = new Node.copy_tree( n._children.index( i ) );
      child.parent = this;
      _children.append_val( child );
    }
  }

  /* Resets the ID generator.  This should be called whenever a new document is started. */
  public static void reset() {
    _next_id = 0;
  }

  /* Copies just the variables of the node, minus the children nodes */
  public void copy_variables( Node n ) {
    _width       = n._width;
    _height      = n._height;
    _padx        = n._padx;
    _pady        = n._pady;
    _ipadx       = n._ipadx;
    _ipady       = n._ipady;
    _task_radius = n._task_radius;
    _alpha       = n._alpha;
    _cursor      = n._cursor;
    _task_count  = n._task_count;
    _task_done   = n._task_done;
    _folded      = n._folded;
    _layout      = n._layout;
    _posx        = n._posx;
    _posy        = n._posy;
    _link_color  = n._link_color;
    name         = n.name;
    note         = n.note;
    mode         = n.mode;
    parent       = n.parent;
    side         = n.side;
  }

  /* Returns the associated ID of this node */
  public int id() {
    return( _id );
  }

  /* Sets the posx value only, leaving the children positions alone */
  public void set_posx_only( double value ) {
    _posx = value;
  }

  /* Sets the posy value only, leaving the children positions alone */
  public void set_posy_only( double value ) {
    _posy = value;
  }

  /* Sets the posx value only, leaving the children positions alone */
  public void adjust_posx_only( double value ) {
    _posx += value;
  }

  /* Sets the posy value only, leaving the children positions alone */
  public void adjust_posy_only( double value ) {
    _posy += value;
  }

  /* Returns the current width value */
  public double get_width() {
    return( _width );
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

  /* Returns true if this node is a task */
  public bool is_task() {
    return( (_task_count > 0) && is_leaf() );
  }

  /* Returns the task completion percentage value */
  public double task_completion_percentage() {
    return( (_task_done / (_task_count * 1.0)) * 100 );
  }

  /* Returns true if the given cursor coordinates lies within this node */
  public virtual bool is_within( double x, double y ) {
    double cx, cy, cw, ch;
    bbox( out cx, out cy, out cw, out ch );
    return( (cx < x) && (x < (cx + cw)) && (cy < y) && (y < (cy + ch)) );
  }

  /*
   Returns true if the given cursor coordinates lies within the task checkbutton
   area.
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

  /*
   Returns true if the given cursor coordinates lies within the note icon area.
  */
  public virtual bool is_within_note( double x, double y ) {
    if( note.length > 0 ) {
      double nx, ny, nw, nh;
      nx = posx + (_width - (note_width() + _padx)) + _ipadx;
      ny = posy + (_height / 2) - 5;
      nw = 11;
      nh = 11;
      return( (nx < x) && (x < (nx + nw)) && (ny < y) && (y < (ny + nh)) );
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
  public virtual Node? contains( double x, double y, Node? n ) {
    if( (this != n) && (is_within( x, y ) || is_within_fold( x, y )) ) {
      return( this );
    } else {
      for( int i=0; i<_children.length; i++ ) {
        Node tmp = _children.index( i ).contains( x, y, n );
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

  /* Returns the root node for this node */
  public Node get_root() {
    Node n = this;
    Node p = parent;
    while( p != null ) {
      n = p;
      p = p.parent;
    }
    return( n );
  }

  /* Returns the child index of this node within its parent */
  public virtual int index() {
    if( !is_root() ) {
      for( int i=0; i<parent.children().length; i++ ) {
        if( parent.children().index( i ) == this ) {
          return i;
        }
      }
    }
    return( -1 );
  }

  /* Returns the number of child nodes that match the given side value */
  public virtual int side_count( NodeSide side ) {
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
  public virtual void load( DrawArea da, Xml.Node* n, Layout? layout ) {

    string? i = n->get_prop( "id" );
    if( i != null ) {
      _id = int.parse( i );
      if( _next_id <= _id ) {
        _next_id = _id + 1;
      }
    }

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

    string? s = n->get_prop( "side" );
    if( s != null ) {
      side = NodeSide.parse( s );
    }

    string? f = n->get_prop( "fold" );
    if( f != null ) {
      folded = bool.parse( f );
    }

    string? ts = n->get_prop( "treesize" );
    if( ts != null ) {
      tree_size = double.parse( ts );
    }

    string? c = n->get_prop( "color" );
    if( c != null ) {
      _link_color.parse( c );
    }

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "nodename" :  load_name( it );  break;
          case "nodenote" :  load_note( it );  break;
          case "nodes"    :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                var child = new Node( da, layout );
                child.load( da, it2, layout );
                child.attach( this, -1, null, null );
              }
            }
            break;
        }
      }
    }

    if( ts == null ) {
      double bx, by, bw, bh;
      layout.bbox( this, side, out bx, out by, out bw, out bh );
      tree_size = ((side & NodeSide.horizontal()) != 0) ? bh : bw;
    }

  }

  /* Saves the current node */
  public virtual void save( Xml.Node* parent ) {
    parent->add_child( save_node() );
  }

  /* Saves the node contents to the given data output stream */
  protected Xml.Node* save_node() {

    Xml.Node* node = new Xml.Node( null, "node" );
    node->new_prop( "id", _id.to_string() );
    node->new_prop( "posx", posx.to_string() );
    node->new_prop( "posy", posy.to_string() );
    node->new_prop( "width", _width.to_string() );
    node->new_prop( "height", _height.to_string() );
    if( (_task_count > 0) && is_leaf() ) {
      node->new_prop( "task", _task_done.to_string() );
    }
    node->new_prop( "side", side.to_string() );
    node->new_prop( "fold", folded.to_string() );
    node->new_prop( "treesize", tree_size.to_string() );
    if( !is_root() ) {
      node->new_prop( "color", color_from_rgba( _link_color ) );
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

  /* Main method for importing an OPML <outline> into a node */
  public void import_opml( DrawArea da, Xml.Node* parent, int node_id, ref Array<int>? expand_state, Theme theme, Layout layout ) {

    /* Get the node name */
    string? n = parent->get_prop( "text" );
    if( n != null ) {
      name = n;
    }

    /* Get the task information */
    string? t = parent->get_prop( "checked" );
    if( t != null ) {
      _task_count = 1;
      _task_done  = bool.parse( t ) ? 1 : 0;
      propagate_task_info_up( _task_count, _task_done );
    }

    /* Get the note information */
    string? o = parent->get_prop( "node" );
    if( o != null ) {
      note = o;
    }

    /* Figure out if this node is folded */
    if( expand_state != null ) {
      folded = true;
      for( int i=0; i<expand_state.length; i++ ) {
        if( expand_state.index( i ) == node_id ) {
          folded = false;
          expand_state.remove_index( i );
          break;
        }
      }
    }

    node_id++;

    /* Parse the child nodes */
    for( Xml.Node* it2 = parent->children; it2 != null; it2 = it2->next ) {
      if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "outline") ) {
        var child = new Node( da, layout );
        child.attach( this, -1, theme, layout );
        child.import_opml( da, it2, node_id, ref expand_state, theme, layout );
      }
    }

  }

  /* Main method to export a node tree as OPML */
  public void export_opml( Xml.Node* parent, ref int node_id, ref Array<int> expand_state ) {
    parent->add_child( export_opml_node( ref node_id, ref expand_state ) );
  }

  /* Traverses the node tree exporting XML nodes in OPML format */
  private Xml.Node* export_opml_node( ref int node_id, ref Array<int> expand_state ) {
    Xml.Node* node = new Xml.Node( null, "outline" );
    node->new_prop( "text", name );
    if( is_leaf() && (_task_count > 0) ) {
      bool checked = _task_done > 0;
      node->new_prop( "checked", checked.to_string() );
    }
    if( note != "" ) {
      node->new_prop( "note", note );
    }
    if( (_children.length > 1) && !folded ) {
      expand_state.append_val( node_id );
    }
    node_id++;
    for( int i=0; i<_children.length; i++ ) {
      node->add_child( _children.index( i ).export_opml_node( ref node_id, ref expand_state ) );
    }
    return( node );
  }

  /*
   Helper function for converting an RGBA color value to a stringified color
   that can be used by a markup parser.
  */
  private string color_from_rgba( RGBA rgba ) {
    return( "#%02x%02x%02x".printf( ((int)(rgba.red * 256) - 1), ((int)(rgba.green * 256) - 1), ((int)(rgba.blue * 256) - 1) ) );
  }

  /* Generates the marked up name that will be displayed in the node */
  private string name_markup( Theme? theme ) {
    if( (_selstart != _selend) && (theme != null) ) {
      string fg      = color_from_rgba( theme.textsel_foreground );
      string bg      = color_from_rgba( theme.textsel_background );
      string seltext = "<span foreground=\"" + fg + "\" background=\"" + bg + "\">" + name.slice( _selstart, _selend ) + "</span>";
      return( name.splice( _selstart, _selend, seltext ) );
    }
    return( name );
  }

  /*
   Updates the width and height based on the current name.  Returns true
   if the width or height has changed since the last time these values were
   updated.
  */
  public void update_size( Theme? theme, out double width_diff, out double height_diff ) {
    width_diff  = 0;
    height_diff = 0;
    if( _layout != null ) {
      int text_width, text_height;
      double orig_width  = _width;
      double orig_height = _height;
      _layout.set_markup( name_markup( theme ), -1 );
      _layout.get_size( out text_width, out text_height );
      _width      = (text_width  / Pango.SCALE) + (_padx * 2) + task_width() + note_width();
      _height     = (text_height / Pango.SCALE) + (_pady * 2);
      width_diff  = _width  - orig_width;
      height_diff = _height - orig_height;
    }
  }

  /* Returns the bounding box for this node */
  public virtual void bbox( out double x, out double y, out double w, out double h ) {
    double width_diff, height_diff;
    update_size( null, out width_diff, out height_diff );
    x = posx;
    y = posy;
    w = _width;
    h = _height;
  }

  /* Returns the bounding box for the fold indicator for this node */
  private void fold_bbox( out double x, out double y, out double w, out double h ) {
    double bw, bh;
    bbox( out x, out y, out bw, out bh );
    w = 16;
    h = 10;
    switch( side ) {
      case NodeSide.RIGHT :
        x += bw + _padx;
        y += (bh / 2) - 5;
        break;
      case NodeSide.LEFT :
        x -= _padx + w;
        y += (bh / 2) - 5;
        break;
      case NodeSide.TOP :
        x += (bw / 2) - 8;
        y -= _padx + bh;
        break;
      case NodeSide.BOTTOM :
        x += (bw / 2) - 8;
        y += bh + _padx;
        break;
    }
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
  public void move_to_position( Node child, NodeSide side, double x, double y, Layout layout ) {
    child.detach( side, layout );
    child.attached = true;
    for( int i=0; i<_children.length; i++ ) {
      if( _children.index( i ).side == child.side ) {
        switch( child.side ) {
          case NodeSide.LEFT  :
          case NodeSide.RIGHT :
            if( y < _children.index( i ).posy ) {
              child.attach( this, i, null, layout );
              return;
            }
            break;
          case NodeSide.TOP :
          case NodeSide.BOTTOM :
            if( x < _children.index( i ).posx ) {
              child.attach( this, i, null, layout );
              return;
            }
            break;
        }
      } else if( _children.index( i ).side > child.side ) {
        child.attach( this, i, null, layout );
        return;
      }
    }
    child.attach( this, -1, null, layout );
  }

  /* Sets the cursor from the given mouse coordinates */
  public void set_cursor_at_char( double x, double y, bool motion ) {
    int cursor, trailing;
    int adjusted_x = (int)(x - (posx + _padx + task_width())) * Pango.SCALE;
    int adjusted_y = (int)(y - (posy + _pady)) * Pango.SCALE;
    if( _layout.xy_to_index( adjusted_x, adjusted_y, out cursor, out trailing ) ) {
      cursor += trailing;
      if( motion ) {
        if( cursor > _selanchor ) {
          _selend = cursor;
        } else if( cursor < _selanchor ) {
          _selstart = cursor;
        } else {
          _selstart = cursor;
          _selend   = cursor;
        }
      } else {
        _selstart  = cursor;
        _selend    = cursor;
        _selanchor = cursor;
      }
      _cursor = _selend;
    }
  }

  /* Selects the word at the current x/y position in the text */
  public void set_cursor_at_word( double x, double y, bool motion ) {
    int cursor, trailing;
    int adjusted_x = (int)(x - (posx + _padx + task_width())) * Pango.SCALE;
    int adjusted_y = (int)(y - (posy + _pady)) * Pango.SCALE;
    if( _layout.xy_to_index( adjusted_x, adjusted_y, out cursor, out trailing ) ) {
      cursor += trailing;
      int word_start = name.substring( 0, cursor ).last_index_of( " " );
      int word_end   = name.index_of( " ", cursor );
      if( word_start == -1 ) {
        _selstart = 0;
      } else if( !motion || (word_start < _selanchor) ) {
        _selstart = word_start + 1;
      }
      if( word_end == -1 ) {
        _selend = name.length;
      } else if( !motion || (word_end > _selanchor) ) {
        _selend = word_end;
      }
      _cursor = _selend;
    }
  }

  /* Selects all of the text and places the cursor at the end of the name string */
  public void set_cursor_all( bool motion ) {
    if( !motion ) {
      _selstart  = 0;
      _selend    = name.length;
      _selanchor = name.length;
      _cursor    = name.length;
    }
  }

  /* Move the cursor in the given direction */
  public void move_cursor( int dir ) {
    _cursor += dir;
    if( _cursor < 0 ) {
      _cursor = 0;
    } else if( _cursor > name.length ) {
      _cursor = name.length;
    }
    _selend = _selstart;
  }

  /* Moves the cursor up/down the text by a line */
  public void move_cursor_vertically( int dir ) {
    int line, x;
    int index, trailing;
    _layout.index_to_line_x( _cursor, false, out line, out x );
    line += dir;
    if( line < 0 ) {
      line = 0;
    } else if( line >= _layout.get_line_count() ) {
      line = _layout.get_line_count() - 1;
    }
    var line_layout = _layout.get_line( line );
    line_layout.x_to_index( x, out index, out trailing );
    _cursor = index + trailing;
    _selend = _selstart;
  }

  /* Moves the cursor to the beginning of the name */
  public void move_cursor_to_start() {
    _cursor = 0;
    _selend = _selstart;
  }

  /* Moves the cursor to the end of the name */
  public void move_cursor_to_end() {
    _cursor = name.length;
    _selend = _selstart;
  }

  /* Handles a backspace key event */
  public void edit_backspace( Layout layout ) {
    if( _cursor > 0 ) {
      if( _selstart != _selend ) {
        name    = name.splice( _selstart, _selend );
        _cursor = _selstart;
        _selend = _selstart;
      } else {
        name = name.splice( (_cursor - 1), _cursor );
        _cursor--;
      }
    }
    layout.handle_update_by_edit( this );
  }

  /* Handles a delete key event */
  public void edit_delete( Layout layout ) {
    if( _cursor < name.length ) {
      if( _selstart != _selend ) {
        name    = name.splice( _selstart, _selend );
        _cursor = _selstart;
        _selend = _selstart;
      } else {
        name = name.splice( _cursor, (_cursor + 1) );
      }
    }
    layout.handle_update_by_edit( this );
  }

  /* Inserts the given string at the current cursor position and adjusts cursor */
  public void edit_insert( string s, Layout layout ) {
    if( _selstart != _selend ) {
      name    = name.splice( _selstart, _selend, s );
      _cursor = _selstart + s.length;
      _selend = _selstart;
    } else {
      name = name.splice( _cursor, _cursor, s );
      _cursor += s.length;
    }
    layout.handle_update_by_edit( this );
  }

  /*
   Returns the currently selected text or, if no text is currently selected,
   returns null.
  */
  public string? get_selected_text() {
    if( _selstart != _selend ) {
      return( name.slice( _selstart, _selend ) );
    }
    return( null );
  }

  /* Detaches this node from its parent node */
  public virtual void detach( NodeSide side, Layout? layout ) {
    if( parent != null ) {
      int idx = index();
      propagate_task_info_up( (0 - _task_count), (0 - _task_done) );
      parent.children().remove_index( idx );
      if( layout != null ) {
        layout.handle_update_by_delete( parent, idx, side, tree_size );
      }
      parent      = null;
      attached    = false;
    }
  }

  /* Removes this node from the node tree along with all descendents */
  public virtual void delete( Layout layout ) {
    detach( side, layout );
  }

  /* Attaches this node as a child of the given node */
  public virtual void attach( Node parent, int index, Theme? theme, Layout? layout ) {
    this.parent = parent;
    if( (parent._children.length == 0) && (parent._task_count == 1) ) {
      parent.propagate_task_info_up( (0 - parent._task_count), (0 - parent._task_done) );
      parent._task_count = 0;
      parent._task_done  = 0;
      _task_count = 1;
      _task_done  = 0;
    }
    if( index == -1 ) {
      index = (int)this.parent.children().length;
      parent.children().append_val( this );
    } else {
      parent.children().insert_val( index, this );
    }
    propagate_task_info_up( _task_count, _task_done );
    if( layout != null ) {
      layout.handle_update_by_insert( parent, this, index );
    }
    if( !is_root() && (theme != null) ) {
      link_color = main_branch() ? theme.next_color() : parent.link_color;
    }
    attached = true;
  }

  /* Returns a reference to the first child of this node */
  public virtual Node? first_child( NodeSide? side = null ) {
    if( !folded ) {
      for( int i=0; i<(int)_children.length; i++ ) {
        if( (side == null) || (_children.index( i ).side == side) ) {
          return( _children.index( i ) );
        }
      }
    }
    return( null );
  }

  /* Returns a reference to the last child of this node */
  public virtual Node? last_child( NodeSide? side = null ) {
    if( !folded ) {
      for( int i=((int)_children.length - 1); i>=0; i-- ) {
        if( (side == null) || (_children.index( i ).side == side) ) {
          return( _children.index( i ) );
        }
      }
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

  /* Propagates task information toward the leaf nodes */
  private void propagate_task_info_down( bool? enable, bool? done ) {
    if( is_leaf() ) {
      if( enable != null ) {
        _task_count = enable ? 1 : 0;
      }
      if( _task_count == 1 ) {
        if( done == null ) {
          _task_done = ((_task_count == 0) || (_task_done == 0)) ? 0 : 1;
        } else {
          _task_done = done ? 1 : 0;
        }
      } else {
        _task_done  = 0;
      }
    } else {
      _task_count = 0;
      _task_done  = 0;
      for( int i=0; i<children().length; i++ ) {
        children().index( i ).propagate_task_info_down( enable, done );
        _task_count += children().index( i )._task_count;
        _task_done  += children().index( i )._task_done;
      }
    }
  }

  /* Propagates a change in the task_done for this node to all parent nodes */
  private void propagate_task_info_up( int count_adjust, int done_adjust ) {
    Node p = parent;
    while( p != null ) {
      p._task_count += count_adjust;
      p._task_done  += done_adjust;
      p = p.parent;
    }
  }

  /* Propagates the given task enable information down and up the tree */
  private void propagate_task_info( bool? enable, bool? done ) {
    int task_count = _task_count;
    int task_done  = _task_done;
    propagate_task_info_down( enable, done );
    propagate_task_info_up( (_task_count - task_count), (_task_done - task_done) );
  }

  /* Returns true if this node's task indicator is currently enabled */
  public bool task_enabled() {
    return( _task_count > 0 );
  }

  /* Returns true if this node's task indicator indicates that it is currently done */
  public bool task_done() {
    return( _task_count == _task_done );
  }

  /* Sets the task enable to the given value */
  public void enable_task( bool task ) {
    propagate_task_info( task, null );
  }

  /*
   Sets the task done indicator to the given value (0 or 1) and propagates the
   change to all parent nodes.
  */
  public void set_task_done( bool done ) {
    propagate_task_info( null, done );
  }

  /*
   Toggles the current value of task done and propagates the change to all
   parent nodes.
  */
  public void toggle_task_done() {
    set_task_done( _task_done == 0 );
  }

  /*
   Set all ancestor nodes fold indicators to false.  Returns the last node
   that is last node that is folded.
  */
  public Node reveal( Layout layout ) {
    var tmp = parent;
    while( tmp != null ) {
      if( !tmp._folded ) {
        return( tmp );
      }
      tmp._folded = false;
      layout.handle_update_by_fold( tmp );
      tmp  = tmp.parent;
    }
    return( tmp );
  }

  /*
   Checks the given string to see if it is a match to the given pattern.  If
   it is, the matching portion of the string appended to the list of matches.
  */
  private void match_string( string pattern, string value, string type, ref Gtk.ListStore matches ) {
    int index = value.casefold().index_of( pattern );
    if( index != -1 ) {
      TreeIter it;
      int    start_index = (index > 20) ? (index - 20) : 0;
      string prefix      = (index > 20) ? "..."        : "";
      string str         = prefix +
                           value.substring( start_index, (index - start_index) ) + "<u>" +
                           value.substring( index, pattern.length ) + "</u>" +
                           value.substring( (index + pattern.length), -1 );
      matches.append( out it );
      matches.set( it, 0, type, 1, str, 2, this, -1 );
    }
  }

  /*
   Populates the given ListStore with all nodes that have names that match
   the given string pattern.
  */
  public void get_match_items( string pattern, bool[] search_opts, ref Gtk.ListStore matches ) {
    if( ((((_task_count == 0) || !is_leaf()) && search_opts[5]) ||
         ((_task_count != 0) && is_leaf()   && search_opts[4])) &&
        (((parent != null) && parent.folded && search_opts[2]) ||
         (((parent == null) || !parent.folded) && search_opts[3])) ) {
      if( search_opts[0] ) {
        match_string( pattern, name, "<b><i>Title:</i></b>", ref matches );
      }
      if( search_opts[1] ) {
        match_string( pattern, note, "<b><i>Note:</i></b>", ref matches );
      }
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).get_match_items( pattern, search_opts, ref matches );
    }
  }

  /* Adjusts the posx and posy values */
  public virtual void pan( double origin_x, double origin_y ) {
    posx -= origin_x;
    posy -= origin_y;
  }

  /*
   Called when the theme is changed by the user.  Looks up this
   node's link color in the old theme to see if it is a themed color.
   If it is, map it to the new theme's color palette.  If the current
   color is not a theme link color, keep the current color as it
   was custom set by the user.  Performs this mapping recursively for
   all descendants.
  */
  public void map_theme_colors( Theme old_theme, Theme new_theme ) {
    int old_index = old_theme.get_color_index( _link_color );
    if( old_index != -1 ) {
      _link_color = new_theme.link_color( old_index );
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).map_theme_colors( old_theme, new_theme );
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
    if( is_root() ) {
      x = posx + (_width / 2);
      y = posy + (_height / 2);
    } else {
      switch( side ) {
        case NodeSide.LEFT :
          x = posx;
          y = posy + _height;
          break;
        case NodeSide.TOP :
          x = posx + (_width / 2);
          y = posy;
          break;
        case NodeSide.RIGHT :
          x = posx + _width;
          y = posy + _height;
          break;
        default :
          x = posx + (_width / 2);
          y = posy + _height;
          break;
      }
    }
  }

  /* Draws the rectangle around the root node */
  protected void draw_root_rectangle( Context ctx, Theme theme ) {

    double r = 10.0;
    double x = posx;
    double y = posy;
    double h = _height;
    double w = _width;

    /* Draw the rounded box around the text */
    set_context_color( ctx, theme.root_background );
    ctx.set_line_width( 1 );
    ctx.move_to(x+r,y);                      // Move to A
    ctx.line_to(x+w-r,y);                    // Straight line to B
    ctx.curve_to(x+w,y,x+w,y,x+w,y+r);       // Curve to C, Control points are both at Q
    ctx.line_to(x+w,y+h-r);                  // Move to D
    ctx.curve_to(x+w,y+h,x+w,y+h,x+w-r,y+h); // Curve to E
    ctx.line_to(x+r,y+h);                    // Line to F
    ctx.curve_to(x,y+h,x,y+h,x,y+h-r);       // Curve to G
    ctx.line_to(x,y+r);                      // Line to H
    ctx.curve_to(x,y,x,y,x+r,y);             // Curve to A
    ctx.fill();

  }

  /* Draws the node font to the screen */
  protected virtual void draw_name( Cairo.Context ctx, Theme theme ) {

    int    hmargin = 3;
    int    vmargin = 3;
    double width_diff, height_diff;

    /* Make sure the the size is up-to-date */
    update_size( theme, out width_diff, out height_diff );

    /* Get the widget of the task icon */
    double twidth = task_width();

    /* Draw the selection box around the text if the node is in the 'selected' state */
    if( mode == NodeMode.CURRENT ) {
      set_context_color( ctx, theme.nodesel_background );
      ctx.rectangle( ((posx + _padx) - hmargin), ((posy + _pady) - vmargin), ((_width - (_padx * 2)) + (hmargin * 2)), ((_height - (_pady * 2)) + (vmargin * 2)) );
      ctx.fill();
    }

    /* Output the text */
    ctx.move_to( (posx + _padx + twidth), (posy + _pady) );
    switch( mode ) {
      case NodeMode.CURRENT  :  set_context_color( ctx, theme.nodesel_foreground );  break;
      default                :  set_context_color( ctx, (parent == null) ? theme.root_foreground : theme.foreground );  break;
    }
    Pango.cairo_show_layout( ctx, _layout );

    /* Draw the insertion cursor if we are in the 'editable' state */
    if( mode == NodeMode.EDITABLE ) {
      var rect = _layout.index_to_pos( _cursor );
      set_context_color( ctx, theme.text_cursor );
      double ix, iy;
      ix = (posx + _padx + twidth) + (rect.x / Pango.SCALE) - 1;
      iy = (posy + _pady) + (rect.y / Pango.SCALE);
      ctx.rectangle( ix, iy, 1, (rect.height / Pango.SCALE) );
      ctx.fill();
    }

  }

  /* Draws the task checkbutton for leaf nodes */
  protected virtual void draw_leaf_task( Context ctx, RGBA color ) {

    if( _task_count > 0 ) {

      double x = posx + _padx + _task_radius;
      double y = posy + (_height / 2);

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

  /* Draws the task checkbutton for non-leaf nodes */
  protected virtual void draw_acc_task( Context ctx, RGBA color ) {

    if( _task_count > 0 ) {

      double x        = posx + _padx + _task_radius;
      double y        = posy + (_height / 2);
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

      double x = posx + (_width - (note_width() + _padx)) + _ipadx;
      double y = posy + (_height / 2) - 5;

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
  protected virtual void draw_common_fold( Context ctx, RGBA bg_color, RGBA fg_color ) {

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

  /* Draws the attachable highlight border to indicate when a node is attachable */
  protected virtual void draw_attachable( Context ctx, Theme theme, RGBA? frost_background ) {

    if( mode == NodeMode.ATTACHABLE ) {

      double x, y, w, h;
      bbox( out x, out y, out w, out h );

      /* Draw box that is translucent */
      if( frost_background != null ) {
        set_context_color_with_alpha( ctx, frost_background, 0.8 );
        ctx.rectangle( x, y, w, h );
        ctx.fill();
      }

      /* Draw highlight border */
      set_context_color( ctx, theme.attachable_color );
      ctx.set_line_width( 4 );
      ctx.rectangle( x, y, w, h );
      ctx.stroke();

    }

  }

  /* Draws the line under the node name */
  protected virtual void draw_line( Context ctx, Theme theme ) {

    /* If we are vertically oriented, don't draw the line */
    if( (side & NodeSide.vertical()) != 0 ) return;

    double x = posx;
    double y = posy + _height;
    double w = _width;

    /* Draw the line under the text name */
    set_context_color( ctx, _link_color );
    ctx.set_line_width( 4 );
    ctx.set_line_cap( LineCap.ROUND );
    ctx.move_to( x, y );
    ctx.line_to( (x + w), y );
    ctx.stroke();

  }

  /* Draw the link from this node to the parent node */
  protected virtual void draw_link( Context ctx, Theme theme ) {

    double parent_x;
    double parent_y;

    /* Get the parent's link point */
    parent.link_point( out parent_x, out parent_y );

    set_context_color( ctx, _link_color );
    ctx.set_line_width( 4 );
    ctx.set_line_cap( LineCap.ROUND );
    ctx.move_to( parent_x, parent_y );
    switch( side ) {
      case NodeSide.LEFT :
        ctx.line_to( (posx + _width), (posy + _height) );
        break;
      case NodeSide.RIGHT :
        ctx.line_to( posx, (posy + _height) );
        break;
      case NodeSide.TOP :
        ctx.line_to( (posx + (_width / 2)), (posy + _height) );
        break;
      case NodeSide.BOTTOM :
        ctx.line_to( (posx + (_width / 2)), posy );
        break;
    }
    ctx.stroke();

  }

  /* Draws the node on the screen */
  public virtual void draw( Context ctx, Theme theme ) {

    /* If this is a root node, draw specifically for a root node */
    if( is_root() ) {
      draw_root_rectangle( ctx, theme );
      draw_name( ctx, theme );
      if( is_leaf() ) {
        draw_leaf_task( ctx, theme.root_foreground );
      } else {
        draw_acc_task( ctx, theme.root_foreground );
      }
      draw_common_note( ctx, theme.root_foreground );
      draw_common_fold( ctx, theme.root_background, theme.root_foreground );
      draw_attachable( ctx, theme, theme.root_background );

    /* Otherwise, draw the node as a non-root node */
    } else {
      draw_name( ctx, theme );
      if( is_leaf() ) {
        draw_leaf_task( ctx, _link_color );
      } else {
        draw_acc_task( ctx, _link_color );
      }
      draw_common_note( ctx, theme.foreground );
      draw_line( ctx, theme );
      draw_common_fold( ctx, _link_color, theme.foreground );
      draw_attachable( ctx, theme, theme.background );
    }

  }

  /* Draw this node and all child nodes */
  public void draw_all( Context ctx, Theme theme, Node? current, bool draw_current ) {
    if( this != current ) {
      if( !folded ) {
        for( int i=0; i<_children.length; i++ ) {
          _children.index( i ).draw_all( ctx, theme, current, false );
        }
      }
      draw( ctx, theme );
    }
    if( !is_root() && !draw_current ) {
      draw_link( ctx, theme );
    }
  }

  /* Called whenever the user changes the layout */
  public void set_layout( Layout? layout ) {
    if( layout == null ) return;
    _padx  = layout.padx;
    _pady  = layout.pady;
    _ipadx = layout.ipadx;
    _ipady = layout.ipady;
    layout.set_side( this );
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).set_layout( layout );
    }
    _layout.set_font_description( layout.get_font_description() );
  }

  /* Outputs the node's information to standard output */
  public void display( string prefix = "" ) {
    stdout.printf( "%sNode, name: %s, posx: %g, posy: %g, side: %s\n", prefix, name, posx, posy, side.to_string() );
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).display( prefix + "  " );
    }
  }

}
