/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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
using Gee;

//-------------------------------------------------------------
// Enumeration describing the different modes a node can be in
public enum NodeMode {
  NONE = 0,      // Specifies that this node is not the current node
  CURRENT,       // Specifies that this node is the current node and is not being edited
  SELECTED,      // Specifies that this node is one of several selected nodes
  EDITABLE,      // Specifies that this node's text has been and currently is actively being edited
  ATTACHABLE,    // Specifies that this node is the currently attachable node (affects display)
  DROPPABLE,     // Specifies that this node can receive a dropped item
  HIGHLIGHTED,   // Specifies that this node is both selected and being highlighted
  MARKED_NONE,   // Specifies that this node is marked (highlight with dashed line) and previous state was NONE
  MARKED_CURR,   // Specifies that this node is marked and previous state was CURRENT
  MARKED_SEL;    // Specifies that this node is marked and previous state was SELECTED

  //-------------------------------------------------------------
  // Returns the mode to set a node to whose current state is
  // not an attachable state.
  public NodeMode get_attach_set_mode( bool mark ) {
    switch( this ) {
      case CURRENT  :  return( MARKED_CURR );
      case SELECTED :  return( MARKED_SEL );
      default       :  return( mark ? MARKED_NONE : ATTACHABLE );  
    }
  }

