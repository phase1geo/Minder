/*
* Copyright (c) 2025-2026 (https://github.com/phase1geo/Minder)
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

public class Template {

  private TemplateType _type = TemplateType.NUM;
  private string       _name = "";

  public TemplateType ttype {
    get {
      return( _type );
    }
  }
  public string name {
    get {
      return( _name );
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public Template( TemplateType ttype, string name ) {
    _type = ttype;
    _name = name;
  }

  //-------------------------------------------------------------
  // Saves template in XML format.
  public virtual Xml.Node* save( string? node_name = "template" ) {
    Xml.Node* node = new Xml.Node( null, node_name );
    node->set_prop( "name", _name );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads template from XML format
  public virtual void load( Xml.Node* node ) {
    var n = node->get_prop( "name" );
    if( n != null ) {
      _name = n;
    }
  }

}
