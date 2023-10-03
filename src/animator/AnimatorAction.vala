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

using GLib;

public enum AnimationType {
  UNKNOWN = 0,
  NODES,
  NODE,
  FADE,
  PAN,
  SCALE,
  PANSCALE
}

/*
 Base class that allows multiple animation objects to be stored in the
 animator class.
*/
public class AnimatorAction : Object {

  protected string     _name;
  protected bool       _save;
  protected int        _id;
  protected static int _next_id = 0;

  protected int    index  { set; get; default = 0; }
  protected double frames { private set; get; default = 10; }

  /* Default constructor */
  public AnimatorAction( string name, bool save ) {
    _name = name;
    _save = save;
    _id   = _next_id++;
  }

  /* Returns the name of this action for debug purposes */
  public string name() {
    return( _name + "-" + _id.to_string() );
  }

  /* Returns true if we should save after this animation ends */
  public bool save() {
    return( _save );
  }

  /* Returns true if this animation action is complete */
  public bool done() {
    return( index > frames );
  }

  /* Returns the animation type */
  public virtual AnimationType type() {
    return( AnimationType.UNKNOWN );
  }

  /* Captures the end state */
  public virtual void capture( DrawArea da ) {}

  /*
   Adjusts the animation by one frame.  Returns true if the action is
   complete.
  */
  public virtual void adjust( DrawArea da ) {}

  /*
   Allows the animation action to do something after the animation has completed.
  */
  public virtual void on_completion( DrawArea da ) {}

  /*
   Force the animation to complete immediately by forcing the index to
   be equal to the frame count.
  */
  public void flush( DrawArea da ) {
    frames = (double)index;
    adjust( da );
  }

}
