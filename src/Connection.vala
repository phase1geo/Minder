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
using Cairo;
using Pango;
using Gdk;
using GLib.Math;
using Gee;

/* Connection mode value for the Connection.mode property */
public enum ConnMode {
  NONE = 0,    // Normally drawn mode
  LINKING,     // Indicates that the connection is being used to create a node link
  CONNECTING,  // Indicates that the connection is being made between two nodes
  SELECTED,    // Indicates that the connection is currently selected
  ADJUSTING,   // Indicates that we are moving the drag handle to change the line shape
  EDITABLE,    // Indicates that the connection title is in edit mode
  DROPPABLE    // Indicates that the connection is a drop zone for stickers
}

public class Connection : Object {

  private int         RADIUS     = 6;
  private ConnMode    _mode      = ConnMode.NONE;
  private Node?       _from_node = null;
  private Node?       _to_node   = null;
  private double      _posx;
  private double      _posy;
  private double      _dragx;
  private double      _dragy;
  private Style       _style     = new Style();
  private Bezier      _curve;
  private CanvasText? _title     = null;
  private string      _note      = "";
  private double      _max_width = 100;
  private RGBA?       _color;
  private string?     _sticker     = null;
  private Pixbuf?     _sticker_buf = null;
  private double      _alpha       = 1.0;

