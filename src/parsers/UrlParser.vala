/*
* Copyright (c) 2020 (https://github.com/phase1geo/Outliner)
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

public class UrlParser : TextParser {

  /* Default constructor */
  public UrlParser() {
    base( "URL" );

    /* Links */
    add_regex( "((mailto:)?[a-z0-9.-]+@[-a-z0-9]+(\\.[-a-z0-9]+)*\\.[a-z]+)", highlight_url );
    add_regex( "((https?|ftp):[^'\">\\s]+)", highlight_url );

  }

  /* Add the URL link */
  private void highlight_url( FormattedText text, MatchInfo match ) {
    add_tag( text, match, 0, FormatTag.URL, get_text( match, 0 ) );
  }

}
