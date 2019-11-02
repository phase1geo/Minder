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

public class DrawArea : Gtk.DrawingArea {

  private const Gtk.TargetEntry[] DRAG_TARGETS = {
    {"text/uri-list", 0, 0}
  };

  private Document         _doc;
  private GLib.Settings    _settings;
  private double           _press_x;
  private double           _press_y;
  private double           _origin_x;
  private double           _origin_y;
  private double           _scale_factor;
  private double           _store_origin_x;
  private double           _store_origin_y;
  private double           _store_scale_factor;
  private bool             _pressed    = false;
  private EventType        _press_type = EventType.NOTHING;
  private bool             _resize     = false;
  private bool             _motion     = false;
  private Node?            _last_node    = null;
  private bool             _current_new  = false;
  private Connection?      _last_connection = null;
  private Array<Node>      _nodes;
  private Connections      _connections;
  private Theme            _theme;
  private string           _orig_name;
  private NodeSide         _orig_side;
  private Array<NodeInfo?> _orig_info;
  private int              _orig_width;
  private string           _orig_title;
  private Node?            _attach_node  = null;
  private NodeMenu         _node_menu;
  private ConnectionMenu   _conn_menu;
  private ConnectionsMenu  _conns_menu;
  private NodesMenu        _nodes_menu;
  private EmptyMenu        _empty_menu;
  private TextMenu         _text_menu;
  private uint?            _auto_save_id = null;
  private ImageEditor      _editor;
  private IMContextSimple  _im_context;
  private bool             _debug        = true;
  private bool             _focus_mode   = false;
  private double           _focus_alpha  = 0.05;
  private bool             _create_new_from_edit;
  private Selection        _selected;

  public MainWindow    win            { private set; get; }
  public UndoBuffer    undo_buffer    { set; get; }
  public Layouts       layouts        { set; get; default = new Layouts(); }
  public Animator      animator       { set; get; }
  public Clipboard     node_clipboard { set; get; default = Clipboard.get_for_display( Display.get_default(), Atom.intern( "org.github.phase1geo.minder", false ) ); }
  public ImageManager  image_manager  { set; get; default = new ImageManager(); }

  public GLib.Settings settings {
    get {
      return( _settings );
    }
  }
  public double origin_x {
    set {
      _store_origin_x = _origin_x = value;
    }
    get {
      return( _origin_x );
    }
  }
  public double origin_y {
    set {
      _store_origin_y = _origin_y = value;
    }
    get {
      return( _origin_y );
    }
  }
  public double sfactor {
    set {
      _store_scale_factor = _scale_factor = value;
    }
    get {
      return( _scale_factor );
    }
  }

  public signal void changed();
  public signal void current_changed( DrawArea da );
  public signal void theme_changed( DrawArea da );
  public signal void scale_changed( double scale );
  public signal void show_properties( string? tab, bool grab_note );
  public signal void hide_properties();
  public signal void loaded();

  /* Default constructor */
  public DrawArea( MainWindow w, GLib.Settings settings, AccelGroup accel_group ) {

    win = w;

    _doc      = new Document( this );
    _settings = settings;

    /* Create the selection */
    _selected = new Selection( this );

    /* Create the array of root nodes in the map */
    _nodes = new Array<Node>();

    /* Create the connections */
    _connections = new Connections();

    /* Allocate memory for the animator */
    animator = new Animator( this );

    /* Allocate memory for the undo buffer */
    undo_buffer = new UndoBuffer( this );

    /* Allocate the image editor popover */
    _editor = new ImageEditor( this );
    _editor.changed.connect( current_image_edited );

    /* Create the popup menu */
    _node_menu  = new NodeMenu( this, accel_group );
    _conn_menu  = new ConnectionMenu( this, accel_group );
    _conns_menu = new ConnectionsMenu( this, accel_group );
    _empty_menu = new EmptyMenu( this, accel_group );
    _nodes_menu = new NodesMenu( this, accel_group );
    _text_menu  = new TextMenu( this, accel_group );

    /* Create the node information array */
    _orig_info = new Array<NodeInfo?>();

    /* Get the value of the new node from edit */
    update_focus_mode_alpha( settings );
    update_create_new_from_edit( settings );
    settings.changed.connect(() => {
      update_focus_mode_alpha( settings );
      update_create_new_from_edit( settings );
    });

    /* Set the theme to the default theme */
    set_theme( win.themes.get_theme( _( "Default" ) ), false );

    /* Add event listeners */
    this.draw.connect( on_draw );
    this.button_press_event.connect( on_press );
    this.motion_notify_event.connect( on_motion );
    this.button_release_event.connect( on_release );
    this.key_press_event.connect( on_keypress );
    this.scroll_event.connect( on_scroll );

    /* Make sure the above events are listened for */
    this.add_events(
      EventMask.BUTTON_PRESS_MASK |
      EventMask.BUTTON_RELEASE_MASK |
      EventMask.BUTTON1_MOTION_MASK |
      EventMask.POINTER_MOTION_MASK |
      EventMask.KEY_PRESS_MASK |
      EventMask.SMOOTH_SCROLL_MASK |
      EventMask.STRUCTURE_MASK
    );

    /* Set ourselves up to be a drag target */
    Gtk.drag_dest_set( this, DestDefaults.MOTION | DestDefaults.DROP, DRAG_TARGETS, Gdk.DragAction.COPY );

    this.drag_motion.connect( handle_drag_motion );
    this.drag_data_received.connect( handle_drag_data_received );

    /*
     Make sure that the images are cleaned up when the user exits the application or we received
     a terminate signal.
    */
    this.destroy.connect(() => {
      image_manager.cleanup();
    });

    /*
    TBD - This code does not compile
    Posix.sighandler_t? t = this.handle_sigterm;
    Posix.@signal( Posix.Signal.TERM, t );
    */

    /* Make sure the drawing area can receive keyboard focus */
    this.can_focus = true;

    /*
     Make sure that we add a CSS class name to ourselves so we can color
     our background with the theme.
    */
    get_style_context().add_class( "canvas" );

    /* Make sure that we us the ImContextSimple input method */
    _im_context = new IMContextSimple();
    _im_context.commit.connect( handle_printable );

  }

  /* Called to handle a sigterm signal to the application */
  public void handle_sigterm( int s ) {
    image_manager.cleanup();
  }

  /* Returns the stored document */
  public Document get_doc() {
    return( _doc );
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
    _theme       = theme;
    _theme.index = (orig_theme != null) ? orig_theme.index : 0;
    StyleContext.add_provider_for_screen(
      Screen.get_default(),
      _theme.get_css_provider(),
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );
    if( orig_theme != null ) {
      map_theme_colors( orig_theme );
    }
    theme_changed( this );
    queue_draw();
    if( save ) {
      changed();
    }
  }

