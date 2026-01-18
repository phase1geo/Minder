/*
* Copyright (c) 2026 (https://github.com/phase1geo/Minder)
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
using Gdk;

public class MindMap {

  private MainWindow     _win;
  private GLib.Settings  _settings;
  private MapModel       _model;
  private DrawArea       _canvas;
  private Document       _doc;
  private UndoBuffer     _undo_buffer;
  private UndoTextBuffer _undo_text;
  private Selection      _selected;
  private bool           _focus_mode     = false;
  private double         _focus_alpha    = 0.05;
  private Tags           _highlighted;
  private TagComboType   _highlight_mode = TagComboType.AND;
  private bool           _editable       = true;
  private Style          _global_style;

  /* Allocate static parsers */
  public MarkdownParser markdown_parser { get; private set; }
  public TaggerParser   tagger_parser   { get; private set; }
  public UrlParser      url_parser      { get; private set; }
  public UnicodeParser  unicode_parser  { get; private set; }

  public MainWindow win {
    get {
      return( _win );
    }
  }
  public GLib.Settings settings {
    get {
      return( _settings );
    }
  }
  public MapModel model {
    get {
      return( _model );
    }
  }
  public DrawArea canvas {
    get {
      return( _canvas );
    }
  }
  public Document doc {
    get {
      return( _doc );
    }
  }
  public Selection selected {
    get {
      return( _selected );
    }
  }
  public UndoBuffer undo_buffer {
    get {
      return( _undo_buffer );
    }
  }
  public UndoTextBuffer undo_text {
    get {
      return( _undo_text );
    }
  }
  public bool focus_mode {
    get {
      return( _focus_mode );
    }
    set {
      if( _focus_mode != value ) {
        _focus_mode = value;
        update_focus_mode();
      }
    }
  }
  public double focus_alpha {
    get {
      return( _focus_alpha );
    }
  }
  public Tags highlighted {
    get {
      return( _highlighted );
    }
  }
  public TagComboType highlight_mode {
    get {
      return( _highlight_mode );
    }
    set {
      if( _highlight_mode != value ) {
        _highlight_mode = value;
        update_focus_mode();
      }
    }
  }
  public Style global_style {
    get {
      return( _global_style );
    }
  }

  // Convenience functions
  public double origin_x {
    get {
      return( _canvas.origin_x );
    }
  }
  public double origin_y {
    get {
      return( _canvas.origin_y );
    }
  }
  public Animator animator {
    get {
      return( _canvas.animator );
    }
  }
  public Array<string> braindump {
    get {
      return( _model.braindump );
    }
  }
  public Connections connections {
    get {
      return( _model.connections );
    }
  }
  public Stickers stickers {
    get {
      return( _model.stickers );
    }
  }
  public NodeGroups groups {
    get {
      return( _model.groups );
    }
  }
  public ImageManager image_manager {
    get {
      return( _model.image_manager );
    }
  }
  public Layouts layouts {
    get {
      return( _model.layouts );
    }
  }
  public int next_node_id {
    get {
      return( _model.next_node_id );
    }
    set {
      _model.next_node_id = value;
    }
  }
  public bool editable {
    get {
      return( _editable && !doc.read_only );
    }
    set {
      if( _editable != value ) {
        _editable = value;
        editable_changed( this );
      }
    }
  }

  public signal void changed();
  public signal void current_changed( MindMap map );
  public signal void theme_changed( MindMap map );
  public signal void loaded();
  public signal void scale_changed( double scale );
  public signal void scroll_changed();
  public signal void show_properties( string? tab, PropertyGrab grab_type );
  public signal void hide_properties();
  public signal void undo_buffer_changed( UndoBuffer buf );
  public signal void editable_changed( MindMap map );
  public signal void reload_tags();

  //-------------------------------------------------------------
  // Constructor
  public MindMap( MainWindow win, GLib.Settings settings ) {

    _win      = win;
    _settings = settings;

    // Create the map model
    _model = new MapModel( this );

    // Create the drawing area where the map will be drawn and interacted with
    _canvas = new DrawArea( this, win );

    // Create the document
    _doc = new Document( this );

    // Create undo buffer
    _undo_buffer = new UndoBuffer( this );

    // Create text undo buffer
    _undo_text = new UndoTextBuffer( this );

    // Create the selection handler
    _selected = new Selection( this );

    // Create the global style
    _global_style = new Style();

    _highlighted = new Tags();

    // Create the parsers
    tagger_parser   = new TaggerParser( this );
    markdown_parser = new MarkdownParser( this );
    url_parser      = new UrlParser();
    unicode_parser  = new UnicodeParser( this );

    markdown_parser.enable = settings.get_boolean( "enable-markdown" );
    url_parser.enable      = settings.get_boolean( "auto-parse-embedded-urls" );
    unicode_parser.enable  = settings.get_boolean( "enable-unicode-input" );

    // Connect signals
    _model.changed.connect( handle_model_changed );
    _model.current_changed.connect( handle_current_changed );
    _model.theme_changed.connect( handle_theme_changed );
    _model.loaded.connect( handle_model_loaded );
    _model.queue_draw.connect( _canvas.queue_draw );
    _model.see.connect( _canvas.see );

    _canvas.current_changed.connect( handle_current_changed );
    _canvas.scale_changed.connect( handle_scale_changed );
    _canvas.scroll_changed.connect( handle_scroll_changed );

    _doc.read_only_changed.connect( handle_read_only_changed );

    _undo_buffer.buffer_changed.connect( handle_undo_buffer_changed );

    _selected.selection_changed.connect( handle_selection_changed );

    _highlighted.changed.connect( handle_tag_highlight_changed );

    // Get the value of the new node from edit
    update_focus_mode_alpha();
    _settings.changed.connect(() => {
      update_focus_mode_alpha();
    });

  }

  //-------------------------------------------------------------
  // SIGNAL HANDLERS FROM MEMBER VARIABLE CLASSES
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Handles any changes to the map model.
  private void handle_model_changed() {
    changed();
  }

  //-------------------------------------------------------------
  // Handles any changed to the currently selected item.
  private void handle_current_changed() {
    current_changed( this );
  }

  //-------------------------------------------------------------
  // Handles any changes to the currently selected theme.
  private void handle_theme_changed() {
    theme_changed( this );
  }

  //-------------------------------------------------------------
  // Handles an indication that the associated map model has been
  // loaded from file.
  private void handle_model_loaded() {
    loaded();
    reload_tags();
  }

  //-------------------------------------------------------------
  // Called whenever the scale changes for the mind map.
  private void handle_scale_changed( double scale ) {
    scale_changed( scale );
  }

  //-------------------------------------------------------------
  // Handles any changes to the scroll position for the mind map.
  private void handle_scroll_changed() {
    scroll_changed();
  }

  //-------------------------------------------------------------
  // Handles any indications that the document read-only status
  // changed.
  private void handle_read_only_changed() {
    editable_changed( this );
  }

  //-------------------------------------------------------------
  // Handles any changes to the undo buffer.
  private void handle_undo_buffer_changed( UndoBuffer buf ) {
    undo_buffer_changed( buf );
  }

  //-------------------------------------------------------------
  // Handles any changes to the selection state.
  private void handle_selection_changed() {
    update_focus_mode();
    _canvas.queue_draw();
    current_changed( this );
  }

  //-------------------------------------------------------------
  // Handles any changes to the highlighted tag list.
  private void handle_tag_highlight_changed() {
    update_focus_mode();
    _canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // DOCUMENT HANDLING
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Called when we want to close this map from the application.
  public void close() {
    doc.cleanup();
  }

  //-------------------------------------------------------------
  // INITIALIZATION CODE
  //-------------------------------------------------------------
  
  //-------------------------------------------------------------
  // Common initialization routine.
  private void initialize() {

    // Initialize the map model
    _model.initialize();

    // Initialize the canvas
    _canvas.initialize();

    // Clear the undo buffers
    _undo_buffer.clear();
    _undo_text.clear();

    // Clear the selection
    _selected.clear();

    // If we are a new mindmap, populate our global style
    switch( _settings.get_int( "default-global-style" ) ) {
      case 0  :
        _global_style.copy( StyleInspector.styles.get_global_style() );
        break;
      case 1  :
        if( StyleInspector.last_global_style != null ) {
          _global_style.copy( StyleInspector.last_global_style );
        } else {
          _global_style.copy( StyleInspector.styles.get_global_style() );
        }
        break;
      default :      
        var template = _win.templates.get_template( TemplateType.STYLE_GENERAL, Minder.settings.get_string( "default-global-style-name" ) );
        if( template != null ) {
          var style_template = (StyleTemplate)template;
          _global_style.copy( style_template.style );
        } else {
          _global_style.copy( StyleInspector.styles.get_global_style() );
        }
        break;
    }

    // Initialize variables
    // TBD

  }

  //-------------------------------------------------------------
  // Initializes the canvas to prepare it for a document that
  // will be loaded.
  public void initialize_for_open() {

    initialize();

    // Add tags from preference if we are loading a 1.x Minder file and it is not read-only
    if( (Utils.compare_versions( _doc.load_version, "2.0" ) == -1) && !editable ) {
      _model.tags.load_variant( Minder.settings.get_value( "starting-tags" ) );
    }

    set_current_node( null );

    _canvas.queue_draw();

  }

  //-------------------------------------------------------------
  // Initialize the empty drawing area with a node.
  public void initialize_for_new() {

    initialize();

    // Add tags from preferences
    _model.tags.load_variant( Minder.settings.get_value( "starting-tags" ) );
    reload_tags();

    // Create and add the first root node after idle to allow the window size to be known
    _canvas.size_ready.connect((w, h) => {
      var n = _model.create_root_node( _( "Main Idea" ) );
      set_current_node( n );
      _model.set_node_mode( n, NodeMode.EDITABLE, false );

      // Make sure that we save the document
      doc.save_xml();
      doc.save();

      // Redraw the canvas
      _canvas.queue_draw();
    });

  }

  //-------------------------------------------------------------
  // NODE SELECTION METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Returns the current CanvasText being edited.  If we are not
  // editing, returns null.
  public CanvasText? get_current_text() {
    if( is_node_editable() ) {
      return( get_current_node().name );
    } else if( is_connection_editable() ) {
      return( get_current_connection().title );
    } else if( is_callout_editable() ) {
      return( get_current_callout().text );
    } else {
      return( null );
    }
  }

  //-------------------------------------------------------------
  // Returns the current node.
  public Node? get_current_node() {
    return( _selected.current_node() );
  }

  //-------------------------------------------------------------
  // Helper function that returns true if a single node is currently
  // selected and matches the given NodeMode state.
  private bool is_node_mode( NodeMode mode ) {
    var current = get_current_node();
    return( (current != null) && (current.mode == mode) );
  }

  //-------------------------------------------------------------
  // Returns if a node is currently selected.
  public bool is_node_selected() {
    return( is_node_mode( NodeMode.CURRENT ) );
  }

  //-------------------------------------------------------------
  // Returns true if one node is selected and it is editable.
  public bool is_node_editable() {
    return( is_node_mode( NodeMode.EDITABLE ) );
  }

  //-------------------------------------------------------------
  // Sets the current node to the given node
  public void set_current_node( Node? n ) {
    if( n == null ) {
      _selected.clear_nodes();
    } else if( _selected.is_node_selected( n ) && (_selected.num_nodes() == 1) ) {
      _model.set_node_mode( _selected.nodes().index( 0 ), NodeMode.CURRENT );
    } else {
      _selected.clear_nodes( false );
      var last_folded = n.folded_ancestor();
      if( last_folded != null ) {
        last_folded.set_fold_only( false );
        add_undo( new UndoNodeFolds.single( last_folded ) );
      }
      _selected.add_node( n );
    }
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
        _canvas.see( animate );
      }
      _canvas.grab_focus();
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if there is a root that is available for selection.
  public bool root_selectable() {
    var current_node = _selected.current_node();
    var current_conn = _selected.current_connection();
    return( (current_conn == null) && ((current_node == null) ? (_model.get_nodes().length > 0) : (current_node.get_root() != current_node)) );
  }

  //-------------------------------------------------------------
  // If there is no current node, selects the first root node;
  // otherwise, selects the current node's root node.
  public void select_root_node() {
    if( _selected.current_connection() != null ) return;
    var current = get_current_node();
    if( current == null ) {
      if( _model.get_nodes().length > 0 ) {
        if( select_node( _model.get_nodes().index( 0 ) ) ) {
          queue_draw();
        }
      }
    } else if( select_node( current.get_root() ) ) {
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Returns the next node to select after the current node is
  // removed.
  public Node? next_node_to_select() {
    var current = _selected.current_node();
    if( current != null ) {
      if( current.is_root() ) {
        var nodes = _model.get_nodes();
        if( nodes.length > 1 ) {
          for( int i=0; i<nodes.length; i++ ) {
            if( nodes.index( i ) == current ) {
              if( i == 0 ) {
                return( nodes.index( 1 ) );
              } else if( (i + 1) == nodes.length ) {
                return( nodes.index( i - 1 ) );
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
  // Selects the next (dir = 1) or previous (dir = -1) sibling.
  public void select_sibling_node( int dir ) {
    var current = _selected.current_node();
    var str_dir = (dir == 1) ? "next" : "prev";
    if( select_node( _model.sibling_node( current, str_dir, true ) ) ) {
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Returns true if there are any selected nodes that contain
  // children.
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
    var current = get_current_node();
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
    var current = get_current_node();
    _selected.add_node_tree( current );
    queue_draw();
  }

  //-------------------------------------------------------------
  // Returns true if any of the selected nodes contains a parent
  // node.
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
      _canvas.see();
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Selects the callout associated with the current node (if one
  // exists).
  public void select_callout() {
    if( is_node_selected() && (get_current_node().callout != null) ) {
      set_current_callout( get_current_node().callout );
    }
  }

  //-------------------------------------------------------------
  // Selects the node that is linked to the specified node.  If
  // node is null, use the current node.
  public void select_linked_node( Node? node = null ) {
    var n = node;
    if( n == null ) {
      n = get_current_node();
    }
    if( (n != null) && (n.linked_node != null) ) {
      n.linked_node.select( this );
    }
  }

  //-------------------------------------------------------------
  // Returns the array of selected nodes
  public Array<Node> get_selected_nodes() {
    return( _selected.nodes() );
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

    var nodes = new Array<Node>();
    _model.get_nodes_within_rectangle( box, nodes );

    if( !shift ) {
      _selected.change_nodes( nodes );
    } else {
      _selected.add_nodes( nodes );
    }

  }

  //-------------------------------------------------------------
  // CONNECTION SELECTION METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Returns the current connection
  public Connection? get_current_connection() {
    return( _selected.current_connection() );
  }

  //-------------------------------------------------------------
  // Helper function that returns true if a connection is currently
  // selected and matches the given mode.
  private bool is_connection_mode( ConnMode mode ) {
    var current = get_current_connection();
    return( (current != null) && (current.mode == mode) );
  }

  //-------------------------------------------------------------
  // Returns true if we are connecting a connection title.
  public bool is_connection_connecting() {
    return( is_connection_mode( ConnMode.CONNECTING ) );
  }

  //-------------------------------------------------------------
  // Returns true if we are editing a connection title.
  public bool is_connection_editable() {
    return( is_connection_mode( ConnMode.EDITABLE ) );
  }

  //-------------------------------------------------------------
  // Returns if a connection is currently selected.
  public bool is_connection_selected() {
    return( is_connection_mode( ConnMode.SELECTED ) );
  }

  //-------------------------------------------------------------
  // Sets the current connection to the given node
  public void set_current_connection( Connection? c ) {
    if( c != null ) {
      _selected.set_current_connection( c );
      c.from_node.last_selected_connection = c;
      if( c.to_node != null ) {
        c.to_node.last_selected_connection = c;
      }
    } else {
      _selected.clear_connections();
    }
  }

  //-------------------------------------------------------------
  // Selects the given connection node.
  public void select_connection_node( bool start ) {
    var current = get_current_connection();
    if( current != null ) {
      if( select_node( start ? current.from_node : current.to_node ) ) {
        _canvas.clear_current_connection( true );
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Selects the next connection in the list.
  public void select_connection( int dir ) {
    var current = get_current_connection();
    if( current != null ) {
      var conn = _model.connections.get_connection( current, dir );
      if( conn != null ) {
        set_current_connection( conn );
        _canvas.see();
        queue_draw();
      }
    }
  }

  //-------------------------------------------------------------
  // Selects the first connection in the list.
  public void select_attached_connection() {
    var current = get_current_node();
    if( current != null ) {
      if( current.last_selected_connection != null ) {
        set_current_connection( current.last_selected_connection );
        _canvas.see();
        queue_draw();
      } else {
        var conn = _model.connections.get_attached_connection( current );
        if( conn != null ) {
          set_current_connection( conn );
          _canvas.see();
          queue_draw();
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Returns the array of selected connections
  public Array<Connection> get_selected_connections() {
    return( _selected.connections() );
  }

  //-------------------------------------------------------------
  // CALLOUT SELECTION METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Selects the node associated with the current callout.
  public void select_callout_node() {
    if( is_callout_selected() ) {
      set_current_node( get_current_callout().node );
      _selected.clear_callouts( false );
    }
  }

  //-------------------------------------------------------------
  // Returns the current callout
  public Callout? get_current_callout() {
    return( _selected.current_callout() );
  }

  //-------------------------------------------------------------
  // Helper function that returns true if a callout is currently
  // selected and matches the given mode.
  private bool is_callout_mode( CalloutMode mode ) {
    var current = get_current_callout();
    return( (current != null) && (current.mode == mode) );
  }

  //-------------------------------------------------------------
  // Returns if a callout is currently selected.
  public bool is_callout_selected() {
    return( is_callout_mode( CalloutMode.SELECTED ) );
  }

  //-------------------------------------------------------------
  // Returns true if we are editing a callout title.
  public bool is_callout_editable() {
    return( is_callout_mode( CalloutMode.EDITABLE ) );
  }

  //-------------------------------------------------------------
  // Sets the current selected callout to the specified callout
  public void set_current_callout( Callout? c ) {
    _selected.set_current_callout( c );
  }

  //-------------------------------------------------------------
  // Returns the array of selected callouts
  public Array<Callout> get_selected_callouts() {
    return( _selected.callouts() );
  }

  //-------------------------------------------------------------
  // GROUP SELECTION METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Returns the current group (if selected)
  public NodeGroup? get_current_group() {
    return( _selected.current_group() );
  }

  //-------------------------------------------------------------
  // Returns if a group is currently selected.
  public bool is_group_selected() {
    return( get_current_group() != null );
  }

  //-------------------------------------------------------------
  // Sets the current selected group to the specified group
  public void set_current_group( NodeGroup? g ) {
    _selected.set_current_group( g );
  }

  //-------------------------------------------------------------
  // Selects the main node(s) of the current groups.
  public void group_select_main() {
    var groups = get_selected_groups();
    for( int i=0; i<groups.length; i++ ) {
      var nodes = groups.index( i ).nodes;
      for( int j=0; j<nodes.length; j++ ) {
        selected.add_node( nodes.index( j ), false, false );
      }
    }
    selected.clear_groups();
  }

  //-------------------------------------------------------------
  // Selecta all of the nodes within the selected groups.
  public void group_select_all() {
    var groups   = get_selected_groups();
    for( int i=0; i<groups.length; i++ ) {
      var nodes = groups.index( i ).nodes;
      for( int j=0; j<nodes.length; j++ ) {
        selected.add_node_tree( nodes.index( j ), false );
      }
    }
    selected.clear_groups();
  }

  //-------------------------------------------------------------
  // Returns the array of selected groups
  public Array<NodeGroup> get_selected_groups() {
    return( _selected.groups() );
  }

  //-------------------------------------------------------------
  // STICKER SELECTION METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Returns the current sticker (if selected).
  public Sticker? get_current_sticker() {
    return( _selected.current_sticker() );
  }

  //-------------------------------------------------------------
  // Returns if a sticker is currently selected.
  public bool is_sticker_selected() {
    return( get_current_sticker() != null );
  }

  //-------------------------------------------------------------
  // Sets the current selected sticker to the specified sticker
  public void set_current_sticker( Sticker? s ) {
    _selected.set_current_sticker( s );
    _model.stickers.select_sticker( s );
  }

  //-------------------------------------------------------------
  // GENERAL SELECTION FUNCTIONS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Selects all of the text in the current node.
  public void select_all() {
    var text = get_current_text();
    if( text != null ) {
      text.set_cursor_all( false );
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Deselects all of the text in the current node.
  public void deselect_all() {
    var text = get_current_text();
    if( text != null ) {
      text.clear_selection();
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // UNDO BUFFER
  //-------------------------------------------------------------

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
  // Adds an undoable operation to the undo buffer.
  public void add_undo( UndoItem item ) {
    _undo_buffer.add_item( item );
  }

  //-------------------------------------------------------------
  // Adds an undoable text operation to the undo buffer.
  public void add_text_undo( UndoTextItem item ) {
    _undo_buffer.add_item( item );
  }

  //-------------------------------------------------------------
  // CLIPBOARD
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Pastes the contents of the clipboard into the current node.
  public void do_paste( bool shift ) {
    MinderClipboard.paste( this, shift );
  }

  //-------------------------------------------------------------
  // Paste the current node as a node link in the current node.
  public void do_paste_node_link() {
    if( MinderClipboard.node_pasteable() ) {
      MinderClipboard.paste_node_link( this );
    }
  }

  //-------------------------------------------------------------
  // NODE FUNCTIONS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Convenience function that provides an array of all of the
  // root nodes in the mindmap.
  public Array<Node> get_nodes() {
    return( _model.get_nodes() );
  }

  //-------------------------------------------------------------
  // Returns the sibling node in the given direction from the
  // currently selected node.
  public Node? sibling_node( int dir, bool wrap = false ) {
    var str_dir = (dir == 1) ? "next" : "prev";
    return( _model.sibling_node( get_current_node(), str_dir, wrap ) );
  }

  //-------------------------------------------------------------
  // Display a color picker to change the color of the current link.
  public void change_current_link_color() {
    var color_picker = new ColorChooserDialog( _( "Select a link color" ), _win );
    color_picker.color_activated.connect((color) => {
      _model.change_current_link_color( color );
    });
    color_picker.present();
  }

  //-------------------------------------------------------------
  // Removes the tags from all nodes in the model, returning the
  // list of nodes that were affected.
  public void remove_tag( Tag tag, Array<Node> nodes ) {
    _model.remove_tag( tag, nodes );
  }

  //-------------------------------------------------------------
  // Swaps the position of the two nodes in the mindmap.
  public void swap_nodes( Node node, Node other ) {

    var complete = false;

    if( node.previous_sibling() == other ) {
      var index   = node.index();
      var summary = node.summary_node();
      animator.add_nodes( get_nodes(), false, "swap_with_previous_sibling" );
      node.swap_with_previous_sibling();
      add_undo( new UndoNodeMove( node, node.side, index, summary ) );
      complete = true;

    } else if( other.previous_sibling() == node ) {
      var index   = other.index();
      var summary = other.summary_node();
      animator.add_nodes( get_nodes(), false, "swap_with_next_sibling" );
      other.swap_with_previous_sibling();
      add_undo( new UndoNodeMove( other, other.side, index, summary ) );
      complete = true;

    } else if( (other == node.parent) && !node.parent.is_root() ) {
      animator.add_nodes( get_nodes(), false, "make_sibling_of_grandparent" );
      add_undo( new UndoNodeUnclify( node ) );
      node.make_parent_sibling();
      complete = true;

    } else if( node.contains_node( other ) ) {
      var idx          = node.index();
      var num_children = (int)node.children().length;
      animator.add_nodes( get_nodes(), false, "make_children_siblings" );
      node.make_children_siblings();
      add_undo( new UndoNodeReparent( node, idx, (idx + num_children) ) );
      complete = true;
    }

    if( complete ) {
      animator.animate();
      queue_draw();
      auto_save();
    }

  }

  //-------------------------------------------------------------
  // Attach all of the selected nodes to the current attachment node.
  public void attach_selected_nodes() {

    assert( _model.attach_node != null );

    var nodes = _selected.ordered_nodes();

    add_undo( new UndoNodesAttach( nodes, _model.attach_node ) );

    animator.add_nodes( get_nodes(), false, "attach_selected_nodes" );
    _model.attach_nodes( nodes, _model.attach_node );
    _model.set_attach_node( null );
    animator.animate();

    auto_save();

  }

  //-------------------------------------------------------------
  // FOCUS MODE FUNCTIONS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Update the focus mode.
  public void update_focus_mode() {
    var selnodes = selected.nodes();
    var selconns = selected.connections();
    var alpha    = (_highlighted.size() > 0) ||
                   (_focus_mode && ((selnodes.length > 0) || (selconns.length > 0))) ? _focus_alpha : 1.0;
    var nodes    = _model.get_nodes();
    for( int i=0; i<nodes.length; i++ ) {
      nodes.index( i ).alpha = alpha;
    }
    if( _highlighted.size() > 0 ) {
      _model.highlight_tags( _highlighted, _highlight_mode );
    } else if( _focus_mode ) {
      for( int i=0; i<selnodes.length; i++ ) {
        var current = selnodes.index( i );
        current.alpha = 1.0;
        var parent = current.parent;
        while( parent != null ) {
          parent.set_alpha_only( 1.0 );
          parent = parent.parent;
        }
      }
      _model.connections.update_alpha();
      for( int i=0; i<selconns.length; i++ ) {
        selconns.index( i ).alpha = 1.0;
      }
    }
    queue_draw();
  }

  //-------------------------------------------------------------
  // Updates all alpha values with the given value.
  public void update_focus_mode_alpha() {
    var key   = "focus-mode-alpha";
    var alpha = _settings.get_double( key );
    if( (alpha < 0) || (alpha >= 1.0) ) {
      _settings.set_double( key, _focus_alpha );
    } else if( _focus_alpha != alpha ) {
      _focus_alpha = alpha;
      var nodes = _model.get_nodes();
      for( int i=0; i<nodes.length; i++ ) {
        nodes.index( i ).update_alpha( alpha );
      }
      _model.connections.update_alpha();
      queue_draw();
    }
  }

  //-------------------------------------------------------------
  // MISCELLANEOUS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Retrieves canvas size settings and returns the approximate
  // dimensions based on saved settings.
  public void get_saved_dimensions( out int width, out int height ) {
    var sidebar_width = _settings.get_boolean( "current-properties-shown" ) ||
                        _settings.get_boolean( "map-properties-shown" )     ||
                        _settings.get_boolean( "sticker-properties-shown" ) ||
                        _settings.get_boolean( "style-properties-shown" ) ? _settings.get_int( "properties-width" ) : 0;
    width  = _settings.get_int( "window-w" ) - sidebar_width;
    height = _settings.get_int( "window-h" );
  }

  //-------------------------------------------------------------
  // Causes the canvas to be redrawn.
  public void queue_draw() {
    _canvas.queue_draw();
  }

  //-------------------------------------------------------------
  // Convenience function to cause the map model to be saved to
  // the filesystem.
  public void auto_save() {
    _model.auto_save();
  }

  //-------------------------------------------------------------
  // Convenience function that returns the current theme.
  public Theme get_theme() {
    return( _model.get_theme() );
  }

}
