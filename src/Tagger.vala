/*
* Copyright (c) 2020 (https://github.com/phase1geo/Outliner)
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
using Gee;

public class Tagger {

  private DrawArea             _da;
  private HashMap<string,bool> _pre_tags;
  private HashMap<string,int>  _tags;
  private Gtk.SearchEntry      _entry;

  /* Default constructor */
  public Tagger( DrawArea da ) {
    _da   = da;
    _tags = new HashMap<string,int>();
  }

  /* Loads the tags prior to edits being made */
  public void preedit_load_tags( FormattedText text ) {
    _pre_tags = text.get_extras_for_tag( FormatTag.TAG );
  }

  /* Updates the stored list of tags in use. */
  public void postedit_load_tags( FormattedText text ) {
    var tags = text.get_extras_for_tag( FormatTag.TAG );
    var it   = tags.map_iterator();
    while( it.next() ) {
      if( !_pre_tags.unset( it.get_key() ) ) {
        var count = _tags.has_key( it.get_key() ) ? _tags.@get( it.get_key() ) : 0;
        _tags.@set( it.get_key(), (count + 1) );
      }
    }
    var pit = _pre_tags.map_iterator();
    while( pit.next() ) {
      if( _tags.has_key( pit.get_key() ) ) {
        var count = _tags.@get( pit.get_key() );
        if( count == 1 ) {
          _tags.unset( pit.get_key() );
        } else {
          _tags.@set( pit.get_key(), (count - 1) );
        }
      }
    }
  }

  /* Gets the list of matching keys */
  public GLib.List<string> get_matches( string partial ) {
    var it = _tags.map_iterator();
    var matches = new GLib.List<string>();
    while( it.next() ) {
      var key = (string)it.get_key();
      if( (key.length >= partial.length) && (key.substring( 0, partial.length ) == partial) ) {
        matches.append( key );
      }
    }
    matches.sort( GLib.strcmp );
    return( matches );
  }

  /* Returns the XML version of this class for saving purposes */
  public Xml.Node* save() {
    Xml.Node* tags = new Xml.Node( null, "tags" );
    var it = _tags.map_iterator();
    while( it.next() ) {
      Xml.Node* tag = new Xml.Node( null, "tag" );
      tag->set_prop( "value", (string)it.get_key() );
      tag->set_prop( "count", ((int)it.get_value()).to_string() );
      tags->add_child( tag );
    }
    return( tags );
  }

  /* Loads the tag information from the XML save file */
  public void load( Xml.Node* tags ) {
    for( Xml.Node* it = tags->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tag") ) {
        var n = it->get_prop( "value" );
        var c = it->get_prop( "count" );
        if( (n != null) && (c != null) ) {
          _tags.@set( n, int.parse( c ) );
        }
      }
    }
  }

  /* Creates the UI for selecting/creating tags */
  public void show_add_ui() {

    var    name = _da.get_current_node().name;
    double left, top, bottom;
    int    line;
    name.get_char_pos( name.text.text.char_count(), out left, out top, out bottom, out line );
    var int_left   = (int)left;
    var int_bottom = (int)bottom;
    Gdk.Rectangle rect = {int_left, int_bottom, 1, 1};

    var popover = new Popover( _da );
    popover.pointing_to = rect;
    popover.position    = PositionType.BOTTOM;

    var box = new Box( Orientation.VERTICAL, 0 );

    var lbl = new Label( _( "Add Tag" ) );

    var listbox = new ListBox();
    listbox.selection_mode = SelectionMode.BROWSE;
    listbox.halign         = Align.START;
    listbox.valign         = Align.START;
    listbox.row_activated.connect( (row) => {
      var label = (Label)row.get_child();
      var value = label.get_text();
      _da.add_tag( value );
      Utils.hide_popover( popover );
    });

    var scroll = new ScrolledWindow( null, null );
    scroll.vscrollbar_policy  = PolicyType.AUTOMATIC;
    scroll.hscrollbar_policy  = PolicyType.EXTERNAL;
    scroll.min_content_height = 200;
    scroll.add( listbox );

    _entry = new SearchEntry();
    _entry.max_width_chars  = 30;
    _entry.activate.connect( () => {
      var value = _entry.text;
      _da.add_tag( value );
      Utils.hide_popover( popover );
    });
    _entry.insert_text.connect( filter_tag_text );
    _entry.search_changed.connect( () => {
      populate_listbox( listbox, get_matches( _entry.text ) );
    });

    box.pack_start( lbl,    false, true, 5 );
    box.pack_start( _entry, false, true, 5 );
    box.pack_start( scroll, true,  true, 5 );
    box.show_all();

    popover.add( box );

    Utils.show_popover( popover );

    /* Preload the tags */
    populate_listbox( listbox, get_matches( "" ) );

  }

  private void filter_tag_text( string str, int slen, ref int pos ) {
    var filtered = str.replace( " ", "" ).replace( "\t", "" ).replace( "@", "" );
    if( str != filtered ) {
      var void_entry = (void*)_entry;
      SignalHandler.block_by_func( void_entry, (void*)filter_tag_text, this );
      _entry.insert_text( filtered, filtered.length, ref pos );
      SignalHandler.unblock_by_func( void_entry, (void*)filter_tag_text, this );
      Signal.stop_emission_by_name( _entry, "insert_text" );
    }
  }

  private void populate_listbox( ListBox listbox, GLib.List<string> tags ) {
    listbox.foreach( (w) => {
      listbox.remove( w );
    });
    foreach( string str in tags ) {
      var lbl = new Label( str );
      lbl.xalign       = 0;
      lbl.margin       = 5;
      lbl.margin_start = 10;
      lbl.margin_end   = 10;
      listbox.add( lbl );
    }
    listbox.show_all();
  }

}
