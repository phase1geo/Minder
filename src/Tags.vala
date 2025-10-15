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

public enum TagComboType {
  AND,
  OR,
  NUM;

  //-------------------------------------------------------------
  // Displays this enumeration as a printable string.
  public string to_string() {
    switch( this ) {
      case AND :  return( "and" );
      case OR  :  return( "or" );
      default  :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Returns the label associated with this TagComboType.
  public string label() {
    switch( this ) {
      case AND :  return( _( "All" ) );
      case OR  :  return( _( "Any" ) );
      default  :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Parses a given string and returns the associated TagComboType.
  public static TagComboType parse( string val ) {
    switch( val ) {
      case "and" :  return( AND );
      case "or"  :  return( OR );
      default    :  return( AND );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the given tags contain all (AND) or any (OR)
  // of the tags in the specified highlight tags.
  public bool highlightable( Tags tags, Tags highlight ) {
    var intersect = Tags.intersect( tags, highlight );
    switch( this ) {
      case AND :  return( intersect.size() == highlight.size() );
      case OR  :  return( intersect.size() > 0 );
      default  :  assert_not_reached();
    }
  }

}

//-------------------------------------------------------------
// Information for a single tag.
public class Tag : Object {

  public string name  { get; set; default = _( "Tag" ); }
  public RGBA   color { get; set; default = Utils.color_from_string( "#000000" ); }

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
  // Returns a copy of this tag.
  public Tag copy() {
    var tag = new Tag( name, color );
    return( tag );
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

  private Array<Tag> _tags;

  public signal void changed();

  //-------------------------------------------------------------
  // Default constructor
  public Tags() {
    _tags = new Array<Tag>();
  }

  //-------------------------------------------------------------
  // Returns the number of tags stored in this list.
  public int size() {
    return( (int)_tags.length );
  }

  //-------------------------------------------------------------
  // Returns the tag at the given index.
  public Tag? get_tag( int index ) {
    return( _tags.index( index ) );
  }

  //-------------------------------------------------------------
  // Returns the index of the given tag.  Returns -1 if the tag
  // cannot be found.
  public int get_tag_index( Tag tag ) {
    for( int i=0; i<_tags.length; i++ ) {
      if( _tags.index( i ) == tag ) {
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
  public bool add_tag( Tag tag, int index = -1 ) {

    // If the tag already exists in this list, don't add it again
    if( contains_tag( tag ) ) return( false );

    if( index == -1 ) {
      _tags.append_val( tag );
    } else {
      _tags.insert_val( index, tag );
    }

    changed();

    return( true );

  }

  //-------------------------------------------------------------
  // Creates a copy of this tag.
  public Tags copy() {
    var tags = new Tags();
    for( int i=0; i<_tags.length; i++ ) {
      tags.add_tag( _tags.index( i ) );
    }
    return( tags );
  }

  //-------------------------------------------------------------
  // Removes the given tag from the list.
  public bool remove_tag( int index ) {
    if( (index < 0) || (index > _tags.length) ) return( false );
    _tags.remove_index( index );
    changed();
    return( true );
  }

  //-------------------------------------------------------------
  // Clears all of the tags.
  public void clear_tags() {
    _tags.remove_range( 0, _tags.length );
    changed();
  }

  //-------------------------------------------------------------
  // Saves the tags in Xml format.
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "tags" );
    for( int i=0; i<_tags.length; i++ ) {
      node->add_child( _tags.index( i ).save() );
    }
    return( node );
  }

  //-------------------------------------------------------------
  // Returns an XML node containing the list of tag indices based
  // on a full list of tags.
  public Xml.Node* save_indices( Tags all_tags ) {
    string[] indices = {};
    for( int i=0; i<_tags.length; i++ ) {
      var all_index = all_tags.get_tag_index( _tags.index( i ) );
      indices += all_index.to_string();
    }
    Xml.Node* node = new Xml.Node( null, "taglist" );
    node->set_prop( "list", string.joinv( ",", indices ) );
    return( node );
  }

  //-------------------------------------------------------------
  // Saves the list of stored tags as a variant used to store
  // to the settings file.
  public Variant save_variant() {

    var builder = new VariantBuilder( new VariantType( "a(ss)" ) );

    for( int i=0; i<_tags.length; i++ ) {
      var tag = get_tag( i );
      builder.add( "(ss)", tag.name, Utils.color_from_rgba( tag.color ) );
    }

    return( builder.end() );

  }

  //-------------------------------------------------------------
  // Loads the list of stored tags from Xml formatted data.
  public void load( Xml.Node* node ) {
    for( Xml.Node* it=node->children; it!= null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "tag") ) {
        var tag = new Tag.from_xml( it );
        _tags.append_val( tag );
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

  //-------------------------------------------------------------
  // Used to load a variant that is from a settings file.  The
  // variant MUST be an array of structures such that each structure
  // contains to strings where the first is a name and the second is
  // a color.
  public void load_variant( Variant variant ) {
    foreach( Variant child in variant ) {
      string name, color;
      child.get( "(ss)", out name, out color );
      var tag = new Tag( name, Utils.color_from_string( color ) );
      _tags.append_val( tag );
    }
  }

  //-------------------------------------------------------------
  // Returns the stored tags as a comma-separated string.
  public string to_string() {
    string[] parts = {};
    for( int i=0; i<_tags.length; i++ ) {
      parts += get_tag( i ).name;
    }
    return( string.joinv( ",", parts ) );
  }

  //-------------------------------------------------------------
  // Returns a new tags list which contains the tags that are in
  // both the first and second tags list.
  public static Tags intersect( Tags first, Tags second ) {
    var tags = new Tags();
    for( int i=0; i<first.size(); i++ ) {
      var first_tag = first.get_tag( i );
      for( int j=0; j<second.size(); j++ ) {
        if( first_tag == second.get_tag( j ) ) {
          tags.add_tag( first_tag );
          break;
        }
      }
    }
    return( tags );
  }

}
