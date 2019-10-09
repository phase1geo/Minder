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

public class UrlLinks {

  private class UrlLink {

    public string lbl  { get; set; default = ""; }
    public string link { get; set; default = ""; }
    public int    spos { get; set; default = -1; }
    public int    epos { get; set; default = -1; }

    /* Constructor */
    public UrlLink( string l, string k, int s, int e ) {
      lbl  = l;
      link = k;
      spos = s;
      epos = e;
    }

  }

  private Array<UrlLink> _links;

  /* Constructor */
  public UrlLinks() {
    _links = new Array<UrlLink>();
  }

}
