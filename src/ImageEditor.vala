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

public class ImageEditor {

  private const double MIN_WIDTH   = 50;
  private const int    CROP_WIDTH  = 8;
  private const int    EDIT_WIDTH  = 600;
  private const int    EDIT_HEIGHT = 600;

  private Popover         _popover;
  private ImageManager    _im;
  private DrawingArea     _da;
  private Node            _node;
  private NodeImage       _image;
  private Button          _paste;
  private int             _crop_target = -1;
  private double          _press_x;
  private double          _press_y;
  private Gdk.Rectangle[] _crop_points;
  private string[]        _crop_cursors;
  private Label           _status_cursor;
  private Label           _status_crop;
  private double          _scale;
  private double          _crop_x;
  private double          _crop_y;
  private double          _crop_w;
  private double          _crop_h;

  public signal void changed( NodeImage? orig_image );

  //-------------------------------------------------------------
  // Default constructor
  public ImageEditor( DrawArea da ) {

    _im = da.map.image_manager;

    // Allocate crop points
    _crop_points  = new Gdk.Rectangle[9];
    _crop_cursors = new string[8];

    // Initialize the crop points
    for( int i=0; i<_crop_points.length; i++ ) {
      _crop_points[i] = {0, 0, CROP_WIDTH, CROP_WIDTH};
    }

    // Initialize the crop
    _scale  = 1.0;
    _crop_x = 0.0;
    _crop_y = 0.0;
    _crop_w = 0.0;
    _crop_h = 0.0;

    // Setup cursor types
    _crop_cursors[0] = "nwse-resize";
    _crop_cursors[1] = "ns-resize";
    _crop_cursors[2] = "nesw-resize";
    _crop_cursors[3] = "ew-resize";
    _crop_cursors[4] = "ew-resize";
    _crop_cursors[5] = "nesw-resize";
    _crop_cursors[6] = "ns-resize";
    _crop_cursors[7] = "nwse-resize";

    // Create the user interface of the editor window
    create_ui( da, da.map.image_manager );

  }

  //-------------------------------------------------------------
  // Opens an image editor popup containing the image of the
  // specified node
  public void edit_image( ImageManager im, Node node, double x, double y ) {

    var int_x = (int)x;
    var int_y = (int)y;
    Gdk.Rectangle rect = {int_x, int_y, 1, 1};
    _popover.pointing_to = rect;

    // Set the defaults
    _node  = node;
    _image = new NodeImage( im, node.image.id, _node.style.node_width );

    if( _image.valid ) {

      _scale = (double)EDIT_WIDTH / _image.orig_width;

      _crop_x = (double)node.image.crop_x;
      _crop_y = (double)node.image.crop_y;
      _crop_w = (double)node.image.crop_w;
      _crop_h = (double)node.image.crop_h;

      // Load the image and draw it
      _crop_points[8].width  = _image.crop_w;
      _crop_points[8].height = _image.crop_h;
      set_crop_points();
      _da.queue_draw();

      // Display ourselves
      _popover.popup();

    }

  }

  //-------------------------------------------------------------
  // Initializes the image editor with the give image filename
  private bool initialize( NodeImage ni ) {

    // Create a new image from the given filename
    _image = ni;

    // Load the image and draw it
    if( _image.valid ) {

      _scale = (double)EDIT_WIDTH / _image.orig_width;

      _crop_x = (double)_image.crop_x;
      _crop_y = (double)_image.crop_y;
      _crop_w = (double)_image.crop_w;
      _crop_h = (double)_image.crop_h;

      _crop_points[8].width  = _image.crop_w;
      _crop_points[8].height = _image.crop_h;
      set_crop_points();
      set_cursor_location( 0, 0 );
      _da.queue_draw();

    }

    return( _image.valid );

  }

  //-------------------------------------------------------------
  // Set the crop point positions to the values on the current
  // crop region
  private void set_crop_points() {

    var crop_width = (CROP_WIDTH / _scale);

    var x0 = (int)_crop_x;
    var x1 = (int)(_crop_x + (_crop_w / 2) - (crop_width / 2));
    var x2 = (int)((_crop_x + _crop_w) - crop_width);
    var y0 = (int)_crop_y;
    var y1 = (int)(_crop_y + (_crop_h / 2) - (crop_width / 2));
    var y2 = (int)((_crop_y + _crop_h) - crop_width);

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

    for( int i=0; i<8; i++ ) {
      _crop_points[i].width  = (int)crop_width;
      _crop_points[i].height = (int)crop_width;
    }

    _crop_points[8].x      = x0;
    _crop_points[8].y      = y0;
    _crop_points[8].width  = (int)_crop_w;
    _crop_points[8].height = (int)_crop_h;

    _status_crop.label = _( "Crop Area: %d,%d %3dx%3d" ).printf( _crop_points[8].x, _crop_points[8].y, _crop_points[8].width, _crop_points[8].height );

  }

