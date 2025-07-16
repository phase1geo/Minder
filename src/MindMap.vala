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

public enum MapItemComponent {
  NONE,
  CURVE,
  TITLE_BOX,
  TITLE,
  NOTE,
  DRAG_HANDLE,
  FROM_HANDLE,
  TO_HANDLE,
  STICKER,
  NODE_LINK,
  IMAGE,
  LINK,
  TASK,
  FOLD,
  RESIZER;

  //-------------------------------------------------------------
  // Returns true if this component is a connection handle.
  public bool is_connection_handle() {
    return( (this == DRAG_HANDLE) || (this == FROM_HANDLE) || (this == TO_HANDLE) );
  }
}

public class MindMap {

  private DrawArea           _da;  // TBD - Temporary
  private GLib.Settings      _settings;
  private Node?              _last_node       = null;
  private Array<Node>        _nodes;
  private Connections        _connections;
  private Stickers           _stickers;
  private Theme              _theme;
  private Node?              _last_match     = null;
  private Node?              _attach_node    = null;
  private SummaryNode?       _attach_summary = null;
  private Connection?        _attach_conn    = null;
  private Sticker?           _attach_sticker = null;
  private uint?              _auto_save_id   = null;
  private bool               _debug        = true;
  private bool               _focus_mode   = false;
  private double             _focus_alpha  = 0.05;
  private Selection          _selected;
  private NodeGroups         _groups;
  private int                _next_node_id    = -1;
  private NodeLinks          _node_links;
  private bool               _hide_callouts   = false;
  private Array<string>      _braindump;

  public MainWindow     win             { private set; get; }
  public UndoBuffer     undo_buffer     { set; get; }
  public UndoTextBuffer undo_text       { set; get; }
  public Layouts        layouts         { set; get; default = new Layouts(); }
  public ImageManager   image_manager   { set; get; default = new ImageManager(); }
  public bool           is_loaded       { get; private set; default = false; }
  public bool           braindump_shown { get; set; default = false; }

  public DrawArea da {
    get {
      return( _da );
    }
  }
  public double origin_x {
    get {
      return( _da.origin_x );
    }
  }
  public double origin_y {
    get {
      return( _da.origin_y );
    }
  }
  public GLib.Settings settings {
    get {
      return( _settings );
    }
  }
  public Selection selected {
    get {
      return( _selected );
    }
  }
  public Stickers stickers {
    get {
      return( _stickers );
    }
  }
  public NodeGroups groups {
    get {
      return( _groups );
    }
  }
  public NodeLinks node_links {
    get {
      return( _node_links );
    }
  }
  public int next_node_id {
    set {
      if( !is_loaded && (_next_node_id < value) ) {
        _next_node_id = value;
      }
    }
    get {
      _next_node_id++;
      return( _next_node_id );
    }
  }
  public bool hide_callouts {
    get {
      return( _hide_callouts );
    }
    set {
      if( _hide_callouts != value ) {
        if( is_callout_editable() ) {
          set_callout_mode( _selected.current_callout(), CalloutMode.NONE );
          _selected.clear_callouts( false );
        }
        _da.animator.add_callouts_fade( _nodes, value, "hide callouts" );
        _hide_callouts = value;
        auto_save();
        _da.animator.animate();
      }
    }
  }
  public Node? attach_node {
    get {
      return( _attach_node );
    }
  }
  public SummaryNode? attach_summary {
    get {
      return( _attach_summary );
    }
  }
  public Connection? attach_conn {
    get {
      return( _attach_conn );
    }
  }
  public Sticker? attach_sticker {
    get {
      return( _attach_sticker );
    }
  }
  public Array<string> braindump {
    get {
      return( _braindump );
    }
  }
  public Node? last_node {
    get {
      return( _last_node );
    }
    set {
      _last_node = value;
    }
  }

  public signal void changed();
  public signal void current_changed( MindMap map );
  public signal void theme_changed( MindMap map );
  public signal void loaded();
  public signal void queue_draw();
  public signal void see( bool animate = true, double width_adjust = 0, double pad = 100.0 );

  /* Default constructor */
  public MindMap( DrawArea da, GLib.Settings settings ) {

    _da       = da;
    win       = da.win;
    _settings = settings;

    /* Create the selection */
    _selected = new Selection( this );
    _selected.selection_changed.connect( selection_changed );

    /* Create the array of root nodes in the map */
    _nodes = new Array<Node>();

    /* Create the connections */
    _connections = new Connections();

    /* Create the stickers */
    _stickers = new Stickers();

    /* Create groups */
    _groups = new NodeGroups();

    /* Allocate memory for the undo buffer */
    undo_buffer = new UndoBuffer( this );

    /* Allocate the note node links manager */
    _node_links = new NodeLinks();

    // Create the braindump list
    _braindump = new Array<string>();

    /* Get the value of the new node from edit */
    update_focus_mode_alpha( settings );
    settings.changed.connect(() => {
      update_focus_mode_alpha( settings );
    });

    /* Set the theme to the default theme */
    set_theme( win.themes.get_theme( settings.get_string( "default-theme" ) ), false );

    /* Create the undo text buffer */
    undo_text = new UndoTextBuffer( this );

    // Initialize variables
    _attach_node    = null;
    _attach_summary = null;
    _attach_conn    = null;
    _attach_sticker = null;

  }

  /* If the current selection ever changes, let the sidebar know about it. */
  private void selection_changed() {
    update_focus_mode();
    current_changed( this );
  }

  /* Returns the name of the currently selected theme */
  public string get_theme_name() {
    return( _theme.name );
  }

  /* Returns the current theme */
  public Theme get_theme() {
    return( _theme );
  }

  /* Sets the theme to the given value */
  public void set_theme( Theme theme, bool save ) {
    Theme? orig_theme = _theme;
    _theme        = theme;
    _theme.index  = (orig_theme != null) ? orig_theme.index : -1;
    _theme.rotate = _settings.get_boolean( "rotate-main-link-colors" );
    FormattedText.set_theme( theme );
    update_css();
    if( orig_theme != null ) {
      update_theme_colors( orig_theme );
    }
    theme_changed( this );
    queue_draw();
    if( save ) {
      auto_save();
    }
  }

  /* Updates the CSS for the current theme */
  public void update_css() {
    StyleContext.add_provider_for_display(
      Display.get_default(),
      _theme.get_css_provider( win.text_size ),
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );
  }

