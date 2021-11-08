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
  if {[regexp {^([a-zA-Z0-9_-]+)\s+(.*)$} $line -> key cmd]} {
    if {[info exists shortcuts($key)]} {
      puts "ERROR:  Found a duplicate shortcut ($key) on line $lnum"
      exit 1
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
          exit 1
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
puts $rc "using Gdk;"
puts $rc ""

# Create the enumeration
puts $rc "public enum ShortcutType {"
puts -nonewline $rc "  "
puts $rc [string map {- _} [join [lsort [array names shortcuts]] ",\n  "]]
puts $rc "}"

puts $rc ""
puts $rc "public class MinderShortcuts : ShortcutsBase {"
puts $rc ""
puts $rc "  /* Constructor */"
puts $rc "  public MinderShortcuts( DrawArea da ) {"
puts $rc "    base( da );"
puts $rc "  }"
puts $rc ""
puts $rc "  /* Adds the keyboard shortcuts */"
puts $rc "  protected override void create_shortcuts() {"

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
puts $rc "  protected override bool run_shortcut( int index, EventKey e ) {"
puts $rc "    switch( index ) {"
foreach {key cmd} [array get shortcuts] {
  puts $rc "      case ShortcutType.[string map {- _} $key] :  return( $cmd );"
}
puts $rc "    }"
puts $rc "    return( false );"
puts $rc "  }"
puts $rc ""
puts $rc "}"

close $rc


