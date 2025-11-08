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
  RESIZER,
  TAGS;

  //-------------------------------------------------------------
  // Returns true if this component is a connection handle.
  public bool is_connection_handle() {
    return( (this == DRAG_HANDLE) || (this == FROM_HANDLE) || (this == TO_HANDLE) );
  }
}

public class MapModel {

  private MindMap       _map;
  private Node?         _last_node      = null;
  private Array<Node>   _nodes;
  private Connections   _connections;
  private Stickers      _stickers;
  private Theme         _theme;
  private Node?         _last_match     = null;
  private Node?         _attach_node    = null;
  private SummaryNode?  _attach_summary = null;
  private Connection?   _attach_conn    = null;
  private Sticker?      _attach_sticker = null;
  private uint?         _auto_save_id   = null;
  private bool          _debug          = true;
  private NodeGroups    _groups;
  private int           _next_node_id   = -1;
  private NodeLinks     _node_links;
  private bool          _hide_callouts  = false;
  private Array<string> _braindump;
  private bool          _modifiable     = true;
  private Tags          _tags;

  public Layouts        layouts         { set; get; default = new Layouts(); }
  public ImageManager   image_manager   { set; get; default = new ImageManager(); }
  public bool           is_loaded       { get; private set; default = false; }
  public bool           braindump_shown { get; set; default = false; }

  public MindMap map {
    get {
      return( _map );
    }
  }
  public Connections connections {
    get {
      return( _connections );
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
        if( _map.is_callout_editable() ) {
          set_callout_mode( _map.selected.current_callout(), CalloutMode.NONE );
          _map.selected.clear_callouts( false );
        }
        _map.animator.add_callouts_fade( _nodes, value, "hide callouts" );
        _hide_callouts = value;
        auto_save();
        _map.animator.animate();
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
  public Tags tags {
    get {
      return( _tags );
    }
  }

  public signal void changed();
  public signal void current_changed();
  public signal void theme_changed();
  public signal void loaded();
  public signal void queue_draw();
  public signal void see( bool animate = true, double width_adjust = 0, double pad = 100.0 );

  /* Default constructor */
  public MapModel( MindMap map ) {

    _map = map;

    /* Create the array of root nodes in the map */
    _nodes = new Array<Node>();

    /* Create the connections */
    _connections = new Connections();

    /* Create the stickers */
    _stickers = new Stickers();

    /* Create groups */
    _groups = new NodeGroups();

    /* Allocate the note node links manager */
    _node_links = new NodeLinks();

    // Create the braindump list
    _braindump = new Array<string>();

    // Create that mindmap tags
    _tags = new Tags();

    /* Set the theme to the default theme */
    set_theme( _map.win.themes.get_theme( _map.settings.get_string( "default-theme" ) ), false );

    // Initialize variables
    _attach_node    = null;
    _attach_summary = null;
    _attach_conn    = null;
    _attach_sticker = null;

  }

  //-------------------------------------------------------------
  // Returns the current theme.
  public Theme get_theme() {
    return( _theme );
  }

  //-------------------------------------------------------------
  // Sets the theme to the given value.
  public void set_theme( Theme theme, bool save ) {
    if( _theme == theme ) return;
    Theme? orig_theme = _theme;
    _theme        = theme;
    _theme.index  = (orig_theme != null) ? orig_theme.index : -1;
    _theme.rotate = _map.settings.get_boolean( "rotate-main-link-colors" );
    FormattedText.set_theme( theme );
    update_css();
    if( orig_theme != null ) {
      update_theme_colors( orig_theme );
    }
    theme_changed();
    queue_draw();
    if( save ) {
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Updates the CSS for the current theme.
  public void update_css() {
    StyleContext.add_provider_for_display(
      Display.get_default(),
      get_theme().get_css_provider( _map.win.text_size ),
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );
  }

  //-------------------------------------------------------------
  // Updates all nodes with the new theme colors.
  private void update_theme_colors( Theme old_theme ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).update_theme_colors( old_theme, _theme );
    }
  }

  //-------------------------------------------------------------
  // Sets the layout to the given value.
  public void set_layout( string name, Node? root_node, bool undoable = true ) {
    var old_layout = (root_node == null) ? _nodes.index( 0 ).layout : root_node.layout;
    var new_layout = layouts.get_layout( name );
    if( undoable ) {
      _map.add_undo( new UndoNodeLayout( old_layout, new_layout, root_node ) );
    }
    var old_balanceable = old_layout.balanceable;
    _map.animator.add_nodes( _nodes, false, "set layout" );
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
    _map.animator.animate();
  }

  //-------------------------------------------------------------
  // Updates all of the node sizes.
  public void update_node_sizes() {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).update_tree();
    }
    queue_draw();
  }

  //-------------------------------------------------------------
  // Returns the list of nodes.
  public Array<Node> get_nodes() {
    return( _nodes );
  }

