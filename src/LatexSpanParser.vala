/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation; either version 2 of
* the License, or (at your option) any later version.
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

//-------------------------------------------------------------
// Finds and validates $ and $$ delimiters shared by Markdown parsing
// and inline LaTeX rendering.
public class LatexSpanParser {

  //-------------------------------------------------------------
  // Returns true when the delimiter at the given byte offset is escaped.
  private static bool is_escaped( string source, int offset ) {
    var slash_count = 0;
    for( var index = offset - 1; (index >= 0) && (source[index] == '\\'); index-- ) {
      slash_count++;
    }
    return( (slash_count % 2) != 0 );
  }

  //-------------------------------------------------------------
  // Returns true when the dollar sign at offset is escaped.
  public static bool is_escaped_dollar( string source, int offset ) {
    return(
      (offset >= 0) && (offset < source.length) &&
      (source[offset] == '$') && is_escaped( source, offset )
    );
  }

  //-------------------------------------------------------------
  // Returns true when the byte is Markdown delimiter whitespace.
  private static bool is_whitespace( char value ) {
    return( (value == ' ') || (value == '\t') || (value == '\r') || (value == '\n') );
  }

  //-------------------------------------------------------------
  // Returns true when a single dollar sign can open an inline span.
  private static bool can_open_inline( string source, int offset ) {
    return(
      ((offset + 1) < source.length) &&
      (source[offset + 1] != '$') &&
      !is_whitespace( source[offset + 1] )
    );
  }

  //-------------------------------------------------------------
  // Returns true when a single dollar sign can close an inline span.
  private static bool can_close_inline( string source, int offset ) {
    if( (offset == 0) || (source[offset - 1] == '$') || is_whitespace( source[offset - 1] ) ) {
      return( false );
    }
    return(
      ((offset + 1) >= source.length) ||
      ((source[offset + 1] < '0') || (source[offset + 1] > '9'))
    );
  }

  //-------------------------------------------------------------
  // Finds the next unescaped delimiter which can open a formula.
  private static int find_opening( string source, int offset, out int delimiter_length ) {
    delimiter_length = 0;
    var delimiter = source.index_of( "$", offset );
    while( delimiter != -1 ) {
      if( !is_escaped( source, delimiter ) ) {
        if( ((delimiter + 1) < source.length) && (source[delimiter + 1] == '$') ) {
          delimiter_length = 2;
          return( delimiter );
        }
        if( can_open_inline( source, delimiter ) ) {
          delimiter_length = 1;
          return( delimiter );
        }
      }
      delimiter = source.index_of( "$", delimiter + 1 );
    }
    return( -1 );
  }

  //-------------------------------------------------------------
  // Finds the matching closing delimiter.  For inline spans, restart
  // identifies a later opening delimiter which supersedes the first one.
  private static int find_closing( string source, int start, int delimiter_length, out int restart ) {
    restart = -1;
    var offset = start + delimiter_length;
    while( offset < source.length ) {
      var delimiter = source.index_of( "$", offset );
      if( delimiter == -1 ) {
        break;
      }
      var newline = source.index_of( "\n", offset );
      if( (delimiter_length == 1) && (newline != -1) && (newline < delimiter) ) {
        break;
      }
      if( is_escaped( source, delimiter ) ) {
        offset = delimiter + 1;
        continue;
      }
      var is_double = ((delimiter + 1) < source.length) && (source[delimiter + 1] == '$');
      if( delimiter_length == 2 ) {
        if( is_double ) {
          return( delimiter );
        }
        offset = delimiter + 1;
      } else {
        var follows_dollar = (delimiter > 0) && (source[delimiter - 1] == '$');
        if( !is_double && !follows_dollar ) {
          if( can_close_inline( source, delimiter ) ) {
            return( delimiter );
          }
          if( can_open_inline( source, delimiter ) ) {
            restart = delimiter;
            return( -1 );
          }
        }
        offset = delimiter + (is_double ? 2 : 1);
      }
    }
    return( -1 );
  }

  //-------------------------------------------------------------
  // Returns the next complete formula span at or after offset.
  public static bool find_span( string source, int offset, out int start,
                                out int close, out int delimiter_length ) {
    start = -1;
    close = -1;
    delimiter_length = 0;
    while( offset < source.length ) {
      start = find_opening( source, offset, out delimiter_length );
      if( start == -1 ) {
        return( false );
      }
      int restart;
      close = find_closing( source, start, delimiter_length, out restart );
      if( close != -1 ) {
        return( true );
      }
      offset = (restart == -1) ? (start + delimiter_length) : restart;
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if the source contains only complete, non-empty
  // formula spans and at least one such span is present.
  public static bool is_latex_source( string source ) {
    var offset = 0;
    var seen   = false;
    while( offset < source.length ) {
      int delimiter_length;
      var start = find_opening( source, offset, out delimiter_length );
      if( start == -1 ) {
        break;
      }
      int restart;
      var close = find_closing( source, start, delimiter_length, out restart );
      if( restart != -1 ) {
        offset = restart;
        continue;
      }
      if( (close == -1) ||
          (source.substring( start + delimiter_length,
                             close - start - delimiter_length ).strip() == "") ) {
        return( false );
      }
      seen   = true;
      offset = close + delimiter_length;
    }
    return( seen );
  }

  //-------------------------------------------------------------
  // Returns true when a byte position is inside an opened formula span.
  // This also handles a span while its closing delimiter is pending.
  public static bool is_latex_at( string source, int position ) {
    var offset = 0;
    while( offset < source.length ) {
      int delimiter_length;
      var start = find_opening( source, offset, out delimiter_length );
      if( start == -1 ) {
        return( false );
      }
      int restart;
      var close = find_closing( source, start, delimiter_length, out restart );
      if( restart != -1 ) {
        offset = restart;
        continue;
      }
      if( position < start ) {
        return( false );
      }
      if( close == -1 ) {
        return( true );
      }
      if( position < close ) {
        return( true );
      }
      offset = close + delimiter_length;
    }
    return( false );
  }

}
