/*
* Copyright (c) 2021 (https://github.com/phase1geo/Minder)
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
* Authored by: Martin Sivak <mars@montik.net>
*/

using GLib;

public class AnimatorScaleInPlace : AnimatorAction {

  private double? _sscale = null;  // Starting scaling factor
  private double? _escale = null;  // Ending scaling factor
  private double? _ssx = null;     // Screen X to keep stable
  private double? _ssy = null;     // Screen X to keep stable
  private double? _dx = null;      // Document X to keep stable
  private double? _dy = null;      // Document Y to keep stable

  /* Constructor for a pan change */
  public AnimatorScaleInPlace( DrawArea da, string name, double ssx, double ssy ) {
    base( name, false );

    double? _sox = null;     // Starting origin X
    double? _soy = null;     // Starting origin Y
    da.get_origin( out _sox, out _soy );

    _sscale = da.sfactor;
    _ssx = ssx;
    _ssy = ssy;
    _dx = _sox + _ssx / _sscale;
    _dy = _soy + _ssy / _sscale;
  }

  /* Returns the NODES types */
  public override AnimationType type() {
    return( AnimationType.PANSCALE );
  }

  /* User method which performs the animation */
  public override void capture( DrawArea da ) {
    _escale = da.sfactor;
  }

  /* Adjusts the origin for the given frame */
  public override void adjust( DrawArea da ) {
    double divisor = index / frames;
    index++;
    double sf = _sscale + ((_escale - _sscale) * divisor);
    da.sfactor = sf;

    double newo_x = _dx - _ssx / sf;
    double newo_y = _dy - _ssy / sf;

    da.set_origin( newo_x, newo_y );
  }

}

