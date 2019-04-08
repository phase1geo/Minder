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

public class UndoItem : GLib.Object {

  public string name { set; get; default = ""; }
  public int    id   { set; get; default = -1; }

  /* Default constructor */
  public UndoItem( string name ) {
    this.name = name;
  }

  /* Causes the stored item to be put into the before state */
  public virtual void undo( DrawArea da ) {}

  /* Causes the stored item to be put into the after state */
  public virtual void redo( DrawArea da ) {}

  /* Checks to see if the given undo item is "mergeable" with this one */
  public virtual bool matches( UndoItem item ) {
    return( false );
  }

  public virtual void replace_with_item( UndoItem item ) {
    /* Do nothing by default */
  }

  public virtual string to_string() {
    return( "%s [%d]".printf( name, id ) );
  }

}
