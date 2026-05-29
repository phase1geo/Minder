/*
* Copyright (c) 2024-2026 (https://github.com/phase1geo/MosaicNote)
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

using Gdk;

public enum SequenceNumType {
  NUM,
  LETTER;

  public string to_string( int index ) {
    switch( this ) {
      case NUM    :  return( "%d".printf( index + 1 ) );
      case LETTER :  return( "%c".printf( 'a' + index ) );
      default     :  return( "" );
    }
  }
}

public class SequenceNum {

  private Pango.Layout _layout;
  private int          _font_size = 12;

  public double          width    { get; private set; default = 0.0; }
  public double          height   { get; private set; default = 0.0; }
  public SequenceNumType seq_type { get; private set; default = SequenceNumType.NUM; }

  public Pango.Layout layout {
    get {
      return( _layout );
    }
  }

  //-------------------------------------------------------------
  // Default constructor
  public SequenceNum( MindMap map ) {
    _layout = map.canvas.create_pango_layout( "1" );
    initialize_font();
  }

  //-------------------------------------------------------------
  // Initializes the font family and size used for displaying the
  // sequence number.  Should only be called from the constructor.
  private void initialize_font() {
    var fd = new Pango.FontDescription();
    fd.set_size( _font_size * Pango.SCALE );
    _layout.set_font_description( fd );
  }

  //-------------------------------------------------------------
  // Sets the font of the sequence number to the given font type
  // and size.
  public void set_font( string? family = null, int? size = null, double zoom_factor = 1.0 ) {

    var fd = _layout.get_font_description();
    if( family != null ) {
      fd.set_family( family );
    }
    if( size != null ) {
      _font_size = size;
    }
    var int_fsize = (int)((_font_size * zoom_factor) * Pango.SCALE);
    fd.set_size( int_fsize );
    _layout.set_font_description( fd );
    update_size();

  }

  //-------------------------------------------------------------
  // Sets the sequence number to the given value.
  public void set_num( int index, SequenceNumType type ) {

    seq_type = type;

    var numstr    = "%s. ".printf( type.to_string( index ) );
    var attr_list = new Pango.AttrList();
    var bold      = Pango.attr_weight_new( Pango.Weight.ULTRABOLD );
    bold.start_index = 0;
    bold.end_index   = numstr.length;
    attr_list.change( (owned)bold );

    _layout.set_text( numstr, -1 );
    _layout.set_attributes( attr_list );
    update_size();

  }

  //-------------------------------------------------------------
  // Updates the size information based on the current layout
  // settings.
  private void update_size() {

    int text_width, text_height;
    _layout.get_size( out text_width, out text_height );

    width  = (text_width  / Pango.SCALE);
    height = (text_height / Pango.SCALE);

  }

}
