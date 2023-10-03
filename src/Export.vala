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
  public bool     dir        { get; private set; }

  /* Constructor */
  public Export( string name, string label, string[] extensions, bool exportable, bool importable, bool dir ) {
    _settings = new HashMap<string,Widget>();
    this.name       = name;
    this.label      = label;
    this.extensions = extensions;
    this.exportable = exportable;
    this.importable = importable;
    this.dir        = dir;
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

  private Label make_help( string help ) {

    var lbl = new Label( help );
    lbl.margin_left     = 10;
    lbl.margin_bottom   = 10;
    lbl.xalign          = (float)0;
    lbl.justify         = Justification.LEFT;
    lbl.max_width_chars = 40;
    lbl.wrap_mode       = Pango.WrapMode.WORD;
    lbl.set_line_wrap( true );

    return( lbl );

  }

  protected void add_setting_bool( string name, Grid grid, string label, string? help, bool dflt ) {

    var row = _settings.size * 2;

    var lbl = new Label( Utils.make_title( label ) );
    lbl.halign     = Align.START;
    lbl.use_markup = true;

    var sw  = new Switch();
    sw.halign = Align.END;
    sw.expand = true;
    sw.active = dflt;
    sw.button_press_event.connect((e) => {
      sw.active = !sw.active;
      settings_changed();
      return( true );
    });

    grid.attach( lbl, 0, row );
    grid.attach( sw,  1, row );

    if( help != null ) {
      var hlp = make_help( help );
      grid.attach( hlp, 0, (row + 1), 2 );
    }

    _settings.@set( name, sw );

  }

  protected void add_setting_scale( string name, Grid grid, string label, string? help, int min, int max, int step, int dflt ) {

    var row = _settings.size * 2;

    var lbl = new Label( Utils.make_title( label ) );
    lbl.halign     = Align.START;
    lbl.use_markup = true;

    var scale = new Scale.with_range( Orientation.HORIZONTAL, min, max, step );
    scale.halign       = Align.FILL;
    scale.expand       = true;
    scale.draw_value   = true;
    scale.round_digits = max.to_string().char_count();
    scale.set_value( dflt );
    scale.value_changed.connect(() => {
      settings_changed();
    });

    grid.attach( lbl,   0, row );
    grid.attach( scale, 1, row );

    if( help != null ) {
      var hlp = make_help( help );
      grid.attach( hlp, 0, (row + 1), 2 );
    }

    _settings.@set( name, scale );

  }

  protected void add_setting_zoom( string name, Grid grid, string label, string? help, int min, int max, int step, int dflt ) {

    var row = _settings.size * 2;

    var lbl = new Label( Utils.make_title( label ) );
    lbl.halign     = Align.START;
    lbl.use_markup = true;

    var zoom = new ZoomWidget( min, max, step );
    zoom.value = dflt;
    zoom.zoom_changed.connect(() => {
      settings_changed();
    });

    grid.attach( lbl,  0, row );
    grid.attach( zoom, 1, row );

    if( help != null ) {
      var hlp = make_help( help );
      grid.attach( hlp, 0, (row + 1), 2 );
    }

    _settings.@set( name, zoom );

  }

  /* Returns true if the given setting is a boolean */
  public bool is_bool_setting( string name ) {
    return( _settings.has_key( name ) && ((_settings.@get( name ) as Switch) != null) );
  }

  /* Returns true if the given setting is a scale */
  public bool is_scale_setting( string name ) {
    return( _settings.has_key( name ) && ((_settings.@get( name ) as Scale) != null) );
  }

  /* Returns true if the given setting is a zoom widget */
  public bool is_zoom_setting( string name ) {
    return( _settings.has_key( name ) && ((_settings.@get( name ) as ZoomWidget) != null) );
  }

  public void set_bool( string name, bool value ) {
    assert( _settings.has_key( name ) );
    var sw = (Switch)_settings.@get( name );
    sw.active = value;
  }

  protected bool get_bool( string name ) {
    assert( _settings.has_key( name ) );
    var sw = (Switch)_settings.@get( name );
    return( sw.active );
  }

  public void set_scale( string name, int value ) {
    assert( _settings.has_key( name ) );
    var scale = (Scale)_settings.@get( name );
    var double_value = (double)value;
    scale.set_value( double_value );
  }

  protected int get_scale( string name ) {
    assert( _settings.has_key( name ) );
    var scale = (Scale)_settings.@get( name );
    return( (int)scale.get_value() );
  }

  public void set_zoom( string name, int value ) {
    assert( _settings.has_key( name ) );
    var zoom = (ZoomWidget)_settings.@get( name );
    zoom.value = value;
  }

  protected int get_zoom( string name ) {
    assert( _settings.has_key( name ) );
    var zoom = (ZoomWidget)_settings.@get( name );
    return( zoom.value );
  }

  /* Saves the settings */
  public virtual void save_settings( Xml.Node* node ) {}

  /* Loads the settings */
  public virtual void load_settings( Xml.Node* node ) {}

  /* Returns true if the given filename is targetted for this export type */
  public bool filename_matches( string fname, out string basename ) {
    if( dir ) {
      basename = fname;
      return( true );
    } else {
      foreach( string extension in extensions ) {
        if( fname.has_suffix( extension ) ) {
          basename = fname.slice( 0, (fname.length - extension.length) );
          return( true );
        }
      }
      return( false );
    }
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


