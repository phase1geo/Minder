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

class ImageEditor : Gtk.Dialog {

  private const double MIN_WIDTH  = 50;
  private const int    CROP_WIDTH = 8;

  private DrawingArea     _da;
  private double          _cx1         = 0;
  private double          _cy1         = 0;
  private double          _cx2         = 200;
  private double          _cy2         = 200;
  private ImageSurface?   _image       = null;
  private int             _crop_target = -1;
  private NodeImage       _node_image;
  private double          _last_x;
  private double          _last_y;
  private double          _scale;
  private Gdk.Rectangle[] _crop_points;

  public signal void done( bool changed );

  /* Default constructor */
  public ImageEditor( NodeImage img, Gtk.Window parent ) {

    /* Allocate crop points */
    _crop_points = new Gdk.Rectangle[8];

    /* Initialize the crop points */
    for( int i=0; i<_crop_points.length; i++ ) {
      _crop_points[i] = {0, 0, CROP_WIDTH, CROP_WIDTH};
    }

    /* Set the defaults */
    _node_image = img;
    _scale      = img.scale;

    /* Create the user interface of the editor window */
    create_ui( parent );

    /* Load the image and draw it */
    try {
      var pixbuf = new Pixbuf.from_file_at_size( img.fname, 600, 600 );
      _image             = (ImageSurface)cairo_surface_create_from_pixbuf( pixbuf, 0, null );
      _da.width_request  = pixbuf.width;
      _da.height_request = pixbuf.height;
      _cx2               = pixbuf.width;
      _cy2               = pixbuf.height;
      set_crop_points();
      _da.queue_draw();
    } catch( Error e ) {
      // TBD
    }

  }

  /* Set the crop point positions to the values on the current crop region */
  private void set_crop_points() {
    var x0 = (int)_cx1;
    var x1 = (int)(_cx1 + ((_cx2 - _cx1) / 2) - (CROP_WIDTH / 2));
    var x2 = (int)(_cx2 - CROP_WIDTH);
    var y0 = (int)_cy1;
    var y1 = (int)(_cy1 + ((_cy2 - _cy1) / 2) - (CROP_WIDTH / 2));
    var y2 = (int)(_cy2 - CROP_WIDTH);
    _crop_points[0].x = x0;
    _crop_points[0].y = y0;
    _crop_points[1].x = x1;
    _crop_points[1].y = y0;
    _crop_points[2].x = x2;
    _crop_points[2].y = y0;
    _crop_points[3].x = x0;
    _crop_points[3].y = y1;
    _crop_points[4].x = x2;
    _crop_points[4].y = y1;
    _crop_points[5].x = x0;
    _crop_points[5].y = y2;
    _crop_points[6].x = x1;
    _crop_points[6].y = y2;
    _crop_points[7].x = x2;
    _crop_points[7].y = y2;
  }

  /* Set the crop target based on the position of the cursor */
  private void set_crop_target( double x, double y ) {
    Gdk.Rectangle cursor = {(int)x, (int)y, 1, 1};
    Gdk.Rectangle tmp;
    int           i      = 0;
    foreach (Gdk.Rectangle crop_point in _crop_points) {
      if( crop_point.intersect( cursor, out tmp ) ) {
        _crop_target = i;
        return;
      }
      i++;
    }
    _crop_target = -1;
  }

  /* Adjusts the crop points by the given cursor difference */
  private void adjust_crop_points( double diffx, double diffy ) {
    if( _crop_target != -1 ) {
      var cx1 = _cx1;
      var cy1 = _cy1;
      var cx2 = _cx2;
      var cy2 = _cy2;
      switch( _crop_target ) {
        case 0 :  cx1 += diffx;  cy1 += diffy;  break;
        case 1 :  cy1 += diffy;                 break;
        case 2 :  cx2 += diffx;  cy1 += diffy;  break;
        case 3 :  cx1 += diffx;                 break;
        case 4 :  cx2 += diffx;                 break;
        case 5 :  cx1 += diffx;  cy2 += diffy;  break;
        case 6 :  cy2 += diffy;                 break;
        case 7 :  cx2 += diffx;  cy2 += diffy;  break;
      }
      if( (cx2 - cx1) >= MIN_WIDTH ) {
        _cx1 = cx1;  _cx2 = cx2;
      }
      if( (cy2 - cy1) >= MIN_WIDTH ) {
        _cy1 = cy1;  _cy2 = cy2;
      }
      set_crop_points();
    }
  }

