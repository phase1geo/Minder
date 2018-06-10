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
     * The {@code Assert} class contains various helper functions for testing assertions
     *
     * @since 1.0.0
     */
    public class Assert {

        public static void string_compare (string? expected, string? actual, string compare = "==") {
            switch (compare) {
                case "!=":
                    if (expected == actual) {
                        warning ("Expected '" + expected + "', got '" + actual +"'");
                        assert (expected != actual);
                    }
                    break;
                case "==":
                default:
                    if (expected != actual) {
                        warning ("Expected '" + expected + "' to not equal '" + actual +"'");
                        assert (expected == actual);
                    }
                    break;
            }
            
        }

        public static void bool_compare (bool? expected, bool? actual, string compare = "==") {
            switch (compare) {
                case "!=":
                    if (expected == actual) {
                        warning ("Expected '" + expected.to_string () + "', got '" + actual.to_string () +"'");
                        assert (expected != actual);
                    }
                    break;
                case "==":
                default:
                    if (expected != actual) {
                        warning ("Expected '" + expected.to_string () + "' to not equal '" + actual.to_string () +"'");
                        assert (expected == actual);
                    }
                    break;
            }
        }

        public static void int_compare (int? expected, int? actual, string compare = "==") {
            switch (compare) {
                case ">":
                    if (expected <= actual) {
                        warning (expected.to_string () + " is less than or equal to " + actual.to_string ());
                        assert (expected <= actual);
                    }
                    break;
                case ">=":
                    if (expected < actual) {
                        warning (expected.to_string () + " is less than " + actual.to_string ());
                        assert (expected < actual);
                    }
                    break;
                case "<":
                    if (expected >= actual) {
                        warning (expected.to_string () + " is greater than or equal to " + actual.to_string ());
                        assert (expected >= actual);
                    }
                    break;
                case "<=":
                    if (expected > actual) {
                        warning (expected.to_string () + " is greater than " + actual.to_string ());
                        assert (expected > actual);
                    }
                    break;
                case "!=":
                    if (expected == actual) {
                        warning (expected.to_string () + " is equal to " + actual.to_string ());
                        assert (expected != actual);
                    }
                    break;
                case "==":
                default:
                    if (expected != actual) {
                        warning (expected.to_string () + " is not equal to " + actual.to_string ());
                        assert (expected == actual);
                    }
                    break;
            }
        }

        public static void float_compare (float? expected, float? actual, string compare = "==") {
            switch (compare) {
                case ">":
                    if (expected <= actual) {
                        warning (expected.to_string () + " is less than or equal to " + actual.to_string ());
                        assert (expected <= actual);
                    }
                    break;
                case ">=":
                    if (expected < actual) {
                        warning (expected.to_string () + " is less than " + actual.to_string ());
                        assert (expected < actual);
                    }
                    break;
                case "<":
                    if (expected >= actual) {
                        warning (expected.to_string () + " is greater than or equal to " + actual.to_string ());
                        assert (expected >= actual);
                    }
                    break;
                case "<=":
                    if (expected > actual) {
                        warning (expected.to_string () + " is greater than " + actual.to_string ());
                        assert (expected > actual);
                    }
                    break;
                case "!=":
                    if (expected == actual) {
                        warning (expected.to_string () + " is equal to " + actual.to_string ());
                        assert (expected != actual);
                    }
                    break;
                case "==":
                default:
                    if (expected != actual) {
                        warning (expected.to_string () + " is not equal to " + actual.to_string ());
                        assert (expected == actual);
                    }
                    break;
            }
        }

        public static void double_compare (double? expected, double? actual, string compare = "==") {
            switch (compare) {
                case ">":
                    if (expected <= actual) {
                        warning (expected.to_string () + " is less than or equal to " + actual.to_string ());
                        assert (expected <= actual);
                    }
                    break;
                case ">=":
                    if (expected < actual) {
                        warning (expected.to_string () + " is less than " + actual.to_string ());
                        assert (expected < actual);
                    }
                    break;
                case "<":
                    if (expected >= actual) {
                        warning (expected.to_string () + " is greater than or equal to " + actual.to_string ());
                        assert (expected >= actual);
                    }
                    break;
                case "<=":
                    if (expected > actual) {
                        warning (expected.to_string () + " is greater than " + actual.to_string ());
                        assert (expected > actual);
                    }
                    break;
                case "!=":
                    if (expected == actual) {
                        warning (expected.to_string () + " is equal to " + actual.to_string ());
                        assert (expected != actual);
                    }
                    break;
                case "==":
                default:
                    if (expected != actual) {
                        warning (expected.to_string () + " is not equal to " + actual.to_string ());
                        assert (expected == actual);
                    }
                    break;
            }
        }

        public static void true (bool? expected) {
            if (expected != true) {
                warning ("Expected '" + expected.to_string () + "' to be true");
            }

            assert (expected == true);
        }

        public static void false (bool? expected) {
            if (expected != false) {
                warning ("Expected '" + expected.to_string () + "' to be false");
            }

            assert (expected == false);
        }
    }
}
