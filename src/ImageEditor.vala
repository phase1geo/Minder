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

  private DrawingArea   _da;
  private double        _cx1         = 0;
  private double        _cy1         = 0;
  private double        _cx2         = 200;
  private double        _cy2         = 200;
  private ImageSurface? _image       = null;
  private int           _crop_target = -1;
  private NodeImage     _node_image;
  private double        _last_x;
  private double        _last_y;
  private double        _scale;

  public signal void done( bool changed );

  /* Default constructor */
  public ImageEditor( NodeImage img, Gtk.Window parent ) {

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
      _da.queue_draw();
    } catch( Error e ) {
      // TBD
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
      var p = 8;
      var h = ((_cy2 - _cy1) + p) / 2;
      var v = ((_cx2 - _cx1) + p) / 2;
      _crop_target = -1;
      _last_x      = e.x;
      _last_y      = e.y;
      if( (_cx1 <= e.x) && (e.x <= (_cx1 + p)) ) {
        if( (_cy1 <= e.y) && (e.y <= (_cy1 + p)) ) {
          _crop_target = 0;
        } else if( (h <= e.x) && (e.x <= (h + p)) ) {
          _crop_target = 1;
        } else if( ((_cy2 - p) <= e.y) && (e.y <= (_cy2 + p)) ) {
          _crop_target = 2;
        }
      } else if( (h <= e.x) && (e.x <= (h + p)) ) {
        if( (_cy1 <= e.y) && (e.y <= (_cy1 + p)) ) {
          _crop_target = 3;
        } else if( (_cy2 <= e.y) && (e.y <= (_cy2 + p)) ) {
          _crop_target = 4;
        }
      } else if( ((_cx2 - p) <= e.x) && (e.x <= (_cx2 + p)) ) {
        if( ((_cy1 - p) <= e.y) && (e.y <= (_cy1 + 5)) ) {
          _crop_target = 5;
        } else if( (v <= e.y) && (e.y <= (v + p)) ) {
          _crop_target = 6;
        } else if( ((_cy2 - p) <= e.y) && (e.y <= (_cy2 + p)) ) {
          _crop_target = 7;
        }
      }
      stdout.printf( "crop_target: %d\n", _crop_target );
      return( false );
    });

    da.motion_notify_event.connect((e) => {
      double diffx = (e.x - _last_x);
      double diffy = (e.y - _last_y);
      switch( _crop_target ) {
        case 0 :  _cx1 += diffx;  _cy1 += diffy;  break;
        case 1 :  _cy1 += diffy;  break;
        case 2 :  _cx2 += diffx;  _cy1 += diffy;  break;
        case 3 :  _cx1 += diffx;  break;
        case 4 :  _cx2 += diffx;  break;
        case 5 :  _cx1 += diffx;  _cy2 += diffy;  break;
        case 6 :  _cy2 += diffy;  break;
        case 7 :  _cx2 += diffx;  _cy2 += diffy;  break;
      }
      _last_x = e.x;
      _last_y = e.y;
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
    var cx1    = _cx1;
    var cy1    = _cy1;
    var cx2    = _cx2;
    var cy2    = _cy2;
    var cw     = 8;

    ctx.set_line_width( 1 );

    ctx.set_source_rgba( 0, 0, 0, 0.8 );
    ctx.rectangle( 0, 0, cx1, height );
    ctx.fill();
    ctx.rectangle( cx2, 0, (width - cx2), height );
    ctx.fill();
    ctx.rectangle( cx1, 0, (cx2 - cx1), cy1 );
    ctx.fill();
    ctx.rectangle( cx1, cy2, (cx2 - cx1), (height - cy2) );
    ctx.fill();

    /* Draw the crop points */
    draw_crop_point( ctx, cx1, cy1, cw );
    draw_crop_point( ctx, (((cx2 - cx1) + cw) / 2), cy1, cw );
    draw_crop_point( ctx, (cx2 - cw), cy1, cw );
    draw_crop_point( ctx, cx1, (((cy2 - cy1) + cw) / 2), cw );
    draw_crop_point( ctx, (cx2 - cw), (((cy2 - cy1) + cw) / 2), cw );
    draw_crop_point( ctx, cx1, (cy2 - cw), cw );
    draw_crop_point( ctx, (((cx2 - cx1) + cw) / 2), (cy2 - cw), cw );
    draw_crop_point( ctx, (cx2 - cw), (cy2 - cw), cw );

  }

  /* Draws a single crop point at the given point with the given width/height */
  private void draw_crop_point( Context ctx, double x, double y, double w ) {

    ctx.set_source_rgb( 1, 1, 1 );
    ctx.rectangle( x, y, w, w );
    ctx.fill();

    ctx.set_source_rgb( 0, 0, 0 );
    ctx.rectangle( x, y, w, w );
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

