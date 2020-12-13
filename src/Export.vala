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
using Gee;

public class Export {

  private HashMap<string,Widget> _settings;

  public string   name       { get; private set; }
  public string   label      { get; private set; }
  public string[] extensions { get; private set; }
  public bool     importable { get; private set; }
  public bool     exportable { get; private set; }

  /* Constructor */
  public Export( string name, string label, string[] extensions, bool exportable, bool importable ) {
    _settings = new HashMap<string,Widget>();
    this.name       = name;
    this.label      = label;
    this.extensions = extensions;
    this.exportable = exportable;
    this.importable = importable;
  }

  public signal void settings_changed();

  /* Performs export to the given filename */
  public virtual bool export( string fname, DrawArea da ) {
    return( false );
  }

  /* Imports given filename into drawing area */
  public virtual bool import( string fname, DrawArea da ) {
    return( false );
  }

  public bool settings_available() {
    return( _settings.size > 0 );
  }

  /* Adds settings to the export dialog page */
  public virtual void add_settings( Grid grid ) {}

  protected void add_setting_bool( string name, Grid grid, string label, bool dflt ) {

    var row = _settings.size;

    var lbl = new Label( label );
    lbl.halign = Align.START;

    var sw  = new Switch();
    sw.halign = Align.END;
    sw.activate.connect(() => {
      settings_changed();
    });

    grid.attach( lbl, 0, row );
    grid.attach( sw,  1, row );

    _settings.@set( name, sw );

  }

  protected void add_setting_scale( string name, Grid grid, string label, int min, int max, int step, int dflt ) {

    var row = _settings.size;

    var lbl = new Label( label );
    lbl.halign = Align.START;

    var scale = new Scale.with_range( Orientation.HORIZONTAL, min, max, step );
    scale.halign = Align.END;
    scale.draw_value   = true;
    scale.round_digits = max.to_string().char_count();
    scale.value_changed.connect(() => {
      settings_changed();
    });
    scale.set_size_request( 150, -1 );

    grid.attach( lbl,   0, row );
    grid.attach( scale, 1, row );

    _settings.@set( name, scale );

  }

  protected void set_bool( string name, bool value ) {
    assert( _settings.has_key( name ) );
    var sw = (Switch)_settings.@get( name );
    sw.active = value;
  }

  protected bool get_bool( string name ) {
    assert( _settings.has_key( name ) );
    var sw = (Switch)_settings.@get( name );
    return( sw.active );
  }

  protected void set_scale( string name, int value ) {
    assert( _settings.has_key( name ) );
    var scale = (Scale)_settings.@get( name );
    scale.set_value( (double)value );
  }

  protected int get_scale( string name ) {
    assert( _settings.has_key( name ) );
    var scale = (Scale)_settings.@get( name );
    return( (int)scale.get_value() );
  }

  /* Saves the settings */
  public virtual void save_settings( Xml.Node* node ) {}

  /* Loads the settings */
  public virtual void load_settings( Xml.Node* node ) {}

  /* Returns true if the given filename is targetted for this export type */
  public bool filename_matches( string fname, out string basename ) {
    foreach( string extension in extensions ) {
      if( fname.has_suffix( extension ) ) {
        basename = fname.slice( 0, (fname.length - extension.length) );
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


