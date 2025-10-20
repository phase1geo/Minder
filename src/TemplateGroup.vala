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

public delegate void TemplateAddLoadFunc( Template template );

public class TemplateGroup {

  private TemplateType    _type;
  private Array<Template> _templates;
  private GLib.Menu?      _menu = null;

  public GLib.Menu menu {
    get {
      assert( _menu != null );
      return( _menu );
    }
  }

  private signal void local_changed();
  public signal void changed();

  //-------------------------------------------------------------
  // Default constructor
  public TemplateGroup( TemplateType ttype ) {
    _type      = ttype;
    _templates = new Array<Template>();
  }

  //-------------------------------------------------------------
  // Create menu command for the user to add a template with a given name.
  private void add_save_as_menu_command( SimpleActionGroup group, MainWindow win, TemplateAddLoadFunc func ) {

    var action = new SimpleAction( "action_save_as_template", null );

    action.activate.connect((v) => {
      save_as_template( win, func );
    });

    group.add_action( action );

  }

  //-------------------------------------------------------------
  // Creates menu command for the user to load a previously saved
  // template.
  private void add_load_menu_command( SimpleActionGroup group, TemplateAddLoadFunc func ) {

    var action = new SimpleAction( "action_load_saved_template", VariantType.STRING );

    action.activate.connect((v) => {
      var name = v.get_string();
      var template = get_template( name );
      if( template != null ) {
        func( template );
      }
    });

    group.add_action( action );

  }

  //-------------------------------------------------------------
  // Creates menu command for the user to delete a previously
  // saved template.
  private void add_delete_menu_command( SimpleActionGroup group ) {

    var action = new SimpleAction( "action_delete_saved_template", VariantType.STRING );

    action.activate.connect((v) => {
      var name = v.get_string();
      delete_template( name );
    });

    group.add_action( action );

  }

  //-------------------------------------------------------------
  // Creates a save as template dialog and displays it to the user
  // If the user successfully adds a name, adds it to the list of
  // templates and saves it to the application template file.
  private void save_as_template( MainWindow win, TemplateAddLoadFunc func ) {

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
        var template = _type.create_template( entry.text );
        func( template );
        add_template( template );
      }
      dialog.destroy();
    });

    dialog.present();
    entry.grab_focus();

  }

  //-------------------------------------------------------------
  // Creates the menu system to manage this template group.
  private void create_menus() {

    var saved_menu = new GLib.Menu();
    saved_menu.append( _( "Save Style As Template" ), "%s.action_save_as_template".printf( _type.to_string() ) );

    var load_submenu = new GLib.Menu();
    var load_menu = new GLib.Menu();
    load_menu.append_submenu( _( "Load Saved Style" ), load_submenu );
    // TODO - load_menu.append( _( "Load Default Style" ), "styles.action_load_default_template" );

    var del_submenu = new GLib.Menu();
    var delete_menu = new GLib.Menu();
    delete_menu.append_submenu( _( "Delete Saved Style" ), del_submenu );

    _menu = new GLib.Menu();
    _menu.append_section( _type.label(), saved_menu );
    _menu.append_section( null, load_menu );
    _menu.append_section( null, delete_menu );

    local_changed.connect(() => {
      update_menu( load_submenu, del_submenu );
    });

  }

  //-------------------------------------------------------------
  // This function must be called for a given group to create menus.
  public void add_menus( Widget w, MainWindow win, TemplateAddLoadFunc add_func, TemplateAddLoadFunc load_func ) {

    // Create and add the action group to the mindmap canvas
    var group = new SimpleActionGroup();
    w.insert_action_group( _type.to_string(), group );

    // Add the menu commands
    add_save_as_menu_command( group, win, add_func );
    add_load_menu_command( group, load_func );
    add_delete_menu_command( group );

    // Create the menus
    create_menus();

  }

  //-------------------------------------------------------------
  // Updates the given load and delete menus with the latest list of
  // templates in this group.
  private void update_menu( GLib.Menu ld_menu, GLib.Menu dl_menu ) {
    ld_menu.remove_all();
    dl_menu.remove_all();
    for( int i=0; i<_templates.length; i++ ) {
      var name = _templates.index( i ).name;
      ld_menu.append( name, "%s.action_load_saved_template('%s')".printf( _type.to_string(), name ) );
      dl_menu.append( name, "%s.action_delete_saved_template('%s')".printf( _type.to_string(), name ) );
    }
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
      local_changed();
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
      local_changed();
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
    local_changed();
  }

}
