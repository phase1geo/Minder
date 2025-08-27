/*
 * Copyright (c) 2014 gnome-pomodoro contributors
 *
 * This code is partly borrowed from libgee's test suite,
 * at https://git.gnome.org/browse/libgee and from gnome-break-timer
 * https://git.gnome.org/browse/gnome-break-timer
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
 */

using GLib;

namespace MinderTest {

  public delegate void TestCaseFunc();

  public GLib.SettingsSchemaSource schema_source;

  private class TestSuiteAdaptor {

    public string name;

    private TestCaseFunc func;
    private TestSuite    test_suite;

    public TestSuiteAdaptor( string name, owned TestCaseFunc test_case_func, TestSuite test_suite ) {
      this.name = name;
      this.func = (owned) test_case_func;
      this.test_suite = test_suite;
    }

    public void setup( void* fixture ) {
      this.test_suite.setup();
    }

    public void run( void* fixture ) {
      this.func();
    }

    public void teardown( void* fixture ) {
      this.test_suite.teardown();
    }

    public GLib.TestCase get_g_test_case () {
      return new GLib.TestCase( this.name, this.setup, this.run, this.teardown );
    }
  }

  public abstract class TestSuite : GLib.Object {

    private GLib.TestSuite     g_test_suite;
    private TestSuiteAdaptor[] adaptors = new TestSuiteAdaptor[0];

    construct {
      this.g_test_suite = new GLib.TestSuite( this.get_name() );
    }

    public string get_name() {
      return this.get_type().name();
    }

    public GLib.TestSuite get_g_test_suite() {
      return this.g_test_suite;
    }

    public void add_test( string name, owned TestCaseFunc func ) {
      var adaptor = new TestSuiteAdaptor( name, (owned) func, this );
      this.adaptors += adaptor;
      this.g_test_suite.add( adaptor.get_g_test_case() );
    }

    public virtual void setup() {}

    public virtual void teardown() {}

  }

  public class TestRunner : GLib.Object {

    private GLib.TestSuite root_suite;
    private GLib.File      tmp_dir;
    private const string   SCHEMA_FILE_NAME = "com.github.phase1geo.minder.gschema.xml";

    public TestRunner( GLib.TestSuite? root_suite = null ) {
      if( root_suite == null ) {
        this.root_suite = GLib.TestSuite.get_root();
      } else {
        this.root_suite = root_suite;
      }
    }

    public void add( TestSuite test_suite ) {
      this.root_suite.add_suite( test_suite.get_g_test_suite() );
    }

    private void setup_settings () {

      Environment.set_variable( "GSETTINGS_BACKEND", "memory", true );
      Environment.set_variable( "GSETTINGS_SCHEMA_DIR", this.tmp_dir.get_path (), true );

      // prepare temporary settings
      var target_schema_path = this.tmp_dir.get_path();

      try {
        var top_builddir       = TestRunner.get_top_builddir();
        var source_schema_file = GLib.File.new_for_path( Path.build_filename( top_builddir, "data", SCHEMA_FILE_NAME ) );
        var target_schema_file = GLib.File.new_for_path( Path.build_filename( target_schema_path, SCHEMA_FILE_NAME ) );
        source_schema_file.copy( target_schema_file, GLib.FileCopyFlags.OVERWRITE );
      } catch( GLib.Error error ) {
        GLib.error( "Error copying schema file: %s", error.message );
      }

      var compile_schemas_result = 0;
      try {
        GLib.Process.spawn_command_line_sync(
          "glib-compile-schemas %s".printf (target_schema_path),
          null,
          null,
          out compile_schemas_result
        );
      } catch( GLib.SpawnError error ) {
        GLib.error( error.message );
      }

      if( compile_schemas_result != 0 ) {
        GLib.error( "Could not compile schemas '%s'.", target_schema_path );
      }

    }

    public virtual void global_setup () {

      Environment.set_variable( "LANGUAGE", "C", true );

      try {
        this.tmp_dir = GLib.File.new_for_path( GLib.DirUtils.make_tmp( "minder-test-XXXXXX" ) );
      } catch( GLib.Error error ) {
        GLib.error( "Error creating temporary directory for test files: %s".printf( error.message ) );
      }

      this.setup_settings();

    }

    public virtual void global_teardown () {

      if( this.tmp_dir != null ) {
        var tmp_dir_path = this.tmp_dir.get_path();
        var delete_tmp_result = 0;

        try {
          GLib.Process.spawn_command_line_sync(
            "rm -rf %s".printf (tmp_dir_path),
            null,
            null,
            out delete_tmp_result
          );
        } catch( GLib.SpawnError error ) {
          GLib.warning( error.message );
        }

        if( delete_tmp_result != 0 ) {
          GLib.warning( "Could not delete temporary directory '%s'", tmp_dir_path );
        }
      }

    }

    public int run() {

      global_setup();

      var exit_status = GLib.Test.run();

      global_teardown();

      return( exit_status );

    }

    private static string get_top_builddir () {

      var builddir = Environment.get_variable( "top_builddir" );

      if( builddir == null ) {
        var dir = GLib.File.new_for_path( Environment.get_current_dir() );
        while( dir != null ) {
          var schema_path = GLib.Path.build_filename( dir.get_path(), "data", SCHEMA_FILE_NAME );

          if( GLib.FileUtils.test( schema_path, GLib.FileTest.IS_REGULAR ) ) {
            builddir = dir.get_path();
            break;
          }

          dir = dir.get_parent();
        }
      }

      if (builddir == null) {
        builddir = "..";  /* fallback to parent dir, test should be ran
                             from 'tests' dir */
      }

      return builddir;
    }

  }

}


public static int main (string[] args) {

  var exit_status = 0;

  Test.init( ref args );

  var tests = new MinderTest.TestRunner ();
  tests.add( new MinderTest.ExampleTest() );

  exit_status = tests.run();

  return( exit_status );

}