  //-------------------------------------------------------------
  // Searches for and returns the node with the specified ID.
  public Node? get_node( Array<Node> nodes, int id ) {
    for( int i=0; i<nodes.length; i++ ) {
      Node? node = nodes.index( i ).get_node( id );
      if( node != null ) {
        return( node );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Loads the given theme from the list of available options.
  private void load_theme( Xml.Node* n ) {

    /* Load the theme */
    var theme       = new Theme.from_theme( _map.win.themes.get_theme( "default" ) );
    theme.temporary = true;
    theme.rotate    = _map.settings.get_boolean( "rotate-main-link-colors" );

    var valid = theme.load( n );

    /* If this theme does not currently exist, add the theme temporarily */
    if( !_map.win.themes.exists( theme ) ) {
      if( valid ) {
        theme.name = _map.win.themes.uniquify_name( theme.name );
        _map.win.themes.add_theme( theme );
      } else {
        theme.name = "default";
      }
    }

    /* Get the theme */
    _theme = _map.win.themes.get_theme( theme.name );

    /* If we are the current drawarea, update the CSS and indicate the theme change */
    if( _map.win.get_current_map() == _map ) {
      update_css();
      theme_changed();
    }

  }

  //-------------------------------------------------------------
  // We don't store the layout, but if it is found, we need to
  // initialize the layout information for all nodes to this value.
  private void load_layout( Xml.Node* n, ref Layout? layout ) {

    string? name = n->get_prop( "name" );
    if( name != null ) {
      layout = layouts.get_layout( name );
    }

  }

  //-------------------------------------------------------------
  // Loads the global style stored in the mindmap file.
  private void load_global_style( Xml.Node* n ) {
    _map.global_style.load_node( n );
    _map.global_style.load_connection( n );
    _map.global_style.load_callout( n );
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
    var animate = _map.animator.enable;
    _map.animator.enable = false;

    /* Clear the existing nodes */
    _nodes.remove_range( 0, _nodes.length );

    /* Load the contents of the file */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "theme"        :  load_theme( it );   break;
          case "layout"       :  load_layout( it, ref use_layout );  break;
          case "styles"       :  
            StyleInspector.styles.load( it );
            _map.global_style.copy( StyleInspector.styles.get_global_style() );
            break;
          case "global-style" :  load_global_style( it );  break;
          case "tags"         :  _tags.load( it );  break;
          case "images"       :  image_manager.load( it );  break;
          case "connections"  :  _connections.load( _map, it, null, _nodes );  break;
          case "groups"       :  groups.load( _map, it, null, _nodes );  break;
          case "stickers"     :  _stickers.load( _map, it );  break;
          case "nodelinks"    :  _node_links.load( it );  break;
          case "nodes"        :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                var siblings = new Array<Node>();
                var node = new Node.from_xml( _map, null, it2, true, null, ref siblings );
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
    current_changed();

    /* Reset the animator enable */
    _map.animator.enable = animate;

  }

  //-------------------------------------------------------------
  // Saves the contents of the drawing area to the data output
  // stream.
  public bool save( Xml.Node* parent ) {

    parent->add_child( _theme.save() );

    Xml.Node* style = new Xml.Node( null, "global-style" );
    _map.global_style.save_node_in_node( style );
    _map.global_style.save_connection_in_node( style );
    _map.global_style.save_callout_in_node( style );
    parent->add_child( style );

    Xml.Node* images = new Xml.Node( null, "images" );
    image_manager.save( images );
    parent->add_child( images );

    parent->add_child( _tags.save() );

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
  // Needs to be called whenever the user changes the mode of the
  // current node
  public void set_node_mode( Node node, NodeMode mode, bool undoable = true ) {
    if( (node.mode != NodeMode.EDITABLE) && (mode == NodeMode.EDITABLE) ) {
      _map.canvas.update_im_cursor( node.name );
      _map.canvas.im_context.focus_in();
      if( node.name.is_within( _map.canvas.scaled_x, _map.canvas.scaled_y ) ) {
        _map.canvas.set_text_cursor();
      }
      _map.undo_text.orig.copy( node.name );
      _map.undo_text.ct      = node.name;
      _map.undo_text.do_undo = undoable;
      node.mode = mode;
    } else if( (node.mode == NodeMode.EDITABLE) && (mode != NodeMode.EDITABLE) ) {
      _map.canvas.im_context.reset();
      _map.canvas.im_context.focus_out();
      if( node.name.is_within( _map.canvas.scaled_x, _map.canvas.scaled_y ) ) {
        _map.canvas.reset_cursor();
      }
      _map.undo_text.clear();
      if( _map.undo_text.do_undo ) {
        _map.add_undo( new UndoNodeName( _map, node, _map.undo_text.orig ) );
      }
      _map.undo_text.ct      = null;
      _map.undo_text.do_undo = false;
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
      _map.canvas.update_im_cursor( conn.title );
      _map.canvas.im_context.focus_in();
      if( (conn.title != null) && conn.title.is_within( _map.canvas.scaled_x, _map.canvas.scaled_y ) ) {
        _map.canvas.set_text_cursor();
      }
      _map.undo_text.orig.copy( conn.title );
      _map.undo_text.ct      = conn.title;
      _map.undo_text.do_undo = undoable;
    } else if( (conn.mode == ConnMode.EDITABLE) && (mode != ConnMode.EDITABLE) ) {
      _map.canvas.im_context.reset();
      _map.canvas.im_context.focus_out();
      if( (conn.title != null) && conn.title.is_within( _map.canvas.scaled_x, _map.canvas.scaled_y ) ) {
        _map.canvas.reset_cursor();
      }
      _map.undo_text.clear();
      if( _map.undo_text.do_undo ) {
        _map.add_undo( new UndoConnectionTitle( _map, conn, _map.undo_text.orig ) );
      }
      _map.undo_text.ct      = null;
      _map.undo_text.do_undo = false;
    }
    conn.mode = mode;
  }

  //-------------------------------------------------------------
  // Needs to be called whenever the user changes the mode of the
  // current callout.
  public void set_callout_mode( Callout callout, CalloutMode mode, bool undoable = true ) {
    if( (callout.mode != CalloutMode.EDITABLE) && (mode == CalloutMode.EDITABLE) ) {
      _map.canvas.update_im_cursor( callout.text );
      _map.canvas.im_context.focus_in();
      if( (callout.text != null) && callout.text.is_within( _map.canvas.scaled_x, _map.canvas.scaled_y ) ) {
        _map.canvas.set_text_cursor();
      }
      _map.undo_text.orig.copy( callout.text );
      _map.undo_text.ct      = callout.text;
      _map.undo_text.do_undo = undoable;
      callout.mode = mode;
    } else if( (callout.mode == CalloutMode.EDITABLE) && (mode != CalloutMode.EDITABLE) ) {
      _map.canvas.im_context.reset();
      _map.canvas.im_context.focus_out();
      if( (callout.text != null) && callout.text.is_within( _map.canvas.scaled_x, _map.canvas.scaled_y ) ) {
        _map.canvas.reset_cursor();
      }
      _map.undo_text.clear();
      if( _map.undo_text.do_undo ) {
        _map.add_undo( new UndoCalloutText( _map, callout, _map.undo_text.orig ) );
      }
      _map.undo_text.ct      = null;
      _map.undo_text.do_undo = false;
      callout.mode = mode;
      auto_save();
    } else {
      callout.mode = mode;
    }
  }

  //-------------------------------------------------------------
  // NODE ATTRIBUTE METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Toggles the value of the specified node, if possible
  public void toggle_task( Node n ) {
    var changes = new Array<NodeTaskInfo?>();
    n.toggle_task_done( ref changes );
    _map.add_undo( new UndoNodeTasks( changes ) );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Toggles the folding of all selected nodes that can be folded
  public void toggle_folds( bool deep = false ) {
    var parents = new Array<Node>();
    _map.selected.get_parents( ref parents );
    if( parents.length > 0 ) {
      var changes = new Array<Node>();
      _map.animator.add_nodes_fold( _nodes, parents, "nodes fold" );
      for( int i=0; i<parents.length; i++ ) {
        var node = parents.index( i );
        node.set_fold( !node.folded, deep, changes );
      }
      _map.add_undo( new UndoNodeFolds( changes ) );
      _map.animator.animate();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Removes the given tag from all nodes containing it.  Returns
  // the list of affected nodes.
  public void remove_tag( Tag tag, Array<Node> nodes ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).remove_tag( tag, nodes );
    }
  }

  //-------------------------------------------------------------
  // Highlights all of the tags that contain the given tag.
  public void highlight_tags( Tags tags, TagComboType combo_type ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).highlight_tags( tags, combo_type );
    }
    _connections.update_alpha();
  }

  //-------------------------------------------------------------
  // GROUP METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Adds a new group for the given list of nodes
  public void add_group() {
    if( _map.selected.num_groups() > 1 ) {
      var selgroups = _map.selected.groups();
      var merged    = groups.merge_groups( selgroups );
      if( merged != null ) {
        _map.add_undo( new UndoGroupsMerge( selgroups, merged ) );
        _map.set_current_group( merged );
        queue_draw();
        auto_save();
      }
    } else if( _map.selected.num_nodes() > 0 ) {
      var nodes = _map.selected.nodes();
      var group = new NodeGroup.array( _map, nodes );
      groups.add_group( group );
      _map.add_undo( new UndoGroupAdd( group ) );
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Removes the currently selected group
  public void remove_groups() {
    var selgroups = _map.selected.groups();
    if( selgroups.length == 0 ) return;
    for( int i=0; i<selgroups.length; i++ ) {
      groups.remove_group( selgroups.index( i ) );
    }
    _map.add_undo( new UndoGroupsRemove( selgroups ) );
    _map.selected.clear();
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Changes to the color of all selected groups to the given color.
  public void change_group_color( RGBA color ) {
    var selgroups = _map.selected.groups();
    if( selgroups.length == 0 ) return;
    _map.add_undo( new UndoGroupsColor( selgroups, color ) );
    for( int i=0; i<selgroups.length; i++ ) {
      selgroups.index( i ).color = color;
    }
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // CALLOUT METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Returns true if the current node has a callout currently
  // associated with it.
  public bool node_has_callout() {
    var current = _map.get_current_node();
    return( (current != null) && (current.callout != null) );
  }

  //-------------------------------------------------------------
  // Adds a callout to the currently selected node
  public void add_callout() {
    var current = _map.selected.current_node();
    if( (current != null) && (current.callout == null) ) {
      _map.add_undo( new UndoNodeCallout( current ) );
      current.callout = new Callout( current );
      current.callout.style = _map.global_style;
      _map.selected.set_current_callout( current.callout, (_map.focus_mode ? _map.focus_alpha : 1.0) );
      set_callout_mode( current.callout, CalloutMode.EDITABLE );
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Removes a callout on the currently selected node
  public void remove_callout() {
    if( _map.is_node_selected() ) {
      var current = _map.selected.current_node();
      if( current.callout != null ) {
        _map.add_undo( new UndoNodeCallout( current ) );
        current.callout = null;
        queue_draw();
        auto_save();
      }
    } else if( _map.is_callout_selected() ) {
      var current = _map.selected.current_callout().node;
      _map.add_undo( new UndoNodeCallout( current ) );
      current.callout = null;
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Changes the current connection's title to the given value.
  public void change_current_connection_title( string title ) {
    var conns = _map.selected.connections();
    if( conns.length == 1 ) {
      var current = conns.index( 0 );
      if( current.title.text.text != title ) {
        var orig_title = new CanvasText( _map );
        orig_title.copy( current.title );
        current.change_title( _map, title );
        // if( !_current_new ) {
          _map.add_undo( new UndoConnectionTitle( _map, current, orig_title ) );
        // }
        queue_draw();
        auto_save();
      }
    }
  }

  //-------------------------------------------------------------
  // TASK METHODS
  //-------------------------------------------------------------

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
    var nodes = _map.selected.nodes();
    if( nodes.length != 1 ) return;
    _map.animator.add_nodes( _nodes, false, "change current task" );
    var changes = new Array<NodeTaskInfo?>();
    change_task( nodes.index( 0 ), enable, done, changes );
    if( changes.length > 0 ) {
      _map.add_undo( new UndoNodeTasks( changes ) );
      current_changed();
      _map.animator.animate();
      auto_save();
    } else {
      _map.animator.cancel_last_add();
    }
  }

  //-------------------------------------------------------------
  // Toggles the task values of the selected nodes
  public void change_selected_tasks() {
    var parents     = new Array<Node>();
    var changes     = new Array<NodeTaskInfo?>();
    var all_enabled = true;
    var all_done    = true;
    _map.selected.get_parents( ref parents );
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
      _map.add_undo( new UndoNodeTasks( changes ) );
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Changes the current node's note to the given value.  Updates
  // the layout, adds the undo item and redraws the canvas.
  public void change_current_node_note( string note ) {
    var nodes = _map.selected.nodes();
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
    link.normalize( _map );
    text = link.get_markdown_text( _map );
    return( _node_links.add_link( link ) );
  }

  //-------------------------------------------------------------
  // Handles a user click on a node link with the given ID
  public void note_node_link_clicked( int id ) {
    var link = _node_links.get_node_link( id );
    if( link != null ) {
      link.select( _map );
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
    var conns = _map.selected.connections();
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
    var current = _map.selected.current_node();
    if( (current != null) && (current.image == null) ) {
      image_manager.choose_image( _map.win, (id) => {
        var curr = _map.selected.current_node();
        curr.set_image( image_manager, new NodeImage( image_manager, id, curr.style.node_width ) );
        if( curr.image != null ) {
          _map.add_undo( new UndoNodeImage( curr, null ) );
          queue_draw();
          current_changed();
          auto_save();
        }
      });
    }
  }

  //-------------------------------------------------------------
  // Deletes the image from the current node.  Updates the layout,
  // adds the undo item and redraws the canvas.
  public void delete_current_image() {
    var nodes = _map.selected.nodes();
    if( nodes.length == 1 ) {
      var current = nodes.index( 0 );
      NodeImage? orig_image = current.image;
      if( orig_image != null ) {
        current.set_image( image_manager, null );
        _map.add_undo( new UndoNodeImage( current, orig_image ) );
        queue_draw();
        current_changed();
        auto_save();
      }
    }
  }

  //-------------------------------------------------------------
  // Causes the current node's image to be edited.
  public void edit_current_image() {
    var nodes = _map.selected.nodes();
    if( nodes.length == 1 ) {
      var current = nodes.index( 0 );
      if( current.image != null ) {
        _map.canvas.image_editor.edit_image( image_manager, current, current.posx, current.posy );
      }
    }
  }

  //-------------------------------------------------------------
  // Called whenever the current node's image is changed
  public void current_image_edited( NodeImage? orig_image ) {
    var current = _map.selected.current_node();
    _map.add_undo( new UndoNodeImage( current, orig_image ) );
    queue_draw();
    current_changed();
    auto_save();
  }

  //-------------------------------------------------------------
  // Called when the linking process has successfully completed
  public void end_link( Node node ) {
    var connection = _map.get_current_connection();
    if( connection == null ) return;
    connection.disconnect_node( _last_node );
    _map.selected.clear_connections();
    _last_node.linked_node = new NodeLink( node );
    _map.add_undo( new UndoNodeLink( _last_node, null ) );
    _map.canvas.last_connection = null;
    _last_node = null;
    set_attach_node( null );
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Returns true if any of the selected nodes contain node links
  public bool any_selected_nodes_linked() {
    var nodes = _map.selected.nodes();
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
    var nodes = _map.selected.nodes();
    if( nodes.length < 2 ) return;
    _map.add_undo( new UndoNodesLink( nodes ) );
    for( int i=0; i<(nodes.length - 1); i++ ) {
      nodes.index( i ).linked_node = new NodeLink( nodes.index( i + 1 ) );
    }
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Deletes all of the selected node links
  public void delete_links() {
    var nodes = _map.selected.nodes();
    _map.add_undo( new UndoNodesLink( nodes ) );
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
    var current = _map.selected.current_node();
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
    var current = _map.selected.current_node();
    if( current != null ) {
      RGBA? orig_color = current.link_color;
      if( orig_color != color ) {
        current.link_color = color;
        _map.add_undo( new UndoNodeLinkColor( current, orig_color ) );
        queue_draw();
        auto_save();
      }
    }
  }

  //-------------------------------------------------------------
  // Changes the link colors of all selected nodes to the
  // specified color
  public void change_link_colors( RGBA color ) {
    var nodes = _map.selected.nodes();
    _map.add_undo( new UndoNodesLinkColor( nodes, color ) );
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).link_color = color;
    }
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Randomizes the current link color.
  public void randomize_current_link_color() {
    var current = _map.selected.current_node();
    if( current != null ) {
      RGBA orig_color = current.link_color;
      do {
        current.link_color = _theme.random_link_color();
      } while( orig_color.equal( current.link_color ) );
      _map.add_undo( new UndoNodeLinkColor( current, orig_color ) );
      queue_draw();
      auto_save();
      current_changed();
    }
  }

  //-------------------------------------------------------------
  // Randomizes the link colors of the selected nodes
  public void randomize_link_colors() {
    var nodes  = _map.selected.nodes();
    var colors = new Array<RGBA?>();
    for( int i=0; i<nodes.length; i++ ) {
      colors.append_val( nodes.index( i ).link_color );
      nodes.index( i ).link_color = _theme.random_link_color();
    }
    _map.add_undo( new UndoNodesRandLinkColor( nodes, colors ) );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Reparents the current node's link color
  public void reparent_current_link_color() {
    var current = _map.selected.current_node();
    if( current != null ) {
      _map.add_undo( new UndoNodeReparentLinkColor( current ) );
      current.link_color_root = false;
      queue_draw();
      auto_save();
      current_changed();
    }
  }

  //-------------------------------------------------------------
  // Causes the selected nodes to use the link color of their parent
  public void reparent_link_colors() {
    var nodes = _map.selected.nodes();
    _map.add_undo( new UndoNodesReparentLinkColor( nodes ) );
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).link_color_root = false;
    }
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Changes the current connection's color to the specified color.
  public void change_current_connection_color( RGBA? color ) {
    var conn = _map.selected.current_connection();
    if( conn == null ) return;
    var orig_color = conn.color;
    if( orig_color != color ) {
      conn.color = color;
      _map.add_undo( new UndoConnectionColor( conn, orig_color ) );
      queue_draw();
      auto_save();
      current_changed();
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
      if( !_map.selected.is_connection_selected( conn ) && (conn.mode != ConnMode.EDITABLE) ) {
        _map.set_current_connection( conn );
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
      var node = _nodes.index( i ).contains( x, y, true );
      if( node != null ) {
        if( !_map.selected.is_node_selected( node ) && (node.mode != NodeMode.EDITABLE) ) {
          _map.set_current_node( node );
          queue_draw();
        }
        return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns the sibling node in the given direction of the current
  // node.  The direction can be any of the following values:
  //   - first
  //   - last
  //   - next
  //   - prev
  public Node? sibling_node( Node? node, string dir, bool wrap = false ) {
    if( node != null ) {
      if( node.is_root() ) {
        if( dir == "first" ) {
          return( _nodes.index( 0 ) );
        } else if( dir == "last" ) {
          return( _nodes.index( _nodes.length - 1 ) );
        } else {
          var int_dir = (dir == "next") ? 1 : -1;
          for( int i=0; i<_nodes.length; i++ ) {
            if( _nodes.index( i ) == node ) {
              if( (i + int_dir) < 0 ) {
                return( wrap ? _nodes.index( _nodes.length - 1 ) : null );
              } else if( (i + int_dir) >= _nodes.length ) {
                return( wrap ? _nodes.index( 0 ) : null );
              } else {
                return( _nodes.index( i + int_dir ) );
              }
            }
          }
        }
      } else if( dir == "first" ) {
        return( node.parent.first_child() );
      } else if( dir == "last" ) {
        return( node.parent.last_child() );
      } else if( dir == "next" ) {
        return( node.parent.next_child( node, wrap ) );
      } else {
        return( node.parent.prev_child( node, wrap ) );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the node that is located at the given X,Y coordinates.
  // Additionally, returns the portion of the node that is under
  // those same coordinates.
  public Node? get_node_at_position( double x, double y, out MapItemComponent component ) {
    component = MapItemComponent.NONE;
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i ).contains( x, y, true );
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
        } else if( node.is_within_tags( x, y ) ) {
          component = MapItemComponent.TAGS;
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
      queue_draw();
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
      queue_draw();
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
      queue_draw();
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
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Returns the attachable node if one is found.
  public Node? attachable_node( double x, double y ) {
    var sel_nodes = _map.selected.nodes();
    for( int i=0; i<_nodes.length; i++ ) {
      Node tmp = _nodes.index( i ).contains( x, y, false );
      if( tmp != null ) {
        for( int j=0; j<sel_nodes.length; j++ ) {
          var current = sel_nodes.index( j );
          if( (tmp == current.parent) || current.contains_node( tmp ) || tmp.is_summarized() ) {
            return( null );
          }
        }
        return( tmp );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the summary node that the current node can be
  // attached to; otherwise, returns null.
  public SummaryNode? attachable_summary_node( double x, double y ) {
    var current = _map.selected.current_node();
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

    var current_node = _map.selected.current_node();
    var current_conn = _map.selected.current_connection();
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).draw_all( ctx, _theme, current_node, false, exporting );
    }

    /* Draw the current node on top of all others */
    if( (current_node != null) && (current_node.folded_ancestor() == null) ) {
      current_node.draw_all( ctx, _theme, null, (!_map.is_node_editable() && moving_node), exporting );
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
  // Selects all nodes within the given rectangle.
  public void select_nodes_within_rectangle( Gdk.Rectangle box ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).select_within_box( box, _map.selected );
    }
  }

  //-------------------------------------------------------------
  // Updates the last_match.
  public bool update_last_match( Node? match ) {
    if( match != _last_match ) {
      if( _last_match != null ) {
        _last_match.show_fold = false;
        queue_draw();
      }
      _last_match = match;
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Attaches the current node to the attach node.
  public void attach_current_node() {

    Node?        orig_parent        = null;
    var          orig_index         = -1;
    SummaryNode? orig_summary       = null;
    var          orig_summary_index = -1;
    var          orig_style         = new Style();
    var          current            = _map.selected.current_node();
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
      current.detach( _map.canvas.get_orig_side() );
      if( (orig_summary != null) && (orig_summary.summarized_count() > 1) ) {
        orig_summary.remove_node( current );
      }
    }

    orig_style.copy( current.style );

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
      set_style_after_parent_attach( current );
    }

    /* Attach the node */
    set_attach_node( null );

    /* Add the attachment information to the undo buffer */
    if( isroot ) {
      _map.add_undo( new UndoNodeAttach.for_root( current, orig_index, _map.canvas.orig_info, orig_style ) );
    } else {
      _map.add_undo( new UndoNodeAttach( current, orig_parent, _map.canvas.get_orig_side(), orig_index, _map.canvas.orig_info, orig_summary, orig_summary_index, orig_style ) );
    }

    queue_draw();
    auto_save();
    current_changed();

  }

  //-------------------------------------------------------------
  // Attach all of the selected nodes.  If a selected node has
  // children, attach those children to the original parent node.
  public void attach_nodes( Array<Node> nodes, Node parent ) {
    for( int i=0; i<nodes.length; i++ ) {
      var node = nodes.index( i );
      node.return_to_position();
      node.make_children_siblings();
      node.detach( node.side );
      node.attach( parent, -1, null );
    }
  }

  //-------------------------------------------------------------
  // Sets the given node's styling after attaching this node to its
  // parent.
  public void set_style_after_parent_attach( Node node ) {
    if( !node.is_root() ) {
      var sibling = node.previous_sibling();
      node.style = (_map.settings.get_boolean( "style-always-from-parent" ) || (sibling == null)) ? node.parent.style : sibling.style;
    }
  }

  //-------------------------------------------------------------
  // Returns true if there is a sibling available for selection.
  public bool sibling_exists( Node? node ) {
    return( (node != null) && (node.is_root() ? (_nodes.length > 1) : (node.parent.children().length > 1)) );
  }

  //-------------------------------------------------------------
  // Returns true if the selected nodes can have their sequence attribute
  // toggled.
  public bool sequences_togglable() {
    for( int i=0; i<_map.selected.nodes().length; i++ ) {
      var node = _map.selected.nodes().index( i );
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
    for( int i=0; i<_map.selected.nodes().length; i++ ) {
      var node = _map.selected.nodes().index( i );
      if( !node.is_root() ) {
        node.sequence = !node.sequence;
        changed.append_val( node );
      }
    }
    if( changed.length > 0 ) {
      _map.add_undo( new UndoNodeSequences( changed ) );
      current_changed();
      auto_save();
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Deletes the given node.
  public void delete_node() {
    var current = _map.selected.current_node();
    if( current == null ) return;
    Node? next_node = _map.next_node_to_select();
    var   conns     = new Array<Connection>();
    UndoNodeGroups? undo_groups = null;
    _map.animator.add_nodes( _nodes, true, "delete_node" );
    _connections.node_deleted( current, conns );
    _groups.remove_node( current, ref undo_groups );
    if( current.is_root() ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) == current ) {
          _map.add_undo( new UndoNodeDelete( current, i, conns, undo_groups ) );
          _nodes.remove_index( i );
          break;
        }
      }
    } else if( current.is_summary() ) {
      _map.add_undo( new UndoNodeSummaryDelete( (SummaryNode)current, conns, undo_groups ) );
      current.delete();
    } else {
      _map.add_undo( new UndoNodeDelete( current, current.index(), conns, undo_groups ) );
      current.delete();
    }
    _map.selected.remove_node( current );
    if( !current.is_root() ) {
      _map.animator.animate();
    } else {
      _map.animator.cancel_last_add();
    }
    _map.select_node( next_node );
    auto_save();
  }

  //-------------------------------------------------------------
  // Deletes all selected nodes.
  public void delete_nodes() {
    if( _map.selected.num_nodes() == 0 ) return;
    if( _map.selected.num_nodes() == 1 ) {
      map.model.set_node_mode( map.get_current_node(), NodeMode.SELECTED );
    }
    var nodes = _map.selected.ordered_nodes();
    var conns = new Array<Connection>();
    Array<UndoNodeGroups?> undo_groups = null;
    _map.animator.add_nodes( _nodes, true, "delete_nodes" );
    for( int i=0; i<nodes.length; i++ ) {
      _connections.node_only_deleted( nodes.index( i ), conns );
    }
    _groups.remove_nodes( nodes, out undo_groups );
    _map.add_undo( new UndoNodesDelete( nodes, conns, undo_groups ) );
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).delete_only();
    }
    _map.selected.clear_nodes();
    _map.animator.animate();
    auto_save();
  }

  //-------------------------------------------------------------
  // Deletes the currently selected sticker (whether the sticker
  // is alone or connected to a node).
  public void remove_sticker() {
    var current_sticker = _map.selected.current_sticker();
    if( current_sticker != null ) {
      _map.add_undo( new UndoStickerRemove( current_sticker ) );
      _stickers.remove_sticker( current_sticker );
      _map.selected.remove_sticker( current_sticker );
      queue_draw();
      auto_save();
      return;
    }
    var current_node = _map.selected.current_node();
    if( current_node != null ) {
      _map.add_undo( new UndoNodeStickerRemove( current_node ) );
      current_node.sticker = null;
      queue_draw();
      auto_save();
      return;
    }
    var current_conn = _map.selected.current_connection();
    if( current_conn != null ) {
      _map.add_undo( new UndoConnectionStickerRemove( current_conn ) );
      current_conn.sticker = null;
      queue_draw();
      auto_save();
      return;
    }
  }

  //-------------------------------------------------------------
  // Positions the given node that will added as a root prior to
  // adding it.
  public void position_root_node( Node node ) {
    if( _nodes.length == 0 ) {
      node.posx = (_map.canvas.get_allocated_width()  / 2) - 30;
      node.posy = (_map.canvas.get_allocated_height() / 2) - 10;
    } else {
      _nodes.index( _nodes.length - 1 ).layout.position_root( _nodes.index( _nodes.length - 1 ), node );
    }
  }

  //-------------------------------------------------------------
  // Creates a root node with the given name, positions it and
  // appends it to the root node list.
  public Node create_root_node( string name = "" ) {
    var node = new Node.with_name( _map, name, ((_nodes.length == 0) ? layouts.get_default() : _nodes.index( 0 ).layout) );
    node.style = _map.global_style;
    position_root_node( node );
    _nodes.append_val( node );
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a sibling node, positions it and appends immediately
  // after the given sibling node.
  public Node create_main_node( Node root, NodeSide side, string name = "" ) {
    var node  = new Node.with_name( _map, name, layouts.get_default() );
    node.side = side;
    if( root.layout.balanceable && ((side == NodeSide.LEFT) || (side == NodeSide.TOP)) ) {
      node.attach( root, root.side_count( side ), _theme, false );
    } else {
      node.attach( root, -1, _theme, false );
    }
    set_style_after_parent_attach( node );
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a sibling node, positions it and appends immediately
  // after the given sibling node.
  public Node create_sibling_node( Node sibling, bool below, string name = "" ) {
    var node   = new Node.with_name( _map, name, layouts.get_default() );
    node.side  = sibling.side;
    node.attach( sibling.parent, (sibling.index() + (below ? 1 : 0)), _theme );
    set_style_after_parent_attach( node );
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
    var node  = new Node.with_name( _map, name, layouts.get_default() );
    var color = child.link_color;
    node.side  = child.side;
    node.attach( child.parent, child.index(), null );
    node.link_color = color;
    child.detach( node.side );
    child.attach( node, -1, null );
    set_style_after_parent_attach( node );
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a child node, positions it, and inserts it into the
  // parent node.
  public Node create_child_node( Node parent, string name = "" ) {
    var node = new Node.with_name( _map, name, layouts.get_default() );
    if( !parent.is_root() ) {
      node.side = parent.side;
    }
    if( parent.children().length > 0 ) {
      parent.folded = false;
    }
    node.attach( parent, -1, _theme );
    set_style_after_parent_attach( node );
    parent.set_fold( false, true );
    return( node );
  }

  //-------------------------------------------------------------
  // Creates a summary node for the nodes in the range of first
  // to last, inclusive.
  public Node create_summary_node( Array<Node> nodes ) {
    var summary = new SummaryNode( _map, layouts.get_default() );
    summary.side = nodes.index( 0 ).side;
    summary.attach_nodes( nodes.index( 0 ).parent, nodes, true, _theme );
    return( summary );
  }

  //-------------------------------------------------------------
  // Creates a summary node from the given node.
  public Node create_summary_node_from_node( Node node ) {
    var prev_node = node.previous_sibling();
    node.detach( node.side );
    var summary = new SummaryNode.from_node( _map, node, image_manager );
    summary.side = node.side;
    summary.attach_siblings( prev_node, _theme );
    return( summary );
  }

  //-------------------------------------------------------------
  // Adds a new root node to the canvas.
  public void add_root_node() {
    var node         = create_root_node( _( "Another Idea" ) );
    var int_node_len = (int)(_nodes.length - 1);
    _map.add_undo( new UndoNodeInsert( node, int_node_len ) );
    if( _map.select_node( node ) ) {
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
    var conn  = new Connection( _map, _map.selected.current_node() );
    conn.connect_to( _map.selected.current_node() );
    conn.connect_to( node );
    _connections.add_connection( conn );
    _map.add_undo( new UndoConnectedNode( node, index, conn ) );
    if( _map.select_node( node ) ) {
      set_node_mode( node, NodeMode.EDITABLE, false );
      queue_draw();
    }
    see();
    auto_save();
  }

  //-------------------------------------------------------------
  // Adds a new sibling node to the current node.
  public void add_sibling_node( bool shift ) {
    var current = _map.selected.current_node();
    if( current.is_summary() ) return;
    var node = create_sibling_node( current, !shift );
    _map.add_undo( new UndoNodeInsert( node, node.index() ) );
    _map.set_current_node( node );
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
    var current = _map.selected.current_node();
    if( current.is_root() || current.is_summarized() ) return;
    _map.animator.add_nodes( _nodes, false, "add_parent_node" );
    var node = create_parent_node( current );
    _map.add_undo( new UndoNodeAddParent( node, current ) );
    _map.set_current_node( node );
    set_node_mode( node, NodeMode.EDITABLE, false );
    _map.animator.animate();
    see();
    auto_save();
  }

  //-------------------------------------------------------------
  // Adds a child node to the current node.
  public void add_child_node() {
    var current = _map.selected.current_node();
    if( current.is_summarized() ) return;
    var node    = create_child_node( current );
    _map.add_undo( new UndoNodeInsert( node, node.index() ) );
    _map.set_current_node( node );
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
    var nodes = _map.selected.ordered_nodes();
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
    var current = _map.selected.current_node();
    if( (current != null) && !current.is_summary() && !current.is_summarized() ) {
      var sibling = current.previous_sibling();
      return( (sibling != null) && !sibling.is_summarized() && sibling.is_leaf() && (current.side == sibling.side) );
    }
    return( false );
  }

  /* Adds a summary node to the first and last nodes in the selected range */
  public void add_summary_node_from_selected() {
    if( !nodes_summarizable() ) return;
    var nodes = _map.selected.nodes();
    var node  = create_summary_node( nodes );
    _map.add_undo( new UndoNodeSummary( (SummaryNode)node ) );
    _map.set_current_node( node );
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
    var current = _map.selected.current_node();
    var node = create_summary_node_from_node( current );
    _map.add_undo( new UndoNodeSummaryFromNode( current, (SummaryNode)node ) );
    _map.set_current_node( node );
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
    var current = _map.selected.current_node();
    return( (current != null) && (current.parent != null) );
  }

  //-------------------------------------------------------------
  // Detaches the current node from its parent and adds it as a
  // root node.
  public void detach() {
    if( !detachable() ) return;
    var current    = _map.selected.current_node();
    var parent     = current.parent;
    var index      = current.index();
    var side       = current.side;
    var root_index = (int)_nodes.length;
    current.detach( side );
    add_root( current, -1 );
    _map.add_undo( new UndoNodeDetach( current, root_index, parent, side, index ) );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Balances the existing nodes based on the current layout.
  public void balance_nodes( bool undoable, bool animate ) {
    var current   = _map.selected.current_node();
    var root_node = (current == null) ? null : current.get_root();
    if( undoable ) {
      _map.add_undo( new UndoNodeBalance( _map, root_node ) );
    }
    if( (current == null) || !undoable ) {
      if( animate ) {
        _map.animator.add_nodes( _nodes, false, "balance nodes" );
      }
      for( int i=0; i<_nodes.length; i++ ) {
        var partitioner = new Partitioner();
        partitioner.partition_node( _nodes.index( i ) );
      }
    } else {
      if( animate ) {
        _map.animator.add_node( root_node, "balance tree" );
      }
      var partitioner = new Partitioner();
      partitioner.partition_node( root_node );
    }
    if( animate ) {
      _map.animator.animate();
    }
  }

  //-------------------------------------------------------------
  // Returns true if there is at least one node that can be
  // folded due to completed tasks.
  public bool completed_tasks_foldable() {
    var current = _map.selected.current_node();
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
    var current = _map.selected.current_node();
    if( current == null ) {
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).fold_completed_tasks( changes );
      }
    } else {
      current.get_root().fold_completed_tasks( changes );
    }
    if( changes.length > 0 ) {
      _map.add_undo( new UndoNodeFolds( changes ) );
      queue_draw();
      auto_save();
      current_changed();
    }
  }

  //-------------------------------------------------------------
  // Returns true if there is at least one node that is unfoldable.
  public bool unfoldable() {
    var current = _map.selected.current_node();
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
    var current = _map.selected.current_node();
    if( current != null ) {
      current.get_root().set_fold( false, true, changes );
    } else {
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).set_fold( false, true, changes );
      }
    }
    if( changes.length > 0 ) {
      _map.add_undo( new UndoNodeFolds( changes ) );
      queue_draw();
      auto_save();
      current_changed();
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

  /* Returns the node at the bottom of the sibling list */
  public Node? get_node_pagedn( Node node ) {
    if( node.is_root() ) {
      return( (_nodes.length > 0) ? _nodes.index( _nodes.length - 1 ) : null );
    } else {
      return( node.is_summary() ? null : node.parent.last_child() );
    }
  }

  //-------------------------------------------------------------
  // Returns true if we can perform a node copy operation.
  public bool node_copyable() {
    return( _map.selected.current_node() != null );
  }

  /* Returns true if we can perform a node cut operation */
  public bool node_cuttable() {
    return( _map.selected.current_node() != null );
  }

  /* Returns true if we can perform a node paste operation */
  public bool node_pasteable() {
    return( MinderClipboard.node_pasteable() );
  }

  /* Returns true if the currently selected nodes are alignable */
  public bool nodes_alignable() {
    var nodes = _map.selected.nodes();
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
            _connections.load( _map, it, conns, nodes );
            break;
          case "groups" :
            _groups.load( _map, it, groups, nodes );
            break;
          case "nodes"       :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                var siblings = new Array<Node>();
                var node = new Node.from_xml( _map, null, it2, true, null, ref siblings );
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

  //-------------------------------------------------------------
  // Deserialize the node tree, returning the first node as a
  // node link
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
    if( _map.selected.num_nodes() == 1 ) {
      nodes.append_val( _map.get_current_node() );
    } else {
      _map.selected.get_subtrees( ref nodes, image_manager );
    }
  }

  //-------------------------------------------------------------
  // Copies the currently selected text to the clipboard.
  public void copy_selected_text() {
    var text = _map.get_current_text();
    if( text != null ) {
      MinderClipboard.copy_text( text.get_selected_text() );
    }
  }

  //-------------------------------------------------------------
  // Copies either the current node or the currently selected
  // text to the clipboard.
  public void do_copy() {
    var current = _map.selected.current_node();
    if( current != null ) {
      switch( current.mode ) {
        case NodeMode.CURRENT  :  MinderClipboard.copy_nodes( _map );  break;
        case NodeMode.EDITABLE :  copy_selected_text();  break;
      }
    } else if( _map.selected.nodes().length > 1 ) {
      MinderClipboard.copy_nodes( _map );
    } else if( _map.is_connection_editable() || _map.is_callout_editable() ) {
      copy_selected_text();
    }
  }

  //-------------------------------------------------------------
  // Cuts the current node from the tree and stores it in the
  // clipboard.
  public void cut_node_to_clipboard() {
    var current = _map.get_current_node();
    if( current == null ) return;
    var next_node = _map.next_node_to_select();
    var conns     = new Array<Connection>();
    UndoNodeGroups? undo_groups = null;
    _map.animator.add_nodes( _nodes, true, "cut nodes" );
    _connections.node_deleted( current, conns );
    _groups.remove_node( current, ref undo_groups );
    MinderClipboard.copy_nodes( _map );
    if( current.is_root() ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) == current ) {
          _map.add_undo( new UndoNodeCut( current, i, conns, undo_groups ) );
          _nodes.remove_index( i );
          break;
        }
      }
    } else {
      _map.add_undo( new UndoNodeCut( current, current.index(), conns, undo_groups ) );
      current.delete();
    }
    _map.selected.remove_node( current );
    if( !current.is_root() ) {
      _map.animator.animate();
    } else {
      _map.animator.cancel_last_add();
    }
    _map.select_node( next_node );
    auto_save();
  }

  //-------------------------------------------------------------
  // Copies all of the selected nodes (along with related connection
  // and group information) and removes them from the clipboard.
  public void cut_selected_nodes_to_clipboard() {
    if( _map.selected.num_nodes() == 0 ) return;
    var nodes = _map.selected.ordered_nodes();
    var conns = new Array<Connection>();
    Array<UndoNodeGroups?> undo_groups = null;
    _map.animator.add_nodes( _nodes, true, "cut nodes" );
    for( int i=0; i<nodes.length; i++ ) {
      _connections.node_only_deleted( nodes.index( i ), conns );
    }
    _groups.remove_nodes( nodes, out undo_groups );
    MinderClipboard.copy_nodes( _map );
    _map.add_undo( new UndoNodesCut( nodes, conns, undo_groups ) );
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).delete_only();
    }
    _map.selected.clear_nodes();
    _map.animator.animate();
    auto_save();
  }

  //-------------------------------------------------------------
  // Cuts the current selected text to the clipboard.
  public void cut_selected_text() {
    var text = _map.get_current_text();
    if( text != null ) {
      MinderClipboard.copy_text( text.get_selected_text() );
      text.insert( "", _map.undo_text );
      queue_draw();
      auto_save();
    }
  }

  //-------------------------------------------------------------
  // Either cuts the current node or cuts the currently selected
  // text.
  public void do_cut() {
    var current = _map.selected.current_node();
    if( current != null ) {
      switch( current.mode ) {
        case NodeMode.CURRENT  :  cut_node_to_clipboard();  break;
        case NodeMode.EDITABLE :  cut_selected_text();      break;
      }
    } else if( _map.selected.nodes().length > 1 ) {
      cut_selected_nodes_to_clipboard();
    } else if( _map.is_connection_editable() || _map.is_callout_editable() ) {
      cut_selected_text();
    }
  }

  //-------------------------------------------------------------
  // Replaces the node's text with the given string.
  private void replace_node_text( Node node, string text ) {
    var orig_text = new CanvasText( _map );
    orig_text.copy( node.name );
    node.name.text.replace_text( 0, node.name.text.text.char_count(), text.strip() );
    _map.add_undo( new UndoNodeName( _map, node, orig_text ) );
    queue_draw();
    auto_save();
  }

  //-------------------------------------------------------------
  // Replaces the connection's text with the given string.
  private void replace_connection_text( Connection conn, string text ) {
    var orig_title = new CanvasText( _map );
    orig_title.copy( conn.title );
    conn.title.text.replace_text( 0, conn.title.text.text.char_count(), text.strip() );
    _map.add_undo( new UndoConnectionTitle( _map, conn, orig_title ) );
    queue_draw();
    current_changed();
    auto_save();
  }

  //-------------------------------------------------------------
  // Replaces the callout's text with the given string.
  private void replace_callout_text( Callout callout, string text ) {
    var orig_text = new CanvasText( _map );
    orig_text.copy( callout.text );
    callout.text.text.replace_text( 0, callout.text.text.text.char_count(), text.strip() );
    _map.add_undo( new UndoCalloutText( _map, callout, orig_text ) );
    queue_draw();
    current_changed();
    auto_save();
  }

  //-------------------------------------------------------------
  // Replaces the node's image with the given image.
  private void replace_node_image( Node node, Pixbuf image ) {
    var ni = new NodeImage.from_pixbuf( image_manager, image, node.style.node_width );
    if( ni.valid ) {
      var orig_image = node.image;
      node.set_image( image_manager, ni );
      _map.add_undo( new UndoNodeImage( node, orig_image ) );
      queue_draw();
      current_changed();
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
    _map.add_undo( new UndoNodesReplace( node, nodes ) );
    _map.select_node( nodes.index( 0 ) );
    queue_draw();
    current_changed();
    auto_save();
  }

  //-------------------------------------------------------------
  // Converts the given text string into a node tree and inserts
  // the node tree into the mindmap.
  public bool insert_text_as_node( Node? node, string text ) {
    var nodes  = new Array<Node>();
    var export = (ExportText)_map.win.exports.get_by_name( "text" );
    export.import_text( text, 0, _map, false, nodes );
    if( nodes.length == 0 ) return( false );
    _map.add_undo( new UndoNodesInsert( _map, nodes ) );
    queue_draw();
    auto_save();
    return( true );
  }

  //-------------------------------------------------------------
  // Converts the given text string into a node tree and replaces
  // the current node tree in the mindmap.
  public bool replace_text_as_node( Node node, string text ) {
    var nodes = new Array<Node>();
    var export = (ExportText)_map.win.exports.get_by_name( "text" );
    export.import_text( text, 0, _map, true, nodes );
    if( nodes.length == 0 ) return( false );
    _map.add_undo( new UndoNodesReplace( node, nodes ) );
    queue_draw();
    auto_save();
    return( true );
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
    _map.add_undo( new UndoNodeInsert( new_node, ((node == null) ? (int)(_nodes.length - 1) : new_node.index()) ) );
    _map.select_node( new_node );
    queue_draw();
    current_changed();
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
    _map.animator.add_nodes( _nodes, false, "paste nodes" );
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
    _map.add_undo( new UndoNodePaste( nodes, conns, groups ) );
    _map.animator.animate();
    _map.select_node( nodes.index( 0 ) );
    current_changed();
    auto_save();
  }

  //-------------------------------------------------------------
  // Called by the clipboard to paste text.
  public void paste_text( string text, bool shift ) {
    var node    = _map.get_current_node();
    var conn    = _map.get_current_connection();
    var callout = _map.get_current_callout();
    if( shift ) {
      if( (node != null) && (node.mode == NodeMode.CURRENT) ) {
        replace_node_text( node, text );
      } else if( (conn != null) && (conn.mode == ConnMode.SELECTED) ) {
        replace_connection_text( conn, text );
      } else if( (callout != null) && (callout.mode == CalloutMode.SELECTED) ) {
        replace_callout_text( callout, text );
      }
    } else {
      var ct = _map.get_current_text();
      if( ct != null ) {
        ct.insert( text, _map.undo_text );
        queue_draw();
      } else if( conn == null ) {
        insert_text_as_node( node, text );
      }
    }
  }

  //-------------------------------------------------------------
  // Pastes the current node in the clipboard as a node link to
  // the current node.
  public void paste_node_link( string text ) {
    if( _map.is_node_selected() ) {
      var current  = _map.selected.current_node();
      var old_link = current.linked_node;
      var new_link = deserialize_for_node_link( text );
      if( new_link != null ) {
        current.linked_node = new_link;
        _map.add_undo( new UndoNodeLink( current, old_link ) );
        auto_save();
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Called by the clipboard to paste image.
  public void paste_image( Pixbuf image, bool shift ) {
    var node = _map.selected.current_node();
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
    var node = _map.selected.current_node();
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
    if( _map.editable ) {
      if( _auto_save_id != null ) {
        Source.remove( _auto_save_id );
      }
      _auto_save_id = Timeout.add( 200, do_auto_save );
    }
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
    var current = _map.selected.current_node();
    var image   = new NodeImage.from_uri( image_manager, uri, current.style.node_width );
    if( image.valid ) {
      var orig_image = current.image;
      current.set_image( image_manager, image );
      _map.add_undo( new UndoNodeImage( current, orig_image ) );
      queue_draw();
      current_changed();
      auto_save();
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Starts a connection from the current node.
  public void start_connection( bool key, bool link ) {
    var current_node = _map.selected.current_node();
    if( (current_node == null) || _connections.hide ) return;
    var conn = new Connection( _map, current_node );
    _map.set_current_connection( conn );
    conn.mode = link ? ConnMode.LINKING : ConnMode.CONNECTING;
    if( key ) {
      double x, y, w, h;
      current_node.bbox( out x, out y, out w, out h );
      conn.draw_to( (x + (w / 2)), (y + (h / 2)) );
      set_attach_node( current_node );
    } else {
      conn.draw_to( _map.canvas.press_x, _map.canvas.press_y );
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
    _map.selected.current_connection().draw_to( (x + (w / 2)), (y + (h / 2)) );
    set_attach_node( node );
    queue_draw();
  }

  //-------------------------------------------------------------
  // Ends a connection at the given node.
  public void end_connection( Node n ) {
    var current = _map.selected.current_connection();
    if( current == null ) return;
    current.connect_to( n );
    _connections.add_connection( current );
    _map.add_undo( new UndoConnectionAdd( current ) );
    _map.set_current_connection( current );
    handle_connection_edit_on_creation( current );
    _map.canvas.last_connection = null;
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
    if( (_map.selected.num_nodes() != 2) || _connections.hide ) return;
    double x, y, w, h;
    var    nodes = _map.selected.nodes();
    var    conn  = new Connection( _map, nodes.index( 0 ) );
    conn.connect_to( nodes.index( 1 ) );
    nodes.index( 1 ).bbox( out x, out y, out w, out h );
    conn.draw_to( (x + (w / 2)), (y + (h / 2)) );
    _connections.add_connection( conn );
    _map.set_current_connection( conn );
    _map.add_undo( new UndoConnectionAdd( conn ) );
    handle_connection_edit_on_creation( conn );
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Deletes the current connection.
  public void delete_connection() {
    var current = _map.selected.current_connection();
    if( current == null ) return;
    _map.add_undo( new UndoConnectionDelete( current ) );
    _connections.remove_connection( current, false );
    _map.selected.remove_connection( current );
    _map.canvas.last_connection = null;
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Deletes the currently selected connections.
  public void delete_connections() {
    if( _map.selected.num_connections() == 0 ) return;
    var conns = _map.selected.connections();
    _map.add_undo( new UndoConnectionsDelete( conns ) );
    for( int i=0; i<conns.length; i++ ) {
      _connections.remove_connection( conns.index( i ), false );
    }
    _map.selected.clear_connections();
    auto_save();
    queue_draw();
  }

  //-------------------------------------------------------------
  // Handles the edit on creation of a newly created connection.
  public void handle_connection_edit_on_creation( Connection conn ) {
    if( (conn.title == null) && _map.settings.get_boolean( "edit-connection-title-on-creation" ) ) {
      conn.change_title( _map, "", true );
      set_connection_mode( conn, ConnMode.EDITABLE, false );
    }
  }

  //-------------------------------------------------------------
  // Sorts and re-arranges the children of the given parent using
  // the given array.
  private void sort_children( Node parent, CompareFunc<Node> sort_fn ) {
    var children = new SList<Node>();
    _map.add_undo( new UndoNodeSort( parent ) );
    _map.animator.add_nodes( _nodes, false, "sort nodes" );
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
    _map.animator.animate();
    auto_save();
  }

  //-------------------------------------------------------------
  // Sorts the current node's children alphabetically.
  public void sort_alphabetically() {
    CompareFunc<Node> sort_fn = (a, b) => {
      return( strcmp( a.name.text.text, b.name.text.text ) );
    };
    sort_children( _map.selected.current_node(), sort_fn );
  }

  //-------------------------------------------------------------
  // Sorts the current node's children in a random manner.
  public void sort_randomly() {
    CompareFunc<Node> sort_fn = (a, b) => {
      return( (Random.int_range( 0, 2 ) == 0) ? -1 : 1 );
    };
    sort_children( _map.selected.current_node(), sort_fn );
  }

  //-------------------------------------------------------------
  // Moves all trees to avoid overlapping.
  public void handle_tree_overlap( NodeBounds prev ) {
    var current = _map.selected.current_node();
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
  // Returns the droppable node, if one exists; otherwise, returns
  // null.
  public Node? get_droppable_node( double x, double y ) {
    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i ).contains( x, y, true );
      if( node != null ) {
        return( node );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Returns the droppable node or connection if one is found.
  public void get_droppable( double x, double y, out Node? node, out Connection? conn, out Sticker? sticker ) {
    conn    = null;
    sticker = null;
    node    = get_droppable_node( x, y );
    if( node != null ) return;
    conn = _connections.within_title_box( x, y );
    if( conn != null ) return;
    conn = _connections.on_curve( x, y );
    if( conn != null ) return;
    sticker = _stickers.is_within( x, y );
  }

}
