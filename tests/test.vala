/*
* Copyright (C) 2018  Trevor Williams <phase1geo@icloud.com>
* 
* This program is free software: you can redistribute it and/or modify
* it under the terms of the Lesser GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* Lesser GNU General Public License for more details.
* 
* You should have received a copy of the Lesser GNU General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

namespace App.Tests {

    /**
     * The {@code Testing} class is entry point for unit and UI testing for the application
     *
     * @since 1.0.0
     */
    public class Testing {
        public Testing (string[] args) {
            Test.init (ref args);

            // Example test
            Test.add_data_func ("/init", () => {
                Assert.string_compare ("Test", "Test");
                Assert.bool_compare (true, true);
                Assert.true (true);
                Assert.false (false);
                Assert.int_compare (5, 5);
                Assert.float_compare (5.2f, 6.4f, "!=");
                Assert.double_compare (8.8, 8.8, "<=");
            });
        }

        public void run () {
            Test.run ();
        }
    }
}
