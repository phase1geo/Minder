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

class ImageEditor {

  private const double MIN_WIDTH  = 50;
  private const int    CROP_WIDTH = 8;
  private const Gtk.TargetEntry[] DRAG_TARGETS = {
    {"text/uri-list", 0, 0}
  };

  private Popover         _popover;
  private DrawingArea     _da;
  private double          _cx1         = 0;
  private double          _cy1         = 0;
  private double          _cx2         = 200;
  private double          _cy2         = 200;
  private ImageSurface?   _image       = null;
  private int             _crop_target = -1;
  private NodeImage       _node_image;
  private int             _max_width;
  private double          _last_x;
  private double          _last_y;
  private Gdk.Rectangle[] _crop_points;
  private CursorType[]    _crop_cursors;
  private int             _rotation;
  private Label           _status_cursor;
  private Label           _status_crop;
  private Label           _status_rotate;

  public signal void changed( NodeImage? orig_image );

  /* Default constructor */
  public ImageEditor( DrawArea da ) {

    /* Allocate crop points */
    _crop_points  = new Gdk.Rectangle[9];
    _crop_cursors = new CursorType[8];

    /* Initialize the crop points */
    for( int i=0; i<_crop_points.length; i++ ) {
      _crop_points[i] = {0, 0, CROP_WIDTH, CROP_WIDTH};
    }

    /* Setup cursor types */
    _crop_cursors[0] = CursorType.TOP_LEFT_CORNER;
    _crop_cursors[1] = CursorType.SB_V_DOUBLE_ARROW;
    _crop_cursors[2] = CursorType.TOP_RIGHT_CORNER;
    _crop_cursors[3] = CursorType.SB_H_DOUBLE_ARROW;
    _crop_cursors[4] = CursorType.SB_H_DOUBLE_ARROW;
    _crop_cursors[5] = CursorType.TOP_RIGHT_CORNER;
    _crop_cursors[6] = CursorType.SB_V_DOUBLE_ARROW;
    _crop_cursors[7] = CursorType.TOP_LEFT_CORNER;

    /* Create the user interface of the editor window */
    create_ui( (Gtk.Window)da.get_toplevel() );

  }

  public void edit_image( NodeImage img, double x, double y, int max_width ) {

    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    _popover.pointing_to = rect;

    /* Set the defaults */
    _node_image = img;
    _max_width  = max_width;

    /* Load the image and draw it */
    if( initialize( img.fname ) ) {
      var scale_width = (max_width * 1.0) / img.width;
      stdout.printf( "max_width: %d, img.width: %d, scale_width: %g\n", max_width, img.width, scale_width );
      _cx1 = img.posx;
      _cy1 = img.posy;
      _cx2 = img.posx + img.width;
      _cy2 = img.posy + img.height;
      _crop_points[8].width  = img.width;
      _crop_points[8].height = img.height;
      set_crop_points();
      set_rotation( img.rotate );
      _da.queue_draw();
    }

    /* Display ourselves */
    _popover.popup();

  }

