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

public interface NodeBorder : Object {

  /* Returns the search name of the node border */
  public abstract string name();

  /* Returns the name of the node border */
  public abstract string display_name();

  /* Returns the name of the node border light-mode icon */
  public abstract string light_icon_name();

  /* Returns the name of the node border dark-mode icon */
  public abstract string? dark_icon_name();

  /* Returns true if this node border is fillable */
  public abstract bool is_fillable();

  /* Draw method for the node border */
  public abstract void draw_border( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s, int padding );

  /* Draw method for the node fill */
  public abstract void draw_fill( Cairo.Context ctx, double x, double y, double w, double h, NodeSide s, int padding );

}

