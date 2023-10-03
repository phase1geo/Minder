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

using Gtk;

public class UndoNodeCallout : UndoItem {

  private Node     _node;
  private Callout? _prev_callout = null;

  /* Constructor for a node callout change */
  public UndoNodeCallout( Node node ) {
    base( _( "node callout changed" ) );
    _node         = node;
    _prev_callout = node.callout;
  }

  private void change( DrawArea da ) {
    var current = _node.callout;
    _node.callout = _prev_callout;
    _prev_callout = current;
    da.queue_draw();
    da.auto_save();
  }

  /* Undoes a node callout add/remove */
  public override void undo( DrawArea da ) {
    change( da );
  }

  /* Redoes a node callout add/remove */
  public override void redo( DrawArea da ) {
    change( da );
  }

}
