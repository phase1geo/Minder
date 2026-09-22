/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

using GLib;

public enum NodeTableVerticalAlignment {
  TOP,
  MIDDLE,
  BOTTOM;

  //-------------------------------------------------------------
  // Returns the XML value for this alignment.
  public string to_string() {
    switch( this ) {
      case MIDDLE :  return( "middle" );
      case BOTTOM :  return( "bottom" );
      default     :  return( "top" );
    }
  }

  //-------------------------------------------------------------
  // Parses an XML alignment value, defaulting to top.
  public static NodeTableVerticalAlignment parse( string? value ) {
    switch( value ) {
      case "middle" :  return( MIDDLE );
      case "bottom" :  return( BOTTOM );
      default       :  return( TOP );
    }
  }

  //-------------------------------------------------------------
  // Returns the text offset within the available cell height.
  public double offset( double available_height, double content_height ) {
    switch( this ) {
      case MIDDLE :  return( Math.fmax( 0.0, (available_height - content_height) / 2.0 ) );
      case BOTTOM :  return( Math.fmax( 0.0, available_height - content_height ) );
      default     :  return( 0.0 );
    }
  }
}

public class NodeTableRegion : Object {

  private string _text = "";

  public int row      { get; set; default = 0; }
  public int column   { get; set; default = 0; }
  public int row_span { get; set; default = 1; }
  public int col_span { get; set; default = 1; }
  public bool highlighted { get; set; default = false; }
  public NodeTableVerticalAlignment vertical_alignment { get; set; default = NodeTableVerticalAlignment.TOP; }
  public string text {
    get {
      return( _text );
    }
    set {
      if( _text != value ) {
        _text = value;
        text_changed();
      }
    }
  }

  //-------------------------------------------------------------
  // Default constructor.
  public NodeTableRegion( int row, int column, string text = "", int row_span = 1, int col_span = 1 ) {
    this.row      = row;
    this.column   = column;
    _text         = text;
    this.row_span = row_span;
    this.col_span = col_span;
  }

  //-------------------------------------------------------------
  // Allows rendered cells to respond when their text changes.
  protected virtual void text_changed() {}

  //-------------------------------------------------------------
  // Returns true if this region covers the given cell.
  public bool covers( int target_row, int target_column ) {
    return( (target_row >= row) && (target_row < (row + row_span)) &&
            (target_column >= column) && (target_column < (column + col_span)) );
  }

  //-------------------------------------------------------------
  // Returns true if this region intersects the given selection.
  public bool intersects( int first_row, int first_column, int last_row, int last_column ) {
    return( (row <= last_row) && ((row + row_span - 1) >= first_row) &&
            (column <= last_column) && ((column + col_span - 1) >= first_column) );
  }

  //-------------------------------------------------------------
  // Returns true if this region is contained by the selection.
  public bool contained_by( int first_row, int first_column, int last_row, int last_column ) {
    return( (row >= first_row) && (column >= first_column) &&
            ((row + row_span - 1) <= last_row) && ((column + col_span - 1) <= last_column) );
  }

}

public class NodeTableTopology {

