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

public class MarkdownParser : TextParser {

  private MindMap _map;

  /* Default constructor */
  public MarkdownParser( MindMap map ) {
    base( "Markdown" );

    _map = map;

    /* Header */
    add_regex( "^(#{1,6})[^#].*$", highlight_header );

    /* Lists */
    add_regex( "^\\s*(\\*|\\+|\\-|[0-9]+\\.)\\s", (text, match) => {
      add_tag( text, match, 1, FormatTag.COLOR, _map.get_theme().get_color( "markdown_listitem" ).to_string() );
    });

    /* Code */
    add_regex( "(`)([^`]+)(`)", (text, match) => {
      make_grey( text, match, 1 );
      add_tag( text, match, 2, FormatTag.CODE );
      make_grey( text, match, 3 );
    });

    /* Bold */
    add_regex( "(\\*\\*)([^* \\t].*?)(?<!\\\\|\\*| |\\t)(\\*\\*)", highlight_bold );
    add_regex( "(__)([^_ \\t].*?(?<!\\\\|_| |\\t))(__)", highlight_bold );

    /* Italics */
    add_regex( "(?<!_)(_)([^_ \t].*?(?<!\\\\|_| |\\t))(_)(?!_)", highlight_italics );
    add_regex( "(?<!\\*)(\\*)([^* \t].*?(?<!\\\\|\\*| |\\t))(\\*)(?!\\*)", highlight_italics );

    /* Strikethrough */
    add_regex( "(~~)([^~ \t].*?(?<!\\\\|~| |\\t))(~~)", highlight_strikethrough );

    /* Links */
    add_regex( "(\\[)(.+?)(\\]\\s*\\((\\S+).*\\))", highlight_url1 );
    add_regex( "(<)((mailto:)?[a-z0-9.-]+@[-a-z0-9]+(\\.[-a-z0-9]+)*\\.[a-z]+)(>)", highlight_url2 );
    add_regex( "(<)((https?|ftp):[^'\">\\s]+)(>)", highlight_url3 );

    /* Subscript/Superscript */
    add_regex( "(<sub>)(.*?)(</sub>)", highlight_subscript );
    add_regex( "(<sup>)(.*?)(</sup>)", highlight_superscript );

  }

  private void make_grey( FormattedText text, MatchInfo match, int paren ) {
    add_tag( text, match, paren, FormatTag.SYNTAX );
  }

  private void highlight_header( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    add_tag( text, match, 0, FormatTag.HEADER, get_text( match, 1 ).length.to_string() );
  }

  private void highlight_bold( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    add_tag( text, match, 2, FormatTag.BOLD );
    make_grey( text, match, 3 );
  }

  private void highlight_italics( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    add_tag( text, match, 2, FormatTag.ITALICS );
    make_grey( text, match, 3 );
  }

  private void highlight_strikethrough( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    add_tag( text, match, 2, FormatTag.STRIKETHRU );
    make_grey( text, match, 3 );
  }

  private void highlight_url1( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    add_tag( text, match, 2, FormatTag.URL, get_text( match, 4 ) );
    make_grey( text, match, 3 );
  }

  private void highlight_url2( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    add_tag( text, match, 2, FormatTag.URL, get_text( match, 2 ) );
    make_grey( text, match, 5 );
  }

  private void highlight_url3( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    add_tag( text, match, 2, FormatTag.URL, get_text( match, 2 ) );
    make_grey( text, match, 4 );
  }

  private void highlight_subscript( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    add_tag( text, match, 2, FormatTag.SUB, get_text( match, 2 ) );
    make_grey( text, match, 3 );
  }

  private void highlight_superscript( FormattedText text, MatchInfo match ) {
    make_grey( text, match, 1 );
    add_tag( text, match, 2, FormatTag.SUPER, get_text( match, 2 ) );
    make_grey( text, match, 3 );
  }

  /* Returns true if the associated tag should enable the associated FormatBar button */
  public override bool tag_handled( FormatTag tag ) {
    switch( tag ) {
      case FormatTag.HEADER  :
      case FormatTag.CODE    :
      case FormatTag.BOLD    :
      case FormatTag.ITALICS :
      case FormatTag.URL     :  return( true );
      default                :  return( false );
    }
  }

  /* This is called when the associated FormatBar button is clicked */
  public override void insert_tag( CanvasText ct, FormatTag tag, int start_pos, int end_pos, UndoTextBuffer undo_buffer, string? extra ) {
    switch( tag ) {
      case FormatTag.HEADER  :  insert_header( ct, start_pos, extra, undo_buffer );  break;
      case FormatTag.CODE    :  insert_surround( ct, "`", start_pos, end_pos, undo_buffer );  break;
      case FormatTag.BOLD    :  insert_surround( ct, "**", start_pos, end_pos, undo_buffer );  break;
      case FormatTag.ITALICS :  insert_surround( ct, "_", start_pos, end_pos, undo_buffer );  break;
      case FormatTag.URL     :  insert_link( ct, start_pos, end_pos, extra, undo_buffer );  break;
    }
  }

  private void insert_header( CanvasText ct, int start_pos, string extra, UndoTextBuffer undo_buffer ) {
    var nl     = ct.text.text.slice( 0, start_pos ).last_index_of( "\n" );
    var num    = int.parse( extra );
    var hashes = "";
    for( int i=0; i<num; i++ ) {
      hashes += "#";
    }
    if( nl == -1 ) {
      var inserts = new Array<InsertText?>();
      inserts.append_val( {0, "%s ".printf( hashes )} );
      ct.insert_ranges( inserts, undo_buffer );
    } else {
      ct.replace( nl, (nl + "\n".char_count()), "\n%s ".printf( hashes ), undo_buffer );
    }
  }

  private void insert_surround( CanvasText ct, string surround, int start_pos, int end_pos, UndoTextBuffer undo_buffer ) {
    var inserts = new Array<InsertText?>();
    inserts.append_val( {start_pos, surround} );
    inserts.append_val( {end_pos,   surround} );
    ct.insert_ranges( inserts, undo_buffer );
  }

  private void insert_link( CanvasText ct, int start_pos, int end_pos, string url, UndoTextBuffer undo_buffer ) {
    var seltext = ct.text.text.slice( start_pos, end_pos );
    var inserts = new Array<InsertText?>();
    if( seltext == url ) {
      inserts.append_val( {start_pos, "<"} );
      inserts.append_val( {end_pos,   ">"} );
    } else {
      inserts.append_val( {start_pos, "["} );
      inserts.append_val( {end_pos,   "](%s)".printf( url )} );
    }
    ct.insert_ranges( inserts, undo_buffer );
  }

}
