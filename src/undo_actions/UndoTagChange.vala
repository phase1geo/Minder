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

public class UndoTagChange : UndoItem {

  Tag _tag;
  Tag _prev_tag;

  //-------------------------------------------------------------
  // Constructor for a node tag change.
  public UndoTagChange( Tag tag, Tag prev_tag ) {
    base( _( "tag change" ) );
    _tag      = tag;
    _prev_tag = prev_tag;
  }

  //-------------------------------------------------------------
  // Performs the tag change.
  private void change( MindMap map ) {
    var prev_tag = _tag.copy();
    _tag.name  = _prev_tag.name;
    _tag.color = _prev_tag.color;
    _prev_tag  = prev_tag;
    map.auto_save();
    map.reload_tags();
  }

  //-------------------------------------------------------------
  // Undoes a node tag change.
  public override void undo( MindMap map ) {
    change( map );
  }

  //-------------------------------------------------------------
  // Redoes a node tag change.
  public override void redo( MindMap map ) {
    change( map );
  }

}
