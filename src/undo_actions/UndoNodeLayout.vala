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

  private DrawArea _da;
  private string   _old_layout;
  private string   _new_layout;

  /* Default constructor */
  public UndoNodeLayout( DrawArea da, Layout old_layout, Layout new_layout ) {
    base( _( "change layout" ) );
    _da         = da;
    _old_layout = old_layout.name;
    _new_layout = new_layout.name;
  }

  /* Performs an undo operation for this data */
  public override void undo() {
    _da.set_layout( _old_layout, false );
    _da.loaded();
  }

  /* Performs a redo operation */
  public override void redo() {
    _da.set_layout( _new_layout, false );
    _da.loaded();
  }

}