  //-------------------------------------------------------------
  // Set the crop target based on the position of the cursor
  private void set_crop_target( double x, double y ) {
    var int_x = (int)x;
    var int_y = (int)y;
    Gdk.Rectangle cursor = {int_x, int_y, 1, 1};
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

  //-------------------------------------------------------------
  // Adjusts the crop points by the given cursor difference
  private void adjust_crop_points( double diffx, double diffy ) {
    if( _crop_target != -1 ) {
      var x = _crop_x;  // _image.FOOBAR;  // crop_x;
      var y = _crop_y;
      var w = _crop_w;
      var h = _crop_h;
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
        _crop_x = x;
        _crop_w = w;
      }
      if( (y >= 0) && ((y + h) <= _da.height_request) && (h >= MIN_WIDTH) ) {
        _crop_y = y;
        _crop_h = h;
      }
      set_crop_points();
    }
  }

  //-------------------------------------------------------------
  // Creates the user interface
  public void create_ui( DrawArea da, ImageManager im ) {

    _da = create_drawing_area( im );
    var status  = create_status_area();
    var buttons = create_buttons( da, im );

    /* Pack the widgets into the window */
    var box = new Box( Orientation.VERTICAL, 5 ) {
      margin_start  = 5,
      margin_end    = 5,
      margin_top    = 5,
      margin_bottom = 5
    };
    box.append( _da );
    box.append( status );
    box.append( buttons );

    /* Add the box to the popover */
    _popover = new Popover() {
      child = box
    };
    _popover.set_parent( da );

    /* Set the stage for keyboard shortcuts */
    var key = new EventControllerKey();
    box.add_controller( key );
    key.key_pressed.connect( (keyval, keycode, state) => {
      var control = (bool)(state & ModifierType.CONTROL_MASK);
      if( control ) {
        switch( keyval ) {
          case 99    :  action_copy();    break;
          case 118   :  action_paste();   break;
          case 120   :  action_cut();     break;
          default    :  return( false );
        }
      } else {
        switch( keyval ) {
          case 65293 :  action_apply();   break;
          case 65307 :  action_cancel();  break;
          case 65535 :  action_delete();  break;
          default    :  return( false );
        }
      }
      return( true );
    });

    /* Update the UI state whenever the mouse enters the popover area */
    var motion = new EventControllerMotion();
    box.add_controller( motion );
    motion.enter.connect((x, y) => {
      update_ui();
    });

    /* Initialize the past button state */
    update_ui();

  }

  //-------------------------------------------------------------
  // Create the image editing area
  public DrawingArea create_drawing_area( ImageManager im ) {

    var da = new DrawingArea() {
      width_request  = EDIT_WIDTH,
      height_request = EDIT_HEIGHT
    };

    da.set_draw_func((d, ctx, w, h) => {
      draw_image( ctx );
    });

    /*
     Make sure that we add a CSS class name to ourselves so we can color
     our background with the theme.
    */
    da.add_css_class( "canvas" );

    var click = new GestureClick();
    da.add_controller( click );
    click.pressed.connect((n_press, x, y) => {
      var scaled_x = x / _scale;
      var scaled_y = y / _scale;
      set_crop_target( scaled_x, scaled_y );
      if( _crop_target == 8 ) {
        da.set_cursor( new Gdk.Cursor.from_name( "grabbing", null ) );
      }
      _press_x = scaled_x;
      _press_y = scaled_y;
    });

    click.released.connect((n_press, x, y) => {
      _crop_target = -1;
      set_cursor( null );
    });

    var motion = new EventControllerMotion();
    da.add_controller( motion );
    motion.motion.connect((x, y) => {
      var scaled_x = (x / _scale);
      var scaled_y = (y / _scale);
      if( _crop_target == -1 ) {
        set_crop_target( scaled_x, scaled_y );
        if( (_crop_target >= 0) && (_crop_target < 8) ) {
          set_cursor( _crop_cursors[_crop_target] );
        } else {
          set_cursor( null );
        }
        _crop_target = -1;
      } else {
        adjust_crop_points( (scaled_x - _press_x), (scaled_y - _press_y) );
        da.queue_draw();
      }
      set_cursor_location( (int)scaled_x, (int)scaled_y );
    });

    /* Set ourselves up to be a drag target */
    var drop = new DropTarget( typeof(File), Gdk.DragAction.COPY );
    da.add_controller( drop );
    drop.drop.connect((val, x, y) => {
      var file = (File)val;
      var ni   = new NodeImage.from_uri( im, file.get_uri(), _node.style.node_width );
      return( (ni != null) && initialize( ni ) );
    });

    return( da );

  }

