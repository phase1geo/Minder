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
// Finds and validates the $$ delimiters shared by Markdown parsing
// and inline LaTeX rendering.
public class LatexSpanParser {

  //-------------------------------------------------------------
  // Returns the next unescaped $$ delimiter at or after offset.
  public static int find_delimiter( string source, int offset ) {
    var delimiter = source.index_of( "$$", offset );
    while( delimiter != -1 ) {
      var slash_count = 0;
      for( var index = delimiter - 1; (index >= 0) && (source[index] == '\\'); index-- ) {
        slash_count++;
      }
      if( (slash_count % 2) == 0 ) {
        return( delimiter );
      }
      delimiter = source.index_of( "$$", delimiter + 2 );
    }
    return( -1 );
  }

  //-------------------------------------------------------------
  // Returns true if the source contains only complete, non-empty
  // formula spans and at least one such span is present.
  public static bool is_latex_source( string source ) {
    var offset = 0;
    var seen   = false;
    while( offset < source.length ) {
      var start = find_delimiter( source, offset );
      if( start == -1 ) {
        break;
      }
      var close = find_delimiter( source, start + 2 );
      if( (close == -1) || (source.substring( start + 2, close - start - 2 ).strip() == "") ) {
        return( false );
      }
      seen   = true;
      offset = close + 2;
    }
    return( seen );
  }

  //-------------------------------------------------------------
  // Returns true when a byte position is inside an opened $$ span.
  // This also handles a span while its closing delimiter is pending.
  public static bool is_latex_at( string source, int position ) {
    var offset  = 0;
    var in_math = false;
    while( offset < source.length ) {
      var delimiter = find_delimiter( source, offset );
      if( delimiter == -1 ) {
        return( in_math );
      }
      if( position < delimiter ) {
        return( in_math );
      }
      in_math = !in_math;
      offset = delimiter + 2;
    }
    return( in_math );
  }

}
