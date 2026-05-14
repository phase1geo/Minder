/*
* Copyright (c) 2020-2026 (https://github.com/phase1geo/Annotator)
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

public class SettingsUpdater {

  //-------------------------------------------------------------
  // Returns true if the settings need to be updated.
  private static bool needs_update( GLib.Settings settings ) {
    return( !settings.get_boolean( "internal-updated" ) );
  }

  //-------------------------------------------------------------
  // Returns the GLib.Settings for the old version of the settings
  private static GLib.Settings? get_old_settings( GLib.Settings new_settings ) {
    var schema_parts = new_settings.schema_id.split( "." );
    schema_parts[0] = "com";
    var old_schema_id = string.joinv( ".", schema_parts );
    if( SettingsSchemaSource.get_default().lookup( old_schema_id, true ) == null ) {
      return( null );
    }
    var old_settings  = new GLib.Settings( old_schema_id );
    return( old_settings );
  }

  //-------------------------------------------------------------
  // Copies the given setting from the old to the new for the given
  // key.
  private static void copy_setting( string key, GLib.Settings new_settings, GLib.Settings old_settings ) {
    var schema_key = new_settings.settings_schema.get_key( key );
    var value_type = schema_key.get_value_type();
    switch( value_type.dup_string() ) {
      case "b"     :  new_settings.set_boolean( key, old_settings.get_boolean( key ) );  break;
      case "s"     :  new_settings.set_string(  key, old_settings.get_string( key ) );   break;
      case "i"     :  new_settings.set_int(     key, old_settings.get_int( key ) );      break;
      case "d"     :  new_settings.set_double(  key, old_settings.get_double( key ) );   break;
      case "a{sv}" :  new_settings.set_value(   key, old_settings.get_value( key ) );    break;
      case "a(ss)" :  new_settings.set_value(   key, old_settings.get_value( key ) );    break;
      default      :  
        stdout.printf( "key: %s, value_type: %s (%d, %d)\n", key, value_type.dup_string(), (int)value_type, (int)VariantType.INT32 );
        assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Performs the settings copy from the old version.
  private static void update_settings( GLib.Settings new_settings ) {
    var old_settings = get_old_settings( new_settings ); 
    if( old_settings != null ) {
      foreach (var key in new_settings.settings_schema.list_keys()) {
        if( old_settings.settings_schema.has_key( key ) ) {
          copy_setting( key, new_settings, old_settings );
        }
      }
    }
    new_settings.set_boolean( "internal-updated", true );
  }

  //-------------------------------------------------------------
  // Checks to see if the gsettings value needs to be pulled from
  // the com.github version to this version.  If it does, performs
  // the copy.
  public static void update( GLib.Settings settings ) {
    if( needs_update( settings ) ) {
      update_settings( settings );
    }
  }

}