  //-------------------------------------------------------------
  // Creates the status area
  private Box create_status_area() {

    var box = new Box( Orientation.HORIZONTAL, 10 ) {
      homogeneous = true
    };

    _status_cursor = new Label( null );
    _status_crop   = new Label( null );

    box.append( _status_cursor );
    box.append( _status_crop );

    return( box );

  }

  //-------------------------------------------------------------
  // Updates the cursor location status with the given values
  private void set_cursor_location( int x, int y ) {
    _status_cursor.label = _( "Cursor: %3d,%3d" ).printf( x, y );
  }

  //-------------------------------------------------------------
  // Creates the button bar at the bottom of the window
  private Box create_buttons( DrawArea da, ImageManager im ) {

    var open = new Button.from_icon_name( "folder-open-symbolic" ) {
      halign         = Align.START,
      tooltip_markup = Utils.tooltip_with_accel( _( "Change Image" ), "<Control>o" )
    };
    var paste = new Button.from_icon_name( "edit-paste-symbolic" ) {
      halign         = Align.START,
      tooltip_markup = Utils.tooltip_with_accel( _( "Paste Image from Clipboard" ), "<Control>v" )
    };
    var del = new Button.from_icon_name( "edit-delete-symbolic" ) {
      halign         = Align.START,
      tooltip_markup = Utils.tooltip_with_accel( _( "Remove Image" ), "Delete" )
    };
    var copy = new Button.from_icon_name( "edit-copy-symbolic" ) {
      halign         = Align.START,
      tooltip_markup = Utils.tooltip_with_accel( _( "Copy Image to Clipboard" ), "<Control>c" )
    };
    var cut = new Button.from_icon_name( "edit-cut-symbolic" ) {
      halign         = Align.START,
      hexpand        = true,
      tooltip_markup = Utils.tooltip_with_accel( _( "Cut Image to Clipboard" ), "<Control>x" )
    };

    var cancel = new Button.with_label( _( "Cancel" ) ) {
      halign = Align.END
    };
    var apply = new Button.with_label( _( "Apply" ) ) {
      halign = Align.END
    };

    _paste = paste;

    open.clicked.connect(() => {
      im.choose_image( da.win, (id) => {
        var ni = new NodeImage( im, id, _node.style.node_width );
        if( ni != null ) {
          initialize( ni );
        }
      });
    });

    cancel.clicked.connect( action_cancel );
    apply.clicked.connect(  action_apply );
    copy.clicked.connect( action_copy );
    cut.clicked.connect(  action_cut );
    paste.clicked.connect( action_paste );
    del.clicked.connect( action_delete );

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( open );
    box.append( paste );
    box.append( del );
    box.append( copy );
    box.append( cut );
    box.append( cancel );
    box.append( apply );

    return( box );

  }

  //-------------------------------------------------------------
  // Sets the cursor of the drawing area
  private void set_cursor( string? cursor_name = null ) {

    var cursor = _da.get_cursor();

    if( cursor_name == null ) {
      _da.set_cursor( null );
    } else if( (cursor == null) || (cursor.name != cursor_name) ) {
      _da.set_cursor( new Gdk.Cursor.from_name( cursor_name, null ) );
    }

  }

