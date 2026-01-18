/*
* Copyright (c) 2026 (https://github.com/phase1geo/Minder)
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

public class StyleTemplate : Template {

  public Style style { get; default = new Style(); }

  //-------------------------------------------------------------
  // Default constructor
  public StyleTemplate( TemplateType ttype, string name ) {
    base( ttype, name );
  }

  //-------------------------------------------------------------
  // Copies the style information to this template.
  public void update_from_style( Style s ) {
    if( (ttype == TemplateType.STYLE_GENERAL) || (ttype == TemplateType.STYLE_NODE) || (ttype == TemplateType.STYLE_OPTION_BRANCH) ) {
      style.copy_node_branch( s );
    }
    if( (ttype == TemplateType.STYLE_GENERAL) || (ttype == TemplateType.STYLE_NODE) || (ttype == TemplateType.STYLE_OPTION_LINK) ) {
      style.copy_node_link( s );
    }
    if( (ttype == TemplateType.STYLE_GENERAL) || (ttype == TemplateType.STYLE_NODE) || (ttype == TemplateType.STYLE_OPTION_NODE) ) {
      style.copy_node_body( s );
    }
    if( (ttype == TemplateType.STYLE_GENERAL) || (ttype == TemplateType.STYLE_CONNECTION) || (ttype == TemplateType.STYLE_OPTION_CONNECTION) ) {
      style.copy_connection( s );
    }
    if( (ttype == TemplateType.STYLE_GENERAL) || (ttype == TemplateType.STYLE_CALLOUT) || (ttype == TemplateType.STYLE_OPTION_CALLOUT) ) {
      style.copy_callout( s );
    }
  }

  //-------------------------------------------------------------
  // Sets the style from the contents stored in this template.
  public void update_to_style( Style to_style ) {
    to_style.copy( style );
  }

  //-------------------------------------------------------------
  // Saves all of the stored style information to an XML node and
  // returns the node.
  public override Xml.Node* save( string? node_name = "template" ) {
    Xml.Node* node = base.save( node_name );
    style.save_node_in_node( node );
    style.save_connection_in_node( node );
    style.save_callout_in_node( node );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the stored style information from the provided XML node
  // to our stored value.
  public override void load( Xml.Node* node ) {
    base.load( node );
    style.load_node( node );
    style.load_connection( node );
    style.load_callout( node );
  }

}
