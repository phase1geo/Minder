/*
* Copyright (c) 2020-2025 (https://github.com/phase1geo/Minder)
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
  public bool     clippable  { get; private set; }

  public signal void settings_changed();

  //-------------------------------------------------------------
  // Constructor
  public Export( string name, string label, string[] extensions, bool exportable, bool importable, bool dir, bool clippable ) {
    _settings = new HashMap<string,Widget>();
    this.name       = name;
    this.label      = label;
    this.extensions = extensions;
    this.exportable = exportable;
    this.importable = importable;
    this.dir        = dir;
    this.clippable  = clippable;
  }

  //-------------------------------------------------------------
  // Performs export to the given filename.  If the filename
  public virtual bool export( string fname, MindMap map ) {
    return( false );
  }

  //-------------------------------------------------------------
  // Imports given filename into drawing area
  public virtual bool import( string fname, MindMap map ) {
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if there are any settings associated with this
  // export.
  public bool settings_available() {
    return( _settings.size > 0 );
  }

  //-------------------------------------------------------------
  // Adds settings to the export dialog page.
  protected virtual void add_settings( Grid grid ) {}

  //-------------------------------------------------------------
  // Adds all of the export settings available.
  public void add_all_settings( Grid grid ) {
    add_settings( grid );
    if( clippable ) {
      add_setting_bool( "clipboard", grid, _( "Export to clipboard" ), null, false );
    }
  }

  //-------------------------------------------------------------
  // Creates a help label to be used in settings and returns it.
  private Label make_help( string help ) {

    var lbl = new Label( help ) {
      margin_start    = 10,
      margin_bottom   = 10,
      xalign          = (float)0,
      justify         = Justification.LEFT,
      max_width_chars = 40,
      wrap_mode       = Pango.WrapMode.WORD,
      wrap            = true
    };

    return( lbl );

  }

  //-------------------------------------------------------------
  // Adds a boolean setting value to the settings and creates a
  // related setting with the given default value.
  protected void add_setting_bool( string name, Grid grid, string label, string? help, bool dflt ) {

    var row = _settings.size * 2;

    var lbl = new Label( label ) {
      halign  = Align.START,
      hexpand = true,
    };
    lbl.add_css_class( "titled" );

    var sw = new Switch() {
      halign = Align.END,
      active = dflt
    };
    sw.notify["active"].connect((e) => {
      settings_changed();
    });

    grid.attach( lbl, 0, row );
    grid.attach( sw,  1, row );

    if( help != null ) {
      var hlp = make_help( help );
      grid.attach( hlp, 0, (row + 1), 2 );
    }

    _settings.@set( name, sw );

  }

  //-------------------------------------------------------------
  // Adds an integer setting value within a given range to the
  // settings panel and creates a related setting with the given
  // default value.
  protected void add_setting_scale( string name, Grid grid, string label, string? help, int min, int max, int step, int dflt ) {

    var row = _settings.size * 2;

    var lbl = new Label( label ) {
      halign  = Align.START,
      hexpand = true,
    };
    lbl.add_css_class( "titled" );

    var scale = new Scale.with_range( Orientation.HORIZONTAL, min, max, step ) {
      halign       = Align.FILL,
      draw_value   = true,
      round_digits = max.to_string().char_count()
    };
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

  //-------------------------------------------------------------
  // Adds a zoom setting to the settings panel and creates an
  // associated setting value.
  protected void add_setting_zoom( string name, Grid grid, string label, string? help, int min, int max, int step, int dflt ) {

    var row = _settings.size * 2;

    var lbl = new Label( label ) {
      halign = Align.START,
    };
    lbl.add_css_class( "titled" );

    var zoom = new ZoomWidget( min, max, step ) {
      value = dflt
    };
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

  //-------------------------------------------------------------
  // Send export results to clipboard instead of to a file.
  public bool send_to_clipboard() {
    return( clippable && get_bool( "clipboard" ) );
  }

  //-------------------------------------------------------------
  // Returns true if the given setting is a boolean.
  public bool is_bool_setting( string name ) {
    return( _settings.has_key( name ) && ((_settings.@get( name ) as Switch) != null) );
  }

  //-------------------------------------------------------------
  // Returns true if the given setting is a scale.
  public bool is_scale_setting( string name ) {
    return( _settings.has_key( name ) && ((_settings.@get( name ) as Scale) != null) );
  }

  //-------------------------------------------------------------
  // Returns true if the given setting is a zoom widget.
  public bool is_zoom_setting( string name ) {
    return( _settings.has_key( name ) && ((_settings.@get( name ) as ZoomWidget) != null) );
  }

  //-------------------------------------------------------------
  // Sets a boolean setting to the given value and updates the
  // associated widget.
  public void set_bool( string name, bool value ) {
    assert( _settings.has_key( name ) );
    var sw = (Switch)_settings.@get( name );
    sw.active = value;
  }

  //-------------------------------------------------------------
  // Returns the boolean value of the given setting value.
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

  //-------------------------------------------------------------
  // Saves the settings
  protected virtual void save_settings( Xml.Node* node ) {}

  //-------------------------------------------------------------
  // Saves all of the settings value.
  private void save_all_settings( Xml.Node* node ) {
    save_settings( node );
    if( clippable ) {
      node->set_prop( "clipboard", get_bool( "clipboard" ).to_string() );
    }
  }

  //-------------------------------------------------------------
  // Loads the settings
  protected virtual void load_settings( Xml.Node* node ) {}

  //-------------------------------------------------------------
  // Loads all of the settings values.
  private void load_all_settings( Xml.Node* node ) {

    load_settings( node );

    if( clippable ) {
      var c = node->get_prop( "clipboard" );
      if( c != null ) {
        set_bool( "clipboard", bool.parse( c ) );
      } else {
        set_bool( "clipboard", false );
      }
    }

  }

  //-------------------------------------------------------------
  // Returns true if the given filename is targetted for this
  // export type
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

  //-------------------------------------------------------------
  // Saves the state of this export.
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "export" );
    node->set_prop( "name", name );
    save_all_settings( node );
    return( node );
  }

  //-------------------------------------------------------------
  // Loads the state of this export.
  public void load( Xml.Node* node ) {
    load_all_settings( node );
  }

}


