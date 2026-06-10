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

using Cairo;

//-------------------------------------------------------------
// A summarized node differs from other nodes in the following ways:
//
// - All summarized nodes exist within an internal list.  The parent
//   node of all internal nodes is the parent node of the SummarizedNode.
//   The child node of all internal nodes is null.
// - Its parent node is the parent of the summarized nodes.  When
//   that parent moves, we will move; otherwise, we will remain
//   unchanged in our location unless the summarized nodes change
//   in size or the parent moves.
// - It tracks the locations of the summarized nodes.  If the size
//   of our tree node changes, we will adjust the internal nodes
//   such that they will be drawn as close together as possible and
//   margin will be added before the first internal node and after
//   the last internal node.
public class SummarizedNode : BaseNode {

  private Array<BaseNode> _nodes;
  private int             _current  = 0;

  public int current {
    get {
      return( _current );
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public SummarizedNode( MindMap map, Layout? layout ) {
    base( map, layout );
    _nodes = new Array<BaseNode>();
    initialize_size();
  }

  //-------------------------------------------------------------
  // Constructor from XML data
  public SummarizedNode.from_xml( MindMap map, Layout? layout, Xml.Node* node ) {
    base( map, layout );
    _nodes = new Array<BaseNode>();
    load( map, node, false );
  }

  //-------------------------------------------------------------
  // Returns the number of summarized nodes stored.
  public int summarized_count() {
    return( (int)_nodes.length );
  }

  //-------------------------------------------------------------
  // Returns the summarized node at the given index.
  public Node? get_summarized_node( int index ) {
    return( ((0 <= index) && (index < _nodes.length)) ? (Node)_nodes.index( index ) : null );
  }

  //-------------------------------------------------------------
  // Returns the current summarized node.  If no current node is
  // available, returns null.
  public Node? current_node() {
    return( (_nodes.length == 0) ? null : (Node)_nodes.index( current ) );
  }

  //-------------------------------------------------------------
  // Sets the current node index to the node that matches.
  public void set_current_node( BaseNode node ) {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ) == node ) {
        _current = i;
      }
    }
  }

  //-------------------------------------------------------------
  // Creates a new SummarizedNode and returns it.
  public override BaseNode make_node( MindMap map ) {
    var node = new SummarizedNode( map, null );
    return( node );
  }

  //-------------------------------------------------------------
  // Copies just the variables of the node.
  public override void copy_variables( BaseNode node, ImageManager im ) {
    var sn = (SummarizedNode)node;
    base.copy_variables( node, im );
    for( int i=0; i<sn._nodes.length; i++ ) {
      var n = sn._nodes.index( i ).copy( map, im );
      add_node( n );
    }
  }

  //-------------------------------------------------------------
  // We are going to set the alpha value to all internal nodes.
  protected override void alpha_callback() {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).alpha = _alpha;
    }
  }

  //-------------------------------------------------------------
  // Sets the style of all internal nodes to the current style.
  protected override void style_callback() {
    /*
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).style = _style;
    }
    */
  }

  //-------------------------------------------------------------
  // Sets the mode of all internal nodes to the current mode value.
  protected override void mode_callback() {
    /*
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).mode = _mode;
    }
    */
  }

  //-------------------------------------------------------------
  // Sets the posx value of this node and adjusts the internal
  // node posx values only.
  public override void set_posx_only( double value ) {
    var diff = value - posx;
    base.set_posx_only( value );
    for( int i=0; i<_nodes.length; i++ ) {
      var n = _nodes.index( i );
      n.set_posx_only( n.posx + diff );
    }
  }

  //-------------------------------------------------------------
  // Sets the posy value of this node and adjusts the internal
  // node posy values only.
  public override void set_posy_only( double value ) {
    stdout.printf( "SummarizedNode, set_posy_only, value: %g\n", value );
    var diff = value - posy;
    base.set_posy_only( value );
    for( int i=0; i<_nodes.length; i++ ) {
      var n = _nodes.index( i );
      n.set_posy_only( n.posy + diff );
    }
  }

  //-------------------------------------------------------------
  // Adjusts posx value by the given amount for all internal nodes.
  public override void adjust_posx_only( double diff ) {
    base.adjust_posx_only( diff );
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).adjust_posx_only( diff );
    }
  }

  //-------------------------------------------------------------
  // Adjusts posy value by the given amount for all internal nodes.
  public override void adjust_posy_only( double diff ) {
    stdout.printf( "SummarizedNode, adjust_posy_only, diff: %g\n", diff );
    base.adjust_posy_only( diff );
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).adjust_posy_only( diff );
    }
  }

  //-------------------------------------------------------------
  // Called whenever the parent node is moved.
  protected override void parent_moved( BaseNode parent, double diffx, double diffy ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).parent_moved( this, diffx, diffy );
    }
    base.parent_moved( parent, diffx, diffy );
  }

  //-------------------------------------------------------------
  // Sets the alpha value of all internal nodes to the given value.
  public override void set_alpha_only( double value ) {
    base.set_alpha_only( value );
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).set_alpha_only( value );
    }
  }

  //-------------------------------------------------------------
  // Calculates the space required for all internal nodes.
  public override void calculate_node_size( out double width, out double height, out double name_space ) {
    stdout.printf( "IN CALCULATE_NODE_SIZE\n" );
    width      = 0.0;
    height     = 0.0;
    name_space = 0.0;
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      if( side.horizontal() ) {
        height += node.total_height;
        if( width < node.total_width ) {
          width = node.total_width;
        }
      } else {
        width += node.total_width;
        if( height < node.total_height ) {
          height = node.total_height;
        }
      }
    }
    stdout.printf( "IN CALCULATE_SUMMARIZED_SIZE, width: %g, height: %g\n", width, height );
  }

  //-------------------------------------------------------------
  // Updates the size of all nodes within this tree.
  public override void update_tree() {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).update_tree();
    }
    base.update_tree();
  }

  //-------------------------------------------------------------
  // Updates all node styles for the node tree.
  public override void set_style_for_tree( Style s ) {
    style = s;
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).set_style_for_tree( s );
    }
    base.set_style_for_tree( s );
  }

  //-------------------------------------------------------------
  // Searches this node for one that contains the given coordinates.
  public override BaseNode? contains( double x, double y, bool allow_selected ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i ).contains( x, y, allow_selected );
      if( node != null ) {
        return( node );
      }
    }
    for( int i=0; i<_children.length; i++ ) {
      var node = _children.index( i ).contains( x, y, allow_selected );
      if( node != null ) {
        return( node );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Searches the summarized nodes for any that contain a callout
  // containing the given coordinates.
  public override Callout? contains_callout( double x, double y ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var callout = _nodes.index( i ).contains_callout( x, y );
      if( callout != null ) {
        return( callout );
      }
    }
    for( int i=0; i<_children.length; i++ ) {
      var callout = _children.index( i ).contains_callout( x, y );
      if( callout != null ) {
        return( callout );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns true if any of the summarized nodes have completed
  // tasks that are foldable.  Recursively checks the summary node
  // also.
  public override bool completed_tasks_foldable() {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ).completed_tasks_foldable() ) {
        return( true );
      }
    }
    for( int i=0; i<_children.length; i++ ) {
      if( _children.index( i ).completed_tasks_foldable() ) {
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if any summarized nodes or descendants are unfoldable.
  public override bool unfoldable() {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ).unfoldable() ) {
        return( true );
      }
    }
    for( int i=0; i<_children.length; i++ ) {
      if( _children.index( i ).unfoldable() ) {
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Recursively spans node tree folding any nodes which contain
  // fully completed tasks.  The derived class must implement this
  // functionality.
  public override void fold_completed_tasks( Array<Node> changed ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).fold_completed_tasks( changed );
    }  
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).fold_completed_tasks( changed );
    }
  }

  //-------------------------------------------------------------
  // Removes the given tag from all summarized nodes.  If the nodes
  // array
  public override bool remove_tag( Tag tag, Array<Node>? nodes = null ) {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ).remove_tag( tag, nodes ) ) {
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
  // Highlights all of the nodes that match the given tags.
  public override void highlight_tags( Tags tags, TagComboType combo_type ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).highlight_tags( tags, combo_type );
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).highlight_tags( tags, combo_type );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the selection box intersects with any internal
  // node.
  public override bool intersects_with( Gdk.Rectangle box ) {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ).intersects_with( box ) ) {
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns all of the nodes found within the given box.  Appends
  // those nodes to the array.
  public override void get_nodes_within_box( Gdk.Rectangle box, Array<BaseNode> nodes ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      if( node.intersects_with( box ) ) {
        nodes.append_val( node );
      }
    }
    for( int i=0; i<_children.length; i++ ) {
      _children.index( i ).get_nodes_within_box( box, nodes );
    }
  }

  //-------------------------------------------------------------
  // Searches the internal nodes and all children for
  // nodes matching the given node ID.
  public override BaseNode? get_node( int id ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i ).get_node( id );
      if( node != null ) {
        return( node );
      }
    }
    for( int i=0; i<children().length; i++ ) {
      var node = children().index( i ).get_node( id );
      if( node != null ) {
        return( node );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the first summarized node in the list.
  public override BaseNode? first_child( NodeSide? side = null ) {
    return( (_nodes.length == 0) ? null : _nodes.index( 0 ) );
  }

  //-------------------------------------------------------------
  // Returns the last summarized node in the list.
  public override BaseNode? last_child( NodeSide? side = null ) {
    return( (_nodes.length == 0) ? null : _nodes.index( _nodes.length - 1 ) );
  }

  //-------------------------------------------------------------
  // Returns the sibling node within the internal list relative
  // to the current node.
  public override BaseNode? get_sibling( int dir, bool wrap ) {
    var index = _current + dir;
    if( index < 0 ) {
      return( wrap ? _nodes.index( _nodes.length - 1 ) : null );
    } else if( index >= _nodes.length ) {
      return( wrap ? _nodes.index( 0 ) : null );
    } else {
      return( _nodes.index( index ) );
    }
  }

  //-------------------------------------------------------------
  // LOAD
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Loads the list of internal summarized nodes.
  private void load_summarized_nodes( Xml.Node* n ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        var node = new Node.from_xml( _map, _layout, it, false );
        add_node( node );
      }
    }
  }

  //-------------------------------------------------------------
  // Overrides the BaseNode load routine.
  public override void load( MindMap map, Xml.Node* n, bool isroot ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "summarized-nodes") ) {
        load_summarized_nodes( it );
      }
    }
    base.load( map, n, isroot );
  }

  //-------------------------------------------------------------
  // SAVE
  //-------------------------------------------------------------

  public override Xml.Node* save() {
    return( save_node( "summarized" ) );
  }

  //-------------------------------------------------------------
  // Saves all internal nodes along with other node information and
  // return the created XML node.
  public override Xml.Node* save_node( string xml_name ) {
    Xml.Node* node = base.save_node( xml_name );
    Xml.Node* summarized = new Xml.Node( null, "summarized-nodes" );
    for( int i=0; i<_nodes.length; i++ ) {
      summarized->add_child( _nodes.index( i ).save() );
    }
    node->add_child( summarized );
    return( node );
  }

  //-------------------------------------------------------------
  // SUMMARIZED-SPECIFIC FUNCTIONALITY
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Connects the node to signals
  private void connect_node( BaseNode node ) {
    // node.moved.connect( nodes_changed_moved );
    node.resized.connect( nodes_changed_resized );
  }

  //-------------------------------------------------------------
  // Disconnects the node from signals
  private void disconnect_node( BaseNode node ) {
    // node.moved.disconnect( nodes_changed_moved );
    node.resized.disconnect( nodes_changed_resized );
  }

  //-------------------------------------------------------------
  // Returns true if the given coordinates is within the
  // horizontal/vertical extents of the list of summarized nodes
  public bool is_within_summarized( double x, double y ) {
    return( is_within( x, y ) );
  }

  private void nodes_changed_moved( double fx, double fy ) {
    // nodes_changed( fx, fy, "moved" );
  }

  private void nodes_changed_resized( double fx, double fy ) {
    nodes_changed( fx, fy, "resized" );
  }

  //-------------------------------------------------------------
  // Called whenever the first or last summarized nodes changes
  // in position or size, we need to adjust our location
  public void nodes_changed( double fx, double fy, string msg = "" ) {

    /* TBD
    var margin = style.branch_margin ?? 0;
    var x1     = _nodes.index( 0 ).posx;
    var y1     = _nodes.index( 0 ).posy;
    var x2     = _nodes.index( 0 ).posx + first_node().width;
    var y2     = _nodes.index( 0 ).posy + first_node().height;

    foreach( var node in _nodes ) {
      if( x1 > node.posx )                 { x1 = node.posx; }
      if( y1 > node.posy )                 { y1 = node.posy; }
      if( x2 < (node.posx + node.width) )  { x2 = (node.posx + node.width); }
      if( y2 < (node.posy + node.height) ) { y2 = (node.posy + node.height); }
    }

    switch( side ) {
      case NodeSide.LEFT   :  
        posx = (fx == 0) ? posx : (x1 - width) - margin;
        posy = (fy == 0) ? posy : (((y2 - y1) / 2) - (height / 2)) + y1;
        break;
      case NodeSide.RIGHT  :  
        posx = (fx == 0) ? posx : x2 + margin;
        posy = (fy == 0) ? posy : (((y2 - y1) / 2) - (height / 2)) + y1;
        break;
      case NodeSide.TOP    :  
        posx = (fx == 0) ? posx : (((x2 -x1) / 2) - (width / 2)) + x1;
        posy = (fy == 0) ? posy : (y1 - height) - margin;
        break;
      case NodeSide.BOTTOM :  
        posx = (fx == 0) ? posx : (((x2 -x1) / 2) - (width / 2)) + x1;
        posy = (fy == 0) ? posy : y2 + margin;
        break;
      default :  break;
    }
    */

  }

  //-------------------------------------------------------------
  // Attach ourself to the list of nodes in the given parent node.
  public void attach_parent_nodes( BaseNode p, int first_index, int last_index, Theme? theme = null ) {

    // Make sure that we didn't mess up the index order
    assert( (first_index >= 0) && (first_index < last_index) );

    stdout.printf( "BEFORE---------------\n" );
    display( true );

    for( int i=first_index; i<last_index; i++ ) {
      var node = p.children().index( first_index );
      node.detach( side );
      add_node( node );
      stdout.printf( "  ADDING NODE--------------\n" );
      display( true );
    }

    double name_space;
    calculate_node_size( out _width, out _height, out name_space );
    update_total_size();

    attach( p, first_index, theme );
    stdout.printf( "  AFTER ATTACHING TO PARENT----------\n" );
    display( true );

  }

  //-------------------------------------------------------------
  // Update the tree_bbox structures of the summarized nodes
  public void update_tree_bboxes() {
    if( layout != null ) {
      foreach( var node in _nodes ) {
        node.tree_bbox = layout.bbox( node, -1, "update_tree_bboxes" );
        node.tree_size = side.horizontal() ? node.tree_bbox.height : node.tree_bbox.width;
      }
    }
  }

  //-------------------------------------------------------------
  // Returns the index of this node within this summarized node.
  // If it cannot be found, returns -1.
  public int node_index( BaseNode node ) {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ) == node ) {
        return( i );
      }
    }
    return( -1 );
  }

  //-------------------------------------------------------------
  // Adds the given node to the list of summarized nodes
  public void add_node( BaseNode node, int index = -1 ) {

    // Modify the node to point to ourself (this will allow it to identify as part of this summarized node)
    node.parent = this;

    // Connect the node signals so that we can handle their placement
    connect_node( node );

    // Add the node to our internal list
    if( index == -1 ) {
      _nodes.append_val( node );
    } else {
      _nodes.insert_val( index, node );
    }

    // FOOBAR

    // Force the node to be positioned
    nodes_changed( 1, 1, "add_nodes" );

  }

  //-------------------------------------------------------------
  // Moves the given node from its current location to a new location
  public void node_moved( BaseNode node ) {
    nodes_changed( 1, 1, "node_moved" );
  }

  //-------------------------------------------------------------
  // Removes the given node from the list of summarized nodes
  public void remove_node( BaseNode node ) {

    var index = node_index( node );

    // If the given node exists in the summarized node list, go ahead and remove it
    if( index != -1 ) {

      node.parent = null;
      disconnect_node( node );
      _nodes.remove_index( index );

      if( _nodes.length == 1 ) {
        this.delete();
      } else {
        nodes_changed( 1, 1, "remove_node" );
      }

    }

  }

  //-------------------------------------------------------------
  // Removes all summarized nodes from this node, attaching them
  // back into the tree, so that we can be deleted.
  public override void delete() {

    var sn_index = index();

    // If we have exactly one summarized node, attach the summary node (the child of this node)
    // to the last remaining item (otherwise, it will be deleted entirely).
    if( _nodes.length == 1 ) {
      var summary  = _children.index( 0 );
      summary.detach( summary.side );
      summary.attach( _nodes.index( 0 ), -1, null );
    }

    // Connect all summarized nodes back into the parent tree
    while( _nodes.length > 0 ) {
      var node = _nodes.index( _nodes.length - 1 ); 
      node.parent = null;
      node.attach( _parent, sn_index, null );
      remove_node( node );
    }

  }

  //-------------------------------------------------------------
  // DRAWING
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Returns the link point for this node.
  protected override void link_point( out double x, out double y, bool seq = false ) {
    int    margin = style.node_margin;
    double height = (_height / 2);
    switch( side ) {
      case NodeSide.LEFT :
        x = posx + margin - 20;
        y = posy + height;
        break;
      case NodeSide.TOP :
        x = posx + (_width / 2);
        y = posy + margin - 20;
        break;
      case NodeSide.RIGHT :
        x = posx + _total_width + 20;
        y = posy + height;
        break;
      default :
        x = posx + (_width / 2);
        y = posy + _total_height - margin + 20;
        break;
    }
  }

  //-------------------------------------------------------------
  // Draws the link to the left of the summarized nodes
  private void draw_bracket( Context ctx ) {

    double x, y, w, h;
    bbox( out x, out y, out w, out h );

    double x1, y1, x2, y2;
    switch( side ) {
      case NodeSide.LEFT :
        x1 = x - 10;
        y1 = y;
        x2 = x - 20;
        y2 = y + h;
        break;
      case NodeSide.RIGHT :
        x1 = x + w + 10;
        y1 = y;
        x2 = x + w + 20;
        y2 = y + h;
        break;
      case NodeSide.TOP :
        x1 = x;
        y1 = y - 10;
        x2 = x + w;
        y2 = y - 20;
        break;
      case NodeSide.BOTTOM :
        x1 = x;
        y1 = y + h + 10;
        x2 = x + w;
        y2 = y + h + 20;
        break;
      default :  assert_not_reached();
    }

    var summary    = (Node)_children.index( 0 );
    var link_color = summary.link_color;

    Utils.set_context_color_with_alpha( ctx, link_color, alpha );
    ctx.move_to( x1, y1 );
    ctx.line_to( x2, y1 );
    ctx.line_to( x2, y2 );
    ctx.line_to( x1, y2 );
    ctx.stroke();

  }

  //-------------------------------------------------------------
  // Draw the summary link that spans the first and last node
  public override void draw( Context ctx, Theme theme, bool motion, bool exporting ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).draw( ctx, theme, motion, exporting );
    }
    draw_bracket( ctx );

    Utils.set_context_color_with_alpha( ctx, theme.get_color( "foreground" ), 0.2 );
    ctx.rectangle( _posx, _posy, _width, _height );
    ctx.fill();

    Utils.set_context_color_with_alpha( ctx, theme.get_color( "foreground" ), 0.2 );
    ctx.rectangle( tree_bbox.x, tree_bbox.y, tree_bbox.width, tree_bbox.height );
    ctx.fill();

  }

  //-------------------------------------------------------------
  // Displays this node to standard output for debugging purposes.
  public override void display( bool recursive = false, string prefix = "" ) {
    stdout.printf( "%sSummarizedNode (%p), _parent: %p, parent: %p, summary: %p, posx: %g, posy: %g, side: %s, layout: %s\n", prefix, this, _parent, parent, children().index( 0 ), posx, posy, side.to_string(), ((layout == null) ? "Unknown" : layout.name) );
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).display( recursive, prefix + "  " );
    }
    stdout.printf( "%sEndSummarized\n", prefix );
    if( recursive ) {
      for( int i=0; i<_children.length; i++ ) {
        _children.index( i ).display( recursive, prefix + "  " );
      }
    }
  }

}
