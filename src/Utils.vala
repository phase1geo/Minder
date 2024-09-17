/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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

using Gtk;
using Gdk;
using Cairo;

public class Utils {

  /* Creates the given directory (and all parent directories) with appropriate permissions */
  public static bool create_dir( string path ) {
    return( DirUtils.create_with_parents( path, 0755 ) == 0 );
  }

  /*
   Returns a regular expression useful for parsing clickable URLs.
  */
  public static string url_re() {
    string[] res = {
      "mailto:.+@[a-z0-9-]+\\.[a-z0-9.-]+",
      "[a-zA-Z0-9]+://[a-z0-9-]+\\.[a-z0-9.-]+(?:/|(?:/[][a-zA-Z0-9!#$%&'*+,.:;=?@_~-]+)*)",
      "file:///([^,\\/:*\\?\\<>\"\\|]+(/|\\\\){0,1})+"
    };
    return( "(" + string.joinv( "|",res ) + ")" );
  }

  /*
   Helper function for converting an RGBA color value to a stringified color
   that can be used by a markup parser.
  */
  public static string color_from_rgba( RGBA rgba ) {
    return( "#%02x%02x%02x".printf( (int)(rgba.red * 255), (int)(rgba.green * 255), (int)(rgba.blue * 255) ) );
  }

  /* Returns the RGBA color for the given color value */
  public static RGBA color_from_string( string value ) {
    RGBA c = {1.0, 1.0, 1.0, 1.0};
    c.parse( value );
    return( c );
  }

  /* Sets the context source color to the given color value */
  public static void set_context_color( Context ctx, RGBA color ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
  }

