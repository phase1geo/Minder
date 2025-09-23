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

  private ScrolledWindow _sw;
  private Switch         _task;
  private Switch         _fold;
  private Switch         _sequence;
  private Box            _link_box;
  private ColorButton    _link_color;
  private NoteView       _note;
  private MindMap?       _map = null;
  private Button         _detach_btn;
  private string         _orig_note = "";
  private Node?          _node = null;
  private Stack          _image_stack;
  private Picture        _image;
  private Button         _image_btn;
  private Label          _image_loc;
  private Switch         _override;
  private ColorButton    _root_color;
  private Box            _root_color_box;
  private Revealer       _color_reveal;
  private ToggleButton   _resize;
  private bool           _ignore = false;

  public signal void update_icons();
  public signal void editable_changed();

  //-------------------------------------------------------------
  // Constructor.
  public NodeInspector( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 10 );

    /* Create the node widgets */
    create_title();
    create_task();
    create_fold();
    create_sequence();
    create_link();
    create_color();
    create_note( win );
    create_image();
    create_buttons();

    win.canvas_changed.connect( tab_changed );

  }

  //-------------------------------------------------------------
  // Called whenever the user clicks on a tab in the tab bar.
  private void tab_changed( MindMap? map ) {
    if( _map != null ) {
      _map.current_changed.disconnect( node_changed );
      _map.theme_changed.disconnect( theme_changed );
    }
    _map = map;
    if( map != null ) {
      map.current_changed.connect( node_changed );
      map.theme_changed.connect( theme_changed );
      node_changed();
      editable_changed();
    }
  }

  //-------------------------------------------------------------
  // Sets the width of this inspector to the given value.
  public void set_width( int width ) {
    _sw.width_request = width;
  }

  //-------------------------------------------------------------
  // Creates a label with text displayed as a title.
  private void create_title() {

    var title = new Label( "<big>" + _( "Node" ) + "</big>" ) {
      halign     = Align.FILL,
      use_markup = true,
      justify    = Justification.CENTER
    };

    append( title );

  }

  //-------------------------------------------------------------
  // Creates the task UI elements.
  private void create_task() {

    var lbl = new Label( _( "Task" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };
    lbl.add_css_class( "titled" );

    _task = new Switch() {
      halign = Align.END
    };
    _task.notify["active"].connect( task_changed );

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _task );

    append( box );

  }

  //-------------------------------------------------------------
  // Creates the fold UI elements.
  private void create_fold() {

    var lbl = new Label( _( "Fold" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0
    };
    lbl.add_css_class( "titled" );

    _fold = new Switch() {
      halign = Align.END
    };
    _fold.notify["active"].connect( fold_changed );

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( _fold );

    append( box );

  }

  //-------------------------------------------------------------
  // Creates the sequence UI elements.
  private void create_sequence() {

    var lbl = new Label( _( "Sequence" ) ) {
      halign = Align.START,
      xalign = (float)0,
    };
    lbl.add_css_class( "titled" );

    var info = new Image.from_icon_name( "dialog-information-symbolic" ) {
      halign       = Align.START,
      hexpand      = true,
      tooltip_text = _( "When set, automatically numbers child nodes and displays them as a sequence." )
    };

    _sequence = new Switch() {
      halign = Align.END
    };
    _sequence.notify["active"].connect( sequence_changed );

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign = Align.FILL
    };
    box.append( lbl );
    box.append( info );
    box.append( _sequence );

    append( box );
    
  }

  //-------------------------------------------------------------
  // Allows the user to select a different color for the current
  // link and tree.
  private void create_link() {

    var lbl = new Label( _( "Color" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0,
    };
    lbl.add_css_class( "titled" );

    _link_color = new ColorButton() {
      halign = Align.FILL
    };
    _link_color.color_set.connect(() => {
      _map.model.change_current_link_color( _link_color.rgba );
    });

    _link_box = new Box( Orientation.HORIZONTAL, 5 ) {
      homogeneous   = true,
      margin_top    = 5,
      margin_bottom = 5
    };
    _link_box.append( lbl );
    _link_box.append( _link_color );

    append( _link_box );

  }

  //-------------------------------------------------------------
  // Allows the user to select a different color for the current
  // root node.
  private void create_color() {

    var lbl = new Label( _( "Override Color" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0,
    };
    lbl.add_css_class( "titled" );

    _override = new Switch() {
      halign = Align.END
    };
    _override.notify["active"].connect( root_color_changed );

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign        = Align.FILL,
      margin_top    = 5,
      margin_bottom = 5
    };
    box.append( lbl );
    box.append( _override );

    var l = new Label( "" );

    _root_color = new ColorButton() {
      halign = Align.FILL
    };
    _root_color.color_set.connect(() => {
      _map.model.change_current_link_color( _root_color.rgba );
    });

    var cbox = new Box( Orientation.HORIZONTAL, 5 ) {
      homogeneous   = true,
      margin_bottom = 5
    };
    cbox.append( l );
    cbox.append( _root_color );

    _color_reveal = new Revealer() {
      child = cbox
    };

    _root_color_box = new Box( Orientation.VERTICAL, 5 ) {
      margin_bottom = 5
    };
    _root_color_box.append( box );
    _root_color_box.append( _color_reveal );

    append( _root_color_box );

  }

  //-------------------------------------------------------------
  // Creates the note widget.
  private void create_note( MainWindow win ) {

    var lbl = new Label( _( "Note" ) ) {
      xalign = (float)0,
    };
    lbl.add_css_class( "titled" );

    _note = new NoteView() {
      valign    = Align.FILL,
      vexpand   = true,
      wrap_mode = Gtk.WrapMode.WORD
    };
    _note.add_unicode_completion( win, win.unicoder );
    _note.buffer.text = "";
    _note.buffer.changed.connect( note_changed );

    var focus = new EventControllerFocus();
    _note.add_controller( focus );
    focus.enter.connect( note_focus_in );
    focus.leave.connect( note_focus_out );

    _note.node_link_added.connect( note_node_link_added );
    _note.node_link_clicked.connect( note_node_link_clicked );
    _note.node_link_hover.connect( note_node_link_hover );

    _sw = new ScrolledWindow() {
      min_content_width  = 300,
      min_content_height = 100,
      child              = _note
    };

    var box = new Box( Orientation.VERTICAL, 10 ) {
      halign = Align.FILL,
      valign = Align.FILL
    };
    box.append( lbl );
    box.append( _sw );

    append( box );

  }

  //-------------------------------------------------------------
  // Creates the image editing UI.
  private void create_image() {

    _image_stack = new Stack() {
      halign          = Align.FILL,
      transition_type = StackTransitionType.NONE,
      hhomogeneous    = false,
      vhomogeneous    = false
    };
    _image_stack.add_named( create_image_add(),  "add" );
    _image_stack.add_named( create_image_edit(), "edit" );

    append( _image_stack );

  }

  //-------------------------------------------------------------
  // Creates the add image widget.
  private Box create_image_add() {

    var lbl = new Label( _( "Image" ) ) {
      halign = Align.FILL,
      xalign = (float)0,
    };
    lbl.add_css_class( "titled" );

    var btn = new Button.with_label( _( "Add Image…" ) );
    btn.clicked.connect( image_button_clicked );
    editable_changed.connect(() => {
      btn.sensitive = _map.editable;
    });

    var box = new Box( Orientation.VERTICAL, 10 );
    box.append( lbl );
    box.append( btn );

    return( box );

  }

  //-------------------------------------------------------------
  // Creates the edit image widget.
  private Box create_image_edit() {

    var lbl = new Label( _( "Image" ) ) {
      halign  = Align.START,
      hexpand = true,
      xalign  = (float)0,
    };
    lbl.add_css_class( "titled" );

    var btn_edit = new Button.from_icon_name( "document-edit-symbolic" ) {
      halign       = Align.END,
      tooltip_text = _( "Edit Image" )
    };
    btn_edit.clicked.connect(() => {
      _map.model.edit_current_image();
    });

    var btn_del = new Button.from_icon_name( "edit-delete-symbolic" ) {
      halign       = Align.END,
      tooltip_text = _( "Remove Image" )
    };
    btn_del.clicked.connect(() => {
      _map.model.delete_current_image();
    });

    _resize = new ToggleButton() {
      halign       = Align.END,
      icon_name    = "view-fullscreen-symbolic",
      tooltip_text =  _( "Resizable" )
    };
    _resize.toggled.connect(() => {
      var current = _map.get_current_node();
      if( current != null ) {
        current.image_resizable = _resize.get_active();
        _map.auto_save();
      }
    });

    var image_btn_box = new Box( Orientation.HORIZONTAL, 10 ) {
      halign = Align.END
    };
    image_btn_box.append( _resize );
    image_btn_box.append( btn_edit );
    image_btn_box.append( btn_del );

    var tbox = new Box( Orientation.HORIZONTAL, 10 );
    tbox.append( lbl );
    tbox.append( image_btn_box );

    _image = new Picture() {
      margin_bottom = 20
    };

    var box  = new Box( Orientation.VERTICAL, 10 );
    box.append( tbox );
    box.append( _image );

    editable_changed.connect(() => {
      btn_edit.sensitive = _map.editable;
      btn_del.sensitive  = _map.editable;
    });

    /* Set ourselves up to be a drag target */
    var drop = new DropTarget( typeof(File), Gdk.DragAction.COPY );
    _image.add_controller( drop );

    drop.accept.connect((d) => { return( _map.editable ); });
    drop.drop.connect((val, x, y) => {
      var file = (File)val;
      return( _map.model.update_current_image( file.get_uri() ) );
    });

    return( box );

  }

  //-------------------------------------------------------------
  // Called when the user clicks on the image button.
  private void image_button_clicked() {
    _map.model.add_current_image();
  }

  //-------------------------------------------------------------
  // Called if the user clicks on the image URI.
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

  //-------------------------------------------------------------
  // Creates the node editing button grid and adds it to the popover.
  private void create_buttons() {

    var grid = new Grid() {
      column_homogeneous = true,
      column_spacing     = 5
    };

    var copy_btn = new Button.from_icon_name( "edit-copy-symbolic" ) {
      tooltip_text = _( "Copy Node To Clipboard" )
    };
    copy_btn.clicked.connect( node_copy );

    var cut_btn = new Button.from_icon_name( "edit-cut-symbolic" ) {
      tooltip_text = _( "Cut Node To Clipboard" )
    };
    cut_btn.clicked.connect( node_cut );

    /* Create the detach button */
    _detach_btn = new Button.from_icon_name( "minder-detach-light-symbolic" ) {
      tooltip_text = _( "Detach Node" )
    };
    _detach_btn.clicked.connect( node_detach );

    update_icons.connect(() => {
      _detach_btn.icon_name = Utils.use_dark_mode( _detach_btn ) ? "minder-detach-dark-symbolic" : "minder-detach-light-symbolic";
    });

    /* Create the node deletion button */
    var del_btn = new Button.from_icon_name( "edit-delete-symbolic" ) {
      tooltip_text = _( "Delete Node" )
    };
    del_btn.clicked.connect( node_delete );

    /* Add the buttons to the button grid */
    grid.attach( copy_btn,    0, 0 );
    grid.attach( cut_btn,     1, 0 );
    grid.attach( _detach_btn, 2, 0 );
    grid.attach( del_btn,     3, 0 );

    /* Add the button grid to the popover */
    // pack_start( grid, false, true );

  }

  //-------------------------------------------------------------
  // Called whenever the task enable switch is changed within the
  // inspector.
  private void task_changed() {
    if( _ignore ) return;
    var current = _map.get_current_node();
    if( current != null ) {
      _map.model.change_current_task( !current.task_enabled(), false );
    }
  }

  //-------------------------------------------------------------
  // Called whenever the fold switch is changed within the inspector.
  private void fold_changed() {
    if( _ignore ) return;
    var current = _map.get_current_node();
    if( current != null ) {
      _map.model.toggle_folds();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the sequence switch is changed within the
  // inspector.
  private void sequence_changed() {
    if( _ignore ) return;
    var current = _map.get_current_node();
    if( current != null ) {
      current.sequence = !current.sequence;
      _map.auto_save();
      _map.queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the user chooses to override the root color
  // via this sidebar.  We will show/hide the color changer.
  private void root_color_changed() {
    if( _ignore ) return;
    var current = _map.get_current_node();
    if( _color_reveal.reveal_child ) {
      _color_reveal.reveal_child = false;
      if( current != null ) {
        _map.model.change_current_link_color( null );
      }
    } else {
      _color_reveal.reveal_child = true;
      if( (current != null) && (_root_color.rgba != _map.get_theme().get_color( "root_background" )) ) {
        _map.model.change_current_link_color( _root_color.get_rgba() );
      }
    }
  }

  //-------------------------------------------------------------
  // Called whenever the text widget is changed.  Updates the
  // current node and redraws the canvas when needed.
  private void note_changed() {
    if( _ignore ) return;
    _map.model.change_current_node_note( _note.buffer.text );
  }

  //-------------------------------------------------------------
  // Saves the original version of the node's note so that we can
  private void note_focus_in() {
    _node      = _map.get_current_node();
    _orig_note = _note.buffer.text;
  }

  //-------------------------------------------------------------
  // When the note buffer loses focus, save the note change to
  // the undo buffer.
  private void note_focus_out() {
    if( (_node != null) && (_node.note != _orig_note) ) {
      _map.add_undo( new UndoNodeNote( _node, _orig_note ) );
    }
  }

  //-------------------------------------------------------------
  // When a node link is added, tell the current node.
  private int note_node_link_added( NodeLink link, out string text ) {
    return( _map.model.add_note_node_link( link, out text ) );
  }

  //-------------------------------------------------------------
  // Handles a click on the node link with the given ID.
  private void note_node_link_clicked( int id ) {
    _map.model.note_node_link_clicked( id );
  }

  //-------------------------------------------------------------
  // Handles a hover over a node link.
  private void note_node_link_hover( int id ) {
    var link = _map.model.node_links.get_node_link( id );
    if( link != null ) {
      _note.show_tooltip( link.get_tooltip( _map ) );
    }
  }

  //-------------------------------------------------------------
  // Copies the current node to the clipboard.
  private void node_copy() {
    MinderClipboard.copy_nodes( _map );
  }

  //-------------------------------------------------------------
  // Cuts the current node to the clipboard.
  private void node_cut() {
    _map.model.cut_node_to_clipboard();
  }

  //-------------------------------------------------------------
  // Detaches the current node and makes it a parent node.
  private void node_detach() {
    _map.model.detach();
    _detach_btn.set_sensitive( false );
  }

  //-------------------------------------------------------------
  // Deletes the current node.
  private void node_delete() {
    _map.model.delete_node();
  }

  //-------------------------------------------------------------
  // Grabs the focus on the note widget.
  public void grab_note() {
    _note.grab_focus();
    node_changed();
  }

  //-------------------------------------------------------------
  // Called whenever the fold switch is changed within the inspector
  private void resize_changed() {
    var current = _map.get_current_node();
    if( current != null ) {
      current.image_resizable = !current.image_resizable;
      _map.auto_save();
    }
  }

  //-------------------------------------------------------------
  // Called whenever the theme is changed.
  private void theme_changed( MindMap map ) {

    int    num_colors = Theme.num_link_colors();
    RGBA[] colors     = new RGBA[num_colors];

    /* Gather the theme colors into an RGBA array */
    for( int i=0; i<num_colors; i++ ) {
      colors[i] = _map.get_theme().link_color( i );
    }

    /* Clear the palette */
    _link_color.add_palette( Orientation.HORIZONTAL, 10, null );

    /* Set the palette with the new theme colors */
    _link_color.add_palette( Orientation.HORIZONTAL, 10, colors );

  }

  //-------------------------------------------------------------
  // Called whenever the user changes the current node in the canvas.
  private void node_changed() {

    Node? current = _map.get_current_node();

    _ignore = true;

    if( current != null ) {
      _task.set_active( current.task_enabled() );
      _task.set_sensitive( _map.editable );
      if( current.is_leaf() ) {
        _fold.set_active( false );
        _fold.set_sensitive( false );
      } else {
        _fold.set_active( current.folded );
        _fold.set_sensitive( _map.editable );
      }
      if( current.is_root() ) {
        _sequence.set_active( false );
        _sequence.set_sensitive( false );
      } else {
        _sequence.set_active( current.sequence );
        _sequence.set_sensitive( _map.editable );
      }
      if( current.is_root() ) {
        _link_box.visible = false;
        _root_color_box.visible = true;
        _override.set_active( current.link_color_set );
        _override.set_sensitive( _map.editable );
        _color_reveal.reveal_child = current.link_color_set;
        _root_color.rgba = current.link_color_set ? current.link_color : _map.get_theme().get_color( "root_background" );
      } else {
        _link_box.visible = true;
        _root_color_box.visible = false;
        _link_color.rgba = current.link_color;
      }
      _detach_btn.set_sensitive( (current.parent != null) && _map.editable );
      var note = current.note;
      _note.buffer.text = note;
      _note.editable    = _map.editable;
      if( current.image != null ) {
        var url = _map.image_manager.get_uri( current.image.id ).replace( "&", "&amp;" );
        var str = "<a href=\"" + url + "\">" + url + "</a>";
        current.image.set_image( _image );
        _resize.set_active( current.image_resizable && _map.editable );
        _image_stack.visible_child_name = "edit";
      } else {
        _image_stack.visible_child_name = "add";
      }
    }

    _ignore = false;

  }

  //-------------------------------------------------------------
  // Sets the input focus on the first widget in this inspector
  public void grab_first() {
    _task.grab_focus();
    node_changed();
  }

}
