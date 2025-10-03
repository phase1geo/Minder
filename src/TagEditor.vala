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
    });

    // Add name label
    var name = new EditableLabel( tag.name ) {
      halign  = Align.FILL,
      hexpand = true
    };

    name.changed.connect(() => {
      tag.name = name.text;
    });

    // Add checkmark field (not editable by user)
    var selected = new CheckButton() {
      halign = Align.END,
      sensitive = false
    };
    selected.set_child_visible( false );

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

  //-------------------------------------------------------------
  // Constructor.
  public TagEditor( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 0 );

    _entry = new Entry() {
      halign           = Align.FILL,
      placeholder_text = _( "Enter Tag Name to Find or Create" ),
      width_chars      = 30,
      margin_top       = 5,
      margin_start     = 5,
      margin_end       = 5
    };

    _entry.activate.connect(() => {
      var tag    = new Tag( _entry.text, Utils.color_from_string( "#000000" ) );
      var tagbox = new TagBox( tag );
      _tags.add_tag( tag );
      _taglist.append( tagbox );
      _entry.text = "";
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
          var index = current.get_index();
          _taglist.remove( current );
          _tags.remove_tag( index );
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
  // Sets the displayed tags list to the given list of tags.
  public void set_tags( Tags? tags ) {

    _tags = tags;
    _taglist.remove_all();

    if( tags != null ) {
      for( int i=0; i<tags.size(); i++ ) {
        var tag = new TagBox( tags.get_tag( i ) );
        _taglist.append( tag );
      }
    }

  }

}
