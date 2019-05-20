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

using GLib.Math;

public class Bezier {

  private class Point {
    public double x { set; get; default = 0; }
    public double y { set; get; default = 0; }
    public Point() {}
    public Point.with_coordinate( double a, double b ) {
      x = a;
      y = b;
    }
    public void set_coordinate( double a, double b ) {
      x = a;
      y = b;
    }
  }

  private Array<Point> _points  = new Array<Point>();
  private Array<Point> _apoints = new Array<Point>();
  private Point        _from    = new Point();
  private Point        _to      = new Point();

  /* Default constructor */
  public Bezier() {
    for( int i=0; i<3; i++ ) {
      _points.append_val( new Point() );
      _apoints.append_val( new Point() );
    }
  }

  /* Default constructor */
  public Bezier.with_endpoints( double x0, double y0, double x1, double y1 ) {
    for( int i=0; i<3; i++ ) {
      _points.append_val( new Point() );
      _apoints.append_val( new Point() );
    }
    _points.index( 0 ).set_coordinate( x0, y0 );
    _points.index( 1 ).set_coordinate( ((x0 + x1) * 0.5), ((y0 + y1) * 0.5) );
    _points.index( 2 ).set_coordinate( x1, y1 );
  }

  /* Copies to this curve from the given curve */
  public void copy( Bezier b ) {
    for( int i=0; i<3; i++ ) {
      _points.index( i ).set_coordinate( b._points.index( i ).x, b._points.index( i ).y );
      _apoints.index( i ).set_coordinate( b._apoints.index( i ).x, b._apoints.index( i ).y );
    }
    _from.set_coordinate( b._from.x, b._from.y );
    _to.set_coordinate( b._to.x, b._to.y );
  }

  /* Returns the point at the given index */
  public void get_point( int pindex, out double x, out double y ) {
    x = _points.index( pindex ).x;
    y = _points.index( pindex ).y;
  }

  public void get_from_point( out double x, out double y ) {
    x = _from.x;
    y = _from.y;
  }

  public void get_to_point( out double x, out double y ) {
    x = _to.x;
    y = _to.y;
  }

  /* Update the given point */
  public void set_point( int pindex, double x, double y ) {
    _points.index( pindex ).set_coordinate( x, y );
  }

  public void update_control_from_drag_handle( double x, double y ) {
    var cx = x - (((_points.index( 0 ).x + _points.index( 2 ).x) * 0.5) - x);
    var cy = y - (((_points.index( 0 ).y + _points.index( 2 ).y) * 0.5) - y);
    set_point( 1, cx, cy );
  }

  /* Returns true if the given t value is within its valid range */
  private bool is_t_within_range( double t ) {
    return( (0 <= t) && (t <= 1) );
  }

  /* Aligns the given point, returning a newly allocated one */
  private void align_point( int pindex, double a, double tx, double ty ) {
    double x = (_points.index( pindex ).x - tx) * cos( a ) - (_points.index( pindex ).y - ty) * sin( a );
    double y = (_points.index( pindex ).x - tx) * sin( a ) + (_points.index( pindex ).y - ty) * cos( a );
    _apoints.index( pindex ).set_coordinate( x, y );
  }

  /* Rotates the curve with the given line to get them into alignment for easier calculations */
  private void align( double lx0, double ly0, double lx1, double ly1 ) {

    var tx = lx0;
    var ty = ly0;
    var a  = -atan2( (ly1 - ty), (lx1 - tx) );

    for( int i=0; i<3; i++ ) {
      align_point( i, a, tx, ty );
    }

  }

  /* Calculates the roots for the given quadratic curve */
  private void get_roots( double axis, bool axis_is_x, ref Array<double?> roots ) {

    double lx0 = axis_is_x ? axis    : 0;
    double ly0 = axis_is_x ? 0       : axis;
    double lx1 = axis_is_x ? axis    : 1000000;
    double ly1 = axis_is_x ? 1000000 : axis;
    align( lx0, ly0, lx1, ly1 );

    double a = _apoints.index( 0 ).y;
    double b = _apoints.index( 1 ).y;
    double c = _apoints.index( 2 ).y;
    double d = a - 2 * b + c;

    if( d != 0 ) {
      var m1 = -sqrt( b * b - a * c );
      var m2 = -a + b;
      var v1 = -(m1 + m2) / d;
      var v2 = -(-m1 + m2) / d;
      if( is_t_within_range( v1 ) ) roots.append_val( v1 );
      if( is_t_within_range( v2 ) ) roots.append_val( v2 );
    } else if( b != c ) {
      var v = ((2 * b) - c) / (2 * (b - c));
      if( is_t_within_range( v ) ) roots.append_val( v );
    }

  }

