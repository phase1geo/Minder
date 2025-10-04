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

using Gdk;

//-------------------------------------------------------------
// Information for a single tag.
public class Tag {

  public string name  { get; set; default = _( "Tag" ); }
  public RGBA   color { get; set; default = Utils.color_from_string( "#000000" ); }

  public signal void removed();

  //-------------------------------------------------------------
  // Constructor
  public Tag( string name, RGBA color ) {
    this.name  = name;
    this.color = color;
  }

  //-------------------------------------------------------------
  // Constructor from Xml format
  public Tag.from_xml( Xml.Node* node ) {
    load( node );
  }

  //-------------------------------------------------------------
  // Returns XML node containing the contents of this tag.
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "tag" );
    node->set_prop( "name", name );
    node->set_prop( "color", Utils.color_from_rgba( color ) );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the contents of this tag from Xml formatted data.
  public void load( Xml.Node* node ) {
    var n = node->get_prop( "name" );
    if( n != null ) {
      name = n;
    }
    var c = node->get_prop( "color" );
    if( c != null ) {
      color = Utils.color_from_string( c );
    }
  }

}

//-------------------------------------------------------------
// Complete list of tags.
public class Tags {

  private class TagInst {
    public Tag   tag       { get; private set; }
    public ulong handle_id { get; private set; }
    public TagInst( Tag t, ulong id = 0 ) {
      tag       = t;
      handle_id = id;
    }
  } 

  private Array<TagInst> _tags;

  //-------------------------------------------------------------
  // Default constructor
  public Tags() {
    _tags = new Array<TagInst>();
  }

  //-------------------------------------------------------------
  // Returns the number of tags stored in this list.
  public int size() {
    return( (int)_tags.length );
  }

  //-------------------------------------------------------------
  // Returns the tag at the given index.
  public Tag? get_tag( int index ) {
    return( _tags.index( index ).tag );
  }

  //-------------------------------------------------------------
  // Returns the index of the given tag.  Returns -1 if the tag
  // cannot be found.
  public int get_tag_index( Tag tag ) {
    for( int i=0; i<_tags.length; i++ ) {
      if( _tags.index( i ).tag == tag ) {
        return( i );
      }
    }
    return( -1 );
  }

  //-------------------------------------------------------------
  // Returns true if this tag currently exists within this tag
  // list.
  public bool contains_tag( Tag tag ) {
    return( get_tag_index( tag ) != -1 );
  }

  //-------------------------------------------------------------
  // Adds the given tag to this list.
  public void add_tag( Tag tag, bool append = true ) {

    // If the tag already exists in this list, don't add it again
    if( contains_tag( tag ) ) return;

    var id = tag.removed.connect(() => {
      var index = get_tag_index( tag );
      if( index != -1 ) {
        _tags.remove_index( index );
      }
    });

    var tag_inst = new TagInst( tag, id );
    if( append ) {
      _tags.append_val( tag_inst );
    } else {
      _tags.prepend_val( tag_inst );
    }

  }

  //-------------------------------------------------------------
  // Removes the given tag from the list.
  public void remove_tag( int index ) {
    var tag_inst = _tags.index( index );
    if( tag_inst.handle_id != 0 ) {
      SignalHandler.disconnect( tag_inst.tag, tag_inst.handle_id );
    }
    _tags.remove_index( index );
  }

  //-------------------------------------------------------------
  // Merges the given list of tags to the beginning or end of this
  // list of tags (tag order is maintained).
  public void add_tags( Tags tags, bool append ) {
    for( int i=0; i<tags.size(); i++ ) {
      add_tag( tags.get_tag( i ), append );
    }
  }

  //-------------------------------------------------------------
  // Saves the tags in Xml format.
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "tags" );
    for( int i=0; i<_tags.length; i++ ) {
      node->add_child( _tags.index( i ).tag.save() );
    }
    return( node );
  }

  //-------------------------------------------------------------
  // Returns an XML node containing the list of tag indices based
  // on a full list of tags.
  public Xml.Node* save_indices( Tags all_tags ) {
    string[] indices = {};
    for( int i=0; i<_tags.length; i++ ) {
      var all_index = all_tags.get_tag_index( _tags.index( i ).tag );
      indices += all_index.to_string();
    }
    Xml.Node* node = new Xml.Node( null, "taglist" );
    node->set_prop( "list", string.joinv( ",", indices ) );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the list of stored tags from Xml formatted data.
  public void load( Xml.Node* node ) {
    for( Xml.Node* it=node->children; it!= null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tag") ) {
        var tag      = new Tag.from_xml( it );
        var tag_inst = new TagInst( tag );
        _tags.append_val( tag_inst );
      }
    }
  }

  //-------------------------------------------------------------
  // Loads the tags based on the existing list of all available tags.
  public void load_indices( Xml.Node* node, Tags all_tags ) {
    var l = node->get_prop( "list" );
    if( l != null ) {
      var indices = l.split( "," );
      foreach (var index in indices) {
        var tag = all_tags.get_tag( int.parse( index ) );
        if( tag != null ) {
          add_tag( tag );
        }
      }
    }
  }

}
