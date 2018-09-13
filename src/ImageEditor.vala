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
  private Node            _node;
  private NodeImage       _image;
  private int             _crop_target = -1;
  private double          _last_x;
  private double          _last_y;
  private Gdk.Rectangle[] _crop_points;
  private CursorType[]    _crop_cursors;
  private Label           _status_cursor;
  private Label           _status_crop;

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

  /* Handles the display of the image editor popover */
  private void show_popover( bool show ) {

#if GTK322
    if( show ) {
      _popover.popup();
    } else {
      _popover.popdown();
    }
#else
    if( show ) {
      _popover.show();
    } else {
      _popover.hide();
    }
#endif

  }

  public void edit_image( Node node, double x, double y ) {

    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    _popover.pointing_to = rect;

    /* Set the defaults */
    _node  = node;
    _image = new NodeImage.from_file( node.image.fname, node.image.uri, _node.max_width() );

    if( _image.valid ) {

      _image.crop_x = node.image.crop_x;
      _image.crop_y = node.image.crop_y;
      _image.crop_w = node.image.crop_w;
      _image.crop_h = node.image.crop_h;

      /* Load the image and draw it */
      _da.width_request      = node.image.get_surface().get_width();
      _da.height_request     = node.image.get_surface().get_height();
      _crop_points[8].width  = _image.crop_w;
      _crop_points[8].height = _image.crop_h;
      set_crop_points();
      _da.queue_draw();

      /* Display ourselves */
      show_popover( true );

    }

  }

  /* Initializes the image editor with the give image filename */
  private bool initialize( string fname, bool fname_is_uri ) {

    /* Create a new image from the given filename */
    if( fname_is_uri ) {
      _image = new NodeImage.from_uri( fname, _node.max_width() );
    } else {
      _image = new NodeImage.from_file( fname, null, _node.max_width() );
    }

    /* Load the image and draw it */
    if( _image.valid ) {
      _da.width_request      = _image.get_surface().get_width();
      _da.height_request     = _image.get_surface().get_height();
      _crop_points[8].width  = _image.crop_w;
      _crop_points[8].height = _image.crop_h;
      set_crop_points();
      set_cursor_location( 0, 0 );
      _da.queue_draw();
    }

    return( _image.valid );

  }

  /* Set the crop point positions to the values on the current crop region */
  private void set_crop_points() {

    var x0 = _image.crop_x;
    var x1 = (_image.crop_x + (_image.crop_w / 2) - (CROP_WIDTH / 2));
    var x2 = ((_image.crop_x + _image.crop_w) - CROP_WIDTH);
    var y0 = _image.crop_y;
    var y1 = (_image.crop_y + (_image.crop_h / 2) - (CROP_WIDTH / 2));
    var y2 = ((_image.crop_y + _image.crop_h) - CROP_WIDTH);

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
    _crop_points[8].width  = _image.crop_w;
    _crop_points[8].height = _image.crop_h;

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
      var x = _image.crop_x;
      var y = _image.crop_y;
      var w = _image.crop_w;
      var h = _image.crop_h;
      switch( _crop_target ) {
        case 0 :  x += diffx;  y += diffy;  w -= diffx;  h -= diffy;  break;
        case 1 :               y += diffy;               h -= diffy;  break;
        case 2 :               y += diffy;  w += diffx;  h -= diffy;  break;
        case 3 :  x += diffx;               w -= diffx;               break;
        case 4 :                            w += diffx;               break;
        case 5 :  x += diffx;               w -= diffx;  h += diffy;  break;
        case 6 :                                         h += diffy;  break;
        case 7 :                            w += diffx;  h += diffy;  break;
        case 8 :  x += diffx;  y += diffy;                            break;
      }
      if( (x >= 0) && ((x + w) <= _da.width_request) && (w >= MIN_WIDTH) ) {
        _image.crop_x = x;
        _image.crop_w = w;
      }
      if( (y >= 0) && ((y + h) <= _da.height_request) && (h >= MIN_WIDTH) ) {
        _image.crop_y = y;
        _image.crop_h = h;
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
    var buttons = create_buttons( parent );

    /* Pack the widgets into the window */
    box.pack_start( _da,     true,  true, 10 );
    box.pack_start( status,  false, false, 0 );
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
        if( initialize( data.get_uris()[0], true ) ) {
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

    box.pack_start( _status_cursor, false, false, 5 );
    box.pack_start( _status_crop,   false, false, 5 );

    return( box );

  }

  /* Updates the cursor location status with the given values */
  private void set_cursor_location( int x, int y ) {
    _status_cursor.label = _( "Cursor: %3d,%3d" ).printf( x, y );
  }

  /* Creates the button bar at the bottom of the window */
  private Box create_buttons( Gtk.Window parent ) {

    var box    = new Box( Orientation.HORIZONTAL, 5 );
    var cancel = new Button.with_label( _( "Cancel" ) );
    var apply  = new Button.with_label( _( "Apply" ) );
    var change = new Button.with_label( _( "Change Image" ) );
    var remove = new Button.with_label( _( "Remove Image" ) );

    cancel.clicked.connect(() => {
      show_popover( false );
    });

    apply.clicked.connect(() => {
      set_image();
      show_popover( false );
    });

    change.clicked.connect(() => {
      string? fn = NodeImage.choose_image_file( parent );
      if( fn != null ) {
        initialize( fn, true );
      }
    });

    remove.clicked.connect(() => {
      remove_image();
      show_popover( false );
    });

    box.pack_start( change, false, false, 5 );
    box.pack_start( remove, false, false, 5 );
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

    /* Draw the cropped portion of the image */
    ctx.set_source_surface( _image.get_surface(), 0, 0 );
    ctx.paint();

    /* On top of that, draw the crop transparency */
    ctx.set_source_rgba( 0, 0, 0, 0.8 );
    ctx.rectangle( 0, 0, _da.width_request, _da.height_request );
    ctx.fill();

    /* Cut out the area for the image */
    ctx.set_operator( Operator.CLEAR );
    ctx.rectangle( _image.crop_x, _image.crop_y, _image.crop_w, _image.crop_h );
    ctx.fill();

    /* Finally, draw the portion of the image this not cropped */
    ctx.set_operator( Operator.OVER );
    ctx.set_source_surface( _image.get_surface(), 0, 0 );
    ctx.rectangle( _image.crop_x, _image.crop_y, _image.crop_w, _image.crop_h );
    ctx.fill();

    /* Draw the crop points */
    ctx.set_line_width( 1 );
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

  /* Removes the current image for the node */
  private void remove_image() {

    /* Create a copy of the current image before changing it */
    var orig_image = _node.image;

    /* Clear the node image */
    _node.image = null;

    /* Indicate that the image changed */
    changed( orig_image );

  }

  /* Sets the node image to the edited image */
  private void set_image() {

    /* Create a copy of the current image before changing it */
    var orig_image = _node.image;

    /* Set the image width to match the node's max width */
    _image.set_width( _node.max_width() );

    /* Set the node image */
    _node.image = _image;

    /* Indicate that the image changed */
    changed( orig_image );

  }

}

