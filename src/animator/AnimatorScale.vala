/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

public class AnimatorScale : AnimatorAction {

  private double? _sscale = null;  // Starting scaling factor
  private double? _escale = null;  // Ending scaling factor

  /* Constructor for a scale change */
  public AnimatorScale( DrawArea da, string name ) {
    base( name, false );
    _sscale = da.sfactor;
  }

  /* Returns the NODES types */
  public override AnimationType type() {
    return( AnimationType.SCALE );
  }

  /* User method which performs the animation */
  public override void capture( DrawArea da ) {
    _escale = da.sfactor;
  }

  /* Adjusts scaling factor for the given frame */
  public override void adjust( DrawArea da ) {
    double divisor = index / frames;
    index++;
    double sf = _sscale + ((_escale - _sscale) * divisor);
    da.set_scaling_factor( sf );
  }

}

