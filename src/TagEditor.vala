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

public class TagBox : Box {

  private Tag   _tag;
  private Label _name_lbl;
  private uint  _timeout_id = 0;
  private bool  _visible    = false;

  public Label name {
    get {
      return( _name_lbl );
    }
  }

  public bool enable_select  { get; set; default = false; }
  public bool enable_visible { get; set; default = false; }

  public signal void changed( Tag tag, Tag orig_tag );
  public signal void select_changed( Tag tag, bool select );
  public signal void visible_changed( Tag tag, bool visible );

  //-------------------------------------------------------------
  // Constructor
  public TagBox( Tag tag ) {

    Object( orientation: Orientation.HORIZONTAL, spacing: 5 );

    _tag = tag;

    // Add Color button
    var dialog = new ColorDialog() {
      modal = true
    };
    var color = new ColorDialogButton( dialog ) {
      halign       = Align.START,
      rgba         = tag.color,
      tooltip_text = _( "Click to change tag color" )
    };
    color.dialog.with_alpha = false;

    color.notify["rgba"].connect(() => {
      var orig_tag = tag.copy();
      tag.color = color.get_rgba();
      changed( tag, orig_tag );
    });

    // Add name label
    _name_lbl = new Label( tag.name ) {
      halign       = Align.START,
      hexpand      = true,
      ellipsize    = Pango.EllipsizeMode.END,
      tooltip_text = enable_select ? _( "Click to add/remove tag to selected node(s).  Click + Delete to remove node from tag list.  Double-click to rename tag." ) :
                                     _( "Click + Delete to remove node from tag list.  Double-click to rename tag." )
    };
    var name_click = new GestureClick();
    _name_lbl.add_controller( name_click );

    var name_entry = new Entry() {
      halign           = Align.FILL,
      hexpand          = true,
      placeholder_text = _( "Enter tag name" )
    };

    var name_stack = new Stack() {
      halign  = Align.FILL,
      hexpand = true
    };
    name_stack.add_named( _name_lbl,  "label" );
    name_stack.add_named( name_entry, "entry" );
    name_stack.visible_child_name = "label";

    name_entry.activate.connect(() => {
      _name_lbl.label = name_entry.text;
      name_stack.visible_child_name = "label";
      var orig_tag = tag.copy();
      tag.name = name_entry.text;
      changed( tag, orig_tag );
    });

    var entry_focus = new EventControllerFocus();
    name_entry.add_controller( entry_focus );

    var entry_key = new EventControllerKey();
    name_entry.add_controller( entry_key );

    entry_focus.leave.connect(() => {
      name_stack.visible_child_name = "label";
    });

    entry_key.key_pressed.connect((keyval, keymod, state) => {
      if( keyval == Gdk.Key.Escape ) {
        name_stack.visible_child_name = "label";
        return( true );
      }
      return( false );
    });

    // Add checkmark field (not editable by user)
    var selected = new CheckButton() {
      sensitive = false,
      visible = false,
      active = true
    };

    var selected_box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.START
    };
    selected_box.append( selected );

    var dummy = new CheckButton();
    var sel_stack = new Stack() {
      halign = Align.END
    };
    sel_stack.add_named( dummy,        "dummy" );
    sel_stack.add_named( selected_box, "selected" );
    sel_stack.visible_child_name = "selected";

    name_click.pressed.connect((n_press, x, y) => {
      if( n_press == 2 ) {
        if( _timeout_id != 0 ) {
            Source.remove( _timeout_id );
          _timeout_id = 0;
        }
        name_entry.text = _name_lbl.label;
        name_entry.grab_focus();
        name_stack.visible_child_name = "entry";
      }
    });

    var visible_btn = new Button.from_icon_name( "minder-eye-symbolic" ) {
      halign       = Align.END,
      visible      = false,
      tooltip_text = _( "Click to add tag to highlight list" )
    };
    visible_btn.add_css_class( "dim-icon" );

    var visible_box = new Box( Orientation.HORIZONTAL, 0 ) {
      halign = Align.START
    };
    visible_box.append( visible_btn );

