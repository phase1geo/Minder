/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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
using GLib;

public class Themes : Object {

  private Array<Theme> _themes;
  private uint         _custom_start;

  public virtual signal void themes_changed() {
    save_custom();
  }

  public uint custom_start {
    get {
      return( _custom_start );
    }
  }

  /* Default constructor */
  public Themes() {

    /* Allocate memory for the themes array */
    _themes = new Array<Theme>();

    /* Create the themes */
    var default_theme         = new ThemeDefault();
    var dark_theme            = new ThemeDark();
    var solarized_light_theme = new ThemeSolarizedLight();
    var solarized_dark_theme  = new ThemeSolarizedDark();

    /* Add the themes to the list */
    _themes.append_val( default_theme );
    _themes.append_val( dark_theme );
    _themes.append_val( solarized_light_theme );
    _themes.append_val( solarized_dark_theme );

    _custom_start = _themes.length;

    /* Load the customized themes */
    load_custom();

  }

  /* Returns a list of theme names */
  public void names( ref Array<string> names ) {
    for( int i=0; i<_themes.length; i++ ) {
      names.append_val( _themes.index( i ).name );
    }
  }

  /* Returns a list of icons associated with each of the loaded themes */
  public void icons( ref Array<Image> icons ) {
    for( int i=0; i<_themes.length; i++ ) {
      icons.append_val( new Image.from_surface( _themes.index( i ).make_icon() ) );
    }
  }

  /* Returns the theme associated with the given name */
  public Theme get_theme( string name ) {
    for( int i=0; i<_themes.length; i++ ) {
      if( name == _themes.index( i ).name ) {
        return( _themes.index( i ) );
      }
    }
    return( _themes.index( 0 ) );
  }

  /* Adds the given theme */
  public void add_theme( Theme theme ) {
    _themes.append_val( theme );
    themes_changed();
  }

  /* Deletes the given theme */
  public void delete_theme( string name ) {
    for( int i=0; i<_themes.length; i++ ) {
      if( _themes.index( i ).name == name ) {
        _themes.remove_index( i );
        themes_changed();
        return;
      }
    }
  }

  /* Loads the custom themes from XML */
  private void load_custom() {
    var themes = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "custom_themes.xml" );
    Xml.Doc* doc = Xml.Parser.parse_file( themes );
    if( doc == null ) return;
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "theme") ) {
        var theme = new Theme();
        theme.load( it );
        _themes.append_val( theme );
      }
    }
    delete doc;
  }

  /* Saves the custom themes to XML */
  public void save_custom() {

    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder" );

    if( DirUtils.create_with_parents( dir, 0775 ) != 0 ) {
      return;
    }

    var       fname = GLib.Path.build_filename( dir, "custom_themes.xml" );
    Xml.Doc*  doc   = new Xml.Doc( "1.0" );
    Xml.Node* root  = new Xml.Node( null, "themes" );

    doc->set_root_element( root );

    for( uint i=_custom_start; i<_themes.length; i++ ) {
      root->add_child( _themes.index( i ).save() );
    }

    /* Save the file */
    doc->save_format_file( fname, 1 );

    delete doc;

  }

}
