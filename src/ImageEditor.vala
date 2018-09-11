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
  private NodeImage       _orig_image;
  private NodeImage       _node_image;
  private int             _crop_target = -1;
  private double          _last_x;
  private double          _last_y;
  private Gdk.Rectangle[] _crop_points;
  private CursorType[]    _crop_cursors;
  private Label           _status_cursor;
  private Label           _status_crop;
  private Label           _status_rotate;
  private Scale           _angle;

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

  public void edit_image( NodeImage img, double x, double y ) {

    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    _popover.pointing_to = rect;

    /* Set the defaults */
    _orig_image = img;
    _node_image = new NodeImage.from_node_image( img );

    /* Load the image and draw it */
    _da.width_request      = img.get_surface().get_width();
    _da.height_request     = img.get_surface().get_height();
    _crop_points[8].width  = img.crop_w;
    _crop_points[8].height = img.crop_h;
    set_crop_points();
    _angle.set_value( img.rotate );
    _da.queue_draw();

    /* Display ourselves */
    _popover.popup();

  }

  /* Initializes the image editor with the give image filename */
  private bool initialize( string fname ) {

    /* Load the image and draw it */
    if( _node_image.load( fname ) ) {
      _da.width_request      = _node_image.width;
      _da.height_request     = _node_image.height;
      _crop_points[8].width  = _node_image.width;
      _crop_points[8].height = _node_image.height;
      set_crop_points();
      set_cursor_location( 0, 0 );
      _angle.set_value( 0 );
    }

    return( _node_image.valid );

  }

  /* Set the crop point positions to the values on the current crop region */
  private void set_crop_points() {

    var x0 = _node_image.crop_x;
    var x1 = (_node_image.crop_x + (_node_image.crop_w / 2) - (CROP_WIDTH / 2));
    var x2 = ((_node_image.crop_x + _node_image.crop_w) - CROP_WIDTH);
    var y0 = _node_image.crop_y;
    var y1 = (_node_image.crop_y + (_node_image.crop_h / 2) - (CROP_WIDTH / 2));
    var y2 = ((_node_image.crop_y + _node_image.crop_h) - CROP_WIDTH);

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
    _crop_points[8].width  = _node_image.crop_w;
    _crop_points[8].height = _node_image.crop_h;

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
  private void adjust_crop_points( int diffx, int diffy ) {
    if( _crop_target != -1 ) {
      var cx1 = _node_image.crop_x;
      var cy1 = _node_image.crop_y;
      var cx2 = cx1 + _node_image.crop_w;
      var cy2 = cy1 + _node_image.crop_h;
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
      if( (cx1 >= 0) && (cx2 <= _da.width_request) && ((cx2 - cx1) >= MIN_WIDTH) ) {
        _node_image.crop_x = cx1;
        _node_image.crop_w = (cx2 - cx1);
      }
      if( (cy1 >= 0) && (cy2 <= _da.height_request) && ((cy2 - cy1) >= MIN_WIDTH) ) {
        _node_image.crop_y = cy1;
        _node_image.crop_h = (cy2 - cy1);
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

    da.width_request  = NodeImage.EDIT_WIDTH;
    da.height_request = NodeImage.EDIT_HEIGHT;

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
        adjust_crop_points( (int)(e.x - _last_x), (int)(e.y - _last_y) );
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
          da.queue_draw();
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

  /* Creates the rotation toolbar */
  private Box create_toolbar() {

    var box       = new Box( Orientation.HORIZONTAL, 5 );
    var clockwise = new Button.from_icon_name( "object-rotate-right-symbolic", IconSize.BUTTON );
    var counter   = new Button.from_icon_name( "object-rotate-left-symbolic",  IconSize.BUTTON );
    _angle        = new Scale.with_range( Orientation.HORIZONTAL, -180, 180, 1 );

    _angle.set_value( 0 );

    clockwise.clicked.connect(() => {
      _angle.set_value( _angle.get_value() + 1 );
    });

    counter.clicked.connect(() => {
      _angle.set_value( _angle.get_value() - 1 );
    });

    _angle.value_changed.connect(() => {
      var value = (int)_angle.get_value();
      _node_image.rotate = value;
      _status_rotate.label = _( "Rotation: %3d\u00b0" ).printf( value );
      _da.queue_draw();
    });

    box.pack_start( counter,   false, false, 5 );
    box.pack_start( _angle,    true,  true,  0 );
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

    var w = _da.width_request;
    var h = _da.height_request;

    ctx.translate( (w * 0.5), (h * 0.5) );
    ctx.rotate( _node_image.rotate * Math.PI / 180 );
    ctx.translate( (w * -0.5), (h * -0.5) );
    ctx.set_source_surface( _node_image.get_surface(), 0, 0 );
    ctx.paint();

    ctx.translate( (w * 0.5), (h * 0.5) );
    ctx.rotate( (0 - _node_image.rotate) * Math.PI / 180 );
    ctx.translate( (w * -0.5), (h * -0.5) );

  }

  /* Draw the crop mask */
  private void draw_crop( Context ctx ) {

    var width  = _da.width_request;
    var height = _da.height_request;
    var cx1    = _node_image.crop_x;
    var cy1    = _node_image.crop_y;
    var cx2    = _node_image.crop_x + _node_image.crop_w;
    var cy2    = _node_image.crop_y + _node_image.crop_h;

    ctx.set_line_width( 0 );
    ctx.set_source_rgba( 0, 0, 0, 0.8 );
    ctx.rectangle( 0, 0, cx1, height );
    ctx.fill();
    ctx.rectangle( cx2, 0, (width - cx2), height );
    ctx.fill();
    ctx.rectangle( cx1, 0, (cx2 - cx1), (cy1 + 1) );
    ctx.fill();
    ctx.rectangle( cx1, cy2, (cx2 - cx1), (height - cy2) );
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
    var orig_image = new NodeImage.from_node_image( _orig_image );

    /* Set the node image */
    _orig_image.copy_from( _node_image );

    /* Indicate that the image changed */
    changed( orig_image );

  }

}

