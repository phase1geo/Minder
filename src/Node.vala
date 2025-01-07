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
  NONE = 0,    // Specifies that this node is not the current node
  CURRENT,     // Specifies that this node is the current node and is not being edited
  SELECTED,    // Specifies that this node is one of several selected nodes
  EDITABLE,    // Specifies that this node's text has been and currently is actively being edited
  ATTACHABLE,  // Specifies that this node is the currently attachable node (affects display)
  DROPPABLE,   // Specifies that this node can receive a dropped item
  HIGHLIGHTED; // Specifies that this node is both selected and being highlighted

  /* Returns true if the mode indicates that this node will be drawn as selected */
  public bool is_selected() {
    return( (this == CURRENT) || (this == SELECTED) || (this == HIGHLIGHTED) );
  }
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

  /* Generates the value of the VERTICAL mask value */
  public bool vertical() {
    return( (this == TOP) || (this == BOTTOM) );
  }

  /* Generates the value of the HORIZONTAL mask value */
  public bool horizontal() {
    return( (this == LEFT) || (this == RIGHT) );
  }
}

public class NodeBounds {

  private DrawArea _da;
  private double   _x = 0.0;
  private double   _y = 0.0;

  public double x {
    get {
      return( _x + _da.origin_x );
    }
    set {
      _x = (value - _da.origin_x);
    }
  }
  public double y {
    get {
      return( _y + _da.origin_y );
    }
    set {
      _y = (value - _da.origin_y);
    }
  }
  public double width  { set; get; default = 0.0; }
  public double height { set; get; default = 0.0; }

  /* Default constructor */
  public NodeBounds( DrawArea da ) {
    _da = da;
  }

  /* Constructor with bounds information */
  public NodeBounds.with_bounds( DrawArea da, double x, double y, double w, double h ) {
    _da         = da;
    this.x      = x;
    this.y      = y;
    this.width  = w;
    this.height = h;
  }

  /* Copy constructor */
  public NodeBounds.copy( NodeBounds nb ) {
    copy_from( nb );
  }

  /* Copies the given node bounds to this instance */
  public void copy_from( NodeBounds nb ) {
    _da         = nb._da;
    this.x      = nb.x;
    this.y      = nb.y;
    this.width  = nb.width;
    this.height = nb.height;
  }

  /* Returns true if the given NodeBounds overlap */
  public bool overlaps( NodeBounds other ) {
    return( ((x < (other.x + other.width))  && ((x + width) > other.x)) &&
            ((y < (other.y + other.height)) && ((y + height) > other.y)) );
  }

  /* Returns the X-coordinates of the upper-left corner of this bounds */
  public double x1() { return( x ); }

  /* Returns the Y-coordinates of the upper-left corner of this bounds */
  public double y1() { return( y ); }

  /* Returns the X-coordinates of the lower-right corner of this bounds */
  public double x2() { return( x + width ); }

  /* Returns the Y-coordinates of the lower-right corner of this bounds */
  public double y2() { return( y + height ); }