  public CanvasText? title {
    get {
      return( _title );
    }
  }
  public string note  {
    get {
      return( _note );
    }
    set {
      bool was_empty = (_note.length == 0);
      _note = value;
      if( was_empty != (_note.length == 0) ) {
        position_title();
      }
    }
  }
  public ConnMode mode  {
    get {
      return( _mode );
    }
    set {
      if( _mode != value ) {
        _mode = value;
        if( _mode == ConnMode.EDITABLE ) {
          if( _title != null ) {
            _title.edit = true;
            _title.set_cursor_all( false );
          }
        } else if( _title != null ) {
          _title.edit = false;
          _title.clear_selection();
          if( (_title.text.text == "") && (_sticker == null) && (_note == "") ) {
            _title = null;
          }
        }
      }
    }
  }
  public Node? from_node {
    get {
      return( _from_node );
    }
    set {
      _from_node = value;
    }
  }
  public Node? to_node {
    get {
      return( _to_node );
    }
    set {
      _to_node = value;
    }
  }
  public Style style {
    get {
      return( _style );
    }
    set {
      if( _style.copy( value ) && (_title != null) ) {
        _title.set_font( _style.connection_font.get_family(), (_style.connection_font.get_size() / Pango.SCALE) );
        _title.max_width = _style.connection_title_width;
        position_title();
      }
    }
  }
  public double alpha {
    get {
      return( _alpha );
    }
    set {
      if( _alpha != value ) {
        _alpha = value;
        if( _from_node != null ) {
          _from_node.set_alpha_only( value );
        }
        if( _to_node != null ) {
          _to_node.set_alpha_only( value );
        }
      }
    }
  }
  public RGBA? color {
    get {
      return( _color );
    }
    set {
      _color = value;
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
        position_title();
      }
    }
  }
  public double extent_x1 { get; private set; default = 0.0; }
  public double extent_y1 { get; private set; default = 0.0; }
  public double extent_x2 { get; private set; default = 0.0; }
  public double extent_y2 { get; private set; default = 0.0; }

  /* Default constructor */
  public Connection( DrawArea da, Node from_node ) {
    double x, y, w, h;
    from_node.bbox( out x, out y, out w, out h );
    _posx      = x + (w / 2);
    _posy      = y + (h / 2);
    _from_node = from_node;
    connect_node( _from_node );
    _dragx     = _posx;
    _dragy     = _posy;
    position_title();
    _curve     = new Bezier.with_endpoints( _posx, _posy, _posx, _posy );
    style      = StyleInspector.styles.get_global_style();
  }

  /* Constructs a connection based on another connection */
  public Connection.from_connection( DrawArea da, Connection conn ) {
    _curve = new Bezier();
    copy( da, conn );
  }

  /* Constructor from XML data */
  public Connection.from_xml( DrawArea da, Xml.Node* n, Array<Node> nodes ) {
    style = StyleInspector.styles.get_global_style();
    load( da, n, nodes );
  }

  /* Copies the given connection to this instance */
  public void copy( DrawArea da, Connection conn ) {
    _from_node = conn._from_node;
    _to_node   = conn._to_node;
    _dragx     = conn._dragx;
    _dragy     = conn._dragy;
    position_title();
    _curve.copy( conn._curve );
    if( conn.title == null ) {
      if( _title != null ) {
        _title.resized.disconnect( position_title );
      }
      _title = null;
    } else {
      if( title == null ) {
        _title = new CanvasText( da );
        _title.resized.connect( position_title );
      }
      _title.copy( conn.title );
    }
    mode  = conn.mode;
    style = conn.style;
    color = conn.color;
  }

  private int sticker_width( bool add_padding ) {
    var padding = add_padding ? (style.connection_padding ?? 0) : 0;
    return( (_sticker_buf != null) ? (_sticker_buf.width + padding) : 0 );
  }

  private int sticker_height() {
    return( (_sticker_buf != null) ? _sticker_buf.height : 0 );
  }

  private int title_width( bool add_padding ) {
    var padding = add_padding ? (style.connection_padding ?? 0) : 0;
    return( (_title != null) ? ((int)_title.width + padding) : 0 );
  }

  private int title_height() {
    return( (_title != null) ? (int)_title.height : 0 );
  }

  private int note_width( bool add_padding ) {
    var padding = add_padding ? (style.connection_padding ?? 0) : 0;
    return( (note.length > 0) ? (11 + padding) : 0 );
  }

  private int note_height() {
    return( (note.length > 0) ? 11 : 0 );
  }

  private int get_width() {
    var sw = sticker_width( false );
    var tw = title_width( sw > 0 );
    var nw = note_width( (sw + tw) > 0 );
    return( sw + tw + nw );
  }

  private int get_height() {
    int sh = sticker_height();
    int th = title_height();
    int nh = note_height();
         if( (sh <= th) && (nh <= th) ) { return( th ); }
    else if( (th <= sh) && (nh <= sh) ) { return( sh ); }
    else                                { return( nh ); }
  }

  /* Returns the canvas box that contains both the from and to nodes */
  public void bbox( out double x, out double y, out double w, out double h ) {
    double fx, fy, fw, fh;
    double tx, ty, tw, th;
    if( (_from_node != null) && (_to_node != null) ) {
      _from_node.bbox( out fx, out fy, out fw, out fh );
      _to_node.bbox( out tx, out ty, out tw, out th );
      x = (fx < tx) ? fx : tx;
      y = (fy < ty) ? fy : ty;
      w = ((fx + fw) > (tx + tw)) ? ((fx + fw) - x) : ((tx + tw) - x);
      h = ((fy + fh) > (ty + th)) ? ((fy + fh) - y) : ((ty + th) - y);
    } else if( _from_node != null ) {
      _from_node.bbox( out x, out y, out w, out h );
    } else if( _to_node != null ) {
      _to_node.bbox( out x, out y, out w, out h );
    } else {
      x = 0;
      y = 0;
      w = 0;
      h = 0;
    }
  }

  /* Makes sure that the title is ready to be edited */
  public void edit_title_begin( DrawArea da ) {
    if( _title != null ) return;
    _title = new CanvasText.with_text( da, "" );
    _title.resized.connect( position_title );
    _title.set_font( style.connection_font.get_family(), (style.connection_font.get_size() / Pango.SCALE) );
    position_title();
  }

  /* Called when the title text is done being edited */
  public void edit_title_end() {
    if( (_title == null) || (_title.text.text != "") ) return;
    _title.resized.disconnect( position_title );
    _title = null;
  }

  /* Adds a title */
  public void change_title( DrawArea da, string title, bool allow_empty = false ) {
    if( (title == "") && !allow_empty ) {
      if( _title != null ) {
        _title.resized.disconnect( position_title );
      }
      _title = null;
    } else if( _title == null ) {
      _title = new CanvasText.with_text( da, title );
      _title.resized.connect( position_title );
      _title.set_font( style.connection_font.get_family(), (style.connection_font.get_size() / Pango.SCALE) );
      position_title();
    } else {
      _title.text.set_text( title );
    }
  }

  /* Positions the given title according to the location of the _dragx and _dragy values */
  private void position_title() {
    if( title != null ) {
      var width   = get_width();
      var swidth  = sticker_width( true );
      var theight = title_height();

      _title.posx = _dragx - ((width / 2) - swidth);
      _title.posy = _dragy - (theight / 2);
    }
  }

  /* Connects to the given node */
  public void connect_node( Node node ) {
    node.moved.connect( this.end_moved );
    node.resized.connect( this.end_resized );
  }

  /* Disconnects from the given node */
  public void disconnect_node( Node node ) {
    node.moved.disconnect( this.end_moved );
    node.resized.disconnect( this.end_resized );
    if( node.last_selected_connection == this ) {
      node.last_selected_connection = null;
    }
  }

  /* Completes the connection */
  public void connect_to( Node node ) {
    double fx, fy, tx, ty;
    double x, y, w, h;
    node.bbox( out x, out y, out w, out h );
    if( _from_node == null ) {
      _from_node = node;
    } else {
      _to_node = node;
    }
    connect_node( node );
    _curve.set_point( ((_from_node == node) ? 0 : 2), (x + (w / 2)), (y + (h / 2)) );
    _curve.get_point( 0, out fx, out fy );
    _curve.get_point( 2, out tx, out ty );
    _dragx = (fx + tx) / 2;
    _dragy = (fy + ty) / 2;
    position_title();
    _curve.update_control_from_drag_handle( _dragx, _dragy );
    set_connect_point( node );
  }

  /* Called when disconnecting a connection from a node */
  public void disconnect_from_node( bool from ) {
    if( from ) {
      _curve.get_from_point( out _posx, out _posy );
      disconnect_node( _from_node );
      _from_node = null;
    } else {
      _curve.get_to_point( out _posx, out _posy );
      disconnect_node( _to_node );
      _to_node = null;
    }
    mode = ConnMode.CONNECTING;
  }

  /* Draws the connections to the given point */
  public void draw_to( double x, double y ) {
    double nx, ny;
    Node node = (_from_node != null) ? _from_node : _to_node;
    _posx = x;
    _posy = y;
    _curve.get_point( ((node == _from_node) ? 0 : 2), out nx, out ny );
    _dragx = (nx + x) / 2;
    _dragy = (ny + y) / 2;
    position_title();
    _curve.update_control_from_drag_handle( _dragx, _dragy );
    set_connect_point( node );
  }

  /* Handles any position changes of either the to or from node */
  private void end_moved( Node node, double diffx, double diffy ) {
    double x, y, w, h;
    node.bbox( out x, out y, out w, out h );
    _curve.set_point( ((_from_node == node) ? 0 : 2), (x + (w / 2)), (y + (h / 2)) );
    _dragx += (diffx / 2);
    _dragy += (diffy / 2);
    position_title();
    _curve.update_control_from_drag_handle( _dragx, _dragy );
    set_connect_point( _from_node );
    if( _to_node != null ) {
      set_connect_point( _to_node );
    }
  }

  /* Handles any resizing changes of either the to or from node */
  private void end_resized( Node node, double diffw, double diffh ) {
    double x, y, w, h;
    node.bbox( out x, out y, out w, out h );
    _curve.set_point( ((_from_node == node) ? 0 : 2), (x + (w / 2)), (y + (h / 2)) );
    _dragx += (diffw / 2);
    _dragy += (diffh / 2);
    position_title();
    _curve.update_control_from_drag_handle( _dragx, _dragy );
    set_connect_point( _from_node );
    set_connect_point( _to_node );
  }

  /* Returns true if we are attached to the given node */
  public bool attached_to_node( Node node ) {
    return( (_from_node == node) || (_to_node == node) );
  }

  /* Returns the point to add the connection to based on the node */
  private void set_connect_point( Node node ) {

    double x, y, w, h;
    double bw     = node.style.node_borderwidth;
    double extra  = bw + (style.connection_line_width / 2);
    double margin = node.style.node_margin;

    node.bbox( out x, out y, out w, out h );

    /* Remove the node's margin */
    x += margin;
    y += margin;
    w -= (margin * 2);
    h -= (margin * 2);

    _curve.set_connect_point( (node == _from_node), (y - extra), (y + h + extra), (x - extra), (x + w + extra) );

  }

  /* Returns true if the given point is within proximity to the stored curve */
  public bool on_curve( double x, double y ) {
    double fx, fy, tx, ty;
    _curve.get_from_point( out fx, out fy );
    _curve.get_to_point( out tx, out ty );
    var curve = new Bezier.with_endpoints( fx, fy, tx, ty );
    curve.update_control_from_drag_handle( _dragx, _dragy );
    return( curve.within_range( x, y ) );
  }

  /* Returns true if the given x/y point lies within a handle located at hx/hy */
  private bool within_handle( double hx, double hy, double x, double y ) {
    return( ((hx - RADIUS) <= x) && (x <= (hx + RADIUS)) && ((hy - RADIUS) <= y) && (y <= (hy + RADIUS)) );
  }

  /* Returns true if the given point is within the drag handle */
  public bool within_drag_handle( double x, double y ) {
    if( mode == ConnMode.SELECTED ) {
      if( (_sticker == null) && (title == null) && (note.length == 0) ) {
        return( within_handle( _dragx, _dragy, x, y ) );
      } else {
        double tx, ty, tw, th;
        title_bbox( out tx, out ty, out tw, out th );
        return( within_handle( _dragx, (_dragy + (th / 2) + _style.connection_padding), x, y ) );
      }
    }
    return( false );
  }

  /* Returns true if the given point lies within the from connection handle */
  public bool within_from_handle( double x, double y ) {
    return( within_endpoint_handle( true, x, y ) );
  }

  /* Returns true if the given point lies within the from connection handle */
  public bool within_to_handle( double x, double y ) {
    return( within_endpoint_handle( false, x, y ) );
  }

  /* Returns true if the given point lies within the from connection handle */
  private bool within_endpoint_handle( bool from, double x, double y ) {
    if( mode == ConnMode.SELECTED ) {
      double px, py;
      if( from ) {
        _curve.get_from_point( out px, out py );
      } else {
        _curve.get_to_point( out px, out py );
      }
      return( within_handle( px, py, x, y ) );
    }
    return( false );
  }

  public bool within_title_box( double x, double y ) {
    if( (_sticker_buf == null) && (_title == null) && (note.length == 0) ) return( false );
    double bx, by, bw, bh;
    title_bbox( out bx, out by, out bw, out bh );
    return( Utils.is_within_bounds( x, y, bx, by, bw, bh ) );
  }

  /* Returns true if the given coordinates are within the title text area. */
  public bool within_title( double x, double y ) {
    return( (_title != null) && _title.is_within( x, y ) );
  }

  /* Returns true if the given coordinates lies within the connection note */
  public bool within_note( double x, double y ) {
    if( note.length == 0 ) return( false );
    double nx, ny, nw, nh;
    note_bbox( out nx, out ny, out nw, out nh );
    return( Utils.is_within_bounds( x, y, nx, ny, nw, nh ) );
  }

  /* Returns true if the given coordinates lies within the connection sticker */
  public bool within_sticker( double x, double y ) {
    if( _sticker_buf == null ) return( false );
    double sx, sy, sw, sh;
    sticker_bbox( out sx, out sy, out sw, out sh );
    return( Utils.is_within_bounds( x, y, sw, sy, sw, sh ) );
  }

  /* Returns the bounding box for the sticker, title and note icon */
  private void title_bbox( out double x, out double y, out double w, out double h ) {
    var padding = style.connection_padding ?? 0;
    var width   = get_width();
    var height  = get_height();

    x = _dragx - ((width / 2) + padding);
    y = _dragy - ((height / 2) + padding);
    w = width  + (padding * 2);
    h = height + (padding * 2);
  }

  /* Returns the positional information for where the note item is located (if it exists) */
  private void note_bbox( out double x, out double y, out double w, out double h ) {
    var width   = get_width();
    var nwidth  = note_width( false );
    var nheight = note_height();

    x = _dragx + (width / 2) - nwidth;
    y = _dragy - (nheight / 2);
    w = nwidth;
    h = nheight;
  }

  /* Returns the position information for where the sticker item is located (if it exists) */
  private void sticker_bbox( out double x, out double y, out double w, out double h ) {
    var width   = get_width();
    var swidth  = sticker_width( false );
    var sheight = sticker_height();

    x = _dragx - (width / 2);
    y = _dragy - (sheight / 2);
    w = swidth;
    h = sheight;
  }

  /* Updates the location of the drag handle */
  public void move_drag_handle( double x, double y ) {
    mode = ConnMode.ADJUSTING;
    position_title();
    _dragx = x;
    _dragy = y;
    if( title != null ) {
      double tx, ty, tw, th;
      title_bbox( out tx, out ty, out tw, out th );
      _dragy -= (th / 2);
    }
    _curve.update_control_from_drag_handle( _dragx, _dragy );
    set_connect_point( _from_node );
    set_connect_point( _to_node );
  }

  /* Loads the connection information */
  private void load( DrawArea da, Xml.Node* node, Array<Node> nodes ) {

    string? f = node->get_prop( "from_id" );
    if( f != null ) {
      _from_node = da.get_node( nodes, int.parse( f ) );
      connect_node( _from_node );
    }

    string? t = node->get_prop( "to_id" );
    if( t != null ) {
      _to_node = da.get_node( nodes, int.parse( t ) );
      connect_node( _to_node );
    }

    string? x = node->get_prop( "drag_x" );
    if( x != null ) {
      _dragx = double.parse( x );
    }

    string? y = node->get_prop( "drag_y" );
    if( y != null ) {
      _dragy = double.parse( y );
    }

    string? n = node->get_prop( "note" );
    if( n != null ) {
      note = n;
    }

    string? c = node->get_prop( "color" );
    if( c != null ) {
      _color = da.get_theme().get_color( "connection_background" );
      _color.parse( c );
    }

    string? sk = node->get_prop( "sticker" );
    if( sk != null ) {
      sticker = sk;
    }

    /* Update the stored curve */
    double fx, fy, fw, fh;
    double tx, ty, tw, th;
    _from_node.bbox( out fx, out fy, out fw, out fh );
    _to_node.bbox(   out tx, out ty, out tw, out th );
    _curve = new Bezier.with_endpoints( (fx + (fw / 2)), (fy + (fh / 2)), (tx + (tw / 2)), (ty + (th / 2)) );
    _curve.update_control_from_drag_handle( _dragx, _dragy );
    set_connect_point( _from_node );
    set_connect_point( _to_node );

    /* Load the connection information */
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "style" :  style.load_connection( it );  break;
          case "title" :
           if( (it->children != null) && (it->children->type == Xml.ElementType.TEXT_NODE) ) {
             change_title( da, it->children->get_content() );
           }
           break;
          case "note"  :
           if( (it->children != null) && (it->children->type == Xml.ElementType.TEXT_NODE) ) {
             note = it->children->get_content();
           }
           break;
        }
      }
    }

  }

  /* Saves the connection information to the given XML node */
  public void save( Xml.Node* parent ) {

    Xml.Node* n = new Xml.Node( null, "connection" );
    n->set_prop( "from_id", _from_node.id().to_string() );
    n->set_prop( "to_id",   _to_node.id().to_string() );
    n->set_prop( "drag_x",  _dragx.to_string() );
    n->set_prop( "drag_y",  _dragy.to_string() );

    if( _color != null ) {
      n->set_prop( "color", Utils.color_from_rgba( _color ) );
    }

    if( _sticker != null ) {
      n->set_prop( "sticker", _sticker );
    }

    /* Save the style connection */
    style.save_connection( n );

    n->new_text_child( null, "title", ((title != null) ? title.text.text : "") );
    n->new_text_child( null, "note",  note );

    parent->add_child( n );

  }

  /*
   Populates the given ListStore with all nodes that have names that match
   the given string pattern.
  */