  /* Updates all nodes with the new theme colors */
  private void map_theme_colors( Theme old_theme ) {
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).map_theme_colors( old_theme, _theme );
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
    animator.add_nodes( "set layout" );
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
      balance_nodes( false );
    } else {
      animator.animate();
    }
  }

  /* Returns the list of nodes */
  public Array<Node> get_nodes() {
    return( _nodes );
  }

  /* Returns the connections list */
  public Connections get_connections() {
    return( _connections );
  }

  /* Returns the current focus mode value */
  public bool get_focus_mode() {
    return( _focus_mode );
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

  /* Sets the cursor of the drawing area */
  private void set_cursor( CursorType? type = null ) {

    var     win    = get_window();
    Cursor? cursor = win.get_cursor();

    if( type == null ) {
      win.set_cursor( null );
    } else if( (cursor == null) || (cursor.cursor_type != type) ) {
      win.set_cursor( new Cursor.for_display( get_display(), type ) );
    }

  }

  /* Sets the cursor of the drawing area to the named cursor */
  private void set_cursor_from_name( string name ) {
    var win = get_window();
    win.set_cursor( new Cursor.from_name( get_display(), name ) );
  }

  /* Loads the drawing area origin from the XML node */
  private void load_drawarea( Xml.Node* n ) {

    string? x = n->get_prop( "x" );
    if( x != null ) {
      origin_x = double.parse( x );
    }

    string? y = n->get_prop( "y" );
    if( y != null ) {
      origin_y = double.parse( y );
    }

    string? sf = n->get_prop( "scale" );
    if( sf != null ) {
      sfactor = double.parse( sf );
      scale_changed( sfactor );
    }

  }

  /* Loads the given theme from the list of available options */
  private void load_theme( Xml.Node* n ) {

    /* Load the theme */
    var theme = new Theme();
    theme.temporary = true;
    theme.load( n );

    /* If this theme does not currently exist, add the theme temporarily */
    if( !win.themes.exists( theme ) ) {
      theme.name = win.themes.uniquify_name( theme.name );
      win.themes.add_theme( theme );
    }

    /* Get the theme */
    _theme = win.themes.get_theme( theme.name );
    StyleContext.add_provider_for_screen(
      Screen.get_default(),
      _theme.get_css_provider(),
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );

    theme_changed( this );

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

  /* Loads the contents of the data input stream */
  public void load( Xml.Node* n ) {

    Layout? use_layout = null;
    var     id_map     = new HashMap<int,int>();
    var     link_ids   = new Array<NodeLinkInfo?>();

    /* Disable animations while we are loading */
    var animate = animator.enable;
    animator.enable = false;

    /* Clear the existing nodes */
    _nodes.remove_range( 0, _nodes.length );

    /* Load the contents of the file */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "theme"       :  load_theme( it );   break;
          case "layout"      :  load_layout( it, ref use_layout );  break;
          case "styles"      :  StyleInspector.styles.load( it );  break;
          case "drawarea"    :  load_drawarea( it );  break;
          case "images"      :  image_manager.load( it );  break;
          case "connections" :  _connections.load( this, it, null, _nodes, id_map );  break;
          case "nodes"       :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                var node = new Node.with_name( this, "temp", null );
                node.load( this, it2, true, id_map, link_ids );
                if( use_layout != null ) {
                  node.layout = use_layout;
                }
                _nodes.append_val( node );
              }
            }
            break;
        }
      }
    }

    /* Handle node links */
    for( int i=0; i<link_ids.length; i++ ) {
      link_ids.index( i ).node.linked_node = get_node( _nodes, id_map.get( int.parse( link_ids.index( i ).id_str ) ) );
    }

    queue_draw();

    /* Indicate to anyone listening that we have loaded a new file */
    loaded();

    /* Make sure that the inspector is updated */
    current_changed( this );

    /* Reset the animator enable */
    animator.enable = animate;

  }

  /* Saves the contents of the drawing area to the data output stream */
  public bool save( Xml.Node* parent ) {

    parent->add_child( _theme.save() );

    StyleInspector.styles.save( parent );

    Xml.Node* origin = new Xml.Node( null, "drawarea" );
    origin->new_prop( "x", _store_origin_x.to_string() );
    origin->new_prop( "y", _store_origin_y.to_string() );
    origin->new_prop( "scale", _store_scale_factor.to_string() );
    parent->add_child( origin );

    Xml.Node* images = new Xml.Node( null, "images" );
    image_manager.save( images );
    parent->add_child( images );

    Xml.Node* nodes = new Xml.Node( null, "nodes" );
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).save( nodes );
    }
    parent->add_child( nodes );

    _connections.save( parent );

    return( true );

  }

  /* Imports the OPML data, creating a mind map */
  public void import_opml( Xml.Node* n, ref Array<int>? expand_state) {

    int node_id = 1;

    /* Clear the existing nodes */
    _nodes.remove_range( 0, _nodes.length );

    /* Load the contents of the file */
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "outline") {
          var root = new Node( this, layouts.get_default() );
          root.import_opml( this, it, node_id, ref expand_state, _theme );
          _nodes.append_val( root );
        }
      }
    }

  }

  /* Exports all of the nodes in OPML format */
  public void export_opml( Xml.Node* parent, out string expand_state ) {
    Array<int> estate  = new Array<int>();
    int        node_id = 1;
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).export_opml( parent, ref node_id, ref estate );
    }
    expand_state = "";
    for( int i=0; i<estate.length; i++ ) {
      if( i > 0 ) {
        expand_state += ",";
      }
      expand_state += estate.index( i ).to_string();
    }
  }

  /* Initializes the canvas to prepare it for a document that will be loaded */
  public void initialize_for_open() {

    /* Clear the list of existing nodes */
    _nodes.remove_range( 0, _nodes.length );

    /* Clear the list of connections */
    _connections.clear_all_connections();

    /* Clear the undo buffer */
    undo_buffer.clear();

    /* Reset the node ID generator */
    Node.reset();

    /* Clear the selection */
    _selected.clear();

    /* Initialize variables */
    origin_x            = 0.0;
    origin_y            = 0.0;
    sfactor             = 1.0;
    node_clipboard.clear();
    _pressed            = false;
    _press_type         = EventType.NOTHING;
    _motion             = false;
    _attach_node        = null;
    _orig_name          = "";
    _current_new        = false;
    _last_connection    = null;

    set_current_node( null );

    queue_draw();

  }

  /* Initialize the empty drawing area with a node */
  public void initialize_for_new() {

    /* Clear the list of existing nodes */
    _nodes.remove_range( 0, _nodes.length );

    /* Clear the list of connections */
    _connections.clear_all_connections();

    /* Clear the undo buffer */
    undo_buffer.clear();

    /* Reset the node ID generator */
    Node.reset();

    /* Clear the selection */
    _selected.clear();

    /* Initialize variables */
    origin_x            = 0.0;
    origin_y            = 0.0;
    sfactor             = 1.0;
    node_clipboard.clear();
    _pressed            = false;
    _press_type         = EventType.NOTHING;
    _motion             = false;
    _attach_node        = null;
    _current_new        = false;
    _last_connection    = null;

    /* Create the main idea node */
    var n = new Node.with_name( this, _("Main Idea"), layouts.get_default() );

    /* Set the node information */
    n.posx  = (get_allocated_width()  / 2) - 30;
    n.posy  = (get_allocated_height() / 2) - 10;
    n.style = StyleInspector.styles.get_global_style();

    _nodes.append_val( n );
    _orig_name    = "";

    /* Make this initial node the current node */
    set_current_node( n );
    n.mode = NodeMode.EDITABLE;

    /* Redraw the canvas */
    queue_draw();

  }

  /* Returns the current node */
  public Node? get_current_node() {
    return( _selected.current_node() );
  }

  /* Returns the current connection */
  public Connection? get_current_connection() {
    return( _selected.current_connection() );
  }

  /* Returns the array of selected nodes */
  public Array<Node> get_selected_nodes() {
    return( _selected.nodes() );
  }

  /* Returns the array of selected connections */
  public Array<Connection> get_selected_connections() {
    return( _selected.connections() );
  }

  /* Returns the selection instance associated with this DrawArea */
  public Selection get_selections() {
    return( _selected );
  }

  /*
   Populates the list of matches with any nodes that match the given string
   pattern.
  */
  public void get_match_items( string pattern, bool[] search_opts, ref Gtk.ListStore matches ) {
    if( search_opts[0] ) {
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).get_match_items( pattern, search_opts, ref matches );
      }
    }
    if( search_opts[1] ) {
      _connections.get_match_items( pattern, search_opts, ref matches );
    }
  }

  /* Sets the current node to the given node */
  public void set_current_node( Node? n ) {
    if( n == null ) {
      if( _selected.num_nodes() > 0 ) {
        _selected.clear_nodes();
        current_changed( this );
      }
    } else if( _selected.is_node_selected( n ) && (_selected.num_nodes() == 1) ) {
      _selected.nodes().index( 0 ).mode = NodeMode.CURRENT;
    } else {
      _selected.clear_nodes();
      if( (n.parent != null) && n.parent.folded ) {
        var last = n.reveal();
        undo_buffer.add_item( new UndoNodeReveal( this, n, last ) );
      }
      _selected.add_node( n );
      current_changed( this );
    }
  }

  /* Sets the current connection to the given node */
  public void set_current_connection( Connection? c ) {
    _selected.set_current_connection( c );
    c.from_node.last_selected_connection = c;
    c.to_node.last_selected_connection   = c;
    current_changed( this );
  }

  /* Toggles the value of the specified node, if possible */
  public void toggle_task( Node n ) {
    undo_buffer.add_item( new UndoNodeTask( n, true, !n.task_done() ) );
    n.toggle_task_done();
    queue_draw();
    changed();
  }

  /* Toggles the fold for the given node */
  public void toggle_fold( Node n ) {
    bool fold = !n.folded;
    undo_buffer.add_item( new UndoNodeFold( n, fold ) );
    n.folded = fold;
    n.layout.handle_update_by_fold( n );
    queue_draw();
    changed();
  }

  /* Toggles the folding of all selected nodes that can be folded */
  public void toggle_folds() {
    var parents = new Array<Node>();
    _selected.get_parents( ref parents );
    if( parents.length > 0 ) {
      for( int i=0; i<parents.length; i++ ) {
        var node = parents.index( i );
        node.folded = !node.folded;
        node.layout.handle_update_by_fold( node );
      }
      undo_buffer.add_item( new UndoNodesFold( parents ) );
      queue_draw();
      changed();
    }
  }

  /*
   Changes the current node's name to the given name.  Updates the layout,
   adds the undo item, and redraws the canvas.
  */
  public void change_current_node_name( string name ) {
    var nodes = _selected.nodes();
    if( nodes.length == 1 ) {
      var current = nodes.index( 0 );
      if( current.name.text != name ) {
        string orig_name = current.name.text;
        current.name.text = name;
        if( !_current_new ) {
          undo_buffer.add_item( new UndoNodeName( current, orig_name ) );
        }
        queue_draw();
        changed();
      }
    }
  }

  /*
   Changes the current connection's title to the given value.
  */
  public void change_current_connection_title( string title ) {
    var conns = _selected.connections();
    if( conns.length == 1 ) {
      var current = conns.index( 0 );
      if( current.title.text != title ) {
        string? orig_title = (current.title == null) ? null : current.title.text;
        current.change_title( this, title );
        if( !_current_new ) {
          undo_buffer.add_item( new UndoConnectionTitle( current, orig_title ) );
        }
        queue_draw();
        changed();
      }
    }
  }

  /*
   Changes the current node's task to the given values.  Updates the layout,
   adds the undo item, and redraws the canvas.
  */
  public void change_current_task( bool enable, bool done ) {
    var nodes = _selected.nodes();
    if( nodes.length == 1 ) {
      var current = nodes.index( 0 );
      undo_buffer.add_item( new UndoNodeTask( current, enable, done ) );
      current.enable_task( enable );
      current.set_task_done( done );
      queue_draw();
      changed();
    }
  }

  /*
   Changes the current node's folded state to the given value.  Updates the
   layout, adds the undo item and redraws the canvas.
  */
  public void change_current_fold( bool folded ) {
    var nodes = _selected.nodes();
    if( nodes.length == 1 ) {
      var current = nodes.index( 0 );
      undo_buffer.add_item( new UndoNodeFold( current, folded ) );
      current.folded = folded;
      current.layout.handle_update_by_fold( current );
      queue_draw();
      changed();
    }
  }

  /*
   Changes the current node's note to the given value.  Updates the
   layout, adds the undo item and redraws the canvas.
  */
  public void change_current_node_note( string note ) {
    var nodes = _selected.nodes();
    if( nodes.length == 1 ) {
      nodes.index( 0 ).note = note;
      queue_draw();
      auto_save();
    }
  }

  /*
   Changes the current connection's note to the given value.
  */
  public void change_current_connection_note( string note ) {
    var conns = _selected.connections();
    if( conns.length == 1 ) {
      conns.index( 0 ).note = note;
      queue_draw();
      auto_save();
    }
  }

  /*
   Adds an image to the current node by allowing the user to select an image file
   from the file system and, optionally, editing the image prior to assigning it
   to a node.  Updates the layout, adds the undo item and redraws the canvas.
   item and redraws the canvas.
  */
  public void add_current_image() {
    var nodes = _selected.nodes();
    if( nodes.length == 1 ) {
      var current = nodes.index( 0 );
      if( current.image == null ) {
        var parent = (Gtk.Window)get_toplevel();
        var id     = image_manager.choose_image( parent );
        if( id != -1 ) {
          var max_width = current.max_width();
          current.set_image( image_manager, new NodeImage( image_manager, id, max_width ) );
          if( current.image != null ) {
            undo_buffer.add_item( new UndoNodeImage( current, null ) );
            queue_draw();
            current_changed( this );
            auto_save();
          }
        }
      }
    }
  }

  /*
   Deletes the image from the current node.  Updates the layout, adds the undo
   item and redraws the canvas.
  */
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

  /*
   Causes the current node's image to be edited.
  */
  public void edit_current_image() {
    var nodes = _selected.nodes();
    if( nodes.length == 1 ) {
      var current = nodes.index( 0 );
      if( current.image != null ) {
        _editor.edit_image( image_manager, current, current.posx, current.posy );
      }
    }
  }

  /* Called whenever the current node's image is changed */
  private void current_image_edited( NodeImage? orig_image ) {
    var current = _selected.current_node();
    undo_buffer.add_item( new UndoNodeImage( current, orig_image ) );
    queue_draw();
    current_changed( this );
    auto_save();
  }

  /* Called when the linking process has successfully completed */
  private void end_link( Node node ) {
    if( _selected.num_connections() == 0 ) return;
    _selected.clear_connections();
    _last_node.linked_node = node;
    undo_buffer.add_item( new UndoNodeLink( _last_node, null ) );
    _last_connection  = null;
    _last_node        = null;
    _attach_node.mode = NodeMode.NONE;
    _attach_node      = null;
    changed();
    queue_draw();
  }

  /* Creates links between selected nodes */
  public void create_links() {
    if( _selected.num_nodes() < 2 ) return;
    var nodes = _selected.nodes();
    undo_buffer.add_item( new UndoNodesLink( nodes ) );
    for( int i=0; i<(nodes.length - 1); i++ ) {
      nodes.index( i ).linked_node = nodes.index( i + 1 );
    }
    changed();
    queue_draw();
  }

  /* Delete the current node link */
  public void delete_current_link() {
    var current = _selected.current_node();
    if( current != null ) {
      Node? old_link = current.linked_node;
      current.linked_node = null;
      undo_buffer.add_item( new UndoNodeLink( current, old_link ) );
      changed();
      queue_draw();
    }
  }

  /* Toggles the node link */
  private void toggle_link() {
    var current = _selected.current_node();
    if( current != null ) {
      if( current.linked_node == null ) {
        start_connection( true, true );
      } else {
        delete_current_link();
      }
    }
  }

  /*
   Changes the current node's link color and propagates that color to all
   descendants.
  */
  public void change_current_link_color( RGBA color ) {
    var current = _selected.current_node();
    if( current != null ) {
      RGBA orig_color = current.link_color;
      if( orig_color != color ) {
        current.link_color = color;
        undo_buffer.add_item( new UndoNodeLinkColor( current, orig_color ) );
        queue_draw();
        changed();
      }
    }
  }

  /*
   Changes the current connection's color to the specified color.
  */
  public void change_current_connection_color( RGBA color ) {
    var conns = _selected.connections();
    if( conns.length == 1 ) {
      var current = conns.index( 0 );
      RGBA orig_color = current.color;
      if( orig_color != color ) {
        current.color = color;
        undo_buffer.add_item( new UndoConnectionColor( current, orig_color ) );
        queue_draw();
        changed();
      }
    }
  }

  /* Clears the current connection (if it is set) and updates the UI accordingly */
  private void clear_current_connection( bool signal_change ) {
    if( _selected.num_connections() > 0 ) {
      _selected.clear_connections();
      _last_connection = null;
      if( signal_change ) {
        current_changed( this );
      }
    }
  }

  /* Clears the current node (if it is set) and updates the UI accordingly */
  private void clear_current_node( bool signal_change ) {
    if( _selected.num_nodes() > 0 ) {
      _selected.clear_nodes();
      if( signal_change ) {
        current_changed( this );
      }
    }
  }

  /* Called whenever the user clicks on a valid connection */
  private bool set_current_connection_from_position( Connection conn, EventButton e ) {

    var shift = (bool) e.state & ModifierType.SHIFT_MASK;

    if( _selected.is_current_connection( conn ) ) {
      if( conn.mode == ConnMode.EDITABLE ) {
        switch( e.type ) {
          case EventType.BUTTON_PRESS        :  conn.title.set_cursor_at_char( e.x, e.y, shift );  break;
          case EventType.DOUBLE_BUTTON_PRESS :  conn.title.set_cursor_at_word( e.x, e.y, shift );  break;
          case EventType.TRIPLE_BUTTON_PRESS :  conn.title.set_cursor_all( false );                break;
        }
      } else if( e.type == EventType.DOUBLE_BUTTON_PRESS ) {
        var current = _selected.current_connection();
        _orig_title = current.title.text;
        current.edit_title_begin( this );
        current.mode = ConnMode.EDITABLE;
      }
      return( true );
    } else {
      if( shift ) {
        _selected.add_connection( conn );
      } else {
        set_current_connection( conn );
      }
    }

    return( false );

  }

  /* Called whenever the user clicks on node */
  private bool set_current_node_from_position( Node node, EventButton e ) {

    var scaled_x = scale_value( e.x );
    var scaled_y = scale_value( e.y );
    var shift    = (bool) e.state & ModifierType.SHIFT_MASK;
    var control  = (bool) e.state & ModifierType.CONTROL_MASK;
    var dpress   = e.type == EventType.DOUBLE_BUTTON_PRESS;
    var url      = "";
    var left     = 0.0;

    /* Check to see if the user clicked anywhere within the node which is itself a clickable target */
    if( node.is_within_task( scaled_x, scaled_y ) ) {
      toggle_task( node );
      current_changed( this );
      return( false );
    } else if( node.is_within_linked_node( scaled_x, scaled_y ) ) {
      select_linked_node( node );
      return( false );
    } else if( node.is_within_fold( scaled_x, scaled_y ) ) {
      toggle_fold( node );
      current_changed( this );
      return( false );
    } else if( node.is_within_resizer( scaled_x, scaled_y ) ) {
      _resize     = true;
      _orig_width = node.max_width();
      return( true );
    } else if( !shift && control && node.is_within_url( scaled_x, scaled_y, out url, out left ) ) {
      show_url_popover( e, node, url, left );
      _selected.set_current_node( node );
      return( false );
    }

    _orig_side = node.side;
    _orig_info.remove_range( 0, _orig_info.length );
    node.get_node_info( ref _orig_info );
    if( _selected.is_current_node( node ) && !control ) {
      if( node.mode == NodeMode.EDITABLE ) {
        switch( e.type ) {
          case EventType.BUTTON_PRESS        :  node.name.set_cursor_at_char( e.x, e.y, shift );  break;
          case EventType.DOUBLE_BUTTON_PRESS :  node.name.set_cursor_at_word( e.x, e.y, shift );  break;
          case EventType.TRIPLE_BUTTON_PRESS :  node.name.set_cursor_all( false );                break;
        }
      } else if( e.type == EventType.DOUBLE_BUTTON_PRESS ) {
        if( node.is_within_image( scaled_x, scaled_y ) ) {
          edit_current_image();
          return( false );
        } else {
          node.mode = NodeMode.EDITABLE;
        }
      }
      return( true );
    } else {
      _current_new = false;
      if( shift ) {  /* This shift key has an additive, toggling effect */
        if( _selected.remove_node( node ) ) {
          if( control ) {
            if( dpress ) {
              _selected.remove_nodes_at_level( node );
            } else {
              _selected.remove_node_tree( node );
            }
          }
        } else {
          if( control ) {
            if( dpress ) {
              _selected.add_nodes_at_level( node );
            } else {
              _selected.add_node_tree( node );
            }
          } else {
            _selected.add_node( node );
          }
        }

      /*
       The Control key + single click will select the current node tree.
       The Control key + double click will select all nodes at the same level.
      */
      } else if( control ) {
        _selected.set_current_node( node );
        if( dpress ) {
          _selected.add_nodes_at_level( node );
        } else {
          _selected.add_node_tree( node );
        }

      /* Otherwise, just select the current node */
      } else {
        _selected.set_current_node( node );
      }

      if( node.parent != null ) {
        node.parent.last_selected_child = node;
      }
      current_changed( this );
      return( true );
    }

  }

  /*
   Sets the current node pointer to the node that is within the given coordinates.
   Returns true if we sucessfully set current_node to a valid node and made it
   selected.
  */
  private bool set_current_at_position( double x, double y, EventButton e ) {

    var current_conn = _selected.current_connection();

    /* If the user clicked on a selected connection endpoint, disconnect that endpoint */
    if( (current_conn != null) && (current_conn.mode == ConnMode.SELECTED) ) {
      if( current_conn.within_from_handle( x, y ) ) {
        _last_connection = new Connection.from_connection( this, current_conn );
        current_conn.disconnect_from_node( true );
        return( true );
      } else if( current_conn.within_to_handle( x, y ) ) {
        _last_connection = new Connection.from_connection( this, current_conn );
        current_conn.disconnect_from_node( false );
        return( true );
      } else if( current_conn.within_drag_handle( x, y ) ) {
        current_conn.mode = ConnMode.ADJUSTING;
        return( true );
      }
    }

    if( (_attach_node == null) || (current_conn == null) ||
        ((current_conn.mode != ConnMode.CONNECTING) && (current_conn.mode != ConnMode.LINKING)) ) {
      Connection? match_conn = current_conn;
      if( current_conn == null ) {
        if( (match_conn = _connections.within_title( x, y )) == null ) {
          match_conn = _connections.on_curve( x, y );
        }
      } else if( !current_conn.within_drag_handle( x, y ) ) {
        if( (match_conn = _connections.within_title( x, y )) == null ) {
          match_conn = _connections.on_curve( x, y );
        }
      }
      if( match_conn != null ) {
        clear_current_node( false );
        return( set_current_connection_from_position( match_conn, e ) );
      } else {
        for( int i=0; i<_nodes.length; i++ ) {
          var match_node = _nodes.index( i ).contains( x, y, null );
          if( match_node != null ) {
            clear_current_connection( false );
            return( set_current_node_from_position( match_node, e ) );
          }
        }
        clear_current_node( true );
        clear_current_connection( true );
        if( _last_node != null ) {
          _selected.set_current_node( _last_node );
        }
      }
    }

    return( true );

  }

  /* Returns the supported scale points */
  public static double[] get_scale_marks() {
    double[] marks = {10, 25, 50, 75, 100, 150, 200, 250, 300, 350, 400};
    return( marks );
  }

  /* Returns a properly scaled version of the given value */
  private double scale_value( double val ) {
    return( val / sfactor );
  }

  /*
   Sets the scaling factor for the drawing area, causing the center pixel
   to remain in the center and forces a redraw.
  */
  public void set_scaling_factor( double sf ) {
    if( sfactor != sf ) {
      int    width  = get_allocated_width()  / 2;
      int    height = get_allocated_height() / 2;
      double diff_x = (width  / sfactor) - (width  / sf);
      double diff_y = (height / sfactor) - (height / sf);
      move_origin( diff_x, diff_y );
      sfactor = sf;
      scale_changed( sfactor );
    }
  }

  /* Returns the scaling factor based on the given width and height */
  private double get_scaling_factor( double width, double height ) {
    double w  = get_allocated_width() / width;
    double h  = get_allocated_height() / height;
    double sf = (w < h) ? w : h;
    return( (sf > 4) ? 4 : sf );
  }

  /*
   Zooms into the image by one scale mark.  Returns true if the zoom was successful;
   otherwise, returns false.
  */
  public bool zoom_in() {
    var value = sfactor * 100;
    var marks = get_scale_marks();
    if( value < marks[0] ) {
      value = marks[0];
    }
    foreach (double mark in marks) {
      if( value < mark ) {
        animator.add_scale( "zoom in" );
        set_scaling_factor( mark / 100 );
        animator.animate();
        return( true );
      }
    }
    return( false );
  }

  /*
   Zooms out of the image by one scale mark.  Returns true if the zoom was successful;
   otherwise, returns false.
  */
  public bool zoom_out() {
    double value = sfactor * 100;
    var    marks = get_scale_marks();
    double last  = marks[0];
    if( value > marks[marks.length-1] ) {
      value = marks[marks.length-1];
    }
    foreach (double mark in marks) {
      if( value <= mark ) {
        animator.add_scale( "zoom out" );
        set_scaling_factor( last / 100 );
        animator.animate();
        return( true );
      }
      last = mark;
    }
    return( false );
  }

  /*
   Positions the given box in the canvas based on the provided
   x and y positions (values between 0 and 1).
  */
  private void position_box( double x, double y, double w, double h, double xpos, double ypos ) {
    double ccx = scale_value( get_allocated_width()  * xpos );
    double ccy = scale_value( get_allocated_height() * ypos );
    double ncx = x + (w * xpos);
    double ncy = y + (h * ypos);
    move_origin( (ncx - ccx), (ncy - ccy) );
  }

  /*
   Returns the scaling factor required to display the currently selected node.
   If no node is currently selected, returns a value of 0.
  */
  public void zoom_to_selected() {
    var current = _selected.current_node();
    if( current == null ) return;
    animator.add_pan_scale( "zoom to selected" );
    var nb = current.tree_bbox;
    position_box( nb.x, nb.y, nb.width, nb.height, 0.5, 0.5 );
    set_scaling_factor( get_scaling_factor( nb.width, nb.height ) );
    animator.animate();
  }

  /* Figures out the boundaries of the document primarily for the purposes of printing */
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

    /* Set the outputs */
    x      = x1;
    y      = y1;
    width  = (x2 - x1);
    height = (y2 - y1);

  }

  /* Returns the scaling factor required to display all nodes */
  public void zoom_to_fit() {

    animator.add_scale( "zoom to fit" );

    /* Get the document rectangle */
    double x, y, w, h;
    document_rectangle( out x, out y, out w, out h );

    /* Center the map and scale it to fit */
    position_box( x, y, w, h, 0.5, 0.5 );
    set_scaling_factor( get_scaling_factor( w, h ) );

    /* Animate the scaling */
    animator.animate();

  }

  /* Scale to actual size */
  public void zoom_actual() {

    /* Start animation */
    animator.add_scale( "action_zoom_actual" );

    /* Scale to a full scale */
    set_scaling_factor( 1.0 );

    /* Animate the scaling */
    animator.animate();

  }

  /* Centers the given node within the canvas by adjusting the origin */
  public void center_node( Node n ) {
    double x, y, w, h;
    n.bbox( out x, out y, out w, out h );
    animator.add_pan( "center node" );
    position_box( x, y, w, h, 0.5, 0.5 );
    animator.animate();
  }

  /* Centers the currently selected node */
  public void center_current_node() {
    var current = _selected.current_node();
    if( current != null ) {
      center_node( current );
    }
  }

  /* Brings the given node into view in its entirety including the given amount of padding */
  public void see( double width_adjust = 0, double pad = 100.0 ) {

    double x, y, w, h;

    var current_conn = _selected.current_connection();
    var current_node = _selected.current_node();

    if( current_conn != null ) {
      current_conn.bbox( out x, out y, out w, out h );
    } else if( current_node != null ) {
      current_node.bbox( out x, out y, out w, out h );
    } else {
      return;
    }

    double diff_x = 0;
    double diff_y = 0;
    double sw     = scale_value( get_allocated_width() + width_adjust );
    double sh     = scale_value( get_allocated_height() );
    double sf     = get_scaling_factor( (w + (pad * 2)), (h + (pad * 2)) );

    if( (x - pad) < 0 ) {
      diff_x = (x - pad);
    } else if( (x + w) > sw ) {
      diff_x = (x + w + pad) - sw;
    }

    if( (y - pad) < 0 ) {
      diff_y = (y - pad);
    } else if( (y + h) > sh ) {
      diff_y = (y + h + pad) - sh;
    }

    if( (diff_x != 0) || (diff_y != 0) ) {
      if( sf >= sfactor ) {
        animator.add_pan( "see" );
        move_origin( diff_x, diff_y );
      } else {
        animator.add_pan_scale( "see" );
        sfactor = sf;
        scale_changed( sfactor );
        move_origin( diff_x, diff_y );
      }
      animator.animate();
    }

  }

  /* Returns the attachable node if one is found */
  private Node? attachable_node( double x, double y ) {
    var current = _selected.current_node();
    for( int i=0; i<_nodes.length; i++ ) {
      Node tmp = _nodes.index( i ).contains( x, y, current );
      if( (tmp != null) && (tmp != current.parent) && !current.contains_node( tmp ) ) {
        return( tmp );
      }
    }
    return( null );
  }

  /* Returns the droppable node if one is found */
  private Node? droppable_node( double x, double y ) {
    for( int i=0; i<_nodes.length; i++ ) {
      Node tmp = _nodes.index( i ).contains( x, y, null );
      if( tmp != null ) {
        return( tmp );
      }
    }
    return( null );
  }

  /* Returns the origin */
  public void get_origin( out double x, out double y ) {
    x = origin_x;
    y = origin_y;
  }

  /* Sets the origin to the given x and y coordinates */
  public void set_origin( double x, double y ) {
    move_origin( (x - origin_x), (y - origin_y) );
  }

  /* Checks to see if the boundary of the map never goes out of view */
  private bool out_of_bounds( double diff_x, double diff_y ) {

    double x, y, w, h;
    double aw = scale_value( get_allocated_width() );
    double ah = scale_value( get_allocated_height() );
    double s  = 40;

    document_rectangle( out x, out y, out w, out h );

    x -= diff_x;
    y -= diff_y;

    return( ((x + w) < s) || ((y + h) < s) || ((aw - x) < s) || ((ah - y) < s) );

  }

  /*
   Adjusts the x and y origins, panning all elements by the given amount.
   Important Note:  When the canvas is panned to the left (causing all
   nodes to be moved to the left, the origin_x value becomes a positive
   number.
  */
  public void move_origin( double diff_x, double diff_y ) {
    if( out_of_bounds( diff_x, diff_y ) ) {
      return;
    }
    origin_x += diff_x;
    origin_y += diff_y;
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).pan( -diff_x, -diff_y );
    }
  }

  /* Draw the background from the stylesheet */
  public void draw_background( Context ctx ) {
    get_style_context().render_background( ctx, 0, 0, (get_allocated_width() / _scale_factor), (get_allocated_height() / _scale_factor) );
  }

  /* Draws all of the root node trees */
  public void draw_all( Context ctx ) {
    var current_node = _selected.current_node();
    var current_conn = _selected.current_connection();
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).draw_all( ctx, _theme, current_node, false, false );
    }
    /* Draw the current node on top of all others */
    if( (current_node != null) && ((current_node.parent == null) || !current_node.parent.folded) ) {
      current_node.draw_all( ctx, _theme, null, true, (!is_node_editable() && _pressed && _motion && !_resize) );
    }
    /* Draw the current connection on top of everything else */
    _connections.draw_all( ctx, _theme );
    if( current_conn != null ) {
      current_conn.draw( ctx, _theme );
    }
  }

  /* Draw the available nodes */
  public bool on_draw( Context ctx ) {
    ctx.scale( sfactor, sfactor );
    draw_background( ctx );
    draw_all( ctx );
    return( false );
  }

  /* Displays the contextual menu based on what is currently selected */
  private void show_contextual_menu( EventButton event ) {

    var current_node = _selected.current_node();
    var current_conn = _selected.current_connection();

#if GTK322
    if( current_node != null ) {
      if( current_node.mode == NodeMode.EDITABLE ) {
        _text_menu.popup_at_pointer( event );
      } else {
        _node_menu.popup_at_pointer( event );
      }
    } else if( _selected.num_nodes() > 1 ) {
      _nodes_menu.popup_at_pointer( event );
    } else if( current_conn != null ) {
      _conn_menu.popup_at_pointer( event );
    } else if( _selected.num_connections() > 1 ) {
      _conns_menu.popup_at_pointer( event );
    } else {
      _empty_menu.popup_at_pointer( event );
    }
#else
    if( current_node != null ) {
      if( current_node.mode == NodeMode.EDITABLE ) {
        _text_menu.popup( null, null, null, event.button, event.time );
      } else {
        _node_menu.popup( null, null, null, event.button, event.time );
      }
    } else if( _selected.num_nodes() > 1 ) {
      _nodes_menu.popup( null, null, null, event.button, event.time );
    } else if( current_conn != null ) {
      _conn_menu.popup( null, null, null, event.button, event.time );
    } else if( _selected.num_connections() > 1 ) {
      _conns_menu.popup( null, null, null, event.button, event.time );
    } else {
      _empty_menu.popup( null, null, null, event.button, event.time );
    }
#endif

  }

  /* Handle button press event */
  private bool on_press( EventButton event ) {
    switch( event.button ) {
      case Gdk.BUTTON_PRIMARY :
        grab_focus();
        _press_x    = scale_value( event.x );
        _press_y    = scale_value( event.y );
        _pressed    = set_current_at_position( _press_x, _press_y, event );
        _press_type = event.type;
        _motion     = false;
        queue_draw();
        break;
      case Gdk.BUTTON_SECONDARY :
        show_contextual_menu( event );
        break;
    }
    return( false );
  }

  /* Handle mouse motion */
  private bool on_motion( EventMotion event ) {

    /* If the node is attached, clear it */
    if( _attach_node != null ) {
      _attach_node.mode = NodeMode.NONE;
      _attach_node      = null;
      queue_draw();
    }

    double scaled_x = scale_value( event.x );
    double scaled_y = scale_value( event.y );

    var current_node = _selected.current_node();
    var current_conn = _selected.current_connection();

    /* If the mouse button is current pressed, handle it */
    if( _pressed ) {

      /* If we are dealing with a connection, update it based on its mode */
      if( current_conn != null ) {
        switch( current_conn.mode ) {
          case ConnMode.ADJUSTING :
            current_conn.move_drag_handle( scaled_x, scaled_y );
            queue_draw();
            break;
          case ConnMode.CONNECTING :
          case ConnMode.LINKING    :
            update_connection( event.x, event.y );
            for( int i=0; i<_nodes.length; i++ ) {
              Node? match = _nodes.index( i ).contains( scaled_x, scaled_y, null );
              if( match != null ) {
                _attach_node      = match;
                _attach_node.mode = NodeMode.ATTACHABLE;
                break;
              }
            }
            break;
        }

      /* If we are dealing with a node, handle it based on its mode */
      } else if( current_node != null ) {
        double diffx = scaled_x - _press_x;
        double diffy = scaled_y - _press_y;
        if( current_node.mode == NodeMode.CURRENT ) {
          if( _resize ) {
            current_node.resize( diffx );
            auto_save();
          } else {
            Node attach_node = attachable_node( scaled_x, scaled_y );
            if( attach_node != null ) {
              attach_node.mode = NodeMode.ATTACHABLE;
              _attach_node = attach_node;
            }
            current_node.posx += diffx;
            current_node.posy += diffy;
            current_node.layout.set_side( current_node );
          }
        } else {
          switch( _press_type ) {
            case EventType.BUTTON_PRESS        :  current_node.name.set_cursor_at_char( scaled_x, scaled_y, true );  break;
            case EventType.DOUBLE_BUTTON_PRESS :  current_node.name.set_cursor_at_word( scaled_x, scaled_y, true );  break;
          }
        }
        queue_draw();

      /* Otherwise, we are panning the canvas */
      } else {
        double diff_x = _press_x - scaled_x;
        double diff_y = _press_y - scaled_y;
        move_origin( diff_x, diff_y );
        queue_draw();
        auto_save();
      }
      if( !_motion && !_resize && (current_node != null) ) {
        current_node.alpha = 0.3;
      }
      _press_x = scaled_x;
      _press_y = scaled_y;
      _motion  = true;
    } else {
      if( current_conn != null )  {
        if( (current_conn.mode == ConnMode.CONNECTING) || (current_conn.mode == ConnMode.LINKING) ) {
          update_connection( event.x, event.y );
        }
        if( current_conn.within_drag_handle( scaled_x, scaled_y ) ||
            current_conn.within_from_handle( scaled_x, scaled_y ) ||
            current_conn.within_to_handle( scaled_x, scaled_y ) ) {
          set_cursor_from_name( "move" );
          return( false );
        } else if( current_conn.within_note( scaled_x, scaled_y ) ) {
          set_tooltip_markup( current_conn.note );
          return( false );
        }
      } else {
        Connection? match_conn = _connections.within_note( scaled_x, scaled_y );
        if( match_conn != null ) {
          set_tooltip_markup( match_conn.note );
          return( false );
        }
      }
      for( int i=0; i<_nodes.length; i++ ) {
        Node match = _nodes.index( i ).contains( scaled_x, scaled_y, null );
        if( match != null ) {
          if( (current_conn != null) && ((current_conn.mode == ConnMode.CONNECTING) || (current_conn.mode == ConnMode.LINKING)) ) {
            _attach_node      = match;
            _attach_node.mode = NodeMode.ATTACHABLE;
          } else if( match.is_within_task( scaled_x, scaled_y ) ) {
            set_cursor( CursorType.HAND1 );
            set_tooltip_markup( _( "%0.3g%% complete" ).printf( match.task_completion_percentage() ) );
          } else if( match.is_within_note( scaled_x, scaled_y ) ) {
            set_tooltip_markup( match.note );
          } else if( match.is_within_linked_node( scaled_x, scaled_y ) ) {
            set_cursor( CursorType.HAND1 );
          } else if( match.is_within_resizer( scaled_x, scaled_y ) ) {
            set_cursor( CursorType.SB_H_DOUBLE_ARROW );
            set_tooltip_markup( null );
          } else {
            set_cursor( null );
            set_tooltip_markup( null );
          }
          return( false );
        }
      }
      set_cursor( null );
      set_tooltip_markup( null );
    }
    return( false );
  }

  /* Handle button release event */
  private bool on_release( EventButton event ) {

    var current_node = _selected.current_node();
    var current_conn = _selected.current_connection();

    _pressed = false;

    /* Return the cursor to the default cursor */
    if( _motion ) {
      set_cursor( null );
    }

    /* If we were resizing a node, end the resize */
    if( _resize ) {
      _resize = false;
      undo_buffer.add_item( new UndoNodeResize( current_node, _orig_width ) );
      return( false );
    }

    /* If a connection is selected, deal with the possibilities */
    if( current_conn != null ) {

      /* If the connection end is released on an attachable node, attach the connection to the node */
      if( _attach_node != null ) {
        if( current_conn.mode == ConnMode.LINKING ) {
          end_link( _attach_node );
        } else {
          end_connection( _attach_node );
          if( _last_connection != null ) {
            undo_buffer.add_item( new UndoConnectionChange( _( "connection endpoint change" ), _last_connection, current_conn ) );
          }
        }
        _last_connection = null;

      /* If we were dragging the connection midpoint, change the connection mode to SELECTED */
      } else if( current_conn.mode == ConnMode.ADJUSTING ) {
        undo_buffer.add_item( new UndoConnectionChange( _( "connection drag" ), _last_connection, current_conn ) );
        _selected.set_current_connection( current_conn );
        auto_save();

      /* If we were dragging a connection end and failed to attach it to a node, return the connection to where it was prior to the drag */
      } else if( _last_connection != null ) {
        current_conn.copy( this, _last_connection );
        _last_connection = null;
      }

      queue_draw();

    /* If a node is selected, deal with the possibilities */
    } else if( current_node != null ) {

      if( current_node.mode == NodeMode.CURRENT ) {

        /* If we are hovering over an attach node, perform the attachment */
        if( _attach_node != null ) {
          attach_current_node();

        /* If we are not in motion, set the cursor */
        } else if( !_motion ) {
          current_node.name.set_cursor_all( false );
          _orig_name = current_node.name.text;
          current_node.name.move_cursor_to_end();

        /* If we are not a root node, move the node into the appropriate position */
        } else if( current_node.parent != null ) {
          int orig_index = current_node.index();
          animator.add_nodes( "move to position" );
          current_node.parent.move_to_position( current_node, _orig_side, scale_value( event.x ), scale_value( event.y ) );
          undo_buffer.add_item( new UndoNodeMove( current_node, _orig_side, orig_index ) );
          animator.animate();

        /* Otherwise, redraw everything after the move */
        } else {
          queue_draw();
        }

      }

    }

    /* If motion is set, clear it and clear the alpha */
    if( _motion ) {
      if( current_node != null ) {
        current_node.alpha = 1.0;
      }
      _motion = false;
    }

    return( false );

  }

  /* Attaches the current node to the attach node */
  private void attach_current_node() {

    Node? orig_parent = null;
    var   orig_index  = -1;
    var   current     = _selected.current_node();
    var   isroot      = current.is_root();

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
      orig_parent = current.parent;
      orig_index  = current.index();
      current.detach( _orig_side );
    }

    /* Attach the node */
    current.attach( _attach_node, -1, _theme );
    _attach_node.mode = NodeMode.NONE;
    _attach_node      = null;

    /* Add the attachment information to the undo buffer */
    if( isroot ) {
      undo_buffer.add_item( new UndoNodeAttach.for_root( current, orig_index, _orig_info ) );
    } else {
      undo_buffer.add_item( new UndoNodeAttach( current, orig_parent, _orig_side, orig_index, _orig_info ) );
    }

    queue_draw();
    changed();
    current_changed( this );

  }

  /* Returns true if we are connecting a connection title */
  public bool is_connection_connecting() {
    var current = _selected.current_connection();
    return( (current != null) && (current.mode == ConnMode.CONNECTING) );
  }

  /* Returns true if we are editing a connection title */
  public bool is_connection_editable() {
    var current = _selected.current_connection();
    return( (current != null) && (current.mode == ConnMode.EDITABLE) );
  }

  /* Returns true if the current connection is in the selected state */
  public bool is_connection_selected() {
    var current = _selected.current_connection();
    return( (current != null) && (current.mode == ConnMode.SELECTED) );
  }

  /* Returns true if we are in node edit mode */
  public bool is_node_editable() {
    var current = _selected.current_node();
    return( (current != null) && (current.mode == NodeMode.EDITABLE) );
  }

  /* Returns true if we are in node selected mode */
  public bool is_node_selected() {
    var current = _selected.current_node();
    return( (current != null) && (current.mode == NodeMode.CURRENT) );
  }

  /* Returns the next node to select after the current node is removed */
  private Node? next_node_to_select() {
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

  /* If the specified node is not null, selects the node and makes it the current node */
  private bool select_node( Node? n ) {
    if( n != null ) {
      if( n != _selected.current_node() ) {
        _selected.set_current_node( n, (_focus_mode ? _focus_alpha : 1.0) );
        _current_new = false;
        update_focus_mode();
        if( n.parent != null ) {
          n.parent.last_selected_child = n;
        }
        see();
        current_changed( this );
      }
      return( true );
    }
    return( false );
  }

  /* Returns true if there is a root that is available for selection */
  public bool root_selectable() {
    var current_node = _selected.current_node();
    var current_conn = _selected.current_connection();
    return( (current_conn == null) && ((current_node == null) ? (_nodes.length > 0) : (current_node.get_root() != current_node)) );
  }

  /*
   If there is no current node, selects the first root node; otherwise, selects
   the current node's root node.
  */
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

  /* Returns true if there is a sibling available for selection */
  public bool sibling_selectable() {
    var current = _selected.current_node();
    return( (current != null) && (current.is_root() ? (_nodes.length > 1) : (current.parent.children().length > 1)) );
  }

  /* Returns the sibling node in the given direction of the current node */
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

  /* Selects the next (dir = 1) or previous (dir = -1) sibling */
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

  /* Returns true if there is a child node of the current node */
  public bool child_selectable() {
    var current = _selected.current_node();
    return( (current != null) && !current.is_leaf() && !current.folded );
  }

  /* Selects the last selected child node of the current node */
  public void select_child_node() {
    var current = _selected.current_node();
    if( (current != null) && !current.is_leaf() && !current.folded ) {
      if( select_node( current.last_selected_child ?? current.children().index( 0 ) ) ) {
        queue_draw();
      }
    }
  }

  /* Returns true if there is a parent node of the current node */
  public bool parent_selectable() {
    var current = _selected.current_node();
    return( (current != null) && !current.is_root() );
  }

  /* Selects the parent node of the current node */
  public void select_parent_node() {
    var current = _selected.current_node();
    if( (current != null) && !current.is_root() ) {
      if( select_node( current.parent ) ) {
        queue_draw();
      }
    }
  }

  /* Selects the node that is linked to this node */
  public void select_linked_node( Node? node = null ) {
    var n = node;
    if( n == null ) {
      n = _selected.current_node();
    }
    if( (n != null) && (n.linked_node != null) ) {
      if( select_node( n.linked_node ) ) {
        queue_draw();
      }
    }
  }

  /* Selects the given connection node */
  public void select_connection_node( bool start ) {
    var current = _selected.current_connection();
    if( current != null ) {
      if( select_node( start ? current.from_node : current.to_node ) ) {
        clear_current_connection( true );
        queue_draw();
      }
    }
  }

  /* Selects the next connection in the list */
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

  /* Selects the first connection in the list */
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

  /* Deletes the given node */
  public void delete_node() {
    var current = _selected.current_node();
    if( current == null ) return;
    Node? next_node = next_node_to_select();
    var   conns     = new Array<Connection>();
    _connections.node_deleted( current, conns );
    if( current.is_root() ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) == current ) {
          undo_buffer.add_item( new UndoNodeDelete( current, i, conns ) );
          _nodes.remove_index( i );
          break;
        }
      }
    } else {
      undo_buffer.add_item( new UndoNodeDelete( current, current.index(), conns ) );
      current.delete();
    }
    _selected.remove_node( current );
    current_changed( this );
    select_node( next_node );
    queue_draw();
    changed();
  }

  /* Deletes all selected nodes */
  public void delete_nodes() {
    if( _selected.num_nodes() == 0 ) return;
    var nodes = _selected.nodes();
    var conns = new Array<Connection>();
    for( int i=0; i<nodes.length; i++ ) {
      _connections.node_only_deleted( nodes.index( i ), conns );
    }
    undo_buffer.add_item( new UndoNodesDelete( nodes, conns ) );
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).delete_only();
    }
    _selected.clear_nodes();
    current_changed( this );
    queue_draw();
    changed();
  }

  /* Called whenever the backspace character is entered in the drawing area */
  private void handle_backspace() {
    if( is_connection_editable() ) {
      _selected.current_connection().title.backspace();
      queue_draw();
      changed();
    } else if( is_connection_selected() ) {
      delete_connection();
    } else if( _selected.num_connections() > 0 ) {
      delete_connections();
    } else if( is_node_editable() ) {
      _selected.current_node().name.backspace();
      queue_draw();
      changed();
    } else if( is_node_selected() ) {
      Node? next;
      var   current = _selected.current_node();
      if( ((next = sibling_node( 1 )) == null) && ((next = sibling_node( -1 )) == null) && current.is_root() ) {
        delete_node();
      } else {
        if( next == null ) {
          next = current.parent;
        }
        delete_node();
        if( select_node( next ) ) {
          queue_draw();
        }
      }
    } else if( _selected.num_nodes() > 0 ) {
      delete_nodes();
    }
  }

  /* Called whenever the delete character is entered in the drawing area */
  private void handle_delete() {
    if( is_connection_editable() ) {
      _selected.current_connection().title.delete();
      queue_draw();
      changed();
    } else if( is_connection_selected() ) {
      delete_connection();
    } else if( _selected.num_connections() > 0 ) {
      delete_connections();
    } else if( is_node_editable() ) {
      _selected.current_node().name.delete();
      queue_draw();
      changed();
    } else if( is_node_selected() ) {
      delete_node();
    } else if( _selected.num_nodes() > 0 ) {
      delete_nodes();
    }
  }

  /* Called whenever the escape character is entered in the drawing area */
  private void handle_escape() {
    if( is_connection_editable() ) {
      var current = _selected.current_connection();
      _im_context.reset();
      current.edit_title_end();
      undo_buffer.add_item( new UndoConnectionTitle( current, _orig_title ) );
      current.mode = ConnMode.SELECTED;
      current_changed( this );
      queue_draw();
    } else if( is_node_editable() ) {
      var current = _selected.current_node();
      _im_context.reset();
      if( !_current_new ) {
        undo_buffer.add_item( new UndoNodeName( current, _orig_name ) );
      }
      current.mode = NodeMode.CURRENT;
      current_changed( this );
      queue_draw();
    } else if( is_connection_connecting() ) {
      var current = _selected.current_connection();
      _connections.remove_connection( current, true );
      _selected.remove_connection( current );
      if( _attach_node != null ) {
        _attach_node.mode = NodeMode.NONE;
        _attach_node      = null;
      }
      _selected.set_current_node( _last_node );
      _last_connection = null;
      queue_draw();
    } else if( is_node_selected() ) {
      hide_properties();
    }
  }

  /* Adds a new root node to the canvas */
  public void add_root_node() {
    var node = new Node.with_name( this, _( "Another Idea" ), _nodes.index( 0 ).layout );
    node.style = StyleInspector.styles.get_global_style();
    if (_nodes.length == 0) {
      node.posx = (get_allocated_width()  / 2) - 30;
      node.posy = (get_allocated_height() / 2) - 10;
    } else {
      _nodes.index( _nodes.length - 1 ).layout.position_root( _nodes.index( _nodes.length - 1 ), node );
    }
    _nodes.append_val( node );
    if( select_node( node ) ) {
      node.mode = NodeMode.EDITABLE;
      _current_new = true;
      queue_draw();
    }
    see();
    changed();
  }

  /* Adds a new sibling node to the current node */
  public void add_sibling_node() {
    var node    = new Node( this, layouts.get_default() );
    var current = _selected.current_node();
    _orig_name = "";
    node.side          = current.side;
    node.style         = current.style;
    node.style         = StyleInspector.styles.get_style_for_level( current.get_level(), current.style );
    node.attach( current.parent, (current.index() + 1), _theme );
    undo_buffer.add_item( new UndoNodeInsert( node ) );
    set_current_node( node );
    node.mode = NodeMode.EDITABLE;
    _current_new = true;
    queue_draw();
    see();
    changed();
  }

  /* Called whenever the return character is entered in the drawing area */
  private void handle_return() {
    if( is_connection_editable() ) {
      var current = _selected.current_connection();
      current.edit_title_end();
      undo_buffer.add_item( new UndoConnectionTitle( current, _orig_title ) );
      current.mode = ConnMode.SELECTED;
      current_changed( this );
      queue_draw();
    } else if( is_node_editable() ) {
      var current = _selected.current_node();
      if( !_current_new ) {
        undo_buffer.add_item( new UndoNodeName( current, _orig_name ) );
      }
      current.mode = NodeMode.CURRENT;
      if( _create_new_from_edit ) {
        if( !current.is_root() ) {
          add_sibling_node();
        } else {
          add_root_node();
        }
      } else {
        current_changed( this );
        queue_draw();
      }
    } else if( is_connection_connecting() && (_attach_node != null) ) {
      end_connection( _attach_node );
    } else if( is_node_selected() ) {
      if( !_selected.current_node().is_root() ) {
        add_sibling_node();
      } else {
        add_root_node();
      }
    }
  }

  /* Called whenever the user hits a Control-Return key.  Causes a newline to be inserted */
  private void handle_control_return() {
    if( is_connection_editable() ) {
      _selected.current_connection().title.insert( "\n" );
      current_changed( this );
      queue_draw();
    } else if( is_node_editable() ) {
      _selected.current_node().name.insert( "\n" );
      see();
      current_changed( this );
      queue_draw();
    }
  }

  /* Returns the index of the given root node */
  public int root_index( Node root ) {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ) == root ) {
        return( i );
      }
    }
    return( -1 );
  }

  /* Adds the given node to the list of root nodes */
  public void add_root( Node n, int index ) {
    if( index == -1 ) {
      _nodes.append_val( n );
    } else {
      _nodes.insert_val( index, n );
    }
  }

  /* Removes the node at the given root index from the list of root nodes */
  public void remove_root( int index ) {
    _nodes.remove_index( index );
  }

  /* Removes the given root node from the node array */
  public void remove_root_node( Node node ) {
    for( int i=0; i<_nodes.length; i++ ) {
      if( _nodes.index( i ) == node ) {
        _nodes.remove_index( i );
        return;
      }
    }
  }

  /* Returns true if the drawing area has a node that is available for detaching */
  public bool detachable() {
    var current = _selected.current_node();
    return( (current != null) && (current.parent != null) );
  }

  /* Detaches the current node from its parent and adds it as a root node */
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
    changed();
  }

  /* Balances the existing nodes based on the current layout */
  public void balance_nodes( bool undoable = true ) {
    var current   = _selected.current_node();
    var root_node = (current == null) ? null : current.get_root();
    if( undoable ) {
      undo_buffer.add_item( new UndoNodeBalance( this, root_node ) );
    }
    if( (current == null) || !undoable ) {
      animator.add_nodes( "balance nodes" );
      for( int i=0; i<_nodes.length; i++ ) {
        var partitioner = new Partitioner();
        partitioner.partition_node( _nodes.index( i ) );
      }
    } else {
      animator.add_node( root_node, "balance tree" );
      var partitioner = new Partitioner();
      partitioner.partition_node( root_node );
    }
    animator.animate();
    grab_focus();
  }

  /* Returns true if there is at least one node that can be folded due to completed tasks */
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

  /* Folds all completed tasks found in any tree */
  public void fold_completed_tasks() {
    var changes = new Array<Node>();
    var current = _selected.current_node();
    if( current == null ) {
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).fold_completed_tasks( ref changes );
      }
    } else {
      current.get_root().fold_completed_tasks( ref changes );
    }
    if( changes.length > 0 ) {
      for( int i=0; i<changes.length; i++ ) {
        changes.index( i ).layout.handle_update_by_fold( changes.index( i ) );
      }
      undo_buffer.add_item( new UndoNodeFoldChanges( _( "fold completed tasks" ), changes, true ) );
      queue_draw();
      changed();
      current_changed( this );
    }
  }

  /* Returns true if there is at least one node that is unfoldable */
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

  /* Unfolds all nodes in the document */
  public void unfold_all_nodes() {
    var changes = new Array<Node>();
    var current = _selected.current_node();
    if( current != null ) {
      current.get_root().set_fold( false, ref changes );
    } else {
      for( int i=0; i<_nodes.length; i++ ) {
        _nodes.index( i ).set_fold( false, ref changes );
      }
    }
    if( changes.length > 0 ) {
      for( int i=0; i<changes.length; i++ ) {
        changes.index( i ).layout.handle_update_by_fold( changes.index( i ) );
      }
      undo_buffer.add_item( new UndoNodeFoldChanges( _( "unfold all tasks" ), changes, false ) );
      queue_draw();
      changed();
      current_changed( this );
    }
  }

  /*
   Re-parents a node by creating a new node whose parent matches the current node's parent
   and then makes the current node's parent match the new node.
  */
  public void add_parent_node() {
    var current = _selected.current_node();
    if( current.is_root() ) return;
    var node  = new Node( this, layouts.get_default() );
    var color = current.link_color;
    node.side       = current.side;
    node.style      = StyleInspector.styles.get_style_for_level( current.get_level(), current.style );
    node.attach( current.parent, current.index(), null );
    node.link_color = color;
    current.detach( node.side );
    current.attach( node, -1, null );
    undo_buffer.add_item( new UndoNodeAddParent( node, current ) );
    set_current_node( node );
    node.mode = NodeMode.EDITABLE;
    queue_draw();
    see();
    changed();
  }

  /* Adds a child node to the current node */
  public void add_child_node() {
    var node    = new Node( this, layouts.get_default() );
    var current = _selected.current_node();
    _orig_name = "";
    if( !current.is_root() ) {
      node.side = current.side;
    }
    if( current.children().length > 0 ) {
      node.style = current.last_child().style;
    } else {
      node.style = current.style;
    }
    node.style = StyleInspector.styles.get_style_for_level( (current.get_level() + 1), current.style );
    node.attach( current, -1, _theme );
    undo_buffer.add_item( new UndoNodeInsert( node ) );
    current.folded = false;
    current.layout.handle_update_by_fold( current );
    set_current_node( node );
    node.mode = NodeMode.EDITABLE;
    queue_draw();
    see();
    changed();
  }

  /* Called whenever the tab character is entered in the drawing area */
  private void handle_tab() {
    if( is_node_editable() ) {
      var current = _selected.current_node();
      if( !_current_new ) {
        undo_buffer.add_item( new UndoNodeName( current, _orig_name ) );
      }
      current.mode = NodeMode.CURRENT;
      if( _create_new_from_edit ) {
        add_child_node();
      } else {
        current_changed( this );
        queue_draw();
      }
    } else if( is_node_selected() ) {
      add_child_node();
    }
  }

  /*
   Called whenever the Control-Tab key combo is entered.  Causes a tabe character
   to be inserted into the title.
  */
  private void handle_control_tab() {
    if( is_node_editable() ) {
      _selected.current_node().name.insert( "\t" );
      see();
      current_changed( this );
      queue_draw();
    }
  }

  /* Returns the node to the right of the given node */
  private Node? get_node_right( Node node ) {
    if( node.is_root() ) {
      return( node.last_selected_child ?? node.first_child( NodeSide.RIGHT ) );
    } else {
      switch( node.side ) {
        case NodeSide.TOP    :
        case NodeSide.BOTTOM :  return( node.parent.next_child( node ) );
        case NodeSide.LEFT   :  return( node.parent );
        default              :  return( node.last_selected_child ?? node.first_child( NodeSide.RIGHT ) );
      }
    }
  }

  /* Returns the node to the left of the given node */
  private Node? get_node_left( Node node ) {
    if( node.is_root() ) {
      return( node.last_selected_child ?? node.first_child( NodeSide.LEFT ) );
    } else {
      switch( node.side ) {
        case NodeSide.TOP :
        case NodeSide.BOTTOM :  return( node.parent.prev_child( node ) );
        case NodeSide.LEFT   :  return( node.last_selected_child ?? node.first_child( NodeSide.LEFT ) );
        default              :  return( node.parent );
      }
    }
  }

  /* Returns the node above the given node */
  private Node? get_node_up( Node node ) {
    if( node.is_root() ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) == node ) {
          return( (i > 0) ? _nodes.index( i - 1 ) : null );
        }
      }
      return( null );
    } else {
      switch( node.side ) {
        case NodeSide.TOP    :  return( node.last_selected_child ?? node.first_child( NodeSide.TOP ) );
        case NodeSide.BOTTOM :  return( node.parent );
        default              :  return( node.parent.prev_child( node ) );
      }
    }
  }

  /* Returns the node below the given node */
  private Node? get_node_down( Node node ) {
    if( node.is_root() ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) == node ) {
          return( ((i + 1) < _nodes.length) ? _nodes.index( i + 1 ) : null );
        }
      }
      return( null );
    } else {
      switch( node.side ) {
        case NodeSide.TOP    :  return( node.parent );
        case NodeSide.BOTTOM :  return( node.last_selected_child ?? node.first_child( NodeSide.BOTTOM ) );
        default              :  return( node.parent.next_child( node ) );
      }
    }
  }

  /* Returns the node at the top of the sibling list */
  private Node? get_node_pageup( Node node ) {
    if( node.is_root() ) {
      return( (_nodes.length > 0) ? _nodes.index( 0 ) : null );
    } else {
      return( node.parent.first_child() );
    }
  }

  /* Returns the node at the top of the sibling list */
  private Node? get_node_pagedn( Node node ) {
    if( node.is_root() ) {
      return( (_nodes.length > 0) ? _nodes.index( _nodes.length - 1 ) : null );
    } else {
      return( node.parent.last_child() );
    }
  }

  /* Called whenever the right key is entered in the drawing area */
  private void handle_right( bool shift ) {
    if( is_connection_editable() ) {
      if( shift ) {
        _selected.current_connection().title.selection_by_char( 1 );
      } else {
        _selected.current_connection().title.move_cursor( 1 );
      }
      queue_draw();
    } else if( is_node_editable() ) {
      if( shift ) {
        _selected.current_node().name.selection_by_char( 1 );
      } else {
        _selected.current_node().name.move_cursor( 1 );
      }
      queue_draw();
    } else if( is_connection_connecting() && (_attach_node != null) ) {
      update_connection_by_node( get_node_right( _attach_node ) );
    } else if( is_connection_selected() ) {
      select_connection( 1 );
    } else if( is_node_selected() ) {
      if( select_node( get_node_right( _selected.current_node() ) ) ) {
        queue_draw();
      }
    }
  }

  /*
   Called whenever the Control-right key combo is entered.  Moves the cursor
   one word to the right.
  */
  private void handle_control_right( bool shift ) {
    if( is_connection_editable() ) {
      if( shift ) {
        _selected.current_connection().title.selection_by_word( 1 );
      } else {
        _selected.current_connection().title.move_cursor_by_word( 1 );
      }
      queue_draw();
    } else if( is_node_editable() ) {
      if( shift ) {
        _selected.current_node().name.selection_by_word( 1 );
      } else {
        _selected.current_node().name.move_cursor_by_word( 1 );
      }
      queue_draw();
    }
  }

  /* Called whenever the left key is entered in the drawing area */
  private void handle_left( bool shift ) {
    if( is_connection_editable() ) {
      if( shift ) {
        _selected.current_connection().title.selection_by_char( -1 );
      } else {
        _selected.current_connection().title.move_cursor( -1 );
      }
      queue_draw();
    } else if( is_node_editable() ) {
      if( shift ) {
        _selected.current_node().name.selection_by_char( -1 );
      } else {
        _selected.current_node().name.move_cursor( -1 );
      }
      queue_draw();
    } else if( is_connection_connecting() && (_attach_node != null) ) {
      update_connection_by_node( get_node_left( _attach_node ) );
    } else if( is_connection_selected() ) {
      select_connection( -1 );
    } else if( is_node_selected() ) {
      if( select_node( get_node_left( _selected.current_node() ) ) ) {
        queue_draw();
      }
    }
  }

  /*
   If Control is used, jumps the cursor to the end of the previous word.  If Control-Shift
   is used, adds the previous word to the selection.
  */
  private void handle_control_left( bool shift ) {
    if( is_connection_editable() ) {
      if( shift ) {
        _selected.current_connection().title.selection_by_word( -1 );
      } else {
        _selected.current_connection().title.move_cursor_by_word( -1 );
      }
      queue_draw();
    } else if( is_node_editable() ) {
      if( shift ) {
        _selected.current_node().name.selection_by_word( -1 );
      } else {
        _selected.current_node().name.move_cursor_by_word( -1 );
      }
      queue_draw();
    }
  }

  /* Selects all of the text in the current node */
  private void handle_control_slash() {
    if( is_connection_editable() ) {
      _selected.current_connection().title.set_cursor_all( false );
      queue_draw();
    } else if( is_node_editable() ) {
      _selected.current_node().name.set_cursor_all( false );
      queue_draw();
    }
  }

  /* Deselects all of the text in the current node */
  private void handle_control_backslash() {
    if( is_connection_editable() ) {
      _selected.current_connection().title.clear_selection();
      queue_draw();
    } else if( is_node_editable() ) {
      _selected.current_node().name.clear_selection();
      queue_draw();
    }
  }

  /* Handles the emoji insertion process for the given text item */
  private void insert_emoji( CanvasText text ) {
    var overlay = (Overlay)get_parent();
    var entry = new Entry();
    int x, ytop, ybot;
    text.get_cursor_pos( out x, out ytop, out ybot );
    entry.margin_start = x;
    entry.margin_top   = ytop + ((ybot - ytop) / 2);
    entry.changed.connect(() => {
      text.insert( entry.text );
      entry.unparent();
      grab_focus();
    });
    overlay.add_overlay( entry );
    entry.insert_emoji();
  }

  /* Called whenever the period key is entered with the control key */
  public void handle_control_period() {
    if( is_node_editable() ) {
      insert_emoji( _selected.current_node().name );
    } else if( is_connection_editable() ) {
      insert_emoji( _selected.current_connection().title );
    }
  }

  /* Displays the quick entry UI */
  public void handle_control_e() {
    var quick_entry = new QuickEntry( this, _settings );
    quick_entry.show_all();
  }

  /* Closes the current tab */
  private void handle_control_w() {
    win.close_current_tab();
  }

  /* Called whenever the home key is entered in the drawing area */
  private void handle_home() {
    if( is_connection_editable() ) {
      _selected.current_connection().title.move_cursor_to_start();
      queue_draw();
    } else if( is_node_editable() ) {
      _selected.current_node().name.move_cursor_to_start();
      queue_draw();
    }
  }

  /* Called whenever the end key is entered in the drawing area */
  private void handle_end() {
    if( is_connection_editable() ) {
      _selected.current_connection().title.move_cursor_to_end();
      queue_draw();
    } else if( is_node_editable() ) {
      _selected.current_node().name.move_cursor_to_end();
      queue_draw();
    }
  }

  /* Called whenever the up key is entered in the drawing area */
  private void handle_up( bool shift ) {
    if( is_connection_editable() ) {
      if( shift ) {
        _selected.current_connection().title.selection_vertically( -1 );
      } else {
        _selected.current_connection().title.move_cursor_vertically( -1 );
      }
      queue_draw();
    } else if( is_node_editable() ) {
      if( shift ) {
        _selected.current_node().name.selection_vertically( -1 );
      } else {
        _selected.current_node().name.move_cursor_vertically( -1 );
      }
      queue_draw();
    } else if( is_connection_connecting() && (_attach_node != null) ) {
      update_connection_by_node( get_node_up( _attach_node ) );
    } else if( is_node_selected() ) {
      if( select_node( get_node_up( _selected.current_node() ) ) ) {
        queue_draw();
      }
    }
  }

  /*
   If the Control key is used, jumps the cursor to the beginning of the text.  If Control-Shift
   is used, selects everything from the beginnning of the string to the cursor position.
  */
  private void handle_control_up( bool shift ) {
    if( is_connection_editable() ) {
      if( shift ) {
        _selected.current_connection().title.selection_to_start();
      } else {
        _selected.current_connection().title.move_cursor_to_start();
      }
      queue_draw();
    } else if( is_node_editable() ) {
      if( shift ) {
        _selected.current_node().name.selection_to_start();
      } else {
        _selected.current_node().name.move_cursor_to_start();
      }
      queue_draw();
    }
  }

  /* Called whenever the down key is entered in the drawing area */
  private void handle_down( bool shift ) {
    if( is_connection_editable() ) {
      if( shift ) {
        _selected.current_connection().title.selection_vertically( 1 );
      } else {
        _selected.current_connection().title.move_cursor_vertically( 1 );
      }
      queue_draw();
    } else if( is_node_editable() ) {
      if( shift ) {
        _selected.current_node().name.selection_vertically( 1 );
      } else {
        _selected.current_node().name.move_cursor_vertically( 1 );
      }
      queue_draw();
    } else if( is_connection_connecting() && (_attach_node != null) ) {
      update_connection_by_node( get_node_down( _attach_node ) );
    } else if( is_node_selected() ) {
      if( select_node( get_node_down( _selected.current_node() ) ) ) {
        queue_draw();
      }
    }
  }

  /*
   If the Control key is used, jumps the cursor to the end of the text.  If Control-Shift is
   used, selects all text from the current cursor position to the end of the string.
  */
  private void handle_control_down( bool shift ) {
    if( is_connection_editable() ) {
      if( shift ) {
        _selected.current_connection().title.selection_to_end();
      } else {
        _selected.current_connection().title.move_cursor_to_end();
      }
      queue_draw();
    } else if( is_node_editable() ) {
      if( shift ) {
        _selected.current_node().name.selection_to_end();
      } else {
        _selected.current_node().name.move_cursor_to_end();
      }
      queue_draw();
    }
  }

  /* Called whenever the page up key is entered in the drawing area */
  private void handle_pageup() {
    if( is_connection_connecting() && (_attach_node != null) ) {
      update_connection_by_node( get_node_pageup( _attach_node ) );
    } else if( is_node_selected() ) {
      if( select_node( get_node_pageup( _selected.current_node() ) ) ) {
        queue_draw();
      }
    }
  }

  /* Called whenever the page down key is entered in the drawing area */
  private void handle_pagedn() {
    if( is_connection_connecting() && (_attach_node != null) ) {
      update_connection_by_node( get_node_pagedn( _attach_node ) );
    } else if( is_node_selected() ) {
      if( select_node( get_node_pagedn( _selected.current_node() ) ) ) {
        queue_draw();
      }
    }
  }

  /* Called whenever a printable character is entered in the drawing area */
  private void handle_printable( string str ) {
    if( str.get_char( 0 ).isprint() ) {
      if( is_connection_editable() ) {
        _selected.current_connection().title.insert( str );
        queue_draw();
        changed();
      } else if( is_node_editable() ) {
        _selected.current_node().name.insert( str );
        see();
        queue_draw();
        changed();
      } else if( is_connection_selected() ) {
        var current = _selected.current_connection();
        switch( str ) {
          case "e" :
            current.edit_title_begin( this );
            current.mode = ConnMode.EDITABLE;
            queue_draw();
            break;
          case "t" :  select_connection_node( false );  break;
          case "f" :  select_connection_node( true );   break;
          case "n" :  select_connection( 1 );  break;
          case "p" :  select_connection( -1 );  break;
          case "i" :  show_properties( "current", false );  break;
          case "u" :  // Perform undo
            if( undo_buffer.undoable() ) {
              undo_buffer.undo();
            }
            break;
          case "r" :  // Perform redo
            if( undo_buffer.redoable() ) {
              undo_buffer.redo();
            }
            break;
          case "s" :  see();  break;
          case "z" :  zoom_out();  break;
          case "Z" :  zoom_in();  break;
          default :
            return;
        }
      } else if( is_node_selected() ) {
        var current = _selected.current_node();
        switch( str ) {
          case "e" :
            current.mode = NodeMode.EDITABLE;
            queue_draw();
            break;
          case "n" :  select_sibling_node( 1 );  break;
          case "p" :  select_sibling_node( -1 );  break;
          case "a" :  select_parent_node();  break;
          case "f" :  toggle_fold( current );  break;
          case "t" :  // Toggle the task done indicator
            if( current.is_task() ) {
              toggle_task( current );
            }
            break;
          case "m" :  select_root_node();  break;
          case "c" :  select_child_node();  break;
          case "C" :  center_current_node();  break;
          case "i" :  show_properties( "current", false );  break;
          case "I" :
            if( _debug ) {
              current.display();
            }
            break;
          case "u" :  // Perform undo
            if( undo_buffer.undoable() ) {
              undo_buffer.undo();
            }
            break;
          case "r" :  // Perform redo
            if( undo_buffer.redoable() ) {
              undo_buffer.redo();
            }
            break;
          case "s" :  see();  break;
          case "S" :  sort_alphabetically();  break;
          case "z" :  zoom_out();  break;
          case "Z" :  zoom_in();  break;
          case "h" :  handle_left( false );  break;
          case "j" :  handle_down( false );  break;
          case "k" :  handle_up( false );  break;
          case "l" :  handle_right( false );  break;
          case "y" :  toggle_link();  break;
          case "Y" :  select_linked_node();  break;
          case "x" :  start_connection( true, false );  break;
          case "X" :  select_attached_connection();  break;
          default :
            // This is a key that doesn't have any associated functionality
            // so just return immediately so that we don't force a redraw
            return;
        }
      }
    }
  }

  /* Handle a key event */
  private bool on_keypress( EventKey e ) {

    /* Figure out which modifiers were used */
    var control = (bool) e.state & ModifierType.CONTROL_MASK;
    var shift   = (bool) e.state & ModifierType.SHIFT_MASK;
    var nomod   = !(control || shift);

    /* If there is a current node or connection selected, operate on it */
    if( (_selected.current_node() != null) || (_selected.current_connection() != null) ) {
      if( control ) {
        switch( e.keyval ) {
          case 99    :  do_copy();                      break;
          case 120   :  do_cut();                       break;
          case 118   :  do_paste();                     break;
          case 65293 :  handle_control_return();        break;
          case 65289 :  handle_control_tab();           break;
          case 65363 :  handle_control_right( shift );  break;
          case 65361 :  handle_control_left( shift );   break;
          case 65362 :  handle_control_up( shift );     break;
          case 65364 :  handle_control_down( shift );   break;
          case 47    :  handle_control_slash();         break;
          case 92    :  handle_control_backslash();     break;
          case 46    :  handle_control_period();        break;
          case 101   :  handle_control_e();             break;
          case 119   :  handle_control_w();             break;
        }
      } else if( nomod || shift ) {
        if( _im_context.filter_keypress( e ) ) {
          return( true );
        }
        switch( e.keyval ) {
          case 65288 :  handle_backspace();    break;
          case 65535 :  handle_delete();       break;
          case 65307 :  handle_escape();       break;
          case 65293 :  handle_return();       break;
          case 65289 :  handle_tab();          break;
          case 65363 :  handle_right( shift ); break;
          case 65361 :  handle_left( shift );  break;
          case 65360 :  handle_home();         break;
          case 65367 :  handle_end();          break;
          case 65362 :  handle_up( shift );    break;
          case 65364 :  handle_down( shift );  break;
          case 65365 :  handle_pageup();       break;
          case 65366 :  handle_pagedn();       break;
          default :
            //if( !e.str.get_char( 0 ).isprint() ) {
            //  stdout.printf( "In on_keypress, keyval: %s\n", e.keyval.to_string() );
            //}
            handle_printable( e.str );
            break;
        }
      }

    /* If there is no current node, allow some of the keyboard shortcuts */
    } else if( control ) {
      switch( e.keyval ) {
        case 99  :  do_copy();  break;
        case 120 :  do_cut();   break;
      }

    } else if( nomod || shift ) {
      switch( e.str ) {
        case "m" :  select_root_node();  break;
        case "u" :  if( undo_buffer.undoable() ) undo_buffer.undo();  break;
        case "r" :  if( undo_buffer.redoable() ) undo_buffer.redo();  break;
        case "z" :  zoom_out();  break;
        case "Z" :  zoom_in();   break;
        case "f" :  toggle_folds();  break;
        default  :
          switch( e.keyval ) {
            case 65288 :  handle_backspace();  break;
            case 65535 :  handle_delete();     break;
          }
          break;
      }
    }
    return( true );
  }

  /* Returns true if we can perform a node copy operation */
  public bool node_copyable() {
    return( _selected.current_node() != null );
  }

  /* Returns true if we can perform a node cut operation */
  public bool node_cuttable() {
    return( _selected.current_node() != null );
  }

  /* Returns true if we can perform a node paste operation */
  public bool node_pasteable() {
    return( node_clipboard.wait_is_text_available() );
  }

  /* Serializes the current node tree */
  public string serialize_for_copy( Array<Node> node_array ) {
    string    str;
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "minder" );
    doc->set_root_element( root );
    Xml.Node* nodes = new Xml.Node( null, "nodes" );
    for( int i=0; i<node_array.length; i++ ) {
      node_array.index( i ).save( nodes );
    }
    root->add_child( nodes );
    Xml.Node* conns = new Xml.Node( null, "connections" );
    for( int i=0; i<node_array.length; i++ ) {
      _connections.save_if_in_node( conns, node_array.index( i ) );
    }
    root->add_child( conns );
    doc->dump_memory( out str );
    delete doc;
    return( str );
  }

  /* Deserializes the paste string and returns the list of nodes */
  public void deserialize_for_paste( string str, Array<Node> nodes, Array<Connection> conns, HashMap<int,int> id_map, Array<NodeLinkInfo?> link_ids ) {
    Xml.Doc* doc    = Xml.Parser.parse_doc( str );
    if( doc == null ) return;
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          // case "images"      :  image_manager.load( it );  break;
          case "connections" :  _connections.load( this, it, conns, nodes, id_map );  break;
          case "nodes"       :
            for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
              if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "node") ) {
                var node = new Node.with_name( this, "temp", null );
                node.load( this, it2, true, id_map, link_ids );
                nodes.append_val( node );
              }
            }
            break;
        }
      }
    }
    for( int i=0; i<link_ids.length; i++ ) {
      link_ids.index( i ).node.linked_node = get_node( nodes, int.parse( link_ids.index( i ).id_str ) );
    }
    delete doc;
  }

  /* Copies the current node to the node clipboard */
  public void copy_nodes_to_clipboard() {
    var nodes_to_copy = new Array<Node>();
    if( _selected.current_node() != null ) {
      nodes_to_copy.append_val( _selected.current_node() );
    } else {
      _selected.get_subtrees( ref nodes_to_copy, image_manager );
    }
    if( nodes_to_copy.length == 0 ) return;
    var text = serialize_for_copy( nodes_to_copy );
    node_clipboard.set_text( text, -1 );
    node_clipboard.store();
  }

  /* Copies the currently selected text to the clipboard */
  public void copy_selected_text() {
    string? value        = null;
    var     current_node = _selected.current_node();
    var     current_conn = _selected.current_connection();
    if( current_node != null ) {
      value = current_node.name.get_selected_text();
    } else if( current_conn != null ) {
      value = current_conn.title.get_selected_text();
    }
    if( value != null ) {
      var clipboard = Clipboard.get_default( get_display() );
      clipboard.set_text( value, -1 );
    }
  }

  /* Copies either the current node or the currently selected text to the clipboard */
  public void do_copy() {
    var current = _selected.current_node();
    if( current != null ) {
      switch( current.mode ) {
        case NodeMode.CURRENT  :  copy_nodes_to_clipboard();  break;
        case NodeMode.EDITABLE :  copy_selected_text();      break;
      }
    } else if( _selected.nodes().length > 1 ) {
      copy_nodes_to_clipboard();
    } else if( is_connection_editable() ) {
      copy_selected_text();
    }
  }

  /* Cuts the current node from the tree and stores it in the clipboard */
  public void cut_node_to_clipboard() {
    var current = _selected.current_node();
    if( current == null ) return;
    var next_node = next_node_to_select();
    var conns     = new Array<Connection>();
    _connections.node_deleted( current, conns );
    copy_nodes_to_clipboard();
    if( current.is_root() ) {
      for( int i=0; i<_nodes.length; i++ ) {
        if( _nodes.index( i ) == current ) {
          undo_buffer.add_item( new UndoNodeCut( current, i, conns ) );
          _nodes.remove_index( i );
          break;
        }
      }
    } else {
      undo_buffer.add_item( new UndoNodeCut( current, current.index(), conns ) );
      current.delete();
    }
    _selected.remove_node( current );
    current_changed( this );
    select_node( next_node );
    queue_draw();
    changed();
  }

  public void cut_nodes_to_clipboard() {
    if( _selected.num_nodes() == 0 ) return;
    var nodes = _selected.nodes();
    var conns = new Array<Connection>();
    for( int i=0; i<nodes.length; i++ ) {
      _connections.node_only_deleted( nodes.index( i ), conns );
    }
    copy_nodes_to_clipboard();
    undo_buffer.add_item( new UndoNodesCut( nodes, conns ) );
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).delete_only();
    }
    _selected.clear_nodes();
    current_changed( this );
    queue_draw();
    changed();
  }

  /* Cuts the current selected text to the clipboard */
  public void cut_selected_text() {
    copy_selected_text();
    var current_node = _selected.current_node();
    var current_conn = _selected.current_connection();
    if( current_node != null ) {
      current_node.name.insert( "" );
    } else if( current_conn != null ) {
      current_conn.title.insert( "" );
    }
    queue_draw();
    changed();
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
      cut_nodes_to_clipboard();
    } else if( is_connection_editable() ) {
      cut_selected_text();
    }
  }

  /*
   Pastes the clipboard content as either a root node or to the currently
   selected node.
  */
  public void paste_node_from_clipboard() {
    if( !node_clipboard.wait_is_text_available() ) return;
    var nodes    = new Array<Node>();
    var conns    = new Array<Connection>();
    var id_map   = new HashMap<int,int>();
    var link_ids = new Array<NodeLinkInfo?>();
    var current  = _selected.current_node();
    deserialize_for_paste( node_clipboard.wait_for_text(), nodes, conns, id_map, link_ids );
    if( current == null ) {
      for( int i=0; i<nodes.length; i++ ) {
        _nodes.index( _nodes.length - 1 ).layout.position_root( _nodes.index( _nodes.length - 1 ), nodes.index( i ) );
        add_root( nodes.index( i ), -1 );
      }
    } else {
      if( current.is_root() ) {
        uint num_children = current.children().length;
        if( num_children > 0 ) {
          for( int i=0; i<nodes.length; i++ ) {
            nodes.index( i ).side = current.children().index( num_children - 1 ).side;
            nodes.index( i ).layout.propagate_side( nodes.index( i ), nodes.index( i ).side );
            nodes.index( i ).attach( current, -1, _theme );
          }
        } else {
          for( int i=0; i<nodes.length; i++ ) {
            nodes.index( i ).attach( current, -1, _theme );
          }
        }
      } else {
        for( int i=0; i<nodes.length; i++ ) {
          nodes.index( i ).side = current.side;
          nodes.index( i ).layout.propagate_side( nodes.index( i ), nodes.index( i ).side );
          nodes.index( i ).attach( current, -1, _theme );
        }
      }
    }
    undo_buffer.add_item( new UndoNodePaste( nodes, conns ) );
    select_node( nodes.index( 0 ) );
    queue_draw();
    current_changed( this );
    changed();
  }

  /* Pastes the text that is in the clipboard to the node text */
  public void paste_text() {
    var clipboard = Clipboard.get_default( get_display() );
    string? value = clipboard.wait_for_text();
    if( value != null ) {
      var current_node = _selected.current_node();
      var current_conn = _selected.current_connection();
      if( current_node != null ) {
        current_node.name.insert( value );
      } else if( current_conn != null ) {
        current_conn.title.insert( value );
      }
      queue_draw();
      changed();
    }
  }

  /* Pastes the contents of the clipboard into the current node */
  public void do_paste() {
    var current = _selected.current_node();
    if( current != null ) {
      switch( current.mode ) {
        case NodeMode.CURRENT  :  paste_node_from_clipboard();  break;
        case NodeMode.EDITABLE :  paste_text();                 break;
      }
    } else if( is_connection_editable() ) {
      paste_text();
    }
  }

  /*
   Called whenever the user scrolls on the canvas.  We will adjust the
   origin to give the canvas the appearance of scrolling.
  */
  private bool on_scroll( EventScroll e ) {

    double delta_x, delta_y;
    e.get_scroll_deltas( out delta_x, out delta_y );

    bool shift   = (bool) e.state & ModifierType.SHIFT_MASK;
    bool control = (bool) e.state & ModifierType.CONTROL_MASK;

    /* Swap the deltas if the SHIFT key is held down */
    if( shift && !control ) {
      double tmp = delta_x;
      delta_x = delta_y;
      delta_y = tmp;
    } else if( control ) {
      if( e.delta_y < 0 ) {
        zoom_in();
      } else if( e.delta_y > 0 ) {
        zoom_out();
      }
      return( false );
    }

    /* Adjust the origin and redraw */
    move_origin( (delta_x * 120), (delta_y * 120) );
    queue_draw();

    /* When the end of the scroll occurs, save the scroll position to the file */
    auto_save();

    return( false );

  }

  /* Perform an automatic save for times when changes may be happening rapidly */
  private void auto_save() {
    if( _auto_save_id != null ) {
      Source.remove( _auto_save_id );
    }
    _auto_save_id = Timeout.add( 200, do_auto_save );
  }

  /* Allows the document to be auto-saved after a scroll event */
  private bool do_auto_save() {
    _auto_save_id = null;
    changed();
    return( false );
  }

  /* Called whenever we drag something over the canvas */
  private bool handle_drag_motion( Gdk.DragContext ctx, int x, int y, uint t ) {

    Node attach_node = droppable_node( scale_value( x ), scale_value( y ) );
    if( _attach_node != null ) {
      _attach_node.mode = NodeMode.NONE;
    }
    if( attach_node != null ) {
      attach_node.mode = NodeMode.DROPPABLE;
      _attach_node = attach_node;
      queue_draw();
    } else if( _attach_node != null ) {
      _attach_node = null;
      queue_draw();
    }

    return( true );

  }

  /* Called when something is dropped on the DrawArea */
  private void handle_drag_data_received( Gdk.DragContext ctx, int x, int y, Gtk.SelectionData data, uint info, uint t ) {

    if( (_attach_node == null) || (_attach_node.mode != NodeMode.DROPPABLE) ) {

      foreach (var uri in data.get_uris()) {
        var image = new NodeImage.from_uri( image_manager, uri, 200 );
        if( image.valid ) {
          var node = new Node.with_name( this, _( "Another Idea" ), layouts.get_default() );
          node.set_image( image_manager, image );
          _nodes.index( _nodes.length - 1 ).layout.position_root( _nodes.index( _nodes.length - 1 ), node );
          _nodes.append_val( node );
          if( select_node( node ) ) {
            node.mode = NodeMode.EDITABLE;
            _current_new = true;
            queue_draw();
          }
        }
      }

      Gtk.drag_finish( ctx, true, false, t );

      see();
      queue_draw();
      current_changed( this );
      auto_save();

    } else if( (_attach_node.mode == NodeMode.DROPPABLE) && (data.get_uris().length == 1) ) {

      var image = new NodeImage.from_uri( image_manager, data.get_uris()[0], _attach_node.max_width() );
      if( image.valid ) {
        var orig_image = _attach_node.image;
        _attach_node.set_image( image_manager, image );
        undo_buffer.add_item( new UndoNodeImage( _attach_node, orig_image ) );
        _attach_node.mode = NodeMode.NONE;
        _attach_node      = null;
        Gtk.drag_finish( ctx, true, false, t );
        queue_draw();
        current_changed( this );
        auto_save();
      }

    }

  }

  /* Sets the image of the current node to the given filename */
  public bool update_current_image( string uri ) {
    var current = _selected.current_node();
    var image   = new NodeImage.from_uri( image_manager, uri, current.max_width() );
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

  /* Starts a connection from the current node */
  public void start_connection( bool key, bool link ) {
    var current_node = _selected.current_node();
    if( current_node == null ) return;
    var conn = new Connection( this, current_node );
    _selected.set_current_connection( conn );
    conn.mode = link ? ConnMode.LINKING : ConnMode.CONNECTING;
    if( key ) {
      double x, y, w, h;
      current_node.bbox( out x, out y, out w, out h );
      conn.draw_to( (x + (w / 2)), (y + (h / 2)) );
      if( _attach_node != null ) {
        _attach_node.mode = NodeMode.NONE;
      }
      _attach_node      = current_node;
      _attach_node.mode = NodeMode.ATTACHABLE;
    } else {
      conn.draw_to( _press_x, _press_y );
    }
    _last_node = current_node;
    queue_draw();
  }

  /* Called when a connection is being drawn by moving the mouse */
  public void update_connection( double x, double y ) {
    var current = _selected.current_connection();
    if( current == null ) return;
    current.draw_to( scale_value( x ), scale_value( y ) );
    queue_draw();
  }

  /* Called when the connection is being connected via the keyboard */
  public void update_connection_by_node( Node? node ) {
    if( node == null ) return;
    double x, y, w, h;
    node.bbox( out x, out y, out w, out h );
    _selected.current_connection().draw_to( (x + (w / 2)), (y + (h / 2)) );
    if( _attach_node != null ) {
      _attach_node.mode = NodeMode.NONE;
    }
    _attach_node      = node;
    _attach_node.mode = NodeMode.ATTACHABLE;
    queue_draw();
  }

  /* Ends a connection at the given node */
  public void end_connection( Node n ) {
    var current = _selected.current_connection();
    if( current == null ) return;
    current.connect_to( n );
    _connections.add_connection( current );
    undo_buffer.add_item( new UndoConnectionAdd( current ) );
    _selected.set_current_connection( current );
    _last_connection = null;
    _last_node       = null;
    _attach_node.mode = NodeMode.NONE;
    _attach_node      = null;
    current_changed( this );
    changed();
    queue_draw();
  }

  /*
   If exactly two nodes are currently selected, draws a connection from the first selected node
   to the second selected node.
  */
  public void create_connection() {
    if( _selected.num_nodes() != 2 ) return;
    double x, y, w, h;
    var    nodes = _selected.nodes();
    var    conn  = new Connection( this, nodes.index( 0 ) );
    conn.connect_to( nodes.index( 1 ) );
    nodes.index( 1 ).bbox( out x, out y, out w, out h );
    conn.draw_to( (x + (w / 2)), (y + (h / 2)) );
    _connections.add_connection( conn );
    _selected.set_current_connection( conn );
    undo_buffer.add_item( new UndoConnectionAdd( conn ) );
    current_changed( this );
    changed();
    queue_draw();
  }

  /* Deletes the current connection */
  public void delete_connection() {
    var current = _selected.current_connection();
    if( current == null ) return;
    undo_buffer.add_item( new UndoConnectionDelete( current ) );
    _connections.remove_connection( current, false );
    _selected.remove_connection( current );
    _last_connection = null;
    current_changed( this );
    changed();
    queue_draw();
  }

  /* Deletes the currently selected connections */
  public void delete_connections() {
    if( _selected.num_connections() == 0 ) return;
    var conns = _selected.connections();
    undo_buffer.add_item( new UndoConnectionsDelete( conns ) );
    for( int i=0; i<conns.length; i++ ) {
      _connections.remove_connection( conns.index( i ), false );
    }
    _selected.clear_connections();
    current_changed( this );
    changed();
    queue_draw();
  }

  /*
   Called when the focus button active state changes.  Causes all nodes and connections
   to have the alpha state set to almost transparent (when focus mode is enabled) or fully opaque.
  */
  public void set_focus_mode( bool focus ) {
    double alpha = focus ? _focus_alpha : 1.0;
    _focus_mode = focus;
    for( int i=0; i<_nodes.length; i++ ) {
      _nodes.index( i ).alpha = alpha;
    }
    if( _selected.current_node() != null ) {
      if( focus ) {
        update_focus_mode();
      } else {
        // zoom_actual();
      }
    } else if( _selected.current_connection() != null ) {
      _selected.current_connection().alpha = 1.0;
    }
    _connections.update_alpha();
    queue_draw();
  }

  /* Update the focus mode */
  public void update_focus_mode() {
    var current = _selected.current_node();
    current.alpha = 1.0;
    if( _focus_mode ) {
      var parent = current.parent;
      while( parent != null ) {
        parent.set_alpha_only( 1.0 );
        parent = parent.parent;
      }
      // zoom_to_selected();
    }
    _connections.update_alpha();
    queue_draw();
  }

  /* Updates the create_new_from_edit variable */
  private void update_create_new_from_edit( GLib.Settings settings ) {
    _create_new_from_edit = settings.get_boolean( "new-node-from-edit" );
  }

  /* Updates all alpha values with the given value */
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

  /* Sorts and re-arranges the children of the given parent using the given array */
  private void sort_children( Node parent, CompareFunc<Node> sort_fn ) {
    var children = new SList<Node>();
    undo_buffer.add_item( new UndoNodeSort( parent ) );
    animator.add_nodes( "sort nodes" );
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
    animator.animate();
    changed();
  }

  /* Sorts the current node's children alphabetically */
  public void sort_alphabetically() {
    CompareFunc<Node> sort_fn = (a, b) => {
      return( strcmp( a.name.text, b.name.text ) );
    };
    sort_children( _selected.current_node(), sort_fn );
  }

  /* Sorts the current node's children in a random manner */
  public void sort_randomly() {
    CompareFunc<Node> sort_fn = (a, b) => {
      return( (Random.int_range( 0, 2 ) == 0) ? -1 : 1 );
    };
    sort_children( _selected.current_node(), sort_fn );
  }

  /* Displays the URL in a popup menu that allows the user to display the URL in a web browser */
  private void show_url_popover( EventButton event, Node node, string url, double left ) {
    var mnu  = new Gtk.Menu();
    var item = new Gtk.MenuItem.with_label( url );
    item.activate.connect(() => {
      try {
        AppInfo.launch_default_for_uri( url, null );
      } catch( GLib.Error e ) {}
    });
    mnu.rect_anchor_dx = (int)(left - event.x);
    mnu.rect_anchor_dy = (int)(node.posy - event.y - 40);
    mnu.take_focus     = false;
    mnu.add( item );
    mnu.show_all();
#if GTK322
    mnu.popup_at_pointer( event );
#else
    mnu.popup( null, null, null, event.button, event.time );
#endif
    Timeout.add( 500, () => {
      grab_focus();
      return( Source.REMOVE );
    });
  }

  /* Moves all trees to avoid overlapping */
  public void handle_tree_overlap( NodeBounds prev ) {

    var current = _selected.current_node();

    if( current == null ) return;

    var root  = current.get_root();
    var curr  = root.tree_bbox;
    var ldiff = curr.x - prev.x;
    var rdiff = (curr.x + curr.width) - (prev.x + prev.width);
    var adiff = curr.y - prev.y;
    var bdiff = (curr.y + curr.height) - (prev.y + prev.height);

    for( int i=0; i<_nodes.length; i++ ) {
      var node = _nodes.index( i );
      if( node != root ) {
        if( node.is_left_of( prev ) )  node.posx += ldiff;
        if( node.is_right_of( prev ) ) node.posx += rdiff;
        if( node.is_above( prev ) )    node.posy += adiff;
        if( node.is_below( prev ) )    node.posy += bdiff;
      }
    }

  }

}