  /* Creates the user interface */
  public void create_ui( Gtk.Window parent ) {

    modal               = true;
    destroy_with_parent = true;
    set_transient_for( parent );

    _da = create_drawing_area();

    /* Pack the widgets into the window */
    get_content_area().pack_start( _da, true, true, 5 );

    /* Add the action buttons */
    add_button( _( "Cancel" ), ResponseType.CANCEL );
    add_button( _( "Apply" ),  ResponseType.APPLY );

    show_all();

  }

  /* Create the image editing area */
  public DrawingArea create_drawing_area() {

    var da = new DrawingArea();

    da.width_request  = 600;
    da.height_request = 600;

    /* Make sure the above events are listened for */
    da.add_events(
      EventMask.BUTTON_PRESS_MASK |
      EventMask.BUTTON_RELEASE_MASK |
      EventMask.BUTTON1_MOTION_MASK
    );

    /*
     Make sure that we add a CSS class name to ourselves so we can color
     our background with the theme.
    */
    da.get_style_context().add_class( "canvas" );

    /* Add event listeners */
    da.draw.connect((ctx) => {
      draw_image( ctx );
      draw_crop( ctx );
      return( false );
    });

    da.button_press_event.connect((e) => {
      set_crop_target( e.x, e.y );
      _last_x = e.x;
      _last_y = e.y;
      return( false );
    });

    da.motion_notify_event.connect((e) => {
      adjust_crop_points( (e.x - _last_x), (e.y - _last_y) );
      _last_x = e.x;
      _last_y = e.y;
      queue_draw();
      return( false );
    });

    return( da );

  }

  /* Add the image */
  private void draw_image( Context ctx ) {

    ctx.set_source_surface( _image, 0, 0 );
    ctx.paint();

  }

  /* Draw the crop mask */
  private void draw_crop( Context ctx ) {

    var width  = _da.get_allocated_width();
    var height = _da.get_allocated_height();

    ctx.set_line_width( 1 );

    ctx.set_source_rgba( 0, 0, 0, 0.8 );
    ctx.rectangle( 0, 0, _cx1, height );
    ctx.fill();
    ctx.rectangle( _cx2, 0, (width - _cx2), height );
    ctx.fill();
    ctx.rectangle( _cx1, 0, (_cx2 - _cx1), _cy1 );
    ctx.fill();
    ctx.rectangle( _cx1, _cy2, (_cx2 - _cx1), (height - _cy2) );
    ctx.fill();

    /* Draw the crop points */
    foreach (Gdk.Rectangle crop_point in _crop_points) {
      draw_crop_point( ctx, crop_point );
    }

  }

  /* Draws a single crop point at the given point with the given width/height */
  private void draw_crop_point( Context ctx, Gdk.Rectangle crop ) {

    ctx.set_source_rgb( 1, 1, 1 );
    ctx.rectangle( crop.x, crop.y, crop.width, crop.width );
    ctx.fill();

    ctx.set_source_rgb( 0, 0, 0 );
    ctx.rectangle( crop.x, crop.y, crop.width, crop.width );
    ctx.stroke();

  }

  /* Returns the pixbuf associated with this window */
  public void set_node_image() {

    _node_image.scale  = _scale;
    _node_image.posx   = _cx1;
    _node_image.posy   = _cy1;

    /* Copy the buffer to the node image */
    try {
      var buf = new Pixbuf.from_file( _node_image.fname );
      buf.scale( _node_image.get_pixbuf(), (int)_cx1, (int)_cy1, (int)(_cx2 - _cx1), (int)(_cy2 - _cy1), 0, 0, _scale, _scale, InterpType.BILINEAR );
    } catch( Error e ) {
      // TBD
    }

  }

}

