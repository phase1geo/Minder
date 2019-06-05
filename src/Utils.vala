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
using Gdk;
using Cairo;

public class Utils {

  /*
   Helper function for converting an RGBA color value to a stringified color
   that can be used by a markup parser.
  */
  public static string color_from_rgba( RGBA rgba ) {
    return( "#%02x%02x%02x".printf( (int)(rgba.red * 255), (int)(rgba.green * 255), (int)(rgba.blue * 255) ) );
  }

  /* Sets the context source color to the given color value */
  public static void set_context_color( Context ctx, RGBA color ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
  }

  /*
   Sets the context source color to the given color value overriding the
   alpha value with the given value.
  */
  public static void set_context_color_with_alpha( Context ctx, RGBA color, double alpha ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, alpha );
  }

  /*
   Adds the given accelerator label to the given menu item.
  */
  public static void add_accel_label( Gtk.MenuItem item, uint key, Gdk.ModifierType mods ) {

    /* Convert the menu item to an accelerator label */
    AccelLabel? label = item.get_child() as AccelLabel;

    if( label == null ) return;

    /* Add the accelerator to the label */
    label.set_accel( key, mods );
    label.refetch();

  }

  /*
   Checks the given string to see if it is a match to the given pattern.  If
   it is, the matching portion of the string appended to the list of matches.
  */
  public static void match_string( string pattern, string value, string type, Node? node, Connection? conn, ref Gtk.ListStore matches ) {
    int index = value.casefold().index_of( pattern );
    if( index != -1 ) {
      TreeIter it;
      int    start_index = (index > 20) ? (index - 20) : 0;
      string prefix      = (index > 20) ? "…"        : "";
      string str         = prefix +
                           value.substring( start_index, (index - start_index) ) + "<u>" +
                           value.substring( index, pattern.length ) + "</u>" +
                           value.substring( (index + pattern.length), -1 );
      matches.append( out it );
      matches.set( it, 0, type, 1, str, 2, node, 3, conn, -1 );
    }
  }

  /* Returns true if the given coordinates are within the specified bounds */
  public static bool is_within_bounds( double x, double y, double bx, double by, double bw, double bh ) {
    return( (bx < x) && (x < (bx + bw)) && (by < y) && (y < (by + bh)) );
  }

  /* Returns a string that is suitable to use as an inspector title */
  public static string make_title( string str ) {
    return( "<b>" + str + "</b>" );
  }

}