    var visible_hide = new Button.from_icon_name( "minder-eye-symbolic" ) {
      halign = Align.END
    };

    visible_btn.clicked.connect(() => {
      if( enable_visible ) {
        set_visible( !_visible );
        visible_changed( tag, _visible );
      }
    });

    var visible_stack = new Stack();
    visible_stack.add_named( visible_hide, "hidden" );
    visible_stack.add_named( visible_box,  "eye" );
    visible_stack.visible_child_name = "eye";

    var box = new Box( Orientation.HORIZONTAL, 5 ) {
      halign     = Align.FILL,
      can_target = true,
      focusable  = true
    };
    box.append( name_stack );
    box.append( sel_stack );
    box.append( visible_stack );

    var box_click = new GestureClick();
    box.add_controller( box_click );

    box_click.released.connect((n_press, x, y) => {
      if( enable_select && (n_press == 1) ) {
        _timeout_id = Timeout.add( Gtk.Settings.get_default().gtk_double_click_time, () => {
          _timeout_id = 0;
          var select = !selected.visible;
          selected.visible = select;
          select_changed( tag, select );
          return( false );
        });
      }
    });

    var box_motion = new EventControllerMotion();
    box.add_controller( box_motion );

    box_motion.enter.connect((x, y) => {
      if( enable_visible ) {
        visible_btn.visible = true;
      }
    });
    box_motion.leave.connect(() => {
      if( !_visible ) {
        visible_btn.visible = false;
      }
    });

    append( color );
    append( box );

  }

  //-------------------------------------------------------------
  // Called when the given child changes its selected state.
  public void set_selected( bool select ) {
    var box   = Utils.get_child_at_index( this, 1 );
    var stack = (Stack)Utils.get_child_at_index( box, 1 );
    if( stack != null ) {
      var sel_box  = stack.visible_child;
      var selected = Utils.get_child_at_index( sel_box, 0 );
      selected.visible = select;
    }
  }

  //-------------------------------------------------------------
  // Called when the given child changes its visible state.
  public void set_visible( bool visible ) {
    var box = Utils.get_child_at_index( this, 1 );
    var stack = (Stack)Utils.get_child_at_index( box, 2 );
    if( stack != null ) {
      var vis_box = stack.visible_child;
      var vis_btn = Utils.get_child_at_index( vis_box, 0 );
      _visible = visible;
      vis_btn.visible = visible;
      vis_btn.tooltip_text = _visible ? _( "Click to remove tag from highlight" ) :
                                        _( "Click to add tag to highlight list" );
      if( visible ) {
        vis_btn.remove_css_class( "dim-icon" );
      } else {
        vis_btn.add_css_class( "dim-icon" );
      }
    }
  }

}

//-------------------------------------------------------------
// Tag editor UI.  This class can be used in the sidebar as well
// as within preferences.  It allows new tags to be added, existing
// ones removed, and allows the existing tags to be edited.  It also
// has support for selecting/deselected existing tags that are
// displayed.
public class TagEditor : Box {

  private MainWindow  _win;
  private Tags?       _tags = null;
  private SearchEntry _entry;
  private Box         _content_area;
  private ListBox     _taglist;
  private Button      _new_label;
  private bool        _draggable  = false;
  private bool        _selectable = false;
  private bool        _editable   = true;

  public bool editable {
    get {
      return( _editable );
    }
    set {
      if( _editable != value ) {
        _editable = value;
        _entry.sensitive = _editable;
        _taglist.sensitive = _editable;
      }
    }
  }
  public Box content_area {
    get {
      return( _content_area );
    }
  }

  public signal void tag_changed( Tag tag, Tag orig_tag );
  public signal void tag_added( Tag tag );
  public signal void tag_removed( Tag tag, int index );
  public signal void select_changed( Tag tag, bool select );
  public signal void visible_changed( Tag tag, bool visible );

