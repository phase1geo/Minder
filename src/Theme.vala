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
using Gee;

public class Theme : Object {

  private HashMap<string,RGBA?> _colors;

  public string name        { set; get; }
  public string label       { set; get; }
  public int    index       { set; get; default = -1; }
  public bool   prefer_dark { set; get; default = false; }
  public bool   custom      { protected set; get; default = true; }
  public bool   temporary   { set; get; default = false; }
  public bool   rotate      { set; get; default = true; }

  /* Default constructor */
  public Theme() {
    _colors = new HashMap<string,RGBA?>();
    _colors.set( "background",            null );
    _colors.set( "foreground",            null );
    _colors.set( "root_background",       null );
    _colors.set( "root_foreground",       null );
    _colors.set( "nodesel_background",    null );
    _colors.set( "nodesel_foreground",    null );
    _colors.set( "textsel_background",    null );
    _colors.set( "textsel_foreground",    null );
    _colors.set( "text_cursor",           null );
    _colors.set( "attachable",            null );
    _colors.set( "connection_background", null );
    _colors.set( "connection_foreground", null );
    _colors.set( "url_background",        null );
    _colors.set( "url_foreground",        null );
    _colors.set( "tag",                   null );
    _colors.set( "syntax",                null );
    _colors.set( "match_background",      null );
    _colors.set( "match_foreground",      null );
    _colors.set( "link_color0",           null );
    _colors.set( "link_color1",           null );
    _colors.set( "link_color2",           null );
    _colors.set( "link_color3",           null );
    _colors.set( "link_color4",           null );
    _colors.set( "link_color5",           null );
    _colors.set( "link_color6",           null );
    _colors.set( "link_color7",           null );
  }

  /* Copy constructor */
  public Theme.from_theme( Theme theme ) {
    copy( theme );
  }

  /* Copies the given theme to this theme */
  public void copy( Theme theme ) {
    name        = theme.name;
    index       = theme.index;
    prefer_dark = theme.prefer_dark;
    temporary   = theme.temporary;
    rotate      = theme.rotate;
    _colors     = new HashMap<string,RGBA?>();
    var it = theme._colors.map_iterator();
    while( it.next() ) {
      _colors.set( (string)it.get_key(), (RGBA)it.get_value() );
    }
  }

  /* Returns the list of stored theme names */
  public Array<string> colors() {
    var cs = new Array<string>();
    var it = _colors.map_iterator();
    while( it.next() ) {
      var name = (string)it.get_key();
      cs.append_val( name );
    }
    return( cs );
  }

  /* Returns true if the given theme matches the current theme */
  public bool matches( Theme theme ) {
    if( (name == theme.name) || (label == theme.name) ) {
      if( custom ) {
        var it = _colors.map_iterator();
        while( it.next() ) {
          var key = it.get_key();
          if( !_colors.get( key ).equal( theme._colors.get( key ) ) ) {
            return( false );
          }
        }
        return( prefer_dark == theme.prefer_dark );
      }
      return( true );
    }
    return( false );
  }

  /* Adds the given color to the list of link colors */
  public bool set_color( string name, RGBA color ) {
    if( _colors.has_key( name ) ) {
      _colors.set( name, color );
      return( true );
    }
    return( false );
  }

  /* Returns the given color */
  public RGBA? get_color( string name ) {
    if( _colors.has_key( name ) ) {
      return( _colors.get( name ) );
    }
    return( null );
  }

  /* Returns the next available link color index */
  public RGBA? next_color() {
    if( index == -1 ) {
      index = 0;
    } else if( rotate ) {
      index = (index + 1) % 8;
    }
    return( link_color( index  ) );
  }

  /* Returns the number of link colors */
  public static int num_link_colors() {
    return( 8 );
  }

  /* Returns the color associated with the given index */
  public RGBA link_color( int index ) {
    return( _colors.get( "link_color%d".printf( index % 8 ) ) );
  }

  /* Returns a randomly selected link color */
  public RGBA random_link_color() {
    var rand = new Rand();
    return( _colors.get( "link_color%d".printf( rand.int_range( 0, 8 ) ) ) );
  }

  /*
   Searches the stored link colors for one that matches the given color.
   If a match is found, returns the index of the stored color.  If no match
   was found, returns -1.
  */
  public int get_color_index( RGBA color ) {
    string color_str = color.to_string();
    for( int i=0; i<8; i++ ) {
      RGBA? lc = link_color( i );
      if( (lc != null) && (lc.to_string() == color_str) ) {
        return( i );
      }
    }
    return( -1 );
  }

  /* Returns the RGBA color for the given color value */
  protected RGBA color_from_string( string value ) {
    RGBA c = {1.0, 1.0, 1.0, 1.0};
    c.parse( value );
    return( c );
  }

  /* Returns the CSS provider for this theme */
  public CssProvider get_css_provider() {
    CssProvider provider = new CssProvider();
    try {
      var css_data = "@define-color colorPrimary #603461; " +
                     "@define-color textColorPrimary @SILVER_100; " +
                     "@define-color colorAccent #603461; " +
                     "@define-color tab_base_color " + get_color( "background" ).to_string() + ";" +
                     ".theme-selected { background: #087DFF; } " +
                     ".canvas { background: " + get_color( "background" ).to_string() + "; }";
      provider.load_from_data( css_data );
    } catch( GLib.Error e ) {
      stdout.printf( "Unable to load background color: %s", e.message );
    }
    return( provider );
  }

