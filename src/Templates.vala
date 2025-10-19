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

public enum TemplateType {
  STYLE_GENERAL,
  STYLE_NODE,
  STYLE_CONNECTION,
  STYLE_CALLOUT,
  STYLE_OPTION_BRANCH,
  STYLE_OPTION_LINK,
  STYLE_OPTION_NODE,
  STYLE_OPTION_CONNECTION,
  STYLE_OPTION_CALLOUT,
  NUM;

  //-------------------------------------------------------------
  // Outputs a string name
  public string to_string() {
    switch( this ) {
      case STYLE_GENERAL           :  return( "style-general" );
      case STYLE_NODE              :  return( "style-node" );
      case STYLE_CONNECTION        :  return( "style-connection" );
      case STYLE_CALLOUT           :  return( "style-callout" );
      case STYLE_OPTION_BRANCH     :  return( "style-option-branch" );
      case STYLE_OPTION_LINK       :  return( "style-option-link" );
      case STYLE_OPTION_NODE       :  return( "style-option-node" );
      case STYLE_OPTION_CONNECTION :  return( "style-option-connection" );
      case STYLE_OPTION_CALLOUT    :  return( "style-option-callout" );
      default                      :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Returns a string label to display in the UI for this template
  // group.
  public string label() {
    switch( this ) {
      case STYLE_GENERAL           :  return( _( "All Options" ) );
      case STYLE_NODE              :  return( _( "Node Options" ) );
      case STYLE_CONNECTION        :  return( _( "Connection Options" ) );
      case STYLE_CALLOUT           :  return( _( "Callout Options" ) );
      case STYLE_OPTION_BRANCH     :  return( _( "Node Branch Options" ) );
      case STYLE_OPTION_LINK       :  return( _( "Node Link Options" ) );
      case STYLE_OPTION_CONNECTION :  return( _( "Connection Options" ) );
      case STYLE_OPTION_CALLOUT    :  return( _( "Callout Options" ) );
      default                      :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Parses the given string and returns the associated TemplateType
  public static TemplateType parse( string val ) {
    switch( val ) {
      case "style-general"           :  return( STYLE_GENERAL );
      case "style-node"              :  return( STYLE_NODE );
      case "style-connection"        :  return( STYLE_CONNECTION );
      case "style-callout"           :  return( STYLE_CALLOUT );
      case "style-option-branch"     :  return( STYLE_OPTION_BRANCH );
      case "style-option-link"       :  return( STYLE_OPTION_LINK );
      case "style-option-node"       :  return( STYLE_OPTION_NODE );
      case "style-option-connection" :  return( STYLE_OPTION_CONNECTION );
      case "style-option-callout"    :  return( STYLE_OPTION_CALLOUT );
      default                        :  return( NUM );
    }
  }

  //-------------------------------------------------------------
  // Creates an empty template for this template type.
  public Template create_template( string name ) {
    switch( this ) {
      case STYLE_GENERAL           :
      case STYLE_NODE              :
      case STYLE_CONNECTION        :
      case STYLE_CALLOUT           :
      case STYLE_OPTION_BRANCH     :
      case STYLE_OPTION_LINK       :
      case STYLE_OPTION_NODE       :
      case STYLE_OPTION_CONNECTION :
      case STYLE_OPTION_CALLOUT    :
        return( new StyleTemplate( this, name ) );
      default :  assert_not_reached();
    }
  }

}

public delegate void TemplateAddFunc( Template template );

public class Templates {

  public Array<TemplateGroup> _template_groups;

  //-------------------------------------------------------------
  // Default constructor
  public Templates() {
    _template_groups = new Array<TemplateGroup>();
    for( int i=0; i<TemplateType.NUM; i++ ) {
      var ttype = (TemplateType)i;
      var group = new TemplateGroup( ttype );
      _template_groups.append_val( group );
    }
  }

  //-------------------------------------------------------------
  // Returns the template with the given name, if it exists.
  public Template? get_template( TemplateType ttype, string name ) {
    return( _template_groups.index( (int)ttype ).get_template( name ) );
  }

  //-------------------------------------------------------------
  // Adds the given template to the associated template group.
  public void add_template( Template template ) {
    _template_groups.index( (int)template.ttype ).add_template( template );
    save();
  }

  //-------------------------------------------------------------
  // Deletes the template with the given name from the specified template group.
  public void delete_template( TemplateType ttype, string name ) {
    _template_groups.index( (int)ttype ).delete_template( name );
    save();
  }

  //-------------------------------------------------------------
  // Creates a save as template dialog and displays it to the user
  // If the user successfully adds a name, adds it to the list of
  // templates and saves it to the application template file.
  public void save_as_template( MainWindow win, TemplateType template_type, TemplateAddFunc func ) {

    var dialog = new Granite.Dialog() {
      modal         = true,
      transient_for = win
    };

    dialog.add_button( _( "Cancel" ), ResponseType.CANCEL );
    dialog.add_button( _( "Save Template" ), ResponseType.ACCEPT );
    dialog.set_default_response( ResponseType.ACCEPT );

    var save = dialog.get_widget_for_response( ResponseType.ACCEPT );
    save.add_css_class( Granite.STYLE_CLASS_SUGGESTED_ACTION );

    var label = new Label( _( "Template Name:" ) ) {
      halign = Align.START,
    };

    var entry = new Entry() {
      halign           = Align.FILL,
      width_chars      = 40,
      placeholder_text = _( "Enter template name" )
    };

    entry.activate.connect(() => {
      dialog.activate_default();
    });

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( label );
    box.append( entry );

    dialog.get_content_area().append( box );

    dialog.response.connect((id) => {
      if( id == ResponseType.ACCEPT ) {
        var template = template_type.create_template( entry.text );
        func( template );
        add_template( template );
      }
      dialog.destroy();
    });

    dialog.present();
    entry.grab_focus();

  }

  //-------------------------------------------------------------
  // Saves all stored templates into a single template XML file.
  public void save() {

    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder" );

    if( DirUtils.create_with_parents( dir, 0775 ) != 0 ) {
      return;
    }

    var       fname = GLib.Path.build_filename( dir, "templates.xml" );
    Xml.Doc*  doc   = new Xml.Doc( "1.0" );
    Xml.Node* root  = new Xml.Node( null, "templates" );

    root->new_prop( "version", "2" );

    doc->set_root_element( root );

    for( int i=0; i<_template_groups.length; i++ ) {
      root->add_child( _template_groups.index( i ).save() );
    }

    // Save the file
    doc->save_format_file( fname, 1 );

    delete doc;

  }

  //-------------------------------------------------------------
  // Loads all stored templates from a single template XML file.
  public void load() {

    var fname = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "templates.xml" );
    if( !FileUtils.test( fname, FileTest.EXISTS ) ) {
      return;
    }

    Xml.Doc* doc  = Xml.Parser.parse_file( fname );

    if( doc == null ) {
      return;
    }

    var root    = doc->get_root_element();
    var version = root->get_prop( "version" );

    for( Xml.Node* it = root->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "template-group") ) {
        var gt = it->get_prop( "name" );
        if( gt != null ) {
          var group_index = (int)TemplateType.parse( gt );
          _template_groups.index( group_index ).load( it );
        }
      }
    }

    delete doc;

  }

}
