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

public class UndoNodeLayout : UndoItem {

  private string _old_layout;
  private string _new_layout;
  private Node?  _root;

  /* Default constructor */
  public UndoNodeLayout( Layout old_layout, Layout new_layout, Node? root_node ) {
    base( _( "change layout" ) );
    _old_layout = old_layout.name;
    _new_layout = new_layout.name;
    _root       = root_node;
  }

  /* Performs an undo operation for this data */
  public override void undo( DrawArea da ) {
    da.set_layout( _old_layout, _root, false );
    da.loaded();
  }

  /* Performs a redo operation */
  public override void redo( DrawArea da ) {
    da.set_layout( _new_layout, _root, false );
    da.loaded();
  }

}
