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
*/

using Gdk;
using GLib;

//-------------------------------------------------------------
// Runs the optional local formula recognizer without blocking the UI.
public class FormulaRecognizer : Object {

  private const int COMMAND_TIMEOUT  = 30;
  private const int MAX_OUTPUT_BYTES = 32768;
  private static bool _busy          = false;

  //-------------------------------------------------------------
  // Finds either the explicitly configured recognizer or the default command.
  private static string? find_command() {
    var configured = Environment.get_variable( "MINDER_FORMULA_OCR" );
    if( (configured != null) && (configured.strip() != "") ) {
      if( configured.contains( "/" ) ) {
        return( FileUtils.test( configured, FileTest.IS_EXECUTABLE ) ? configured : null );
      }
      return( Environment.find_program_in_path( configured ) );
    }
    return( Environment.find_program_in_path( "formulaocr-offline" ) );
  }

  //-------------------------------------------------------------
  // Returns true when formula recognition is installed.
  public static bool available() {
    return( find_command() != null );
  }

  //-------------------------------------------------------------
  // Recognizes a single pixbuf and returns unwrapped LaTeX source.
  public static async string recognize( Pixbuf image ) throws Error {
    var command = find_command();
    if( command == null ) {
      throw new IOError.NOT_FOUND( _( "The offline formula recognizer is not installed" ) );
    }
    if( _busy ) {
      throw new IOError.BUSY( _( "Another formula is already being recognized" ) );
    }

    string? temp_dir  = null;
    string? image_path = null;
    _busy = true;
    try {
      temp_dir  = DirUtils.make_tmp( "minder-formula-ocr-XXXXXX" );
      image_path = GLib.Path.build_filename( temp_dir, "formula.png" );
      image.save( image_path, "png" );

      string[] argv = { command, image_path };
      var launcher = new SubprocessLauncher(
        SubprocessFlags.STDOUT_PIPE | SubprocessFlags.STDERR_PIPE
      );
      var process = launcher.spawnv( argv );
      string? stdout_buf = null;
      string? stderr_buf = null;
      var timed_out = false;
      var timeout_id = Timeout.add_seconds( COMMAND_TIMEOUT, () => {
        timed_out = true;
        process.force_exit();
        return( Source.REMOVE );
      });

      try {
        yield process.communicate_utf8_async( null, null, out stdout_buf, out stderr_buf );
      } finally {
        if( !timed_out ) {
          Source.remove( timeout_id );
        }
      }

      if( timed_out ) {
        throw new IOError.TIMED_OUT( _( "Offline formula recognition timed out" ) );
      }
      if( !process.get_successful() ) {
        throw new IOError.FAILED(
          compact_error( stderr_buf ?? stdout_buf ?? _( "Offline formula recognition failed" ) )
        );
      }

      var formula = (stdout_buf ?? "").strip();
      if( formula == "" ) {
        throw new IOError.INVALID_DATA( _( "The formula recognizer returned no LaTeX" ) );
      }
      if( formula.length > MAX_OUTPUT_BYTES ) {
        throw new IOError.INVALID_DATA( _( "The recognized formula is too long" ) );
      }
      return( formula );
    } finally {
      _busy = false;
      if( image_path != null ) {
        FileUtils.remove( image_path );
      }
      if( temp_dir != null ) {
        DirUtils.remove( temp_dir );
      }
    }
  }

  //-------------------------------------------------------------
  // Keeps process errors readable in notifications and logs.
  private static string compact_error( string message ) {
    var stripped = message.strip();
    var chars = stripped.char_count();
    if( chars <= 500 ) {
      return( stripped );
    }
    return( stripped.substring( stripped.index_of_nth_char( chars - 500 ) ) );
  }

}