public void get_match_items( string tabname, string pattern, bool[] search_opts, ref Gtk.ListStore matches ) {
  var tab = Utils.rootname( tabname );
  if( search_opts[2] && (title != null) ) {
    string str = Utils.match_string( pattern, title.text.text);
    if(str.length > 0) {
      TreeIter it;
      matches.append( out it );
      matches.set( it, 0, "<b><i>%s:</i></b>".printf( _( "Connection Title" ) ), 1, str, 2, null, 3, this, 4, tabname, 5, tab, -1 );
    }
  }
  if( search_opts[3] ) {
    string str = Utils.match_string( pattern, note);
    if(str.length > 0) {
      TreeIter it;
      matches.append( out it );
      matches.set( it, 0, "<b><i>%s:</i></b>".printf( _( "Connection Note" ) ), 1, str, 2, null, 3, this, 4, tabname, 5, tab, -1 );
    }
  }
}
  /* Draws the connection to the given context */
  public virtual void draw( Cairo.Context ctx, Theme theme, bool exporting ) {

    /* If either the from or to node is hidden, don't bother to draw ourselves */
    if( ((_from_node != null) && !_from_node.is_root() && (_from_node.folded_ancestor() != null)) ||
        ((_to_node   != null) && !_to_node.is_root()   && (_to_node.folded_ancestor() != null)) ) {
      return;
    }

    double start_x, start_y;
    double end_x,   end_y;
    double dragx  = _dragx;
    double dragy  = _dragy;
    RGBA   ccolor = (_color != null) ? _color : theme.get_color( "connection_background" );
    RGBA   bg     = ((mode == ConnMode.NONE) || exporting) ? theme.get_color( "background" ) :
                                                             theme.get_color( "nodesel_background" );

    if( _from_node == null ) {
      start_x = _posx;
      start_y = _posy;
    } else {
      _curve.get_from_point( out start_x, out start_y );
    }

    if( _to_node == null ) {
      end_x = _posx;
      end_y = _posy;
    } else {
      _curve.get_to_point( out end_x, out end_y );
    }

    /* The value of t is always 0.5 */
    double cx, cy;

    /* Calclate the control points based on the calculated start/end points */
    cx = dragx - (((start_x + end_x) * 0.5) - dragx);
    cy = dragy - (((start_y + end_y) * 0.5) - dragy);

    /* Draw the curve */
    ctx.save();
    style.draw_connection( ctx );
    Utils.set_context_color_with_alpha( ctx, ccolor, alpha );

    /* Draw the curve as a quadratic curve (saves some additional calculations) */
    ctx.move_to( start_x, start_y );
    ctx.curve_to(
      (((2.0 / 3.0) * cx) + ((1.0 / 3.0) * start_x)),
      (((2.0 / 3.0) * cy) + ((1.0 / 3.0) * start_y)),
      (((2.0 / 3.0) * cx) + ((1.0 / 3.0) * end_x)),
      (((2.0 / 3.0) * cy) + ((1.0 / 3.0) * end_y)),
      end_x, end_y
    );

    double x1, y1, x2, y2;
    ctx.stroke_extents( out x1, out y1, out x2, out y2 );
    extent_x1 = x1;
    extent_y1 = y1;
    extent_x2 = x2;
    extent_y2 = y2;

    ctx.stroke();

    ctx.set_dash( {}, 0 );

    /* Draw the arrow */
    if( (mode != ConnMode.SELECTED) || exporting ) {
      if( (style.connection_arrow == "fromto") || (style.connection_arrow == "both") ) {
        draw_arrow( ctx, style.connection_line_width, end_x, end_y, cx, cy );
      }
      if( (style.connection_arrow == "tofrom") || (style.connection_arrow == "both") ) {
        draw_arrow( ctx, style.connection_line_width, start_x, start_y, cx, cy );
      }
    }

    /* If we are selected draw the endpoints */
    if( (mode == ConnMode.SELECTED) && !exporting ) {

      ctx.set_source_rgba( bg.red, bg.green, bg.blue, alpha );
      ctx.arc( start_x, start_y, RADIUS, 0, (2 * Math.PI) );
      ctx.fill_preserve();
      ctx.set_source_rgba( ccolor.red, ccolor.green, ccolor.blue, alpha );
      ctx.stroke();

      ctx.set_source_rgba( bg.red, bg.green, bg.blue, alpha );
      ctx.arc( end_x, end_y, RADIUS, 0, (2 * Math.PI) );
      ctx.fill_preserve();
      ctx.set_source_rgba( ccolor.red, ccolor.green, ccolor.blue, alpha );
      ctx.stroke();

    }

    /* Draw the connection title if it exists */
    if( (_sticker != null) || (title != null) || (note.length > 0) ) {

      draw_title( ctx, theme, exporting );

    /* Draw the drag handle */
    } else if( (mode != ConnMode.NONE) && !exporting ) {

      ctx.set_line_width( 1 );
      Utils.set_context_color_with_alpha( ctx, Utils.color_from_string( "yellow" ), alpha );
      ctx.arc( dragx, dragy, RADIUS, 0, (2 * Math.PI) );
      ctx.fill_preserve();
      if( mode == ConnMode.DROPPABLE ) {
        Utils.set_context_color_with_alpha( ctx, theme.get_color( "attachable" ), alpha );
        ctx.set_line_width( 4 );
      } else {
        ctx.set_source_rgba( ccolor.red, ccolor.green, ccolor.blue, alpha );
      }
      ctx.stroke();

    }

    ctx.restore();

  }

  /* Draws the sticker associated with this connection, if necessary */
  private void draw_sticker( Cairo.Context ctx, Theme theme ) {

    if( _sticker_buf != null ) {

      double x, y, w, h;
      sticker_bbox( out x, out y, out w, out h );

      /* Draw sticker */
      cairo_set_source_pixbuf( ctx, _sticker_buf, x, y );
      ctx.paint_with_alpha( alpha );

    }

  }

  /*
   Draws the connection title if it has been enabled.
  */
  private void draw_title( Cairo.Context ctx, Theme theme, bool exporting ) {

    var    ccolor  = (_color != null) ? _color : theme.get_color( "connection_background" );
    var    fg      = theme.get_color( "connection_foreground" ) ?? theme.get_color( "background" );
    var    padding = _style.connection_padding ?? 0;
    double x, y, w, h;

    /* Get the bbox for the entire title box */
    title_bbox( out x, out y, out w, out h );
    x -= padding;
    y -= padding;
    w += (padding * 2);
    h += (padding * 2);

    /* Calculate the extents */
    extent_x1 = (x < extent_x1) ? x : extent_x1;
    extent_y1 = (y < extent_y1) ? y : extent_y1;
    extent_x2 = ((x + w) > extent_x2) ? (x + w) : extent_x2;
    extent_y2 = ((y + h) > extent_y2) ? (y + h) : extent_y2;

    /* Draw the box */
    ctx.set_source_rgba( ccolor.red, ccolor.green, ccolor.blue, alpha );
    Granite.Drawing.Utilities.cairo_rounded_rectangle( ctx, x, y, w, h, (padding * 2) );
    ctx.fill();

    /* Draw the droppable indicator, if necessary */
    if( (mode == ConnMode.DROPPABLE) && !exporting ) {
      Utils.set_context_color_with_alpha( ctx, theme.get_color( "attachable" ), alpha );
      ctx.set_line_width( 4 );
      Granite.Drawing.Utilities.cairo_rounded_rectangle( ctx, x, y, w, h, (padding * 2) );
      ctx.stroke();
    }

    /* Draw the sticker, if necessary */
    draw_sticker( ctx, theme );

    /* Draw the text */
    if( _title != null ) {
      _title.draw( ctx, theme, fg, alpha, exporting );
    }

    /* Draw the note, if necessary */
    draw_note( ctx, fg );

    /* Draw the drag handle */
    if( ((mode == ConnMode.SELECTED) || (mode == ConnMode.ADJUSTING)) && !exporting ) {

      Utils.set_context_color_with_alpha( ctx, Utils.color_from_string( "yellow" ), alpha );
      ctx.set_line_width( 1 );
      ctx.arc( _dragx, (_dragy + (h / 2) + padding), RADIUS, 0, (2 * Math.PI) );
      ctx.fill_preserve();
      ctx.set_source_rgba( ccolor.red, ccolor.green, ccolor.blue, alpha );
      ctx.stroke();

    }

  }

  /* Draws the icon indicating that a note is associated with this node */
  private void draw_note( Cairo.Context ctx, RGBA color ) {

    if( note.length > 0 ) {

      double x, y, w, h;

      note_bbox( out x, out y, out w, out h );

      Utils.set_context_color_with_alpha( ctx, color, alpha );
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

  /*
   Draws arrow point to the "to" node.  The tailx/y values should be the
   bezier control point closest to the "to" node.
  */
  public static void draw_arrow( Cairo.Context ctx, int line_width, double tipx, double tipy, double tailx, double taily, double arrowLength = 0 ) {

    double extlen[8] = {12, 13, 14, 15, 16, 17, 18, 18};

    if( arrowLength == 0 ) {
      arrowLength = extlen[line_width-1];
    }

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
    ctx.set_line_width( 1 );
    ctx.move_to( tipx, tipy );
    ctx.line_to( x1, y1 );
    ctx.line_to( x2, y2 );
    ctx.close_path();
    ctx.fill();

  }

  /* Makes an icon for the given dash */
  public static Cairo.Surface make_arrow_icon( string type ) {

    Cairo.ImageSurface surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, 100, 20 );
    Cairo.Context      ctx     = new Cairo.Context( surface );

    ctx.set_source_rgba( 0.5, 0.5, 0.5, 1 );
    ctx.set_line_width( 4 );
    ctx.set_line_cap( LineCap.ROUND );
    ctx.move_to( 15, 10 );
    ctx.line_to( 85, 10 );
    ctx.stroke();

    if( (type == "fromto") || (type == "both") ) {
      draw_arrow( ctx, 4, 90, 10, 10, 10 );
    }
    if( (type == "tofrom") || (type == "both") ) {
      draw_arrow( ctx, 4, 10, 10, 90, 10 );
    }

    return( surface );

  }

}
