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

public class UnicodeParser : TextParser {

  private DrawArea _da;

  /* Default constructor */
  public UnicodeParser( DrawArea da ) {

    base( "Unicode" );

    _da = da;

    add_regex( "\\\\([a-zA-Z0-9_\\^\\(\\){}!+-=~:\\`'\".<>-]*)", handle_code );
    add_regex( "\\s", handle_nocode );

  }

  /* Highlights the given tag */
  private void handle_code( FormattedText text, MatchInfo match ) {

    var tag = get_text( match, 0 );

    /* Highlight the tag */
    add_tag( text, match, 0, FormatTag.TAG, tag );

    /* If the FormattedText item matches the currently edited */
    if( _da.map.get_current_node() != null ) {
      handle_code_for_ct( _da.map.get_current_node().name, text, match, tag );
    } else if( _da.map.get_current_callout() != null ) {
      handle_code_for_ct( _da.map.get_current_callout().text, text, match, tag );
    }

  }

  private void handle_code_for_ct( CanvasText ct, FormattedText text, MatchInfo match, string tag ) {
    if( ct.text == text ) {
      int start, end;
      match.fetch_pos( 0, out start, out end );
      var cursor = ct.cursor;
      if( (start <= cursor) && (cursor <= end) ) {
        _da.show_auto_completion( _da.win.unicoder.get_matches( tag ), start, end );
      }
    }
  }

  /* Handles hiding the auto-completion window */
  private void handle_nocode( FormattedText text, MatchInfo match ) {
    if( _da.map.get_current_node() != null ) {
      handle_nocode_for_ct( _da.map.get_current_node().name, text, match );
    } else if( _da.map.get_current_callout() != null ) {
      handle_nocode_for_ct( _da.map.get_current_callout().text, text, match );
    }
  }

  private void handle_nocode_for_ct( CanvasText ct, FormattedText text, MatchInfo match ) {
    if( ct.text == text ) {
      int start, end;
      match.fetch_pos( 0, out start, out end );
      if( ct.cursor == start ) {
        _da.hide_auto_completion();
      }
    }
  }

  public override bool tag_handled( FormatTag tag ) {
    return( tag == FormatTag.TAG );
  }

}
