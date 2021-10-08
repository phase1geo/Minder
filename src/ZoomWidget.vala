/*
* Copyright (c) 2021 (https://github.com/phase1geo/Outliner)
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

public class ZoomWidget : Gtk.Box {

  private Button _zoom_out;
  private Button _zoom_actual;
  private Button _zoom_in;
  private int    _min   = 100;
  private int    _max   = 400;
  private int    _value = 100;

  public int min {
    get {
      return( _min );
    }
    set {
      _min = value;
      value = _value;
    }
  }

  public int max {
    get {
      return( _max );
    }
    set {
      _max = value;
      value = _value;
    }
  }

  public int step { get; set; default = 25; }

  public int value {
    get {
      return( _value );
    }
    set {
      var orig_value = _value;
      _value = (value < min) ? min :
               (value > max) ? max :
               value;
      if( orig_value != _value ) {
        update_state();
        zoom_changed( factor );
      }
    }
  }

  public double factor {
    get {
      return( (double)value / 100 );
    }
  }

  public signal void zoom_changed( double factor );

  /* Constructor */
  public ZoomWidget( int min, int max, int step ) {

    this.min  = min;
    this.max  = max;
    this.step = step;

    homogeneous = true;

    get_style_context().add_class( Gtk.STYLE_CLASS_LINKED );

    _zoom_out = new Button.from_icon_name( "zoom-out-symbolic", IconSize.SMALL_TOOLBAR );
    _zoom_out.relief = ReliefStyle.NORMAL;
    _zoom_out.set_tooltip_markup( Utils.tooltip_with_accel( _( "Zoom Out" ), "<Control>minus" ) );
    _zoom_out.clicked.connect( zoom_out );

    _zoom_actual = new Button.with_label( "100%" );
    _zoom_actual.relief = ReliefStyle.NORMAL;
    _zoom_actual.set_tooltip_markup( Utils.tooltip_with_accel( _( "Zoom Actual" ), "<Control>0" ) );
    _zoom_actual.clicked.connect( zoom_actual );

    _zoom_in = new Button.from_icon_name( "zoom-in-symbolic", IconSize.SMALL_TOOLBAR );
    _zoom_in.relief = ReliefStyle.NORMAL;
    _zoom_in.set_tooltip_markup( Utils.tooltip_with_accel( _( "Zoom In" ), "<Control>plus" ) );
    _zoom_in.clicked.connect( zoom_in );

    pack_start( _zoom_out,    false, true );
    pack_start( _zoom_actual, false, true );
    pack_start( _zoom_in,     false, true );

    /* Update the state of the widget */
    update_state();

  }

  /* Update the zoom label */
  private void update_state() {
    _zoom_in.set_sensitive( value < max );
    _zoom_out.set_sensitive( value > min );
    _zoom_actual.label = "%d%%".printf( value );
  }

  /* Perform a zoom in function */
  public void zoom_in() {
    value += step;
  }

  /* Perform a zoom to 100% function */
  public void zoom_actual() {
    value = 100;
  }

  /* Perform a zoom out function */
  public void zoom_out() {
    value -= step;
  }

}
