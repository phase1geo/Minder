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
using Gee;

/* Enumeration describing the different modes a node can be in */
public enum NodeMode {
  NONE = 0,   // Specifies that this node is not the current node
  CURRENT,    // Specifies that this node is the current node and is not being edited
  SELECTED,   // Specifies that this node is one of several selected nodes
  EDITABLE,   // Specifies that this node's text has been and currently is actively being edited
  ATTACHABLE, // Specifies that this node is the currently attachable node (affects display)
  DROPPABLE   // Specifies that this node can receive a dropped item
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
  public bool overlaps( NodeBounds other ) {
    return( ((x < (other.x + other.width))  && ((x + width) > other.x)) ||
            ((y < (other.y + other.height)) && ((y + height) > other.y)) );
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

public struct NodeLinkInfo {
  string id_str;
  Node   node;
  public NodeLinkInfo( string id, Node n ) {
    id_str = id;
    node   = n;
  }
}

public class Node : Object {

  private static int _next_id = 0;

  /* Member variables */
  private   DrawArea     _da;
  protected int          _id;
  protected int          _id_file;
  private   CanvasText   _name;
  private   string       _note         = "";
  protected double       _width        = 0;
  protected double       _height       = 0;
  protected double       _ipadx        = 6;
  protected double       _ipady        = 3;
  protected double       _task_radius  = 5;
  protected double       _alpha        = 1.0;
  protected Array<Node>  _children;
  private   NodeMode     _mode         = NodeMode.NONE;
  private   int          _task_count   = 0;
  private   int          _task_done    = 0;
  private   double       _posx         = 0;
  private   double       _posy         = 0;
  private   RGBA         _link_color;
  private   bool         _link_color_set  = false;
  private   bool         _link_color_root = false;
  private   double       _min_width      = 50;
  private   NodeImage?   _image          = null;
  private   Layout?      _layout         = null;
  private   Style        _style          = new Style();
  private   bool         _loaded         = true;
  private   Node         _linked_node    = null;
  private   string?      _sticker        = null;
  private   Pixbuf?      _sticker_buf    = null;

  /* Node signals */
  public signal void moved( double diffx, double diffy );
  public signal void resized( double diffw, double diffh );

  /* Properties */
  public DrawArea da {
    get {
      return( _da );
    }
  }
  public CanvasText name {
    get {
      return( _name );
    }
    set {
      _name = value;
    }
  }
  public double posx {
    get {
      return( _posx );
    }
    set {
      double diff = (value - _posx);
      _posx = value;
      update_tree_bbox( diff, 0 );
      position_name();
      if( diff != 0 ) {
        moved( diff, 0 );
      }
    }
  }
  public double posy {
    get {
      return( _posy );
    }
    set {
      double diff = (value - _posy);
      _posy = value;
      update_tree_bbox( 0, diff );
      position_name();
      if( diff != 0 ) {
        moved( 0, diff );
      }
    }
  }
  public string note {
    get {
      return( _note );
    }
    set {
      if( _note != value ) {
        _note = value;
        update_size();
      }
    }
  }
  public NodeMode mode {
    get {
      return( _mode );
    }
    set {
      if( _mode != value ) {
        if( _mode == NodeMode.EDITABLE ) {
          if( _da.settings.get_boolean( "auto-parse-embedded-urls" ) ) {
            // TBD - _urls.parse_embedded_urls( name );
          }
        }
        _mode = value;
        if( _mode == NodeMode.EDITABLE ) {
          name.edit = true;
          name.set_cursor_all( false );
        } else {
          name.edit = false;
          name.clear_selection();
        }
      }
    }
  }
  public Node?    parent     { get; protected set; default = null; }
  public NodeSide side       { get; set; default = NodeSide.RIGHT; }
  public bool     folded     { get; set; default = false; }
  public double   tree_size  { get; set; default = 0; }
  public bool     group      { get; set; default = false; }
  public RGBA     link_color {
    get {
      return( _link_color );
    }
    set {
      if( !is_root() ) {
        _link_color      = value;
        _link_color_set  = true;
        _link_color_root = true;
        for( int i=0; i<_children.length; i++ ) {
          _children.index( i ).link_color_child = value;
        }
      }
    }
  }
  public RGBA     link_color_only {
    set {
      _link_color     = value;
      _link_color_set = true;
    }
  }
  private RGBA    link_color_child {
    set {
      if( !link_color_root ) {
        _link_color     = value;
        _link_color_set = true;
        for( int i=0; i<_children.length; i++ ) {
          _children.index( i ).link_color_child = value;
        }
      }
    }
  }
  public bool     link_color_root {
    get {
      return( _link_color_root );
    }
    set {
      if( (_link_color_root != value) && !is_root() ) {
        _link_color_root = value;
        if( !_link_color_root ) {
          link_color_child = parent.link_color;
        }
      }
    }
  }
  public bool     attached   { get; set; default = false; }
  public Style    style {
    get {
      return( _style );
    }
    set {
      var branch_margin = style.branch_margin;
      if( _style.copy( value ) ) {
        name.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
        name.max_width = style.node_width;
        if( branch_margin != style.branch_margin ) {
          for( int i=0; i<_children.length; i++ ) {
            _layout.apply_margin( _children.index( i ) );
          }
        }
        position_name();
      }
    }
  }
  public Layout?  layout {
    get {
      return( _layout );
    }
    set {
      _layout = value;
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).layout = value;
      }
    }
  }
  public Node?       last_selected_child      { get; set; default = null; }
  public Connection? last_selected_connection { get; set; default = null; }
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
  public NodeImage? image {
    get {
      return( _image );
    }
  }
  public double alpha {
    get {
      return( _alpha );
    }
    set {
      _alpha = value;
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).alpha = value;
      }
    }
  }
  public Node? linked_node {
    get {
      return( _linked_node );
    }
    set {
      _linked_node = value;
      update_size();
    }
  }
  public NodeBounds tree_bbox { get; set; default = NodeBounds(); }
  public int task_count {
    get {
      return( _task_count );
    }
  }
  public int done_count {
    get {
      return( _task_done );
    }
  }
  public string? sticker {
    get {
      return( _sticker );
    }
    set {
      if( _sticker != value ) {
        _sticker = value;
        if( _sticker != null ) {
          _sticker_buf = new Pixbuf.from_resource( "/com/github/phase1geo/minder/" + _sticker );
        } else {
          _sticker_buf = null;
        }
        position_name_and_update_size();
      }
    }
  }

  /* Default constructor */
  public Node( DrawArea da, Layout? layout ) {
    _da       = da;
    _id       = _next_id++;
    _children = new Array<Node>();
    _layout   = layout;
    _name     = new CanvasText( da );
    _name.resized.connect( position_name_and_update_size );
    set_parsers();
  }

  /* Constructor initializing string */
  public Node.with_name( DrawArea da, string n, Layout? layout ) {
    _da       = da;
    _id       = _next_id++;
    _children = new Array<Node>();
    _layout   = layout;
    _name     = new CanvasText.with_text( da, n );
    _name.resized.connect( position_name_and_update_size );
    set_parsers();
  }

  /* Copies an existing node to this node */
  public Node.copy( DrawArea da, Node n, ImageManager im ) {
    _da       = da;
    _id       = _next_id++;
    _name     = new CanvasText( da );
    copy_variables( n, im );
    _name.resized.connect( position_name_and_update_size );
    set_parsers();
    mode      = NodeMode.NONE;
    _children = n._children;
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).parent = this;
    }
  }

  public Node.copy_only( DrawArea da, Node n, ImageManager im ) {
    _da = da;
    _id = _next_id++;
    _name = new CanvasText( da );
    copy_variables( n, im );
  }

  /* Copies an existing node tree to this node */
  public Node.copy_tree( DrawArea da, Node n, ImageManager im, HashMap<int,int> id_map ) {
    _da       = da;
    _id       = _next_id++;
    _name     = new CanvasText( da );
    _children = new Array<Node>();
    copy_variables( n, im );
    _name.resized.connect( position_name_and_update_size );
    set_parsers();
    mode      = NodeMode.NONE;
    tree_size = n.tree_size;
    id_map.set( n._id, _id );
    for( int i=0; i<n._children.length; i++ ) {
      Node child = new Node.copy_tree( da, n._children.index( i ), im, id_map );
      child.parent = this;
      _children.append_val( child );
    }
  }

  /* Adds the valid parsers */
  public void set_parsers() {
    _name.text.add_parser( _da.markdown_parser );
    // _name.text.add_parser( _da.tagger_parser );
    _name.text.add_parser( _da.url_parser );
  }

  /* Resets the ID generator.  This should be called whenever a new document is started. */
  public static void reset() {
    _next_id = 0;
  }

  /* Copies just the variables of the node, minus the children nodes */
  public void copy_variables( Node n, ImageManager im ) {
    _width          = n._width;
    _height         = n._height;
    _task_radius    = n._task_radius;
    _alpha          = n._alpha;
    _task_count     = n._task_count;
    _task_done      = n._task_done;
    _layout         = n._layout;
    _posx           = n._posx;
    _posy           = n._posy;
    _image          = (n._image == null) ? null : new NodeImage.from_node_image( im, n._image, n.style.node_width );
    _name.copy( n._name );
    _link_color      = n._link_color;
    _link_color_set  = n._link_color_set;
    _link_color_root = n._link_color_root;
    folded           = n.folded;
    note             = n.note;
    mode             = n.mode;
    parent           = n.parent;
    side             = n.side;
    style            = n.style;
    tree_bbox        = n.tree_bbox;
  }

  /* Returns the associated ID of this node */
  public int id() {
    return( _id );
  }

  /* Sets the posx value only, leaving the children positions alone */
  public void set_posx_only( double value ) {
    var diff = value - _posx;
    _posx = value;
    update_tree_bbox( diff, 0 );
    position_name();
  }

  /* Sets the posy value only, leaving the children positions alone */
  public void set_posy_only( double value ) {
    var diff = value - _posy;
    _posy = value;
    update_tree_bbox( 0, diff );
    position_name();
  }

  /* Sets the alpha value without propagating this to the children */
  public void set_alpha_only( double value ) {
    _alpha = value;
  }

  /* Updates the alpha value if it is not set to 1.0 */
  public void update_alpha( double value ) {
    if( _alpha < 1.0 ) {
      _alpha = value;
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).update_alpha( value );
    }
  }

  /* Sets the posx value only, leaving the children positions alone */
  public void adjust_posx_only( double value ) {
    _posx += value;
    update_tree_bbox( value, 0 );
    position_name();
  }

  /* Sets the posy value only, leaving the children positions alone */
  public void adjust_posy_only( double value ) {
    _posy += value;
    update_tree_bbox( 0, value );
    position_name();
  }

  /* Updates the tree_bbox */
  private void update_tree_bbox( double diffx, double diffy ) {
    var nb = tree_bbox;
    nb.x += diffx;
    nb.y += diffy;
    tree_bbox = nb;
  }

  /* Called whenever the canvas text is resized */
  private void position_name_and_update_size() {
    position_name();
    update_size();
  }

  /* Called whenever the node size is changed */
  private void update_size() {
    if( !_loaded ) return;
    var orig_width  = _width;
    var orig_height = _height;
    var margin      = (style.node_margin  == null) ? 0 : style.node_margin;
    var padding     = (style.node_padding == null) ? 0 : style.node_padding;
    var stk_height  = sticker_height();
    var name_width  = task_width() + sticker_width() + _name.width + note_width() + linked_node_width();
    var name_height = (_name.height < stk_height) ? stk_height : _name.height;
    if( _image != null ) {
      _width  = (margin * 2) + (padding * 2) + ((name_width < _image.width) ? _image.width : name_width);
      _height = (margin * 2) + (padding * 2) + _image.height + padding + name_height;
    } else {
      _width  = (margin * 2) + (padding * 2) + name_width;
      _height = (margin * 2) + (padding * 2) + name_height;
    }
    if( (_layout != null) && (((_width - orig_width) != 0) || ((_height - orig_height) != 0)) ) {
      _layout.handle_update_by_edit( this, (_width - orig_width), (_height - orig_height) );
    }
  }

  /* Sets the node image to the given value, updating the image manager accordingly. */
  public void set_image( ImageManager im, NodeImage? ni ) {
    if( _image != null ) {
      im.set_valid( _image.id, false );
    }
    if( ni != null ) {
      im.set_valid( ni.id, true );
    }
    _image = ni;
    update_size();
  }

  /* Get the level of this node */
  public uint get_level() {
    Node p     = parent;
    uint level = 0;
    while( p != null ) {
      level++;
      p = p.parent;
    }
    return( level );
  }

  /* Returns true if the node does not have a parent */
  public bool is_root() {
    return( parent == null );
  }

  /* Returns true if this node exists within a group */
  public bool is_grouped() {
    var node = this;
    while( node != null ) {
      if( node.group ) {
        return( true );
      }
      node = node.parent;
    }
    return( false );
  }

  /* Returns the number of groups betwen the current node and the specified ancestor node */
  public int groups_between( Node node ) {
    var curr  = this;
    var count = 0;
    while( !curr.is_root() && (curr != node) ) {
      count += curr.group ? 1 : 0;
      curr = curr.parent;
    }
    return( count );
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

  /* Returns true if this task node is complete */
  public bool is_task_done() {
    return( _task_count == _task_done );
  }

  /* Returns true if this node is a descendant of the given node */
  public bool is_descendant_of( Node node ) {
    Node p = parent;
    while( (p != null) && (p != node) ) {
      p = p.parent;
    }
    return( p == node );
  }

  /* Returns true if this tree bounds of this node is left of the given bounds */
  public bool is_left_of( NodeBounds nb ) {
    return( (tree_bbox.x + tree_bbox.width) < nb.x );
  }

  /* Returns true if this tree bounds of this node is right of the given bounds */
  public bool is_right_of( NodeBounds nb ) {
    return( tree_bbox.x > (nb.x + nb.width) );
  }

  /* Returns true if this tree bounds of this node is above the given bounds */
  public bool is_above( NodeBounds nb ) {
    return( (tree_bbox.y + tree_bbox.height) < nb.y );
  }

  /* Returns true if this tree bounds of this node is below the given bounds */
  public bool is_below( NodeBounds nb ) {
    return( tree_bbox.y > (nb.y + nb.height) );
  }

  /* Returns the task completion percentage value */
  public double task_completion_percentage() {
    return( (_task_done / (_task_count * 1.0)) * 100 );
  }

  /* Returns true if the resizer should be in the upper left */
  private bool resizer_on_left() {
    return( !is_root() && (side == NodeSide.LEFT) );
  }

  /* Returns true if the given cursor coordinates lies within this node */
  public virtual bool is_within( double x, double y ) {
    double margin = style.node_margin ?? 0;
    double cx, cy, cw, ch;
    bbox( out cx, out cy, out cw, out ch );
    cx += margin;
    cy += margin;
    cw -= margin * 2;
    ch -= margin * 2;
    return( Utils.is_within_bounds( x, y, cx, cy, cw, ch ) );
  }

  /* Returns the positional information for where the task item is located (if it exists) */
  protected virtual void task_bbox( out double x, out double y, out double w, out double h ) {
    int    margin     = style.node_margin  ?? 0;
    int    padding    = style.node_padding ?? 0;
    double img_height = (_image == null) ? 0 : (_image.height + padding);
    x = posx + margin + padding;
    y = posy + margin + padding + img_height + (((_height - (img_height + (padding * 2) + (margin * 2))) / 2) - _task_radius);
    w = _task_radius * 2;
    h = _task_radius * 2;
  }

  protected virtual void sticker_bbox( out double x, out double y, out double w, out double h ) {
    int    margin     = style.node_margin  ?? 0;
    int    padding    = style.node_padding ?? 0;
    double img_height = (_image == null) ? 0 : (_image.height + padding);
    double stk_height = (_sticker_buf == null) ? 0 : _sticker_buf.height;
    x = posx + margin + padding + task_width();
    y = posy + margin + padding + img_height + ((_height - (img_height + (padding * 2) + (margin + 2))) / 2) - (stk_height / 2);
    w = (_sticker_buf == null) ? 0 : _sticker_buf.width;
    h = (_sticker_buf == null) ? 0 : _sticker_buf.height;
  }

  protected virtual void linked_node_bbox( out double x, out double y, out double w, out double h ) {
    int    margin     = style.node_margin  ?? 0;
    int    padding    = style.node_padding ?? 0;
    double img_height = (_image == null) ? 0 : (_image.height + padding);
    x = posx + (_width - (linked_node_width() + padding + margin)) + _ipadx;
    y = posy + padding + margin + img_height + ((_height - (img_height + (padding * 2) + (margin * 2))) / 2) - 5;
    w = 11;
    h = 11;
  }

  /* Returns the positional information for where the note item is located (if it exists) */
  protected virtual void note_bbox( out double x, out double y, out double w, out double h ) {
    int    margin     = style.node_margin  ?? 0;
    int    padding    = style.node_padding ?? 0;
    double img_height = (_image == null) ? 0 : (_image.height + padding);
    x = posx + (_width - (note_width() + linked_node_width() + padding + margin)) + _ipadx;
    y = posy + padding + margin + img_height + ((_height - (img_height + (padding * 2) + (margin * 2))) / 2) - 5;
    w = 11;
    h = 11;
  }

  /* Returns the positional information of the stored image (if no image exists, the behavior of this method is undefined) */
  protected virtual void image_bbox( out double x, out double y, out double w, out double h ) {
    int margin  = style.node_margin  ?? 0;
    int padding = style.node_padding ?? 0;
    x = posx + padding + margin;
    y = posy + padding + margin;
    w = (_image == null) ? 0 : _image.width;
    h = (_image == null) ? 0 : _image.height;
  }

  /* Returns the positional information for where the resizer box is located (if it exists) */
  protected virtual void resizer_bbox( out double x, out double y, out double w, out double h ) {
    int margin  = style.node_margin  ?? 0;
    x = resizer_on_left() ? (posx + margin) : (posx + _width - margin - 8);
    y = posy + margin;
    w = 8;
    h = 8;
  }

  /*
   Returns true if the given cursor coordinates lies within the task checkbutton
   area.
  */
  public virtual bool is_within_task( double x, double y ) {
    if( _task_count > 0 ) {
      double tx, ty, tw, th;
      task_bbox( out tx, out ty, out tw, out th );
      return( Utils.is_within_bounds( x, y, tx, ty, tw, th ) );
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
      note_bbox( out nx, out ny, out nw, out nh );
      return( Utils.is_within_bounds( x, y, nx, ny, nw, nh ) );
    } else {
      return( false );
    }
  }

  public virtual bool is_within_linked_node( double x, double y ) {
    if( linked_node != null ) {
      double lx, ly, lw, lh;
      linked_node_bbox( out lx, out ly, out lw, out lh );
      return( Utils.is_within_bounds( x, y, lx, ly, lw, lh ) );
    } else {
      return( false );
    }
  }

  /* Returns true if the given cursor coordinates lie within the fold indicator area */
  public virtual bool is_within_fold( double x, double y ) {
    if( folded && (_children.length > 0) ) {
      double fx, fy, fw, fh;
      fold_bbox( out fx, out fy, out fw, out fh );
      return( Utils.is_within_bounds( x, y, fx, fy, fw, fh ) );
    } else {
      return( false );
    }
  }

  /* Returns true if the given cursor coordinates lie within the image area */
  public virtual bool is_within_image( double x, double y ) {
    if( _image != null ) {
      double ix, iy, iw, ih;
      image_bbox( out ix, out iy, out iw, out ih );
      return( Utils.is_within_bounds( x, y, ix, iy, iw, ih ) );
    } else {
      return( false );
    }
  }

  /* Returns true if the given cursor coordinates lie within the resizer area */
  public virtual bool is_within_resizer( double x, double y ) {
    if( mode == NodeMode.CURRENT ) {
      double rx, ry, rw, rh;
      resizer_bbox( out rx, out ry, out rw, out rh );
      return( Utils.is_within_bounds( x, y, rx, ry, rw, rh ) );
    }
    return( false );
  }

  /* Finds the node which contains the given pixel coordinates */
  public virtual Node? contains( double x, double y, Node? n ) {
    if( (this != n) && (is_within( x, y ) || is_within_fold( x, y )) ) {
      return( this );
    } else if( !folded ) {
      for( int i=0; i<_children.length; i++ ) {
        Node tmp = _children.index( i ).contains( x, y, n );
        if( tmp != null ) {
          return( tmp );
        }
      }
    }
    return( null );
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

  /* Returns true if the given box intersects with this node box */
  public bool intersects_with( Gdk.Rectangle box ) {
    Gdk.Rectangle node_box = { (int)posx, (int)posy, (int)width, (int)height };
    return( box.intersect( node_box, null ) );
  }

  /* Adds all nodes within this tree that intersect with the given box */
  public void select_within_box( Gdk.Rectangle box, Selection select ) {
    if( intersects_with( box ) ) {
      select.add_node( this );
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).select_within_box( box, select );
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

  /* Returns the node side relative to its parent node */
  public NodeSide relative_side() {
    switch( side ) {
      case NodeSide.LEFT  :
      case NodeSide.RIGHT :  return( (posy < parent.posy) ? NodeSide.TOP  : NodeSide.BOTTOM );
      default             :  return( (posx < parent.posx) ? NodeSide.LEFT : NodeSide.RIGHT );
    }
  }

  /*
   Returns a reference to the node with the given ID.  If the ID was
   not found in this node's tree, returns null.
  */
  public virtual Node? get_node( int id ) {
    if( _id == id || _id_file == id ) {
      return( this );
    } else {
      for( int i=0; i<children().length; i++ ) {
        Node? node = children().index( i ).get_node( id );
        if( node != null ) {
          return( node );
        }
      }
    }
    return( null );
  }

  /* Loads the name value from the given XML node */
  private void load_name( Xml.Node* n ) {
    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      name.text.insert_text( 0, n->children->get_content() );
    } else {
      name.load( n );
    }
  }

  /* Loads the note value from the given XML node */
  private void load_note( Xml.Node* n ) {
    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      note = n->children->get_content();
    }
  }

  /* Loads the image information from the given XML node */
  private void load_image( ImageManager im, Xml.Node* n ) {
    _image = new NodeImage.from_xml( im, n, style.node_width );
    if( !_image.valid ) {
      _image = null;
      update_size();
    }
  }

  /* Loads the style information from the given XML node */
  private void load_style( Xml.Node* n ) {
    _style.load_node( n );
    _name.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
  }

  /* Loads the file contents into this instance */
  public virtual void load( DrawArea da, Xml.Node* n, bool isroot, HashMap<int,int> id_map, Array<NodeLinkInfo?> link_ids ) {

    _loaded = false;

    string? i = n->get_prop( "id" );
    if( i != null ) {
      int i_int = int.parse( i );
       _id_file = i_int;
      id_map.set( i_int, _id );
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

    string? ln = n->get_prop( "link" );
    if( ln != null ) {
      link_ids.append_val( NodeLinkInfo( ln, this ) );
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
      _link_color_set = true;
    }

    string? cr = n->get_prop( "colorroot" );
    if( cr != null ) {
      _link_color_root = bool.parse( cr );
    }

    string? sk = n->get_prop( "sticker" );
    if( sk != null ) {
      sticker = sk;
    }

    string? g = n->get_prop( "group" );
    if( g != null ) {
      group = bool.parse( g );
    }

    /* If the posx and posy values are not set, set the layout now */
    if( (x == null) && (y == null) ) {
      string? l = n->get_prop( "layout" );
      if( l != null ) {
        layout = da.layouts.get_layout( l );
      }
      _loaded = true;
    }

    /* Make sure the style has a default value */
    style.copy( StyleInspector.styles.get_style_for_level( (isroot ? 0 : 1), null ) );

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "nodename"   :  load_name( it );  break;
          case "nodenote"   :  load_note( it );  break;
          case "nodeimage"  :  load_image( da.image_manager, it );  break;
          case "style"      :  load_style( it );  break;
          case "nodes"      :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                var child = new Node( da, _layout );
                child.load( da, it2, false, id_map, link_ids );
                child.attach( this, -1, null );
              }
            }
            break;
        }
      }
    }

    /* Load the layout after the nodes are loaded if the posx/posy information is set */
    if( (x != null) || (y != null) ) {
      string? l = n->get_prop( "layout" );
      if( l != null ) {
        layout = da.layouts.get_layout( l );
      }
    }

    /* If a color was not specified and this node is a root node, colorize the children */
    if( isroot ) {
      for( int j=0; j<_children.length; j++ ) {
        var child = _children.index( j );
        if( !child._link_color_set ) {
          child.link_color_child = da.get_theme().next_color();
        }
      }
    }

    /* Get the tree bbox */
    tree_bbox = layout.bbox( this, -1 );

    if( ts == null ) {
      tree_size = ((side & NodeSide.horizontal()) != 0) ? tree_bbox.height : tree_bbox.width;
    }

    /* Make sure that the name is positioned properly */
    position_name();

    _loaded = true;

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
    if( is_task() ) {
      node->new_prop( "task", _task_done.to_string() );
    }
    if( _linked_node != null ) {
      node->new_prop( "link", _linked_node.id().to_string() );
    }
    node->new_prop( "side", side.to_string() );
    node->new_prop( "fold", folded.to_string() );
    node->new_prop( "treesize", tree_size.to_string() );
    if( !is_root() ) {
      node->new_prop( "color", Utils.color_from_rgba( _link_color ) );
      node->new_prop( "colorroot", link_color_root.to_string() );
    }
    node->new_prop( "layout", _layout.name );
    if( _sticker != null ) {
      node->new_prop( "sticker", _sticker );
    }
    node->new_prop( "group", group.to_string() );

    style.save_node( node );

    if( _image != null ) {
      _image.save( node );
    }

    node->add_child( name.save( "nodename" ) );
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
  public void import_opml( DrawArea da, Xml.Node* parent, int node_id, ref Array<int>? expand_state, Theme theme ) {

    /* Get the node name */
    string? n = parent->get_prop( "text" );
    if( n != null ) {
      name.text.insert_text( 0, n );
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

    /* Load the style */
    style.copy( StyleInspector.styles.get_global_style() );

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
        child.import_opml( da, it2, node_id, ref expand_state, theme );
        child.attach( this, -1, theme );
      }
    }

    /* Calculate the tree size */
    tree_bbox = layout.bbox( this, -1 );
    tree_size = ((side & NodeSide.horizontal()) != 0) ? tree_bbox.height : tree_bbox.width;

  }

  /* Main method to export a node tree as OPML */
  public void export_opml( Xml.Node* parent, ref int node_id, ref Array<int> expand_state ) {
    parent->add_child( export_opml_node( ref node_id, ref expand_state ) );
  }

  /* Traverses the node tree exporting XML nodes in OPML format */
  private Xml.Node* export_opml_node( ref int node_id, ref Array<int> expand_state ) {
    Xml.Node* node = new Xml.Node( null, "outline" );
    node->new_prop( "text", name.text.text );
    if( is_task() ) {
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

  /* Resizes the node width by the given amount */
  public virtual void resize( double diff ) {
    diff = resizer_on_left() ? (0 - diff) : diff;
    if( _image == null ) {
      if( (diff < 0) ? ((style.node_width + diff) <= _min_width) : !_name.is_wrapped() ) return;
      style.node_width += (int)diff;
    } else {
      if( (style.node_width + diff) < _min_width ) return;
      style.node_width += (int)diff;
      _image.set_width( (int)style.node_width );
    }
    _name.resize( diff );
  }

  /* Returns the bounding box for this node */
  public virtual void bbox( out double x, out double y, out double w, out double h ) {
    if( is_root() || ((side & NodeSide.vertical()) != 0) ) {
      x = posx;
      y = posy;
      w = _width;
      h = _height;
    } else {
      x = posx;
      y = posy;
      w = _width;
      h = _height;
    }
  }

  /* Returns the bounding box for the fold indicator for this node */
  public void fold_bbox( out double x, out double y, out double w, out double h ) {
    double bw, bh;
    bbox( out x, out y, out bw, out bh );
    w = 16;
    h = 10;
    switch( side ) {
      case NodeSide.RIGHT :
        x += bw + style.node_padding;
        y += (bh / 2) - 5;
        break;
      case NodeSide.LEFT :
        x -= style.node_padding + w;
        y += (bh / 2) - 5;
        break;
      case NodeSide.TOP :
        x += (bw / 2) - 8;
        y -= style.node_padding + h;
        break;
      case NodeSide.BOTTOM :
        x += (bw / 2) - 8;
        y += bh + style.node_padding;
        break;
    }
  }

  /*
   Sets the fold for this node to the given value.  Appends this node to
   the changed list if the folded value changed.
  */
  public void set_fold( bool value, Array<Node>? changed = null ) {
    if( !folded && value ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).clear_tree_folds( changed );
      }
    }
    if( folded != value ) {
      folded = value;
      if( changed != null ) {
        changed.append_val( this );
      }
      layout.handle_update_by_fold( this );
    }
  }

  /*
   Sets the fold value of this node only.  This should only be used when we
   are undo'ing a fold operation.
  */
  public void set_fold_only( bool value ) {
    folded = value;
    layout.handle_update_by_fold( this );
  }

  /* Clears all of the folds below the current node */
  private void clear_tree_folds( Array<Node>? changed ) {
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).clear_tree_folds( changed );
    }
    if( folded ) {
      folded = false;
      if( changed != null ) {
        changed.append_val( this );
      }
      layout.handle_update_by_fold( this );
    }
  }

  /* Returns true if there is at least one node that is foldable due to its tasks being completed. */
  public bool completed_tasks_foldable() {
    if( !folded && (_task_count > 0) ) {
      if( _task_count == _task_done ) {
        for( int i=0; i<_children.length; i++ ) {
          if( _children.index( i ).is_leaf() && (_children.index( i )._task_done == 1) ) {
            return( true );
          }
        }
      }
      for( int i=0; i<_children.length; i++ ) {
        if( _children.index( i ).completed_tasks_foldable() ) {
          return( true );
        }
      }
    }
    return( false );
  }

  /* Returns true if any node is found to be unfoldable */
  public bool unfoldable() {
    if( folded ) {
      return( true );
    } else {
      for( int i=0; i<_children.length; i++ ) {
        if( _children.index( i ).unfoldable() ) {
          return( true );
        }
      }
    }
    return( false );
  }

  /* Recursively spans node tree folding any nodes which contain fully completed tasks */
  public void fold_completed_tasks( Array<Node> changed ) {
    if( !folded && (_task_count > 0) ) {
      if( _task_count == _task_done ) {
        for( int i=0; i<_children.length; i++ ) {
          if( _children.index( i ).is_leaf() && (_children.index( i )._task_done == 1) ) {
            set_fold( true, changed );
            return;
          }
        }
      }
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).fold_completed_tasks( changed );
      }
    }
  }

  /* Returns the width of the sticker */
  public double sticker_width() {
    return( (_sticker_buf != null) ? (_sticker_buf.width + _ipadx) : 0 );
  }

  /* Returns the height of the sticker */
  public double sticker_height() {
    return( (_sticker_buf != null) ? _sticker_buf.height : 0 );
  }

  /* Returns the amount of internal width to draw the task checkbutton */
  public double task_width() {
    return( (_task_count > 0) ? ((_task_radius * 2) + _ipadx) : 0 );
  }

  /* Returns the width of the note indicator */
  public double note_width() {
    return( (note.length > 0) ? (10 + _ipadx) : 0 );
  }

  /* Returns the width of the linked node indicator */
  public double linked_node_width() {
    return( (linked_node != null) ? (10 + _ipadx) : 0 );
  }

  /* Moves this node into the proper position within the parent node */
  public void move_to_position( Node child, NodeSide side, double x, double y ) {
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
              return;
            }
            break;
          case NodeSide.TOP :
          case NodeSide.BOTTOM :
            if( x < _children.index( i ).posx ) {
              child.detach( side );
              child.attached = true;
              child.attach( this, (i - ((idx < i) ? 1 : 0)), null, false );
              last_selected_child = last_selected;
              return;
            }
            break;
        }
      } else if( _children.index( i ).side > child.side ) {
        child.detach( side );
        child.attached = true;
        child.attach( this, (i - ((idx < i) ? 1 : 0)), null, false );
        last_selected_child = last_selected;
        return;
      }
    }
    child.detach( side );
    child.attached = true;
    child.attach( this, -1, null, false );
    last_selected_child = last_selected;
  }

  /*
   Checks to see if the given node is a sibling node on the same side.  If it is,
   swaps the position of the given node with the given node.  Returns true if
   the nodes are swapped.
  */
  public bool swap_with_sibling( Node? other ) {
    if( (other != null) && (other.parent == parent) ) {
      var other_index = other.index();
      var our_index   = index();
      var our_parent  = parent;
      if( (other_index + 1) == our_index ) {
        da.animator.add_nodes( da.get_nodes(), "swap_with_sibling" );
        detach( side );
        attached = true;
        attach( our_parent, other_index, null, false );
        our_parent.last_selected_child = this;
        da.undo_buffer.add_item( new UndoNodeMove( this, side, our_index ) );
        da.animator.animate();
        return( true );
      } else if( (our_index + 1) == other_index ) {
        var other_side = other.side;
        da.animator.add_nodes( da.get_nodes(), "swap_with_sibling" );
        other.detach( other_side );
        other.attached = true;
        other.attach( our_parent, our_index, null, false );
        da.undo_buffer.add_item( new UndoNodeMove( other, other_side, other_index ) );
        da.animator.animate();
        return( true );
      }
    }
    return( false );
  }

  /* Adjusts the position of the text object */
  private void position_name() {
    int margin  = (style.node_margin  == null) ? 0 : style.node_margin;
    int padding = (style.node_padding == null) ? 0 : style.node_padding;
    double stk_height = sticker_height();
    double img_height = (_image != null) ? (_image.height + padding) : 0;
    name.posx = posx + margin + padding + task_width() + sticker_width();
    name.posy = posy + margin + padding + img_height + ((name.height < stk_height) ? ((stk_height - name.height) / 2) : 0);
  }

  /* If the parent node is moved, we will move ourselves the same amount */
  private void parent_moved( Node parent, double diffx, double diffy ) {
    _posx += diffx;
    _posy += diffy;
    update_tree_bbox( diffx, diffy );
    position_name();
    moved( diffx, diffy );
  }

  /* Detaches this node from its parent node */
  public virtual void detach( NodeSide side ) {
    if( parent != null ) {
      int idx = index();
      propagate_task_info_up( (0 - _task_count), (0 - _task_done) );
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

  /* Removes this node from the node tree along with all descendents */
  public virtual void delete() {
    detach( side );
  }

  /*
   Removes only this node from its parent, attaching all children nodes of this node to the
   parent.  If the parent node does not exist (i.e., this node is a root node, the children
   nodes will become top-level nodes themselves.
  */
  public virtual void delete_only() {
    if( parent == null ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).parent   = null;
        _children.index( i ).attached = false;
        _da.get_nodes().append_val( _children.index( i ) );
      }
      _da.remove_root_node( this );
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
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).attach( parent, idx, null );
      }
    }
  }

  /* Undoes a delete_only call by reattaching this node to the given parent */
  public virtual void attach_only( Node? prev_parent, int prev_index ) {
    if( index() == -1 ) {
      attach_init( prev_parent, prev_index );
    }
    attached = true;
    var temp = new Array<Node>();
    for( int i=0; i<children().length; i++ ) {
      temp.append_val( children().index( i ) );
    }
    children().remove_range( 0, children().length );
    for( int i=0; i<temp.length; i++ ) {
      var child = temp.index( i );
      if( child.is_root() ) {
        _da.remove_root_node( child );
      } else {
        child.detach( child.side );
      }
      child.attach_init( this, i );
    }
  }

  /* Attaches this node as a child of the given node */
  public virtual void attach( Node parent, int index, Theme? theme, bool set_side = true ) {
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
    attach_common( index, theme );
  }

  public virtual void attach_init( Node parent, int index ) {
    this.parent = parent;
    layout = parent.layout;
    attach_common( index, null );
  }

  protected virtual void attach_common( int index, Theme? theme ) {
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
    parent.moved.connect( this.parent_moved );
    if( layout != null ) {
      layout.handle_update_by_insert( parent, this, index );
    }
    if( theme != null ) {
      link_color_child = main_branch() ? theme.next_color() : parent.link_color;
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
    if( enable != null ) {
      position_name();
      update_size();
    }
  }

  /* Propagates a change in the task_done for this node to all parent nodes */
  private void propagate_task_info_up( int count_adjust, int done_adjust ) {
    Node p = parent;
    while( p != null ) {
      p._task_count += count_adjust;
      p._task_done  += done_adjust;
      p.position_name();
      p.update_size();
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
   Returns the ancestor node that is folded or returns null if no ancestor nodes
   are folded.
  */
  public Node folded_ancestor() {
    var node = parent;
    while( (node != null) && !node.folded ) node = node.parent;
    return( node );
  }

  /*
   Populates the given ListStore with all nodes that have names that match
   the given string pattern.
  */
  public void get_match_items(string tabname, string pattern, bool[] search_opts, ref Gtk.ListStore matches ) {
    if( ((((_task_count == 0) || !is_leaf()) && search_opts[7]) ||
         ((_task_count != 0) && is_leaf()   && search_opts[6])) &&
        (((parent != null) && parent.folded && search_opts[4]) ||
         (((parent == null) || !parent.folded) && search_opts[5])) ) {
      if( search_opts[2] ) {
        string str = Utils.match_string( pattern, name.text.text);
        if(str.length > 0) {
          TreeIter it;
          matches.append( out it );
          matches.set( it, 0, "<b><i>%s:</i></b>".printf( _( "Node Title" ) ), 1, str, 2, this, 3, null, 4, tabname, -1 );  
        }
      }
      if( search_opts[3] ) {
        string str = Utils.match_string( pattern, note);
        if(str.length > 0) {
          TreeIter it;
          matches.append( out it );
          matches.set( it, 0, "<b><i>%s:</i></b>".printf( _( "Node Note" ) ), 1, str, 2, this, 3, null, 4, tabname, -1 );  
        }
      }
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).get_match_items(tabname, pattern, search_opts, ref matches );
    }
  }

  /* Adjusts the posx and posy values */
  public virtual void pan( double diffx, double diffy ) {
    _posx += diffx;
    _posy += diffy;
    update_tree_bbox( diffx, diffy );
    position_name();
    moved( diffx, diffy );
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
      link_color_only = new_theme.link_color( old_index );
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).map_theme_colors( old_theme, new_theme );
    }
  }

  /*
   Gathers the information from all stored nodes for positional and link color information.
   This information is used by the undo/redo functions.
  */
  public void get_node_info( ref Array<NodeInfo?> info ) {

    info.append_val( NodeInfo( _posx, _posy, side, _link_color ) );

    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).get_node_info( ref info );
    }

  }

  /*
   Restores the give information in the node info array to the node and subnodes.
  */
  public void set_node_info( Array<NodeInfo?> info, ref int index ) {

    var diffx = info.index( index ).posx - _posx;
    var diffy = info.index( index ).posy - _posy;

    _posx           = info.index( index ).posx;
    _posy           = info.index( index ).posy;
    side            = info.index( index ).side;
    link_color_only = info.index( index ).color;

    update_tree_bbox( diffx, diffy );
    position_name();

    for( int i=0; i<_children.length; i++ ) {
      index++;
      _children.index( i ).set_node_info( info, ref index );
    }

  }

  /* Returns the link point for this node */
  protected virtual void link_point( out double x, out double y ) {
    if( is_root() ) {
      x = posx + (_width / 2);
      y = posy + (_height / 2);
    } else {
      int    margin = style.node_margin ?? 0;
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
          x = posx + _width - margin;
          y = posy + height;
          break;
        default :
          x = posx + (_width / 2);
          y = posy + _height - margin;
          break;
      }
    }
  }

  /* Draws the border around the node */
  protected void draw_shape( Context ctx, Theme theme, RGBA border_color ) {

    double x = posx + style.node_margin;
    double y = posy + style.node_margin;
    double w = _width  - (style.node_margin * 2);
    double h = _height - (style.node_margin * 2);
    RGBA   group_color;

    /* Set the fill color */
    if( (mode == NodeMode.CURRENT) || (mode == NodeMode.SELECTED) ) {
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "nodesel_background" ), _alpha );
      style.draw_node_fill( ctx, x, y, w, h, side );
    } else if( is_root() || style.is_fillable() ) {
      Utils.set_context_color_with_alpha( ctx, border_color, _alpha );
      style.draw_node_fill( ctx, x, y, w, h, side );
    } else if( !is_grouped() ) {
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "background" ), _alpha );
      style.draw_node_fill( ctx, x, y, w, h, side );
    }

    if( !is_root() || style.is_fillable() ) {

      /* Draw the border */
      Utils.set_context_color_with_alpha( ctx, border_color, _alpha );
      ctx.set_line_width( style.node_borderwidth );

      /* If we are in a vertical orientation and the border type is underlined, draw nothing */
      style.draw_node_border( ctx, x, y, w, h, side );

    }

  }

  /* Draws the node image above the note */
  protected virtual void draw_image( Cairo.Context ctx, Theme theme ) {
    if( _image != null ) {
      double x, y, w, h;
      image_bbox( out x, out y, out w, out h );
      _image.draw( ctx, x, y, _alpha );
    }

  }

  /* Draws the node font to the screen */
  protected virtual void draw_name( Cairo.Context ctx, Theme theme ) {

    int hmargin = 3;
    int vmargin = 3;

    /* Draw the selection box around the text if the node is in the 'selected' state */
    if( (mode == NodeMode.CURRENT) || (mode == NodeMode.SELECTED) ) {
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "nodesel_background" ), _alpha );
      ctx.rectangle( ((posx + style.node_padding + style.node_margin) - hmargin),
                     ((posy + style.node_padding + style.node_margin) - vmargin),
                     ((_width  - (style.node_padding * 2) - (style.node_margin * 2)) + (hmargin * 2)),
                     ((_height - (style.node_padding * 2) - (style.node_margin * 2)) + (vmargin * 2)) );
      ctx.fill();
    }

    /* Draw the text */
    var color = theme.get_color( "foreground" );
    if( (mode == NodeMode.CURRENT) || (mode == NodeMode.SELECTED) ) {
      color = theme.get_color( "nodesel_foreground" );
    } else if( parent == null ) {
      color = theme.get_color( "root_foreground" );
    } else if( style.is_fillable() ) {
      color = Granite.contrasting_foreground_color( link_color );
    }

    name.draw( ctx, theme, color, _alpha, false );
  }

  /* Draws the task checkbutton for leaf nodes */
  protected virtual void draw_leaf_task( Context ctx, RGBA color ) {

    if( _task_count > 0 ) {

      double x, y, w, h;

      task_bbox( out x, out y, out w, out h );

      Utils.set_context_color_with_alpha( ctx, color, _alpha );
      ctx.new_path();
      ctx.set_line_width( 1 );
      ctx.arc( (x + _task_radius), (y + _task_radius), _task_radius, 0, (2 * Math.PI) );

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

      double x, y, w, h;
      double complete = _task_done / (_task_count * 1.0);
      double angle    = ((complete * 360) + 270) * (Math.PI / 180.0);

      task_bbox( out x, out y, out w, out h );

      x += _task_radius;
      y += _task_radius;

      /* Draw circle outline */
      if( complete < 1 ) {
        Utils.set_context_color_with_alpha( ctx, color, _alpha );
        ctx.new_path();
        ctx.set_line_width( 1 );
        ctx.arc( x, y, _task_radius, 0, (2 * Math.PI) );
        ctx.stroke();
      }

      /* Draw completeness pie */
      if( _task_done > 0 ) {
        Utils.set_context_color_with_alpha( ctx, color, _alpha );
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

  protected virtual void draw_sticker( Context ctx, RGBA sel_color, RGBA bg_color ) {

    if( _sticker_buf != null ) {

      double x, y, w, h;
      RGBA color = ((mode == NodeMode.CURRENT) || (mode == NodeMode.SELECTED)) ? sel_color : bg_color;

      sticker_bbox( out x, out y, out w, out h );

      if( _mode == NodeMode.SELECTED ) {
        Utils.set_context_color_with_alpha( ctx, color, _alpha );
        ctx.move_to( x, y );
        ctx.rectangle( x, y, w, h );
        ctx.fill();
      }

      /* Draw sticker */
      cairo_set_source_pixbuf( ctx, _sticker_buf, x, y );
      ctx.paint_with_alpha( _alpha );

    }

  }

  /* Draws the icon indicating that a note is associated with this node */
  protected virtual void draw_common_note( Context ctx, RGBA reg_color, RGBA sel_color, RGBA bg_color ) {

    if( note.length > 0 ) {

      double x, y, w, h;
      RGBA   color = ((mode == NodeMode.CURRENT) || (mode == NodeMode.SELECTED)) ? sel_color :
                     style.is_fillable()                                         ? Granite.contrasting_foreground_color( link_color )  :
                                                                                   reg_color;

      note_bbox( out x, out y, out w, out h );

      Utils.set_context_color_with_alpha( ctx, color, _alpha );
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

  protected virtual void draw_link_node( Context ctx, RGBA reg_color, RGBA sel_color, RGBA bg_color ) {

    if( linked_node != null ) {

      double x, y, w, h;
      RGBA   color = ((mode == NodeMode.CURRENT) || (mode == NodeMode.SELECTED)) ? sel_color :
                     style.is_fillable()                                         ? Granite.contrasting_foreground_color( link_color )  :
                                                                                   reg_color;

      linked_node_bbox( out x, out y, out w, out h );

      Utils.set_context_color_with_alpha( ctx, color, _alpha );
      ctx.new_path();
      ctx.set_line_width( 1 );
      ctx.move_to( x, (y + 3) );
      ctx.line_to( (x + 5), (y + 3) );
      ctx.line_to( (x + 5), (y + 1) );
      ctx.line_to( (x + 6), (y + 1) );
      ctx.line_to( (x + 10), (y + 4) );
      ctx.line_to( (x + 10), (y + 5) );
      ctx.line_to( (x + 6), (y + 8) );
      ctx.line_to( (x + 5), (y + 8) );
      ctx.line_to( (x + 5), (y + 6) );
      ctx.line_to( x, (y + 6) );
      ctx.close_path();
      ctx.fill();

    }

  }

  /* Draw the fold indicator */
  protected virtual void draw_common_fold( Context ctx, RGBA bg_color, RGBA fg_color ) {

    if( folded && (_children.length > 0) ) {

      double fx, fy, fw, fh;

      fold_bbox( out fx, out fy, out fw, out fh );

      /* Draw the fold rectangle */
      Utils.set_context_color_with_alpha( ctx, bg_color, _alpha );
      ctx.new_path();
      ctx.set_line_width( 1 );
      ctx.rectangle( fx, fy, fw, fh );
      ctx.fill();

      /* Draw circles */
      Utils.set_context_color_with_alpha( ctx, fg_color, _alpha );
      ctx.new_path();
      ctx.arc( (fx + 5), (fy + 5), 2, 0, (2 * Math.PI) );
      ctx.fill();
      ctx.new_path();
      ctx.arc( (fx + 10), (fy + 5), 2, 0, (2 * Math.PI) );
      ctx.fill();

    }

  }

  /* Draws the attachable highlight border to indicate when a node is attachable */
  protected virtual void draw_attachable( Context ctx, Theme theme, RGBA? frost_background ) {

    if( (mode == NodeMode.ATTACHABLE) || (mode == NodeMode.DROPPABLE) ) {

      double x, y, w, h;
      bbox( out x, out y, out w, out h );

      /* Draw highlight border */
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "attachable" ), _alpha );
      ctx.set_line_width( 4 );
      ctx.rectangle( x, y, w, h );
      ctx.stroke();

    }

  }

  /* Draw the link from this node to the parent node */
  protected virtual void draw_link( Context ctx, Theme theme ) {

    double parent_x;
    double parent_y;
    double height  = (style.node_border.name() == "underlined") ? (_height - style.node_margin) : (_height / 2);
    double tailx   = 0, taily = 0, tipx = 0, tipy = 0;
    double child_x = 0;
    double child_y = 0;

    /* Get the parent's link point */
    parent.link_point( out parent_x, out parent_y );

    Utils.set_context_color_with_alpha( ctx, _link_color, ((_parent.alpha != 1.0) ? _parent.alpha : _alpha) );
    ctx.set_line_cap( LineCap.ROUND );

    switch( side ) {
      case NodeSide.LEFT   :  child_x = (posx + _width - style.node_margin);  child_y = (posy + height);                       break;
      case NodeSide.RIGHT  :  child_x = (posx + style.node_margin);           child_y = (posy + height);                       break;
      case NodeSide.TOP    :  child_x = (posx + (_width / 2));                child_y = (posy + _height - style.node_margin);  break;
      case NodeSide.BOTTOM :  child_x = (posx + (_width / 2));                child_y = (posy + style.node_margin);            break;
    }

    style.draw_link( ctx, parent.style, this, parent_x, parent_y, child_x, child_y, out tailx, out taily, out tipx, out tipy );

    /* Draw the arrow */
    if( style.link_arrow ) {
      draw_link_arrow( ctx, theme, tailx, taily, tipx, tipy );
    }

  }

  /* Draws arrow point to the "to" node */
  protected virtual void draw_link_arrow( Context ctx, Theme theme, double tailx, double taily, double tipx, double tipy ) {

    double extlen[7] = {12, 12, 13, 14, 15, 16, 16};

    var arrowLength = extlen[style.link_width - 2]; // can be adjusted
    var dx = tipx - tailx;
    var dy = tipy - taily;

    var theta = Math.atan2( dy, dx );

    var rad = 35 * (Math.PI / 180);  // 35 angle, can be adjusted
    var x1  = tipx - arrowLength * Math.cos( theta + rad );
    var y1  = tipy - arrowLength * Math.sin( theta + rad );

    var phi2 = -35 * (Math.PI / 180);  // -35 angle, can be adjusted
    var x2   = tipx - arrowLength * Math.cos( theta + phi2 );
    var y2   = tipy - arrowLength * Math.sin( theta + phi2 );

    /* Draw the arrow */
    Utils.set_context_color_with_alpha( ctx, _link_color, _alpha );
    ctx.set_line_width( 1 );
    ctx.move_to( tipx, tipy );
    ctx.line_to( x1, y1 );
    ctx.line_to( x2, y2 );
    ctx.close_path();
    ctx.fill_preserve();

    Utils.set_context_color_with_alpha( ctx, theme.get_color( "background" ), _alpha );
    ctx.set_line_width( 2 );
    ctx.stroke();

  }

  /* Draw the node resizer area */
  protected virtual void draw_resizer( Context ctx, Theme theme ) {

    /* Only draw the resizer if we are the current node */
    if( mode != NodeMode.CURRENT ) {
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

  /* Draws the node on the screen */
  public virtual void draw( Context ctx, Theme theme, bool motion ) {

    var nodesel_background = theme.get_color( "nodesel_background" );
    var nodesel_foreground = theme.get_color( "nodesel_foreground" );

    /* If this is a root node, draw specifically for a root node */
    if( is_root() ) {

      var background = theme.get_color( "root_background" );
      var foreground = theme.get_color( "root_foreground" );

      draw_shape( ctx, theme, background );
      draw_name( ctx, theme );
      draw_image( ctx, theme );
      if( is_leaf() ) {
        draw_leaf_task( ctx, foreground );
      } else {
        draw_acc_task( ctx, foreground );
      }
      draw_sticker( ctx, nodesel_background, background );
      draw_common_note( ctx, foreground, nodesel_foreground, foreground );
      draw_link_node(   ctx, foreground, nodesel_foreground, foreground );
      draw_common_fold( ctx, background, foreground );
      draw_attachable(  ctx, theme, background );
      draw_resizer( ctx, theme );

    /* Otherwise, draw the node as a non-root node */
    } else {

      var background = theme.get_color( "background" );
      var foreground = theme.get_color( "foreground" );

      draw_shape( ctx, theme, _link_color );
      draw_name( ctx, theme );
      draw_image( ctx, theme );
      if( is_leaf() ) {
        draw_leaf_task( ctx, (style.is_fillable() ? background : _link_color) );
      } else {
        draw_acc_task( ctx, (style.is_fillable() ? background : _link_color) );
      }
      draw_sticker( ctx, nodesel_background, background );
      draw_common_note( ctx, foreground, nodesel_foreground, background );
      draw_link_node(   ctx, foreground, nodesel_foreground, foreground );
      draw_common_fold( ctx, _link_color, background );
      draw_attachable(  ctx, theme, background );
      draw_resizer( ctx, theme );
    }

  }

  /*
   Draws all of the nodes on the same side of the parent.  Draws the nodes such that
   overlapping links are drawn in a more meaningful way.
  */
  private void draw_side( Context ctx, Theme theme, Node? current, bool motion, int first, int last ) {
    var first_rside = _children.index( first ).relative_side();
    var mid         = first + 1;
    while( (mid < last) && (_children.index( mid ).relative_side() == first_rside) ) mid++;
    for( int i=first; i<mid; i++ ) {
      _children.index( i ).draw_all( ctx, theme, current, false, motion );
    }
    for( int i=(last - 1); i>=mid; i-- ) {
      _children.index( i ).draw_all( ctx, theme, current, false, motion );
    }
  }

  /* Draw this node and all child nodes */
  public void draw_all( Context ctx, Theme theme, Node? current, bool draw_current, bool motion ) {
    if( !is_root() && !draw_current ) {
      draw_link( ctx, theme );
    }
    if( this != current ) {
      if( !folded ) {
        if( _children.length > 0 ) {
          var first_side = side_count( _children.index( 0 ).side );
          draw_side( ctx, theme, current, motion, 0, first_side );
          if( first_side < _children.length ) {
            draw_side( ctx, theme, current, motion, first_side, (int)_children.length );
          }
        }
      }
      draw( ctx, theme, motion );
    }
  }

  /* Outputs the node's information to standard output */
  public void display( bool recursive = false, string prefix = "" ) {
    stdout.printf( "%sNode, name: %s, posx: %g, posy: %g, side: %s, layout: %s\n", prefix, name.text.text, posx, posy, side.to_string(), ((layout == null) ? "Unknown" : layout.name) );
    if( recursive ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).display( recursive, prefix + "  " );
      }
    }
  }

}
