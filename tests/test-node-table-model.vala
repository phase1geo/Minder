/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version.
*/

namespace MinderTest {

  public class NodeTableModelTest : TestSuite {

    public NodeTableModelTest() {
      this.add_test( "merge-order", test_merge_order );
      this.add_test( "expand-selection", test_expand_selection );
      this.add_test( "edit-merged-cell", test_edit_merged_cell );
      this.add_test( "markdown", test_markdown );
      this.add_test( "tsv-trailing-cells", test_tsv_trailing_cells );
      this.add_test( "paste-limits", test_paste_limits );
      this.add_test( "vertical-alignment", test_vertical_alignment );
      this.add_test( "cell-highlight", test_cell_highlight );
      this.add_test( "markdown-row", test_markdown_row );
    }

    private void test_merge_order() {
      var regions = new GLib.Array<NodeTableRegion>();
      regions.append_val( new NodeTableRegion( 1, 1, "D" ) );
      regions.append_val( new NodeTableRegion( 1, 0, "C" ) );
      regions.append_val( new NodeTableRegion( 0, 1, "B" ) );
      regions.append_val( new NodeTableRegion( 0, 0, "A" ) );
      Assert.string_compare( "A B C D", NodeTableTopology.merge_text( regions, 0, 0, 1, 1 ) );
    }

    private void test_expand_selection() {
      var regions = new GLib.Array<NodeTableRegion>();
      regions.append_val( new NodeTableRegion( 0, 0, "A", 1, 2 ) );
      regions.append_val( new NodeTableRegion( 1, 0, "B", 1, 2 ) );
      var first_row = 0;
      var first_column = 1;
      var last_row = 1;
      var last_column = 1;
      NodeTableTopology.expand_selection(
        regions, ref first_row, ref first_column, ref last_row, ref last_column
      );
      Assert.int_compare( 0, first_row );
      Assert.int_compare( 0, first_column );
      Assert.int_compare( 1, last_row );
      Assert.int_compare( 1, last_column );
    }

    private void test_edit_merged_cell() {
      var region = new NodeTableRegion( 0, 0, "merged", 2, 2 );
      NodeTableTopology.insert_row( region, 1 );
      NodeTableTopology.insert_column( region, 1 );
      Assert.int_compare( 3, region.row_span );
      Assert.int_compare( 3, region.col_span );
      Assert.true( NodeTableTopology.delete_rows( region, 1, 1 ) );
      Assert.true( NodeTableTopology.delete_columns( region, 1, 1 ) );
      Assert.int_compare( 2, region.row_span );
      Assert.int_compare( 2, region.col_span );
      Assert.false( NodeTableTopology.delete_rows( region, 0, 1 ) );
    }

    private void test_markdown() {
      var source = new GLib.Array<string>();
      source.append_val( "| A | B\\|pipe |  |" );
      source.append_val( "| --- | :---: | ---: |" );
      source.append_val( "| C<br>line | D | E |" );
      var grid = NodeTableTextParser.from_markdown( source );
      Assert.true( grid != null );
      Assert.int_compare( 2, grid.row_count );
      Assert.int_compare( 3, grid.column_count );
      Assert.string_compare( "B|pipe", grid.get( 0, 1 ) );
      Assert.string_compare( "", grid.get( 0, 2 ) );
      Assert.string_compare( "C\nline", grid.get( 1, 0 ) );
    }

    private void test_tsv_trailing_cells() {
      var grid = NodeTableTextParser.from_tsv( "a\t\t\nb\tc\t\n" );
      Assert.int_compare( 2, grid.row_count );
      Assert.int_compare( 3, grid.column_count );
      Assert.string_compare( "a", grid.get( 0, 0 ) );
      Assert.string_compare( "", grid.get( 0, 2 ) );
      Assert.string_compare( "", grid.get( 1, 2 ) );
    }

    private void test_paste_limits() {
      var source = new GLib.StringBuilder();
      for( int row=0; row<1000; row++ ) {
        if( row > 0 ) source.append_c( '\n' );
        for( int column=0; column<20; column++ ) {
          if( column > 0 ) source.append_c( '\t' );
          source.append( "x" );
        }
      }
      var grid = NodeTableTextParser.from_tsv( source.str );
      Assert.int_compare( 50, grid.row_count );
      Assert.int_compare( 20, grid.column_count );
      Assert.true( grid.truncated );
    }

    private void test_vertical_alignment() {
      var region = new NodeTableRegion( 0, 0 );
      Assert.string_compare( "top", region.vertical_alignment.to_string() );
      region.vertical_alignment = NodeTableVerticalAlignment.parse( "middle" );
      Assert.string_compare( "middle", region.vertical_alignment.to_string() );
      region.vertical_alignment = NodeTableVerticalAlignment.parse( "bottom" );
      Assert.string_compare( "bottom", region.vertical_alignment.to_string() );
      region.vertical_alignment = NodeTableVerticalAlignment.parse( "invalid" );
      Assert.string_compare( "top", region.vertical_alignment.to_string() );
      Assert.double_compare( 0.0, NodeTableVerticalAlignment.TOP.offset( 60.0, 20.0 ) );
      Assert.double_compare( 20.0, NodeTableVerticalAlignment.MIDDLE.offset( 60.0, 20.0 ) );
      Assert.double_compare( 40.0, NodeTableVerticalAlignment.BOTTOM.offset( 60.0, 20.0 ) );
      Assert.double_compare( 0.0, NodeTableVerticalAlignment.BOTTOM.offset( 20.0, 60.0 ) );
    }

    private void test_cell_highlight() {
      var region = new NodeTableRegion( 0, 0 );
      Assert.false( region.highlighted );
      region.highlighted = true;
      Assert.true( region.highlighted );
    }

    private void test_markdown_row() {
      Assert.true( NodeTableTextParser.is_markdown_row( "  | A | B |  " ) );
      Assert.false( NodeTableTextParser.is_markdown_row( "not a table" ) );
      Assert.false( NodeTableTextParser.is_markdown_row( "| missing end" ) );
    }

  }

}