  //-------------------------------------------------------------
  // Returns the mode to set a node to whose current state is an
  // attachable state.
  public NodeMode get_attach_reset_mode() {
    switch( this ) {
      case MARKED_CURR :  return( CURRENT );
      case MARKED_SEL  :  return( SELECTED );
      default          :  return( NONE );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the mode indicates that this node will be
  // drawn as selected.
  public bool is_selected() {
    return(
      (this == CURRENT)     ||
      (this == SELECTED)    ||
      (this == HIGHLIGHTED) ||
      (this == MARKED_CURR) ||
      (this == MARKED_SEL)
    );
  }

  //-------------------------------------------------------------
  // Returns true if this node is indicating that the node should
  // be distinguished as an attachable/droppable node.
  public bool attachable() {
    return(
      (this == ATTACHABLE)  ||
      (this == DROPPABLE)   ||
      (this == HIGHLIGHTED) ||
      is_marked()
    );
  }

  //-------------------------------------------------------------
  // Specifies if this node should be drawn as "marked" which means
  // this it looks like an attachable node but is not as noted by
  // a dashed highlight.
  public bool is_marked() {
    return(
      (this == MARKED_NONE) ||
      (this == MARKED_CURR) ||
      (this == MARKED_SEL)
    );
  }
}

public enum NodeSide {
  LEFT   = 1,  // Specifies that this node is to the left of the root node
  TOP    = 2,  // Specifies that this node is above the root node
  RIGHT  = 4,  // Specifies that this node is to the right of the root node
  BOTTOM = 8;  // Specifies that this node is below the root node

  //-------------------------------------------------------------
  // Displays the string value of this NodeSide.
  public string to_string() {
    switch( this ) {
      case LEFT   :  return( "left" );
      case TOP    :  return( "top" );
      case RIGHT  :  return( "right" );
      case BOTTOM :  return( "bottom" );
      default     :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Translates a string from to_string() to a NodeSide value.
  public static NodeSide parse( string val ) {
    switch( val ) {
      case "left"   :  return( LEFT );
      case "top"    :  return( TOP );
      case "right"  :  return( RIGHT );
      case "bottom" :  return( BOTTOM );
      default       :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Generates the value of the VERTICAL mask value.
  public bool vertical() {
    return( (this == TOP) || (this == BOTTOM) );
  }

  //-------------------------------------------------------------
  // Generates the value of the HORIZONTAL mask value.
  public bool horizontal() {
    return( (this == LEFT) || (this == RIGHT) );
  }
}

public class NodeBounds {

  private MindMap _map;
  private double  _x = 0.0;
  private double  _y = 0.0;

  public double x {
    get {
      return( _x + _map.origin_x );
    }
    set {
      _x = (value - _map.origin_x);
    }
  }
  public double y {
    get {
      return( _y + _map.origin_y );
    }
    set {
      _y = (value - _map.origin_y);
    }
  }
  public double width  { set; get; default = 0.0; }
  public double height { set; get; default = 0.0; }

  //-------------------------------------------------------------
  // Default constructor.
  public NodeBounds( MindMap map ) {
    _map = map;
  }

  //-------------------------------------------------------------
  // Constructor with bounds information.
  public NodeBounds.with_bounds( MindMap map, double x, double y, double w, double h ) {
    _map        = map;
    this.x      = x;
    this.y      = y;
    this.width  = w;
    this.height = h;
  }

  //-------------------------------------------------------------
  // Copy constructor.
  public NodeBounds.copy( NodeBounds nb ) {
    copy_from( nb );
  }

  //-------------------------------------------------------------
  // Copies the given node bounds to this instance.
  public void copy_from( NodeBounds nb ) {
    _map        = nb._map;
    this.x      = nb.x;
    this.y      = nb.y;
    this.width  = nb.width;
    this.height = nb.height;
  }

  //-------------------------------------------------------------
  // Returns true if the given NodeBounds overlap.
  public bool overlaps( NodeBounds other ) {
    return( ((x < (other.x + other.width))  && ((x + width) > other.x)) &&
            ((y < (other.y + other.height)) && ((y + height) > other.y)) );
  }

  //-------------------------------------------------------------
  // Returns the X-coordinates of the upper-left corner of this
  // bounds.
  public double x1() { return( x ); }

  //-------------------------------------------------------------
  // Returns the Y-coordinates of the upper-left corner of this
  // bounds.
  public double y1() { return( y ); }

  //-------------------------------------------------------------
  // Returns the X-coordinates of the lower-right corner of this
  // bounds.
  public double x2() { return( x + width ); }

  //-------------------------------------------------------------
  // Returns the Y-coordinates of the lower-right corner of this
  // bounds.
  public double y2() { return( y + height ); }

  //-------------------------------------------------------------
  // Returns a string version of this instance.
  public string to_string() {
    return( "map: %s, x: %g, y: %g, w: %g, h: %g".printf( (_map != null).to_string(), x, y, width, height ) );
  }

}

public struct NodeInfo {
  double   posx;
  double   posy;
  NodeSide side;
  RGBA     color;
  public NodeInfo( double x, double y, NodeSide s, RGBA c ) {
    posx  = x;
    posy  = y;
    side  = s;
    color = c;
  }
}

public class BaseNode : Object {

  // Member variables
  protected MindMap         _map;
  protected int             _id;
  protected double          _width        = 0;
  protected double          _height       = 0;
  protected double          _total_width  = 0;
  protected double          _total_height = 0;
  protected double          _ipadx        = 6;
  protected double          _ipady        = 3;
  protected double          _alpha        = 1.0;
  protected BaseNode        _parent       = null;
  protected Array<BaseNode> _children;
  protected NodeMode        _mode         = NodeMode.NONE;
  protected NodeBounds      _tree_bbox;
  protected double          _posx         = 0;
  protected double          _posy         = 0;
  protected Layout?         _layout       = null;
  protected bool            _loaded       = true;
  protected Style           _style        = new Style();

  // Node signals
  public signal void moved( double diffx, double diffy );
  public signal void resized( double diffw, double diffh );

  // Properties
  public MindMap map {
    get {
      return( _map );
    }
  }
  public double posx {
    get {
      return( _posx + _map.origin_x );
    }
    set {
      double diff = (value - posx);
      _posx = value - _map.origin_x;
      update_tree_bbox( diff, 0 );
      if( diff != 0 ) {
        moved( diff, 0 );
      }
    }
  }
  public double posy {
    get {
      return( _posy + _map.origin_y );
    }
    set {
      double diff = (value - posy);
      _posy = value - _map.origin_y;
      update_tree_bbox( 0, diff );
      if( diff != 0 ) {
        moved( 0, diff );
      }
    }
  }
  public NodeMode mode {
    get {
      return( _mode );
    }
    set {
      if( _mode != value ) {
        _mode = value;
        mode_callback();
        if( _mode == NodeMode.EDITABLE ) {
          name.edit = true;
          name.node_selected = false;
          name.set_cursor_all( false );
        } else {
          name.edit = false;
          name.node_selected = _mode.is_selected();
          name.clear_selection();
        }
      }
    }
  }
  public BaseNode? parent {
    get {

      return( (((_parent as SummarizedNode) != null) && (_parent.childen().index( 0 ) != this)) ? _parent.parent : _parent );
    }
    protected set {
      _parent = value;
    }
  }
  public SummarizedNode? summarized_node {
    get {
      return( is_summary() ? null : (_parent as SummarizedNode) );
    }
  }
  public NodeSide  side      { get; set; default = NodeSide.RIGHT; }
  public double    tree_size { get; set; default = 0; }
  public BaseNode? last_selected_child { get; set; default = null; }
  public Layout?   layout {
    get {
      return( _layout );
    }
    set {
      _layout = value;
      if( traversable() ) {
        for( int i=0; i<_children.length; i++ ) {
          _children.index( i ).layout = value;
        }
      }
    }
  }
  public double alpha {
    get {
      return( _alpha );
    }
    set {
      _alpha = value;
      if( traversable() ) {
        for( int i=0; i<_children.length; i++ ) {
          _children.index( i ).alpha = value;
        }
      }
      alpha_callback();
    }
  }
  public double width {
    get {
      return( _width );
    }
  }
  public double height {
    get {
      return( _height );
    }
  }
  public double total_width {
    get {
      return( _total_width );
    }
  }
  public double total_height {
    get {
      return( _total_height );
    }
  }
  public NodeBounds tree_bbox {
    get {
      return( _tree_bbox );
    }
    set {
      _tree_bbox.copy_from( value );
    }
  }
  public Style style {
    get {
      return( _style );
    }
    set {
      if( _style.copy( value ) ) {
        name.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
        name.set_text_alignment( _style.node_text_align );
        if( _sequence_num != null ) {
          _sequence_num.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
        }
        name.max_width = style.node_width;
        if( traversable() ) {
          for( int i=0; i<_children.length; i++ ) {
            _layout.apply_margin( _children.index( i ) );
          }
        }
        style_callback();
        update_size();
      }
    }
  }

  //-------------------------------------------------------------
  // Default constructor.
  public BaseNode( MindMap map, Layout? layout ) {
    _map       = map;
    _id        = map.next_node_id;
    _children  = new Array<Node>();
    _tree_bbox = new NodeBounds( map );
    _layout    = layout;
  }

  //-------------------------------------------------------------
  // Constructor from an XML node.
  public BaseNode.from_xml( MindMap map, Layout? layout, Xml.Node* n, bool isroot ) {
    _map       = map;
    _children  = new Array<Node>();
    _tree_bbox = new NodeBounds( map );
    _layout    = layout;
    load( map, n, isroot );
  }

  //-------------------------------------------------------------
  // Creates a node.  This method should be overridden for its type.
  public virtual BaseNode make_node( MindMap map ) {
    var node = new BaseNode( map, null );
    return( node );
  }

  //-------------------------------------------------------------
  // Copies an existing node to this node.
  public virtual BaseNode copy( MindMap map, ImageManager im ) {
    var copy = make_node( map );
    copy.copy_variables( this, im );
    copy.mode = NodeMode.NONE;
    copy._children = _children;
    for( int i=0; i<copy._children.length; i++ ) {
      copy._children.index( i ).parent = this;
    }
    return( copy );
  }

  //-------------------------------------------------------------
  // Copies only the node without worrying about the child nodes.
  public virtual BaseNode copy_only( MindMap map, ImageManager im ) {
    var copy = make_node( map );
    copy.copy_variables( this, im );
    return( copy );
  }

  //-------------------------------------------------------------
  // Copies an existing node tree to this node.
  public virtual BaseNode copy_tree( MindMap map, ImageManager im ) {
    var copy = make_node( map );
    copy.copy_variables( this, im );
    copy.mode      = NodeMode.NONE;
    copy.tree_size = tree_size;
    for( int i=0; i<_children.length; i++ ) {
      var child = _children.index( i ).copy_tree( map, im );
      child.parent = this;
      _children.append_val( child );
    }
    return( copy );
  }

  //-------------------------------------------------------------
  // Copies just the variables of the node, minus the children
  // nodes.
  public void copy_variables( BaseNode n, ImageManager im ) {
    _width        = n._width;
    _height       = n._height;
    _total_width  = n._total_width;
    _total_height = n._total_height;
    _layout       = n._layout;
    _posx         = n._posx;
    _posy         = n._posy;
    mode          = n.mode;
    style         = n.style;
    parent        = n.parent;
    side          = n.side;
    tree_bbox.copy_from( n.tree_bbox );
  }

  //-------------------------------------------------------------
  // Allows derived class to handle changes to the alpha value.
  protected virtual void alpha_callback() {}

  //-------------------------------------------------------------
  // Allows derived class to handle changes to the style.
  protected virtual void style_callback() {}

  //-------------------------------------------------------------
  // Allows derived class to handle changes to the mode value.
  protected virtual void mode_callback() {}

  //-------------------------------------------------------------
  // Returns the associated ID of this node.
  public int id() {
    return( _id );
  }

  //-------------------------------------------------------------
  // Reassign this node's and all child node's ID from the mindmap.
  public virtual void reassign_ids() {
    _id = _map.next_node_id;
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).reassign_ids();
    }
  }

  //-------------------------------------------------------------
  // Sets the posx value only, leaving the children positions alone.
  public virtual void set_posx_only( double value ) {
    var diff = value - _posx;
    _posx = value;
    update_tree_bbox( diff, 0 );
  }

  //-------------------------------------------------------------
  // Sets the posy value only, leaving the children positions
  // alone.
  public virtual void set_posy_only( double value ) {
    var diff = value - _posy;
    _posy = value;
    update_tree_bbox( 0, diff );
  }

  //-------------------------------------------------------------
  // Sets the alpha value without propagating this to the children.
  public virtual void set_alpha_only( double value ) {
    _alpha = value;
  }

  //-------------------------------------------------------------
  // Updates the alpha value if it is not set to 1.0.
  public virtual void update_alpha( double value ) {
    if( _alpha < 1.0 ) {
      set_alpha_only( value );
    }
    if( traversable() ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).update_alpha( value );
      }
    }
  }

  //-------------------------------------------------------------
  // Sets the posx value only, leaving the children positions alone.
  public virtual void adjust_posx_only( double value ) {
    _posx += value;
    update_tree_bbox( value, 0 );
  }

  //-------------------------------------------------------------
  // Sets the posy value only, leaving the children positions alone.
  public virtual void adjust_posy_only( double value ) {
    _posy += value;
    update_tree_bbox( 0, value );
  }

  //-------------------------------------------------------------
  // Updates the tree_bbox.
  protected virtual void update_tree_bbox( double diffx, double diffy ) {
    var nb = tree_bbox;
    nb.x += diffx;
    nb.y += diffy;
    tree_bbox = nb;
  }

  //-------------------------------------------------------------
  // Calculates the node size based on the width and height of
  // all of the node elements.  Also returns whether the node
  // width was dictated by the embedded image or not.  This method
  // needs to be implemented by the derived class.
  public virtual void calculate_node_size( out double width, out double height ) {
    width  = 0;
    height = 0;
  }

  //-------------------------------------------------------------
  // Called whenever the node size is changed.
  protected void update_size() {

    if( !_loaded ) return;

    var orig_width  = _total_width;
    var orig_height = _total_height;

    calculate_node_size( out _width, out _height );
    update_total_size();

    var diffw = _total_width - orig_width;
    var diffh = _total_height - orig_height;

    if( (diffw != 0) || (diffh != 0) ) {
      if( _layout != null ) {
        _layout.handle_update_by_edit( this, diffw, diffh );
      }
      resized( diffw, diffh );
    }

  }

  //-------------------------------------------------------------
  // Updates the total size which includes the callout.
  private virtual void update_total_size() {
    _total_width  = _width;
    _total_height = _height;
  }

  //-------------------------------------------------------------
  // Updates the size of all nodes within this tree.  This method
  // needs to be implemented by the derived class.
  public virtual void update_tree() {
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).update_tree();
    }
  }