  //-------------------------------------------------------------
  // Constructor.
  public TagEditor( MainWindow win, bool draggable ) {

    Object( orientation: Orientation.VERTICAL, spacing: 0 );

    _win       = win;
    _draggable = draggable;

    _entry = new SearchEntry() {
      halign           = Align.FILL,
      placeholder_text = _( "Enter name of tag to find or create" ),
      width_chars      = 30,
      margin_top       = 5,
      margin_bottom    = 5,
      margin_start     = 5,
      margin_end       = 5
    };

    _entry.search_changed.connect( search_tags );

    _entry.activate.connect(() => {
      add_new_tag( _entry.text );
      _entry.text = "";
    });

    _content_area = new Box( Orientation.VERTICAL, 5 ) {
      margin_start = 5,
      margin_end   = 5
    };

    _taglist = new ListBox() {
      halign          = Align.FILL,
      selection_mode  = SelectionMode.SINGLE,
      show_separators = true
    };

    var key = new EventControllerKey();
    key.key_pressed.connect((keyval, keycode, state) => {
      var current = _taglist.get_selected_row();
      if( current != null ) {
        if( keyval == Gdk.Key.Delete ) {
          remove_tag( current );
          return( true );
        }
      }
      return( false );
    });

    _taglist.add_controller( key );

    var sw = new ScrolledWindow() {
      vscrollbar_policy = PolicyType.AUTOMATIC,
      hscrollbar_policy = PolicyType.NEVER,
      halign            = Align.FILL,
      valign            = Align.FILL,
      margin_start      = 5,
      margin_end        = 5,
      margin_top        = 5,
      vexpand           = true,
      child             = _taglist
    };

    _new_label = new Button.with_label( "" ) {
      has_frame = false
    };

    _new_label.clicked.connect(() => {
      add_new_tag( _entry.text );
      _entry.text = "";
    });

    append( _entry );
    append( _content_area );
    append( sw );

  }

  //-------------------------------------------------------------
  // Called whenever an individual tag changes color or name.
  private void handle_tag_change( Tag tag, Tag orig_tag ) {
    tag_changed( tag, orig_tag );
  }

  //-------------------------------------------------------------
  // Called whenever an individual tag changes its inclusion or not.
  private void handle_select_change( Tag tag, bool selected ) {
    select_changed( tag, selected );
  }

  //-------------------------------------------------------------
  // Called whenever an individual tag changes its visibility state.
  private void handle_visible_change( Tag tag, bool visible ) {
    visible_changed( tag, visible );
  }