  /*
   Sets the context source color to the given color value overriding the
   alpha value with the given value.
  */
  public static void set_context_color_with_alpha( Context ctx, RGBA color, double alpha ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, alpha );
  }

  /* Returns the red, green and blue color values that are needed by the Pango color attributes */
  public static void get_attribute_color( RGBA color, out uint16 red, out uint16 green, out uint16 blue ) {
    var maxval = 65535;
    red   = (uint16)(color.red   * maxval);
    green = (uint16)(color.green * maxval);
    blue  = (uint16)(color.blue  * maxval);
  }

  /*
   Adds the given accelerator label to the given menu item.
  */
  public static void add_accel_label( Gtk.MenuItem item, uint key, Gdk.ModifierType mods ) {

    /* Convert the menu item to an accelerator label */
    AccelLabel? label = item.get_child() as AccelLabel;

    if( label == null ) return;

    /* Add the accelerator to the label */
    label.set_accel( key, mods );
    label.refetch();

  }

  /*
   Checks the given string to see if it is a match to the given pattern.  If
   it is, the matching portion of the string appended to the list of matches.

   See : https://valadoc.org/glib-2.0/string.substring.html
  */
  public static string match_string( string pattern, string value) {
      int pattern_byte_idx = value.casefold().index_of( pattern );
      if( pattern_byte_idx != -1 ) {
        unichar  c = 0;
        int i = 0;
        int current_index = pattern_byte_idx;
        while (value.get_prev_char(ref current_index, out c) && i < 10) {
          i++;
        }
        int start = i < 10 ? 0 : current_index;
        i = 0;
        current_index = pattern_byte_idx + pattern.length;
        while (value.get_next_char(ref current_index, out c) && i < 10) {
          i++;
        }
        int end = i < 10 ? -1 : current_index - ( pattern_byte_idx + pattern.length );
        string str = (start > 0 ? "..." : "") +
        value.substring(start, pattern_byte_idx - start) +
        "<u>" + pattern + "</u>" +
        value.substring(pattern_byte_idx + pattern.length);
        return str;
      }
    return "";
  }

  /* Returns the rootname of the given filename */
  public static string rootname( string filename ) {
    var basename = GLib.Path.get_basename( filename );
    var parts    = basename.split( "." );
    if( parts.length > 2 ) {
      return( string.joinv( ".", parts[0:parts.length-1] ) );
    } else {
      return( parts[0] );
    }
  }

  /* Returns true if the given coordinates are within the specified bounds */
  public static bool is_within_bounds( double x, double y, double bx, double by, double bw, double bh ) {
    return( (bx < x) && (x < (bx + bw)) && (by < y) && (y < (by + bh)) );
  }

  /* Returns a string that is suitable to use as an inspector title */
  public static string make_title( string str ) {
    return( "<b>" + str + "</b>" );
  }

  /* Returns a string that is used to display a tooltip with displayed accelerator */
  public static string tooltip_with_accel( string tooltip, string accel ) {
    string[] accels = {accel};
    return( Granite.markup_accel_tooltip( accels, tooltip ) );
  }

  /* Opens the given URL in the proper external default application */
  public static void open_url( string url ) {
    try {
      AppInfo.launch_default_for_uri( url, null );
    } catch( GLib.Error e ) {
      stdout.printf( _( "error: %s\n" ), e.message );
    }
  }

  /* Prepares the given note string for use in a markup tooltip */
  public static string prepare_note_markup( string note ) {
    var str = markdown_to_html( note );  // .replace( "<", "&lt;" ).replace( ">", "&gt;" ) );
    // stdout.printf( "---------------\n%s--------------\n", str );
    try {
      MatchInfo match_info;
      var re    = new Regex( "</?(\\w+)[^>]*>" );
      var start = 0;
      var list  = new Queue<int>();
      while( re.match_full( str, -1, start, 0, out match_info ) ) {
        int tag_start, tag_end;
        int name_start, name_end;
        match_info.fetch_pos( 0, out tag_start, out tag_end );
        match_info.fetch_pos( 1, out name_start, out name_end );
        var old_tag = str.slice( tag_start, tag_end );
        var new_tag = old_tag;
        var name    = str.slice( name_start, name_end );
        var end_tag = (str.substring( (name_start - 1), 1 ) == "/");
        switch( name ) {
          case "h1"     :  new_tag = end_tag ? "</span>" : "<span weight=\"bold\" size=\"xx-large\">";  break;
          case "h2"     :  new_tag = end_tag ? "</span>" : "<span weight=\"bold\" size=\"x-large\">";   break;
          case "h3"     :  new_tag = end_tag ? "</span>" : "<span weight=\"bold\" size=\"large\">";     break;
          case "h4"     :
          case "h5"     :
          case "h6"     :  new_tag = end_tag ? "</span>" : "<span weight=\"bold\" size=\"medium\">";    break;
          case "strong" :  new_tag = end_tag ? "</b>" : "<b>";  break;
          case "em"     :  new_tag = end_tag ? "</i>" : "<i>";  break;
          case "code"   :  new_tag = end_tag ? "</tt>" : "<tt>";  break;
          case "blockquote" :  new_tag = end_tag ? "</i>" : "<i>";  break;
          case "hr"     :  new_tag = end_tag ? "" : "---";  break;
          case "p"      :  new_tag = "";  break;
          case "br"     :  new_tag = "";  break;
          case "ul"     :
          case "ol"     :
            new_tag = ""; 
            if( end_tag ) {
              list.pop_tail();
            } else {
              list.push_tail( (name == "ul") ? 1000000 : 1 );
            }
            break;
          case "li"     :
            if( end_tag ) {
              new_tag = "";
            } else {
              var val    = list.pop_tail();
              var prefix = string.nfill( list.get_length(), ' ' );
              if( val >= 1000000 ) {
                new_tag = "%s* ".printf( prefix );
              } else {
                new_tag = "%s%d. ".printf( prefix, val );
              }
              list.push_tail( val + 1 );
            }
            break;
        }
        str   = str.splice( tag_start, tag_end, new_tag );
        start = tag_end + (new_tag.length - old_tag.length);
      }
    } catch( RegexError e ) {
      return( note.replace( "<", "&lt;" ) );
    }
    return( str.replace( "\n\n\n", "\n\n" ) );
  }

  /* Converts the given Markdown into HTML */
  public static string markdown_to_html( string md, string? tag = null ) {
    string html;
#if MD30
    html = Markup.escape_text( md );
#else
    uint32 flags = Markdown.DocumentFlags.NOPANTS |
                Markdown.DocumentFlags.TOC |
                Markdown.DocumentFlags.@1_COMPAT |
                Markdown.DocumentFlags.AUTOLINK |
                Markdown.DocumentFlags.EXTRA_FOOTNOTE |
                Markdown.DocumentFlags.NOSTYLE |
                Markdown.DocumentFlags.DLEXTRA |
                Markdown.DocumentFlags.FENCEDCODE |
                Markdown.DocumentFlags.IDANCHOR |
                Markdown.DocumentFlags.LATEX;
    var mkd = new Markdown.Document.from_gfm_string( md.data, flags );
    mkd.compile( flags );
    mkd.document( out html );
#endif
    if( tag == null ) {
      return( html );
    } else {
      return( "<" + tag + ">" + html + "</" + tag + ">" );
    }
  }

  /* Returns the line height of the first line of the given pango layout */
  public static double get_line_height( Pango.Layout layout ) {
    int height;
    var line = layout.get_line_readonly( 0 );
    if( line == null ) {
      int width;
      layout.get_size( out width, out height );
    } else {
      Pango.Rectangle ink_rect, log_rect;
      line.get_extents( out ink_rect, out log_rect );
      height = log_rect.height;
    }
    return( height / Pango.SCALE );
  }

  /* Searches for the beginning or ending word */
  public static int find_word( string str, int cursor, bool wordstart ) {
    try {
      MatchInfo match_info;
      var substr = wordstart ? str.substring( 0, cursor ) : str.substring( cursor );
      var re = new Regex( wordstart ? ".*(\\W\\w|[\\w\\s][^\\w\\s])" : "(\\w\\W|[^\\w\\s][\\w\\s])" );
      if( re.match( substr, 0, out match_info ) ) {
        int start_pos, end_pos;
        match_info.fetch_pos( 1, out start_pos, out end_pos );
        return( wordstart ? (start_pos + 1) : (cursor + start_pos + 1) );
      }
    } catch( RegexError e ) {}
    return( -1 );
  }

  /* Returns true if the given string is a valid URL */
  public static bool is_url( string str ) {
    return( Regex.match_simple( url_re(), str ) );
  }

  /* Returns true if the given file is read-only */
  public static bool is_read_only( string fname ) {
    var file = File.new_for_path( fname );
    var src  = new Gtk.SourceFile();
    src.set_location( file );
    src.check_file_on_disk();
    return( src.is_readonly() );
  }

  /* Show the specified popover */
  public static void show_popover( Popover popover ) {
#if GTK322
    popover.popup();
#else
    popover.show();
#endif
  }

  /* Hide the specified popover */
  public static void hide_popover( Popover popover ) {
#if GTK322
    popover.popdown();
#else
    popover.hide();
#endif
  }

  /* Pops up the given menu */
  public static void popup_menu( Gtk.Menu menu, Event e ) {
#if GTK322
    menu.popup_at_pointer( e );
#else
    menu.popup( null, null, null, e.button, e.time );
#endif
  }

  public static void set_chooser_folder( FileChooser chooser ) {
    var dir = Minder.settings.get_string( "last-directory" );
    if( dir != "" ) {
      chooser.set_current_folder( dir );
    }
  }

  public static void store_chooser_folder( string file, bool is_dir ) {
    var dir = is_dir ? file : GLib.Path.get_dirname( file );
    Minder.settings.set_string( "last-directory", dir );
  }

}