  /* Sets the context color based on the theme RGBA color */
  private void set_context_color( Cairo.Context ctx, RGBA color ) {
    ctx.set_source_rgba( color.red, color.green, color.blue, color.alpha );
  }

  /* Parses the specified XML node for theme coloring information */
  public void load( Xml.Node* n ) {

    string? nn = n->get_prop( "name" );
    if( nn != null ) {
      name = nn;
    }

    string? ll = n->get_prop( "label" );
    if( ll != null ) {
      label = ll;
    } else if( nn != null ) {  /* This is for backwards compatibility */
      label = nn;
    }

    string? idx = n->get_prop( "index" );
    if( idx != null ) {
      index = int.parse( idx );
    }

    var cs = colors();
    for( int i=0; i<cs.length; i++ ) {
      var name = cs.index( i );
      string? s = n->get_prop( name );
      if( s != null ) {
        set_color( name, color_from_string( s ) );
      }
    }

    string? d = n->get_prop( "prefer_dark" );
    if( d != null ) {
      prefer_dark = bool.parse( d );
    }

  }

  /* Returns an XML node containing the contents of this theme color scheme */
  public Xml.Node* save() {

    Xml.Node* n = new Xml.Node( null, "theme" );

    n->new_prop( "name",  name );
    n->new_prop( "label", label );
    n->new_prop( "index", index.to_string() );

    if( custom ) {

      var cs = colors();
      for( int i=0; i<cs.length; i++ ) {
        var name = cs.index( i );
        n->new_prop( name, Utils.color_from_rgba( get_color( name ) ) );
      }

      n->new_prop( "prefer_dark", prefer_dark.to_string() );

    }

    return( n );

  }

  /* Creates the icon representation based on the theme's colors */
  public Cairo.Surface make_icon() {

    int                side    = 140;
    int                nrad    = 15;
    Cairo.ImageSurface surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, side, side );
    Cairo.Context      ctx     = new Cairo.Context( surface );
    int                hside   = side / 2;
    double             ypos[6];
    int                width, height;

    var font_desc = new Pango.FontDescription();
    font_desc.set_family( "Sans" );
    font_desc.set_size( 11 * Pango.SCALE );

    /* Draw the background */
    set_context_color( ctx, get_color( "background" ) );
    ctx.rectangle( 0, 0, side, side );
    ctx.fill();

    /* Create root node text */
    var root_text = Pango.cairo_create_layout( ctx );
    root_text.set_font_description( font_desc );
    // root_text.set_width( 70 * Pango.SCALE );
    root_text.set_text( _( "Root" ), -1 );
    root_text.get_pixel_size( out width, out height );

    var rrad   = (width + 20) / 2;
    var hspace = ((side - (rrad * 2) - (nrad * 4)) / 4) + nrad;
    var vspace = ((side - (nrad * 6))              / 4) + nrad;

    ypos[0] = ypos[3] = vspace;
    ypos[1] = ypos[4] = (side / 2);
    ypos[2] = ypos[5] = (side - vspace);

    /* Draw root node */
    set_context_color( ctx, get_color( "root_background" ) );
    ctx.arc( hside, hside, rrad, 0, (2 * Math.PI) );
    ctx.fill();

    /* Add the text */
    set_context_color( ctx, get_color( "root_foreground" ) );
    ctx.move_to( (hside - (width / 2)), (hside - (height / 2)) );
    Pango.cairo_show_layout( ctx, root_text );

    /* Draw subnodes */
    for( int i=0; i<6; i++ ) {
      set_context_color( ctx, link_color( i ) );
      ctx.arc( ((i < 3) ? hspace : (side - hspace)), ypos[i], nrad, 0, (2 * Math.PI) );
      ctx.fill();
    }

    /* Draw connection */
    set_context_color( ctx, get_color( "connection_background" ) );
    double p[6];
    p[0] = hspace + nrad + 2;
    p[1] = vspace + 2;
    p[2] = hside;
    p[3] = p[1] - nrad;
    p[4] = side - (hspace + nrad + 2);
    p[5] = p[1];
    ctx.set_line_width( 2 );
    ctx.set_dash( {3, 5}, 0 );
    ctx.move_to( p[0], p[1] );
    ctx.curve_to(
      (((2.0 / 3.0) * p[2]) + ((1.0 / 3.0) * p[0])),
      (((2.0 / 3.0) * p[3]) + ((1.0 / 3.0) * p[1])),
      (((2.0 / 3.0) * p[2]) + ((1.0 / 3.0) * p[4])),
      (((2.0 / 3.0) * p[3]) + ((1.0 / 3.0) * p[5])),
      p[4], p[5]
    );
    ctx.stroke();
    Connection.draw_arrow( ctx, 2, p[0], p[1], p[2], p[3], 7 );
    Connection.draw_arrow( ctx, 2, p[4], p[5], p[2], p[3], 7 );

    return( surface );

  }

}
