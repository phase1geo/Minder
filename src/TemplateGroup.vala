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

public class TemplateGroup {

  private TemplateType    _type;
  private Array<Template> _templates;

  public signal void changed();

  //-------------------------------------------------------------
  // Default constructor
  public TemplateGroup( TemplateType ttype ) {
    _type      = ttype;
    _templates = new Array<Template>();
  }

  //-------------------------------------------------------------
  // Returns the index of the template which matches the given name.
  // If the name could not be found, returns a value of -1.
  private int get_template_index( string name ) {
    for( int i=0; i<_templates.length; i++ ) {
      if( _templates.index( i ).name == name ) {
        return( i );
      }
    }
    return( -1 ); 
  }

  //-------------------------------------------------------------
  // Retrieves the template with the given name.  If it could not
  // be found, returns null.
  public Template? get_template( string name ) {
    var index = get_template_index( name );
    return( (index == -1) ? null : _templates.index( index ) );
  }

  //-------------------------------------------------------------
  // Removes the template from the array.
  public bool add_template( Template template ) {
    var index = get_template_index( template.name );
    if( index == -1 ) {
      _templates.append_val( template );
      changed();
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Deletes the template specified with the given name.
  public bool delete_template( string name ) {
    var index = get_template_index( name );
    if( index != -1 ) {
      _templates.remove_index( index );
      changed();
      return( true );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Method to save contents of template group
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "template-group" );
    node->set_prop( "name", _type.to_string() );
    for( int i=0; i<_templates.length; i++ ) {
      node->add_child( _templates.index( i ).save() ); 
    }
    return( node );
  }

  //-------------------------------------------------------------
  // Loads contents of template group from XML format.
  public void load( Xml.Node* node ) {
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "template") ) {
        var template = _type.create_template( "" );
        template.load( it );
        _templates.append_val( template );
      }
    }
  }

}
