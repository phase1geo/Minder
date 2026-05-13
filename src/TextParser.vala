/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/Outliner)
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

public class TextParser {

  public delegate void TextMatchCallback( FormattedText text, MatchInfo match_info );

  private string _name;
  private bool   _enable;

  public string name {
    get {
      return( _name );
    }
  }
  public bool enable {
    get {
      return( _enable );
    }
    set {
      if( _enable != value ) {
        _enable = value;
        enable_changed();
      }
    }
  }

  public signal void parse( FormattedText text );
  public signal void enable_changed();

  //-------------------------------------------------------------
  // Default constructor
  public TextParser( string name ) {
    _name   = name;
    _enable = true;
  }

  //-------------------------------------------------------------
  // Adds a regular expression to this parser
  protected void add_regex( string pattern, TextMatchCallback func ) {
    try {
      var re = new Regex( pattern, RegexCompileFlags.MULTILINE );
      parse.connect((text) => {
        MatchInfo matches;
        var       start = 0;
        try {
          while( re.match_full( text.text, -1, start, 0, out matches ) ) {
            int start_pos, end_pos;
            matches.fetch_pos( 0, out start_pos, out end_pos );
            start = end_pos;
            func( text, matches );
          }
        } catch( RegexError e ) {}
      });
    } catch( RegexError e ) {
      stdout.printf( _( "Parser regex error (pattern: %s, error: %s)\n" ), pattern, e.message );
      return;
    }
  }

  //-------------------------------------------------------------
  // Helper function that adds the tag for the given parenthesis
  // match.
  protected void add_tag( FormattedText text, MatchInfo matches, int paren, FormatTag tag, string? extra = null ) {
    int start, end;
    matches.fetch_pos( paren, out start, out end );
    text.add_tag( tag, start, end, true, extra );
  }

  //-------------------------------------------------------------
  // Removes all tags in the range of the given matched parenthesis.
  protected void remove_tags( FormattedText text, MatchInfo matches, int paren ) {
    int start, end;
    matches.fetch_pos( paren, out start, out end );
    text.remove_all_tags( start, end );
  }

  //-------------------------------------------------------------
  // Returns true if the given match range contains the given tag.
  protected bool within_tag( FormattedText text, MatchInfo matches, int paren, FormatTag tag ) {
    int start, end;
    matches.fetch_pos( paren, out start, out end );
    return( text.is_tag_applied_at_index( tag, start ) );
  }

  //-------------------------------------------------------------
  // Helper function that returns the matched string.
  protected string get_text( MatchInfo matches, int paren ) {
    return( matches.fetch( paren ) );
  }

  //-------------------------------------------------------------
  // Returns true if the associated tag should enable the associated
  // FormatBar button.
  public virtual bool tag_handled( FormatTag tag ) {
    return( false );
  }

  //-------------------------------------------------------------
  // This is called when the associated FormatBar button is clicked.
  public virtual void insert_tag( CanvasText ct, FormatTag tag, int start_pos, int end_pos, UndoTextBuffer undo_buffer, string? extra = null ) {
    ct.text.add_tag( tag, start_pos, end_pos, false, extra );
  }

  //-------------------------------------------------------------
  // This is called when the associated FormatBar button is unclicked.
  public virtual void remove_all_tags( CanvasText ct, int start_pos, int end_pos, UndoTextBuffer undo_buffer ) {
    ct.text.remove_all_tags( start_pos, end_pos );
  }

}