  //-------------------------------------------------------------
  // Expands a selection until it fully contains intersecting merged cells.
  public static void expand_selection(
    Array<NodeTableRegion> regions,
    ref int first_row,
    ref int first_column,
    ref int last_row,
    ref int last_column
  ) {
    var expanded = true;
    while( expanded ) {
      expanded = false;
      for( int index=0; index<regions.length; index++ ) {
        var region = regions.index( index );
        if( region.intersects( first_row, first_column, last_row, last_column ) ) {
          var region_last_row = region.row + region.row_span - 1;
          var region_last_column = region.column + region.col_span - 1;
          if( (region.row < first_row) || (region.column < first_column) ||
              (region_last_row > last_row) || (region_last_column > last_column) ) {
            first_row = int.min( first_row, region.row );
            first_column = int.min( first_column, region.column );
            last_row = int.max( last_row, region_last_row );
            last_column = int.max( last_column, region_last_column );
            expanded = true;
          }
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Joins non-empty cell text in visual row-major order.
  public static string merge_text(
    Array<NodeTableRegion> regions,
    int first_row,
    int first_column,
    int last_row,
    int last_column
  ) {
    var merged = "";
    for( int row=first_row; row<=last_row; row++ ) {
      for( int column=first_column; column<=last_column; column++ ) {
        for( int index=0; index<regions.length; index++ ) {
          var region = regions.index( index );
          if( (region.row == row) && (region.column == column) && (region.text.strip() != "") ) {
            merged += ((merged == "") ? "" : " ") + region.text.strip();
            break;
          }
        }
      }
    }
    return( merged );
  }

  //-------------------------------------------------------------
  // Updates a cell region when a row is inserted.
  public static void insert_row( NodeTableRegion region, int row ) {
    if( region.row >= row ) {
      region.row++;
    } else if( (region.row + region.row_span) > row ) {
      region.row_span++;
    }
  }

  //-------------------------------------------------------------
  // Updates a cell region when a column is inserted.
  public static void insert_column( NodeTableRegion region, int column ) {
    if( region.column >= column ) {
      region.column++;
    } else if( (region.column + region.col_span) > column ) {
      region.col_span++;
    }
  }

  //-------------------------------------------------------------
  // Updates a cell region for deleted rows and returns whether it survives.
  public static bool delete_rows( NodeTableRegion region, int first_row, int last_row ) {
    var count = (last_row - first_row) + 1;
    var region_last_row = region.row + region.row_span - 1;
    var overlap_start = int.max( region.row, first_row );
    var overlap_end = int.min( region_last_row, last_row );
    var overlap = int.max( 0, (overlap_end - overlap_start) + 1 );
    if( overlap == 0 ) {
      if( region.row > last_row ) region.row -= count;
    } else if( overlap == region.row_span ) {
      return( false );
    } else {
      if( region.row >= first_row ) region.row = first_row;
      region.row_span -= overlap;
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Updates a cell region for deleted columns and returns whether it survives.
  public static bool delete_columns( NodeTableRegion region, int first_column, int last_column ) {
    var count = (last_column - first_column) + 1;
    var region_last_column = region.column + region.col_span - 1;
    var overlap_start = int.max( region.column, first_column );
    var overlap_end = int.min( region_last_column, last_column );
    var overlap = int.max( 0, (overlap_end - overlap_start) + 1 );
    if( overlap == 0 ) {
      if( region.column > last_column ) region.column -= count;
    } else if( overlap == region.col_span ) {
      return( false );
    } else {
      if( region.column >= first_column ) region.column = first_column;
      region.col_span -= overlap;
    }
    return( true );
  }

}

public class NodeTableTextGrid : Object {

  private Array<Array<string>> _rows;

  public int row_count    { get { return( (int)_rows.length ); } }
  public int column_count { get; private set; default = 1; }
  public bool truncated   { get; private set; default = false; }

  //-------------------------------------------------------------
  // Default constructor.
  public NodeTableTextGrid( int column_count, bool truncated = false ) {
    _rows = new Array<Array<string>>();
    this.column_count = column_count;
    this.truncated = truncated;
  }

  //-------------------------------------------------------------
  // Appends a row to the grid.
  public void append( Array<string> row ) {
    _rows.append_val( row );
  }

  //-------------------------------------------------------------
  // Returns a cell value or an empty string if it is absent.
  public string get( int row, int column ) {
    if( (row < 0) || (row >= _rows.length) ) return( "" );
    var values = _rows.index( row );
    return( ((column < 0) || (column >= values.length)) ? "" : values.index( column ) );
  }

}

public class NodeTableTextParser {

  public const int MAX_ROWS    = 100;
  public const int MAX_COLUMNS = 50;
  public const int MAX_CELLS   = 1000;

  //-------------------------------------------------------------
  // Constrains dimensions to the supported table size.
  public static bool limit_dimensions( ref int row_count, ref int column_count ) {
    var original_rows = row_count;
    var original_columns = column_count;
    row_count = int.min( int.max( row_count, 1 ), MAX_ROWS );
    column_count = int.min( int.max( column_count, 1 ), MAX_COLUMNS );
    if( (row_count * column_count) > MAX_CELLS ) {
      row_count = int.max( 1, MAX_CELLS / column_count );
    }
    return( (row_count != original_rows) || (column_count != original_columns) );
  }

  //-------------------------------------------------------------
  // Parses tab-separated text without discarding trailing empty cells.
  public static NodeTableTextGrid from_tsv( string source ) {
    var normalized = source.replace( "\r\n", "\n" ).replace( "\r", "\n" );
    while( normalized.has_suffix( "\n" ) ) {
      normalized = normalized.substring( 0, normalized.length - 1 );
    }
    var lines = normalized.split( "\n" );
    var row_count = int.max( lines.length, 1 );
    var column_count = 1;
    foreach( string line in lines ) {
      column_count = int.max( column_count, line.split( "\t" ).length );
    }
    var truncated = limit_dimensions( ref row_count, ref column_count );
    var grid = new NodeTableTextGrid( column_count, truncated );
    for( int row=0; row<int.min( lines.length, row_count ); row++ ) {
      var values = new Array<string>();
      var fields = lines[row].split( "\t" );
      for( int column=0; column<int.min( fields.length, column_count ); column++ ) {
        values.append_val( fields[column] );
      }
      grid.append( values );
    }
    return( grid );
  }

  //-------------------------------------------------------------
  // Returns true when a line has Markdown table delimiters.
  public static bool is_markdown_row( string source ) {
    var row = source.strip();
    return( row.has_prefix( "|" ) && row.has_suffix( "|" ) );
  }

  //-------------------------------------------------------------
  // Removes Markdown's single padding spaces from an exported cell.
  private static string normalize_markdown_cell( string source ) {
    var value = source;
    if( value.has_prefix( " " ) ) value = value.substring( 1 );
    if( value.has_suffix( " " ) ) value = value.substring( 0, value.length - 1 );
    return( value.replace( "<br>", "\n" ) );
  }

  //-------------------------------------------------------------
  // Parses one Markdown table row.
  private static Array<string> parse_markdown_row( string source ) {
    var values = new Array<string>();
    var row = source.strip();
    if( !row.has_prefix( "|" ) || !row.has_suffix( "|" ) ) return( values );
    var value = new StringBuilder();
    for( int index=1; index<(row.length - 1); index++ ) {
      if( (row[index] == '\\') && ((index + 1) < (row.length - 1)) && (row[index + 1] == '|') ) {
        value.append_c( '|' );
        index++;
      } else if( row[index] == '|' ) {
        values.append_val( normalize_markdown_cell( value.str ) );
        value = new StringBuilder();
      } else {
        value.append_c( row[index] );
      }
    }
    values.append_val( normalize_markdown_cell( value.str ) );
    return( values );
  }

  //-------------------------------------------------------------
  // Returns true if the row is a Markdown table separator.
  private static bool is_markdown_separator( Array<string> values ) {
    if( values.length == 0 ) return( false );
    for( int index=0; index<values.length; index++ ) {
      var value = values.index( index ).strip();
      if( value.has_prefix( ":" ) ) value = value.substring( 1 );
      if( value.has_suffix( ":" ) ) value = value.substring( 0, value.length - 1 );
      if( value.length < 3 ) return( false );
      for( int character=0; character<value.length; character++ ) {
        if( value[character] != '-' ) return( false );
      }
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Parses exported Markdown table rows.
  public static NodeTableTextGrid? from_markdown( Array<string> source ) {
    var parsed_rows = new Array<Array<string>>();
    var row_count = 0;
    var column_count = 0;
    for( int index=0; index<source.length; index++ ) {
      var values = parse_markdown_row( source.index( index ) );
      if( (values.length == 0) || is_markdown_separator( values ) ) continue;
      parsed_rows.append_val( values );
      row_count++;
      column_count = int.max( column_count, (int)values.length );
    }
    if( row_count == 0 ) return( null );
    var truncated = limit_dimensions( ref row_count, ref column_count );
    var grid = new NodeTableTextGrid( column_count, truncated );
    for( int row=0; row<int.min( (int)parsed_rows.length, row_count ); row++ ) {
      grid.append( parsed_rows.index( row ) );
    }
    return( grid );
  }

}
