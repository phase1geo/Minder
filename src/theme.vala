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

  private int _index;

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
  protected RGBA[] link_colors        { set; get; }

  /* Default constructor */
  public Theme() {
    _index = 0;
  }

  /* Returns the next available link color index */
  public int next_color_index() {
    return( _index++ );
  }

  /* Returns the color associated with the given index */
  public RGBA link_color( int index ) {
    return( link_colors[index % link_colors.length] );
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
      provider.load_from_data( "GtkDrawingArea { background:" + background.to_string() + "; }" );
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

    int width, height;
    Cairo.ImageSurface surface = new Cairo.ImageSurface( Cairo.Format.ARGB32, 200, 100 );
    Cairo.Context      ctx     = new Cairo.Context( surface );

    /* Draw the background */
    set_context_color( ctx, background );
    ctx.rectangle( 0, 0, 200, 100 );
    ctx.fill();

    /* Draw subnode lines */
    set_context_color( ctx, link_colors[0] );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 50, 25 );
    ctx.stroke();
    set_context_color( ctx, link_colors[0] );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 50, 25 );
    ctx.line_to( 10, 25 );
    ctx.stroke();

    set_context_color( ctx, link_colors[1] );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 10, 50 );
    ctx.stroke();

    set_context_color( ctx, link_colors[2] );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 50, 75 );
    ctx.stroke();
    set_context_color( ctx, link_colors[2] );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 50, 75 );
    ctx.line_to( 10, 75 );
    ctx.stroke();

    set_context_color( ctx, link_colors[3] );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 150, 25 );
    ctx.stroke();
    set_context_color( ctx, link_colors[3] );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 150, 25 );
    ctx.line_to( 190, 25 );
    ctx.stroke();

    set_context_color( ctx, link_colors[4] );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 190, 50 );
    ctx.stroke();

    set_context_color( ctx, link_colors[5] );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 100, 50 );
    ctx.line_to( 150, 75 );
    ctx.stroke();
    set_context_color( ctx, link_colors[5] );
    ctx.set_line_cap( Cairo.LineCap.ROUND );
    ctx.set_line_width( 4 );
    ctx.move_to( 150, 75 );
    ctx.line_to( 190, 75 );
    ctx.stroke();

    /* Draw root node */
    double r = 4;
    double x = 65;
    double y = 40;
    double w = 70;
    double h = 20;
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

    /* Create text */
    var root_text = Pango.cairo_create_layout( ctx );
    root_text.set_width( 70 * Pango.SCALE );
    root_text.set_wrap( Pango.WrapMode.WORD_CHAR );
    root_text.set_text( name, -1 );

    var node_text = Pango.cairo_create_layout( ctx );
    node_text.set_width( 40 * Pango.SCALE );
    node_text.set_wrap( Pango.WrapMode.WORD_CHAR );
    node_text.set_text( "Node", -1 );

    /* Add the text */
    root_text.get_size( out width, out height );
    set_context_color( ctx, root_foreground );
    ctx.move_to( (100 - ((width / Pango.SCALE) / 2)), (50 - ((height / Pango.SCALE) / 2)) );
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

    return( surface );

  }

}
