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

  private Tag _tag;

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
    var name = new EditableLabel( tag.name ) {
      halign   = Align.FILL,
      editable = false,
      hexpand  = true
    };

    name.changed.connect(() => {
      tag.name = name.text;
      changed();
    });

    // Add checkmark field (not editable by user)
    var selected = new CheckButton() {
      halign = Align.END,
      sensitive = false,
      active = true
    };
    selected.set_child_visible( false );

    var click = new GestureClick();
    click.pressed.connect((n_press, x, y) => {
      switch( n_press ) {
        case 1 :
          if( selectable ) {
            var select = !selected.get_child_visible();
            selected.set_child_visible( select );
            select_changed( select );
          }
          break;
        case 2 :
          name.editable = true;
          break;
      }
    });
    name.add_controller( click );

    append( color );
    append( name );
    append( selected );

  }

  //-------------------------------------------------------------
  // Called when the given child changes its selected state.
  public void set_selected( bool select ) {
    var selected = (CheckButton)Utils.get_child_at_index( this, 2 );
    selected.set_child_visible( select );
  }

}

//-------------------------------------------------------------
// Tag editor UI.  This class can be used in the sidebar as well
// as within preferences.  It allows new tags to be added, existing
// ones removed, and allows the existing tags to be edited.  It also
// has support for selecting/deselected existing tags that are
// displayed.
public class TagEditor : Box {

  private Tags?   _tags = null;
  private Entry   _entry;
  private ListBox _taglist;

  public signal void changed();
  public signal void select_changed( Tag tag, bool select );

  //-------------------------------------------------------------
  // Constructor.
  public TagEditor( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 0 );

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
      var tag    = new Tag( _entry.text, Utils.color_from_string( "#000000" ) );
      var tagbox = new TagBox( tag );
      tagbox.changed.connect( handle_tag_change );
      _taglist.append( tagbox );
      _tags.add_tag( tag );
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
        var tag    = tags.get_tag( i );
        var tagbox = new TagBox( tag );
        tagbox.select_changed.connect((select) => {
          select_changed( tag, select );
        });
        _taglist.append( tagbox );
      }
    }

  }

  //-------------------------------------------------------------
  // Shows the provided tags in the current list of tags as being
  // used.
  public void show_selected_tags( Tags? tags ) {

    for( int i=0; i<_tags.size(); i++ ) {
      var tagbox = get_tagbox( _taglist.get_row_at_index( i ) );
      if( tagbox != null ) {
        tagbox.selectable = (tags != null);
        if( tags != null ) {
          tagbox.set_selected( tags.contains_tag( _tags.get_tag( i ) ) );
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