  //-------------------------------------------------------------
  // Updates all nodes styles for ourselves and our node tree.
  // Include any callouts that exist within the node.
  public virtual void set_style_for_tree( Style s ) {
    style = s;
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).set_style_for_tree( s );
    }
  }

  //-------------------------------------------------------------
  // Get the level of this node.
  public uint get_level() {
    var p = parent;
    uint level = 0;
    while( p != null ) {
      level++;
      p = p.parent;
    }
    return( level );
  }

  //-------------------------------------------------------------
  // Returns true if the node does not have a parent.
  public bool is_root() {
    return( parent == null );
  }

  //-------------------------------------------------------------
  // Returns true if this node is a summary node.  A summary node
  // is the child of a summarized node.
  public bool is_summary() {
    return( (_parent != null) && ((_parent as SummarizedNode) != null) && (_parent.children().index( 0 ) == this) );
  }

  //-------------------------------------------------------------
  // Returns true if this node can be traversed in the hierarchy.
  public virtual bool traversable() {
    return( true );
  }

  //-------------------------------------------------------------
  // Returns true if this node is positioned somewhere between
  // the first and last sibling node in the same parent.
  public virtual bool is_between_siblings( BaseNode first, BaseNode last ) {
    return( (first.parent == parent) && (last.parent == parent) && ((first.index() <= index()) && (index() <= last.index())) );
  }

  //-------------------------------------------------------------
  // Returns true if this node is a "main branch" which is a node
  // attached directly to the parent.
  public virtual bool main_branch() {
    return( (parent != null) && (parent.parent == null) );
  }

  //-------------------------------------------------------------
  // Returns the number of descendants within this node.
  public virtual int descendant_count() {
    if( !traversable() ) {
      return( 0 );
    } else {
      var count = (int)_children.length;
      for( int i=0; i<_children.length; i++ ) {
        count += _children.index( i ).descendant_count();
      }
      return( count );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the node is a leaf node.
  public virtual bool is_leaf() {
    return( (parent != null) && (_children.length == 0) );
  }

  //-------------------------------------------------------------
  // Returns true if this node is a descendant of the given node.
  public virtual bool is_descendant_of( BaseNode node ) {
    var p = parent;
    while( (p != null) && (p != node) ) {
      p = p.parent;
    }
    return( p == node );
  }

  //-------------------------------------------------------------
  // Returns true if this tree bounds of this node is left of the
  // given bounds.
  public virtual bool is_left_of( NodeBounds nb ) {
    return( (tree_bbox.x + tree_bbox.width) < nb.x );
  }

  //-------------------------------------------------------------
  // Returns true if this tree bounds of this node is right of
  // the given bounds.
  public virtual bool is_right_of( NodeBounds nb ) {
    return( tree_bbox.x > (nb.x + nb.width) );
  }

  //-------------------------------------------------------------
  // Returns true if this tree bounds of this node is above the
  // given bounds.
  public virtual bool is_above( NodeBounds nb ) {
    return( (tree_bbox.y + tree_bbox.height) < nb.y );
  }

  //-------------------------------------------------------------
  // Returns true if this tree bounds of this node is below the
  // given bounds.
  public virtual bool is_below( NodeBounds nb ) {
    return( tree_bbox.y > (nb.y + nb.height) );
  }

  //-------------------------------------------------------------
  // Returns true if the resizer should be in the upper left.
  public virtual bool resizer_on_left() {
    return( !is_root() && (side == NodeSide.LEFT) );
  }

  //-------------------------------------------------------------
  // Returns true if the given cursor coordinates lie within any
  // part of this node.
  public virtual bool is_within( double x, double y ) {
    double bx, by, bw, bh;
    bbox( out bx, out by, out bw, out bh );
    return( Utils.is_within_bounds( x, y, bx, by, bw, bh ) );
  }

  //-------------------------------------------------------------
  // Returns true if the given cursor coordinates lies within
  // the node bounding box.
  public virtual bool is_within_node( double x, double y ) {
    double margin = style.node_margin;
    double cx, cy, cw, ch;
    node_bbox( out cx, out cy, out cw, out ch );
    cx += margin;
    cy += margin;
    cw -= margin * 2;
    ch -= margin * 2;
    return( Utils.is_within_bounds( x, y, cx, cy, cw, ch ) );
  }

  //-------------------------------------------------------------
  // Returns the positional information for where the resizer box
  // is located (if it exists).
  protected virtual void resizer_bbox( out double x, out double y, out double w, out double h ) {
    int margin  = style.node_margin;
    x = resizer_on_left() ? (posx + margin) : (posx + _width - margin - 8);
    y = posy + margin;
    w = 8;
    h = 8;
  }

  //-------------------------------------------------------------
  // Returns true if the given cursor coordinates lie within the
  // resizer area.
  public virtual bool is_within_resizer( double x, double y ) {
    if( (mode == NodeMode.CURRENT) || (mode == NodeMode.HIGHLIGHTED) ) {
      double rx, ry, rw, rh;
      resizer_bbox( out rx, out ry, out rw, out rh );
      return( Utils.is_within_bounds( x, y, rx, ry, rw, rh ) );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Finds the node which contains the given pixel coordinates.
  // The derived class must implement this function.
  public virtual BaseNode? contains( double x, double y, bool allow_selected ) {
    return( null );
  }

  //-------------------------------------------------------------
  // Returns true if this node contains the given node.
  public virtual bool contains_node( BaseNode node ) {
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

  //-------------------------------------------------------------
  // Returns true if the given box intersects with this node box.
  protected virtual bool intersects_with( Gdk.Rectangle box ) {
    var int_x = (int)posx;
    var int_y = (int)posy;
    var int_w = (int)width;
    var int_h = (int)height;
    Gdk.Rectangle node_box = { int_x, int_y, int_w, int_h };
    return( box.intersect( node_box, null ) );
  }

  //-------------------------------------------------------------
  // Adds all nodes within this tree that intersect with the
  // given box.
  public virtual void get_nodes_within_box( Gdk.Rectangle box, Array<BaseNode> nodes ) {
    if( intersects_with( box ) ) {
      nodes.append_val( this );
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).get_nodes_within_box( box, nodes );
    }
  }

  //-------------------------------------------------------------
  // Returns the children nodes of this node.
  public Array<BaseNode> children() {
    return( _children );
  }

  //-------------------------------------------------------------
  // Returns the root node for this node.
  public virtual BaseNode get_root() {
    var n = this;
    var p = parent;
    while( p != null ) {
      n = p;
      p = p.parent;
    }
    return( n );
  }

  //-------------------------------------------------------------
  // Returns the child index of this node within its parent.
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

  //-------------------------------------------------------------
  // Returns the number of child nodes that match the given side
  // value.
  public virtual int side_count( NodeSide side ) {
    int count = 0;
    for( int i=0; i<children().length; i++ ) {
      if( _children.index( i ).side == side ) {
        count++;
      }
    }
    return( count );
  }

  //-------------------------------------------------------------
  // Returns the node side relative to its parent node.
  public virtual NodeSide relative_side() {
    switch( side ) {
      case NodeSide.LEFT  :
      case NodeSide.RIGHT :  return( (posy < parent.posy) ? NodeSide.TOP  : NodeSide.BOTTOM );
      default             :  return( (posx < parent.posx) ? NodeSide.LEFT : NodeSide.RIGHT );
    }
  }

  //-------------------------------------------------------------
  // Returns a reference to the node with the given ID.  If the
  // ID was not found in this node's tree, returns null.
  public virtual BaseNode? get_node( int id ) {
    if( _id == id ) {
      return( this );
    } else {
      for( int i=0; i<children().length; i++ ) {
        var node = children().index( i ).get_node( id );
        if( node != null ) {
          return( node );
        }
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the sibling node relative to this node.
  protected virtual BaseNode? get_sibling( int dir, bool wrap ) {
    var index = index() + dir;
    if( index < 0 ) {
      return( wrap ? parent.children().index( parent.children().length - 1 ) : null );
    } else if( index >= parent.children().length ) {
      return( wrap ? parent.children().index( 0 ) : null );
    } else {
      return( parent.children().index( index ) );
    }
  }

  //-------------------------------------------------------------
  // Returns the previous sibling node relative to this node.
  public BaseNode? previous_sibling( bool wrap = false ) {
    return( get_sibling( -1, wrap ) );
  }

  //-------------------------------------------------------------
  // Returns the previous sibling node relative to this node.
  public BaseNode? next_sibling( bool wrap = false ) {
    return( get_sibling( 1, wrap ) );
  }

  //-------------------------------------------------------------
  // LOAD
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Loads the style information from the given XML node.
  private virtual void load_style( Xml.Node* n ) {
    _style.load_node( n );
  }

  //-------------------------------------------------------------
  // Loads the child nodes.
  private void load_nodes( Xml.Node* n ) {
    var first_summary_index = -1;
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "node" :
            var node = new Node.from_xml( _map, _layout, it, false );
            node.attach( this, -1, null );
            break;
          case "summarized" :
            var node = new SummarizedNode.from_xml( _map, _layout, it );
            node.attach( this, -1, null );
            break;
          default :  break;
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Loads the file contents into this instance.
  public virtual void load( MindMap map, Xml.Node* n, bool isroot ) {

    _loaded = false;

    string? i = n->get_prop( "id" );
    if( i != null ) {
      _id = int.parse( i );
      map.next_node_id = _id;
    }

    string? x = n->get_prop( "posx" );
    if( x != null ) {
      _posx = double.parse( x );
    }

    string? y = n->get_prop( "posy" );
    if( y != null ) {
      _posy = double.parse( y );
    }

    string? w = n->get_prop( "width" );
    if( w != null ) {
      _width = double.parse( w );
    }

    string? h = n->get_prop( "height" );
    if( h != null ) {
      _height = double.parse( h );
    }

    string? s = n->get_prop( "side" );
    if( s != null ) {
      side = NodeSide.parse( s );
    }

    string? ts = n->get_prop( "treesize" );
    if( ts != null ) {
      tree_size = double.parse( ts );
    }

    // If the posx and posy values are not set, set the layout now
    if( (x == null) && (y == null) ) {
      string? l = n->get_prop( "layout" );
      if( l != null ) {
        layout = map.layouts.get_layout( l );
      }
      _loaded = true;
    }

    // Make sure the style has a default value
    style.copy( StyleInspector.styles.get_style_for_level( (isroot ? 0 : 1), null ) );

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "style" :  load_style( it );  break;
          case "nodes" :  load_nodes( it );  break;
          default      :  break;
        }
      }
    }

    _loaded = true;

    // Force the size to get re-calculated
    update_total_size();
    update_size();

    // Load the layout after the nodes are loaded if the posx/posy information is set
    if( (x != null) || (y != null) ) {
      string? l = n->get_prop( "layout" );
      if( l != null ) {
        layout = map.layouts.get_layout( l );
      }
    }

    // Get the tree bbox
    tree_bbox = layout.bbox( this, -1, "node.load" );

    if( ts == null ) {
      tree_size = side.horizontal() ? tree_bbox.height : tree_bbox.width;
    }

  }

  //-------------------------------------------------------------
  // SAVE
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Saves the current node.
  public virtual Xml.Node* save() {
    return( save_node( "node" ) );
  }

  //-------------------------------------------------------------
  // Saves the node contents to the given data output stream.
  protected virtual Xml.Node* save_node( string xml_name ) {

    Xml.Node* node = new Xml.Node( null, xml_name );
    node->new_prop( "id", _id.to_string() );
    node->new_prop( "posx", _posx.to_string() );
    node->new_prop( "posy", _posy.to_string() );
    node->new_prop( "width", _width.to_string() );
    node->new_prop( "height", _height.to_string() );
    node->new_prop( "side", side.to_string() );
    node->new_prop( "treesize", tree_size.to_string() );
    node->new_prop( "layout", _layout.name );

    style.save_node( node );

    if( _children.length > 0 ) {
      Xml.Node* nodes = new Xml.Node( null, "nodes" );
      for( int i=0; i<_children.length; i++ ) {
        var child = _children.index( i );
        nodes->add_child( child.save() );
      }
      node->add_child( nodes );
    }

    return( node );

  }

  //-------------------------------------------------------------
  // SEARCH
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Searches for a node ID matching the given node ID.  If found,
  // returns true along with the plain text title of the found node.
  public static bool xml_find( Xml.Node* n, int id, ref string name ) {

    bool found = false;

    string? i = n->get_prop( "id" );
    if( i != null ) {
      found = (int.parse( i ) == id);
    }

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "nodename" :
            if( (it->children != null) && (it->children->type == Xml.ElementType.TEXT_NODE) ) {
              name = it->children->get_content();
            } else {
              name = CanvasText.xml_text( it );
            }
            break;
          case "nodes" :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                if( xml_find( it2, id, ref name ) ) {
                  return( true );
                }
              }
            }
            break;
        }
      }
    }

    return( found );

  }

  //-------------------------------------------------------------
  // Resizes the node width by the given amount.
  public virtual void resize( double diff ) {}

  //-------------------------------------------------------------
  // LOCATION METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Returns the bounding box for this node.
  public virtual void bbox( out double x, out double y, out double w, out double h ) {
    if( is_root() || side.vertical() ) {
      x = posx;
      y = posy;
      w = _total_width;
      h = _total_height;
    } else {
      x = posx;
      y = posy;
      w = _total_width;
      h = _total_height;
    }
  }

  //-------------------------------------------------------------
  // Returns the bounding box for the node box itself (this
  // includes everything but the callout).
  public void node_bbox( out double x, out double y, out double w, out double h ) {
    x = posx;
    y = posy; 
    w = _width;
    h = _height;
  }

  //-------------------------------------------------------------
  // Returns the bounding box for the fold indicator for this node.
  public void fold_bbox( out double x, out double y, out double w, out double h ) {
    double bw, bh;
    node_bbox( out x, out y, out bw, out bh );
    w = 16;
    h = 16;
    switch( side ) {
      case NodeSide.RIGHT :
        x += bw + style.node_padding;
        y += (bh / 2) - (h / 2);
        break;
      case NodeSide.LEFT :
        x -= style.node_padding + w;
        y += (bh / 2) - (h / 2);
        break;
      case NodeSide.TOP :
        x += (bw / 2) - (w / 2);
        y -= style.node_padding + h;
        break;
      case NodeSide.BOTTOM :
        x += (bw / 2) - (w / 2);
        y += bh + style.node_padding;
        break;
    }
  }

  //-------------------------------------------------------------
  // SIZE METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Moves this node into the proper position within the parent
  // node.  Returns true if the node is moved to a new position.
  public virtual bool move_to_position( BaseNode child, NodeSide side, double x, double y ) {
    int   idx           = child.index();
    Node? last_selected = last_selected_child;
    for( int i=0; i<_children.length; i++ ) {
      if( _children.index( i ).side == child.side ) {
        switch( child.side ) {
          case NodeSide.LEFT  :
          case NodeSide.RIGHT :
            if( y < _children.index( i ).posy ) {
              child.detach( side );
              child.attached = true;
              child.attach( this, (i - ((idx < i) ? 1 : 0)), null, false );
              last_selected_child = last_selected;
              return( (i != (idx + 1)) || (child.side != side) );
            }
            break;
          case NodeSide.TOP :
          case NodeSide.BOTTOM :
            if( x < _children.index( i ).posx ) {
              child.detach( side );
              child.attached = true;
              child.attach( this, (i - ((idx < i) ? 1 : 0)), null, false );
              last_selected_child = last_selected;
              return( (i != (idx + 1)) || (child.side != side) );
            }
            break;
        }
      } else if( _children.index( i ).side > child.side ) {
        child.detach( side );
        child.attached = true;
        child.attach( this, (i - ((idx < i) ? 1 : 0)), null, false );
        last_selected_child = last_selected;
        return( (i != (idx + 1)) || (child.side != side) );
      }
    }
    child.detach( side );
    child.attached = true;
    child.attach( this, -1, null, false );
    last_selected_child = last_selected;
    return( (_children.length != (idx + 1)) || (child.side != side) );
  }

  //-------------------------------------------------------------
  // Returns this node to its original position.
  public virtual void return_to_position() {
    var orig_parent = parent;
    var orig_index  = index();
    detach( side );
    attached = true;
    attach( orig_parent, orig_index, null, false );
  }

  //-------------------------------------------------------------
  // Checks to see if the given node is a sibling node on the
  // same side.  If it is, swaps the position of the given node
  // with the given node.  Returns true if the nodes are swapped.
  public virtual void swap_with_previous_sibling() {

    var other = previous_sibling();
    if( other == null ) return;

    var other_summary = other.summary_node();
    var our_summary   = summary_node();

    detach( side );
    if( our_summary != null ) {
      our_summary.remove_node( this );
    }
    attached = true;
    attach( other.parent, other.index(), null, false );
    if( other_summary != null ) {
      other_summary.add_node( this );
    }

    parent.last_selected_child = this;

  }

  //-------------------------------------------------------------
  // Moves the node (and its tree) to be a sibling of its parent
  // located just before its parent node (side will match parent's
  // side).
  public virtual void make_parent_sibling() {

    var grandparent = parent.parent;
    var parent_idx  = parent.index();

    detach( side );
    attach( grandparent, parent_idx, null );

  }

  //-------------------------------------------------------------
  // Moves all children of the given node to the node's parent,
  // placed just before the parent node.
  public virtual void make_children_siblings() {

    var idx          = index();
    var num_children = (int)_children.length;

    for( int i=(num_children - 1); i>=0; i-- ) {
      var child = _children.index( i );
      child.detach( child.side );
      child.attach( parent, idx, null );
    }

  }

  //-------------------------------------------------------------
  // If the parent node is moved, we will move ourselves the same
  // amount.
  protected virtual void parent_moved( BaseNode parent, double diffx, double diffy ) {

    _posx += diffx;
    _posy += diffy;

    update_tree_bbox( diffx, diffy );
    moved( diffx, diffy );

  }

  //-------------------------------------------------------------
  // Detaches this node from its parent node.
  public virtual void detach( NodeSide side ) {

    if( parent != null ) {
      int idx = index();
      parent.children().remove_index( idx );
      parent.moved.disconnect( this.parent_moved );
      if( parent.last_selected_child == this ) {
        parent.last_selected_child = null;
      }
      if( layout != null ) {
        layout.handle_update_by_delete( parent, idx, side, tree_size );
      }
      parent   = null;
      attached = false;
    }

  }

  //-------------------------------------------------------------
  // Removes this node from the node tree along with all
  // descendents.
  public virtual void delete() {
    detach( side );
  }

  //-------------------------------------------------------------
  // Removes only this node from its parent, attaching all
  // children nodes of this node to the parent.  If the parent
  // node does not exist (i.e., this node is a root node, the
  // children nodes will become top-level nodes themselves.
  public virtual void delete_only() {
    if( parent == null ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).parent   = null;
        _children.index( i ).attached = false;
        _map.get_nodes().append_val( _children.index( i ) );
      }
      _map.model.remove_root_node( this );
    } else {
      int idx = index();
      parent.children().remove_index( idx );
      parent.moved.disconnect( this.parent_moved );
      if( parent.last_selected_child == this ) {
        parent.last_selected_child = null;
      }
      if( layout != null ) {
        layout.handle_update_by_delete( parent, idx, side, tree_size );
      }
      attached = false;
      for( int i=(int)(_children.length - 1); i>=0; i-- ) {
        moved.disconnect( _children.index( i ).parent_moved );
        _children.index( i ).attach( parent, idx, null, false );
      }
      parent = null;
    }
  }

  //-------------------------------------------------------------
  // Undoes a delete_only call by reattaching this node to the
  // given parent.
  public virtual void attach_only( BaseNode? prev_parent, int prev_index ) {
    var temp = new Array<BaseNode>();
    for( int i=(int)(children().length - 1); i>=0; i-- ) {
      var child = children().index( i );
      if( child.is_root() ) {
        _map.model.remove_root_node( child );
      } else {
        child.detach( child.side );
      }
      temp.prepend_val( child );
    }
    children().remove_range( 0, children().length );
    if( index() == -1 ) {
      if( prev_parent == null ) {
        _map.model.position_root_node( this );
        _map.model.add_root( this, prev_index );
      } else {
        attach_init( prev_parent, prev_index );
      }
    }
    attached = true;
    for( int i=0; i<temp.length; i++ ) {
      var child = temp.index( i );
      child.attach_init( this, -1 );
    }
  }

  //-------------------------------------------------------------
  // Attaches this node as a child of the given node.
  public virtual void attach( BaseNode parent, int idx, Theme? theme, bool set_side = true ) {
    this.parent = parent;
    layout = parent.layout;
    if( layout != null ) {
      if( set_side ) {
        if( parent.is_root() ) {
          if( parent.children().length == 0 ) {
            side = layout.side_mapping( side );
          } else {
            side = parent.children().index( parent.children().length - 1 ).side;
          }
        } else {
          side = parent.side;
        }
        layout.propagate_side( this, side );
      }
      layout.initialize( this );
    }
    attach_common( idx, theme );
  }

  //-------------------------------------------------------------
  // Attachment method to use when node side is known and does not
  // need to be calculated.
  public virtual void attach_init( BaseNode parent, int index ) {
    this.parent = parent;
    layout = parent.layout;
    attach_common( index, null );
  }

  //-------------------------------------------------------------
  // Common attachment code that is called by the higher-level attachment
  // methods.
  protected virtual void attach_common( int index, Theme? theme ) {
    if( index == -1 ) {
      index = (int)this.parent.children().length;
      parent.children().append_val( this );
    } else {
      parent.children().insert_val( index, this );
    }
    parent.moved.connect( this.parent_moved );
    if( layout != null ) {
      layout.handle_update_by_insert( parent, this, index );
    }
    attached = true;
  }

  //-------------------------------------------------------------
  // Returns a reference to the first child of this node.
  public virtual BaseNode? first_child( NodeSide? side = null ) {
    for( int i=0; i<_children.length; i++ ) {
      if( (side == null) || (_children.index( i ).side == side) ) {
        return( _children.index( i ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns a reference to the last child of this node.
  public virtual BaseNode? last_child( NodeSide? side = null ) {
    for( int i=((int)_children.length - 1); i>=0; i-- ) {
      if( (side == null) || (_children.index( i ).side == side) ) {
        return( _children.index( i ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns a reference to the next child after the specified
  // child of this node.
  public virtual BaseNode? next_child( BaseNode n, bool wrap = false ) {
    int idx = n.index();
    if( idx == -1 ) {
      return( null );
    } else if( (idx + 1) < _children.length ) {
      return( _children.index( idx + 1 ) );
    } else {
      return( wrap ? _children.index( 0 ) : null );
    }
  }

  //-------------------------------------------------------------
  // Returns a reference to the next child after the specified
  // child of this node.
  public virtual BaseNode? prev_child( BaseNode n, bool wrap = false ) {
    int idx = n.index();
    if( idx == -1 ) {
      return( null );
    } else if( idx > 0 ) {
      return( _children.index( idx - 1 ) );
    } else {
      return( wrap ? _children.index( _children.length - 1 ) : null );
    }
  }

  //-------------------------------------------------------------
  // MISCELLANEOUS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Populates the given ListStore with all nodes that have names
  // that match the given string pattern.
  public virtual void get_match_items( string tabname, string pattern, bool[] search_opts, ref GLib.ListStore matches ) {
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).get_match_items( tabname, pattern, search_opts, ref matches );
    }
  }

  //-------------------------------------------------------------
  // Called when the theme is changed by the user.  Looks up this
  // node's link color in the old theme to see if it is a themed
  // color.  If it is, map it to the new theme's color palette.
  // If the current color is not a theme link color, keep the
  // current color as it was custom set by the user.  Performs
  // this mapping recursively for all descendants.
  public virtual void update_theme_colors( Theme old_theme, Theme new_theme ) {
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).update_theme_colors( old_theme, new_theme );
    }
  }

  //-------------------------------------------------------------
  // Gathers the information from all stored nodes for positional
  // and link color information.  This information is used by the
  // undo/redo functions.
  public virtual void get_node_info( ref Array<NodeInfo?> info ) {
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).get_node_info( ref info );
    }
  }

  //-------------------------------------------------------------
  // Restores the give information in the node info array to the
  // node and subnodes.
  public virtual void set_node_info( Array<NodeInfo?> info, ref int index ) {

    var diffx = info.index( index ).posx - _posx;
    var diffy = info.index( index ).posy - _posy;

    _posx = info.index( index ).posx;
    _posy = info.index( index ).posy;
    side  = info.index( index ).side;

    update_tree_bbox( diffx, diffy );

    for( int i=0; i<_children.length; i++ ) {
      index++;
      _children.index( i ).set_node_info( info, ref index );
    }

  }

  //-------------------------------------------------------------
  // DRAWING
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Returns the link point for this node.
  protected virtual void link_point( out double x, out double y, bool seq = false ) {
    if( is_root() ) {
      x = posx + (_width / 2);
      y = posy + (_height / 2);
    } else if( seq ) {
      int margin  = style.node_margin;
      int padding = style.node_padding;
      switch( side ) {
        case NodeSide.LEFT :
          x = posx + _total_width - margin - padding;
          y = posy + _total_height - margin;
          break;
        case NodeSide.RIGHT :
          x = posx + margin + padding;
          y = posy + _total_height - margin;
          break;
        default :
          if( (side == NodeSide.BOTTOM) && (style.node_border.name() != "underlined") ) {
            x = posx + _total_width - margin;
            y = posy + margin + padding;
          } else {
            x = posx + _total_width - margin;
            y = posy + _total_height - margin - padding;
          }
          break;
      }
    } else {
      int    margin = style.node_margin;
      double height = (style.node_border.name() == "underlined") ? (_height - margin) : (_height / 2);
      switch( side ) {
        case NodeSide.LEFT :
          x = posx + margin;
          y = posy + height;
          break;
        case NodeSide.TOP :
          x = posx + (_width / 2);
          y = posy + margin;
          break;
        case NodeSide.RIGHT :
          x = posx + _total_width - margin;
          y = posy + height;
          break;
        default :
          x = posx + (_width / 2);
          y = posy + _total_height - margin;
          break;
      }
    }
  }

  //-------------------------------------------------------------
  // Draws the attachable highlight border to indicate when a
  // node is attachable.
  protected virtual void draw_attachable( Context ctx, Theme theme, RGBA? frost_background ) {

    if( mode.attachable() ) {

      double x, y, w, h;
      node_bbox( out x, out y, out w, out h );

      // Draw highlight border
      ctx.save();
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "attachable" ), _alpha );
      ctx.set_line_width( 4 );
      if( mode.is_marked() ) {
        ctx.set_dash( {5, 10}, 0 );
      }
      ctx.rectangle( x, y, w, h );
      ctx.stroke();
      ctx.restore();

    }

  }

  //-------------------------------------------------------------
  // Draw the node resizer area.
  protected virtual void draw_resizer( Context ctx, Theme theme, bool exporting ) {

    // Only draw the resizer if we are the current node
    if( ((mode != NodeMode.CURRENT) && (mode != NodeMode.HIGHLIGHTED)) || exporting ) {
      return;
    }

    double x, y, w, h;
    resizer_bbox( out x, out y, out w, out h );

    Utils.set_context_color( ctx, theme.get_color( "background" ) );
    ctx.set_line_width( 1 );
    ctx.rectangle( x, y, w, h );
    ctx.fill_preserve();

    Utils.set_context_color_with_alpha( ctx, theme.get_color( "foreground" ), _alpha );
    ctx.stroke();

  }

  //-------------------------------------------------------------
  // Draws the node on the screen.
  public virtual void draw( Context ctx, Theme theme, bool motion, bool exporting ) {}

  //-------------------------------------------------------------
  // Draw this node and all child nodes.
  public virtual void draw_all( Context ctx, Theme theme, BaseNode? current, bool motion, bool exporting ) {
    if( this != current ) {
      if( traversable() ) {
        for( int i=0; i<_children.length; i++ ) {
          _children.index( i ).draw_all( ctx, theme, current, motion, exporting );
        }
      }
      draw( ctx, theme, motion, exporting );
    }
  }

  //-------------------------------------------------------------
  // Outputs the node's information to standard output.
  public virtual void display( bool recursive = false, string prefix = "" ) {
    if( recursive ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).display( recursive, prefix + "  " );
      }
    }
  }

}
