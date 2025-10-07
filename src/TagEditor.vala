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

  private Tag           _tag;
  private EditableLabel _name;

  public EditableLabel name {
    get {
      return( _name );
    }
  }
  public bool selectable { get; set; default = false; }

  public signal void changed();
  public signal void select_changed( bool select );

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
      halign = Align.START,
      rgba   = tag.color,
    };
    color.dialog.with_alpha = false;

    color.notify["rgba"].connect(() => {
      tag.color = color.get_rgba();
      changed();
    });

    // Add name label
    _name = new EditableLabel( tag.name ) {
      halign   = Align.FILL,
      editable = false,
      hexpand  = true
    };

    _name.changed.connect(() => {
      tag.name = _name.text;
      changed();
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
    var stack = new Stack() {
      halign = Align.END
    };
    stack.add_named( dummy,        "dummy" );
    stack.add_named( selected_box, "selected" );
    stack.visible_child_name = "selected";

    var click = new GestureClick();
    click.released.connect((n_press, x, y) => {
      switch( n_press ) {
        case 1 :
          if( selectable ) {
            var select = !selected.visible;
            selected.visible = select;
            select_changed( select );
          }
          break;
        case 2 :
          name.editable = true;
          break;
      }
    });
    _name.add_controller( click );

    append( color );
    append( _name );
    append( stack );

  }

  //-------------------------------------------------------------
  // Called when the given child changes its selected state.
  public void set_selected( bool select ) {
    var stack = (Stack)Utils.get_child_at_index( this, 2 );
    if( stack != null ) {
      var box      = stack.visible_child;
      var selected = Utils.get_child_at_index( box, 0 );
      selected.visible = select;
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

  private MainWindow _win;
  private Tags?      _tags = null;
  private Entry      _entry;
  private ListBox    _taglist;
  private bool       _draggable = false;

  public signal void changed();
  public signal void select_changed( Tag tag, bool select );

  //-------------------------------------------------------------
  // Constructor.
  public TagEditor( MainWindow win, bool draggable ) {

    Object( orientation: Orientation.VERTICAL, spacing: 0 );

    _win       = win;
    _draggable = draggable;

    _entry = new Entry() {
      halign           = Align.FILL,
      placeholder_text = _( "Enter Tag Name to Find or Create" ),
      width_chars      = 30,
      margin_top       = 5,
      margin_bottom    = 10,
      margin_start     = 5,
      margin_end       = 5
    };

    _entry.activate.connect(() => {
      add_new_tag( _entry.text );
      _entry.text = "";
      changed();
    });

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
      vexpand           = true,
      child             = _taglist
    };

    append( _entry );
    append( sw );

  }

  //-------------------------------------------------------------
  // Called whenever an individual tag changes color or name.
  private void handle_tag_change() {
    changed();
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
  // Creates a new tag, setting the color to a unique value.
  private void add_new_tag( string name ) {

    var tag = new Tag( name, Utils.color_from_string( "#000000" ) );
    _tags.add_tag( tag );

    add_tag( tag );

  } 

  //-------------------------------------------------------------
  // Creates a tag for the given tag name and adds it to the 
  // stores tag list and to the listbox.
  private void add_tag( Tag tag ) {

    var tagbox = new TagBox( tag );

    tagbox.changed.connect( handle_tag_change );

    if( _draggable ) {

      tagbox.select_changed.connect((select) => {
        select_changed( tag, select );
      });

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

      /*
      drag.drag_end.connect((d, del) => {
        ideas_changed( BraindumpChangeType.REMOVE, _current_index.to_string() );
      });
      */

    }

    // Add the tagbox to the listbox
    _taglist.append( tagbox );

  }

  //-------------------------------------------------------------
  // Creates the icon that will be displayed when dragging and dropping
  // the given text from the brainstorm list.
  private Paintable create_icon( EditableLabel label ) {
    
    Pango.Rectangle log, ink;

    var theme = _win.get_current_map().model.get_theme();

    var layout = label.create_pango_layout( label.text );
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

    Utils.set_context_color_with_alpha( context, theme.get_color( "root_background" ), alpha );
    context.rectangle( 0, 0, width, height );
    context.fill();

    Utils.set_context_color_with_alpha( context, theme.get_color( "root_foreground" ), alpha );
    context.move_to( (padding - (log.x / Pango.SCALE)), padding );
    Pango.cairo_show_layout( context, layout );
    context.new_path();

    return( snapshot.free_to_paintable( null ) );

  }

  //-------------------------------------------------------------
  // Removes the tag at the given listbox row.
  private void remove_tag( ListBoxRow? row ) {

    var index  = row.get_index();
    var change = false;

    // Remove the tagbox from the listbox
    var tagbox = get_tagbox( row );
    if( tagbox != null ) {
      tagbox.changed.disconnect( handle_tag_change );
      change = true;
    }
    _taglist.remove( row );

    // Remove the tag from the list of stored tags
    var tag = _tags.get_tag( index );
    if( tag != null ) {
      _tags.remove_tag( index );
      tag.removed();
      change = true;
    }

    if( change ) {
      changed();
    }

  }

  //-------------------------------------------------------------
  // Sets the displayed tags list to the given list of tags.
  public void set_tags( Tags? tags ) {

    _tags = tags;
    _taglist.remove_all();

    if( tags != null ) {
      for( int i=0; i<tags.size(); i++ ) {
        var tag = tags.get_tag( i );
        add_tag( tag );
      }
    }

  }

  //-------------------------------------------------------------
  // Shows the provided tags in the current list of tags as being
  // used.
  public void show_selected_tags( Tags? tags ) {

    for( int i=0; i<_tags.size(); i++ ) {
      var tag    = _tags.get_tag( i );
      var tagbox = get_tagbox( _taglist.get_row_at_index( i ) );
      if( tagbox != null ) {
        tagbox.selectable = (tags != null);
        if( tags != null ) {
          tagbox.set_selected( tags.contains_tag( tag ) );
        }
      }
    }

  }

  //-------------------------------------------------------------
  // When the focus is grabbed, we will give the entry field the focus.
  public override bool grab_focus() {
    return( _entry.grab_focus() );
  }
}