  //-------------------------------------------------------------
  // Returns the TagBox at the given row in the listbox.
  private TagBox? get_tagbox( ListBoxRow? row ) {
    if( row != null ) {
      var child = row.get_child();
      if( child != null ) {
        return( (TagBox)child );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Searches tags for those containing the search string and
  // only displays matching tags.
  private void search_tags() {
    var text = _entry.text;
    for( int i=0; i<_tags.size(); i++ ) {
      var tag    = _tags.get_tag( i );
      var tagbox = _taglist.get_row_at_index( i );
      tagbox.visible = (text == "") || tag.name.contains( text );
    }
    _new_label.visible = (text != "");
    _new_label.label   = _( "Create '%s' tag" ).printf( text );
  }

  //-------------------------------------------------------------
  // Creates a new tag, setting the color to a unique value.
  private void add_new_tag( string name ) {

    var rand = new Rand();
    var red   = rand.int_range( 0, 255 );
    var green = rand.int_range( 0, 255 );
    var blue  = rand.int_range( 0, 255 );
    var color = Utils.color_from_string( "#%02x%02x%02x".printf( red, green, blue ) );

    var tag = new Tag( name, color );
    _tags.add_tag( tag );

    add_tag( tag, (_tags.size() - 1) );

    tag_added( tag );

  } 

  //-------------------------------------------------------------
  // Creates a tag for the given tag name and adds it to the 
  // stores tag list and to the listbox.
  private void add_tag( Tag tag, int pos ) {

    var tagbox = new TagBox( tag );
    tagbox.enable_select  = _selectable;
    tagbox.enable_visible = _draggable;

    tagbox.changed.connect( handle_tag_change );

    if( _draggable ) {

      tagbox.select_changed.connect( handle_select_change );
      tagbox.visible_changed.connect( handle_visible_change );

      var drag = new DragSource() {
        actions = DragAction.COPY
      };

      tagbox.add_controller( drag );

      drag.set_icon( create_icon( tagbox.name ), 10, 10 );

      drag.prepare.connect((x, y) => {
        var val = new Value( typeof(Tag) );
        val.set_object( tag );
        var provider = new ContentProvider.for_value( val );
        return( provider );
      });

    }

    // Add the tagbox to the listbox
    _taglist.insert( tagbox, pos );

  }

  //-------------------------------------------------------------
  // Creates the icon that will be displayed when dragging and dropping
  // the given text from the brainstorm list.
  private Paintable create_icon( Label label ) {
    
    Pango.Rectangle log, ink;

    var layout = label.create_pango_layout( label.label );
    layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    layout.set_width( 200 * Pango.SCALE );
    layout.get_extents( out ink, out log );

    var padding = 10;
    var alpha   = 0.5;
    var width   = (log.width  / Pango.SCALE) + (padding * 2);
    var height  = (log.height / Pango.SCALE) + (padding * 2);

    var rect = Graphene.Rect.alloc();
    rect.init( (float)0.0, (float)0.0, (float)width, (float)height );

    var snapshot = new Gtk.Snapshot();
    var context  = snapshot.append_cairo( rect );

    Utils.set_context_color_with_alpha( context, Utils.color_from_string( "#ffffff" ), alpha );
    context.rectangle( 0, 0, width, height );
    context.fill();

    Utils.set_context_color_with_alpha( context, Utils.color_from_string( "#000000" ), alpha );
    context.move_to( (padding - (log.x / Pango.SCALE)), padding );
    Pango.cairo_show_layout( context, layout );
    context.new_path();

    return( snapshot.free_to_paintable( null ) );

  }

  //-------------------------------------------------------------
  // Removes the tag at the given listbox row.
  private void remove_tag( ListBoxRow? row ) {

    var index = row.get_index();

    // Remove the tagbox from the listbox
    var tagbox = get_tagbox( row );
    if( tagbox != null ) {
      tagbox.changed.disconnect( handle_tag_change );
      if( _draggable ) {
        tagbox.select_changed.disconnect( handle_select_change );
        tagbox.visible_changed.disconnect( handle_visible_change );
      }
    }
    _taglist.remove( row );

    // Remove the tag from the list of stored tags
    var tag = _tags.get_tag( index );
    if( tag != null ) {
      _tags.remove_tag( index );
      tag_removed( tag, index );
    }

  }

  //-------------------------------------------------------------
  // Sets the displayed tags list to the given list of tags.
  public void set_tags( Tags? tags ) {

    _tags = tags;
    _taglist.remove_all();
    _taglist.append( _new_label );

    _new_label.visible = false;

    if( tags != null ) {
      for( int i=0; i<tags.size(); i++ ) {
        var tag = tags.get_tag( i );
        add_tag( tag, i );
      }
    }

  }

  //-------------------------------------------------------------
  // Shows the provided tags in the current list of tags as being
  // used.
  public void show_selected_tags( Tags? tags ) {

    _selectable = (tags != null);

    for( int i=0; i<_tags.size(); i++ ) {
      var tag    = _tags.get_tag( i );
      var tagbox = get_tagbox( _taglist.get_row_at_index( i ) );
      if( tagbox != null ) {
        tagbox.enable_select = _selectable;
        tagbox.set_selected( (tags != null) && tags.contains_tag( tag ) );
      }
    }

  }

  //-------------------------------------------------------------
  // Clears the visibility indicators on all tags.
  public void clear_visible() {

    for( int i=0; i<_tags.size(); i++ ) {
      var tagbox = get_tagbox( _taglist.get_row_at_index( i ) );
      if( tagbox != null ) {
        tagbox.set_visible( false );
      }
    }

  }

  //-------------------------------------------------------------
  // When the focus is grabbed, we will give the entry field the focus.
  public override bool grab_focus() {
    return( _entry.grab_focus() );
  }

}
