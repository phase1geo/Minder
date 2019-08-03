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

public class Theme : Object {

  private int          _index;
  private Array<RGBA?> _link_colors;

  public    string name               { protected set; get; }
  public    Image  icon               { protected set; get; }
  public    RGBA   background         { protected set; get; }
  public    RGBA   foreground         { protected set; get; }
  public    RGBA   root_background    { protected set; get; }
  public    RGBA   root_foreground    { protected set; get; }
  public    RGBA   nodesel_background { protected set; get; }
  public    RGBA   nodesel_foreground { protected set; get; }
  public    RGBA   textsel_background { protected set; get; }
  public    RGBA   textsel_foreground { protected set; get; }
  public    RGBA   text_cursor        { protected set; get; }
  public    RGBA   attachable_color   { protected set; get; }
  public    RGBA   connection_color   { protected set; get; }
  public    bool   prefer_dark        { protected set; get; }

  public int index {
    set {
      _index = value;
    }
    get {
      return( _index );
    }
  }

  /* Default constructor */
  public Theme() {
    _index       = 0;
    _link_colors = new Array<RGBA?>();
  }

  /* Adds the given color to the list of link colors */
  protected void add_link_color( RGBA color ) {
    _link_colors.append_val( color );
  }

  /* Returns the next available link color index */
  public RGBA next_color() {
    return( _link_colors.index( _index++ % _link_colors.length ) );
  }

  /* Returns the number of link colors */
  public int num_link_colors() {
    return( (int)_link_colors.length );
  }

  /* Returns the color associated with the given index */
  public RGBA link_color( int index ) {
    return( _link_colors.index( index % _link_colors.length ) );
  }

  /*
   Searches the stored link colors for one that matches the given color.
   If a match is found, returns the index of the stored color.  If no match
   was found, returns -1.
  */
  public int get_color_index( RGBA color ) {
    string color_str = color.to_string();
    for( int i=0; i<_link_colors.length; i++ ) {
      if( _link_colors.index( i ).to_string() == color_str ) {
        return( i );
      }
    }
    return( -1 );
  }

  /* Returns the RGBA color for the given color value */
  protected RGBA get_color( string value ) {
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
                     // "@define-color textColorPrimaryShadow @SILVER_500; " +
                     "@define-color colorAccent #603461; " +
                     ".theme-selected { background: #087DFF; } " +
                     ".find { -gtk-icon-source: -gtk-icontheme('edit-find'); -gtk-icon-theme: 'hicolor'; } " +
                     ".canvas { background: " + background.to_string() + "; }";
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

  /* Creates the icon representation based on the theme's colors */
  public Cairo.Surface make_icon() {

    Cairo.ImageSurface surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, 200, 100 );
    Cairo.Context      ctx     = new Cairo.Context( surface );
    int                width, height;

    var font_desc = new Pango.FontDescription();
    font_desc.set_family( "Sans" );
    font_desc.set_size( 10 * Pango.SCALE );

    /* Draw the background */
    set_context_color( ctx, background );
    ctx.rectangle( 0, 0, 200, 100 );
    ctx.fill();

    /* Draw subnode lines */
    set_context_color( ctx, _link_colors.index( 0 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 50, 25 );
    ctx.stroke();
    set_context_color( ctx, _link_colors.index( 0 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 50, 25 );
    ctx.line_to( 10, 25 );
    ctx.stroke();

    set_context_color( ctx, _link_colors.index( 1 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 10, 50 );
    ctx.stroke();

    set_context_color( ctx, _link_colors.index( 2 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 50, 75 );
    ctx.stroke();
    set_context_color( ctx, _link_colors.index( 2 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 50, 75 );
    ctx.line_to( 10, 75 );
    ctx.stroke();

    set_context_color( ctx, _link_colors.index( 3 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 150, 25 );
    ctx.stroke();
    set_context_color( ctx, _link_colors.index( 3 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 150, 25 );
    ctx.line_to( 190, 25 );
    ctx.stroke();

    set_context_color( ctx, _link_colors.index( 4 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 190, 50 );
    ctx.stroke();

    set_context_color( ctx, _link_colors.index( 5 ) );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 150, 75 );
    ctx.stroke();
    set_context_color( ctx, _link_colors.index( 5 ) );
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
    set_context_color( ctx, root_background );
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
    set_context_color( ctx, root_foreground );
    ctx.move_to( (100 - (width / 2)), (50 - (height / 2)) );
    Pango.cairo_show_layout( ctx, root_text );

    node_text.get_size( out width, out height );
    width  /= Pango.SCALE;
    height /= Pango.SCALE;

    set_context_color( ctx, foreground );
    ctx.move_to( (30 - (width / 2)), (25 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    set_context_color( ctx, foreground );
    ctx.move_to( (30 - (width / 2)), (50 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    set_context_color( ctx, foreground );
    ctx.move_to( (30 - (width / 2)), (75 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    set_context_color( ctx, foreground );
    ctx.move_to( (170 - (width / 2)), (25 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    set_context_color( ctx, foreground );
    ctx.move_to( (170 - (width / 2)), (50 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    set_context_color( ctx, foreground );
    ctx.move_to( (170 - (width / 2)), (75 - (height + 2)) );
    Pango.cairo_show_layout( ctx, node_text );

    /* Draw connection */
    set_context_color( ctx, connection_color );
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
