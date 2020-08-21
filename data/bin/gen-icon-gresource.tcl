# Usage:  tclsh8.6 bin/gen-icon-gresource.tcl  (run from 'data' directory)

set svg_dir [file join icons flat-color-icons svg]

foreach item [glob -nocomplain -directory $svg_dir -tails *.svg] {
  puts "    <file alias=\"[string range $item 0 end-4]\">[file join $svg_dir $item]</file>"
}
