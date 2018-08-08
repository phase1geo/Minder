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
  private double        _scale       = 1;
  private double        _tx          = 0;
  private double        _ty          = 0;
  private double        _cx1         = 0;
  private double        _cy1         = 0;
  private double        _cx2         = 200;
  private double        _cy2         = 200;
  private ImageSurface? _image       = null;
  private int           _crop_target = -1;
  private double        _last_x;
  private double        _last_y;
//  private Pixbuf?       _pixbuf;

  public signal void done( bool changed );

  /* Default constructor */
  public ImageEditor() {
    create_ui();
  }

  /* Constructor */
  public ImageEditor.from_file( string fname ) {
    create_ui();
    try {
      var pix = new Pixbuf.from_file( fname );
      _image = new ImageSurface.for_data( pix.get_pixels(), Format.RGB24, pix.width, pix.height, pix.rowstride );
    } catch( Error e ) {
      // TBD - There was an error loading the file
    }
  }

  /* Constructor */
  public ImageEditor.from_image( Image img ) {
    create_ui();
    var pix = img.get_pixbuf();
    _image = new ImageSurface.for_data( pix.get_pixels(), Format.RGB24, pix.width, pix.height, pix.rowstride );
  }

  /* Creates the user interface */
  public void create_ui() {

    this.modal               = true;
    this.destroy_with_parent = true;

    var vbox = new Box( Orientation.VERTICAL, 5 );

    _da      = create_drawing_area();
    var zoom = create_zoom_slider();

    /* Add the action buttons */
    add_button( _( "Apply" ),  ResponseType.APPLY );
    add_button( _( "Cancel" ), ResponseType.CANCEL );

    /* Pack the widgets into the window */
    vbox.pack_start( _da,  true,  true, 5 );
    vbox.pack_start( zoom, false, true, 5 );

    /* Add the items to the window */
    add( vbox );

    show_all();

  }

  /* Create the image editing area */
  public DrawingArea create_drawing_area() {

    var da = new DrawingArea();

    da.width_request  = 200;
    da.height_request = 200;

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
      ctx.scale( _scale, _scale );
      ctx.translate( _tx, _ty );
      draw_image( ctx );
      draw_crop( ctx );
      return( false );
    });
    da.button_press_event.connect((e) => {
      var p = 5;
      _crop_target = -1;
      _last_x      = e.x;
      _last_y      = e.y;
      if( ((_cx1 - p) <= e.x) && (e.x <= (_cx1 + p)) ) {
        if( ((_cy1 - p) <= e.y) && (e.y <= (_cy1 + p)) ) {
          _crop_target = 0;
        } else if( ((_cy2 - p) <= e.y) && (e.y <= (_cy2 + p)) ) {
          _crop_target = 2;
        }
      } else if( ((_cx2 - p) <= e.x) && (e.x <= (_cx2 + p)) ) {
        if( ((_cy1 - p) <= e.y) && (e.y <= (_cy1 + 5)) ) {
          _crop_target = 1;
        } else if( ((_cy2 - p) <= e.y) && (e.y <= (_cy2 + p)) ) {
          _crop_target = 3;
        }
      }
      return( false );
    });
    da.motion_notify_event.connect((e) => {
      if( _crop_target == -1 ) {
        _tx += (e.x - _last_x);
        _ty += (e.y - _last_y);
      } else {
        if( (_crop_target & 0x2) == 0 ) {
          _cx1 += (e.x - _last_x);
        } else {
          _cx2 += (e.x - _last_x);
        }
        if( (_crop_target & 0x1) == 0 ) {
          _cy1 += (e.y - _last_y);
        } else {
          _cy2 += (e.y - _last_y);
        }
      }
      _last_x = e.x;
      _last_y = e.y;
      da.queue_draw();
      return( false );
    });

    return( da );

  }

  /* Add the image */
  private void draw_image( Context ctx ) {
    ctx.set_source_surface( _image, 0, 0 );
  }

  /* Draw the crop mask */
  private void draw_crop( Context ctx ) {

    // TBD

  }

  /* Create the zoom slider */
  public Scale create_zoom_slider() {

    var slider = new Scale.with_range( Orientation.HORIZONTAL, 10, 200, 10 );

    slider.set_value( 100 );
    slider.has_origin = true;
    slider.change_value.connect((scroll, value) => {
      _scale = value / 100;
      _da.queue_draw();
      return( false );
    });

    return( slider );

  }

  /* Returns the pixbuf associated with this window */
#if DEVELOPMENT
  public Pixbuf? get_pixbuf() {
    return( _pixbuf );
  }
#endif

}

