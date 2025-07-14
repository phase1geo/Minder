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

public class TaggerParser : TextParser {

  private DrawArea _da;

  /* Default constructor */
  public TaggerParser( DrawArea da ) {

    base( "Tagger" );

    _da = da;

    add_regex( "\\s(@(\\S*))", handle_tag );
    add_regex( "\\s", handle_notag );

  }

  /* Highlights the given tag */
  private void handle_tag( FormattedText text, MatchInfo match ) {

    var tag = get_text( match, 2 );

    /* Highlight the tag */
    add_tag( text, match, 1, FormatTag.TAG, tag );

    /* If the FormattedText item matches the currently edited */
    var current = _da.map.get_current_node();
    if( (current != null) && (current.name.text == text) ) {

      int start, end;
      match.fetch_pos( 1, out start, out end );

      /* If the cursor is at the end of the tag, display the auto-completer */
      var cursor = current.name.cursor;
      if( (start <= cursor) && (cursor <= end) ) {
        _da.show_auto_completion( _da.tagger.get_matches( tag ), (start + 1), end );
      }

    }

  }

  /* Handles hiding the auto-completion window */
  private void handle_notag( FormattedText text, MatchInfo match ) {
    var current = _da.map.get_current_node();
    if( (current != null) && (current.name.text == text) ) {
      int start, end;
      match.fetch_pos( 0, out start, out end );
      if( current.name.cursor == start ) {
        _da.hide_auto_completion();
      }
    }
  }

  public override bool tag_handled( FormatTag tag ) {
    return( tag == FormatTag.TAG );
  }

}
