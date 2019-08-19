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

  private int                   _index;
  private HashMap<string,RGBA?> _colors;

  public string name        { set; get; }
  public bool   prefer_dark { set; get; default = false; }

  public int index {
    set {
      _index = value;
    }
    get {
      return( _index );
    }
  }

  public bool custom { protected set; get; default = true; }

  /* Default constructor */
  public Theme() {
    _index  = 0;
    _colors = new HashMap<string,RGBA?>();
    _colors.set( "background",         null );
    _colors.set( "foreground",         null );
    _colors.set( "root_background",    null );
    _colors.set( "root_foreground",    null );
    _colors.set( "nodesel_background", null );
    _colors.set( "nodesel_foreground", null );
    _colors.set( "textsel_background", null );
    _colors.set( "textsel_foreground", null );
    _colors.set( "text_cursor",        null );
    _colors.set( "attachable",         null );
    _colors.set( "connection",         null );
    _colors.set( "link_color0",        null );
    _colors.set( "link_color1",        null );
    _colors.set( "link_color2",        null );
    _colors.set( "link_color3",        null );
    _colors.set( "link_color4",        null );
    _colors.set( "link_color5",        null );
    _colors.set( "link_color6",        null );
    _colors.set( "link_color7",        null );
  }

  /* Copy constructor */
  public Theme.from_theme( Theme theme ) {
    copy( theme );
  }

  public void copy( Theme theme ) {
    name        = theme.name;
    prefer_dark = theme.prefer_dark;
    _index      = 0;
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
    return( link_color( _index++ % 8 ) );
  }

  /* Returns the number of link colors */
  public static int num_link_colors() {
    return( 8 );
  }

  /* Returns the color associated with the given index */
  public RGBA link_color( int index ) {
    return( _colors.get( "link_color%d".printf( index % 8 ) ) );
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

    n->new_prop( "name", name );

    var cs = colors();
    for( int i=0; i<cs.length; i++ ) {
      var name = cs.index( i );
      n->new_prop( name, Utils.color_from_rgba( get_color( name ) ) );
    }

    n->new_prop( "prefer_dark", prefer_dark.to_string() );

    return( n );

  }

  /* Creates the icon representation based on the theme's colors */
  public Cairo.Surface make_icon() {

    Cairo.ImageSurface surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, 200, 100 );
    Cairo.Context      ctx     = new Cairo.Context( surface );
    int                width, height;

    var font_desc = new Pango.FontDescription();
    font_desc.set_family( "Sans" );
    font_desc.set_size( 10 * Pango.SCALE );

    /* Draw the background */
    set_context_color( ctx, get_color( "background" ) );
    ctx.rectangle( 0, 0, 200, 100 );
    ctx.fill();

    /* Draw subnode lines */
    set_context_color( ctx, link_color( 0 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 50, 25 );
    ctx.stroke();
    set_context_color( ctx, link_color( 0 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 50, 25 );
    ctx.line_to( 10, 25 );
    ctx.stroke();

    set_context_color( ctx, link_color( 1 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 10, 50 );
    ctx.stroke();

    set_context_color( ctx, link_color( 2 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 50, 75 );
    ctx.stroke();
    set_context_color( ctx, link_color( 2 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 50, 75 );
    ctx.line_to( 10, 75 );
    ctx.stroke();

    set_context_color( ctx, link_color( 3 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 150, 25 );
    ctx.stroke();
    set_context_color( ctx, link_color( 3 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 150, 25 );
    ctx.line_to( 190, 25 );
    ctx.stroke();

    set_context_color( ctx, link_color( 4 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 190, 50 );
    ctx.stroke();

    set_context_color( ctx, link_color( 5 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 150, 75 );
    ctx.stroke();
    set_context_color( ctx, link_color( 5 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 150, 75 );
    ctx.line_to( 190, 75 );
    ctx.stroke();

    /* Create root node text */
    var root_text = Pango.cairo_create_layout( ctx );
    root_text.set_font_description( font_desc );
    root_text.set_width( 70 * Pango.SCALE );
    root_text.set_wrap( Pango.WrapMode.WORD_CHAR );
    root_text.set_text( name, -1 );
    root_text.get_pixel_size( out width, out height );

    height += 4;

    /* Draw root node */
    double r = 4;
    double x = 65;
    double y = (100 - height) / 2;
    double w = 70;
    double h = height;
    set_context_color( ctx, get_color( "root_background" ) );
    ctx.set_line_width( 1 );
    ctx.move_to(x+r,y);
    ctx.line_to(x+w-r,y);
    ctx.curve_to(x+w,y,x+w,y,x+w,y+r);
    ctx.line_to(x+w,y+h-r);
    ctx.curve_to(x+w,y+h,x+w,y+h,x+w-r,y+h);
    ctx.line_to(x+r,y+h);
    ctx.curve_to(x,y+h,x,y+h,x,y+h-r);
    ctx.line_to(x,y+r);
    ctx.curve_to(x,y,x,y,x+r,y);
    ctx.fill();

    /* Create non-root node text */
    var node_text = Pango.cairo_create_layout( ctx );
    node_text.set_font_description( font_desc );
    node_text.set_width( 40 * Pango.SCALE );
    node_text.set_wrap( Pango.WrapMode.WORD_CHAR );
    node_text.set_text( "Node", -1 );

    /* Add the text */
    set_context_color( ctx, get_color( "root_foreground" ) );
    ctx.move_to( (100 - (width / 2)), (50 - (height / 2)) );
    Pango.cairo_show_layout( ctx, root_text );

    node_text.get_size( out width, out height );
    width  /= Pango.SCALE;
    height /= Pango.SCALE;

    set_context_color( ctx, get_color( "foreground" ) );
    ctx.move_to( (30 - (width / 2)), (25 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    set_context_color( ctx, get_color( "foreground" ) );
    ctx.move_to( (30 - (width / 2)), (50 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    set_context_color( ctx, get_color( "foreground" ) );
    ctx.move_to( (30 - (width / 2)), (75 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    set_context_color( ctx, get_color( "foreground" ) );
    ctx.move_to( (170 - (width / 2)), (25 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    set_context_color( ctx, get_color( "foreground" ) );
    ctx.move_to( (170 - (width / 2)), (50 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    set_context_color( ctx, get_color( "foreground" ) );
    ctx.move_to( (170 - (width / 2)), (75 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    /* Draw connection */
    set_context_color( ctx, get_color( "connection" ) );
    double p[6] = {60, 15, 100, 5, 140, 15};
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
