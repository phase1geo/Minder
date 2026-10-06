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

using Cairo;
using Gdk;
using GLib;
using Pango;

public enum NodeTableFormat {
  BOLD,
  ITALIC,
  UNDERLINE,
  STRIKETHROUGH
}

public class NodeTableCell : NodeTableRegion {

  private MindMap _map;
  private int _font_size = 12;
  private FormattedText _formatted;
  private LatexRenderer _latex;
  private bool _bold = false;
  private bool _italic = false;
  private bool _underline = false;
  private bool _strikethrough = false;

  public Pango.Alignment alignment { get; private set; default = Pango.Alignment.LEFT; }
  public Pango.Layout layout { get; set; }

  public signal void latex_changed();

  //-------------------------------------------------------------
  // Creates a rendered table cell.
  public NodeTableCell( MindMap map, int row, int column, string text = "", int row_span = 1, int col_span = 1 ) {
    base( row, column, text, row_span, col_span );
    _map          = map;
    layout = map.canvas.create_pango_layout( text );
    layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    _latex = new LatexRenderer();
    _latex.attach( layout.get_context() );
    _latex.changed.connect(() => {
      apply_latex_attributes();
      latex_changed();
    });
    update_latex();
  }

  //-------------------------------------------------------------
  // Creates a deep copy of a rendered table cell.
  public NodeTableCell.copy( MindMap map, NodeTableCell cell ) {
    this( map, cell.row, cell.column, cell.text, cell.row_span, cell.col_span );
    copy_style( cell );
    var description = cell.layout.get_font_description();
    if( description != null ) {
      layout.set_font_description( description );
    }
  }

  //-------------------------------------------------------------
  // Copies the visual style from another cell.
  public void copy_style( NodeTableCell cell ) {
    alignment    = cell.alignment;
    highlighted  = cell.highlighted;
    _bold         = cell._bold;
    _italic       = cell._italic;
    _underline    = cell._underline;
    _strikethrough = cell._strikethrough;
    apply_latex_attributes();
  }

  //-------------------------------------------------------------
  // Sets the horizontal alignment of this cell's text.
  public void set_text_alignment( Pango.Alignment value ) {
    alignment = value;
    layout.set_alignment( alignment );
  }

