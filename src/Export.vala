/*
* Copyright (c) 2020 (https://github.com/phase1geo/Minder)
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

public class Export {

  public string   name       { get; private set; }
  public string   label      { get; private set; }
  public string[] patterns   { get; private set; }
  public bool     importable { get; private set; }
  public bool     exportable { get; private set; }

  /* Constructor */
  public Export( string name, string label, string[] patterns, bool exportable, bool importable ) {
    this.name       = name;
    this.label      = label;
    this.patterns   = patterns;
    this.exportable = exportable;
    this.importable = importable;
  }

  /* Performs export to the given filename */
  public virtual bool export( string fname, DrawArea da ) {
    return( false );
  }

  /* Imports given filename into drawing area */
  public virtual bool import( string fname, DrawArea da ) {
    return( false );
  }

  /* Adds settings to the export dialog page */
  public virtual void add_settings( Box box ) {}

  /* Saves the settings */
  public virtual void save_settings( Xml.Node* node ) {}

  /* Loads the settings */
  public virtual void load_settings( Xml.Node* node ) {}

  /* Returns true if the given filename is targetted for this export type */
  public bool filename_matches( string fname, out string basename ) {
    foreach( string pattern in patterns ) {
      var ext = pattern.slice( pattern.index_of_nth_char( 1 ), fname.length );
      if( fname.has_suffix( ext ) ) {
        basename = fname.slice( 0, (fname.length - ext.length) );
        return( true );
      }
    }
    return( false );
  }

  /* Saves the state of this export */
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "export" );
    node->set_prop( "name", name );
    save_settings( node );
    return( node );
  }

  /* Loads the state of this export */
  public void load( Xml.Node* node ) {
    load_settings( node );
  }

}


