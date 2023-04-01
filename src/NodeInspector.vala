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
using Gdk;
using Granite.Widgets;

public class NodeInspector : Box {

  private const Gtk.TargetEntry[] DRAG_TARGETS = {
    {"text/uri-list", 0, 0}
  };

  private ScrolledWindow _sw;
  private Switch         _task;
  private Switch         _fold;
  private Revealer       _link_reveal;
  private ColorButton    _link_color;
  private NoteView       _note;
  private DrawArea?      _da = null;
  private Button         _detach_btn;
  private string         _orig_note = "";
  private Node?          _node = null;
  private Stack          _image_stack;
  private Image          _image;
  private Button         _image_btn;
  private Label          _image_loc;
  private Switch         _override;
  private ColorButton    _root_color;
  private Revealer       _root_color_reveal;
  private Revealer       _color_reveal;
  private ToggleButton   _resize;

  public NodeInspector( MainWindow win ) {

    Object( orientation:Orientation.VERTICAL, spacing:0 );

    /* Create the node widgets */
    create_title();
    create_task();
    create_fold();
    create_link();
    create_color();
    create_note( win );
    create_image();
    create_buttons();

    show_all();

    win.canvas_changed.connect( tab_changed );

  }

  /* Called whenever the user clicks on a tab in the tab bar */
  private void tab_changed( DrawArea? da ) {
    if( _da != null ) {
      _da.current_changed.disconnect( node_changed );
      _da.theme_changed.disconnect( theme_changed );
    }
    _da = da;
    if( da != null ) {
      da.current_changed.connect( node_changed );
      da.theme_changed.connect( theme_changed );
      node_changed();
    }
  }

  /* Sets the width of this inspector to the given value */
  public void set_width( int width ) {
    _sw.width_request = width;
  }

  private void create_title() {

    var title = new Label( "<big>" + _( "Node" ) + "</big>" );
    title.use_markup = true;
    title.justify    = Justification.CENTER;

    pack_start( title, false, true );

  }

