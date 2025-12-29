/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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

using GLib;

public class AnimatorPanScale : AnimatorAction {

  private double? _sox    = null;  // Starting x-origin
  private double? _soy    = null;  // Starting y-origin
  private double? _eox    = null;  // Ending x-origin
  private double? _eoy    = null;  // Ending y-origin
  private double? _sscale = null;  // Starting scaling factor
  private double? _escale = null;  // Ending scaling factor

  /* Constructor for a pan change */
  public AnimatorPanScale( DrawArea da, string name ) {
    base( name, false );
    da.get_origin( out _sox, out _soy );
    _sscale = da.sfactor;
    _sox    = _sox * _sscale;
    _soy    = _soy * _sscale;
  }

  /* Returns the NODES types */
  public override AnimationType type() {
    return( AnimationType.PANSCALE );
  }

  /* User method which performs the animation */
  public override void capture( DrawArea da ) {
    da.get_origin( out _eox, out _eoy );
    _escale = da.sfactor;
    _eox    = _eox * _escale;
    _eoy    = _eoy * _escale;
  }

  /* Adjusts the origin for the given frame */
  public override void adjust( DrawArea da ) {
    double divisor = index / frames;
    index++;
    double sf       = _sscale + ((_escale - _sscale) * divisor);
    double origin_x = (_sox + ((_eox - _sox) * divisor)) / sf;
    double origin_y = (_soy + ((_eoy - _soy) * divisor)) / sf;
    da.sfactor = sf;
    da.set_origin( origin_x, origin_y );
  }

  //-------------------------------------------------------------
  // Only allow this action to be cancelled if the start and
  // end origin values haven't changed.
  public override bool can_cancel() {
    return( (_sox == _eox) && (_soy == _eoy) );
  }

}