  /* Returns a string version of this instance */
  public string to_string() {
    return( "da: %s, x: %g, y: %g, w: %g, h: %g".printf( (_da != null).to_string(), x, y, width, height ) );
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

public struct NodeTaskInfo {
  bool enabled;
  bool done;
  Node node;
  public NodeTaskInfo( bool e, bool d, Node n ) {
    enabled = e;
    done    = d;
    node    = n;
  }
}

public class Node : Object {

  /* Member variables */
  private   DrawArea     _da;
  protected int          _id;
  private   CanvasText   _name;
  private   string       _note         = "";
  protected double       _width        = 0;
  protected double       _height       = 0;
  protected double       _total_width  = 0;
  protected double       _total_height = 0;
  protected double       _ipadx        = 6;
  protected double       _ipady        = 3;
  protected double       _task_radius  = 7;
  protected double       _alpha        = 1.0;
  protected Array<Node>  _children;
  private   NodeMode     _mode         = NodeMode.NONE;
  private   NodeBounds   _tree_bbox;
  private   int          _task_count   = 0;
  private   int          _task_done    = 0;
  private   double       _posx         = 0;
  private   double       _posy         = 0;
  private   RGBA?        _link_color      = {(float)1.0, (float)1.0, (float)1.0, (float)1.0};
  private   bool         _link_color_set  = false;
  private   bool         _link_color_root = false;
  private   double       _min_width      = 50;
  private   NodeImage?   _image          = null;
  private   Layout?      _layout         = null;
  private   Style        _style          = new Style();
  private   bool         _loaded         = true;
  private   NodeLink?    _linked_node    = null;
  private   string?      _sticker        = null;
  private   Pixbuf?      _sticker_buf    = null;
  private   SequenceNum  _sequence_num   = null;
  private   Callout?     _callout        = null;
  private   bool         _sequence       = false;

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
      return( _posx + _da.origin_x );
    }
    set {
      double diff = (value - posx);
      _posx = value - _da.origin_x;
      update_tree_bbox( diff, 0 );
      position_text();
      if( diff != 0 ) {
        moved( diff, 0 );
      }
    }
  }
  public double posy {
    get {
      return( _posy + _da.origin_y );
    }
    set {
      double diff = (value - posy);
      _posy = value - _da.origin_y;
      update_tree_bbox( 0, diff );
      position_text();
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
  public bool     show_fold  { get; set; default = false; }
  public double   tree_size  { get; set; default = 0; }
  public bool     group      { get; set; default = false; }
  public RGBA?    link_color {
    get {
      return( (!is_root() || _link_color_set) ? _link_color : null );
    }
    set {
      if( is_root() ) {
        if( value == null ) {
          _link_color_set = false;
        } else {
          _link_color     = value;
          _link_color_set = true;
        }
      } else if( value != null ) {
        _link_color      = value;
        _link_color_set  = true;
        _link_color_root = true;
        if( traversable() ) {
          for( int i=0; i<_children.length; i++ ) {
            _children.index( i ).link_color_child = value;
          }
        }
      }
    }
  }
  public RGBA link_color_only {
    set {
      _link_color     = value;
      _link_color_set = true;
    }
  }
  protected RGBA link_color_child {
    set {
      if( !link_color_root ) {
        _link_color     = value;
        _link_color_set = true;
        if( traversable() ) {
          for( int i=0; i<_children.length; i++ ) {
            _children.index( i ).link_color_child = value;
          }
        }
      }
    }
  }
  public bool link_color_root {
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
  public bool link_color_set {
    get {
      return( _link_color_set );
    }
  }
  public bool  attached { get; set; default = false; }
  public Style style {
    get {
      return( _style );
    }
    set {
      var branch_margin = style.branch_margin;
      if( _style.copy( value ) ) {
        name.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
        if( _sequence_num != null ) {
          _sequence_num.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
        }
        name.max_width = style.node_width;
        if( traversable() ) {
          for( int i=0; i<_children.length; i++ ) {
            _layout.apply_margin( _children.index( i ) );
          }
        }
        if( _callout != null ) {
          _callout.position_text( false );
        }
        position_text_and_update_size();
      }
    }
  }
  public Layout? layout {
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
  public bool image_resizable {
    get {
      return( (_image == null) ? false : _image.resizable );
    }
    set {
      if( _image != null ) {
        _image.resizable = value;
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
      if( _callout != null ) {
        _callout.alpha = _alpha;
      }
    }
  }
  public NodeLink? linked_node {
    get {
      return( _linked_node );
    }
    set {
      _linked_node = value;
      if( _linked_node != null ) {
        _linked_node.normalize( _da );
      }
      update_size();
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
          _sticker_buf = StickerSet.make_pixbuf( _sticker );
        } else {
          _sticker_buf = null;
        }
        position_text_and_update_size();
      }
    }
  }
  public Callout? callout {
    get {
      return( _callout );
    }
    set {
      if( _callout != value ) {
        if( value == null ) {
          _callout.resized.disconnect( position_text_and_update_size );
        }
        _callout = value;
        if( _callout != null ) {
          _callout.resized.connect( position_text_and_update_size );
        }
        position_text_and_update_size();
      }
    }
  }
  public bool sequence {
    get {
      return( _sequence );
    }
    set {
      if( _sequence != value ) {
        _sequence = value;
        for( int i=0; i<_children.length; i++ ) {
          _children.index( i ).update_sequence_num();
        }
      }
    }
  }

  /* Default constructor */
  public Node( DrawArea da, Layout? layout ) {
    _da        = da;
    _id        = da.next_node_id;
    _children  = new Array<Node>();
    _tree_bbox = new NodeBounds( da );
    _layout    = layout;
    _name      = new CanvasText( da );
    _name.resized.connect( position_text_and_update_size );
    set_parsers();
  }

  /* Constructor initializing string */
  public Node.with_name( DrawArea da, string n, Layout? layout ) {
    _da        = da;
    _id        = da.next_node_id;
    _children  = new Array<Node>();
    _tree_bbox = new NodeBounds( da );
    _layout    = layout;
    _name      = new CanvasText.with_text( da, n );
    _name.resized.connect( position_text_and_update_size );
    set_parsers();
  }

  /* Constructor from an XML node */
  public Node.from_xml( DrawArea da, Layout? layout, Xml.Node* n, bool isroot, Node? sibling_parent, ref Array<Node> siblings ) {
    _da        = da;
    _children  = new Array<Node>();
    _tree_bbox = new NodeBounds( da );
    _layout    = layout;
    _name      = new CanvasText.with_text( da, "" );
    _name.resized.connect( position_text_and_update_size );
    set_parsers();
    siblings.append_val( this );
    load( da, n, isroot, sibling_parent, ref siblings );
  }

  /* Copies an existing node to this node */
  public Node.copy( DrawArea da, Node n, ImageManager im ) {
    _da        = da;
    _id        = da.next_node_id;
    _children  = n._children;
    _tree_bbox = new NodeBounds( da );
    _name      = new CanvasText( da );
    copy_variables( n, im );
    _name.resized.connect( position_text_and_update_size );
    set_parsers();
    mode      = NodeMode.NONE;
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).parent = this;
    }
  }

  public Node.copy_only( DrawArea da, Node n, ImageManager im ) {
    _da        = da;
    _id        = da.next_node_id;
    _children  = new Array<Node>();
    _tree_bbox = new NodeBounds( da );
    _name      = new CanvasText( da );
    copy_variables( n, im );
  }

  /* Copies an existing node tree to this node */
  public Node.copy_tree( DrawArea da, Node n, ImageManager im ) {
    _da        = da;
    _id        = n.id();
    _children  = new Array<Node>();
    _tree_bbox = new NodeBounds( da );
    _name      = new CanvasText( da );
    copy_variables( n, im );
    _name.resized.connect( position_text_and_update_size );
    set_parsers();
    mode      = NodeMode.NONE;
    tree_size = n.tree_size;
    for( int i=0; i<n._children.length; i++ ) {
      Node child = new Node.copy_tree( da, n._children.index( i ), im );
      child.parent = this;
      _children.append_val( child );
    }
  }

  /* Adds the valid parsers */
  public void set_parsers() {
    _name.text.add_parser( _da.markdown_parser );
    // _name.text.add_parser( _da.tagger_parser );
    _name.text.add_parser( _da.url_parser );
    _name.text.add_parser( _da.unicode_parser );
  }

  /* Copies just the variables of the node, minus the children nodes */
  public void copy_variables( Node n, ImageManager im ) {
    _width          = n._width;
    _height         = n._height;
    _total_width    = n._total_width;
    _total_height   = n._total_height;
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
    tree_bbox.copy_from( n.tree_bbox );
    sticker          = n.sticker;
    sequence         = n.sequence;
  }

  /* Returns the associated ID of this node */
  public int id() {
    return( _id );
  }

  /* Reassign this node's and all child node's ID from the DrawArea */
  public void reassign_ids() {
    _id = _da.next_node_id;
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).reassign_ids();
    }
  }

  /* Sets the posx value only, leaving the children positions alone */
  public void set_posx_only( double value ) {
    var diff = value - _posx;
    _posx = value;
    update_tree_bbox( diff, 0 );
    position_text();
  }

  /* Sets the posy value only, leaving the children positions alone */
  public void set_posy_only( double value ) {
    var diff = value - _posy;
    _posy = value;
    update_tree_bbox( 0, diff );
    position_text();
  }

  /* Sets the alpha value without propagating this to the children */
  public void set_alpha_only( double value ) {
    _alpha = value;
    if( _callout != null ) {
      _callout.alpha = value;
    }
  }

  /* Updates the alpha value if it is not set to 1.0 */
  public void update_alpha( double value ) {
    if( _alpha < 1.0 ) {
      _alpha = value;
    }
    if( traversable() ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).update_alpha( value );
      }
    }
  }

  /* Sets the posx value only, leaving the children positions alone */
  public void adjust_posx_only( double value ) {
    _posx += value;
    update_tree_bbox( value, 0 );
    position_text();
  }

  /* Sets the posy value only, leaving the children positions alone */
  public void adjust_posy_only( double value ) {
    _posy += value;
    update_tree_bbox( 0, value );
    position_text();
  }

  //-------------------------------------------------------------
  // Updates the sequence number pango layout.
  public void update_sequence_num() {
    if( parent.sequence ) {
      if( _sequence_num == null ) {
        _sequence_num = new SequenceNum( _da );
        _sequence_num.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
      }
      var seq_type = SequenceNumType.NUM;
      if( (parent._sequence_num != null) && (parent._sequence_num.seq_type == SequenceNumType.NUM) ) {
        seq_type = SequenceNumType.LETTER;
      }
      _sequence_num.set_num( index(), seq_type );
    } else {
      _sequence_num = null;
    }
    position_text_and_update_size();
  }

  /* Clears the summary extents found as grandchildren of this node */
  public virtual void clear_summary_extents() {
    for( int i=0; i<_children.length; i++ ) {
      var node = _children.index( i );
      if( node.last_summarized() ) {
        node.summary_node().clear_extents();
      }
    }
  }

  /* Sets the summary extents found as grandchildren of this node */
  public virtual void set_summary_extents() {
    for( int i=0; i<_children.length; i++ ) {
      var node = _children.index( i );
      if( node.last_summarized() ) {
        node.summary_node().set_extents();
      }
    }
  }

  /* Updates the tree_bbox */
  private void update_tree_bbox( double diffx, double diffy ) {
    var nb = tree_bbox;
    nb.x += diffx;
    nb.y += diffy;
    tree_bbox = nb;
  }

  /* Called whenever the canvas text is resized */
  private void position_text_and_update_size() {
    position_text();
    update_size();
  }

  /* Called whenever the node size is changed */
  private void update_size() {

    if( !_loaded ) return;

    var orig_width  = _total_width;
    var orig_height = _total_height;
    var margin      = style.node_margin  ?? 0;
    var padding     = style.node_padding ?? 0;
    var stk_height  = sticker_height();
    var name_width  = task_width() + sticker_width() + sequence_width() + _name.width + note_width() + linked_node_width();
    var name_height = (_name.height < stk_height) ? stk_height : _name.height;

    if( _image != null ) {
      _width  = (margin * 2) + (padding * 2) + ((name_width < _image.width) ? _image.width : name_width);
      _height = (margin * 2) + (padding * 2) + _image.height + padding + name_height;
    } else {
      _width  = (margin * 2) + (padding * 2) + name_width;
      _height = (margin * 2) + (padding * 2) + name_height;
    }

    update_total_size();

    var diffw = _total_width - orig_width;
    var diffh = _total_height - orig_height;

    if( (_layout != null) && ((diffw != 0) || (diffh != 0)) ) {
      _layout.handle_update_by_edit( this, diffw, diffh );
    }

  }

  /* Updates the total size which includes the callout */
  private void update_total_size() {

    if( (_callout == null) || _callout.mode.is_disconnected() ) {
      _total_width  = _width;
      _total_height = _height;
    } else if( side.horizontal() ) {
      var margin         = style.node_margin  ?? 0;
      var callout_width  = _callout.total_width + (margin * 2);
      var callout_height = _callout.total_height + margin;
      _total_width  = (_width < callout_width) ? callout_width : _width;
      _total_height = _height + callout_height;
    } else {
      var margin         = style.node_margin  ?? 0;
      var callout_width  = _callout.total_width + margin;
      var callout_height = _callout.total_height + (margin * 2);
      _total_width  = _width + callout_width;
      _total_height = (_height < callout_height) ? callout_height : _height;
    }

  }

  /* Sets all callouts to the specified mode */
  public void set_callout_modes( CalloutMode mode ) {
    if( _callout != null ) {
      _callout.mode = mode;
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).set_callout_modes( mode );
    }
  }

  /* Updates the size of all nodes within this tree */
  public void update_tree() {
    _name.update_size();
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).update_tree();
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

  /* Returns true if this node can be traversed in the hierarchy */
  public bool traversable() {
    return( !is_summarized() || last_summarized() );
  }

  /* Returns if this is a summary node */
  public virtual bool is_summary() {
    return( false );
  }

  /* Returns true if this node is summarized in the mindmap */
  public virtual bool is_summarized() {
    return( (_children.length == 1) && _children.index( 0 ).is_summary() );
  }

  /* Returns true if this node is the first node of a summary node */
  public virtual bool first_summarized() {
    return( is_summarized() && ((_children.index( 0 ) as SummaryNode).first_node() == this) );
  }

  /* Returns true if this node is the last node of a summary node */
  public virtual bool last_summarized() {
    return( is_summarized() && ((_children.index( 0 ) as SummaryNode).last_node() == this) );
  }

  /* Returns the summary node this node is attached to if it is summarized; otherwise, returns null */
  public SummaryNode? summary_node() {
    if( is_summarized() ) {
      return( (SummaryNode)children().index( 0 ) );
    }
    return( null );
  }

  /* Returns true if this node is positioned somewhere between the first and last sibling node in the same parent */
  public bool is_between_siblings( Node first, Node last ) {
    return( (first.parent == parent) && (last.parent == parent) && ((first.index() <= index()) && (index() <= last.index())) );
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

  /* Returns the number of descendants within this node */
  public int descendant_count() {
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

  //-------------------------------------------------------------
  // Returns true if this node contains a sequence of nodes (i.e., is the
  // parent node of a sequence of nodes).
  public bool contains_sequence() {
    return( sequence );
  }

  //-------------------------------------------------------------
  // Returns true if this node is within a sequence.
  public bool is_in_sequence() {
    return( _sequence_num != null );
  }

  /* Returns the task completion percentage value */
  public double task_completion_percentage() {
    return( (_task_done / (_task_count * 1.0)) * 100 );
  }

  /* Returns true if the resizer should be in the upper left */
  public bool resizer_on_left() {
    return( !is_root() && (side == NodeSide.LEFT) );
  }

  /* Returns true if the given cursor coordinates lie within any part of this node */
  public virtual bool is_within( double x, double y ) {
    double bx, by, bw, bh;
    bbox( out bx, out by, out bw, out bh );
    return( Utils.is_within_bounds( x, y, bx, by, bw, bh ) );
  }

  /* Returns true if the given cursor coordinates lies within the node bounding box */
  public virtual bool is_within_node( double x, double y ) {
    double margin = style.node_margin ?? 0;
    double cx, cy, cw, ch;
    node_bbox( out cx, out cy, out cw, out ch );
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

  /* Returns the positional information for where the sticker is located (if it exists) */
  protected virtual void sticker_bbox( out double x, out double y, out double w, out double h ) {
    int    margin     = style.node_margin  ?? 0;
    int    padding    = style.node_padding ?? 0;
    double img_height = (_image == null) ? 0 : (_image.height + padding);
    double stk_height = (_sticker_buf == null) ? 0 : _sticker_buf.height;
    x = posx + margin + padding + task_width();
    y = posy + margin + padding + img_height + ((_height - (img_height + (padding * 2) + (margin * 2))) / 2) - (stk_height / 2);
    w = (_sticker_buf == null) ? 0 : _sticker_buf.width;
    h = (_sticker_buf == null) ? 0 : _sticker_buf.height;
  }

  /* Returns the positional information for where the sequence number is located (if it exists) */
  protected virtual void sequence_bbox( out double x, out double y, out double w, out double h ) {
    int    margin     = style.node_margin  ?? 0;
    int    padding    = style.node_padding ?? 0;
    double img_height = (_image == null) ? 0 : (_image.height + padding);
    double stk_height = (_sticker_buf == null) ? 0 : _sticker_buf.height;
    double seq_height = (_sequence_num == null) ? 0 : _sequence_num.height;
    x = posx + margin + padding + task_width() + sticker_width();
    y = name.posy;
    w = sequence_width();
    h = sequence_height();
  }

  /* Returns the positional information for where the linked node indicator is located (if it exists) */
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
    x = (posx + (_width / 2)) - ((_image == null) ? 0 : (_image.width / 2));
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
    }
    return( false );
  }

  /*
   Returns true if the given cursor coordinates lies within the note icon area.
  */
  public virtual bool is_within_note( double x, double y ) {
    if( note.length > 0 ) {
      double nx, ny, nw, nh;
      note_bbox( out nx, out ny, out nw, out nh );
      return( Utils.is_within_bounds( x, y, nx, ny, nw, nh ) );
    }
    return( false );
  }

  /*
   Returns true if the given cursor coordinates lies within the linked node indicator area.
  */
  public virtual bool is_within_linked_node( double x, double y ) {
    if( linked_node != null ) {
      double lx, ly, lw, lh;
      linked_node_bbox( out lx, out ly, out lw, out lh );
      return( Utils.is_within_bounds( x, y, lx, ly, lw, lh ) );
    }
    return( false );
  }

  /* Returns true if the given cursor coordinates lie within the fold indicator area */
  public virtual bool is_within_fold( double x, double y ) {
    if( (_children.length > 0) && !is_summarized() ) {
      double fx, fy, fw, fh;
      fold_bbox( out fx, out fy, out fw, out fh );
      return( Utils.is_within_bounds( x, y, fx, fy, fw, fh ) );
    }
    return( false );
  }

  /* Returns true if the given cursor coordinates lie within the fold indicator surrounding area */
  public virtual bool is_within_fold_area( double x, double y ) {
    if( (_children.length > 0) && !is_summarized() ) {
      double fx, fy, fw, fh;
      var pad = 20;
      fold_bbox( out fx, out fy, out fw, out fh );
      return( Utils.is_within_bounds( x, y, (fx - pad), (fy - pad), (fw + (pad * 2)), (fh + (pad * 2)) ) );
    }
    return( false );
  }

  /* Returns true if the given cursor coordinates lie within the image area */
  public virtual bool is_within_image( double x, double y ) {
    if( _image != null ) {
      double ix, iy, iw, ih;
      image_bbox( out ix, out iy, out iw, out ih );
      return( Utils.is_within_bounds( x, y, ix, iy, iw, ih ) );
    }
    return( false );
  }

  /* Returns true if the given cursor coordinates lie within the resizer area */
  public virtual bool is_within_resizer( double x, double y ) {
    if( (mode == NodeMode.CURRENT) || (mode == NodeMode.HIGHLIGHTED) ) {
      double rx, ry, rw, rh;
      resizer_bbox( out rx, out ry, out rw, out rh );
      return( Utils.is_within_bounds( x, y, rx, ry, rw, rh ) );
    }
    return( false );
  }

  /* Finds the node which contains the given pixel coordinates */
  public virtual Node? contains( double x, double y, Node? n ) {
    if( (this != n) && (is_within_node( x, y ) || is_within_fold_area( x, y )) ) {
      return( this );
    } else if( !folded ) {
      for( int i=0; i<_children.length; i++ ) {
        var tmp = _children.index( i ).contains( x, y, n );
        if( tmp != null ) {
          return( tmp );
        }
      }
    }
    return( null );
  }

  /* Finds the callout which contains the given pixel coordinates */
  public virtual Callout? contains_callout( double x, double y ) {
    if( (_callout != null) && !_callout.mode.is_disconnected() && _callout.contains( x, y ) ) {
      return( _callout );
    } else if( !folded ) {
      for( int i=0; i<_children.length; i++ ) {
        var tmp = _children.index( i ).contains_callout( x, y );
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
    var int_x = (int)posx;
    var int_y = (int)posy;
    var int_w = (int)width;
    var int_h = (int)height;
    Gdk.Rectangle node_box = { int_x, int_y, int_w, int_h };
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
    if( _id == id ) {
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
      position_text();
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

  /* Loads the node link from the given XML node */
  private void load_node_link( Xml.Node* n ) {
    _linked_node = new NodeLink.from_xml( n );
  }

  /* Loads the style information from the given XML node */
  private void load_style( Xml.Node* n ) {
    _style.load_node( n );
    _name.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
    if( _sequence_num != null ) {
      _sequence_num.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
    }
  }

  /* Loads the callout information */
  private void load_callout( Xml.Node* n ) {
    if( _callout == null ) {
      callout = new Callout( this );
    }
    callout.load( n );
  }

  /* Loads the child nodes */
  private void load_nodes( Xml.Node* n, Node? sibling_parent, ref Array<Node> siblings ) {
    var nodes = new Array<Node>();
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "node" :
            var node = new Node.from_xml( _da, _layout, it, false, this, ref nodes );
            node.attach( this, -1, null );
            break;
          case "summary-node" :
            var node = new SummaryNode.from_xml( _da, _layout, it, ref nodes );
            node.attach_nodes( sibling_parent, siblings, false, null );
            siblings.remove_range( 0, siblings.length );
            break;
        }
      }
    }
  }

  /*
   Searches for a node ID matching the given node ID.  If found, returns true
   along with the plain text title of the found node.
  */
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

  /* Loads the file contents into this instance */
  public virtual void load( DrawArea da, Xml.Node* n, bool isroot, Node? sibling_parent, ref Array<Node> siblings ) {

    _loaded = false;

    string? i = n->get_prop( "id" );
    if( i != null ) {
      _id = int.parse( i );
      da.next_node_id = _id;
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

    string? tc = n->get_prop( "task" );
    if( tc != null ) {
      _task_count = 1;
      _task_done  = int.parse( tc );
    }

    string? ln = n->get_prop( "link" );
    if( ln != null ) {
      _linked_node = new NodeLink.for_local( int.parse( ln ) );
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

    string? su = n->get_prop( "summarized" );
    if( (su != null) && bool.parse( su ) ) {
      siblings.append_val( this );
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
          case "nodelink"   :  load_node_link( it );  break;
          case "style"      :  load_style( it );  break;
          case "callout"    :  load_callout( it );  break;
          case "nodes"      :  load_nodes( it, sibling_parent, ref siblings );  break;
        }
      }
    }

    string? srl = n->get_prop( "sequence" );
    if( srl != null ) {
      sequence = bool.parse( srl );
    }

    _loaded = true;

    /* Force the size to get re-calculated */
    update_total_size();
    update_size();

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
    tree_bbox = layout.bbox( this, -1, "node.load" );

    if( ts == null ) {
      tree_size = side.horizontal() ? tree_bbox.height : tree_bbox.width;
    }

    /* Make sure that the name is positioned properly */
    position_text();

  }

  /* Saves the current node */
  public virtual void save( Xml.Node* parent ) {
    parent->add_child( save_node() );
  }

  /* Saves the node contents to the given data output stream */
  protected Xml.Node* save_node() {

    Xml.Node* node = new Xml.Node( null, (is_summary() ? "summary-node" : "node") );
    node->new_prop( "id", _id.to_string() );
    node->new_prop( "posx", _posx.to_string() );
    node->new_prop( "posy", _posy.to_string() );
    node->new_prop( "width", _width.to_string() );
    node->new_prop( "height", _height.to_string() );
    if( is_task() ) {
      node->new_prop( "task", _task_done.to_string() );
    }
    node->new_prop( "side", side.to_string() );
    node->new_prop( "fold", folded.to_string() );
    node->new_prop( "sequence", sequence.to_string() );
    node->new_prop( "treesize", tree_size.to_string() );
    if( is_root() ) {
      if( _link_color_set ) {
        node->new_prop( "color", Utils.color_from_rgba( _link_color ) );
      }
    } else {
      node->new_prop( "color", Utils.color_from_rgba( _link_color ) );
      node->new_prop( "colorroot", link_color_root.to_string() );
    }
    node->new_prop( "summarized", is_summarized().to_string() );
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

    if( _linked_node != null ) {
      node->add_child( _linked_node.save() );
    }

    if( _callout != null ) {
      node->add_child( _callout.save() );
    }

    if( (_children.length > 0) && traversable() ) {
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
    string? o = parent->get_prop( "note" );
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
    tree_bbox = layout.bbox( this, -1, "import_opml" );
    tree_size = side.horizontal() ? tree_bbox.height : tree_bbox.width;

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

  /* Sets the resizable property on the node image, if it exists. */
  public void set_resizable( bool resizable ) {
    if( _image != null ) {
      _image.resizable = resizable;
    }
  }

  /* Resizes the node width by the given amount */
  public virtual void resize( double diff ) {
    diff = resizer_on_left() ? (0 - diff) : diff;
    var int_diff = (int)diff;
    if( _image == null ) {
      if( (diff < 0) ? ((style.node_width + diff) <= _min_width) : !_name.is_wrapped() ) return;
      style.node_width += int_diff;
    } else {
      if( (style.node_width + diff) < _min_width ) return;
      style.node_width += int_diff;
      var int_node_width = (int)style.node_width;
      _image.set_width( int_node_width );
    }
    _name.resize( diff );
  }

  /* Returns the bounding box for this node */
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

  /* Returns the bounding box for the node box itself (this includes everything but the callout) */
  public void node_bbox( out double x, out double y, out double w, out double h ) {
    x = posx;
    y = posy; 
    w = _width;
    h = _height;
  }

  /* Returns the bounding box for the fold indicator for this node */
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

  /*
   Sets the fold for this node to the given value.  Appends this node to
   the changed list if the folded value changed.
  */
  public void set_fold( bool value, bool deep, Array<Node>? changed = null ) {
    if( !value && deep ) {
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
            set_fold( true, true, changed );
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

  /* Returns the width of the sequence number */
  public double sequence_width() {
    return( (_sequence_num != null) ? _sequence_num.width : 0 );
  }

  /* Returns the height of the sequence number */
  public double sequence_height() {
    return( (_sequence_num != null) ? _sequence_num.height : 0 );
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

  /* Returns the sibling node relative to this node */
  private Node? get_sibling( int dir ) {
    var index = index() + dir;
    if( (index < 0) || (index >= parent.children().length) ) {
      return( null );
    } else {
      return( parent.children().index( index ) );
    }
  }

  /* Returns the previous sibling node relative to this node */
  public Node? previous_sibling() {
    return( get_sibling( -1 ) );
  }

  /* Returns the previous sibling node relative to this node */
  public Node? next_sibling() {
    return( get_sibling( 1 ) );
  }

  /*
   Checks to see if the given node is a sibling node on the same side.  If it is,
   swaps the position of the given node with the given node.  Returns true if
   the nodes are swapped.
  */
  public bool swap_with_sibling( Node? other ) {

    if( (other != null) && !is_summary() && !other.is_summary() && (summary_node() == other.summary_node()) && (other.parent == parent) ) {

      var other_index   = other.index();
      var other_summary = other.summary_node();
      var our_index     = index();
      var our_parent    = parent;
      var our_summary   = summary_node();

      if( (other_index + 1) == our_index ) {
        da.animator.add_nodes( da.get_nodes(), "swap_with_sibling" );
        detach( side );
        if( our_summary != null ) {
          our_summary.remove_node( this );
        }
        attached = true;
        attach( our_parent, other_index, null, false );
        if( other_summary != null ) {
          other_summary.add_node( this );
        }
        our_parent.last_selected_child = this;
        da.undo_buffer.add_item( new UndoNodeMove( this, side, our_index, our_summary ) );
        da.animator.animate();
        return( true );

      } else if( (our_index + 1) == other_index ) {
        var other_side = other.side;
        da.animator.add_nodes( da.get_nodes(), "swap_with_sibling" );
        other.detach( other_side );
        if( other_summary != null ) {
          other_summary.remove_node( other );
        }
        other.attached = true;
        other.attach( our_parent, our_index, null, false );
        if( our_summary != null ) {
          our_summary.add_node( other );
        }
        da.undo_buffer.add_item( new UndoNodeMove( other, other_side, other_index, other_summary ) );
        da.animator.animate();
        return( true );
      }

    }

    return( false );

  }

  /*
   Moves the node (and its tree) to be a sibling of its parent located just
   before its parent node (side will match parent's side).
  */
  public bool make_parent_sibling( Node? other, bool add_undo = true ) {

    // If the other node matches our parent, perform this operation
    if( (other != null) && (other == parent) && !parent.is_root() ) {

      var grandparent = parent.parent;
      var parent_idx  = parent.index();

      if( add_undo ) {
        da.undo_buffer.add_item( new UndoNodeUnclify( this ) );
      }

      da.animator.add_nodes( da.get_nodes(), "make_sibling_of_grandparent" );
      detach( side );
      attach( grandparent, parent_idx, null );

      da.animator.animate();

      return( true );

    }

    return( false );

  }

  /*
   Moves all children of the given node to the node's parent, placed just
   before the parent node.
  */
  public bool make_children_siblings( Node? potential_child, bool add_undo = true ) {

    if( (potential_child != null) && contains_node( potential_child ) ) {

      var idx          = index();
      var num_children = (int)_children.length;

      da.animator.add_nodes( da.get_nodes(), "make_children_siblings" );
      for( int i=(num_children - 1); i>=0; i-- ) {
        var child = _children.index( i );
        child.detach( child.side );
        child.attach( parent, idx, null );
      }
      if( add_undo ) {
        da.undo_buffer.add_item( new UndoNodeReparent( this, idx, idx + num_children ) );
      }
      da.animator.animate();

      return( true );

    }

    return( false );

  }

  /* Adjusts the position of the text object */
  private void position_text() {

    var margin     = style.node_margin  ?? 0;
    var padding    = style.node_padding ?? 0;
    var stk_height = sticker_height();
    var img_height = (_image != null) ? (_image.height + padding) : 0;
    var orig_posx  = name.posx;
    var orig_posy  = name.posy;

    name.posx = posx + margin + padding + task_width() + sticker_width() + sequence_width();
    name.posy = posy + margin + padding + img_height + ((name.height < stk_height) ? ((stk_height - name.height) / 2) : 0);

    if( (_callout != null) && ((orig_posx != name.posx) || (orig_posy != name.posy)) ) {
      _callout.position_text( true );
    }

  }

  /* If the parent node is moved, we will move ourselves the same amount */
  protected void parent_moved( Node parent, double diffx, double diffy ) {

    _posx += diffx;
    _posy += diffy;

    update_tree_bbox( diffx, diffy );
    position_text();

    if( !is_summarized() || last_summarized() ) {
      moved( diffx, diffy );
    }

  }

  /* Detaches this node from its parent node */
  public virtual void detach( NodeSide side ) {

    assert( !is_summary() );

    if( parent != null ) {
      int idx = index();
      propagate_task_info_up( (0 - _task_count), (0 - _task_done) );
      parent.children().remove_index( idx );
      parent.moved.disconnect( this.parent_moved );
      if( parent.last_selected_child == this ) {
        parent.last_selected_child = null;
      }
      _sequence_num = null;
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
      propagate_task_info_up( (0 - _task_count), (0 - _task_done) );
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

  /* Undoes a delete_only call by reattaching this node to the given parent */
  public virtual void attach_only( Node? prev_parent, int prev_index ) {
    assert( !is_summary() );
    var temp = new Array<Node>();
    for( int i=0; i<children().length; i++ ) {
      var child = children().index( i );
      if( child.is_root() ) {
        _da.remove_root_node( child );
      } else {
        child.detach( child.side );
      }
      temp.append_val( child );
    }
    children().remove_range( 0, children().length );
    for( int i=0; i<temp.length; i++ ) {
      var child = temp.index( i );
      child.attach_init( this, -1 );
    }
    if( index() == -1 ) {
      attach_init( prev_parent, prev_index );
    }
    attached = true;
  }

  /* Attaches this node as a child of the given node */
  public virtual void attach( Node parent, int index, Theme? theme, bool set_side = true ) {
    this.parent = parent;
    layout = parent.layout;
    assert( !is_summary() );
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
    assert( !is_summary() );
    this.parent = parent;
    layout = parent.layout;
    attach_common( index, null );
  }

  protected virtual void attach_common( int index, Theme? theme ) {
    if( index == -1 ) {
      index = (int)this.parent.children().length;
      parent.children().append_val( this );
    } else {
      parent.children().insert_val( index, this );
    }
    if( (parent._task_count > 0) && (_task_count == 0) ) {
      _task_count = 1;
    }
    propagate_task_info_up( _task_count, _task_done );
    if( parent.sequence ) {
      for( int i=index; i<parent.children().length; i++ ) {
        parent.children().index( i ).update_sequence_num();
      }
    }
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
      for( int i=0; i<_children.length; i++ ) {
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
      position_text();
      update_size();
    }
  }

  /* Propagates a change in the task_done for this node to all parent nodes */
  private void propagate_task_info_up( int count_adjust, int done_adjust ) {
    Node p = parent;
    while( p != null ) {
      p._task_count += count_adjust;
      p._task_done  += done_adjust;
      p.position_text();
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
  public void toggle_task_done( ref Array<NodeTaskInfo?> changed ) {
    var change = new NodeTaskInfo( task_enabled(), task_done(), this );
    changed.append_val( change );
    set_task_done( _task_done == 0 );
  }

  /*
   Returns the ancestor node that is folded or returns null if no ancestor nodes
   are folded.
  */
  public Node? folded_ancestor() {
    var node = parent;
    while( (node != null) && !node.folded ) node = node.parent;
    return( node );
  }

  /*
   Populates the given ListStore with all nodes that have names that match
   the given string pattern.
  */
  public void get_match_items( string tabname, string pattern, bool[] search_opts, ref Gtk.ListStore matches ) {
    if( search_opts[SearchOptions.NODES] &&
        (((((_task_count == 0) || !is_leaf()) && search_opts[SearchOptions.NONTASKS]) ||
          ((_task_count != 0) && is_leaf()   && search_opts[SearchOptions.TASKS])) &&
         (((parent != null) && parent.folded && search_opts[SearchOptions.FOLDED]) ||
          (((parent == null) || !parent.folded) && search_opts[SearchOptions.UNFOLDED]))) ) {
      var tab = "<i>" + Utils.rootname( tabname ) + "</i>";
      if( search_opts[SearchOptions.TITLES] ) {
        string str = Utils.match_string( pattern, name.text.text );
        if( str.length > 0 ) {
          TreeIter it;
          matches.append( out it );
          matches.set( it, 0, "<b><i>%s:</i></b>".printf( _( "Node Title" ) ), 1, str, 2, this, 3, null, 4, null, 5, null, 6, tabname, 7, tab, -1 );
        }
      }
      if( search_opts[SearchOptions.NOTES] ) {
        string str = Utils.match_string( pattern, note);
        if(str.length > 0) {
          TreeIter it;
          matches.append( out it );
          matches.set( it, 0, "<b><i>%s:</i></b>".printf( _( "Node Note" ) ), 1, str, 2, this, 3, null, 4, null, 5, null, 6, tabname, 7, tab, -1 );
        }
      }
    }
    if( (_callout != null) && search_opts[SearchOptions.CALLOUTS] && search_opts[SearchOptions.TITLES] ) {
      string str = Utils.match_string( pattern, _callout.text.text.text );
      if( str.length > 0 ) {
        TreeIter it;
        var tab = "<i>" + Utils.rootname( tabname ) + "</i>";
        matches.append( out it );
        matches.set( it, 0, "<b><i>%s:</i></b>".printf( _( "Callout Text" ) ), 1, str, 2, null, 3, null, 4, _callout, 5, null, 6, tabname, 7, tab, -1 );
      }
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).get_match_items( tabname, pattern, search_opts, ref matches );
    }
  }

  /*
   Called when the theme is changed by the user.  Looks up this
   node's link color in the old theme to see if it is a themed color.
   If it is, map it to the new theme's color palette.  If the current
   color is not a theme link color, keep the current color as it
   was custom set by the user.  Performs this mapping recursively for
   all descendants.
  */
  public void update_theme_colors( Theme old_theme, Theme new_theme ) {
    int old_index = old_theme.get_color_index( _link_color );
    if( old_index != -1 ) {
      link_color_only = new_theme.link_color( old_index );
    }
    name.update_attributes();
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).update_theme_colors( old_theme, new_theme );
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
    position_text();

    for( int i=0; i<_children.length; i++ ) {
      index++;
      _children.index( i ).set_node_info( info, ref index );
    }

  }

  /* Returns the link point for this node */
  protected virtual void link_point( out double x, out double y, bool seq = false ) {
    if( is_root() ) {
      x = posx + (_width / 2);
      y = posy + (_height / 2);
    } else if( seq ) {
      int margin  = style.node_margin ?? 0;
      int padding = style.node_padding ?? 0;
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

  /* Draws the border around the node */
  protected void draw_shape( Context ctx, Theme theme, RGBA border_color, bool exporting ) {

    double x = posx + style.node_margin;
    double y = posy + style.node_margin;
    double w = _width  - (style.node_margin * 2);
    double h = _height - (style.node_margin * 2);

    /* Set the fill color */
    if( mode.is_selected() && !exporting ) {
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

    /* If we have children and we need to extend our link point, let's draw the extended link link now */
    if( (_children.length > 0) && !is_summarized() ) {
      var max_width = 0;
      for( int i=0; i<_children.length; i++ ) {
        if( max_width < _children.index( i ).style.link_width ) {
          max_width = _children.index( i ).style.link_width;
        }
      }
      if( (side == NodeSide.RIGHT) && (_width < _total_width) ) {
        link_point( out x, out y );
        ctx.set_line_width( max_width );
        ctx.move_to( (posx + _width - (style.node_margin ?? 0)), y );
        ctx.line_to( x, y );
        ctx.stroke();
      } else if( (side == NodeSide.BOTTOM) && (_height < _total_height) ) {
        link_point( out x, out y );
        ctx.set_line_width( max_width );
        ctx.move_to( x, (posy + _height - (style.node_margin ?? 0)) );
        ctx.line_to( x, y );
        ctx.stroke();
      }
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
  protected virtual void draw_name( Cairo.Context ctx, Theme theme, bool exporting ) {

    int hmargin = 3;
    int vmargin = 3;

    /* Draw the selection box around the text if the node is in the 'selected' state */
    if( mode.is_selected() && !exporting ) {
      var padding = style.node_padding ?? 0;
      var margin  = style.node_margin  ?? 0;
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "nodesel_background" ), _alpha );
      ctx.rectangle( ((posx + padding + margin) - hmargin),
                     ((posy + padding + margin) - vmargin),
                     ((_width  - (padding * 2) - (margin * 2)) + (hmargin * 2)),
                     ((_height - (padding * 2) - (margin * 2)) + (vmargin * 2)) );
      ctx.fill();
    }

    /* Draw the text */
    var color = theme.get_color( "foreground" );
    if( mode.is_selected() && !exporting ) {
      color = theme.get_color( "nodesel_foreground" );
    } else if( parent == null ) {
      color = _link_color_set ? Granite.contrasting_foreground_color( link_color ) :
                                theme.get_color( "root_foreground" );
    } else if( style.is_fillable() ) {
      color = Granite.contrasting_foreground_color( link_color );
    }

    name.draw( ctx, theme, color, _alpha, exporting );

  }

  /* Draws the task checkbutton for leaf nodes */
  protected virtual void draw_leaf_task( Context ctx, RGBA color, RGBA? background ) {

    if( _task_count > 0 ) {

      double x, y, w, h;
      task_bbox( out x, out y, out w, out h );

      ctx.new_path();
      ctx.set_line_width( 2 );
      ctx.arc( (x + _task_radius), (y + _task_radius), _task_radius, 0, (2 * Math.PI) );

      if( (_task_done == 0) && (background != null) ) {
        Utils.set_context_color_with_alpha( ctx, background, _alpha );
      } else {
        Utils.set_context_color_with_alpha( ctx, color, _alpha );
      }
      ctx.fill_preserve();

      if( style.is_fillable() && (background != null) ) {
        Utils.set_context_color_with_alpha( ctx, background, _alpha );
      } else {
        Utils.set_context_color_with_alpha( ctx, color, _alpha );
      }
      ctx.stroke();

    }

  }

  /* Draws the task checkbutton for non-leaf nodes */
  protected virtual void draw_acc_task( Context ctx, RGBA color, RGBA? background ) {

    if( _task_count > 0 ) {

      double x, y, w, h;
      double complete = _task_done / (_task_count * 1.0);
      double angle    = ((complete * 360) + 270) * (Math.PI / 180.0);

      task_bbox( out x, out y, out w, out h );

      x += _task_radius;
      y += _task_radius;

      /* Draw circle outline */
      ctx.new_path();
      ctx.set_line_width( 2 );
      ctx.arc( x, y, _task_radius, 0, (2 * Math.PI) );
      if( style.is_fillable() && (background != null) ) {
        Utils.set_context_color_with_alpha( ctx, background, _alpha );
        ctx.fill();
      } else {
        Utils.set_context_color_with_alpha( ctx, color, _alpha );
        ctx.stroke();
      }

      /* Draw completeness pie */
      if( _task_done > 0 ) {
        Utils.set_context_color_with_alpha( ctx, color, _alpha );
        ctx.new_path();
        ctx.set_line_width( 2 );
        ctx.arc( x, y, (_task_radius - 1), (1.5 * Math.PI), angle );
        ctx.line_to( x, y );
        ctx.arc( x, y, (_task_radius - 1), (1.5 * Math.PI), (1.5 * Math.PI) );
        ctx.line_to( x, y );
        ctx.fill();
      }

    }

  }

  /* Draws the sticker associated with the node */
  protected virtual void draw_sticker( Context ctx, RGBA sel_color, RGBA bg_color ) {

    if( _sticker_buf != null ) {

      double x, y, w, h;
      RGBA color = mode.is_selected() ? sel_color : bg_color;

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

  //-------------------------------------------------------------
  // Draw the sequence number, if applicable.
  protected virtual void draw_sequence_num( Context ctx, RGBA sel_color, RGBA fg_color ) {

    if( _sequence_num != null ) {

      double x, y, w, h;
      RGBA color = mode.is_selected()  ? sel_color :
                   style.is_fillable() ?  Granite.contrasting_foreground_color( link_color ) :
                   fg_color;

      sequence_bbox( out x, out y, out w, out h );

      if( _mode == NodeMode.SELECTED ) {
        Utils.set_context_color_with_alpha( ctx, color, _alpha );
        ctx.move_to( x, y );
        ctx.rectangle( x, y, w, h );
        ctx.fill();
      }

      /* Draw sequence number */
      Pango.Rectangle ink_rect, log_rect;
      _sequence_num.layout.get_extents( out ink_rect, out log_rect );

      /* Output the text */
      ctx.move_to( (x - (log_rect.x / Pango.SCALE)), y );
      Utils.set_context_color_with_alpha( ctx, color, _alpha );
      Pango.cairo_show_layout( ctx, _sequence_num.layout );
      ctx.new_path();

    }

  }

  /* Draws the icon indicating that a note is associated with this node */
  protected virtual void draw_common_note( Context ctx, RGBA reg_color, RGBA sel_color, RGBA bg_color ) {

    if( note.length > 0 ) {

      double x, y, w, h;
      RGBA   color = mode.is_selected()                  ? sel_color :
                     (!is_root() && style.is_fillable()) ? Granite.contrasting_foreground_color( link_color ) :
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
      RGBA   color = mode.is_selected()                  ? sel_color :
                     (!is_root() && style.is_fillable()) ? Granite.contrasting_foreground_color( link_color ) :
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
      if( linked_node.is_local() ) {
        ctx.fill();
      } else {
        ctx.stroke();
      }

    }

  }

  /* Draw the fold indicator */
  protected virtual void draw_common_fold( Context ctx, RGBA bg_color, RGBA fg_color ) {

    if( (_children.length == 0) || is_summarized() ) return;

    double fx, fy, fw, fh;
    fold_bbox( out fx, out fy, out fw, out fh );

    if( folded ) {

      /* Draw the fold rectangle */
      Utils.set_context_color_with_alpha( ctx, bg_color, _alpha );
      ctx.new_path();
      ctx.set_line_width( 1 );
      ctx.rectangle( fx, fy, fw, fh );
      ctx.fill();

      /* Draw circles */
      Utils.set_context_color_with_alpha( ctx, fg_color, _alpha );
      ctx.new_path();
      ctx.arc( (fx + (fw / 3)), (fy + (fh / 2)), 2, 0, (2 * Math.PI) );
      ctx.fill();
      ctx.new_path();
      ctx.arc( (fx + ((fw / 3) * 2)), (fy + (fh / 2)), 2, 0, (2 * Math.PI) );
      ctx.fill();

    } else if( show_fold ) {

      /* Draw the fold rectangle */
      Utils.set_context_color_with_alpha( ctx, fg_color, _alpha );
      ctx.new_path();
      ctx.set_line_width( 2 );
      ctx.rectangle( fx, fy, fw, fh );
      ctx.fill_preserve();
      Utils.set_context_color_with_alpha( ctx, bg_color, _alpha );
      ctx.stroke();

    }

  }

  /* Draws the attachable highlight border to indicate when a node is attachable */
  protected virtual void draw_attachable( Context ctx, Theme theme, RGBA? frost_background ) {

    if( (mode == NodeMode.ATTACHABLE) || (mode == NodeMode.DROPPABLE) || (mode == NodeMode.HIGHLIGHTED) ) {

      double x, y, w, h;
      node_bbox( out x, out y, out w, out h );

      /* Draw highlight border */
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "attachable" ), _alpha );
      ctx.set_line_width( 4 );
      ctx.rectangle( x, y, w, h );
      ctx.stroke();

    }

  }

  /*
   Draw the link from this node to the parent node (or previous sibling if this is node
   is part of a sequence).
  */
  public virtual void draw_link( Context ctx, Theme theme ) {

    double  parent_x, parent_y;
    double  height   = (style.node_border.name() == "underlined") ? (_height - style.node_margin) : (_height / 2);
    double  tailx    = 0, taily = 0, tipx = 0, tipy = 0;
    double  child_x1 = 0;
    double  child_y1 = 0;
    double  child_x2 = 0;
    double  child_y2 = 0;
    double? ext_x, ext_y;

    var margin  = style.node_margin  ?? 0;
    var padding = style.node_padding ?? 0;

    /* Get the parent's link point */
    var prev = previous_sibling();
    var link_sibling = parent.sequence && (prev != null);
    if( link_sibling ) {
      prev.link_point( out parent_x, out parent_y, true );
    } else {
      parent.link_point( out parent_x, out parent_y );
    }

    Utils.set_context_color_with_alpha( ctx, _link_color, ((_parent.alpha != 1.0) ? _parent.alpha : _alpha) );
    ctx.set_line_cap( LineCap.ROUND );

    if( link_sibling ) {
      switch( side ) {
        case NodeSide.LEFT :
          child_x1 = posx + _width - margin - padding;
          child_x2 = child_x1;
          child_y1 = (posy + margin);
          child_y2 = child_y1;
          break;
        case NodeSide.RIGHT :
          child_x1 = posx + margin + padding;
          child_x2 = child_x1;
          child_y1 = (posy + margin);
          child_y2 = child_y1;
          break;
        default :
          if( (side == NodeSide.BOTTOM) && (style.node_border.name() != "underlined") ) {
            child_x1 = (posx + margin);
            child_x2 = child_x1;
            child_y1 = posy + margin + padding;
            child_y2 = child_y1;
          } else {
            child_x1 = (posx + margin);
            child_x2 = child_x1;
            child_y1 = posy + _height - margin - padding;
            child_y2 = child_y1;
          }
          break;
      }
      style.draw_link( ctx, parent, this, true, parent_x, parent_y, child_x1, child_y1, child_x2, child_y2, out tailx, out taily, out tipx, out tipy );
    } else {
      switch( side ) {
        case NodeSide.LEFT   :
          child_x1 = (posx + _total_width - margin);
          child_x2 = (posx + _width - margin);
          child_y1 = (posy + height);
          child_y2 = child_y1;
          break;
        case NodeSide.RIGHT  :
          child_x1 = (posx + margin);
          child_x2 = child_x1;
          child_y1 = (posy + height);
          child_y2 = child_y1;
          break;
        case NodeSide.TOP    :
          child_x1 = (posx + (_width / 2));
          child_x2 = child_x1;
          child_y1 = (posy + _total_height - margin);
          child_y2 = (posy + _height - margin);
          break;
        case NodeSide.BOTTOM :
          child_x1 = (posx + (_width / 2));
          child_x2 = child_x1;
          child_y1 = (posy + margin);
          child_y2 = child_y1;
          break;
      }
      style.draw_link( ctx, parent, this, false, parent_x, parent_y, child_x1, child_y1, child_x2, child_y2, out tailx, out taily, out tipx, out tipy );
    }


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
  protected virtual void draw_resizer( Context ctx, Theme theme, bool exporting ) {

    /* Only draw the resizer if we are the current node */
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

  /* Draws the node callout, if one exists */
  protected virtual void draw_callout( Context ctx, Theme theme, bool exporting ) {
    if( _callout != null ) {
      _callout.draw( ctx, theme, exporting );
    }
  }

  /* Draws the node on the screen */
  public virtual void draw( Context ctx, Theme theme, bool motion, bool exporting ) {

    var nodesel_background = theme.get_color( "nodesel_background" );
    var nodesel_foreground = theme.get_color( "nodesel_foreground" );

    /* Draw tree_bbox */
    if( is_summarized() || is_summary() ) {
      Utils.set_context_color_with_alpha( ctx, nodesel_background, 0.1 );
      ctx.rectangle( tree_bbox.x, tree_bbox.y, tree_bbox.width, tree_bbox.height );
      ctx.fill();
    }

    /* Draw bbox */
    /*
    double x, y, w, h;
    bbox( out x, out y, out w, out h );
    Utils.set_context_color_with_alpha( ctx, nodesel_background, 0.1 );
    ctx.rectangle( x, y, w, h );
    ctx.fill();
    */

    /* If this is a root node, draw specifically for a root node */
    if( is_root() ) {

      var background = theme.get_color( "root_background" );
      var foreground = theme.get_color( "root_foreground" );

      if( _link_color_set ) {
        background = _link_color;
        foreground = Granite.contrasting_foreground_color( background );
      }

      draw_shape( ctx, theme, background, exporting );
      draw_name( ctx, theme, exporting );
      draw_image( ctx, theme );
      if( is_leaf() ) {
        draw_leaf_task( ctx, foreground, null );
      } else {
        draw_acc_task( ctx, foreground, null );
      }
      draw_sticker( ctx, nodesel_background, background );
      draw_common_note( ctx, foreground, nodesel_foreground, foreground );
      draw_link_node(   ctx, foreground, nodesel_foreground, foreground );
      draw_common_fold( ctx, foreground, background );
      draw_attachable(  ctx, theme, background );
      draw_resizer( ctx, theme, exporting );

    /* Otherwise, draw the node as a non-root node */
    } else {

      var background = theme.get_color( "background" );
      var foreground = theme.get_color( "foreground" );

      draw_shape( ctx, theme, _link_color, exporting );
      draw_name( ctx, theme, exporting );
      draw_image( ctx, theme );
      if( is_leaf() ) {
        draw_leaf_task( ctx, _link_color, background );
      } else {
        draw_acc_task( ctx, _link_color, background );
      }
      draw_sticker( ctx, nodesel_background, background );
      draw_sequence_num( ctx, nodesel_foreground, foreground );
      draw_common_note( ctx, foreground, nodesel_foreground, background );
      draw_link_node(   ctx, foreground, nodesel_foreground, foreground );
      draw_common_fold( ctx, _link_color, background );
      draw_attachable(  ctx, theme, background );
      draw_resizer( ctx, theme, exporting );
    }

    draw_callout( ctx, theme, exporting );

  }

  /*
   Draws all of the nodes on the same side of the parent.  Draws the nodes such that
   overlapping links are drawn in a more meaningful way.
  */
  private void draw_side_links( Context ctx, Theme theme, int first, int last ) {
    var first_rside = _children.index( first ).relative_side();
    var mid         = first + 1;
    while( (mid < last) && (_children.index( mid ).relative_side() == first_rside) ) mid++;
    for( int i=first; i<mid; i++ ) {
      _children.index( i ).draw_links( ctx, theme );
    }
    for( int i=(last - 1); i>=mid; i-- ) {
      _children.index( i ).draw_links( ctx, theme );
    }
  }

  /* Draw all of the node links */
  public void draw_links( Context ctx, Theme theme ) {
    if( !is_root() ) {
      draw_link( ctx, theme );
    }
    if( !folded && traversable() ) {
      var int_child_len = (int)_children.length;
      if( int_child_len > 0 ) {
        var first_side = side_count( _children.index( 0 ).side );
        draw_side_links( ctx, theme, 0, first_side );
        if( first_side < int_child_len ) {
          draw_side_links( ctx, theme, first_side, int_child_len );
        }
      }
    }
  }

  /* Draw this node and all child nodes */
  public void draw_all( Context ctx, Theme theme, Node? current, bool motion, bool exporting ) {
    if( this != current ) {
      if( !folded && traversable() ) {
        for( int i=0; i<_children.length; i++ ) {
          _children.index( i ).draw_all( ctx, theme, current, motion, exporting );
        }
      }
      draw( ctx, theme, motion, exporting );
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
