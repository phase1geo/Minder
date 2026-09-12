/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License as
* published by the Free Software Foundation; either version 2 of
* the License, or (at your option) any later version.
*/

namespace MinderTest {

  public class LatexSpanParserTest : TestSuite {

    public LatexSpanParserTest() {
      this.add_test( "valid-source", test_valid_source );
      this.add_test( "invalid-source", test_invalid_source );
      this.add_test( "escaped-delimiters", test_escaped_delimiters );
      this.add_test( "position", test_position );
    }

    private void test_valid_source() {
      Assert.true( LatexSpanParser.is_latex_source( "before $$x_1$$ after" ) );
      Assert.true( LatexSpanParser.is_latex_source( "$$x$$ and $$\\frac{1}{2}$$" ) );
    }

    private void test_invalid_source() {
      Assert.false( LatexSpanParser.is_latex_source( "ordinary text" ) );
      Assert.false( LatexSpanParser.is_latex_source( "before $$x" ) );
      Assert.false( LatexSpanParser.is_latex_source( "before $$$$ after" ) );
      Assert.false( LatexSpanParser.is_latex_source( "$$x$$ and $$" ) );
    }

    private void test_escaped_delimiters() {
      Assert.false( LatexSpanParser.is_latex_source( "escaped \\$$ only" ) );
      Assert.true( LatexSpanParser.is_latex_source( "escaped \\$$ then $$x$$" ) );
      Assert.true( LatexSpanParser.is_latex_source( "two slashes \\\\$$x$$" ) );
      Assert.true( LatexSpanParser.is_latex_source( "$$x \\$$ y$$" ) );
    }

    private void test_position() {
      var source = "α before $$x_1$$ after";
      Assert.false( LatexSpanParser.is_latex_at( source, source.index_of( "before" ) ) );
      Assert.true( LatexSpanParser.is_latex_at( source, source.index_of( "$$" ) ) );
      Assert.true( LatexSpanParser.is_latex_at( source, source.index_of( "x_1" ) ) );
      Assert.false( LatexSpanParser.is_latex_at( source, source.last_index_of( "$$" ) ) );
      Assert.true( LatexSpanParser.is_latex_at( "pending $$x", 11 ) );
    }

  }

}
