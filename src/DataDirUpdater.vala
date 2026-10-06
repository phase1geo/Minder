/*
* Copyright (c) 2025-2026 (https://github.com/phase1geo/Minder)
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

public class DataDirUpdater {

  //-------------------------------------------------------------
  // Performs an update of the data directory, if necessary.  This
  // needs to be called prior to calling the SettingsUpdater.
  public static void update( GLib.Settings settings ) {

    // Copy over the tab state file and unsaved files
    if( SettingsUpdater.needs_update( settings ) ) {
      move_minder_files();
    }

  }

  //-------------------------------------------------------------
  // Returns the directory containing the unsaved Minder files
  // in older versions of Minder.
  private static string old_data_dir() {
    return( GLib.Path.build_filename( Environment.get_user_data_dir(), "minder" ) );
  }

  //-------------------------------------------------------------
  // Returns the directory containing the unsaved Minder files in
  // this version of Minder.
  private static string new_data_dir() {
    return( GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "unsaved" ) );
  }

  //-------------------------------------------------------------
  // Moves all of the Minder file from the old location to the new.
  private static void move_minder_files() {

    if( Utils.create_dir( new_data_dir() ) ) {

      try {

        var dir = Dir.open( old_data_dir(), 0 );
        string? name = null;

        while ((name = dir.read_name ()) != null) {
          if( name.has_suffix( ".minder" ) ) {
            move_file( name );
          }
        }

      } catch( FileError err ) {
        stderr.printf( err.message );
      }

    }

  }

  //-------------------------------------------------------------
  // Copies the given file (basename) from the original directory to
  // the new directory.
  private static bool move_file( string basename ) {

    var ofile = File.new_for_path( Path.build_filename( old_data_dir(), basename ) );
    var nfile = File.new_for_path( Path.build_filename( new_data_dir(), basename ) );

    try {
      ofile.move( nfile, FileCopyFlags.OVERWRITE );
    } catch( Error e ) {
      stdout.printf( "Error: %s\n", e.message );
      return( false );
    }

    return( true );

  }

}