  /* Updates all nodes with the new theme colors */
  private void update_theme_colors( Theme old_theme ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).update_theme_colors( old_theme, _theme );
    }
  }

  /* Sets the layout to the given value */
  public void set_layout( string name, Node? root_node, bool undoable = true ) {
    var old_layout = (root_node == null) ? _nodes.index( 0 ).layout : root_node.layout;
    var new_layout = layouts.get_layout( name );
    if( undoable ) {
      undo_buffer.add_item( new UndoNodeLayout( old_layout, new_layout, root_node ) );
    }
    var old_balanceable = old_layout.balanceable;
    _da.animator.add_nodes( _nodes, "set layout" );
    if( root_node == null ) {
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).layout = new_layout;
        new_layout.initialize( _nodes.index( i ) );
      }
    } else {
      root_node.layout = new_layout;
      new_layout.initialize( root_node );
    }
    if( !old_balanceable && new_layout.balanceable ) {
      balance_nodes( false, false );
    }
    _da.animator.animate();
  }

  /* Updates all of the node sizes */
  public void update_node_sizes() {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).update_tree();
    }
    queue_draw();
  }

  /* Returns the list of nodes */
  public Array<Node> get_nodes() {
    return( _nodes );
  }

  /* Returns the connections list */
  public Connections get_connections() {
    return( _connections );
  }

  /* Searches for and returns the node with the specified ID */
  public Node? get_node( Array<Node> nodes, int id ) {
    for( int i=0; i<nodes.length; i++ ) {
      Node? node = nodes.index( i ).get_node( id );
      if( node != null ) {
        return( node );
      }
    }
    return( null );
  }

  /* Loads the given theme from the list of available options */
  private void load_theme( Xml.Node* n ) {

    /* Load the theme */
    var theme       = new Theme.from_theme( win.themes.get_theme( "default" ) );
    theme.temporary = true;
    theme.rotate    = _settings.get_boolean( "rotate-main-link-colors" );

    var valid = theme.load( n );

    /* If this theme does not currently exist, add the theme temporarily */
    if( !win.themes.exists( theme ) ) {
      if( valid ) {
        theme.name = win.themes.uniquify_name( theme.name );
        win.themes.add_theme( theme );
      } else {
        theme.name = "default";
      }
    }

    /* Get the theme */
    _theme = win.themes.get_theme( theme.name );

    /* If we are the current drawarea, update the CSS and indicate the theme change */
    if( _da.win.get_current_da() == _da ) {
      update_css();
      theme_changed( this );
    }

  }

  /*
   We don't store the layout, but if it is found, we need to initialize the
   layout information for all nodes to this value.
  */
  private void load_layout( Xml.Node* n, ref Layout? layout ) {

    string? name = n->get_prop( "name" );
    if( name != null ) {
      layout = layouts.get_layout( name );
    }

  }

  //-------------------------------------------------------------
  // Searches for a node with the given ID.  If found, returns
  // true along with its title.
  public static bool xml_find( Xml.Node* n, int id, ref string name ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "nodes") ) {
        for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
          if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
            if( Node.xml_find( it2, id, ref name ) ) {
              return( true );
            }
          }
        }
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Loads the contents of the data input stream
  public void load( Xml.Node* n ) {

    Layout? use_layout = null;

    /* Disable animations while we are loading */
    var animate = _da.animator.enable;
    _da.animator.enable = false;

    /* Clear the existing nodes */
    _nodes.remove_range( 0, _nodes.length );

    /* Load the contents of the file */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "theme"       :  load_theme( it );   break;
          case "layout"      :  load_layout( it, ref use_layout );  break;
          case "styles"      :  StyleInspector.styles.load( it );  break;
          case "images"      :  image_manager.load( it );  break;
          case "connections" :  _connections.load( this, it, null, _nodes );  break;
          case "groups"      :  groups.load( this, it, null, _nodes );  break;
          case "stickers"    :  _stickers.load( this, it );  break;
          case "nodelinks"   :  _node_links.load( it );  break;
          case "nodes"       :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                var siblings = new Array<Node>();
                var node = new Node.from_xml( this, null, it2, true, null, ref siblings );
                if( use_layout != null ) {
                  node.layout = use_layout;
                }
                _nodes.append_val( node );
              }
            }
            break;
          case "ideas" :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "idea") ) {
                var idea = it2->get_prop( "text" );
                if( idea != null ) {
                  _braindump.append_val( idea );
                }
              }
            }
            break;
        }
      }
    }

    /* Perform the layout process again to make sure that everything is accounted for */
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).layout.initialize( _nodes.index( i ) );
    }

    queue_draw();

    /* Indicate to anyone listening that we have loaded a new file */
    is_loaded = true;
    loaded();

    /* Make sure that the inspector is updated */
    current_changed( this );

    /* Reset the animator enable */
    _da.animator.enable = animate;

  }

  //-------------------------------------------------------------
  // Saves the contents of the drawing area to the data output
  // stream.
  public bool save( Xml.Node* parent ) {

    parent->add_child( _theme.save() );

    StyleInspector.styles.save( parent );

    Xml.Node* images = new Xml.Node( null, "images" );
    image_manager.save( images );
    parent->add_child( images );

    Xml.Node* nodes = new Xml.Node( null, "nodes" );
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).save( nodes );
    }
    parent->add_child( nodes );
    parent->add_child( groups.save() );

    _connections.save( parent );
    parent->add_child( _stickers.save() );

    parent->add_child( _node_links.save() );

    Xml.Node* ideas = new Xml.Node( null, "ideas" );
    for( int i=0; i<_braindump.length; i++ ) {
      Xml.Node* idea = new Xml.Node( null, "idea" );
      idea->set_prop( "text", _braindump.index( i ) );
      ideas->add_child( idea );
    }
    parent->add_child( ideas );

    return( true );

  }

  //-------------------------------------------------------------
  // Figures out the boundaries of the document primarily for the
  // purposes of printing.
  public void document_rectangle( out double x, out double y, out double width, out double height ) {

    double x1 =  10000000;
    double y1 =  10000000;
    double x2 = -10000000;
    double y2 = -10000000;

    /* Calculate the overall size of the map */
    for( int i=0; i<_nodes.length; i++ ) {
      var nb = _nodes.index( i ).tree_bbox;
      x1 = (x1 < nb.x) ? x1 : nb.x;
      y1 = (y1 < nb.y) ? y1 : nb.y;
      x2 = (x2 < (nb.x + nb.width))  ? (nb.x + nb.width)  : x2;
      y2 = (y2 < (nb.y + nb.height)) ? (nb.y + nb.height) : y2;
    }

    /* Include the connection and sticker extents */
    _connections.add_extents( ref x1, ref y1, ref x2, ref y2 );
    _stickers.add_extents( ref x1, ref y1, ref x2, ref y2 );

    /* Set the outputs */
    x      = x1;
    y      = y1;
    width  = (x2 - x1);
    height = (y2 - y1);

  }

  //-------------------------------------------------------------
  // Initializes the mindmap to prepare it for a document that
  // will be loaded.
  public void initialize() {

    /* Clear the list of existing nodes */
    _nodes.remove_range( 0, _nodes.length );

    /* Clear the list of connections */
    _connections.clear_all_connections();

    /* Clear the stickers */
    _stickers.clear();

    /* Clear the groups */
    _groups.clear();

    /* Clear the undo buffer */
    undo_buffer.clear();

    /* Clear the selection */
    _selected.clear();

  }

  //-------------------------------------------------------------
  // Returns the current node.
  public Node? get_current_node() {
    return( _selected.current_node() );
  }

  //-------------------------------------------------------------
  // Returns the current connection
  public Connection? get_current_connection() {
    return( _selected.current_connection() );
  }

  //-------------------------------------------------------------
  // Returns the current callout
  public Callout? get_current_callout() {
    return( _selected.current_callout() );
  }

  //-------------------------------------------------------------
  // Returns the array of selected nodes
  public Array<Node> get_selected_nodes() {
    return( _selected.nodes() );
  }

  //-------------------------------------------------------------
  // Returns the array of selected connections
  public Array<Connection> get_selected_connections() {
    return( _selected.connections() );
  }

  //-------------------------------------------------------------
  // Returns the array of selected callouts
  public Array<Callout> get_selected_callouts() {
    return( _selected.callouts() );
  }

  //-------------------------------------------------------------
  // Returns the current group (if selected)
  public NodeGroup? get_current_group() {
    return( _selected.current_group() );
  }

  //-------------------------------------------------------------
  // Returns the array of selected groups
  public Array<NodeGroup> get_selected_groups() {
    return( _selected.groups() );
  }

  //-------------------------------------------------------------
  // Populates the list of matches with any nodes that match the
  // given string pattern.
  public void get_match_items(string tabname, string pattern, bool[] search_opts, ref Gtk.ListStore matches ) {
    if( search_opts[SearchOptions.NODES] || search_opts[SearchOptions.CALLOUTS] ) {
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).get_match_items( tabname, pattern, search_opts, ref matches );
      }
    }
    if( search_opts[SearchOptions.CONNECTIONS] ) {
      _connections.get_match_items( tabname, pattern, search_opts, ref matches );
    }
    if( search_opts[SearchOptions.GROUPS] ) {
      _groups.get_match_items( tabname, pattern, search_opts, ref matches );
    }
  }

  //-------------------------------------------------------------
  // Sets the current node to the given node
  public void set_current_node( Node? n ) {
    if( n == null ) {
      _selected.clear_nodes();
    } else if( _selected.is_node_selected( n ) && (_selected.num_nodes() == 1) ) {
      set_node_mode( _selected.nodes().index( 0 ), NodeMode.CURRENT );
    } else {
      _selected.clear_nodes( false );
      var last_folded = n.folded_ancestor();
      if( last_folded != null ) {
        last_folded.set_fold_only( false );
        undo_buffer.add_item( new UndoNodeFolds.single( last_folded ) );
      }
      _selected.add_node( n );
    }
  }

  //-------------------------------------------------------------
  // Needs to be called whenever the user changes the mode of the
  // current node
  public void set_node_mode( Node node, NodeMode mode, bool undoable = true ) {
    if( (node.mode != NodeMode.EDITABLE) && (mode == NodeMode.EDITABLE) ) {
      _da.update_im_cursor( node.name );
      _da.im_context.focus_in();
      if( node.name.is_within( _da.scaled_x, _da.scaled_y ) ) {
        _da.set_text_cursor();
      }
      undo_text.orig.copy( node.name );
      undo_text.ct      = node.name;
      undo_text.do_undo = undoable;
      node.mode = mode;
    } else if( (node.mode == NodeMode.EDITABLE) && (mode != NodeMode.EDITABLE) ) {
      _da.im_context.reset();
      _da.im_context.focus_out();
      if( node.name.is_within( _da.scaled_x, _da.scaled_y ) ) {
        _da.reset_cursor();
      }
      undo_text.clear();
      if( undo_text.do_undo ) {
        undo_buffer.add_item( new UndoNodeName( this, node, undo_text.orig ) );
      }
      undo_text.ct      = null;
      undo_text.do_undo = false;
      node.mode = mode;
      auto_save();
    } else {
      node.mode = mode;
    }
  }

  //-------------------------------------------------------------
  // Needs to be called whenever the user changes the mode of the
  // current connection
  public void set_connection_mode( Connection conn, ConnMode mode, bool undoable = true ) {
    if( (conn.mode != ConnMode.EDITABLE) && (mode == ConnMode.EDITABLE) ) {
      _da.update_im_cursor( conn.title );
      _da.im_context.focus_in();
      if( (conn.title != null) && conn.title.is_within( _da.scaled_x, _da.scaled_y ) ) {
        _da.set_text_cursor();
      }
      undo_text.orig.copy( conn.title );
      undo_text.ct      = conn.title;
      undo_text.do_undo = undoable;
    } else if( (conn.mode == ConnMode.EDITABLE) && (mode != ConnMode.EDITABLE) ) {
      _da.im_context.reset();
      _da.im_context.focus_out();
      if( (conn.title != null) && conn.title.is_within( _da.scaled_x, _da.scaled_y ) ) {
        _da.reset_cursor();
      }
      undo_text.clear();
      if( undo_text.do_undo ) {
        undo_buffer.add_item( new UndoConnectionTitle( this, conn, undo_text.orig ) );
      }
      undo_text.ct      = null;
      undo_text.do_undo = false;
    }
    conn.mode = mode;
  }

  //-------------------------------------------------------------
  // Needs to be called whenever the user changes the mode of the
  // current callout.
  public void set_callout_mode( Callout callout, CalloutMode mode, bool undoable = true ) {
    if( (callout.mode != CalloutMode.EDITABLE) && (mode == CalloutMode.EDITABLE) ) {
      _da.update_im_cursor( callout.text );
      _da.im_context.focus_in();
      if( (callout.text != null) && callout.text.is_within( _da.scaled_x, _da.scaled_y ) ) {
        _da.set_text_cursor();
      }
      undo_text.orig.copy( callout.text );
      undo_text.ct      = callout.text;
      undo_text.do_undo = undoable;
      callout.mode = mode;
    } else if( (callout.mode == CalloutMode.EDITABLE) && (mode != CalloutMode.EDITABLE) ) {
      _da.im_context.reset();
      _da.im_context.focus_out();
      if( (callout.text != null) && callout.text.is_within( _da.scaled_x, _da.scaled_y ) ) {
        _da.reset_cursor();
      }
      undo_text.clear();
      if( undo_text.do_undo ) {
        undo_buffer.add_item( new UndoCalloutText( this, callout, undo_text.orig ) );
      }
      undo_text.ct      = null;
      undo_text.do_undo = false;
      callout.mode = mode;
      auto_save();
    } else {
      callout.mode = mode;
    }
  }

  //-------------------------------------------------------------
  // Returns the undo buffer associated with the current state
  public UndoBuffer current_undo_buffer() {
    var current = _selected.current_node();
    if( (current != null) && (current.mode == NodeMode.EDITABLE) ) {
      return( undo_text );
    }
    return( undo_buffer );
  }

  //-------------------------------------------------------------
  // Sets the current connection to the given node
  public void set_current_connection( Connection? c ) {
    if( c != null ) {
      _selected.set_current_connection( c );
      c.from_node.last_selected_connection = c;
      c.to_node.last_selected_connection   = c;
    } else {
      _selected.clear_connections();
    }
  }

  //-------------------------------------------------------------
  // Sets the current selected sticker to the specified sticker
  public void set_current_sticker( Sticker? s ) {
    _selected.set_current_sticker( s );
    _stickers.select_sticker( s );
  }

  //-------------------------------------------------------------
  // Sets the current selected group to the specified group
  public void set_current_group( NodeGroup? g ) {
    _selected.set_current_group( g );
  }

  //-------------------------------------------------------------
  // Sets the current selected callout to the specified callout
  public void set_current_callout( Callout? c ) {
    _selected.set_current_callout( c );
  }

  //-------------------------------------------------------------
  // Toggles the value of the specified node, if possible
  public void toggle_task( Node n ) {
    var changes = new Array<NodeTaskInfo?>();
    n.toggle_task_done( ref changes );
    undo_buffer.add_item( new UndoNodeTasks( changes ) );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Toggles the fold for the given node
  public void toggle_fold( Node n, bool deep ) {
    var fold    = !n.folded;
    var changes = new Array<Node>();
    n.set_fold( fold, deep, changes );
    undo_buffer.add_item( new UndoNodeFolds( changes ) );
    current_changed( this );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Toggles the folding of all selected nodes that can be folded
  public void toggle_folds( bool deep = false ) {
    var parents = new Array<Node>();
    var changes = new Array<Node>();
    _selected.get_parents( ref parents );
    if( parents.length > 0 ) {
      for( int i=0; i<parents.length; i++ ) {
        var node = parents.index( i );
        node.set_fold( !node.folded, deep, changes );
      }
      undo_buffer.add_item( new UndoNodeFolds( changes ) );
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Adds a new group for the given list of nodes
  public void add_group() {
    if( _selected.num_groups() > 1 ) {
      var selgroups = _selected.groups();
      var merged    = groups.merge_groups( selgroups );
      if( merged != null ) {
        undo_buffer.add_item( new UndoGroupsMerge( selgroups, merged ) );
        _selected.set_current_group( merged );
        queue_draw();
        auto_save();
      }
    } else if( _selected.num_nodes() > 0 ) {
      var nodes = _selected.nodes();
      var group = new NodeGroup.array( this, nodes );
      groups.add_group( group );
      undo_buffer.add_item( new UndoGroupAdd( group ) );
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Removes the currently selected group
  public void remove_groups() {
    var selgroups = _selected.groups();
    if( selgroups.length == 0 ) return;
    for( int i=0; i<selgroups.length; i++ ) {
      groups.remove_group( selgroups.index( i ) );
    }
    undo_buffer.add_item( new UndoGroupsRemove( selgroups ) );
    _selected.clear();
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Changes to the color of all selected groups to the given color.
  public void change_group_color( RGBA color ) {
    var selgroups = _selected.groups();
    if( selgroups.length == 0 ) return;
    undo_buffer.add_item( new UndoGroupsColor( selgroups, color ) );
    for( int i=0; i<selgroups.length; i++ ) {
      selgroups.index( i ).color = color;
    }
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Adds a callout to the currently selected node
  public void add_callout() {
    var current = _selected.current_node();
    if( (current != null) && (current.callout == null) ) {
      undo_buffer.add_item( new UndoNodeCallout( current ) );
      current.callout = new Callout( current );
      current.callout.style = StyleInspector.styles.get_global_style();
      _selected.set_current_callout( current.callout, (_focus_mode ? _focus_alpha : 1.0) );
      set_callout_mode( current.callout, CalloutMode.EDITABLE );
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Removes a callout on the currently selected node
  public void remove_callout() {
    if( is_node_selected() ) {
      var current = _selected.current_node();
      if( current.callout != null ) {
        undo_buffer.add_item( new UndoNodeCallout( current ) );
        current.callout = null;
        queue_draw();
        auto_save();
      }
    } else if( is_callout_selected() ) {
      var current = _selected.current_callout().node;
      undo_buffer.add_item( new UndoNodeCallout( current ) );
      current.callout = null;
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Changes the current connection's title to the given value.
  public void change_current_connection_title( string title ) {
    var conns = _selected.connections();
    if( conns.length == 1 ) {
      var current = conns.index( 0 );
      if( current.title.text.text != title ) {
        var orig_title = new CanvasText( this );
        orig_title.copy( current.title );
        current.change_title( this, title );
        // if( !_current_new ) {
          undo_buffer.add_item( new UndoConnectionTitle( this, current, orig_title ) );
        // }
        queue_draw();
        auto_save();
      }
    }
  }

  //-------------------------------------------------------------
  // Changes the state of the given task if it differs from the
  // desired values
  private void change_task( Node node, bool enable, bool done, Array<NodeTaskInfo?> changes ) {
    if( (node.task_enabled() == enable) && (node.task_done() == done) ) return;
    changes.append_val( NodeTaskInfo( node.task_enabled(), node.task_done(), node ) );
    node.enable_task( enable );
    node.set_task_done( done );
  }

  //-------------------------------------------------------------
  // Changes the current node's task to the given values.  Updates
  // the layout, adds the undo item, and redraws the canvas.
  public void change_current_task( bool enable, bool done ) {
    var nodes = _selected.nodes();
    if( nodes.length != 1 ) return;
    var changes = new Array<NodeTaskInfo?>();
    change_task( nodes.index( 0 ), enable, done, changes );
    if( changes.length > 0 ) {
      undo_buffer.add_item( new UndoNodeTasks( changes ) );
      current_changed( this );
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Toggles the task values of the selected nodes
  public void change_selected_tasks() {
    var parents     = new Array<Node>();
    var changes     = new Array<NodeTaskInfo?>();
    var all_enabled = true;
    var all_done    = true;
    _selected.get_parents( ref parents );
    for( int i=0; i<parents.length; i++ ) {
      var node = parents.index( i );
      all_enabled &= node.task_enabled();
      all_done    &= node.task_done();
    }
    if( all_enabled ) {
      if( all_done ) {
        for( int i=0; i<parents.length; i++ ) {
          change_task( parents.index( i ), false, false, changes );
        }
      } else {
        for( int i=0; i<parents.length; i++ ) {
          change_task( parents.index( i ), true, true, changes );
        }
      }
    } else {
      for( int i=0; i<parents.length; i++ ) {
        change_task( parents.index( i ), true, false, changes );
      }
    }
    if( changes.length > 0 ) {
      undo_buffer.add_item( new UndoNodeTasks( changes ) );
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Changes the current node's folded state to the given value.
  // Updates the layout, adds the undo item and redraws the canvas.
  public void change_current_fold( bool folded, bool deep = false ) {
    var nodes = _selected.nodes();
    if( nodes.length == 1 ) {
      var current = nodes.index( 0 );
      var changes = new Array<Node>();
      current.set_fold( folded, deep, changes );
      undo_buffer.add_item( new UndoNodeFolds( changes ) );
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Changes the current node's note to the given value.  Updates
  // the layout, adds the undo item and redraws the canvas.
  public void change_current_node_note( string note ) {
    var nodes = _selected.nodes();
    if( nodes.length == 1 ) {
      nodes.index( 0 ).note = note;
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // If there is a currently selected node (and there should be),
  // adds the given node link to the current node's list and
  // returns the unique ID associated with the node link.
  public int add_note_node_link( NodeLink link, out string text ) {
    link.normalize( _da );
    text = link.get_markdown_text( this );
    return( _node_links.add_link( link ) );
  }

  //-------------------------------------------------------------
  // Handles a user click on a node link with the given ID
  public void note_node_link_clicked( int id ) {
    var link = _node_links.get_node_link( id );
    if( link != null ) {
      link.select( _da );
    }
  }

  //-------------------------------------------------------------
  // A link can be added if text is selected and the selected text
  // does not overlap with any existing links.
  public bool add_link_possible( CanvasText ct ) {

    int cursor, selstart, selend;
    if( ct.is_selected() ) {
      ct.get_cursor_info( out cursor, out selstart, out selend );
    } else {
      selstart = 0;
      selend   = ct.text.text.length;
    }

    return( (selstart != selend) && !ct.text.is_tag_applied_in_range( FormatTag.URL, selstart, selend ) );

  }


  //-------------------------------------------------------------
  // Changes the current connection's note to the given value.
  public void change_current_connection_note( string note ) {
    var conns = _selected.connections();
    if( conns.length == 1 ) {
      conns.index( 0 ).note = note;
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Adds an image to the current node by allowing the user to
  // select an image file from the file system and, optionally,
  // editing the image prior to assigning it to a node.  Updates
  // the layout, adds the undo item and redraws the canvas item
  // and redraws the canvas.
  public void add_current_image() {
    var current = _selected.current_node();
    if( (current != null) && (current.image == null) ) {
      image_manager.choose_image( win, (id) => {
        var curr = _selected.current_node();
        curr.set_image( image_manager, new NodeImage( image_manager, id, curr.style.node_width ) );
        if( curr.image != null ) {
          undo_buffer.add_item( new UndoNodeImage( curr, null ) );
          queue_draw();
          current_changed( this );
          auto_save();
        }
      });
    }
  }

  //-------------------------------------------------------------
  // Deletes the image from the current node.  Updates the layout,
  // adds the undo item and redraws the canvas.
  public void delete_current_image() {
    var nodes = _selected.nodes();
    if( nodes.length == 1 ) {
      var current = nodes.index( 0 );
      NodeImage? orig_image = current.image;
      if( orig_image != null ) {
        current.set_image( image_manager, null );
        undo_buffer.add_item( new UndoNodeImage( current, orig_image ) );
        queue_draw();
        current_changed( this );
        auto_save();
      }
    }
  }

  //-------------------------------------------------------------
  // Causes the current node's image to be edited.
  public void edit_current_image() {
    var nodes = _selected.nodes();
    if( nodes.length == 1 ) {
      var current = nodes.index( 0 );
      if( current.image != null ) {
        _da.image_editor.edit_image( image_manager, current, current.posx, current.posy );
      }
    }
  }

  //-------------------------------------------------------------
  // Called whenever the current node's image is changed
  public void current_image_edited( NodeImage? orig_image ) {
    var current = _selected.current_node();
    undo_buffer.add_item( new UndoNodeImage( current, orig_image ) );
    queue_draw();
    current_changed( this );
    auto_save();
  }

  //-------------------------------------------------------------
  // Called when the linking process has successfully completed
  public void end_link( Node node ) {
    if( _selected.num_connections() == 0 ) return;
    _selected.clear_connections();
    _last_node.linked_node = new NodeLink( node );
    undo_buffer.add_item( new UndoNodeLink( _last_node, null ) );
    _da.last_connection = null;
    _last_node          = null;
    set_attach_node( null );
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Returns true if any of the selected nodes contain node links
  public bool any_selected_nodes_linked() {
    var nodes = _selected.nodes();
    for( int i=0; i<nodes.length; i++ ) {
      if( nodes.index( i ).linked_node != null ) {
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Creates links between selected nodes
  public void create_links() {
    var nodes = _selected.nodes();
    if( nodes.length < 2 ) return;
    undo_buffer.add_item( new UndoNodesLink( nodes ) );
    for( int i=0; i<(nodes.length - 1); i++ ) {
      nodes.index( i ).linked_node = new NodeLink( nodes.index( i + 1 ) );
    }
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Deletes all of the selected node links
  public void delete_links() {
    var nodes = _selected.nodes();
    undo_buffer.add_item( new UndoNodesLink( nodes ) );
    for( int i=0; i<nodes.length; i++ ) {
      if( nodes.index( i ).linked_node != null ) {
        nodes.index( i ).linked_node = null;
      }
    }
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Toggles the node links
  public void toggle_links() {
    var current = _selected.current_node();
    if( any_selected_nodes_linked() ) {
      delete_links();
    } else if( current != null ) {
      start_connection( true, true );
    } else {
      create_links();
    }
  }

  //-------------------------------------------------------------
  // Changes the current node's link color and propagates that
  // color to all descendants.
  public void change_current_link_color( RGBA? color ) {
    var current = _selected.current_node();
    if( current != null ) {
      RGBA? orig_color = current.link_color;
      if( orig_color != color ) {
        current.link_color = color;
        undo_buffer.add_item( new UndoNodeLinkColor( current, orig_color ) );
        queue_draw();
        auto_save();
      }
    }
  }

  //-------------------------------------------------------------
  // Changes the link colors of all selected nodes to the
  // specified color
  public void change_link_colors( RGBA color ) {
    var nodes = _selected.nodes();
    undo_buffer.add_item( new UndoNodesLinkColor( nodes, color ) );
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).link_color = color;
    }
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Randomizes the current link color.
  public void randomize_current_link_color() {
    var current = _selected.current_node();
    if( current != null ) {
      RGBA orig_color = current.link_color;
      do {
        current.link_color = _theme.random_link_color();
      } while( orig_color.equal( current.link_color ) );
      undo_buffer.add_item( new UndoNodeLinkColor( current, orig_color ) );
      queue_draw();
      auto_save();
      current_changed( this );
    }
  }

  //-------------------------------------------------------------
  // Randomizes the link colors of the selected nodes
  public void randomize_link_colors() {
    var nodes  = _selected.nodes();
    var colors = new Array<RGBA?>();
    for( int i=0; i<nodes.length; i++ ) {
      colors.append_val( nodes.index( i ).link_color );
      nodes.index( i ).link_color = _theme.random_link_color();
    }
    undo_buffer.add_item( new UndoNodesRandLinkColor( nodes, colors ) );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Reparents the current node's link color
  public void reparent_current_link_color() {
    var current = _selected.current_node();
    if( current != null ) {
      undo_buffer.add_item( new UndoNodeReparentLinkColor( current ) );
      current.link_color_root = false;
      queue_draw();
      auto_save();
      current_changed( this );
    }
  }

  //-------------------------------------------------------------
  // Causes the selected nodes to use the link color of their parent
  public void reparent_link_colors() {
    var nodes = _selected.nodes();
    undo_buffer.add_item( new UndoNodesReparentLinkColor( nodes ) );
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).link_color_root = false;
    }
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Changes the current connection's color to the specified color.
  public void change_current_connection_color( RGBA? color ) {
    var conn = _selected.current_connection();
    if( conn == null ) return;
    var orig_color = conn.color;
    if( orig_color != color ) {
      conn.color = color;
      undo_buffer.add_item( new UndoConnectionColor( conn, orig_color ) );
      queue_draw();
      auto_save();
      current_changed( this );
    }
  }

  //-------------------------------------------------------------
  // Checks to see if the user has clicked a connection that was
  // not previously selected.  If this is the case, select the
  // connection.
  public bool select_connection_if_unselected( double x, double y ) {
    var conn = _connections.within_title( x, y );
    if( conn == null ) {
      conn = _connections.on_curve( x, y );
    }
    if( conn != null ) {
      if( !_selected.is_connection_selected( conn ) && (conn.mode != ConnMode.EDITABLE) ) {
        _selected.set_current_connection( conn );
        queue_draw();
      }
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Checks to see if the user has clicked a node that was not
  // previously selected.  If this is the case, select the node.
  public bool select_node_if_unselected( double x, double y ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i ).contains( x, y, null );
      if( node != null ) {
        if( !_selected.is_node_selected( node ) && (node.mode != NodeMode.EDITABLE) ) {
          _selected.set_current_node( node );
          queue_draw();
        }
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns the node that is located at the given X,Y coordinates.
  // Additionally, returns the portion of the node that is under
  // those same coordinates.
  public Node? get_node_at_position( double x, double y, out MapItemComponent component ) {
    component = MapItemComponent.NONE;
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i ).contains( x, y, null );
      if( node != null ) {
        if( node.is_within_title( x, y ) ) {
          component = MapItemComponent.TITLE;
        } else if( node.is_within_task( x, y ) ) {
          component = MapItemComponent.TASK;
        } else if( node.is_within_note( x, y ) ) {
          component = MapItemComponent.NOTE;
        } else if( node.is_within_linked_node( x, y ) ) {
          component = MapItemComponent.NODE_LINK;
        } else if( node.is_within_fold( x, y ) ) {
          component = MapItemComponent.FOLD;
        } else if( node.is_within_image( x, y ) ) {
          component = MapItemComponent.IMAGE;
        } else if( node.is_within_resizer( x, y ) ) {
          component = MapItemComponent.RESIZER;
        }
        return( node );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the callout that is located at the given coordinates
  // along with the callout component that is at that position.
  public Callout? get_callout_at_position( double x, double y, out MapItemComponent component ) {
    component = MapItemComponent.NONE;
    for( int i=0; i<_nodes.length; i++ ) {
      var callout = _nodes.index( i ).contains_callout( x, y );
      if( callout != null ) {
        if( callout.is_within_title( x, y ) ) {
          component = MapItemComponent.TITLE;
        } else if( callout.is_within_resizer( x, y ) ) {
          component = MapItemComponent.RESIZER;
        }
        return( callout );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the connection and its associated component that is
  // located at the given X,Y coordinates.
  public Connection? get_connection_at_position( double x, double y, out MapItemComponent component ) {
    return( _connections.within( x, y, out component ) );
  }

  //-------------------------------------------------------------
  // Returns the sticker that is located at the given X,Y coordinates.
  public Sticker? get_sticker_at_position( double x, double y ) {
    return( _stickers.is_within( x, y ) );
  }

  //-------------------------------------------------------------
  // Returns the node group that is located at the given X,Y coordinates.
  public NodeGroup? get_group_at_position( double x, double y ) {
    return( _groups.node_group_containing( x, y ) );
  }

  //-------------------------------------------------------------
  // Sets the given node to be the new attach node.
  public void set_attach_node( Node? n, NodeMode mode = NodeMode.ATTACHABLE ) {
    var change = _attach_node != n;
    if( _attach_node != null ) {
      set_node_mode( _attach_node, NodeMode.NONE );
    }
    _attach_node = n;
    if( n != null ) {
      set_node_mode( n, mode );
    }
    if( change ) {
      _da.queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Sets the given summary node to be the new attach summary node.
  public void set_attach_summary( SummaryNode? n ) {
    var change = (_attach_summary != n);
    if( _attach_summary != null ) {
      _attach_summary.attachable = false;
    }
    _attach_summary = n;
    if( n != null ) {
      _attach_summary.attachable = true;
    }
    if( change ) {
      _da.queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Sets the given connection to be the new attach connection.
  public void set_attach_connection( Connection? c, ConnMode mode = ConnMode.DROPPABLE ) {
    var change = (_attach_conn != c);
    if( _attach_conn != null ) {
      set_connection_mode( _attach_conn, ConnMode.NONE );
    }
    _attach_conn = c;
    if( c != null ) {
      set_connection_mode( c, mode );
    }
    if( change ) {
      _da.queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Sets the attached sticker to the given sticker.
  public void set_attach_sticker( Sticker? s, StickerMode mode = StickerMode.DROPPABLE ) {
    var change = (_attach_sticker != s);
    if( _attach_sticker != null ) {
      _attach_sticker.mode = StickerMode.NONE;
    }
    _attach_sticker = s;
    if( s != null ) {
      s.mode = mode;
    }
    if( change ) {
      _da.queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Returns the attachable node if one is found.
  public Node? attachable_node( double x, double y ) {
    var current = _selected.current_node();
    for( int i=0; i<_nodes.length; i++ ) {
      Node tmp = _nodes.index( i ).contains( x, y, current );
      if( (tmp != null) && (tmp != current.parent) && !current.contains_node( tmp ) && !tmp.is_summarized() ) {
        return( tmp );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the summary node that the current node can be
  // attached to; otherwise, returns null.
  public SummaryNode? attachable_summary_node( double x, double y ) {
    var current = _selected.current_node();
    if( (current.is_summarized() && (current.parent.children().length > 1) && (current.summary_node().summarized_count() > 1)) || current.is_leaf() ) {
      for( int i=0; i<current.parent.children().length; i++ ) {
        var sibling = current.parent.children().index( i );
        if( sibling.last_summarized() && sibling.summary_node().is_within_summarized( x, y ) ) {
          return( sibling.summary_node() );
        }
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Draws all of the root node trees.
  public void draw_all( Context ctx, bool exporting, bool moving_node ) {

    /* Draw the links first */
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).draw_links( ctx, _theme );
    }

    /* Draw groups next */
    _groups.draw_all( ctx, _theme, exporting );

    var current_node = _selected.current_node();
    var current_conn = _selected.current_connection();
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).draw_all( ctx, _theme, current_node, false, exporting );
    }

    /* Draw the current node on top of all others */
    if( (current_node != null) && (current_node.folded_ancestor() == null) ) {
      current_node.draw_all( ctx, _theme, null, (!is_node_editable() && moving_node), exporting );
    }

    /* Draw the current connection on top of everything else */
    _connections.draw_all( ctx, _theme, exporting );
    if( current_conn != null ) {
      current_conn.draw( ctx, _theme, exporting );
    }

    /* Draw the floating stickers */
    _stickers.draw_all( ctx, _theme, 1.0, exporting );

  }

  //-------------------------------------------------------------
  // Selects all nodes within the selected box.
  public void select_nodes_within_box( SelectBox select_box, bool shift ) {
    Gdk.Rectangle box = {
      (int)((select_box.w < 0) ? (select_box.x + select_box.w) : select_box.x),
      (int)((select_box.h < 0) ? (select_box.y + select_box.h) : select_box.y),
      (int)((select_box.w < 0) ? (0 - select_box.w) : select_box.w),
      (int)((select_box.h < 0) ? (0 - select_box.h) : select_box.h)
    };
    if( !shift ) {
      _selected.clear_nodes();
    }
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).select_within_box( box, _selected );
    }
  }

  //-------------------------------------------------------------
  // Updates the last_match.
  public void update_last_match( Node? match ) {
    if( match != _last_match ) {
      if( _last_match != null ) {
        _last_match.show_fold = false;
        queue_draw();
      }
      _last_match = match;
    }
  }

  //-------------------------------------------------------------
  // Attaches the current node to the attach node.
  public void attach_current_node() {

    Node?        orig_parent        = null;
    var          orig_index         = -1;
    SummaryNode? orig_summary       = null;
    var          orig_summary_index = -1;
    var          current            = _selected.current_node();
    var          isroot             = current.is_root();
    var          isleaf             = current.is_leaf();

    /* Remove the current node from its current location */
    if( isroot ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) == current ) {
          _nodes.remove_index( i );
          orig_index = i;
          break;
        }
      }
    } else {
      orig_parent        = current.parent;
      orig_index         = current.index();
      orig_summary       = current.summary_node();
      orig_summary_index = (orig_summary != null) ? orig_summary.node_index( current ) : -1;
      current.detach( _da.get_orig_side() );
      if( (orig_summary != null) && (orig_summary.summarized_count() > 1) ) {
        orig_summary.remove_node( current );
      }
    }

    var summary = _attach_node.summary_node();

    if( isleaf && (orig_summary != summary) && _attach_node.first_summarized() ) {
      current.attach( _attach_node.parent, _attach_node.index(), _theme );
      summary.add_node( current );
    } else if( isleaf && (orig_summary != summary) && _attach_node.last_summarized() ) {
      current.attach( _attach_node.parent, (_attach_node.index() + 1), _theme );
      summary.add_node( current );
    } else if( (orig_summary == summary) && _attach_node.first_summarized() ) {
      current.attach( _attach_node.parent, _attach_node.index(), _theme );
    } else if( (orig_summary == summary) && _attach_node.last_summarized() ) {
      current.attach( _attach_node.parent, (_attach_node.index() + 1), _theme );
    } else {
      current.attach( _attach_node, -1, _theme );
    }

    /* Attach the node */
    set_attach_node( null );

    /* Add the attachment information to the undo buffer */
    if( isroot ) {
      undo_buffer.add_item( new UndoNodeAttach.for_root( current, orig_index, _da.orig_info ) );
    } else {
      undo_buffer.add_item( new UndoNodeAttach( current, orig_parent, _da.get_orig_side(), orig_index, _da.orig_info, orig_summary, orig_summary_index ) );
    }

    queue_draw();
    auto_save();
    current_changed( this );

  }

  //-------------------------------------------------------------
  // Returns true if we are connecting a connection title.
  public bool is_connection_connecting() {
    var current = _selected.current_connection();
    return( (current != null) && (current.mode == ConnMode.CONNECTING) );
  }

  //-------------------------------------------------------------
  // Returns true if we are editing a connection title.
  public bool is_connection_editable() {
    var current = _selected.current_connection();
    return( (current != null) && (current.mode == ConnMode.EDITABLE) );
  }

  //-------------------------------------------------------------
  // Returns true if the current callout is in the selected state.
  public bool is_callout_selected() {
    var current = _selected.current_callout();
    return( (current != null) && (current.mode == CalloutMode.SELECTED) );
  }

  //-------------------------------------------------------------
  // Returns true if we are editing a callout title.
  public bool is_callout_editable() {
    var current = _selected.current_callout();
    return( (current != null) && (current.mode == CalloutMode.EDITABLE) );
  }

  //-------------------------------------------------------------
  // Returns true if the current connection is in the selected state.
  public bool is_connection_selected() {
    var current = _selected.current_connection();
    return( (current != null) && (current.mode == ConnMode.SELECTED) );
  }

  //-------------------------------------------------------------
  // Returns true if we are in node edit mode.
  public bool is_node_editable() {
    var current = _selected.current_node();
    return( (current != null) && (current.mode == NodeMode.EDITABLE) );
  }

  //-------------------------------------------------------------
  // Returns true if we are in node selected mode.
  public bool is_node_selected() {
    var current = _selected.current_node();
    return( (current != null) && (current.mode == NodeMode.CURRENT) );
  }

  //-------------------------------------------------------------
  // Returns true if we are in sticker selected mode.
  public bool is_sticker_selected() {
    var current = _selected.current_sticker();
    return( (current != null) && (current.mode == StickerMode.SELECTED) );
  }

  //-------------------------------------------------------------
  // Returns true if we are in group selected mode.
  public bool is_group_selected() {
    var current = _selected.current_group();
    return( (current != null) && (current.mode == GroupMode.SELECTED) );
  }

  //-------------------------------------------------------------
  // Returns the next node to select after the current node is
  // removed.
  public Node? next_node_to_select() {
    var current = _selected.current_node();
    if( current != null ) {
      if( current.is_root() ) {
        if( _nodes.length > 1 ) {
          for( int i=0; i<_nodes.length; i++ ) {
            if( _nodes.index( i ) == current ) {
              if( i == 0 ) {
                return( _nodes.index( 1 ) );
              } else if( (i + 1) == _nodes.length ) {
                return( _nodes.index( i - 1 ) );
              }
              break;
            }
          }
        }
      } else {
        Node? next = current.parent.next_child( current );
        if( next == null ) {
          next = current.parent.prev_child( current );
          if( next == null ) {
            next = current.parent;
          }
        }
        return( next );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // If the specified node is not null, selects the node and
  // makes it the current node.
  public bool select_node( Node? n, bool animate = true ) {
    if( n != null ) {
      if( n != _selected.current_node() ) {
        var folded = n.folded_ancestor();
        if( folded != null ) {
          folded.set_fold_only( false );
        }
        _selected.set_current_node( n, (_focus_mode ? _focus_alpha : 1.0) );
        if( n.parent != null ) {
          n.parent.last_selected_child = n;
        }
        if( n.is_summarized() ) {
          n.summary_node().last_selected_node = n;
        }
        see( animate );
      }
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if there is a root that is available for selection.
  public bool root_selectable() {
    var current_node = _selected.current_node();
    var current_conn = _selected.current_connection();
    return( (current_conn == null) && ((current_node == null) ? (_nodes.length > 0) : (current_node.get_root() != current_node)) );
  }

  //-------------------------------------------------------------
  // If there is no current node, selects the first root node;
  // otherwise, selects the current node's root node.
  public void select_root_node() {
    if( _selected.current_connection() != null ) return;
    var current = _selected.current_node();
    if( current == null ) {
      if( _nodes.length > 0 ) {
        if( select_node( _nodes.index( 0 ) ) ) {
          queue_draw();
        }
      }
    } else if( select_node( current.get_root() ) ) {
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Returns true if there is a sibling available for selection.
  public bool sibling_selectable() {
    var current = _selected.current_node();
    return( (current != null) && (current.is_root() ? (_nodes.length > 1) : (current.parent.children().length > 1)) );
  }

  //-------------------------------------------------------------
  // Returns the sibling node in the given direction of the current
  // node.
  public Node? sibling_node( int dir ) {
    var current = _selected.current_node();
    if( current != null ) {
      if( current.is_root() ) {
        for( int i=0; i<_nodes.length; i++ ) {
          if( _nodes.index( i ) == current ) {
            return( (((i + dir) < 0) || ((i + dir) >= _nodes.length)) ? null : _nodes.index( i + dir ) );
          }
        }
      } else if( dir == 1 ) {
        return( current.parent.next_child( current ) );
      } else {
        return( current.parent.prev_child( current ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Selects the next (dir = 1) or previous (dir = -1) sibling.
  public void select_sibling_node( int dir ) {
    var current = _selected.current_node();
    if( current != null ) {
      Array<Node> nodes;
      int         index = 0;
      if( current.is_root() ) {
        nodes = _nodes;
        for( int i=0; i<_nodes.length; i++ ) {
          if( _nodes.index( i ) == current ) {
            index = i;
            break;
          }
        }
      } else {
        nodes = current.parent.children();
        index = current.index();
      }
      if( (index + dir) < 0 ) {
        if( select_node( nodes.index( nodes.length - 1 ) ) ) {
          queue_draw();
        }
      } else {
        if( select_node( nodes.index( (index + dir) % nodes.length ) ) ) {
          queue_draw();
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Returns true if there is a child node of the current node.
  public bool children_selectable() {
    var nodes      = _selected.nodes();
    var selectable = false;
    for( int i=0; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      selectable |= (!node.is_leaf() && !node.folded);
    }
    return( selectable );
  }

  //-------------------------------------------------------------
  // Selects the last selected child node of the current node.
  public void select_child_node() {
    var current = _selected.current_node();
    if( (current != null) && !current.is_leaf() && !current.folded ) {
      if( select_node( current.last_selected_child ?? current.children().index( 0 ) ) ) {
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Selects all of the child nodes.
  public void select_child_nodes() {
    var nodes   = _selected.nodes_copy();
    var changed = _selected.clear_nodes( false );
    for( int i=0; i<nodes.length; i++ ) {
      changed |= _selected.add_child_nodes( nodes.index( i ), false );
    }
    if( changed ) {
      current_changed( this );
    }
    queue_draw();
  }

  //-------------------------------------------------------------
  // Selects all of the nodes in the current node's tree.
  public void select_node_tree() {
    var current = _selected.current_node();
    _selected.add_node_tree( current );
    queue_draw();
  }

  //-------------------------------------------------------------
  // Returns true if there is a parent node of the current node.
  public bool parent_selectable() {
    var nodes      = _selected.nodes();
    var selectable = false;
    for( int i=0; i<nodes.length; i++ ) {
      selectable |= !nodes.index( i ).is_root();
    }
    return( selectable );
  }

  //-------------------------------------------------------------
  // Selects the parent nodes of the selected nodes.
  public void select_parent_nodes() {
    var child_nodes  = _selected.nodes();
    var parent_nodes = new Array<Node>();
    for( int i=0; i<child_nodes.length; i++ ) {
      var node = child_nodes.index( i );
      if( (node != null) && !node.is_root() ) {
        if( node.is_summary() ) {
          parent_nodes.append_val( (node as SummaryNode).last_selected_node );
        } else {
          parent_nodes.append_val( node.parent );
        }
      }
    }
    if( parent_nodes.length > 0 ) {
      _selected.clear_nodes();
      for( int i=0; i<parent_nodes.length; i++ ) {
        _selected.add_node( parent_nodes.index( i ) );
      }
      see();
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Selects the node that is linked to this node.
  public void select_linked_node( Node? node = null ) {
    var n = node;
    if( n == null ) {
      n = _selected.current_node();
    }
    if( (n != null) && (n.linked_node != null) ) {
      n.linked_node.select( _da );
    }
  }

  //-------------------------------------------------------------
  // Selects the given connection node.
  public void select_connection_node( bool start ) {
    var current = _selected.current_connection();
    if( current != null ) {
      if( select_node( start ? current.from_node : current.to_node ) ) {
        _da.clear_current_connection( true );
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Selects the next connection in the list.
  public void select_connection( int dir ) {
    var current = _selected.current_connection();
    if( current == null ) return;
    var conn = _connections.get_connection( current, dir );
    if( conn != null ) {
      set_current_connection( conn );
      see();
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Selects the first connection in the list.
  public void select_attached_connection() {
    var current = _selected.current_node();
    if( current == null ) return;
    if( current.last_selected_connection != null ) {
      set_current_connection( current.last_selected_connection );
      see();
      queue_draw();
    } else {
      var conn = _connections.get_attached_connection( current );
      if( conn != null ) {
        set_current_connection( conn );
        see();
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Selects the callout associated with the current node (if one
  // exists).
  public void select_callout() {
    if( is_node_selected() && (_selected.current_node().callout != null) ) {
      _selected.set_current_callout( _selected.current_node().callout );
    }
  }

  //-------------------------------------------------------------
  // Selects the node associated with the current callout.
  public void select_callout_node() {
    if( is_callout_selected() ) {
      _selected.set_current_node( _selected.current_callout().node );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the selected nodes can have their sequence attribute
  // toggled.
  public bool sequences_togglable() {
    for( int i=0; i<_selected.nodes().length; i++ ) {
      var node = _selected.nodes().index( i );
      if( !node.is_root() ) {
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Toggles the current node's sequence indicator.
  public void toggle_sequence() {
    var changed = new Array<Node>();
    for( int i=0; i<_selected.nodes().length; i++ ) {
      var node = _selected.nodes().index( i );
      if( !node.is_root() ) {
        node.sequence = !node.sequence;
        changed.append_val( node );
      }
    }
    if( changed.length > 0 ) {
      undo_buffer.add_item( new UndoNodeSequences( changed ) );
      current_changed( this );
      auto_save();
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Deletes the given node.
  public void delete_node() {
    var current = _selected.current_node();
    if( current == null ) return;
    Node? next_node = next_node_to_select();
    var   conns     = new Array<Connection>();
    UndoNodeGroups? undo_groups = null;
    _connections.node_deleted( current, conns );
    _groups.remove_node( current, ref undo_groups );
    if( current.is_root() ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) == current ) {
          undo_buffer.add_item( new UndoNodeDelete( current, i, conns, undo_groups ) );
          _nodes.remove_index( i );
          break;
        }
      }
    } else if( current.is_summary() ) {
      undo_buffer.add_item( new UndoNodeSummaryDelete( (SummaryNode)current, conns, undo_groups ) );
      current.delete();
    } else {
      undo_buffer.add_item( new UndoNodeDelete( current, current.index(), conns, undo_groups ) );
      current.delete();
    }
    _selected.remove_node( current );
    select_node( next_node );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Deletes all selected nodes.
  public void delete_nodes() {
    if( _selected.num_nodes() == 0 ) return;
    var nodes = _selected.ordered_nodes();
    var conns = new Array<Connection>();
    Array<UndoNodeGroups?> undo_groups = null;
    for( int i=0; i<nodes.length; i++ ) {
      _connections.node_only_deleted( nodes.index( i ), conns );
    }
    _groups.remove_nodes( nodes, out undo_groups );
    undo_buffer.add_item( new UndoNodesDelete( nodes, conns, undo_groups ) );
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).delete_only();
    }
    _selected.clear_nodes();
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Deletes the currently selected sticker.
  public void remove_sticker() {
    var current = _selected.current_sticker();
    if( current == null ) return;
    undo_buffer.add_item( new UndoStickerRemove( current ) );
    _stickers.remove_sticker( current );
    _selected.remove_sticker( current );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Positions the given node that will added as a root prior to
  // adding it.
  public void position_root_node( Node node ) {
    if( _nodes.length == 0 ) {
      node.posx = (_da.get_allocated_width()  / 2) - 30;
      node.posy = (_da.get_allocated_height() / 2) - 10;
    } else {
      _nodes.index( _nodes.length - 1 ).layout.position_root( _nodes.index( _nodes.length - 1 ), node );
    }
  }

  //-------------------------------------------------------------
  // Creates a root node with the given name, positions it and
  // appends it to the root node list.
  public Node create_root_node( string name = "" ) {
    var node = new Node.with_name( this, name, ((_nodes.length == 0) ? layouts.get_default() : _nodes.index( 0 ).layout) );
    node.style = StyleInspector.styles.get_global_style();
    position_root_node( node );
    _nodes.append_val( node );
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a sibling node, positions it and appends immediately
  // after the given sibling node.
  public Node create_main_node( Node root, NodeSide side, string name = "" ) {
    var node   = new Node.with_name( this, name, layouts.get_default() );
    node.side  = side;
    node.style = root.style;
    // node.style = StyleInspector.styles.get_style_for_level( 1, null );
    if( root.layout.balanceable && ((side == NodeSide.LEFT) || (side == NodeSide.TOP)) ) {
      node.attach( root, root.side_count( side ), _theme, false );
    } else {
      node.attach( root, -1, _theme, false );
    }
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a sibling node, positions it and appends immediately
  // after the given sibling node.
  public Node create_sibling_node( Node sibling, bool below, string name = "" ) {
    var node   = new Node.with_name( this, name, layouts.get_default() );
    node.side  = sibling.side;
    node.style = sibling.style;
    node.attach( sibling.parent, (sibling.index() + (below ? 1 : 0)), _theme );
    node.parent.set_fold( false, true );
    if( sibling.is_summarized() ) {
      sibling.summary_node().add_node( node );
    }
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a parent node, positions it, and inserts it just
  // above the child node.
  public Node create_parent_node( Node child, string name = "" ) {
    var node  = new Node.with_name( this, name, layouts.get_default() );
    var color = child.link_color;
    node.side  = child.side;
    node.style = child.style;
    // node.style = StyleInspector.styles.get_style_for_level( child.get_level(), child.style );
    node.attach( child.parent, child.index(), null );
    node.link_color = color;
    child.detach( node.side );
    child.attach( node, -1, null );
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a child node, positions it, and inserts it into the
  // parent node.
  public Node create_child_node( Node parent, string name = "" ) {
    var node = new Node.with_name( this, name, layouts.get_default() );
    if( !parent.is_root() ) {
      node.side = parent.side;
    }
    if( parent.children().length > 0 ) {
      node.style = parent.last_child().style;
    } else {
      node.style = parent.style;
    }
    // node.style = StyleInspector.styles.get_style_for_level( (parent.get_level() + 1), parent.style );
    node.attach( parent, -1, _theme );
    parent.set_fold( false, true );
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a summary node for the nodes in the range of first
  // to last, inclusive.
  public Node create_summary_node( Array<Node> nodes ) {
    var summary = new SummaryNode( this, layouts.get_default() );
    summary.side = nodes.index( 0 ).side;
    summary.attach_nodes( nodes.index( 0 ).parent, nodes, true, _theme );
    return( summary );
  }

  //-------------------------------------------------------------
  // Creates a summary node from the given node.
  public Node create_summary_node_from_node( Node node ) {
    var prev_node = node.previous_sibling();
    node.detach( node.side );
    var summary = new SummaryNode.from_node( this, node, image_manager );
    summary.side = node.side;
    summary.attach_siblings( prev_node, _theme );
    return( summary );
  }

  //-------------------------------------------------------------
  // Adds a new root node to the canvas.
  public void add_root_node() {
    var node         = create_root_node( _( "Another Idea" ) );
    var int_node_len = (int)(_nodes.length - 1);
    undo_buffer.add_item( new UndoNodeInsert( node, int_node_len ) );
    if( select_node( node ) ) {
      set_node_mode( node, NodeMode.EDITABLE, false );
      queue_draw();
    }
    see();
    auto_save();
  }

  //-------------------------------------------------------------
  // Adds a connected node to the currently selected node.
  public void add_connected_node() {
    var index = (int)_nodes.length;
    var node  = create_root_node( _( "Another Idea" ) );
    var conn  = new Connection( this, _selected.current_node() );
    conn.connect_to( _selected.current_node() );
    conn.connect_to( node );
    _connections.add_connection( conn );
    undo_buffer.add_item( new UndoConnectedNode( node, index, conn ) );
    if( select_node( node ) ) {
      set_node_mode( node, NodeMode.EDITABLE, false );
      queue_draw();
    }
    see();
    auto_save();
  }

  //-------------------------------------------------------------
  // Adds a new sibling node to the current node.
  public void add_sibling_node( bool shift ) {
    var current = _selected.current_node();
    if( current.is_summary() ) return;
    var node = create_sibling_node( current, !shift );
    undo_buffer.add_item( new UndoNodeInsert( node, node.index() ) );
    set_current_node( node );
    set_node_mode( node, NodeMode.EDITABLE, false );
    queue_draw();
    see();
    auto_save();
  }

  //-------------------------------------------------------------
  // Re-parents a node by creating a new node whose parent
  // matches the current node's parent and then makes the current
  // node's parent match the new node.
  public void add_parent_node() {
    var current = _selected.current_node();
    if( current.is_root() || current.is_summarized() ) return;
    var node  = create_parent_node( current );
    undo_buffer.add_item( new UndoNodeAddParent( node, current ) );
    set_current_node( node );
    set_node_mode( node, NodeMode.EDITABLE, false );
    queue_draw();
    see();
    auto_save();
  }

  //-------------------------------------------------------------
  // Adds a child node to the current node.
  public void add_child_node() {
    var current = _selected.current_node();
    if( current.is_summarized() ) return;
    var node    = create_child_node( current );
    undo_buffer.add_item( new UndoNodeInsert( node, node.index() ) );
    set_current_node( node );
    set_node_mode( node, NodeMode.EDITABLE, false );
    queue_draw();
    see();
    auto_save();
  }

  //-------------------------------------------------------------
  // Returns true if all of the selected nodes are consecutive
  // siblings that are not already summarized and are leaf nodes
  // on the same side.
  public bool nodes_summarizable() {
    var nodes = _selected.ordered_nodes();
    if( nodes.length < 2 ) return( false );
    var first = nodes.index( 0 );
    if( first.is_leaf() && !first.is_summarized() ) {
      for( int i=1; i<nodes.length; i++ ) {
        var prev = nodes.index( i - 1 );
        var node = nodes.index( i );
        if( (prev.parent != node.parent) || (prev.side != node.side) || ((prev.index() + 1) != node.index()) || !node.is_leaf() || node.is_summarized() ) return( false );
      }
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Returns true if the currently selected node has at least one
  // sibling that is before this node which is not already
  // summarized and is on the same side.
  public bool node_summarizable() {
    var current = _selected.current_node();
    if( (current != null) && !current.is_summary() && !current.is_summarized() ) {
      var sibling = current.previous_sibling();
      return( (sibling != null) && !sibling.is_summarized() && sibling.is_leaf() && (current.side == sibling.side) );
    }
    return( false );
  }

  /* Adds a summary node to the first and last nodes in the selected range */
  public void add_summary_node_from_selected() {
    if( !nodes_summarizable() ) return;
    var nodes = _selected.nodes();
    var node  = create_summary_node( nodes );
    undo_buffer.add_item( new UndoNodeSummary( (SummaryNode)node ) );
    set_current_node( node );
    set_node_mode( node, NodeMode.EDITABLE, false );
    queue_draw();
    see();
    auto_save();
  }

  //-------------------------------------------------------------
  // Adds a summary node to the first and last nodes in the
  // selected range.
  public void add_summary_node_from_current() {
    if( !node_summarizable() ) return;
    var current = _selected.current_node();
    var node = create_summary_node_from_node( current );
    undo_buffer.add_item( new UndoNodeSummaryFromNode( current, (SummaryNode)node ) );
    set_current_node( node );
    set_node_mode( node, NodeMode.CURRENT, false );
    queue_draw();
    see();
    auto_save();
  }

  //-------------------------------------------------------------
  // Replaces the original node with the new node.  The new_node
  // must not have any children.  Returns true if the replacement
  // was successful; otherwise, returns false.
  public void replace_node( Node orig_node, Node new_node ) {

    var parent = orig_node.parent;
    var index  = (parent == null) ? root_index( orig_node ) : orig_node.index();

    /* Perform the replacement */
    if( parent == null ) {
      remove_root_node( orig_node );
      add_root( new_node, index );
      new_node.posx = orig_node.posx;
      new_node.posy = orig_node.posy;
    } else {
      orig_node.detach( orig_node.side );
      new_node.attach( parent, index, null );
    }

    /* Copy over a few attributes */
    if( new_node.main_branch() ) {
      new_node.link_color = orig_node.link_color;
    }

  }

  //-------------------------------------------------------------
  // Returns the index of the given root node.
  public int root_index( Node root ) {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ) == root ) {
        return( i );
      }
    }
    return( -1 );
  }

  //-------------------------------------------------------------
  // Adds the given node to the list of root nodes.
  public void add_root( Node n, int index ) {
    if( index == -1 ) {
      _nodes.append_val( n );
    } else {
      _nodes.insert_val( index, n );
    }
  }

  //-------------------------------------------------------------
  // Removes the node at the given root index from the list of
  // root nodes.
  public void remove_root( int index ) {
    _nodes.remove_index( index );
  }

  //-------------------------------------------------------------
  // Removes the given root node from the node array.
  public void remove_root_node( Node node ) {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ) == node ) {
        _nodes.remove_index( i );
      }
    }
  }

  //-------------------------------------------------------------
  // Returns true if the drawing area has a node that is
  // available for detaching.
  public bool detachable() {
    var current = _selected.current_node();
    return( (current != null) && (current.parent != null) );
  }

  //-------------------------------------------------------------
  // Detaches the current node from its parent and adds it as a
  // root node.
  public void detach() {
    if( !detachable() ) return;
    var current    = _selected.current_node();
    var parent     = current.parent;
    var index      = current.index();
    var side       = current.side;
    var root_index = (int)_nodes.length;
    current.detach( side );
    add_root( current, -1 );
    undo_buffer.add_item( new UndoNodeDetach( current, root_index, parent, side, index ) );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Balances the existing nodes based on the current layout.
  public void balance_nodes( bool undoable, bool animate ) {
    var current   = _selected.current_node();
    var root_node = (current == null) ? null : current.get_root();
    if( undoable ) {
      undo_buffer.add_item( new UndoNodeBalance( this, root_node ) );
    }
    if( (current == null) || !undoable ) {
      if( animate ) {
        _da.animator.add_nodes( _nodes, "balance nodes" );
      }
      for( int i=0; i<_nodes.length; i++ ) {
        var partitioner = new Partitioner();
        partitioner.partition_node( _nodes.index( i ) );
      }
    } else {
      if( animate ) {
        _da.animator.add_node( root_node, "balance tree" );
      }
      var partitioner = new Partitioner();
      partitioner.partition_node( root_node );
    }
    if( animate ) {
      _da.animator.animate();
    }
  }

  //-------------------------------------------------------------
  // Returns true if there is at least one node that can be
  // folded due to completed tasks.
  public bool completed_tasks_foldable() {
    var current = _selected.current_node();
    if( current != null ) {
      return( current.get_root().completed_tasks_foldable() );
    } else {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ).completed_tasks_foldable() ) {
          return( true );
        }
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Folds all completed tasks found in any tree.
  public void fold_completed_tasks() {
    var changes = new Array<Node>();
    var current = _selected.current_node();
    if( current == null ) {
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).fold_completed_tasks( changes );
      }
    } else {
      current.get_root().fold_completed_tasks( changes );
    }
    if( changes.length > 0 ) {
      undo_buffer.add_item( new UndoNodeFolds( changes ) );
      queue_draw();
      auto_save();
      current_changed( this );
    }
  }

  //-------------------------------------------------------------
  // Returns true if there is at least one node that is unfoldable.
  public bool unfoldable() {
    var current = _selected.current_node();
    if( current != null ) {
      return( current.get_root().unfoldable() );
    } else {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ).unfoldable() ) {
          return( true );
        }
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Unfolds all nodes in the document.
  public void unfold_all_nodes() {
    var changes = new Array<Node>();
    var current = _selected.current_node();
    if( current != null ) {
      current.get_root().set_fold( false, true, changes );
    } else {
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).set_fold( false, true, changes );
      }
    }
    if( changes.length > 0 ) {
      undo_buffer.add_item( new UndoNodeFolds( changes ) );
      queue_draw();
      auto_save();
      current_changed( this );
    }
  }

  //-------------------------------------------------------------
  // Returns the parent node of the given node that should be
  // selected.
  public Node? get_select_parent( Node node ) {
    if( node.is_summary() ) {
      var summary = (SummaryNode)node;
      return( summary.last_selected_node ?? summary.first_node() );
    }
    return( node.parent );
  }

  //-------------------------------------------------------------
  // Returns the node to the right of the given node.
  public Node? get_node_right( Node node ) {
    if( node.is_root() ) {
      if( node.side.horizontal() ) {
        if( (node.last_selected_child != null) && (node.last_selected_child.side == NodeSide.RIGHT) ) {
          return( node.last_selected_child );
        }
        return( node.first_child( NodeSide.RIGHT ) );
      } else {
        for( int i=0; i<_nodes.length; i++ ) {
          if( _nodes.index( i ) == node ) {
            return( ((i + 1) < _nodes.length) ? _nodes.index( i + 1 ) : null );
          }
        }
      }
      return( null );
    } else {
      switch( node.side ) {
        case NodeSide.TOP    :
        case NodeSide.BOTTOM :  return( node.is_summary() ? null : node.parent.next_child( node ) );
        case NodeSide.LEFT   :  return( get_select_parent( node ) );
        default              :  return( node.last_selected_child ?? node.first_child( NodeSide.RIGHT ) );
      }
    }
  }

  /* Returns the node to the left of the given node */
  public Node? get_node_left( Node node ) {
    if( node.is_root() ) {
      if( node.side.horizontal() ) {
        if( (node.last_selected_child != null) && (node.last_selected_child.side == NodeSide.LEFT) ) {
          return( node.last_selected_child );
        }
        return( node.first_child( NodeSide.LEFT ) );
      } else {
        for( int i=0; i<_nodes.length; i++ ) {
          if( _nodes.index( i ) == node ) {
            return( (i > 0) ? _nodes.index( i - 1 ) : null );
          }
        }
      }
      return( null );
    } else {
      switch( node.side ) {
        case NodeSide.TOP :
        case NodeSide.BOTTOM :  return( node.is_summary() ? null : node.parent.prev_child( node ) );
        case NodeSide.LEFT   :  return( node.last_selected_child ?? node.first_child( NodeSide.LEFT ) );
        default              :  return( get_select_parent( node ) );
      }
    }
  }

  /* Returns the node above the given node */
  public Node? get_node_up( Node node ) {
    if( node.is_root() ) {
      if( node.side.vertical() ) {
        if( (node.last_selected_child != null) && (node.last_selected_child.side == NodeSide.TOP) ) {
          return( node.last_selected_child );
        }
        return( node.first_child( NodeSide.TOP ) );
      } else {
        for( int i=0; i<_nodes.length; i++ ) {
          if( _nodes.index( i ) == node ) {
            return( (i > 0) ? _nodes.index( i - 1 ) : null );
          }
        }
      }
      return( null );
    } else {
      switch( node.side ) {
        case NodeSide.TOP    :  return( node.last_selected_child ?? node.first_child( NodeSide.TOP ) );
        case NodeSide.BOTTOM :  return( get_select_parent( node ) );
        default              :  return( node.is_summary() ? null : node.parent.prev_child( node ) );
      }
    }
  }

  /* Returns the node below the given node */
  public Node? get_node_down( Node node ) {
    if( node.is_root() ) {
      if( node.side.vertical() ) {
        if( (node.last_selected_child != null) && (node.last_selected_child.side == NodeSide.BOTTOM) ) {
          return( node.last_selected_child );
        }
        return( node.first_child( NodeSide.BOTTOM ) );
      } else {
        for( int i=0; i<_nodes.length; i++ ) {
          if( _nodes.index( i ) == node ) {
            return( ((i + 1) < _nodes.length) ? _nodes.index( i + 1 ) : null );
          }
        }
      }
      return( null );
    } else {
      switch( node.side ) {
        case NodeSide.TOP    :  return( get_select_parent( node ) );
        case NodeSide.BOTTOM :  return( node.last_selected_child ?? node.first_child( NodeSide.BOTTOM ) );
        default              :  return( node.is_summary() ? null : node.parent.next_child( node ) );
      }
    }
  }

  /* Returns the node at the top of the sibling list */
  public Node? get_node_pageup( Node node ) {
    if( node.is_root() ) {
      return( (_nodes.length > 0) ? _nodes.index( 0 ) : null );
    } else {
      return( node.is_summary() ? null : node.parent.first_child() );
    }
  }

  /* Returns the node at the top of the sibling list */
  public Node? get_node_pagedn( Node node ) {
    if( node.is_root() ) {
      return( (_nodes.length > 0) ? _nodes.index( _nodes.length - 1 ) : null );
    } else {
      return( node.is_summary() ? null : node.parent.last_child() );
    }
  }

  //-------------------------------------------------------------
  // Selects all of the text in the current node.
  public void select_all() {
    if( is_connection_editable() ) {
      _selected.current_connection().title.set_cursor_all( false );
      queue_draw();
    } else if( is_node_editable() ) {
      _selected.current_node().name.set_cursor_all( false );
      queue_draw();
    } else if( is_callout_editable() ) {
      _selected.current_callout().text.set_cursor_all( false );
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Deselects all of the text in the current node.
  public void deselect_all() {
    if( is_connection_editable() ) {
      _selected.current_connection().title.clear_selection();
      queue_draw();
    } else if( is_node_editable() ) {
      _selected.current_node().name.clear_selection();
      queue_draw();
    } else if( is_callout_editable() ) {
      _selected.current_callout().text.clear_selection();
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Returns true if we can perform a node copy operation.
  public bool node_copyable() {
    return( _selected.current_node() != null );
  }

  /* Returns true if we can perform a node cut operation */
  public bool node_cuttable() {
    return( _selected.current_node() != null );
  }

  /* Returns true if we can perform a node paste operation */
  public bool node_pasteable() {
    return( MinderClipboard.node_pasteable() );
  }

  /* Returns true if the currently selected nodes are alignable */
  public bool nodes_alignable() {
    var nodes = _selected.nodes();
    if( nodes.length < 2 ) return( false );
    for( int i=0; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      if( !node.is_root() && (node.layout.name != _( "Manual" )) ) {
        return( false );
      }
    }
    return( true );
  }

  /* Serializes the current node tree */
  public string serialize_for_copy( Array<Node> nodes, Connections conns, NodeGroups groups ) {
    string    str;
    var       nodelinks = new NodeLinks();
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "minder" );
    doc->set_root_element( root );
    Xml.Node* ns = new Xml.Node( null, "nodes" );
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).save( ns );
      nodelinks.get_links_from_node( nodes.index( i ), _node_links );
    }
    root->add_child( ns );
    Xml.Node* cs = new Xml.Node( null, "connections" );
    Xml.Node* gs = new Xml.Node( null, "groups" );
    for( int i=0; i<nodes.length; i++ ) {
      conns.save_if_in_node( cs, nodes.index( i ), nodelinks, _node_links );
      groups.save_if_in_node( gs, nodes.index( i ) );
    }
    root->add_child( cs );
    root->add_child( gs );
    if( nodes.length > 0 ) {
      var link = new NodeLink( nodes.index( 0 ) );
      root->add_child( link.save() );
    }
    if( nodelinks.num_links() > 0 ) {
      root->add_child( nodelinks.save() );
    }
    doc->dump_memory_format( out str );
    delete doc;
    return( str );
  }

  /* Deserializes the paste string and returns the list of nodes */
  public void deserialize_for_paste( string str, Array<Node> nodes, Array<Connection> conns, Array<NodeGroup> groups ) {
    Xml.Doc* doc = Xml.Parser.parse_doc( str );
    if( doc == null ) return;
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          // case "images"      :  image_manager.load( it );  break;
          case "connections" :
            _connections.load( this, it, conns, nodes );
            break;
          case "groups" :
            _groups.load( this, it, groups, nodes );
            break;
          case "nodes"       :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                var siblings = new Array<Node>();
                var node = new Node.from_xml( this, null, it2, true, null, ref siblings );
                nodes.append_val( node );
              }
            }
            break;
          case "nodelinks" :
            var nodelinks = new NodeLinks();
            nodelinks.load( it );
            for( int i=0; i<nodes.length; i++ ) {
              nodelinks.set_links_in_node( nodes.index( i ), _node_links );
              _connections.set_links_in_notes( nodes.index( i ), nodelinks, _node_links );
            }
            break;
        }
      }
    }
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).reassign_ids();
    }
    delete doc;
  }

  /* Deserialize the node tree, returning the first node as a node link */
  public static NodeLink? deserialize_for_node_link( string str ) {
    Xml.Doc* doc = Xml.Parser.parse_doc( str );
    if( doc == null ) return( null );
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "nodelink") ) {
        var link = new NodeLink.from_xml( it );
        delete doc;
        return( link );
      }
    }
    delete doc;
    return( null );
  }

  //-------------------------------------------------------------
  // Copies the current node to the node clipboard.
  public void get_nodes_for_clipboard( out Array<Node> nodes, out Connections conns, out NodeGroups groups ) {
    nodes  = new Array<Node>();
    conns  = _connections;
    groups = _groups;
    _selected.get_parents( ref nodes );
  }

  //-------------------------------------------------------------
  // Copies the currently selected text to the clipboard.
  public void copy_selected_text() {
    string? value           = null;
    var     current_node    = _selected.current_node();
    var     current_conn    = _selected.current_connection();
    var     current_callout = _selected.current_callout();
    if( current_node != null ) {
      value = current_node.name.get_selected_text();
    } else if( current_conn != null ) {
      value = current_conn.title.get_selected_text();
    } else if( current_callout != null ) {
      value = current_callout.text.get_selected_text();
    }
    if( value != null ) {
      MinderClipboard.copy_text( value );
    }
  }

  /* Copies either the current node or the currently selected text to the clipboard */
  public void do_copy() {
    var current = _selected.current_node();
    if( current != null ) {
      switch( current.mode ) {
        case NodeMode.CURRENT  :  MinderClipboard.copy_nodes( this );  break;
        case NodeMode.EDITABLE :  copy_selected_text();  break;
      }
    } else if( _selected.nodes().length > 1 ) {
      MinderClipboard.copy_nodes( this );
    } else if( is_connection_editable() || is_callout_editable() ) {
      copy_selected_text();
    }
  }

  /* Cuts the current node from the tree and stores it in the clipboard */
  public void cut_node_to_clipboard() {
    var current = _selected.current_node();
    if( current == null ) return;
    var next_node = next_node_to_select();
    var conns     = new Array<Connection>();
    UndoNodeGroups? undo_groups = null;
    _connections.node_deleted( current, conns );
    _groups.remove_node( current, ref undo_groups );
    MinderClipboard.copy_nodes( this );
    if( current.is_root() ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) == current ) {
          undo_buffer.add_item( new UndoNodeCut( current, i, conns, undo_groups ) );
          _nodes.remove_index( i );
          break;
        }
      }
    } else {
      undo_buffer.add_item( new UndoNodeCut( current, current.index(), conns, undo_groups ) );
      current.delete();
    }
    _selected.remove_node( current );
    select_node( next_node );
    queue_draw();
    auto_save();
  }

  public void cut_selected_nodes_to_clipboard() {
    if( _selected.num_nodes() == 0 ) return;
    var nodes = _selected.ordered_nodes();
    var conns = new Array<Connection>();
    Array<UndoNodeGroups?> undo_groups = null;
    for( int i=0; i<nodes.length; i++ ) {
      _connections.node_only_deleted( nodes.index( i ), conns );
    }
    _groups.remove_nodes( nodes, out undo_groups );
    MinderClipboard.copy_nodes( this );
    undo_buffer.add_item( new UndoNodesCut( nodes, conns, undo_groups ) );
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).delete_only();
    }
    _selected.clear_nodes();
    queue_draw();
    auto_save();
  }

  /* Cuts the current selected text to the clipboard */
  public void cut_selected_text() {
    copy_selected_text();
    var current_node    = _selected.current_node();
    var current_conn    = _selected.current_connection();
    var current_callout = _selected.current_callout();
    if( current_node != null ) {
      current_node.name.insert( "", undo_text );
    } else if( current_conn != null ) {
      current_conn.title.insert( "", undo_text );
    } else if( current_callout != null ) {
      current_callout.text.insert( "", undo_text );
    }
    queue_draw();
    auto_save();
  }

  /* Either cuts the current node or cuts the currently selected text */
  public void do_cut() {
    var current = _selected.current_node();
    if( current != null ) {
      switch( current.mode ) {
        case NodeMode.CURRENT  :  cut_node_to_clipboard();  break;
        case NodeMode.EDITABLE :  cut_selected_text();      break;
      }
    } else if( _selected.nodes().length > 1 ) {
      cut_selected_nodes_to_clipboard();
    } else if( is_connection_editable() || is_callout_editable() ) {
      cut_selected_text();
    }
  }

  //-------------------------------------------------------------
  // Replaces the node's text with the given string.
  private void replace_node_text( Node node, string text ) {
    var orig_text = new CanvasText( this );
    orig_text.copy( node.name );
    node.name.text.replace_text( 0, node.name.text.text.char_count(), text.strip() );
    undo_buffer.add_item( new UndoNodeName( this, node, orig_text ) );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Replaces the connection's text with the given string.
  private void replace_connection_text( Connection conn, string text ) {
    var orig_title = new CanvasText( this );
    orig_title.copy( conn.title );
    conn.title.text.replace_text( 0, conn.title.text.text.char_count(), text.strip() );
    undo_buffer.add_item( new UndoConnectionTitle( this, conn, orig_title ) );
    queue_draw();
    current_changed( this );
    auto_save();
  }

  //-------------------------------------------------------------
  // Replaces the callout's text with the given string.
  private void replace_callout_text( Callout callout, string text ) {
    var orig_text = new CanvasText( this );
    orig_text.copy( callout.text );
    callout.text.text.replace_text( 0, callout.text.text.text.char_count(), text.strip() );
    undo_buffer.add_item( new UndoCalloutText( this, callout, orig_text ) );
    queue_draw();
    current_changed( this );
    auto_save();
  }

  //-------------------------------------------------------------
  // Replaces the node's image with the given image.
  private void replace_node_image( Node node, Pixbuf image ) {
    var ni = new NodeImage.from_pixbuf( image_manager, image, node.style.node_width );
    if( ni.valid ) {
      var orig_image = node.image;
      node.set_image( image_manager, ni );
      undo_buffer.add_item( new UndoNodeImage( node, orig_image ) );
      queue_draw();
      current_changed( this );
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Replaces the current node with the node tree expressed in XML.
  private void replace_node_xml( Node node, string text ) {
    var nodes  = new Array<Node>();
    var conns  = new Array<Connection>();
    var groups = new Array<NodeGroup>();
    deserialize_for_paste( text, nodes, conns, groups );
    if( nodes.length == 0 ) return;
    replace_node( node, nodes.index( 0 ) );
    for( int i=1; i<nodes.length; i++ ) {
      add_root( nodes.index( i ), -1 );
    }
    undo_buffer.add_item( new UndoNodesReplace( node, nodes ) );
    select_node( nodes.index( 0 ) );
    queue_draw();
    current_changed( this );
    auto_save();
  }

  //-------------------------------------------------------------
  // Inserts the given text string into the given node.
  private void insert_node_text( Node node, string text ) {
    node.name.insert( text, undo_text );
    queue_draw();
  }

  //-------------------------------------------------------------
  // Inserts the given text string into the given connection.
  private void insert_connection_text( Connection conn, string text ) {
    conn.title.insert( text, undo_text );
    queue_draw();
  }

  //-------------------------------------------------------------
  // Inserts the given text string into the given callout.
  private void insert_callout_text( Callout callout, string text ) {
    callout.text.insert( text, undo_text );
    queue_draw();
  }

  //-------------------------------------------------------------
  // Converts the given text string into a node tree and inserts
  // the node tree into the mindmap.
  private void paste_text_as_node( Node? node, string text ) {
    var nodes  = new Array<Node>();
    var export = (ExportText)_da.win.exports.get_by_name( "text" );
    export.import_text( text, 0, this, false, nodes );
    undo_buffer.add_item( new UndoNodesInsert( this, nodes ) );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Creates a node for the given image and inserts the new node
  // into the mindmap.
  private void paste_image_as_node( Node? node, Pixbuf image ) {
    var new_node = (node == null) ? create_root_node() : create_child_node( node );
    var ni = new NodeImage.from_pixbuf( image_manager, image, 200 );
    if( ni.valid ) {
      new_node.set_image( image_manager, ni );
    }
    undo_buffer.add_item( new UndoNodeInsert( new_node, ((node == null) ? (int)(_nodes.length - 1) : new_node.index()) ) );
    select_node( new_node );
    queue_draw();
    current_changed( this );
    auto_save();
  }

  //-------------------------------------------------------------
  // Converts the given text into a list of nodes, connections
  // and/or groups and inserts them into the mindmap.
  private void paste_as_nodes( Node? node, string text ) {
    var nodes  = new Array<Node>();
    var conns  = new Array<Connection>();
    var groups = new Array<NodeGroup>();
    deserialize_for_paste( text, nodes, conns, groups );
    if( nodes.length == 0 ) return;
    if( node == null ) {
      for( int i=0; i<nodes.length; i++ ) {
        position_root_node( nodes.index( i ) );
        add_root( nodes.index( i ), -1 );
      }
    } else if( node.is_root() ) {
      uint num_children = node.children().length;
      if( num_children > 0 ) {
        for( int i=0; i<nodes.length; i++ ) {
          nodes.index( i ).side = node.children().index( num_children - 1 ).side;
          nodes.index( i ).layout.propagate_side( nodes.index( i ), nodes.index( i ).side );
          nodes.index( i ).attach( node, -1, _theme );
        }
      } else {
        for( int i=0; i<nodes.length; i++ ) {
          nodes.index( i ).attach( node, -1, _theme );
        }
      }
    } else {
      for( int i=0; i<nodes.length; i++ ) {
        nodes.index( i ).side = node.side;
        nodes.index( i ).layout.propagate_side( nodes.index( i ), nodes.index( i ).side );
        nodes.index( i ).attach( node, -1, _theme );
      }
    }
    undo_buffer.add_item( new UndoNodePaste( nodes, conns, groups ) );
    select_node( nodes.index( 0 ) );
    queue_draw();
    current_changed( this );
    auto_save();
  }

  //-------------------------------------------------------------
  // Called by the clipboard to paste text.
  public void paste_text( string text, bool shift ) {
    var node    = _selected.current_node();
    var conn    = _selected.current_connection();
    var callout = _selected.current_callout();
    if( shift ) {
      if( (node != null) && (node.mode == NodeMode.CURRENT) ) {
        replace_node_text( node, text );
      } else if( (conn != null) && (conn.mode == ConnMode.SELECTED) ) {
        replace_connection_text( conn, text );
      } else if( (callout != null) && (callout.mode == CalloutMode.SELECTED) ) {
        replace_callout_text( callout, text );
      }
    } else {
      if( (node != null) && (node.mode == NodeMode.EDITABLE) ) {
        insert_node_text( node, text );
      } else if( (conn != null) && (conn.mode == ConnMode.EDITABLE) ) {
        insert_connection_text( conn, text );
      } else if( (callout != null) && (callout.mode == CalloutMode.EDITABLE) ) {
        insert_callout_text( callout, text );
      } else if( conn == null ) {
        paste_text_as_node( node, text );
      }
    }
  }

  //-------------------------------------------------------------
  // Pastes the current node in the clipboard as a node link to
  // the current node.
  public void paste_node_link( string text ) {
    if( is_node_selected() ) {
      var current  = _selected.current_node();
      var old_link = current.linked_node;
      var new_link = deserialize_for_node_link( text );
      if( new_link != null ) {
        current.linked_node = new_link;
        undo_buffer.add_item( new UndoNodeLink( current, old_link ) );
        auto_save();
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Called by the clipboard to paste image.
  public void paste_image( Pixbuf image, bool shift ) {
    var node = _selected.current_node();
    if( shift ) {
      if( (node != null) && (node.mode == NodeMode.CURRENT) ) {
        replace_node_image( node, image );
      }
    } else {
      paste_image_as_node( node, image );
    }
  }

  //-------------------------------------------------------------
  // Called by the clipboard to paste nodes.
  public void paste_nodes( string text, bool shift ) {
    var node = _selected.current_node();
    if( shift ) {
      if( (node != null) && (node.mode == NodeMode.CURRENT) ) {
        replace_node_xml( node, text );
      }
    } else {
      paste_as_nodes( node, text );
    }
  }

  //-------------------------------------------------------------
  // Perform an automatic save for times when changes may be
  // happening rapidly.
  public void auto_save() {
    if( _auto_save_id != null ) {
      Source.remove( _auto_save_id );
    }
    _auto_save_id = Timeout.add( 200, do_auto_save );
  }

  //-------------------------------------------------------------
  // Allows the document to be auto-saved after a scroll event.
  private bool do_auto_save() {
    _auto_save_id = null;
    is_loaded = true;
    changed();
    return( false );
  }

  //-------------------------------------------------------------
  // Sets the image of the current node to the given filename.
  public bool update_current_image( string uri ) {
    var current = _selected.current_node();
    var image   = new NodeImage.from_uri( image_manager, uri, current.style.node_width );
    if( image.valid ) {
      var orig_image = current.image;
      current.set_image( image_manager, image );
      undo_buffer.add_item( new UndoNodeImage( current, orig_image ) );
      queue_draw();
      current_changed( this );
      auto_save();
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Starts a connection from the current node.
  public void start_connection( bool key, bool link ) {
    var current_node = _selected.current_node();
    if( (current_node == null) || _connections.hide ) return;
    var conn = new Connection( this, current_node );
    _selected.set_current_connection( conn );
    conn.mode = link ? ConnMode.LINKING : ConnMode.CONNECTING;
    if( key ) {
      double x, y, w, h;
      current_node.bbox( out x, out y, out w, out h );
      conn.draw_to( (x + (w / 2)), (y + (h / 2)) );
      set_attach_node( current_node );
    } else {
      conn.draw_to( _da.press_x, _da.press_y );
    }
    _last_node = current_node;
    queue_draw();
  }

  //-------------------------------------------------------------
  // Called when the connection is being connected via the
  // keyboard.
  public void update_connection_by_node( Node? node ) {
    if( node == null ) return;
    double x, y, w, h;
    node.bbox( out x, out y, out w, out h );
    _selected.current_connection().draw_to( (x + (w / 2)), (y + (h / 2)) );
    set_attach_node( node );
    queue_draw();
  }

  //-------------------------------------------------------------
  // Ends a connection at the given node.
  public void end_connection( Node n ) {
    var current = _selected.current_connection();
    if( current == null ) return;
    current.connect_to( n );
    _connections.add_connection( current );
    undo_buffer.add_item( new UndoConnectionAdd( current ) );
    _selected.set_current_connection( current );
    handle_connection_edit_on_creation( current );
    _da.last_connection = null;
    _last_node          = null;
    set_attach_node( null );
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // If exactly two nodes are currently selected, draws a
  // connection from the first selected node to the second selected
  // node.
  public void create_connection() {
    if( (_selected.num_nodes() != 2) || _connections.hide ) return;
    double x, y, w, h;
    var    nodes = _selected.nodes();
    var    conn  = new Connection( this, nodes.index( 0 ) );
    conn.connect_to( nodes.index( 1 ) );
    nodes.index( 1 ).bbox( out x, out y, out w, out h );
    conn.draw_to( (x + (w / 2)), (y + (h / 2)) );
    _connections.add_connection( conn );
    _selected.set_current_connection( conn );
    undo_buffer.add_item( new UndoConnectionAdd( conn ) );
    handle_connection_edit_on_creation( conn );
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Deletes the current connection.
  public void delete_connection() {
    var current = _selected.current_connection();
    if( current == null ) return;
    undo_buffer.add_item( new UndoConnectionDelete( current ) );
    _connections.remove_connection( current, false );
    _selected.remove_connection( current );
    _da.last_connection = null;
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Deletes the currently selected connections.
  public void delete_connections() {
    if( _selected.num_connections() == 0 ) return;
    var conns = _selected.connections();
    undo_buffer.add_item( new UndoConnectionsDelete( conns ) );
    for( int i=0; i<conns.length; i++ ) {
      _connections.remove_connection( conns.index( i ), false );
    }
    _selected.clear_connections();
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Handles the edit on creation of a newly created connection.
  public void handle_connection_edit_on_creation( Connection conn ) {
    if( (conn.title == null) && _settings.get_boolean( "edit-connection-title-on-creation" ) ) {
      conn.change_title( this, "", true );
      set_connection_mode( conn, ConnMode.EDITABLE, false );
    }
  }

  //-------------------------------------------------------------
  // Returns the current focus mode state.
  public bool get_focus_mode() {
    return( _focus_mode );
  }

  //-------------------------------------------------------------
  // Called when the focus button active state changes.  Causes
  // all nodes and connections to have the alpha state set to
  // almost transparent (when focus mode is enabled) or fully opaque.
  public void set_focus_mode( bool focus ) {
    double alpha = focus ? _focus_alpha : 1.0;
    _focus_mode = focus;
    update_focus_mode();
  }

  //-------------------------------------------------------------
  // Update the focus mode.
  public void update_focus_mode() {
    var nodes = _selected.nodes();
    var conns = _selected.connections();
    var alpha = (_focus_mode && ((nodes.length > 0) || (conns.length > 0))) ? _focus_alpha : 1.0;
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).alpha = alpha;
    }
    if( _focus_mode ) {
      for( int i=0; i<nodes.length; i++ ) {
        var current = nodes.index( i );
        current.alpha = 1.0;
        var parent = current.parent;
        while( parent != null ) {
          parent.set_alpha_only( 1.0 );
          parent = parent.parent;
        }
      }
      _connections.update_alpha();
      for( int i=0; i<conns.length; i++ ) {
        conns.index( i ).alpha = 1.0;
      }
    }
    queue_draw();
  }

  //-------------------------------------------------------------
  // Updates all alpha values with the given value.
  public void update_focus_mode_alpha( GLib.Settings settings ) {
    var key   = "focus-mode-alpha";
    var alpha = settings.get_double( key );
    if( (alpha < 0) || (alpha >= 1.0) ) {
      settings.set_double( key, _focus_alpha );
    } else if( _focus_alpha != alpha ) {
      _focus_alpha = alpha;
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).update_alpha( alpha );
      }
      _connections.update_alpha();
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Sorts and re-arranges the children of the given parent using
  // the given array.
  private void sort_children( Node parent, CompareFunc<Node> sort_fn ) {
    var children = new SList<Node>();
    undo_buffer.add_item( new UndoNodeSort( parent ) );
    _da.animator.add_nodes( _nodes, "sort nodes" );
    for( int i=0; i<parent.children().length; i++ ) {
      children.append( parent.children().index( i ) );
    }
    children.@foreach( (child) => {
      child.detach( child.side );
    });
    children.sort( sort_fn );
    children.@foreach( (child) => {
      child.attach( parent, -1, null, false );
    });
    _da.animator.animate();
    auto_save();
  }

  //-------------------------------------------------------------
  // Sorts the current node's children alphabetically.
  public void sort_alphabetically() {
    CompareFunc<Node> sort_fn = (a, b) => {
      return( strcmp( a.name.text.text, b.name.text.text ) );
    };
    sort_children( _selected.current_node(), sort_fn );
  }

  //-------------------------------------------------------------
  // Sorts the current node's children in a random manner.
  public void sort_randomly() {
    CompareFunc<Node> sort_fn = (a, b) => {
      return( (Random.int_range( 0, 2 ) == 0) ? -1 : 1 );
    };
    sort_children( _selected.current_node(), sort_fn );
  }

  //-------------------------------------------------------------
  // Moves all trees to avoid overlapping.
  public void handle_tree_overlap( NodeBounds prev ) {
    var current = _selected.current_node();
    var visited = new GLib.List<Node>();
    if( current == null ) return;
    handle_tree_overlap_helper( current.get_root(), prev, visited );
  }

  //-------------------------------------------------------------
  // Helper method for handle_tree_overlap.
  public void handle_tree_overlap_helper( Node root, NodeBounds prev, GLib.List<Node> visited ) {

    var curr  = root.tree_bbox;
    var ldiff = curr.x - prev.x;
    var rdiff = (curr.x + curr.width) - (prev.x + prev.width);
    var adiff = curr.y - prev.y;
    var bdiff = (curr.y + curr.height) - (prev.y + prev.height);

    visited.append( root );

    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      if( (visited.find( node ).length() == 0) && curr.overlaps( node.tree_bbox ) ) {
        var node_prev = new NodeBounds.copy( node.tree_bbox );
        if( node.is_left_of( prev ) )  node.posx += ldiff;
        if( node.is_right_of( prev ) ) node.posx += rdiff;
        if( node.is_above( prev ) )    node.posy += adiff;
        if( node.is_below( prev ) )    node.posy += bdiff;
        handle_tree_overlap_helper( node, node_prev, visited );
      }
    }

  }

  //-------------------------------------------------------------
  // Returns the droppable node or connection if one is found.
  public void get_droppable( double x, double y, out Node? node, out Connection? conn, out Sticker? sticker ) {
    node = null;
    conn = null;
    for( int i=0; i<_nodes.length; i++ ) {
      Node tmp = _nodes.index( i ).contains( x, y, null );
      if( tmp != null ) {
        node = tmp;
        return;
      }
    }
    conn = _connections.within_title_box( x, y );
    if( conn == null ) {
      conn = _connections.on_curve( x, y );
    }
    sticker = _stickers.is_within( x, y );
  }

}
