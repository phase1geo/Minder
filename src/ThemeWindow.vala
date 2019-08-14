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

public class ThemeWindow : Window {

  private int          _index;
  private Array<RGBA?> _link_colors;

  public    string name               { protected set; get; }
  public    Image  icon               { protected set; get; }
  public    RGBA   background         { protected set; get; }
  public    RGBA   foreground         { protected set; get; }
  public    RGBA   root_background    { protected set; get; }
  public    RGBA   root_foreground    { protected set; get; }
  public    RGBA   nodesel_background { protected set; get; }
  public    RGBA   nodesel_foreground { protected set; get; }
  public    RGBA   textsel_background { protected set; get; }
  public    RGBA   textsel_foreground { protected set; get; }
  public    RGBA   text_cursor        { protected set; get; }
  public    RGBA   attachable_color   { protected set; get; }
  public    RGBA   connection_color   { protected set; get; }
  public    bool   prefer_dark        { protected set; get; }

  /* Adds the given color to the list of link colors */
  protected void add_link_color( RGBA color ) {
    _link_colors.append_val( color );
  }

  /* Returns the CSS provider for this theme */
  public CssProvider get_css_provider() {
    CssProvider provider = new CssProvider();
    try {
      var css_data = "@define-color colorPrimary #603461; " +
                     "@define-color textColorPrimary @SILVER_100; " +
                     // "@define-color textColorPrimaryShadow @SILVER_500; " +
                     "@define-color colorAccent #603461; " +
                     ".theme-selected { background: #087DFF; } " +
                     ".find { -gtk-icon-source: -gtk-icontheme('edit-find'); -gtk-icon-theme: 'hicolor'; } " +
                     ".canvas { background: " + background.to_string() + "; }";
      provider.load_from_data( css_data );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to load background color: %s", e.message );
    }
    return( provider );
  }

}
