/*
 * This file is part of GNOME Pomodoro
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Kamil Prusko <kamilprusko@gmail.com>
 *
 */

namespace MinderTest {

  public class ExampleTest : TestSuite {

    private int enable_count;
    private int disable_count;

    public ExampleTest() {
      this.add_test( "example1", test_example1 );
      this.add_test( "example2", test_example2 );
      this.add_test( "example3", test_example3 );
    }

    public override void setup() {
      // ADD SETUP CODE HERE
    }

    public override void teardown() {
      // ADD TEARDOWN CODE HERE
    }

    public void test_example1() {
      Assert.true( true );
    }

    public void test_example2() {
      Assert.false( false );
    }

    public void test_example3() {
      Assert.string_compare( "foobar", "barfoo", "!=" );
    }

  }

}