  /* Initializes the image editor with the give image filename */
  private bool initialize( string fname ) {

    var cx1 = _cx1;
    var cy1 = _cy1;

    _cx1 = 0;
    _cy1 = 0;

    /* Load the image and draw it */
    try {
      var pixbuf = new Pixbuf.from_file_at_size( fname, 600, 600 );
      _image                 = (ImageSurface)cairo_surface_create_from_pixbuf( pixbuf, 0, null );
      _da.width_request      = pixbuf.width;
      _da.height_request     = pixbuf.height;
      _cx2                   = pixbuf.width;
      _cy2                   = pixbuf.height;
      _crop_points[8].width  = pixbuf.width;
      _crop_points[8].height = pixbuf.height;
      set_crop_points();
      set_cursor_location( 0, 0 );
      set_rotation( 0 );
    } catch( Error e ) {
      _cx1 = cx1;
      _cy1 = cy1;
      return( false );
    }

    return( true );

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

    _crop_points[8].x      = x0;
    _crop_points[8].y      = y0;
    _crop_points[8].width  = (int)(_cx2 - _cx1);
    _crop_points[8].height = (int)(_cy2 - _cy1);

    _status_crop.label = _( "Crop Area: %d,%d %3dx%3d" ).printf( _crop_points[8].x, _crop_points[8].y, _crop_points[8].width, _crop_points[8].height );

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
        case 8 :  cx1 += diffx;  cy1 += diffy;
                  cx2 += diffx;  cy2 += diffy;  break;
      }
      if( (cx1 >= 0) && (cx2 <= _image.get_width()) && ((cx2 - cx1) >= MIN_WIDTH) ) {
        _cx1 = cx1;  _cx2 = cx2;
      }
      if( (cy1 >= 0) && (cy2 <= _da.height_request) && ((cy2 - cy1) >= MIN_WIDTH) ) {
        _cy1 = cy1;  _cy2 = cy2;
      }
      set_crop_points();
    }
  }

  /* Creates the user interface */
  public void create_ui( Gtk.Window parent ) {

    _popover = new Popover( parent );
    _popover.modal = true;

    var box = new Box( Orientation.VERTICAL, 5 );

    _da = create_drawing_area();
    var status  = create_status_area();
    var toolbar = create_toolbar();
    var buttons = create_buttons( parent );

    /* Pack the widgets into the window */
    box.pack_start( _da,     true,  true, 10 );
    box.pack_start( status,  false, false, 0 );
    box.pack_start( toolbar, false, true, 10 );
    box.pack_start( buttons, false, true, 10 );

    box.show_all();

    /* Add the box to the popover */
    _popover.add( box );

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
      EventMask.BUTTON1_MOTION_MASK |
      EventMask.POINTER_MOTION_MASK
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
      if( _crop_target == 8 ) {
        var win = _da.get_window();
        win.set_cursor( new Cursor.from_name( _popover.get_display(), "grabbing" ) );
      }
      _last_x = e.x;
      _last_y = e.y;
      return( false );
    });

    da.motion_notify_event.connect((e) => {
      if( _crop_target == -1 ) {
        set_crop_target( e.x, e.y );
        if( (_crop_target >= 0) && (_crop_target < 8) ) {
          set_cursor( _crop_cursors[_crop_target] );
        } else {
          set_cursor( null );
        }
        _crop_target = -1;
      } else {
        adjust_crop_points( (e.x - _last_x), (e.y - _last_y) );
        da.queue_draw();
      }
      _last_x = e.x;
      _last_y = e.y;
      set_cursor_location( (int)e.x, (int)e.y );
      return( false );
    });

    da.button_release_event.connect((e) => {
      _crop_target = -1;
      set_cursor( null );
      return( false );
    });

    /* Set ourselves up to be a drag target */
    Gtk.drag_dest_set( da, DestDefaults.MOTION | DestDefaults.DROP, DRAG_TARGETS, Gdk.DragAction.COPY );

    da.drag_data_received.connect((ctx, x, y, data, info, t) => {
      if( data.get_uris().length == 1 ) {
        string? fname = NodeImage.get_fname_from_uri( data.get_uris()[0] );
        if( (fname != null) && initialize( fname ) ) {
          Gtk.drag_finish( ctx, true, false, t );
        }
      }
    });

    return( da );

  }

  /* Creates the status area */
  private Box create_status_area() {

    var box = new Box( Orientation.HORIZONTAL, 10 );

    box.homogeneous = true;

    _status_cursor = new Label( null );
    _status_crop   = new Label( null );
    _status_rotate = new Label( null );

    box.pack_start( _status_cursor, false, false, 5 );
    box.pack_start( _status_crop,   false, false, 5 );
    box.pack_start( _status_rotate, false, false, 5 );

    return( box );

  }

  /* Updates the cursor location status with the given values */
  private void set_cursor_location( int x, int y ) {

    _status_cursor.label = _( "Cursor: %3d,%3d" ).printf( x, y );

  }

  /* Sets the rotation value and updates the status */
  private void set_rotation( int value ) {

    _rotation = value;
    _status_rotate.label = _( "Rotation: %3d\u00b0" ).printf( _rotation );

  }

  /* Creates the rotation toolbar */
  private Box create_toolbar() {

    var box       = new Box( Orientation.HORIZONTAL, 5 );
    var clockwise = new Button.from_icon_name( "object-rotate-right-symbolic", IconSize.BUTTON );
    var counter   = new Button.from_icon_name( "object-rotate-left-symbolic",  IconSize.BUTTON );
    var angle     = new Scale.with_range( Orientation.HORIZONTAL, -180, 180, 1 );

    angle.set_value( 0 );

    clockwise.clicked.connect(() => {
      angle.set_value( angle.get_value() + 1 );
    });

    counter.clicked.connect(() => {
      angle.set_value( angle.get_value() - 1 );
    });

    angle.value_changed.connect(() => {
      set_rotation( (int)angle.get_value() );
      _da.queue_draw();
    });

    box.pack_start( counter,   false, false, 5 );
    box.pack_start( angle,     true,  true,  0 );
    box.pack_start( clockwise, false, false, 5 );

    return( box );

  }

  /* Creates the button bar at the bottom of the window */
  private Box create_buttons( Gtk.Window parent ) {

    var box    = new Box( Orientation.HORIZONTAL, 5 );
    var cancel = new Button.with_label( _( "Cancel" ) );
    var apply  = new Button.with_label( _( "Apply" ) );
    var change = new Button.with_label( _( "Change Image" ) );

    cancel.clicked.connect(() => {
      _popover.popdown();
    });

    apply.clicked.connect(() => {
      set_node_image();
      _popover.popdown();
    });

    change.clicked.connect(() => {
      string? fn = NodeImage.choose_image_file( parent );
      if( (fn != null) && initialize( fn ) ) {
        _da.queue_draw();
      }
    });

    box.pack_start( change, false, false, 5 );
    box.pack_end(   apply,  false, false, 5 );
    box.pack_end(   cancel, false, false, 5 );

    return( box );

  }

  /* Sets the cursor of the drawing area */
  private void set_cursor( CursorType? type = null ) {

    var     win    = _da.get_window();
    Cursor? cursor = win.get_cursor();

    if( type == null ) {
      win.set_cursor( null );
    } else if( (cursor == null) || (cursor.cursor_type != type) ) {
      win.set_cursor( new Cursor.for_display( _popover.get_display(), type ) );
    }

  }

  /* Add the image */
  private void draw_image( Context ctx ) {

    var w = _image.get_width();
    var h = _image.get_height();

    ctx.translate( (w * 0.5), (h * 0.5) );
    ctx.rotate( _rotation * Math.PI / 180 );
    ctx.translate( (w * -0.5), (h * -0.5) );
    ctx.set_source_surface( _image, 0, 0 );
    ctx.paint();

    ctx.translate( (w * 0.5), (h * 0.5) );
    ctx.rotate( (0 - _rotation) * Math.PI / 180 );
    ctx.translate( (w * -0.5), (h * -0.5) );

  }

  /* Draw the crop mask */
  private void draw_crop( Context ctx ) {

    var width  = _image.get_width();
    var height = _image.get_height();

    ctx.set_line_width( 0 );
    ctx.set_source_rgba( 0, 0, 0, 0.8 );
    ctx.rectangle( 0, 0, _cx1, height );
    ctx.fill();
    ctx.rectangle( _cx2, 0, (width - _cx2), height );
    ctx.fill();
    ctx.rectangle( _cx1, 0, (_cx2 - _cx1), (_cy1 + 1) );
    ctx.fill();
    ctx.rectangle( _cx1, _cy2, (_cx2 - _cx1), (height - _cy2) );
    ctx.fill();

    ctx.set_line_width( 1 );

    /* Draw the crop points */
    for( int i=0; i<8; i++ ) {
      draw_crop_point( ctx, _crop_points[i] );
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
  private void set_node_image() {

    /* Create a copy of the current image before changing it */
    NodeImage orig_image = new NodeImage.from_node_image( _node_image );

    /* Create a surface and context to draw */
    var surface = new ImageSurface( _image.get_format(), _image.get_width(), _image.get_height() );
    var context = new Context( surface );

    /* Draw the image onto the context */
    draw_image( context );

    /* Set the node image */
    _node_image.rotate = _rotation;
    _node_image.set_from_surface( surface, (int)_cx1, (int)_cy1, (int)(_cx2 - _cx1), (int)(_cy2 - _cy1), _max_width );

    /* Indicate that the image changed */
    changed( orig_image );

  }

}