  //-------------------------------------------------------------
  // Add the image
  private void draw_image( Context ctx ) {

    // Set the scale
    ctx.scale( _scale, _scale );

    // Draw the cropped portion of the image
    cairo_set_source_pixbuf( ctx, _image.get_orig_pixbuf(), 0, 0 );
    ctx.paint();

    // On top of that, draw the crop transparency
    ctx.set_source_rgba( 0, 0, 0, 0.8 );
    ctx.rectangle( 0, 0, _da.width_request, _da.height_request );
    ctx.fill();

    // Cut out the area for the image
    ctx.set_operator( Operator.CLEAR );
    ctx.rectangle( (int)_crop_x, (int)_crop_y, (int)_crop_w, (int)_crop_h );
    ctx.fill();

    // Finally, draw the portion of the image this not cropped
    ctx.set_operator( Operator.OVER );
    cairo_set_source_pixbuf( ctx, _image.get_orig_pixbuf(), 0, 0 );
    ctx.rectangle( (int)_crop_x, (int)_crop_y, (int)_crop_w, (int)_crop_h );
    ctx.fill();

    // Draw the crop points
    ctx.set_line_width( 1 );
    for( int i=0; i<8; i++ ) {
      draw_crop_point( ctx, _crop_points[i] );
    }

  }

  //-------------------------------------------------------------
  // Draws a single crop point at the given point with the given
  // width/height
  private void draw_crop_point( Context ctx, Gdk.Rectangle crop ) {

    ctx.set_source_rgb( 1, 1, 1 );
    ctx.rectangle( crop.x, crop.y, crop.width, crop.width );
    ctx.fill();

    ctx.set_source_rgb( 0, 0, 0 );
    ctx.rectangle( crop.x, crop.y, crop.width, crop.width );
    ctx.stroke();

  }

  //-------------------------------------------------------------
  // Removes the current image for the node
  private void remove_image( ImageManager im ) {

    // Create a copy of the current image before changing it
    var orig_image = _node.image;

    // Clear the node image
    _node.set_image( im, null );

    // Indicate that the image changed
    changed( orig_image );

    // Hide the popover
    _popover.popdown();

  }

  //-------------------------------------------------------------
  // Sets the node image to the edited image
  private void set_image( ImageManager im ) {

    // Create a copy of the current image before changing it
    var orig_image = _node.image;

    // Copy the crop
    _image.crop_x = (int)_crop_x;
    _image.crop_y = (int)_crop_y;
    _image.crop_w = (int)_crop_w;
    _image.crop_h = (int)_crop_h;

    // Set the image width to match the node's max width
    _image.set_width( _node.style.node_width );

    // Set the node image
    _node.set_image( im, _image );

    // Indicate that the image changed
    changed( orig_image );

    // Close the popover
    _popover.popdown();

  }

  //-------------------------------------------------------------
  // Returns true if an image is pasteable from the clipboard
  private bool image_pasteable() {
    return( MinderClipboard.image_pasteable() );
  }

  //-------------------------------------------------------------
  // Updates the state of the UI
  private void update_ui() {
    _paste.set_sensitive( image_pasteable() );
  }

  //-------------------------------------------------------------
  // Copies the current image to the clipboard
  private void action_copy() {
    var fname = _im.get_file( _node.image.id );
    if( fname != null ) {
      try {
        var buf = new Gdk.Pixbuf.from_file( fname );
        MinderClipboard.copy_image( buf );
        update_ui();
      } catch( Error e ) {}
    }
  }

  //-------------------------------------------------------------
  // Copies the image to the clipboard and removes the current image
  private void action_cut() {
    action_copy();
    remove_image( _im );
  }

  /* Pastes the image from the clipboard */
  private void action_paste() {
    if( image_pasteable() ) {
      var clipboard = Display.get_default().get_clipboard();
      clipboard.read_texture_async.begin( null, (ob, res) => {
        try {
          var texture = clipboard.read_texture_async.end( res );
          if( texture != null ) {
            var buf   = Utils.texture_to_pixbuf( texture );
            var image = new NodeImage.from_pixbuf( _im, buf, _node.style.node_width );
            _image = image;
            _da.queue_draw();
          }
        } catch( Error e ) {}
      });
    } else {
      update_ui();
    }
  }

  //-------------------------------------------------------------
  // Deletes the current image
  private void action_delete() {
    remove_image( _im );
  }

  //-------------------------------------------------------------
  // Cancels this editing session
  private void action_cancel() {
    _popover.popdown();
  }

  //-------------------------------------------------------------
  // Applies the current edits and closes the window
  private void action_apply() {
    set_image( _im );
  }

}