  /* Creates the task UI elements */
  private void create_task() {

    var lbl  = new Label( Utils.make_title( _( "Task" ) ) );
    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _task = new Switch();
    _task.button_release_event.connect( task_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.pack_start( lbl,   false, true, 0 );
    box.pack_end(   _task, false, true, 0 );

    pack_start( box, false, true, 5 );

  }

  /* Creates the fold UI elements */
  private void create_fold() {

    var lbl = new Label( Utils.make_title( _( "Fold" ) ) );
    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _fold = new Switch();
    _fold.button_release_event.connect( fold_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.pack_start( lbl,   false, true, 0 );
    box.pack_end(   _fold, false, true, 0 );

    pack_start( box, false, true, 5 );

  }

  /*
   Allows the user to select a different color for the current link
   and tree.
  */
  private void create_link() {

    var lbl = new Label( Utils.make_title( _( "Color" ) ) );
    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _link_color = new ColorButton();
    _link_color.color_set.connect(() => {
      _da.change_current_link_color( _link_color.rgba );
    });

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.homogeneous   = true;
    box.margin_top    = 5;
    box.margin_bottom = 5;
    box.pack_start( lbl,         false, true, 0 );
    box.pack_end(   _link_color, true,  true, 0 );

    _link_reveal = new Revealer();
    _link_reveal.transition_type = RevealerTransitionType.NONE;
    _link_reveal.add( box );

    pack_start( _link_reveal, false, true );

  }

  /*
   Allows the user to select a different color for the current root
   node.
  */
  private void create_color() {

    var lbl = new Label( Utils.make_title( _( "Override Color" ) ) );
    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _override = new Switch();
    _override.button_release_event.connect( root_color_changed );

    var box = new Box( Orientation.HORIZONTAL, 0 );
    box.margin_top    = 5;
    box.margin_bottom = 5;
    box.pack_start( lbl, false, true, 0 );
    box.pack_end( _override, false, true, 0 );

    var l = new Label("");

    _root_color = new ColorButton();
    _root_color.color_set.connect(() => {
      _da.change_current_link_color( _root_color.rgba );
    });

    var cbox = new Box( Orientation.HORIZONTAL, 0 );
    cbox.homogeneous = true;
    cbox.margin_bottom = 5;
    cbox.pack_start( l, false, true, 0 );
    cbox.pack_end( _root_color, false, true, 0 );

    _color_reveal = new Revealer();
    _color_reveal.add( cbox );

    var hbox = new Box( Orientation.VERTICAL, 0 );
    hbox.margin_bottom = 5;
    hbox.pack_start( box, false, true, 0 );
    hbox.pack_start( _color_reveal, false, true, 0 );

    _root_color_reveal = new Revealer();
    _root_color_reveal.transition_type = RevealerTransitionType.NONE;
    _root_color_reveal.add( hbox );

    pack_start( _root_color_reveal, false, true );

  }

  /* Creates the note widget */
  private void create_note( MainWindow win ) {

    Label lbl = new Label( Utils.make_title( _( "Note" ) ) );

    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    _note = new NoteView();
    _note.set_wrap_mode( Gtk.WrapMode.WORD );
    _note.add_unicode_completion( win.unicoder );
    _note.buffer.text = "";
    _note.buffer.changed.connect( note_changed );
    _note.focus_in_event.connect( note_focus_in );
    _note.focus_out_event.connect( note_focus_out );

    _sw = new ScrolledWindow( null, null );
    _sw.min_content_width  = 300;
    _sw.min_content_height = 100;
    _sw.add( _note );

    var box = new Box( Orientation.VERTICAL, 0 );
    box.pack_start( lbl, false, false );
    box.pack_start( _sw, true,  true );

    pack_start( box, true, true, 5 );

  }

  private void create_image() {

    _image_stack = new Stack();
    _image_stack.transition_type = StackTransitionType.NONE;
    _image_stack.homogeneous     = false;
    _image_stack.add_named( create_image_add(),  "add" );
    _image_stack.add_named( create_image_edit(), "edit" );

    pack_start( _image_stack, false, true, 5 );

  }

  /* Creates the add image widget */
  private Box create_image_add() {

    var lbl  = new Label( Utils.make_title( _( "Image" ) ) );
    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    var btn = new Button.with_label( _( "Add Image…" ) );
    btn.clicked.connect( image_button_clicked );

    var box = new Box( Orientation.VERTICAL, 10 );
    box.pack_start( lbl, false, false );
    box.pack_start( btn, false, true );

    return( box );

  }

  /* Creates the edit image widget */
  private Box create_image_edit() {

    var lbl  = new Label( Utils.make_title( _( "Image" ) ) );
    lbl.xalign     = (float)0;
    lbl.use_markup = true;

    var btn_edit = new Button.from_icon_name( "document-edit-symbolic" );
    btn_edit.set_tooltip_text( _( "Edit Image" ) );
    btn_edit.clicked.connect(() => {
      _da.edit_current_image();
    });

    var btn_del = new Button.from_icon_name( "edit-delete-symbolic" );
    btn_del.set_tooltip_text( _( "Remove Image" ) );
    btn_del.clicked.connect(() => {
      _da.delete_current_image();
    });

    _resize = new ToggleButton();
    _resize.image = new Image.from_icon_name( "view-fullscreen-symbolic", IconSize.SMALL_TOOLBAR );
    _resize.set_tooltip_text( _( "Resizable" ) );
    _resize.toggled.connect(() => {
      var current = _da.get_current_node();
      if( current != null ) {
        current.image_resizable = _resize.get_active();
        _da.auto_save();
      }
    });

    var image_btn_box = new Box( Orientation.HORIZONTAL, 10 );
    image_btn_box.pack_start( _resize,  false, false );
    image_btn_box.pack_start( btn_edit, false, false );
    image_btn_box.pack_start( btn_del,  false, false );

    // var resize_lbl = new Label( Utils.make_title( _( "Resizable" ) ) );
    // var resize_lbl = new Label( _( "Resizable" ) );
    //resize_lbl.xalign     = (float)0;
    //resize_lbl.use_markup = true;

//    _resize = new Switch();
 //   _resize.button_release_event.connect( resize_changed );

//    var resize_box = new Box( Orientation.HORIZONTAL, 10 );
    //resize_box.margin_left  = 20;
    //resize_box.margin_right = 20;
 //   resize_box.pack_start( resize_lbl, false, false, 0 );
  //  resize_box.pack_start( _resize,    false, false, 0 );

    var tbox = new Box( Orientation.HORIZONTAL, 10 );
    tbox.pack_start( lbl,         false, false );
    tbox.pack_end( image_btn_box, false, false );
   // tbox.pack_end( resize_box,    false, false );

    _image = new Image();
    _image.margin_bottom = 20;

//    _image_loc = new Label( "" );
//    _image_loc.use_markup = true;
//    _image_loc.wrap       = true;
//    _image_loc.max_width_chars = 40;
//    _image_loc.activate_link.connect( image_link_clicked );

    var box  = new Box( Orientation.VERTICAL, 10 );
    box.pack_start( tbox,       false, false );
    box.pack_start( _image,     true,  true );
    // box.pack_start( _image_loc, false, true );
    // box.pack_start( resize_box, false, true );

    /* Set ourselves up to be a drag target */
    Gtk.drag_dest_set( _image, DestDefaults.MOTION | DestDefaults.DROP, DRAG_TARGETS, Gdk.DragAction.COPY );

    _image.drag_data_received.connect((ctx, x, y, data, info, t) => {
      if( data.get_uris().length == 1 ) {
        if( _da.update_current_image( data.get_uris()[0] ) ) {
          Gtk.drag_finish( ctx, true, false, t );
        }
      }
    });

    return( box );

  }

  /* Called when the user clicks on the image button */
  private void image_button_clicked() {

    _da.add_current_image();

  }

  /* Called if the user clicks on the image URI */
  private bool image_link_clicked( string uri ) {

    File file = File.new_for_uri( uri );

    /* If the URI is a file on the local filesystem, view it with the Files app */
    if( file.get_uri_scheme() == "file" ) {
      var files = AppInfo.get_default_for_type( "inode/directory", true );
      var list  = new List<File>();
      list.append( file );
      try {
        files.launch( list, null );
      } catch( Error e ) {
        return( false );
      }
      return( true );
    }

    return( false );

  }

  /* Creates the node editing button grid and adds it to the popover */
  private void create_buttons() {

    var grid = new Grid();
    grid.column_homogeneous = true;
    grid.column_spacing     = 5;

    var copy_btn = new Button.from_icon_name( "edit-copy-symbolic", IconSize.SMALL_TOOLBAR );
    copy_btn.set_tooltip_text( _( "Copy Node To Clipboard" ) );
    copy_btn.clicked.connect( node_copy );

    var cut_btn = new Button.from_icon_name( "edit-cut-symbolic", IconSize.SMALL_TOOLBAR );
    cut_btn.set_tooltip_text( _( "Cut Node To Clipboard" ) );
    cut_btn.clicked.connect( node_cut );

    /* Create the detach button */
    _detach_btn = new Button.from_icon_name( "minder-detach-symbolic", IconSize.SMALL_TOOLBAR );
    _detach_btn.set_tooltip_text( _( "Detach Node" ) );
    _detach_btn.clicked.connect( node_detach );

    /* Create the node deletion button */
    var del_btn = new Button.from_icon_name( "edit-delete-symbolic", IconSize.SMALL_TOOLBAR );
    del_btn.set_tooltip_text( _( "Delete Node" ) );
    del_btn.clicked.connect( node_delete );

    /* Add the buttons to the button grid */
    grid.attach( copy_btn,    0, 0, 1, 1 );
    grid.attach( cut_btn,     1, 0, 1, 1 );
    grid.attach( _detach_btn, 2, 0, 1, 1 );
    grid.attach( del_btn,     3, 0, 1, 1 );

    /* Add the button grid to the popover */
    // pack_start( grid, false, true );

  }

  /* Called whenever the task enable switch is changed within the inspector */
  private bool task_changed( Gdk.EventButton e ) {
    var current = _da.get_current_node();
    if( current != null ) {
      _da.change_current_task( !current.task_enabled(), false );
    }
    return( false );
  }

  /* Called whenever the fold switch is changed within the inspector */
  private bool fold_changed( Gdk.EventButton e ) {
    var current = _da.get_current_node();
    if( current != null ) {
      _da.change_current_fold( !current.folded );
    }
    return( false );
  }

  /*
   Called whenever the user chooses to override the root color via
   this sidebar.  We will show/hide the color changer.
  */
  private bool root_color_changed( Gdk.EventButton e ) {
    var current = _da.get_current_node();
    if( _color_reveal.reveal_child ) {
      _color_reveal.reveal_child = false;
      if( current != null ) {
        _da.change_current_link_color( null );
      }
    } else {
      _color_reveal.reveal_child = true;
      if( (current != null) && (_root_color.rgba != _da.get_theme().get_color( "root_background" )) ) {
        _da.change_current_link_color( _root_color.get_rgba() );
      }
    }
    return( false );
  }

  /*
   Called whenever the text widget is changed.  Updates the current node
   and redraws the canvas when needed.
  */
  private void note_changed() {
    _da.change_current_node_note( _note.buffer.text );
  }

  /* Saves the original version of the node's note so that we can */
  private bool note_focus_in( EventFocus e ) {
    _node      = _da.get_current_node();
    _orig_note = _note.buffer.text;
    return( false );
  }

  /* When the note buffer loses focus, save the note change to the undo buffer */
  private bool note_focus_out( EventFocus e ) {
    if( (_node != null) && (_node.note != _orig_note) ) {
      _da.undo_buffer.add_item( new UndoNodeNote( _node, _orig_note ) );
    }
    return( false );
  }

  /* Copies the current node to the clipboard */
  private void node_copy() {
    MinderClipboard.copy_nodes( _da );
  }

  /* Cuts the current node to the clipboard */
  private void node_cut() {
    _da.cut_node_to_clipboard();
  }

  /* Detaches the current node and makes it a parent node */
  private void node_detach() {
    _da.detach();
    _detach_btn.set_sensitive( false );
  }

  /* Deletes the current node */
  private void node_delete() {
    _da.delete_node();
  }

  /* Grabs the focus on the note widget */
  public void grab_note() {
    _note.grab_focus();
    node_changed();
  }

  /* Called whenever the fold switch is changed within the inspector */
  private bool resize_changed( Gdk.EventButton e ) {
    var current = _da.get_current_node();
    if( current != null ) {
      current.image_resizable = !current.image_resizable;
      _da.auto_save();
    }
    return( false );
  }

  /* Called whenever the theme is changed */
  private void theme_changed( DrawArea da ) {

    int    num_colors = Theme.num_link_colors();
    RGBA[] colors     = new RGBA[num_colors];

    /* Gather the theme colors into an RGBA array */
    for( int i=0; i<num_colors; i++ ) {
      colors[i] = _da.get_theme().link_color( i );
    }

    /* Clear the palette */
    _link_color.add_palette( Orientation.HORIZONTAL, 10, null );

    /* Set the palette with the new theme colors */
    _link_color.add_palette( Orientation.HORIZONTAL, 10, colors );

  }

  /* Called whenever the user changes the current node in the canvas */
  private void node_changed() {

    Node? current = _da.get_current_node();

    if( current != null ) {
      _task.set_active( current.task_enabled() );
      if( current.is_leaf() ) {
        _fold.set_active( false );
        _fold.set_sensitive( false );
      } else {
        _fold.set_active( current.folded );
        _fold.set_sensitive( true );
      }
      if( current.is_root() ) {
        _link_reveal.reveal_child       = false;
        _root_color_reveal.reveal_child = true;
        _override.set_active( current.link_color_set );
        _color_reveal.reveal_child = current.link_color_set;
        _root_color.rgba  = current.link_color_set ? current.link_color : _da.get_theme().get_color( "root_background" );
        _root_color.alpha = 65535;
      } else {
        _link_reveal.reveal_child       = true;
        _root_color_reveal.reveal_child = false;
        _link_color.rgba  = current.link_color;
        _link_color.alpha = 65535;
      }
      _detach_btn.set_sensitive( current.parent != null );
      var note = current.note;
      _note.buffer.text = note;
      if( current.image != null ) {
        var url = _da.image_manager.get_uri( current.image.id ).replace( "&", "&amp;" );
        var str = "<a href=\"" + url + "\">" + url + "</a>";
        current.image.set_image( _image );
        _image_loc.label = str;
        _resize.set_active( current.image_resizable );
        _image_stack.visible_child_name = "edit";
      } else {
        _image_stack.visible_child_name = "add";
      }
    }

  }

  /* Sets the input focus on the first widget in this inspector */
  public void grab_first() {
    _task.grab_focus();
    node_changed();
  }

}
