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

public class Node : BaseNode {

  // Member variables
  private   CanvasText   _name;
  private   string       _note         = "";
  protected double       _task_radius  = 7;
  private   int          _task_count   = 0;
  private   int          _task_done    = 0;
  private   RGBA?        _link_color      = {(float)1.0, (float)1.0, (float)1.0, (float)1.0};
  private   bool         _link_color_set  = false;
  private   bool         _link_color_root = false;
  private   double       _min_width      = 50;
  private   NodeImage?   _image          = null;
  private   NodeLink?    _linked_node    = null;
  private   string?      _sticker        = null;
  private   Pixbuf?      _sticker_buf    = null;
  private   SequenceNum  _sequence_num   = null;
  private   Callout?     _callout        = null;
  private   bool         _sequence       = false;
  private   Tags         _tags;

  // Properties
  public CanvasText name {
    get {
      return( _name );
    }
    set {
      _name = value;
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
  public bool folded    { get; set; default = false; }
  public bool show_fold { get; set; default = false; }
  public bool group     { get; set; default = false; }
  public RGBA? link_color {
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
  public Connection? last_selected_connection { get; set; default = null; }
  public NodeImage? image {
    get {
      return( _image );
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
  public NodeLink? linked_node {
    get {
      return( _linked_node );
    }
    set {
      _linked_node = value;
      if( _linked_node != null ) {
        _linked_node.normalize( _map );
      }
      update_size();
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
  public Tags tags {
    get {
      return( _tags );
    }
  }

  //-------------------------------------------------------------
  // Default constructor.
  public Node( MindMap map, Layout? layout ) {
    base( map, layout );
    _name = new CanvasText( map );
    _tags = new Tags();
    _name.resized.connect( position_text_and_update_size );
  }

  //-------------------------------------------------------------
  // Constructor initializing string.
  public Node.with_name( MindMap map, string n, Layout? layout ) {
    base( map, layout );
    _name = new CanvasText.with_text( map, n );
    _tags = new Tags();
    _name.resized.connect( position_text_and_update_size );
  }

  //-------------------------------------------------------------
  // Constructor from an XML node.
  public Node.from_xml( MindMap map, Layout? layout, Xml.Node* n, bool isroot ) {
    _name = new CanvasText.with_text( map, "" );
    _tags = new Tags();
    base.from_xml( map, layout, n, isroot );
    _name.resized.connect( position_text_and_update_size );
  }

  //-------------------------------------------------------------
  // Creates a node.
  public override BaseNode make_node( MindMap map ) {
    var node = new Node( map, null );
    return( node );
  }

  //-------------------------------------------------------------
  // Copies just the variables of the node, minus the children
  // nodes.
  public override void copy_variables( BaseNode node, ImageManager im ) {
    var n = (Node)node;
    base.copy_variables( n, im );
    _task_radius    = n._task_radius;
    _task_count     = n._task_count;
    _task_done      = n._task_done;
    _image          = (n._image == null) ? null : new NodeImage.from_node_image( im, n._image, n.style.node_width );
    _name.copy( n._name );
    _link_color      = n._link_color;
    _link_color_set  = n._link_color_set;
    _link_color_root = n._link_color_root;
    folded           = n.folded;
    note             = n.note;
    style            = n.style;
    sticker          = n.sticker;
    sequence         = n.sequence;
    _tags.copy_tags( n.tags );
  }

  //-------------------------------------------------------------
  // Handle any changes to the alpha value.
  protected override void alpha_callback() {
    if( _callout != null ) {
      _callout.alpha = _alpha;
    }
  }

  //-------------------------------------------------------------
  // Handle any changes to the style.
  protected override void style_callback() {
    name.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
    name.set_text_alignment( _style.node_text_align );
    if( _sequence_num != null ) {
      _sequence_num.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
    }
    name.max_width = style.node_width;
    if( _callout != null ) {
      _callout.position_text( false );
    }
    position_text_and_update_size();
  }

  //-------------------------------------------------------------
  // Handle any changes to the mode value.
  protected override void mode_callback() {
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

  //-------------------------------------------------------------
  // Sets the posx value only, leaving the children positions alone.
  public override void set_posx_only( double value ) {
    base.set_posx_only( value );
    position_text();
  }

  //-------------------------------------------------------------
  // Sets the posy value only, leaving the children positions
  // alone.
  public override void set_posy_only( double value ) {
    base.set_posy_only( value );
    position_text();
  }

  //-------------------------------------------------------------
  // Sets the alpha value without propagating this to the children.
  public override void set_alpha_only( double value ) {
    base.set_alpha_only( value );
    if( _callout != null ) {
      _callout.alpha = value;
    }
  }

  //-------------------------------------------------------------
  // Sets the posx value only, leaving the children positions alone.
  public override void adjust_posx_only( double value ) {
    base.adjust_posx_only( value );
    position_text();
  }

  //-------------------------------------------------------------
  // Sets the posy value only, leaving the children positions alone.
  public override void adjust_posy_only( double value ) {
    base.adjust_posy_only( value );
    position_text();
  }

  //-------------------------------------------------------------
  // Updates the sequence number pango layout.
  public void update_sequence_num() {
    if( parent == null ) return;
    var pnode = (parent as Node);
    if( (pnode != null) && pnode.sequence ) {
      if( _sequence_num == null ) {
        _sequence_num = new SequenceNum( _map );
        _sequence_num.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
      }
      var seq_type = SequenceNumType.NUM;
      if( (pnode._sequence_num != null) && (pnode._sequence_num.seq_type == SequenceNumType.NUM) ) {
        seq_type = SequenceNumType.LETTER;
      }
      _sequence_num.set_num( index(), seq_type );
    } else {
      _sequence_num = null;
    }
    position_text_and_update_size();
  }

  //-------------------------------------------------------------
  // Updates the tree_bbox.
  protected override void update_tree_bbox( double diffx, double diffy ) {
    base.update_tree_bbox( diffx, diffy );
    position_text();
  }

  //-------------------------------------------------------------
  // Called whenever the canvas text is resized.
  private void position_text_and_update_size() {
    position_text();
    update_size();
  }

  //-------------------------------------------------------------
  // Calculates the node size based on the width and height of
  // all of the node elements.  Also returns whether the node
  // width was dictated by the embedded image or not.
  public override void calculate_node_size( out double width, out double height ) {

    int margin       = style.node_margin;
    int padding      = style.node_padding;
    var stk_height   = sticker_height();
    var noname_width = task_width() + sticker_width() + sequence_width() + note_width() + linked_node_width();
    var name_width   = noname_width + _name.width;
    var name_height  = (_name.height < stk_height) ? stk_height : _name.height;
    var image_width  = (_image != null) ? _image.width : 0;
    var image_height = (_image != null) ? (_image.height + padding) : 0;
    var tg_width     = noname_width + tags_width();
    var tg_height    = tags_height();
    var all_width    = Math.fmax( name_width, Math.fmax( image_width, tg_width ) );

    width      = (margin * 2) + (padding * 2) + all_width;
    height     = (margin * 2) + (padding * 2) + image_height + name_height + tg_height;

  }

  //-------------------------------------------------------------
  // Updates the total size which includes the callout.
  protected override void update_total_size() {

    if( (_callout == null) || _callout.mode.is_disconnected() ) {
      _total_width  = _width;
      _total_height = _height;
    } else if( side.horizontal() ) {
      var margin         = style.node_margin;
      var callout_width  = _callout.total_width + (margin * 2);
      var callout_height = _callout.total_height + margin;
      _total_width  = (_width < callout_width) ? callout_width : _width;
      _total_height = _height + callout_height;
    } else {
      var margin         = style.node_margin;
      var callout_width  = _callout.total_width + margin;
      var callout_height = _callout.total_height + (margin * 2);
      _total_width  = _width + callout_width;
      _total_height = (_height < callout_height) ? callout_height : _height;
    }

  }

  //-------------------------------------------------------------
  // Sets all callouts to the specified mode.
  public void set_callout_modes( CalloutMode mode ) {
    if( _callout != null ) {
      _callout.mode = mode;
    }
    for( int i=0; i<_children.length; i++ ) {
      var child = (_children.index( i ) as Node);
      if( child != null ) {
        child.set_callout_modes( mode );
      }
    }
  }

  //-------------------------------------------------------------
  // Updates the size of all nodes within this tree.
  public override void update_tree() {
    _name.update_size();
    base.update_tree();
  }

  //-------------------------------------------------------------
  // Sets the node image to the given value, updating the image
  // manager accordingly.
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

  //-------------------------------------------------------------
  // Returns true if this node can be traversed in the hierarchy.
  public override bool traversable() {
    return( !folded );
  }

  //-------------------------------------------------------------
  // Returns true if this node exists within a group.
  public bool is_grouped() {
    var n = (BaseNode)this;
    while( n != null ) {
      var node = (n as Node);
      if( (node != null) && node.group ) {
        return( true );
      }
      n = n.parent;
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns the number of groups betwen the current node and the
  // specified ancestor node.
  public int groups_between( Node node ) {
    var n     = (BaseNode)this;
    var count = 0;
    while( !n.is_root() && (n != node) ) {
      var curr = (n as Node);
      count += ((curr != null) && curr.group) ? 1 : 0;
      n = n.parent;
    }
    return( count );
  }

  //-------------------------------------------------------------
  // Returns true if this node is a task.
  public bool is_task() {
    return( (_task_count > 0) && is_leaf() );
  }

  //-------------------------------------------------------------
  // Returns true if this task node is complete.
  public bool is_task_done() {
    return( _task_count == _task_done );
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

  //-------------------------------------------------------------
  // Returns the task completion percentage value.
  public double task_completion_percentage() {
    return( (_task_done / (_task_count * 1.0)) * 100 );
  }

  //-------------------------------------------------------------
  // Returns the positional information for where the task item
  // is located (if it exists).
  protected virtual void task_bbox( out double x, out double y, out double w, out double h ) {
    int    margin     = style.node_margin;
    int    padding    = style.node_padding;
    double img_height = (_image == null) ? 0 : (_image.height + padding);
    x = posx + margin + padding;
    y = posy + margin + padding + img_height + (((_height - (img_height + (padding * 2) + (margin * 2))) / 2) - _task_radius);
    w = _task_radius * 2;
    h = _task_radius * 2;
  }

  //-------------------------------------------------------------
  // Returns the positional information for where the sticker is
  // located (if it exists).
  protected virtual void sticker_bbox( out double x, out double y, out double w, out double h ) {
    int    margin     = style.node_margin;
    int    padding    = style.node_padding;
    double img_height = (_image == null) ? 0 : (_image.height + padding);
    double stk_height = (_sticker_buf == null) ? 0 : _sticker_buf.height;
    x = posx + margin + padding + task_width();
    y = posy + margin + padding + img_height + ((_height - (img_height + (padding * 2) + (margin * 2))) / 2) - (stk_height / 2);
    w = (_sticker_buf == null) ? 0 : _sticker_buf.width;
    h = (_sticker_buf == null) ? 0 : _sticker_buf.height;
  }

  //-------------------------------------------------------------
  // Returns the positional information for where the sequence
  // number is located (if it exists).
  protected virtual void sequence_bbox( out double x, out double y, out double w, out double h ) {
    int margin  = style.node_margin;
    int padding = style.node_padding;
    x = posx + margin + padding + task_width() + sticker_width();
    y = name.posy;
    w = sequence_width();
    h = sequence_height();
  }

  //-------------------------------------------------------------
  // Returns the positional information for where the linked node
  // indicator is located (if it exists).
  protected virtual void linked_node_bbox( out double x, out double y, out double w, out double h ) {
    int    margin     = style.node_margin;
    int    padding    = style.node_padding;
    double img_height = (_image == null) ? 0 : (_image.height + padding);
    x = posx + (_width - (linked_node_width() + padding + margin)) + _ipadx;
    y = posy + padding + margin + img_height + ((_height - (img_height + (padding * 2) + (margin * 2))) / 2) - 5;
    w = 11;
    h = 11;
  }

  //-------------------------------------------------------------
  // Returns the positional information for where the note item
  // is located (if it exists).
  protected virtual void note_bbox( out double x, out double y, out double w, out double h ) {
    int    margin     = style.node_margin;
    int    padding    = style.node_padding;
    double img_height = (_image == null) ? 0 : (_image.height + padding);
    x = posx + (_width - (note_width() + linked_node_width() + padding + margin)) + _ipadx;
    y = posy + padding + margin + img_height + ((_height - (img_height + (padding * 2) + (margin * 2))) / 2) - 5;
    w = 11;
    h = 11;
  }

  //-------------------------------------------------------------
  // Returns the positional information of the stored image (if
  // no image exists, the behavior of this method is undefined).
  protected virtual void image_bbox( out double x, out double y, out double w, out double h ) {
    int margin  = style.node_margin;
    int padding = style.node_padding;
    x = (posx + (_width / 2)) - ((_image == null) ? 0 : (_image.width / 2));
    y = posy + padding + margin;
    w = (_image == null) ? 0 : _image.width;
    h = (_image == null) ? 0 : _image.height;
  }

  //-------------------------------------------------------------
  // Returns the positional information for where the given tag
  // indicator exists.
  protected virtual void tag_bbox( int index, out double x, out double y, out double w, out double h ) {
    int margin  = style.node_margin;
    int padding = style.node_padding;
    x = name.posx + (index * 17);
    y = posy + (_height - (margin + padding) - 8);
    w = 12;
    h = 8;
  }

  //-------------------------------------------------------------
  // Returns the positional information for all of the tags.
  protected virtual void tags_bbox( out double x, out double y, out double w, out double h ) {
    tag_bbox( 0, out x, out y, out w, out h );
    if( _tags.size() > 1 ) {
      double bx, by, bw, bh;
      tag_bbox( (_tags.size() - 1), out bx, out by, out bw, out bh );
      w = (bx + bw);
    }
  }

  //-------------------------------------------------------------
  // Returns true if the given cursor coordinates lies within the
  // task checkbutton area.
  public virtual bool is_within_task( double x, double y ) {
    if( _task_count > 0 ) {
      double tx, ty, tw, th;
      task_bbox( out tx, out ty, out tw, out th );
      return( Utils.is_within_bounds( x, y, tx, ty, tw, th ) );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if the given cursor coordinates lies within the
  // note icon area.
  public virtual bool is_within_note( double x, double y ) {
    if( note.length > 0 ) {
      double nx, ny, nw, nh;
      note_bbox( out nx, out ny, out nw, out nh );
      return( Utils.is_within_bounds( x, y, nx, ny, nw, nh ) );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if the given cursor coordinates lies within the
  // linked node indicator area.
  public virtual bool is_within_linked_node( double x, double y ) {
    if( linked_node != null ) {
      double lx, ly, lw, lh;
      linked_node_bbox( out lx, out ly, out lw, out lh );
      return( Utils.is_within_bounds( x, y, lx, ly, lw, lh ) );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if the given cursor coordinates lie within the
  // fold indicator area.
  public virtual bool is_within_fold( double x, double y ) {
    if( (_children.length > 0) && (summarized_node == null) ) {
      double fx, fy, fw, fh;
      fold_bbox( out fx, out fy, out fw, out fh );
      return( Utils.is_within_bounds( x, y, fx, fy, fw, fh ) );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if the given cursor coordinates lie within the
  // fold indicator surrounding area.
  public virtual bool is_within_fold_area( double x, double y ) {
    if( (_children.length > 0) && (summarized_node == null) ) {
      double fx, fy, fw, fh;
      var pad = 20;
      fold_bbox( out fx, out fy, out fw, out fh );
      return( Utils.is_within_bounds( x, y, (fx - pad), (fy - pad), (fw + (pad * 2)), (fh + (pad * 2)) ) );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if the given cursor coordinates lie within the
  // image area.
  public virtual bool is_within_image( double x, double y ) {
    if( _image != null ) {
      double ix, iy, iw, ih;
      image_bbox( out ix, out iy, out iw, out ih );
      return( Utils.is_within_bounds( x, y, ix, iy, iw, ih ) );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if the given cursor coordinates lie within the
  // tags area.
  public virtual bool is_within_tags( double x, double y ) {
    if( _tags.size() > 0 ) {
      double tx, ty, tw, th;
      tags_bbox( out tx, out ty, out tw, out th );
      return( Utils.is_within_bounds( x, y, tx, ty, tw, th ) );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if the given coordinates are within the node title
  // text.
  public virtual bool is_within_title( double x, double y ) {
    return( (_name != null) && (_name.is_within( x, y ) ) );
  }

  //-------------------------------------------------------------
  // Finds the node which contains the given pixel coordinates.
  public override BaseNode? contains( double x, double y, bool allow_selected ) {
    if( (allow_selected || ((mode != NodeMode.CURRENT) && (mode != NodeMode.SELECTED))) &&
        (is_within_node( x, y ) || is_within_fold_area( x, y )) ) {
      return( this );
    } else if( !folded ) {
      for( int i=0; i<_children.length; i++ ) {
        var tmp = _children.index( i ).contains( x, y, allow_selected );
        if( tmp != null ) {
          return( tmp );
        }
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Finds the callout which contains the given pixel coordinates.
  public override Callout? contains_callout( double x, double y ) {
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

  //-------------------------------------------------------------
  // LOAD
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Loads the name value from the given XML node.
  private void load_name( Xml.Node* n ) {
    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      name.text.insert_text( 0, n->children->get_content() );
    } else {
      name.load( n );
      position_text();
    }
  }

  //-------------------------------------------------------------
  // Loads the note value from the given XML node.
  private void load_note( Xml.Node* n ) {
    if( (n->children != null) && (n->children->type == Xml.ElementType.TEXT_NODE) ) {
      note = n->children->get_content();
    }
  }

  //-------------------------------------------------------------
  // Loads the image information from the given XML node.
  private void load_image( ImageManager im, Xml.Node* n ) {
    _image = new NodeImage.from_xml( im, n, style.node_width );
    if( !_image.valid ) {
      _image = null;
      update_size();
    }
  }

  //-------------------------------------------------------------
  // Loads the node link from the given XML node.
  private void load_node_link( Xml.Node* n ) {
    _linked_node = new NodeLink.from_xml( n );
  }

  //-------------------------------------------------------------
  // Loads the style information from the given XML node.
  private void load_style( Xml.Node* n ) {
    base.load_style( n );
    _name.set_text_alignment( _style.node_text_align );
    _name.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
    if( _sequence_num != null ) {
      _sequence_num.set_font( _style.node_font.get_family(), (_style.node_font.get_size() / Pango.SCALE) );
    }
  }

  //-------------------------------------------------------------
  // Loads the callout information.
  private void load_callout( Xml.Node* n ) {
    if( _callout == null ) {
      callout = new Callout( this );
    }
    callout.load( n );
  }

  //-------------------------------------------------------------
  // Loads the file contents into this instance.
  public override void load( MindMap map, Xml.Node* n, bool isroot ) {

    string? tc = n->get_prop( "task" );
    if( tc != null ) {
      _task_count = 1;
      _task_done  = int.parse( tc );
    }

    string? ln = n->get_prop( "link" );
    if( ln != null ) {
      _linked_node = new NodeLink.for_local( int.parse( ln ) );
    }

    string? f = n->get_prop( "fold" );
    if( f != null ) {
      folded = bool.parse( f );
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

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "nodename"  :  load_name( it );  break;
          case "nodenote"  :  load_note( it );  break;
          case "nodeimage" :  load_image( map.image_manager, it );  break;
          case "nodelink"  :  load_node_link( it );  break;
          case "taglist"   :  tags.load_indices( it, _map.model.tags );  break;
          case "callout"   :  load_callout( it );  break;
          default          :  break;
        }
      }
    }

    // If a color was not specified and this node is a root node, colorize the children
    if( isroot ) {
      for( int j=0; j<_children.length; j++ ) {
        var child = (_children.index( j ) as Node);
        if( (child != null) && !child._link_color_set ) {
          child.link_color_child = map.get_theme().next_color();
        }
      }
    }

    base.load( map, n, isroot );

    // Make sure that the name is positioned properly
    position_text();

  }

  //-------------------------------------------------------------
  // SAVE
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Saves the current node.
  public override Xml.Node* save() {
    return( save_node( "node" ) );
  }

  //-------------------------------------------------------------
  // Saves the node contents to the given data output stream.
  protected override Xml.Node* save_node( string xml_name ) {

    Xml.Node* node = base.save_node( xml_name );

    if( is_task() ) {
      node->new_prop( "task", _task_done.to_string() );
    }
    node->new_prop( "fold", folded.to_string() );
    node->new_prop( "sequence", sequence.to_string() );
    if( is_root() ) {
      if( _link_color_set ) {
        node->new_prop( "color", Utils.color_from_rgba( _link_color ) );
      }
    } else {
      node->new_prop( "color", Utils.color_from_rgba( _link_color ) );
      node->new_prop( "colorroot", link_color_root.to_string() );
    }
    if( _sticker != null ) {
      node->new_prop( "sticker", _sticker );
    }
    node->new_prop( "group", group.to_string() );

    if( _image != null ) {
      _image.save( node );
    }

    node->add_child( name.save( "nodename" ) );
    node->new_text_child( null, "nodenote", note );
    node->add_child( tags.save_indices( _map.model.tags ) );

    if( _linked_node != null ) {
      node->add_child( _linked_node.save() );
    }

    if( _callout != null ) {
      node->add_child( _callout.save() );
    }

    return( node );

  }

  //-------------------------------------------------------------
  // Sets the resizable property on the node image, if it exists.
  public void set_resizable( bool resizable ) {
    if( _image != null ) {
      _image.resizable = resizable;
    }
  }

  //-------------------------------------------------------------
  // Resizes the node width by the given amount.
  public override void resize( double diff ) {
    diff = resizer_on_left() ? (0 - diff) : diff;
    var int_diff  = (int)diff;
    if( (_name.width + diff) < tags_width() ) return;
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

  //-------------------------------------------------------------
  // FOLDING
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Sets the fold for this node to the given value.  Appends
  // this node to the changed list if the folded value changed.
  public void set_fold( bool value, bool deep, Array<Node>? changed = null ) {
    if( deep ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).set_fold( value, deep, changed );
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

  //-------------------------------------------------------------
  // Sets the fold value of this node only.  This should only be
  // used when we are undo'ing a fold operation.
  public void set_fold_only( bool value ) {
    folded = value;
    layout.handle_update_by_fold( this );
  }

  //-------------------------------------------------------------
  // Returns true if there is at least one node that is foldable
  // due to its tasks being completed.
  public override bool completed_tasks_foldable() {
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

  //-------------------------------------------------------------
  // Returns true if any node is found to be unfoldable.
  public override bool unfoldable() {
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

  //-------------------------------------------------------------
  // Recursively spans node tree folding any nodes which contain
  // fully completed tasks.
  public override void fold_completed_tasks( Array<Node> changed ) {
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

  //-------------------------------------------------------------
  // SIZE METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Returns the width of the sticker.
  public double sticker_width() {
    return( (_sticker_buf != null) ? (_sticker_buf.width + _ipadx) : 0 );
  }

  //-------------------------------------------------------------
  // Returns the height of the sticker.
  public double sticker_height() {
    return( (_sticker_buf != null) ? _sticker_buf.height : 0 );
  }

  //-------------------------------------------------------------
  // Returns the width of the sequence number.
  public double sequence_width() {
    return( (_sequence_num != null) ? _sequence_num.width : 0 );
  }

  //-------------------------------------------------------------
  // Returns the height of the sequence number.
  public double sequence_height() {
    return( (_sequence_num != null) ? _sequence_num.height : 0 );
  }

  //-------------------------------------------------------------
  // Returns the amount of internal width to draw the task
  // checkbutton.
  public double task_width() {
    return( (_task_count > 0) ? ((_task_radius * 2) + _ipadx) : 0 );
  }

  //-------------------------------------------------------------
  // Returns the width of the note indicator.
  public double note_width() {
    return( (note.length > 0) ? (10 + _ipadx) : 0 );
  }

  //-------------------------------------------------------------
  // Returns the width of the linked node indicator.
  public double linked_node_width() {
    return( (linked_node != null) ? (10 + _ipadx) : 0 );
  }

  //-------------------------------------------------------------
  // Returns the total width of the tag indicators.
  public double tags_width() {
    var num_tags = _tags.size();
    return( (num_tags == 0) ? 0 : ((num_tags * 12) + ((num_tags - 1) * 5)) );
  }

  //-------------------------------------------------------------
  // Returns the height of the tags indicators.
  public double tags_height() {
    return( (_tags.size() > 0) ? (5 + _ipadx) : 0 );
  }

  //-------------------------------------------------------------
  // Adjusts the position of the text object.
  private void position_text() {

    double node_width, node_height, name_space;

    calculate_node_size( out node_width, out node_height, out name_space );

    var margin     = style.node_margin;
    var padding    = style.node_padding;
    var stk_height = sticker_height();
    var img_height = (_image != null) ? (_image.height + padding) : 0;
    var orig_posx  = name.posx;
    var orig_posy  = name.posy;

    name.posx = posx + margin + padding + task_width() + sticker_width() + sequence_width();
    name.posy = posy + margin + padding + img_height + ((name.height < stk_height) ? ((stk_height - name.height) / 2) : 0);

    if( style.node_text_align != null ) {
      switch( style.node_text_align ) {
        case Pango.Alignment.CENTER :  name.posx += (name_space / 2);  break;
        case Pango.Alignment.RIGHT  :  name.posx += name_space;        break;
        default                     :  break;
      }
    }

    if( (_callout != null) && ((orig_posx != name.posx) || (orig_posy != name.posy)) ) {
      _callout.position_text( true );
    }

  }

  //-------------------------------------------------------------
  // Detaches this node from its parent node.
  public override void detach( NodeSide side ) {
    if( parent != null ) {
      propagate_task_info_up( (0 - _task_count), (0 - _task_done) );
      _sequence_num = null;
      base.detach( side );
    }
  }

  //-------------------------------------------------------------
  // Removes only this node from its parent, attaching all
  // children nodes of this node to the parent.  If the parent
  // node does not exist (i.e., this node is a root node, the
  // children nodes will become top-level nodes themselves.
  public override void delete_only() {
    if( parent == null ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i )._sequence_num = null;
      }
    } else {
      propagate_task_info_up( (0 - _task_count), (0 - _task_done) );
      for( int i=(int)(_children.length - 1); i>=0; i-- ) {
        _children.index( i )._sequence_num = null;
      }
    }
    base.delete_only();
  }

  //-------------------------------------------------------------
  // Common attachment code that is called by the higher-level attachment
  // methods.
  protected override void attach_common( int index, Theme? theme ) {
    base.attach_common( index, theme );
    propagate_task_info_up( _task_count, _task_done );
    var pnode = (parent as Node);
    if( (pnode != null) && pnode.sequence ) {
      for( int i=index; i<parent.children().length; i++ ) {
        var child = (parent.children().index( i ) as Node);
        if( child != null ) {
          child.update_sequence_num();
        }
      }
    }
    if( theme != null ) {
      if( main_branch() ) {
        link_color_child = theme.next_color();
      } else if( pnode != null ) {
        link_color_child = pnode.link_color;
      }
    }
  }

  //-------------------------------------------------------------
  // Returns a reference to the first child of this node.
  public override BaseNode? first_child( NodeSide? side = null ) {
    return( !folded ? base.first_child( side ) : null );
  }

  //-------------------------------------------------------------
  // Returns a reference to the last child of this node.
  public override BaseNode? last_child( NodeSide? side = null ) {
    return( !folded ? base.last_child( side ) : null );
  }

  //-------------------------------------------------------------
  // TASKS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Propagates task information toward the leaf nodes.
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

  //-------------------------------------------------------------
  // Propagates a change in the task_done for this node to all
  // parent nodes.
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

  //-------------------------------------------------------------
  // Propagates the given task enable information down and up the
  // tree.
  private void propagate_task_info( bool? enable, bool? done ) {
    int task_count = _task_count;
    int task_done  = _task_done;
    propagate_task_info_down( enable, done );
    propagate_task_info_up( (_task_count - task_count), (_task_done - task_done) );
  }

  //-------------------------------------------------------------
  // Returns true if this node's task indicator is currently enabled.
  public bool task_enabled() {
    return( _task_count > 0 );
  }

  //-------------------------------------------------------------
  // Returns true if this node's task indicator indicates that it
  // is currently done.
  public bool task_done() {
    return( _task_count == _task_done );
  }

  //-------------------------------------------------------------
  // Sets the task enable to the given value.
  public void enable_task( bool task ) {
    propagate_task_info( task, null );
  }

  //-------------------------------------------------------------
  // Sets the task done indicator to the given value (0 or 1) and
  // propagates the change to all parent nodes.
  public void set_task_done( bool done ) {
    propagate_task_info( null, done );
  }

  //-------------------------------------------------------------
  // Toggles the current value of task done and propagates the
  // change to all parent nodes.
  public void toggle_task_done( ref Array<NodeTaskInfo?> changed ) {
    var change = NodeTaskInfo( task_enabled(), task_done(), this );
    changed.append_val( change );
    set_task_done( _task_done == 0 );
  }

  //-------------------------------------------------------------
  // TAGS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Adds the given tag to this node.
  public bool add_tag( Tag tag ) {
    var added = tags.add_tag( tag );
    update_size();
    return( added );
  }

  //-------------------------------------------------------------
  // Removes the specified tag from the list of tags.
  public bool remove_tag( Tag tag, Array<Node>? nodes = null ) {
    var index = tags.get_tag_index( tag );
    if( index != -1 ) {
      tags.remove_tag( index );
      update_size();
      if( nodes != null ) {
        nodes.append_val( this );
      } else {
        return( true );
      }
    }
    if( nodes != null ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).remove_tag( tag, nodes );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if the given node is highlightable based on its
  // current tags, the tags selected to highlight and the given
  // combo type.
  public bool highlightable( Tags tags, TagComboType combo_type ) {
    return( combo_type.highlightable( _tags, tags ) );
  }

  //-------------------------------------------------------------
  // Checks to see if the current node contains the given tag.
  // If it exists, causes this node to be highlighted.  Performs
  // this procedure recursively.
  public void highlight_tags( Tags tags, TagComboType combo_type ) {
    if( combo_type.highlightable( _tags, tags ) ) {
      set_alpha_only( 1.0 );
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).highlight_tags( tags, combo_type );
    }
  }

  //-------------------------------------------------------------
  // MISCELLANEOUS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Returns true if the given node is folded.
  private bool is_folded( BaseNode node ) {
    var n = (node as Node);
    return( (n != null) && node.folded );
  }

  //-------------------------------------------------------------
  // Returns the ancestor node that is folded or returns null if
  // no ancestor nodes are folded.
  public Node? folded_ancestor() {
    var node = parent;
    while( node != null ) {
      if( is_folded( node ) ) {
        return( (Node)node );
      }
      node = node.parent;
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Populates the given ListStore with all nodes that have names
  // that match the given string pattern.
  public override void get_match_items( string tabname, string pattern, bool[] search_opts, ref GLib.ListStore matches ) {
    if( search_opts[SearchOptions.NODES] &&
        (_alpha == 1.0) &&
        (((((_task_count == 0) || !is_leaf()) && search_opts[SearchOptions.NONTASKS]) ||
          ((_task_count != 0) && is_leaf()   && search_opts[SearchOptions.TASKS])) &&
         (((parent != null) && is_folded( parent ) && search_opts[SearchOptions.FOLDED]) ||
          (((parent == null) || !is_folded( parent )) && search_opts[SearchOptions.UNFOLDED]))) ) {
      var tab = "<i>" + Utils.rootname( tabname ) + "</i>";
      if( search_opts[SearchOptions.TITLES] ) {
        string str = Utils.match_string( pattern, name.stripped_text.text );
        if( str.length > 0 ) {
          matches.append( new SearchItem.node( tabname, tab, this, "<b><i>%s:</i></b>".printf( _( "Node Title" ) ), str ) );
        }
      }
      if( search_opts[SearchOptions.NOTES] ) {
        string str = Utils.match_string( pattern, Utils.remove_markdown( note ) );
        if( str.length > 0 ) {
          matches.append( new SearchItem.node( tabname, tab, this, "<b><i>%s:</i></b>".printf( _( "Node Note" ) ), str ) );
        }
      }
    }
    if( (_callout != null) && search_opts[SearchOptions.CALLOUTS] && search_opts[SearchOptions.TITLES] ) {
      string str = Utils.match_string( pattern, _callout.text.stripped_text.text );
      if( str.length > 0 ) {
        var tab = "<i>" + Utils.rootname( tabname ) + "</i>";
        matches.append( new SearchItem.callout( tabname, tab, _callout, "<b><i>%s:</i></b>".printf( _( "Callout Text" ) ), str ) );
      }
    }
    base.get_match_items( tabname, pattern, search_opts, ref matches );
  }

  //-------------------------------------------------------------
  // Called when the theme is changed by the user.  Looks up this
  // node's link color in the old theme to see if it is a themed
  // color.  If it is, map it to the new theme's color palette.
  // If the current color is not a theme link color, keep the
  // current color as it was custom set by the user.  Performs
  // this mapping recursively for all descendants.
  public override void update_theme_colors( Theme old_theme, Theme new_theme ) {
    int old_index = old_theme.get_color_index( _link_color );
    if( old_index != -1 ) {
      link_color_only = new_theme.link_color( old_index );
    }
    name.update_attributes();
    base.update_theme_colors( old_theme, new_theme );
  }

  //-------------------------------------------------------------
  // Gathers the information from all stored nodes for positional
  // and link color information.  This information is used by the
  // undo/redo functions.
  public override void get_node_info( ref Array<NodeInfo?> info ) {
    info.append_val( NodeInfo( _posx, _posy, side, _link_color ) );
    base.get_node_info( ref info );
  }

  //-------------------------------------------------------------
  // Restores the give information in the node info array to the
  // node and subnodes.
  public override void set_node_info( Array<NodeInfo?> info, ref int index ) {
    link_color_only = info.index( index ).color;
    base.set_node_info( info, ref index );
  }

  //-------------------------------------------------------------
  // DRAWING
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Draws the border around the node.
  protected void draw_shape( Context ctx, Theme theme, RGBA border_color, bool exporting ) {

    double x = posx + style.node_margin;
    double y = posy + style.node_margin;
    double w = _width  - (style.node_margin * 2);
    double h = _height - (style.node_margin * 2);

    // If we are a root node and our alpha value is not 1.0, draw our shape in the background color to hide
    // any links that are drawn under us.
    if( is_root() && (_alpha < 1.0) ) {
      Utils.set_context_color( ctx, theme.get_color( "background" ) );
      style.draw_node_fill( ctx, x, y, w, h, side );
    }

    // Set the fill color
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

      // Draw the border
      Utils.set_context_color_with_alpha( ctx, border_color, _alpha );
      ctx.set_line_width( style.node_borderwidth );

      // If we are in a vertical orientation and the border type is underlined, draw nothing
      style.draw_node_border( ctx, x, y, w, h, side );

    }

    // If we have children and we need to extend our link point, let's draw the extended link link now
    if( (_children.length > 0) && (summarized_node == null) ) {
      var max_width = 0;
      for( int i=0; i<_children.length; i++ ) {
        if( max_width < _children.index( i ).style.link_width ) {
          max_width = _children.index( i ).style.link_width;
        }
      }
      if( (side == NodeSide.RIGHT) && (_width < _total_width) ) {
        link_point( out x, out y );
        ctx.set_line_width( max_width );
        ctx.move_to( (posx + _width - style.node_margin), y );
        ctx.line_to( x, y );
        ctx.stroke();
      } else if( (side == NodeSide.BOTTOM) && (_height < _total_height) ) {
        link_point( out x, out y );
        ctx.set_line_width( max_width );
        ctx.move_to( x, (posy + _height - style.node_margin) );
        ctx.line_to( x, y );
        ctx.stroke();
      }
    }

  }

  //-------------------------------------------------------------
  // Draws the node image above the note.
  protected virtual void draw_image( Cairo.Context ctx, Theme theme ) {
    if( _image != null ) {
      double x, y, w, h;
      image_bbox( out x, out y, out w, out h );
      _image.draw( ctx, x, y, _alpha );
    }

  }

  //-------------------------------------------------------------
  // Draws the node font to the screen.
  protected virtual void draw_name( Cairo.Context ctx, Theme theme, bool exporting ) {

    int hmargin = 3;
    int vmargin = 3;

    // Draw the selection box around the text if the node is in the 'selected' state
    if( mode.is_selected() && !exporting ) {
      var padding = style.node_padding;
      var margin  = style.node_margin;
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "nodesel_background" ), _alpha );
      ctx.rectangle( ((posx + padding + margin) - hmargin),
                     ((posy + padding + margin) - vmargin),
                     ((_width  - (padding * 2) - (margin * 2)) + (hmargin * 2)),
                     ((_height - (padding * 2) - (margin * 2)) + (vmargin * 2)) );
      ctx.fill();
    }

    // Draw the text
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

  //-------------------------------------------------------------
  // Draws the task checkbutton for leaf nodes.
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

  //-------------------------------------------------------------
  // Draws the task checkbutton for non-leaf nodes.
  protected virtual void draw_acc_task( Context ctx, RGBA color, RGBA? background ) {

    if( _task_count > 0 ) {

      double x, y, w, h;
      double complete = _task_done / (_task_count * 1.0);
      double angle    = ((complete * 360) + 270) * (Math.PI / 180.0);

      task_bbox( out x, out y, out w, out h );

      x += _task_radius;
      y += _task_radius;

      // Draw circle outline
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

      // Draw completeness pie
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

  //-------------------------------------------------------------
  // Draws the sticker associated with the node.
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

      // Draw sticker
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

      // Draw sequence number
      Pango.Rectangle ink_rect, log_rect;
      _sequence_num.layout.get_extents( out ink_rect, out log_rect );

      // Output the text
      ctx.move_to( (x - (log_rect.x / Pango.SCALE)), y );
      Utils.set_context_color_with_alpha( ctx, color, _alpha );
      Pango.cairo_show_layout( ctx, _sequence_num.layout );
      ctx.new_path();

    }

  }

  //-------------------------------------------------------------
  // Draws the icon indicating that a note is associated with
  // this node.
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

  //-------------------------------------------------------------
  // Draws the link node indicator.
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

  //-------------------------------------------------------------
  // Draw the fold indicator.
  protected virtual void draw_common_fold( Context ctx, RGBA bg_color, RGBA fg_color ) {

    if( (_children.length == 0) || (summarized_node != null) ) return;

    double fx, fy, fw, fh;
    fold_bbox( out fx, out fy, out fw, out fh );

    if( folded ) {

      // Draw the fold rectangle
      Utils.set_context_color_with_alpha( ctx, bg_color, _alpha );
      ctx.new_path();
      ctx.set_line_width( 1 );
      ctx.rectangle( fx, fy, fw, fh );
      ctx.fill();

      // Draw circles
      Utils.set_context_color_with_alpha( ctx, fg_color, _alpha );
      ctx.new_path();
      ctx.arc( (fx + (fw / 3)), (fy + (fh / 2)), 2, 0, (2 * Math.PI) );
      ctx.fill();
      ctx.new_path();
      ctx.arc( (fx + ((fw / 3) * 2)), (fy + (fh / 2)), 2, 0, (2 * Math.PI) );
      ctx.fill();

    } else if( show_fold ) {

      // Draw the fold rectangle
      Utils.set_context_color_with_alpha( ctx, fg_color, _alpha );
      ctx.new_path();
      ctx.set_line_width( 2 );
      ctx.rectangle( fx, fy, fw, fh );
      ctx.fill_preserve();
      Utils.set_context_color_with_alpha( ctx, bg_color, _alpha );
      ctx.stroke();

    }

  }

  //-------------------------------------------------------------
  // Draw the link from this node to the parent node (or previous
  // sibling if this is node is part of a sequence).
  public virtual void draw_link( Context ctx, Theme theme ) {

    double  parent_x, parent_y;
    double  height   = (style.node_border.name() == "underlined") ? (_height - style.node_margin) : (_height / 2);
    double  tailx    = 0, taily = 0, tipx = 0, tipy = 0;
    double  child_x1 = 0;
    double  child_y1 = 0;
    double  child_x2 = 0;
    double  child_y2 = 0;

    var margin  = style.node_margin;
    var padding = style.node_padding;

    // Get the parent's link point
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


    // Draw the arrow
    if( style.link_arrow ) {
      draw_link_arrow( ctx, theme, tailx, taily, tipx, tipy );
    }

  }

  //-------------------------------------------------------------
  // Draws arrow point to the "to" node.
  protected virtual void draw_link_arrow( Context ctx, Theme theme, double tailx, double taily, double tipx, double tipy ) {

    double extlen[7] = {12, 12, 13, 14, 15, 16, 16};

    var arrowLength = extlen[style.link_width - 2] + (style.link_arrow_size * 3); // can be adjusted
    var dx = tipx - tailx;
    var dy = tipy - taily;

    var theta = Math.atan2( dy, dx );

    var rad = 35 * (Math.PI / 180);  // 35 angle, can be adjusted
    var x1  = tipx - arrowLength * Math.cos( theta + rad );
    var y1  = tipy - arrowLength * Math.sin( theta + rad );

    var phi2 = -35 * (Math.PI / 180);  // -35 angle, can be adjusted
    var x2   = tipx - arrowLength * Math.cos( theta + phi2 );
    var y2   = tipy - arrowLength * Math.sin( theta + phi2 );

    // Draw the arrow
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

  //-------------------------------------------------------------
  // Draw all of the tag rectangles.
  protected virtual void draw_tags( Context ctx, Theme theme, bool exporting ) {
    for( int i=0; i<_tags.size(); i++ ) {

      var tag = _tags.get_tag( i );

      double x, y, w, h;
      tag_bbox( i, out x, out y, out w, out h );

      Utils.set_context_color_with_alpha( ctx, tag.color, _alpha );
      ctx.rectangle( x, y, w, h );
      ctx.fill_preserve();

      var color = (mode.is_selected() && !exporting) ? Granite.contrasting_foreground_color( theme.get_color( "nodesel_background" ) ) :
                                                       theme.get_color( "background" );
      Utils.set_context_color_with_alpha( ctx, color, _alpha );
      ctx.set_line_width( 1 );
      ctx.stroke();

    }
  }

  //-------------------------------------------------------------
  // Draws the node callout, if one exists.
  protected virtual void draw_callout( Context ctx, Theme theme, bool exporting ) {
    if( _callout != null ) {
      _callout.draw( ctx, theme, exporting );
    }
  }

  //-------------------------------------------------------------
  // Draws the node on the screen.
  public override void draw( Context ctx, Theme theme, bool motion, bool exporting ) {

    var nodesel_background = theme.get_color( "nodesel_background" );
    var nodesel_foreground = theme.get_color( "nodesel_foreground" );

    // Draw tree_bbox
    /*
    if( is_summarized() || is_summary() ) {
      if( first_summarized() ) {
        Utils.set_context_color_with_alpha( ctx, theme.get_color( "link_color0" ), 0.5 );
      } else if( last_summarized() ) {
        Utils.set_context_color_with_alpha( ctx, theme.get_color( "link_color3" ), 0.5 );
      } else if( is_summarized() ) {
        Utils.set_context_color_with_alpha( ctx, theme.get_color( "link_color6" ), 0.5 );
      } else {
        Utils.set_context_color_with_alpha( ctx, nodesel_background, 0.5 );
      }
      ctx.rectangle( tree_bbox.x, tree_bbox.y, tree_bbox.width, tree_bbox.height );
      ctx.fill();
    }
    */

    /*
    // Draw bbox
    double x, y, w, h;
    bbox( out x, out y, out w, out h );
    Utils.set_context_color_with_alpha( ctx, nodesel_background, 0.1 );
    ctx.rectangle( x, y, w, h );
    ctx.fill();
    */

    // If this is a root node, draw specifically for a root node
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
      draw_tags( ctx, theme, exporting );

    // Otherwise, draw the node as a non-root node
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
      draw_tags( ctx, theme, exporting );
    }

    draw_callout( ctx, theme, exporting );

  }

  //-------------------------------------------------------------
  // Draws all of the nodes on the same side of the parent.  Draws
  // the nodes such that overlapping links are drawn in a more
  // meaningful way.
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

  //-------------------------------------------------------------
  // Draw all of the node links.
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

  //-------------------------------------------------------------
  // Outputs the node's information to standard output.
  public override void display( bool recursive = false, string prefix = "" ) {
    stdout.printf( "%sNode, name: %s, posx: %g, posy: %g, side: %s, layout: %s\n", prefix, name.text.text, posx, posy, side.to_string(), ((layout == null) ? "Unknown" : layout.name) );
    if( recursive ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).display( recursive, prefix + "  " );
      }
    }
  }

}