  //-------------------------------------------------------------
  // Returns whether the requested format is enabled.
  public bool format_enabled( NodeTableFormat format ) {
    switch( format ) {
      case NodeTableFormat.BOLD          :  return( _bold );
      case NodeTableFormat.ITALIC        :  return( _italic );
      case NodeTableFormat.UNDERLINE     :  return( _underline );
      case NodeTableFormat.STRIKETHROUGH :  return( _strikethrough );
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Enables or disables the requested format.
  public void set_format( NodeTableFormat format, bool enabled ) {
    switch( format ) {
      case NodeTableFormat.BOLD          :  _bold = enabled;          break;
      case NodeTableFormat.ITALIC        :  _italic = enabled;        break;
      case NodeTableFormat.UNDERLINE     :  _underline = enabled;     break;
      case NodeTableFormat.STRIKETHROUGH :  _strikethrough = enabled; break;
    }
    apply_latex_attributes();
  }

  //-------------------------------------------------------------
  // Clears the cell text and restores its default style.
  public void clear() {
    text = "";
    alignment = Pango.Alignment.LEFT;
    highlighted = false;
    _bold = false;
    _italic = false;
    _underline = false;
    _strikethrough = false;
    update_latex();
  }

  //-------------------------------------------------------------
  // Updates the cell font and LaTeX rendering size.
  public void set_font( string? family, int size ) {
    var description = new Pango.FontDescription();
    if( family != null ) description.set_family( family );
    _font_size = size;
    description.set_size( size * Pango.SCALE );
    layout.set_font_description( description );
    _latex.update( _formatted, _font_size );
    apply_latex_attributes();
  }

  //-------------------------------------------------------------
  // Rebuilds the formatted text and embedded LaTeX spans.
  private void update_latex() {
    _formatted = new FormattedText.with_text( _map, text );
    _latex.update( _formatted, _font_size );
    apply_latex_attributes();
  }

  //-------------------------------------------------------------
  // Handles text changes inherited from the cell region.
  protected override void text_changed() {
    update_latex();
  }

  //-------------------------------------------------------------
  // Applies formatting and LaTeX attributes to the layout.
  private void apply_latex_attributes() {
    var attributes = get_format_attributes();
    _latex.apply_attributes( text, ref attributes );
    layout.set_text( text, -1 );
    layout.set_attributes( attributes );
    layout.set_alignment( alignment );
  }

  //-------------------------------------------------------------
  // Returns all Pango attributes for this cell.
  public Pango.AttrList get_format_attributes() {
    var attributes = _formatted.get_attributes();
    if( _bold ) {
      var attribute = Pango.attr_weight_new( Pango.Weight.BOLD );
      attribute.start_index = 0;
      attribute.end_index = text.length;
      attributes.change( (owned)attribute );
    }
    if( _italic ) {
      var attribute = Pango.attr_style_new( Pango.Style.ITALIC );
      attribute.start_index = 0;
      attribute.end_index = text.length;
      attributes.change( (owned)attribute );
    }
    if( _underline ) {
      var attribute = Pango.attr_underline_new( Pango.Underline.SINGLE );
      attribute.start_index = 0;
      attribute.end_index = text.length;
      attributes.change( (owned)attribute );
    }
    if( _strikethrough ) {
      var attribute = Pango.attr_strikethrough_new( true );
      attribute.start_index = 0;
      attribute.end_index = text.length;
      attributes.change( (owned)attribute );
    }
    return( attributes );
  }

  //-------------------------------------------------------------
  // Draws the cell text and any embedded LaTeX.
  public void draw(
    Cairo.Context context,
    double x,
    double y,
    RGBA foreground,
    double opacity
  ) {
    Utils.set_context_color_with_alpha( context, foreground, opacity );
    context.move_to( x, y );
    _latex.prepare_draw( foreground, opacity );
    Pango.cairo_update_layout( context, layout );
    Pango.cairo_show_layout( context, layout );
  }

}

public class NodeTable : Object {

  private const double MIN_COLUMN_WIDTH = 56.0;
  private const double MIN_ROW_HEIGHT   = 28.0;
  private const double MAX_CELL_WIDTH   = 220.0;
  private const double CELL_PADDING     = 6.0;
  private MindMap _map;
  private Array<NodeTableCell> _cells;
  private double[] _column_widths;
  private double[] _row_heights;

  public int rows       { get; private set; default = 2; }
  public int columns    { get; private set; default = 2; }
  public double width   { get; private set; default = 0.0; }
  public double height  { get; private set; default = 0.0; }

  public signal void resized();

  //-------------------------------------------------------------
  // Adds a rendered cell and connects its resize notification.
  private void append_cell( NodeTableCell cell ) {
    cell.latex_changed.connect(() => {
      update_layout();
      resized();
      _map.queue_draw();
    });
    _cells.append_val( cell );
  }

  //-------------------------------------------------------------
  // Creates an empty table with the requested dimensions.
  public NodeTable( MindMap map, int rows = 2, int columns = 2 ) {
    _map         = map;
    NodeTableTextParser.limit_dimensions( ref rows, ref columns );
    this.rows    = rows;
    this.columns = columns;
    _cells       = new Array<NodeTableCell>();
    fill_empty_cells();
    for( int index=0; index<_cells.length; index++ ) {
      _cells.index( index ).highlighted = (_cells.index( index ).row == 0);
    }
    update_layout();
  }

  //-------------------------------------------------------------
  // Creates a deep copy of an existing table.
  public NodeTable.copy( MindMap map, NodeTable table ) {
    _map         = map;
    rows         = table.rows;
    columns      = table.columns;
    _cells       = new Array<NodeTableCell>();
    for( int index=0; index<table._cells.length; index++ ) {
      append_cell( new NodeTableCell.copy( map, table._cells.index( index ) ) );
    }
    update_layout();
  }

  //-------------------------------------------------------------
  // Loads a table from its native XML representation.
  public NodeTable.from_xml( MindMap map, Xml.Node* node ) {
    _map = map;
    string? row_count = node->get_prop( "rows" );
    string? column_count = node->get_prop( "columns" );
    rows    = (row_count == null) ? 1 : int.parse( row_count );
    columns = (column_count == null) ? 1 : int.parse( column_count );
    var limited_rows = rows;
    var limited_columns = columns;
    var truncated = NodeTableTextParser.limit_dimensions( ref limited_rows, ref limited_columns );
    rows = limited_rows;
    columns = limited_columns;
    _cells  = new Array<NodeTableCell>();
    for( Xml.Node* item = node->children; item != null; item = item->next ) {
      if( (item->type != Xml.ElementType.ELEMENT_NODE) || (item->name != "cell") ) continue;
      string? row_value      = item->get_prop( "row" );
      string? column_value   = item->get_prop( "column" );
      string? row_span_value = item->get_prop( "rowspan" );
      string? col_span_value = item->get_prop( "colspan" );
      string? text_value     = item->get_prop( "text" );
      var row      = (row_value == null) ? 0 : int.parse( row_value );
      var column   = (column_value == null) ? 0 : int.parse( column_value );
      var row_span = (row_span_value == null) ? 1 : int.parse( row_span_value );
      var col_span = (col_span_value == null) ? 1 : int.parse( col_span_value );
      if( (row < 0) || (column < 0) || (row >= rows) || (column >= columns) ) continue;
      row_span = int.min( int.max( row_span, 1 ), rows - row );
      col_span = int.min( int.max( col_span, 1 ), columns - column );
      if( !region_is_empty( row, column, row_span, col_span ) ) continue;
      var cell = new NodeTableCell( map, row, column, text_value ?? "", row_span, col_span );
      switch( item->get_prop( "align" ) ) {
        case "center" :  cell.set_text_alignment( Pango.Alignment.CENTER );  break;
        case "right"  :  cell.set_text_alignment( Pango.Alignment.RIGHT );   break;
        default       :  cell.set_text_alignment( Pango.Alignment.LEFT );    break;
      }
      string? highlighted = item->get_prop( "highlighted" );
      cell.highlighted = (highlighted == null) ? (row == 0) : (highlighted == "true");
      cell.set_format( NodeTableFormat.BOLD,          item->get_prop( "bold" ) == "true" );
      cell.set_format( NodeTableFormat.ITALIC,        item->get_prop( "italic" ) == "true" );
      cell.set_format( NodeTableFormat.UNDERLINE,     item->get_prop( "underline" ) == "true" );
      cell.set_format( NodeTableFormat.STRIKETHROUGH, item->get_prop( "strikethrough" ) == "true" );
      append_cell( cell );
    }
    fill_empty_cells();
    update_layout();
    if( truncated ) notify_truncated( map );
  }

  //-------------------------------------------------------------
  // Performs search of the table for a cell that matches the given pattern.
  // If a match occurs, return the string; otherwise, returns null.
  public string? get_match_string( string pattern ) {
    for( int i=0; i<_cells.length; i++ ) {
      var cell = _cells.index( i );
      var str  = Utils.match_string( pattern, cell.text );
      if( str.length > 0 ) {
        return( str );
      }
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Creates a table from tab-separated text.
  public static NodeTable from_tsv( MindMap map, string source ) {
    var grid = NodeTableTextParser.from_tsv( source );
    var table = new NodeTable( map, grid.row_count, grid.column_count );
    for( int row=0; row<table.rows; row++ ) {
      for( int column=0; column<table.columns; column++ ) {
        table.set_text( row, column, grid.get_value( row, column ) );
      }
    }
    table.update_layout();
    if( grid.truncated ) notify_truncated( map );
    return( table );
  }

  //-------------------------------------------------------------
  // Creates a table from exported Markdown rows.
  public static NodeTable? from_markdown( MindMap map, Array<string> source ) {
    var grid = NodeTableTextParser.from_markdown( source );
    if( grid == null ) return( null );
    var table = new NodeTable( map, grid.row_count, grid.column_count );
    for( int row=0; row<table.rows; row++ ) {
      for( int column=0; column<table.columns; column++ ) {
        table.set_text( row, column, grid.get_value( row, column ) );
      }
    }
    table.update_layout();
    if( grid.truncated ) notify_truncated( map );
    return( table );
  }

  //-------------------------------------------------------------
  // Notifies the user when imported table data exceeds safe limits.
  private static void notify_truncated( MindMap map ) {
    map.win.notification(
      _( "Table Truncated" ),
      _( "Tables are limited to %d rows, %d columns, and %d cells." ).printf(
        NodeTableTextParser.MAX_ROWS,
        NodeTableTextParser.MAX_COLUMNS,
        NodeTableTextParser.MAX_CELLS
      ),
      NotificationPriority.HIGH
    );
  }

  //-------------------------------------------------------------
  // Returns true if no existing cell intersects the given region.
  private bool region_is_empty( int row, int column, int row_span, int col_span ) {
    var last_row = row + row_span - 1;
    var last_column = column + col_span - 1;
    for( int index=0; index<_cells.length; index++ ) {
      if( _cells.index( index ).intersects( row, column, last_row, last_column ) ) return( false );
    }
    return( true );
  }

  //-------------------------------------------------------------
  // Adds individual cells for every uncovered grid position.
  private void fill_empty_cells() {
    for( int row=0; row<rows; row++ ) {
      for( int column=0; column<columns; column++ ) {
        if( cell_at( row, column ) == null ) {
          append_cell( new NodeTableCell( _map, row, column ) );
        }
      }
    }
  }

  //-------------------------------------------------------------
  // Returns the rendered cells in this table.
  public Array<NodeTableCell> cells() {
    return( _cells );
  }

  //-------------------------------------------------------------
  // Returns the cells through their display-independent base type.
  private Array<NodeTableRegion> regions() {
    var regions = new Array<NodeTableRegion>();
    for( int index=0; index<_cells.length; index++ ) {
      regions.append_val( _cells.index( index ) );
    }
    return( regions );
  }

  //-------------------------------------------------------------
  // Returns the cell covering the requested grid position.
  public NodeTableCell? cell_at( int row, int column ) {
    for( int index=0; index<_cells.length; index++ ) {
      var cell = _cells.index( index );
      if( cell.covers( row, column ) ) return( cell );
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Sets the text of the cell covering the requested position.
  public void set_text( int row, int column, string text ) {
    var cell = cell_at( row, column );
    if( cell != null ) cell.text = text;
  }

  //-------------------------------------------------------------
  // Applies a font to every rendered cell.
  public void set_font( string? family, int size ) {
    for( int index=0; index<_cells.length; index++ ) {
      _cells.index( index ).set_font( family, size );
    }
    update_layout();
  }

  //-------------------------------------------------------------
  // Returns the total width of a column span.
  private double span_width( int column, int span ) {
    double value = 0.0;
    for( int index=column; index<(column + span); index++ ) value += _column_widths[index];
    return( value );
  }

  //-------------------------------------------------------------
  // Returns the total height of a row span.
  private double span_height( int row, int span ) {
    double value = 0.0;
    for( int index=row; index<(row + span); index++ ) value += _row_heights[index];
    return( value );
  }

  //-------------------------------------------------------------
  // Grows the columns needed to fit a cell's natural width.
  private void grow_columns( NodeTableCell cell, double required_width ) {
    var current_width = span_width( cell.column, cell.col_span );
    if( current_width >= required_width ) return;
    var increment = (required_width - current_width) / cell.col_span;
    for( int column=cell.column; column<(cell.column + cell.col_span); column++ ) {
      _column_widths[column] += increment;
    }
  }

  //-------------------------------------------------------------
  // Grows the rows needed to fit a cell's natural height.
  private void grow_rows( NodeTableCell cell, double required_height ) {
    var current_height = span_height( cell.row, cell.row_span );
    if( current_height >= required_height ) return;
    var increment = (required_height - current_height) / cell.row_span;
    for( int row=cell.row; row<(cell.row + cell.row_span); row++ ) {
      _row_heights[row] += increment;
    }
  }

  //-------------------------------------------------------------
  // Recalculates all row, column, and table dimensions.
  public void update_layout() {
    _column_widths = new double[columns];
    _row_heights   = new double[rows];
    for( int column=0; column<columns; column++ ) _column_widths[column] = MIN_COLUMN_WIDTH;
    for( int row=0; row<rows; row++ ) _row_heights[row] = MIN_ROW_HEIGHT;
    for( int index=0; index<_cells.length; index++ ) {
      var cell = _cells.index( index );
      cell.layout.set_width( -1 );
      cell.layout.set_text( cell.text, -1 );
      int text_width, text_height;
      cell.layout.get_size( out text_width, out text_height );
      var natural_width = (text_width / Pango.SCALE) + (CELL_PADDING * 2);
      grow_columns( cell, Math.fmin( natural_width, MAX_CELL_WIDTH * cell.col_span ) );
    }
    for( int index=0; index<_cells.length; index++ ) {
      var cell = _cells.index( index );
      var available_width = span_width( cell.column, cell.col_span ) - (CELL_PADDING * 2);
      cell.layout.set_width( (int)(available_width * Pango.SCALE) );
      int text_width, text_height;
      cell.layout.get_size( out text_width, out text_height );
      grow_rows( cell, (text_height / Pango.SCALE) + (CELL_PADDING * 2) );
    }
    width = 0.0;
    height = 0.0;
    for( int column=0; column<columns; column++ ) width += _column_widths[column];
    for( int row=0; row<rows; row++ ) height += _row_heights[row];
  }

  //-------------------------------------------------------------
  // Merges a rectangular selection, expanding across merged cells.
  public bool merge( int first_row, int first_column, int last_row, int last_column ) {
    var selected_first_row = int.min( first_row, last_row );
    var selected_first_column = int.min( first_column, last_column );
    var selected_last_row = int.max( first_row, last_row );
    var selected_last_column = int.max( first_column, last_column );
    first_row    = int.max( 0, selected_first_row );
    first_column = int.max( 0, selected_first_column );
    last_row     = int.min( rows - 1, selected_last_row );
    last_column  = int.min( columns - 1, selected_last_column );
    var table_regions = regions();
    NodeTableTopology.expand_selection(
      table_regions, ref first_row, ref first_column, ref last_row, ref last_column
    );
    if( (first_row == last_row) && (first_column == last_column) ) return( false );
    var merged_text = NodeTableTopology.merge_text(
      table_regions, first_row, first_column, last_row, last_column
    );
    var style_cell = cell_at( first_row, first_column );
    for( int index=(int)_cells.length - 1; index>=0; index-- ) {
      var cell = _cells.index( index );
      if( cell.contained_by( first_row, first_column, last_row, last_column ) ) {
        _cells.remove_index( index );
      }
    }
    var merged_cell = new NodeTableCell(
      _map, first_row, first_column, merged_text,
      (last_row - first_row) + 1, (last_column - first_column) + 1
    );
    if( style_cell != null ) merged_cell.copy_style( style_cell );
    append_cell( merged_cell );
    update_layout();
    return( true );
  }

  //-------------------------------------------------------------
  // Splits the merged cell covering the requested position.
  public bool split( int row, int column ) {
    var cell = cell_at( row, column );
    if( (cell == null) || ((cell.row_span == 1) && (cell.col_span == 1)) ) return( false );
    for( int index=0; index<_cells.length; index++ ) {
      if( _cells.index( index ) == cell ) {
        _cells.remove_index( index );
        break;
      }
    }
    for( int target_row=cell.row; target_row<(cell.row + cell.row_span); target_row++ ) {
      for( int target_column=cell.column; target_column<(cell.column + cell.col_span); target_column++ ) {
        var text = ((target_row == cell.row) && (target_column == cell.column)) ? cell.text : "";
        var split_cell = new NodeTableCell( _map, target_row, target_column, text );
        split_cell.copy_style( cell );
        append_cell( split_cell );
      }
    }
    update_layout();
    return( true );
  }

  //-------------------------------------------------------------
  // Appends a row when the table size limit allows it.
  public bool append_row() {
    return( insert_row( rows ) );
  }

  //-------------------------------------------------------------
  // Inserts a row when the table size limit allows it.
  public bool insert_row( int row ) {
    if( (rows >= NodeTableTextParser.MAX_ROWS) ||
        (((rows + 1) * columns) > NodeTableTextParser.MAX_CELLS) ) return( false );
    row = int.min( int.max( row, 0 ), rows );
    for( int index=0; index<_cells.length; index++ ) {
      NodeTableTopology.insert_row( _cells.index( index ), row );
    }
    rows++;
    fill_empty_cells();
    update_layout();
    return( true );
  }

  //-------------------------------------------------------------
  // Appends a column when the table size limit allows it.
  public bool append_column() {
    return( insert_column( columns ) );
  }

  //-------------------------------------------------------------
  // Inserts a column when the table size limit allows it.
  public bool insert_column( int column ) {
    if( (columns >= NodeTableTextParser.MAX_COLUMNS) ||
        ((rows * (columns + 1)) > NodeTableTextParser.MAX_CELLS) ) return( false );
    column = int.min( int.max( column, 0 ), columns );
    for( int index=0; index<_cells.length; index++ ) {
      NodeTableTopology.insert_column( _cells.index( index ), column );
    }
    columns++;
    fill_empty_cells();
    update_layout();
    return( true );
  }

  //-------------------------------------------------------------
  // Deletes the selected row range while preserving merged cells.
  public void delete_rows( int first_row, int last_row ) {
    var selected_first_row = int.min( first_row, last_row );
    var selected_last_row = int.max( first_row, last_row );
    first_row = int.min( rows - 1, int.max( 0, selected_first_row ) );
    last_row = int.min( rows - 1, int.max( 0, selected_last_row ) );
    var count = (last_row - first_row) + 1;
    if( count >= rows ) {
      _cells.remove_range( 0, _cells.length );
      rows = 1;
      fill_empty_cells();
      update_layout();
      return;
    }
    for( int index=(int)_cells.length - 1; index>=0; index-- ) {
      if( !NodeTableTopology.delete_rows( _cells.index( index ), first_row, last_row ) ) {
        _cells.remove_index( index );
      }
    }
    rows -= count;
    fill_empty_cells();
    update_layout();
  }

  //-------------------------------------------------------------
  // Deletes the selected column range while preserving merged cells.
  public void delete_columns( int first_column, int last_column ) {
    var selected_first_column = int.min( first_column, last_column );
    var selected_last_column = int.max( first_column, last_column );
    first_column = int.min( columns - 1, int.max( 0, selected_first_column ) );
    last_column = int.min( columns - 1, int.max( 0, selected_last_column ) );
    var count = (last_column - first_column) + 1;
    if( count >= columns ) {
      _cells.remove_range( 0, _cells.length );
      columns = 1;
      fill_empty_cells();
      update_layout();
      return;
    }
    for( int index=(int)_cells.length - 1; index>=0; index-- ) {
      if( !NodeTableTopology.delete_columns( _cells.index( index ), first_column, last_column ) ) {
        _cells.remove_index( index );
      }
    }
    columns -= count;
    fill_empty_cells();
    update_layout();
  }

  //-------------------------------------------------------------
  // Clears the contents and formatting of selected cells.
  public void clear_cells( int first_row, int first_column, int last_row, int last_column ) {
    var selected_first_row = int.min( first_row, last_row );
    var selected_first_column = int.min( first_column, last_column );
    var selected_last_row = int.max( first_row, last_row );
    var selected_last_column = int.max( first_column, last_column );
    for( int index=0; index<_cells.length; index++ ) {
      var cell = _cells.index( index );
      if( cell.intersects( selected_first_row, selected_first_column,
                          selected_last_row, selected_last_column ) ) {
        cell.clear();
      }
    }
    update_layout();
  }

  //-------------------------------------------------------------
  // Returns the horizontal offset of a column.
  private double column_offset( int column ) {
    double offset = 0.0;
    for( int index=0; index<column; index++ ) offset += _column_widths[index];
    return( offset );
  }

  //-------------------------------------------------------------
  // Returns the vertical offset of a row.
  private double row_offset( int row ) {
    double offset = 0.0;
    for( int index=0; index<row; index++ ) offset += _row_heights[index];
    return( offset );
  }

  //-------------------------------------------------------------
  // Draws the table grid and all cell contents.
  public void draw( Cairo.Context context, double x, double y, RGBA foreground, double opacity ) {
    context.save();
    context.set_line_width( 1.0 );
    for( int index=0; index<_cells.length; index++ ) {
      var cell = _cells.index( index );
      var cell_x = x + column_offset( cell.column );
      var cell_y = y + row_offset( cell.row );
      var cell_width = span_width( cell.column, cell.col_span );
      var cell_height = span_height( cell.row, cell.row_span );
      if( cell.highlighted ) {
        Utils.set_context_color_with_alpha( context, foreground, opacity * 0.10 );
        context.rectangle( cell_x, cell_y, cell_width, cell_height );
        context.fill();
      }
      Utils.set_context_color_with_alpha( context, foreground, opacity * 0.65 );
      context.rectangle( cell_x, cell_y, cell_width, cell_height );
      context.stroke();
      cell.draw(
        context,
        cell_x + CELL_PADDING,
        cell_y + CELL_PADDING,
        foreground,
        opacity
      );
    }
    context.restore();
  }

  //-------------------------------------------------------------
  // Saves this table to the native XML document.
  public void save( Xml.Node* parent ) {
    Xml.Node* table = new Xml.Node( null, "nodetable" );
    table->new_prop( "rows", rows.to_string() );
    table->new_prop( "columns", columns.to_string() );
    for( int index=0; index<_cells.length; index++ ) {
      var cell = _cells.index( index );
      Xml.Node* item = new Xml.Node( null, "cell" );
      item->new_prop( "row", cell.row.to_string() );
      item->new_prop( "column", cell.column.to_string() );
      item->new_prop( "rowspan", cell.row_span.to_string() );
      item->new_prop( "colspan", cell.col_span.to_string() );
      item->new_prop( "text", cell.text );
      switch( cell.alignment ) {
        case Pango.Alignment.CENTER :  item->new_prop( "align", "center" );  break;
        case Pango.Alignment.RIGHT  :  item->new_prop( "align", "right" );   break;
        default                     :  item->new_prop( "align", "left" );    break;
      }
      item->new_prop( "highlighted", cell.highlighted.to_string() );
      if( cell.format_enabled( NodeTableFormat.BOLD ) ) {
        item->new_prop( "bold", "true" );
      }
      if( cell.format_enabled( NodeTableFormat.ITALIC ) ) {
        item->new_prop( "italic", "true" );
      }
      if( cell.format_enabled( NodeTableFormat.UNDERLINE ) ) {
        item->new_prop( "underline", "true" );
      }
      if( cell.format_enabled( NodeTableFormat.STRIKETHROUGH ) ) {
        item->new_prop( "strikethrough", "true" );
      }
      table->add_child( item );
    }
    parent->add_child( table );
  }

  //-------------------------------------------------------------
  // Exports this table as Markdown-compatible text.
  public string to_markdown() {
    var output = "";
    for( int row=0; row<rows; row++ ) {
      output += "|";
      for( int column=0; column<columns; column++ ) {
        var cell = cell_at( row, column );
        var text = ((cell != null) && (cell.row == row) && (cell.column == column)) ? cell.text : "";
        output += " " + text.replace( "|", "\\|" ).replace( "\n", "<br>" ) + " |";
      }
      output += "\n";
      if( row == 0 ) {
        output += "|";
        for( int column=0; column<columns; column++ ) {
          var cell = cell_at( row, column );
          switch( cell.alignment ) {
            case Pango.Alignment.LEFT   :  output += " :--- |";  break;
            case Pango.Alignment.CENTER :  output += " :---: |";  break;
            case Pango.Alignment.RIGHT  :  output += " ---: |";  break;
            default                     :  assert_not_reached();
          }
        }
        output += "\n";
      }
    }
    return( output.chomp() );
  }

}
