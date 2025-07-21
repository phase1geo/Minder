/*
* Copyright (c) 2025 (https://github.com/phase1geo/Minder)
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
  public UndoTextBuffer undo_text {
    get {
      return( _undo_text );
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
      return( _image_manager );
    }
  }
  public Layouts layouts {
    get {
      return( _layouts );
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
  public signal void save_state_changed();
  public signal void undo_buffer_changed( UndoBuffer buf );

  //-------------------------------------------------------------
  // Constructor
  public MindMap( MainWindow win, GLib.Settings settings ) {

    _win      = win;
    _settings = settings;

    // Create the drawing area where the map will be drawn and interacted with
    _canvas = new DrawArea( this, win );

    // Create the map model
    _model = new MapModel( this );

    // Create the document
    _doc = new Document( this );

    // Create undo buffer
    _undo_buffer = new UndoBuffer( this );

    // Create text undo buffer
    _undo_text = new UndoTextBuffer( this );

    // Create the selection handler
    _selected = new Selection( this );

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
    _canvas.show_properties.connect( handle_show_properties );
    _canvas.hide_properties.connect( handle_hide_properties );

    _doc.save_state_changed.connect( handle_save_state_changed );

    _undo_buffer.buffer_changed.connect( handle_undo_buffer_changed );

    _selected.selection_changed.connect( handle_selection_changed );

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
  // Handles any requests to show the properties sidebar.
  private void handle_show_properties( string? tab, PropertyGrab grab_type ) {
    show_properties( tab, grab_type );
  }

  //-------------------------------------------------------------
  // Handles any requests to hide the properties sidebar.
  private void handle_hide_properties() {
    hide_properties();
  }

  //-------------------------------------------------------------
  // Handles any indications that the save state has changed.
  private void handle_save_state_changed() {
    save_state_changed();
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

    // Initialize variables
    // TBD

  }

  //-------------------------------------------------------------
  // Initializes the canvas to prepare it for a document that
  // will be loaded.
  public void initialize_for_open() {

    initialize();

    _model.set_current_node( null );

    _canvas.queue_draw();

  }

  //-------------------------------------------------------------
  // Initialize the empty drawing area with a node.
  public void initialize_for_new() {

    initialize();

    // Create the main idea node
    var n = new Node.with_name( this, _("Main Idea"), _model.layouts.get_default() );

    // Get the rough dimensions of the canvas
    int wwidth, wheight;
    get_saved_dimensions( out wwidth, out wheight );

    // Set the node information
    n.posx  = (wwidth  / 2) - 30;
    n.posy  = (wheight / 2) - 10;
    n.style = StyleInspector.styles.get_global_style();

    _model.get_nodes().append_val( n );

    // Make this initial node the current node
    _model.set_current_node( n );
    Idle.add(() => {
      _model.set_node_mode( n, NodeMode.EDITABLE, false );
      return( false );
    });

    // Redraw the canvas
    _canvas.queue_draw();

  }

  //-------------------------------------------------------------
  // SELECTION METHODS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Returns the current node.
  public Node? get_current_node() {
    return( _selected.current_node() );
  }

  //-------------------------------------------------------------
  // Returns if a node is currently selected.
  public bool is_node_selected() {
    return( get_current_node() != null );
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
  // Returns the current connection
  public Connection? get_current_connection() {
    return( _selected.current_connection() );
  }

  //-------------------------------------------------------------
  // Returns if a connection is currently selected.
  public bool is_connection_selected() {
    return( get_current_connect() != null );
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
  // Returns the current callout
  public Callout? get_current_callout() {
    return( _selected.current_callout() );
  }

  //-------------------------------------------------------------
  // Returns if a callout is currently selected.
  public bool is_callout_selected() {
    return( get_current_callout() != null );
  }

  //-------------------------------------------------------------
  // Sets the current selected callout to the specified callout
  public void set_current_callout( Callout? c ) {
    _selected.set_current_callout( c );
  }

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
    _stickers.select_sticker( s );
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
  // Returns the array of selected groups
  public Array<NodeGroup> get_selected_groups() {
    return( _selected.groups() );
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
  // NODE FUNCTIONS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Convenience function that provides an array of all of the
  // root nodes in the mindmap.
  public Array<Node> get_nodes() {
    return( _model.get_nodes() );
  }

  //-------------------------------------------------------------
  // Convenience function that provides the connections in the
  // mind map.
  public Connections get_connections() {
    return( _model.get_connections() );
  }

  //-------------------------------------------------------------
  // MISCELLANEOUS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // Updates the CSS for the current theme.
  public void update_css() {
    StyleContext.add_provider_for_display(
      Display.get_default(),
      _model.get_theme().get_css_provider( _win.text_size ),
      STYLE_PROVIDER_PRIORITY_APPLICATION
    );
  }

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
  // Sets the focus mode
  public void set_focus_mode( bool mode ) {
    _model.set_focus_mode( selected, mode );  // TODO - Avoiding name collisions
  }

  //-------------------------------------------------------------
  // Updates the focus mode
  public void update_focus_mode() {
    _model.update_focus_mode( selected );
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
