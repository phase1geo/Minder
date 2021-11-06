set shortcuts_txt  [file join src shortcuts.txt]
set shortcuts_vala [file join src Shortcuts.vala]

if {[catch { open $shortcuts_txt r } rc]} {
  puts "ERROR:  Unable to read $shortcuts_txt file: $rc"
  exit 1
}

set contents [read $rc]
close $rc

set lnum 1
foreach line [split $contents \n] {
  set cmds [list]
  if {[regexp {^([a-zA-Z-]+)\s+(.*)$} $line -> key cmd]} {
    if {[info exists shortcuts($key)]} {
      puts "ERROR:  Found a duplicate shortcut ($key) on line $lnum"
      # exit 1
    }
    set shortcuts($key) $cmd
  }
  incr lnum
}

# Extrapolate the modifiers in the key and command
foreach {modifier pos} [list CONTROL 0 SHIFT 1 ALT 2] {
  foreach {key cmd} [array get shortcuts] {
    if {[string first $modifier $cmd] != -1} {
      if {[string first $modifier $key] != -1} {
        set shortcuts($key) [string map [list $modifier true] $cmd]
      } else {
        set shortcuts($key) [string map [list $modifier false] $cmd]
        set key_comps [split $key -]
        if {[llength $key_comps] <= $pos} {
          set pos [expr [llength $key_comps] - 1]
        }
        set key [join [linsert $key_comps $pos $modifier] -]
        if {[info exists shortcuts($key)]} {
          puts "ERROR:  Found a duplicate shortcut ($key)"
          # exit 1
        }
        set shortcuts($key) [string map [list $modifier true] $cmd]
      }
    }
  }
}

if {[catch { open $shortcuts_vala w } rc]} {
  puts "ERROR:  Unable to write $shortcuts_vala: $rc"
  exit 1
}

puts $rc "/*"
puts $rc "* Copyright (c) 2018-21 (https://github.com/phase1geo/Minder)"
puts $rc "*"
puts $rc "* This program is free software; you can redistribute it and/or"
puts $rc "* modify it under the terms of the GNU General Public"
puts $rc "* License as published by the Free Software Foundation; either"
puts $rc "* version 2 of the License, or (at your option) any later version."
puts $rc "*"
puts $rc "* This program is distributed in the hope that it will be useful,"
puts $rc "* but WITHOUT ANY WARRANTY; without even the implied warranty of"
puts $rc "* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU"
puts $rc "* General Public License for more details."
puts $rc "*"
puts $rc "* You should have received a copy of the GNU General Public"
puts $rc "* License along with this program; if not, write to the"
puts $rc "* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,"
puts $rc "* Boston, MA 02110-1301 USA"
puts $rc "*"
puts $rc "* Authored by: Trevor Williams <phase1geo@gmail.com>"
puts $rc "*/"
puts $rc ""
puts $rc "using Gee;"
puts $rc "using Gdk;"

# Create the enumeration
puts $rc "public enum ShortcutType {"
puts -nonewline $rc "  "
puts $rc [string map {- _} [join [lsort [array names shortcuts]] ",\n  "]]
puts $rc "}"

puts $rc ""
puts $rc "public class MinderShortcuts {"
puts $rc ""
puts $rc "  DrawArea                       _da;"
puts $rc "  HashMap<EventKey,ShortcutType> _shortcuts;"
puts $rc ""
puts $rc "  /* Constructor */"
puts $rc "  public MinderShortcuts( DrawArea da ) {"
puts $rc "    _da        = da;"
puts $rc "    _shortcuts = new HashMap( null, (a, b) => {"
puts $rc "      return( (a.state == b.state) && (a.keyval == b.keyval) );"
puts $rc "    });"
puts $rc "    create_shortcuts();"
puts $rc "  }"
puts $rc ""
puts $rc "  /* Adds the keyboard shortcuts */"
puts $rc "  private void create_shortcuts() {"

foreach {key cmd} [array get shortcuts] {
  set control [expr {([string first CONTROL $key] != -1) ? "true" : "false"}]
  set shift   [expr {([string first SHIFT   $key] != -1) ? "true" : "false"}]
  set alt     [expr {([string first ALT     $key] != -1) ? "true" : "false"}]
  set char    [lindex [split $key -] end]
  if {([string length $char] == 1) && [string is alpha $char]} {
    set keyval [expr {($shift eq "true") ? [string toupper $char] : [string tolower $char]}]
  } else {
    set keyval $char
  }
  puts $rc "    add_event( ShortcutType.[string map {- _} $key], $control, $shift, $alt, Key.$keyval );"
}
puts $rc "  }"
puts $rc ""
puts $rc "  /* Runs the given keyboard shortcut */"
puts $rc "  private void run_shortcut( ShortcutType index, EventKey e ) {"
puts $rc "    switch( index ) {"
foreach {key cmd} [array get shortcuts] {
  puts $rc "      case ShortcutType.[string map {- _} $key] :  $cmd;  break;"
}
puts $rc "    }"
puts $rc "  }"
puts $rc ""
puts $rc "  /* Creates a new event from the given values */"
puts $rc "  private EventKey create_event( bool control, bool shift, bool alt, uint keyval ) {"
puts $rc "    var e = new Event( EventType.KEY_PRESS );"
puts $rc "    if( control ) {"
puts $rc "      e.key.state |= ModifierType.CONTROL_MASK;"
puts $rc "    }"
puts $rc "    if( shift ) {"
puts $rc "      e.key.state |= ModifierType.SHIFT_MASK;"
puts $rc "    }"
puts $rc "    if( alt ) {"
puts $rc "      e.key.state |= ModifierType.MOD1_MASK;"
puts $rc "    }"
puts $rc "    e.key.keyval = keyval;"
puts $rc "    return( e.key );"
puts $rc "  }"
puts $rc ""
puts $rc "  /* Adds a new event-method to the list of available keyboard shortcuts */"
puts $rc "  private void add_event( ShortcutType index, bool control, bool shift, bool alt, uint keyval ) {"
puts $rc "    var e = create_event( control, shift, alt, keyval );"
puts $rc "    _shortcuts.set( e, index );"
puts $rc "  }"
puts $rc ""
puts $rc "  /*"
puts $rc "   Called whenever the key is pressed.  Looks up the given key to see if it corresponds to a keyboard shortcut."
puts $rc "   If a shortcut is found, it is run and we return true.  If no shortcut matches, we will return false. "
puts $rc "  */"
puts $rc "  public bool key_pressed( EventKey ek ) {"
puts $rc ""
puts $rc "    var e = ek.copy();"
puts $rc ""
puts $rc "    /* Convert the hardware keycode to a list of possible keys */"
puts $rc "    var keymap = Keymap.get_for_display( Display.get_default() );"
puts $rc "    uint\[\] kvs = {};"
puts $rc "    keymap.get_entries_for_keycode( ek.hardware_keycode, null, out kvs );"
puts $rc ""
puts $rc "    for( int i=(kvs.length-1); i>=0; i-- ) {"
puts $rc "      e.key.keyval = kvs\[i\];"
puts $rc "      if( _shortcuts.has_key( e.key ) ) {"
puts $rc "        run_shortcut( _shortcuts.get( e.key ), ek );"
puts $rc "        return( true );"
puts $rc "      }"
puts $rc "    }"
puts $rc ""
puts $rc "    return( false );"
puts $rc ""
puts $rc "  }"
puts $rc ""
puts $rc "}"

close $rc