  private double get_axis( double t, bool axis_is_x ) {

    double mt   = (1 - t);
    double mt2  = mt * mt;
    double t2   = t * t;
    double a    = mt2;
    double b    = mt * t * 2;
    double c    = t2;
    double axis = a * (axis_is_x ? _points.index( 0 ).y : _points.index( 0 ).x) +
                  b * (axis_is_x ? _points.index( 1 ).y : _points.index( 1 ).x) +
                  c * (axis_is_x ? _points.index( 2 ).y : _points.index( 2 ).x);

    return( axis );

  }

  /* Returns true if the given point is within close proximity to this curve */
  public bool within_range( double x, double y ) {

    Array<double?> roots     = new Array<double?>();
    double         tolerance = 10;

    /* Let's start by looking at the X axis */
    get_roots( x, true, ref roots );

    if( roots.length > 0 ) {
      for( int i=0; i<roots.length; i++ ) {
        double curve_y = get_axis( roots.index( i ), true );
        if( ((curve_y - tolerance) <= y) && (y <= (curve_y + tolerance)) ) {
          return( true );
        }
      }
    }

    /* Let's take a look at the Y axis */
    roots.remove_range( 0, roots.length );
    get_roots( y, false, ref roots );

    for( int i=0; i<roots.length; i++ ) {
      double curve_x = get_axis( roots.index( i ), false );
      if( ((curve_x - tolerance) <= x) && (x <= (curve_x + tolerance)) ) {
        return( true );
      }
    }

    return( false );

  }

  /* Returns the intersecting point */
  public double get_intersecting_point( double axis, bool axis_is_x, bool from ) {

    Array<double?> roots = new Array<double?>();

    get_roots( axis, axis_is_x, ref roots );

    switch( roots.length ) {
      case 0  :  return( -1 );
      case 1  :
        return( get_axis( roots.index( 0 ), axis_is_x ) );
      default :
        if( from ) {
          double max = 1000000;
          for( int i=0; i<roots.length; i++ ) {
            if( roots.index( i ) < max ) {
              max = roots.index( i );
            }
          }
          return( get_axis( max, axis_is_x ) );
        } else {
          double min = 0;
          for( int i=0; i<roots.length; i++ ) {
            if( roots.index( i ) > min ) {
              min = roots.index( i );
            }
          }
          return( get_axis( min, axis_is_x ) );
        }
    }

  }

  /* Given the bounds of a box, calculate the connection point to the box and store it locally */
  public void set_connect_point( bool from, double top, double bottom, double left, double right ) {

    double isect;

    /* Check the top of the node */
    isect = get_intersecting_point( top, false, from );
    if( (left <= isect) && (isect <= right) ) {
      if( from ) { _from.set_coordinate( isect, top ); } else { _to.set_coordinate( isect, top ); }
      return;
    }

    /* Check the bottom of the node */
    isect = get_intersecting_point( bottom, false, from );
    if( (left <= isect) && (isect <= right) ) {
      if( from ) { _from.set_coordinate( isect, bottom ); } else { _to.set_coordinate( isect, bottom ); }
      return;
    }

    /* Check the left side of the node */
    isect = get_intersecting_point( left, true, from );
    if( (top <= isect) && (isect <= bottom) ) {
      if( from ) { _from.set_coordinate( left, isect ); } else { _to.set_coordinate( left, isect ); }
      return;
    }

    /* Check the right side of the node */
    isect = get_intersecting_point( right, true, from );
    if( (top <= isect) && (isect <= bottom) ) {
      if( from ) { _from.set_coordinate( right, isect ); } else { _to.set_coordinate( right, isect ); }
      return;
    }

    if( from ) {
      _from.set_coordinate( _points.index( 0 ).x, _points.index( 0 ).y );
    } else {
      _to.set_coordinate( _points.index( 2 ).x, _points.index( 2 ).y );
    }

  }

}
