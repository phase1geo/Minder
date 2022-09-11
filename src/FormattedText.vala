/*
* Copyright (c) 2020 (https://github.com/phase1geo/Outliner)
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

using Pango;
using Gdk;
using Gtk;
using Gee;

public enum FormatTag {
  BOLD = 0,
  ITALICS,
  UNDERLINE,
  STRIKETHRU,
  CODE,
  SUB,
  SUPER,
  HEADER,
  COLOR,
  HILITE,
  URL,
  SYNTAX,
  TAG,
  MATCH,
  SELECT,
  LENGTH;

  public string to_string() {
    switch( this ) {
      case BOLD       :  return( "bold" );
      case ITALICS    :  return( "italics" );
      case UNDERLINE  :  return( "underline" );
      case STRIKETHRU :  return( "strikethru" );
      case CODE       :  return( "code" );
      case SUB        :  return( "subscript" );
      case SUPER      :  return( "superscript" );
      case HEADER     :  return( "header" );
      case COLOR      :  return( "color" );
      case HILITE     :  return( "hilite" );
      case URL        :  return( "url" );
      case TAG        :  return( "tag" );
      case SYNTAX     :  return( "syntax" );
      case MATCH      :  return( "match" );
    }
    return( "bold" );
  }

  public static FormatTag from_string( string str ) {
    switch( str ) {
      case "bold"        :  return( BOLD );
      case "italics"     :  return( ITALICS );
      case "underline"   :  return( UNDERLINE );
      case "strikethru"  :  return( STRIKETHRU );
      case "code"        :  return( CODE );
      case "subscript"   :  return( SUB );
      case "superscript" :  return( SUPER );
      case "header"      :  return( HEADER );
      case "color"       :  return( COLOR );
      case "hilite"      :  return( HILITE );
      case "url"         :  return( URL );
      case "tag"         :  return( TAG );
      case "syntax"      :  return( SYNTAX );
      case "match"       :  return( MATCH );
    }
    return( LENGTH );
  }

}

/* Stores information for undo/redo operation on tags */
public class UndoTagInfo {
  public int     start  { private set; get; }
  public int     end    { private set; get; }
  public int     tag    { private set; get; }
  public bool    parsed { private set; get; }
  public string? extra  { private set; get; }
  public UndoTagInfo( int tag, int start, int end, string? extra, bool parsed ) {
    this.tag    = tag;
    this.start  = start;
    this.end    = end;
    this.parsed = parsed;
    this.extra  = extra;
  }
  public string to_string() {
    return( "tag: %s, start: %d, end: %d, extra: %s, parsed: %s".printf( tag.to_string(), start, end, extra, parsed.to_string() ) );
  }
}


public class FormattedText {

  private class TagInfo {

    public class FormattedRange {
      public int     start  { get; set; default = 0; }
      public int     end    { get; set; default = 0; }
      public bool    parsed { get; set; default = false; }
      public string? extra  { get; set; default = null; }
      public FormattedRange( int s, int e, string? x, bool p ) {
        start  = s;
        end    = e;
        extra  = x;
        parsed = p;
      }
      public FormattedRange.from_xml( Xml.Node* n ) {
        load( n );
      }
      public bool combine( int s, int e, string? x ) {
        bool changed = false;
        if( (x != null) && (x != extra) ) {
          return( false );
        }
        if( (s <= end) && (e > end) ) {
          end     = e;
          changed = true;
        }
        if( (s < start) && (e >= start) ) {
          start   = s;
          changed = true;
        }
        return( changed );
      }
      public Xml.Node* save() {
        Xml.Node* n = new Xml.Node( null, "range" );
        n->set_prop( "start", start.to_string() );
        n->set_prop( "end",   end.to_string() );
        if( extra != null ) {
          n->set_prop( "extra", extra );
        }
        return( n );
      }
      public void load( Xml.Node* n ) {
        string? s = n->get_prop( "start" );
        if( s != null ) {
          start = int.parse( s );
        }
        string? e = n->get_prop( "end" );
        if( e != null ) {
          end = int.parse( e );
        }
        extra = n->get_prop( "extra" );
      }
      public static int compare( void* x, void* y ) {
     		 FormattedRange** x1 = (FormattedRange**)x;
       	FormattedRange** y1 = (FormattedRange**)y;
        return( (int)((*x1)->start > (*y1)->start) - (int)((*x1)->start < (*y1)->start) );
      }
    }

    private Array<FormattedRange> _info;

    public Array<FormattedRange> info {
      get {
        return( _info );
      }
    }

    /* Default constructor */
    public TagInfo() {
      _info = new Array<FormattedRange>();
    }

    /* Copies the given TagInfo structure to this one */
    public void copy( TagInfo other ) {
      _info.remove_range( 0, _info.length );
      for( int i=0; i<other._info.length; i++ ) {
        var other_info = other._info.index( i );
        _info.append_val( new FormattedRange( other_info.start, other_info.end, other_info.extra, other_info.parsed ) );
      }
    }

    /* Returns true if this info array is empty */
    public bool is_empty() {
      return( _info.length == 0 );
    }

    /* Returns true if we have at least one unparsed range */
    public bool save_needed() {
      for( int i=0; i<_info.length; i++ ) {
        if( !_info.index( i ).parsed ) {
          return( true );
        }
      }
      return( false );
    }

    public void adjust( int index, int length ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        if( index <= info.start ) {
          info.start += length;
          info.end   += length;
          if( info.end <= index ) {
            _info.remove_index( i );
          }
        } else if( index < info.end ) {
          info.end += length;
        }
      }
    }

    /* Adds the given range from this format type */
    public void add_tag( int start, int end, string? extra, bool parsed ) {
      for( int i=0; i<_info.length; i++ ) {
        if( _info.index( i ).combine( start, end, extra ) ) {
          return;
        }
      }
      _info.append_val( new FormattedRange( start, end, extra, parsed ) );
      _info.sort( (CompareFunc)FormattedRange.compare );
    }

    /* Adds the given TagInfo contents to the existing list */
    public void add_tags_at_offset( TagInfo other, int offset ) {
      for( int i=0; i<other._info.length; i++ ) {
        var other_info = other._info.index( i );
        add_tag( (other_info.start + offset), (other_info.end + offset), other_info.extra, other_info.parsed );
      }
    }

    /* Replaces the given range(s) with the given range */
    public void replace_tag( int start, int end, string? extra, bool parsed ) {
      _info.remove_range( 0, _info.length );
      _info.append_val( new FormattedRange( start, end, extra, parsed ) );
      _info.sort( (CompareFunc)FormattedRange.compare );
    }

    /* Removes the given range from this format type */
    public void remove_tag( int start, int end ) {
      for( int i=((int)_info.length - 1); i>=0; i-- ) {
        var info = _info.index( i );
        if( (start < info.end) && (end > info.start) ) {
          if( start <= info.start ) {
            if( info.end <= end ) {
              _info.remove_index( i );
            } else {
              info.start = end;
            }
          } else {
            if( info.end > end ) {
              _info.append_val( new FormattedRange( end, info.end, info.extra, info.parsed ) );
            }
            info.end = start;
          }
        }
      }
      _info.sort( (CompareFunc)FormattedRange.compare );
    }

    /* Removes all ranges for this tag */
    public void remove_tag_all() {
      _info.remove_range( 0, _info.length );
    }

    /* Removes all tags added due to parsing */
    public void remove_parsed_tags() {
      for( int i=(int)(_info.length - 1); i>=0; i-- ) {
        if( _info.index( i ).parsed ) {
          _info.remove_index( i );
        }
      }
    }

    /*
     Returns true if the text contains a tag that matches the given extra information.
     If extra is set to the empty string, returns true if there are any tags of this
     type.
    */
    public bool contains_tag( string extra ) {
      if( extra == "" ) {
        return( _info.length > 0 );
      } else {
        for( int i=0; i<_info.length; i++ ) {
          if( _info.index( i ).extra == extra ) {
            return( true );
          }
        }
        return( false );
      }
    }

    /* Returns all of the extra values for this tag */
    public void get_extras_for_tag( ref HashMap<string,bool> extras ) {
      for( int i=0; i<_info.length; i++ ) {
        var extra = _info.index( i ).extra;
        if( !extras.has_key( extra ) ) {
          extras.@set( extra, true );
        }
      }
    }

    /* Returns the full tag ranges which overlap with the given range */
    public void get_full_tags_in_range( int tag, int start, int end, ref Array<UndoTagInfo> tags ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        if( (start < info.end) && (end > info.start) ) {
          tags.append_val( new UndoTagInfo( tag, info.start, info.end, info.extra, info.parsed ) );
        }
      }
    }

    /* Returns all tags found within the given range */
    public void get_tags_in_range( int tag, int start, int end, ref Array<UndoTagInfo> tags ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        if( (start < info.end) && (end > info.start) ) {
          var save_start = (info.start < start) ? start : info.start;
          var save_end   = (info.end   > end)   ? end   : info.end;
          tags.append_val( new UndoTagInfo( tag, (save_start - start), (save_end - start), info.extra, info.parsed ) );
        }
      }
    }

    /* Returns true if the given index contains this tag */
    public bool is_applied_at_index( int index ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        if( (info.start <= index) && (index < info.end) ) {
          return( true );
        }
      }
      return( false );
    }

    /*
     Returns true if the given range overlaps with any tag; otherwise,
     returns false.
    */
    public bool is_applied_in_range( int start, int end ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        if( (start < info.end) && (end > info.start) ) {
          return( true );
        }
      }
      return( false );
    }

    /* Inserts all of the attributes for this tag */
    public void get_attributes( TagAttr tag_attr, ref AttrList attrs ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        tag_attr.add_attrs( ref attrs, info.start, info.end, info.extra );
      }
    }

    /* Returns the extra data associated with the given cursor position */
    public string? get_extra( int index ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        if( (info.start <= index) && (index < info.end) ) {
          return( info.extra );
        }
      }
      return( null );
    }

    /* Returns the extra and parsed data associated with the given cursor position */
    public void get_extra_parsed( int index, out string? extra, out bool parsed ) {
      extra  = null;
      parsed = false;
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        if( (info.start <= index) && (index < info.end) ) {
          extra  = info.extra;
          parsed = info.parsed;
          return;
        }
      }
    }

    /* Returns the first extra value found within the given range */
    public string? get_first_extra_in_range( int start, int end ) {
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        if( (start < info.end) && (end > info.start) ) {
          return( info.extra );
        }
      }
      return( null );
    }

    /* Returns the list of ranges this tag is associated with */
    public Xml.Node* save( string tag ) {
      Xml.Node* n = new Xml.Node( null, tag );
      for( int i=0; i<_info.length; i++ ) {
        var info = _info.index( i );
        if( !info.parsed ) {
          n->add_child( info.save() );
        }
      }
      return( n );
    }

    /* Loads the data from XML */
    public void load( Xml.Node* n ) {
      for( Xml.Node* it = n->children; it != null; it = it->next ) {
        if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "range") ) {
          _info.append_val( new FormattedRange.from_xml( it ) );
        }
      }
    }

  }

  private class TagAttr {
    public Array<Pango.Attribute> attrs;
    public TagAttr() {
      attrs = new Array<Pango.Attribute>();
    }
    public TagAttr.copy_from( TagAttr ta ) {
      attrs = new Array<Pango.Attribute>();
      for( int i=0; i<ta.attrs.length; i++ ) {
        attrs.append_val( ta.attrs.index( i ).copy() );
      }
    }
    public virtual void add_attrs( ref AttrList list, int start, int end, string? extra ) {
      for( int i=0; i<attrs.length; i++ ) {
        var attr = attrs.index( i ).copy();
        attr.start_index = start;
        attr.end_index   = end;
        list.change( (owned)attr );
      }
    }
    public virtual TextTag text_tag( string? extra ) {
      return( new TextTag() );
    }
    protected RGBA get_color( string value ) {
      RGBA c = {1.0, 1.0, 1.0, 1.0};
      c.parse( value );
      return( c );
    }
  }

  private class BoldInfo : TagAttr {
    public BoldInfo() {
      attrs.append_val( attr_weight_new( Weight.BOLD ) );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "bold" );
      ttag.weight     = Weight.BOLD;
      ttag.weight_set = true;
      return( ttag );
    }
  }

  private class ItalicsInfo : TagAttr {
    public ItalicsInfo() {
      attrs.append_val( attr_style_new( Pango.Style.ITALIC ) );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "italics" );
      ttag.style     = Pango.Style.ITALIC;
      ttag.style_set = true;
      return( ttag );
    }
  }

  private class UnderlineInfo : TagAttr {
    public UnderlineInfo() {
      attrs.append_val( attr_underline_new( Underline.SINGLE ) );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "underline" );
      ttag.underline     = Underline.SINGLE;
      ttag.underline_set = true;
      return( ttag );
    }
  }

  private class StrikeThruInfo : TagAttr {
    public StrikeThruInfo() {
      attrs.append_val( attr_strikethrough_new( true ) );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "strikethru" );
      ttag.strikethrough     = true;
      ttag.strikethrough_set = true;
      return( ttag );
    }
  }

  private class CodeInfo : TagAttr {
    public CodeInfo( DrawArea da ) {
      attrs.append_val( attr_family_new( "Monospace" ) );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "code" );
      ttag.family     = "Monospace";
      ttag.family_set = true;
      return( ttag );
    }
  }

  private class SubInfo : TagAttr {
    public SubInfo() {
      attrs.append_val( attr_rise_new( 0 - (4 * Pango.SCALE) ) );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "subscript" );
      ttag.rise     = 0 - (4 * Pango.SCALE);
      ttag.rise_set = true;
      return( ttag );
    }
  }

  private class SuperInfo : TagAttr {
    public SuperInfo() {
      attrs.append_val( attr_rise_new( 4 * Pango.SCALE ) );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "superscript" );
      ttag.rise     = (4 * Pango.SCALE);
      ttag.rise_set = true;
      return( ttag );
    }
  }

  private class HeaderInfo : TagAttr {
    public HeaderInfo() {}
    private double get_scale_factor( string? extra ) {
      switch( extra ) {
        case "1" :  return( 2.1 );
        case "2" :  return( 1.8 );
        case "3" :  return( 1.5 );
        case "4" :  return( 1.3 );
        case "5" :  return( 1.2 );
        case "6" :  return( 1.1 );
        default  :  return( 1.1 );
      }
    }
    public override void add_attrs( ref AttrList list, int start, int end, string? extra ) {
      var scale = attr_scale_new( get_scale_factor( extra ) );
      var bold  = attr_weight_new( Weight.BOLD );
      scale.start_index = start;
      scale.end_index   = end;
      list.change( (owned)scale );
      bold.start_index = start;
      bold.end_index   = end;
      list.change( (owned)bold );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "header" + extra );
      ttag.scale     = get_scale_factor( extra );
      ttag.scale_set = true;
      return( ttag );
    }
  }

  private class ColorInfo : TagAttr {
    public ColorInfo() {}
    public override void add_attrs( ref AttrList list, int start, int end, string? extra ) {
      var color = get_color( extra );
      var attr  = attr_foreground_new( (uint16)(color.red * 65535), (uint16)(color.green * 65535), (uint16)(color.blue * 65535) );
      attr.start_index = start;
      attr.end_index   = end;
      list.change( (owned)attr );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "color" + extra );
      ttag.foreground_rgba = get_color( extra );
      ttag.foreground_set  = true;
      return( ttag );
    }
  }

  private class HighlightInfo : TagAttr {
    public HighlightInfo() {}
    public override void add_attrs( ref AttrList list, int start, int end, string? extra ) {
      var color = get_color( extra );
      var bg    = attr_background_new( (uint16)(color.red * 65535), (uint16)(color.green * 65535), (uint16)(color.blue * 65535) );
      var alpha = attr_background_alpha_new( (uint16)(65536 * 0.5) );
      bg.start_index = start;
      bg.end_index   = end;
      list.change( (owned)bg );
      alpha.start_index = start;
      alpha.end_index   = end;
      list.change( (owned)alpha );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "hilite" + extra );
      ttag.background_rgba = get_color( extra );
      ttag.background_set  = true;
      return( ttag );
    }
  }

  private class UrlInfo : TagAttr {
    private RGBA _color;
    public UrlInfo( RGBA color ) {
      set_color( color );
    }
    private void set_color( RGBA color ) {
      attrs.append_val( attr_foreground_new( (uint16)(color.red * 65535), (uint16)(color.green * 65535), (uint16)(color.blue * 65535) ) );
      attrs.append_val( attr_underline_new( Underline.SINGLE ) );
      _color = color.copy();
    }
    public void update_color( RGBA color ) {
      attrs.remove_range( 0, 2 );
      set_color( color );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "url" );
      ttag.foreground      = Utils.color_from_rgba( _color );
      ttag.underline       = Underline.SINGLE;
      ttag.foreground_set  = true;
      ttag.underline_set   = true;
      return( ttag );
    }
  }

  private class TaggingInfo : TagAttr {
    private RGBA _color;
    public TaggingInfo( RGBA color ) {
      set_color( color );
    }
    private void set_color( RGBA color ) {
      attrs.append_val( attr_foreground_new( (uint16)(color.red * 65535), (uint16)(color.green * 65535), (uint16)(color.blue * 65535) ) );
      _color = color.copy();
    }
    public void update_color( RGBA color ) {
      attrs.remove_range( 0, 1 );
      set_color( color );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "tag" );
      ttag.foreground     = Utils.color_from_rgba( _color );
      ttag.foreground_set = true;
      return( ttag );
    }
  }

  private class SyntaxInfo : TagAttr {
    private RGBA _color;
    private bool _hide;
    public SyntaxInfo( RGBA color, bool hide ) {
      set_color( color, hide );
    }
    private void set_color( RGBA color, bool hide ) {
      attrs.append_val( attr_foreground_new( (uint16)(color.red * 65535), (uint16)(color.green * 65535), (uint16)(color.blue * 65535) ) );
      attrs.append_val( attr_foreground_alpha_new( hide ? 20000 : 65535 ) );
      _color = color.copy();
      _hide = hide;
    }
    public void update_color( RGBA color ) {
      attrs.remove_range( 0, 2 );
      set_color( color, _hide );
    }
    public override TextTag text_tag( string? extra ) {
      var ttag = new TextTag( "syntax" );
      if( _hide ) {
        ttag.invisible      = true;
        ttag.invisible_set  = true;
      } else {
        ttag.foreground     = Utils.color_from_rgba( _color );
        ttag.foreground_set = true;
      }
      return( ttag );
    }
  }

  private class MatchInfo : TagAttr {
    public MatchInfo( RGBA f, RGBA b ) {
      set_color( f, b );
    }
    private void set_color( RGBA f, RGBA b ) {
      attrs.append_val( attr_foreground_new( (uint16)(f.red * 65535), (uint16)(f.green * 65535), (uint16)(f.blue * 65535) ) );
      attrs.append_val( attr_background_new( (uint16)(b.red * 65535), (uint16)(b.green * 65535), (uint16)(b.blue * 65535) ) );
    }
    public void update_color( RGBA f, RGBA b ) {
      attrs.remove_range( 0, 2 );
      set_color( f, b );
    }
  }

  private class SelectInfo : TagAttr {
    public SelectInfo( RGBA f, RGBA b ) {
      set_color( f, b );
    }
    private void set_color( RGBA f, RGBA b ) {
      attrs.append_val( attr_foreground_new( (uint16)(f.red * 65535), (uint16)(f.green * 65535), (uint16)(f.blue * 65535) ) );
      attrs.append_val( attr_background_new( (uint16)(b.red * 65535), (uint16)(b.green * 65535), (uint16)(b.blue * 65535) ) );
    }
    public void update_color( RGBA f, RGBA b ) {
      attrs.remove_range( 0, 2 );
      set_color( f, b );
    }
  }

  private static TagAttr[]  _attr_tags = null;
  private TagInfo[]         _formats   = new TagInfo[FormatTag.LENGTH];
  private string            _text      = "";
  private Array<TextParser> _parsers   = new Array<TextParser>();

  public signal void changed();

  public string text {
    get {
      return( _text );
    }
  }

  /* Default copy constructor */
  public FormattedText( DrawArea da ) {
    initialize( da );
  }

  /* Copy contructor with a string */
  public FormattedText.with_text( DrawArea da, string txt ) {
    initialize( da );
    _text = txt;
  }

  /* Copies the selected portion of the given FormattedText instance to this instance */
  public FormattedText.copy_range( DrawArea da, FormattedText text, int start, int end ) {
    initialize( da );
    _text = text.text.slice( start, end );
    var tags = text.get_tags_in_range( start, end );
    for( int i=0; i<tags.length; i++ ) {
      var tag = tags.index( i );
      _formats[tag.tag].add_tag( (tag.start - start), (tag.end - start), tag.extra, tag.parsed );
    }
  }

  /* Creates a copy of the given text and removes all of the syntax characters */
  public FormattedText.copy_clean( DrawArea da, FormattedText other ) {
    initialize( da );
    _text = other._text;
    for( int i=0; i<FormatTag.LENGTH-3; i++ ) {
      _formats[i].copy( other._formats[i] );
    }
    var ranges = other._formats[FormatTag.SYNTAX].info;
    for( int i=(int)(ranges.length - 1); i>=0; i-- ) {
      var range = ranges.index( i );
      remove_text( range.start, (range.end - range.start) );
    }
  }

  /* Initializes this instance */
  private void initialize( DrawArea da ) {
    if( _attr_tags == null ) {
      var theme = da.get_theme();
      _attr_tags = new TagAttr[FormatTag.LENGTH];
      _attr_tags[FormatTag.BOLD]       = new BoldInfo();
      _attr_tags[FormatTag.ITALICS]    = new ItalicsInfo();
      _attr_tags[FormatTag.UNDERLINE]  = new UnderlineInfo();
      _attr_tags[FormatTag.STRIKETHRU] = new StrikeThruInfo();
      _attr_tags[FormatTag.CODE]       = new CodeInfo( da );
      _attr_tags[FormatTag.SUB]        = new SubInfo();
      _attr_tags[FormatTag.SUPER]      = new SuperInfo();
      _attr_tags[FormatTag.HEADER]     = new HeaderInfo();
      _attr_tags[FormatTag.COLOR]      = new ColorInfo();
      _attr_tags[FormatTag.HILITE]     = new HighlightInfo();
      _attr_tags[FormatTag.URL]        = new UrlInfo( theme.get_color( "url_foreground" ) );
      _attr_tags[FormatTag.TAG]        = new TaggingInfo( theme.get_color( "tag" ) );
      _attr_tags[FormatTag.SYNTAX]     = new SyntaxInfo( theme.get_color( "syntax" ), false );
      _attr_tags[FormatTag.MATCH]      = new MatchInfo( theme.get_color( "match_foreground" ), theme.get_color( "match_background" ) );
      _attr_tags[FormatTag.SELECT]     = new SelectInfo( theme.get_color( "textsel_foreground" ), theme.get_color( "textsel_background" ) );
    }
    for( int i=0; i<FormatTag.LENGTH; i++ ) {
      _formats[i] = new TagInfo();
    }
  }

  /* Called whenever the theme changes */
  public static void set_theme( Theme theme ) {
    if( _attr_tags == null ) return;
    (_attr_tags[FormatTag.URL] as UrlInfo).update_color( theme.get_color( "url_foreground" ) );
    (_attr_tags[FormatTag.TAG] as TaggingInfo).update_color( theme.get_color( "tag" ) );
    (_attr_tags[FormatTag.SYNTAX] as SyntaxInfo).update_color( theme.get_color( "syntax" ) );
    (_attr_tags[FormatTag.MATCH] as MatchInfo).update_color( theme.get_color( "match_foreground" ), theme.get_color( "match_background" ) );
    (_attr_tags[FormatTag.SELECT] as SelectInfo).update_color( theme.get_color( "textsel_foreground" ), theme.get_color( "textsel_background" ) );
  }

  /* Adds the given parser */
  public void add_parser( TextParser parser ) {
    _parsers.append_val( parser );
    parser.enable_changed.connect( handle_parser_enable_change );
    parse();
    changed();
  }

  /* Called whenever the user changes the enablement for one of its parsers */
  private void handle_parser_enable_change() {
    parse();
    changed();
  }

  /* Removes the specified parser */
  public void remove_parser( TextParser parser ) {
    for( int i=0; i<_parsers.length; i++ ) {
      if( _parsers.index( i ) == parser ) {
        parser.enable_changed.disconnect( handle_parser_enable_change );
        _parsers.remove_index( i );
        parse( true );
        changed();
        return;
      }
    }
  }

  /* Copies the specified FormattedText instance to this one */
  public void copy( FormattedText other ) {
    _text = other._text;
    for( int i=0; i<FormatTag.LENGTH; i++ ) {
      _formats[i].copy( other._formats[i] );
    }
    changed();
  }

  /* Initializes the text to the given value */
  public void set_text( string str ) {
    _text = str;
  }

  /* Appends a string to the end of the current text */
  public void append_text( string str ) {
    insert_text( _text.length, str );
  }

  /* Inserts a string into the given text */
  public void insert_text( int index, string str ) {
    _text = _text.splice( index, index, str );
    foreach( TagInfo f in _formats) {
      f.adjust( index, str.length );
    }
    parse();
    changed();
  }

  /* Appends the given string to this text */
  public void append_text( string str ) {
    insert_text( _text.length, str );
  }

  /* Inserts the formatted text at the given position */
  public void insert_formatted_text( int index, FormattedText text ) {
    insert_text( index, text.text );
    for( int i=0; i<FormatTag.LENGTH-2; i++ ) {
      _formats[i].add_tags_at_offset( text._formats[i], index );
    }
  }

  /* Replaces the given text range with the given string */
  public void replace_text( int index, int chars, string str ) {
    _text = _text.splice( index, (index + chars), str );
    foreach( TagInfo f in _formats ) {
      f.remove_tag( index, (index + chars) );
      f.adjust( index, ((0 - chars) + str.length) );
    }
    parse();
    changed();
  }

  /* Removes characters from the current text, starting at the given index */
  public void remove_text( int index, int chars ) {
    _text = _text.splice( index, (index + chars) );
    foreach( TagInfo f in _formats ) {
      f.remove_tag( index, (index + chars) );
      f.adjust( index, (0 - chars) );
    }
    parse();
    changed();
  }

  /* Adds the given tag */
  public void add_tag( FormatTag tag, int start, int end, bool parsed, string? extra=null ) {
    _formats[tag].add_tag( start, end, extra, parsed );
    changed();
  }

  /* Replaces the given tag with the given range */
  public void replace_tag( FormatTag tag, int start, int end, bool parsed, string? extra=null ) {
    _formats[tag].replace_tag( start, end, extra, parsed );
    changed();
  }

  /* Removes the given tag */
  public void remove_tag( FormatTag tag, int start, int end ) {
    _formats[tag].remove_tag( start, end );
    changed();
  }

  /* Removes all parsed ranges for the given tag */
  public void remove_parsed_tags( FormatTag tag ) {
    _formats[tag].remove_parsed_tags();
    changed();
  }

  /* Removes all parsed ranges for the given tag */
  public void remove_tag_all( FormatTag tag ) {
    _formats[tag].remove_tag_all();
    changed();
  }

  /* Removes all formatting from the text */
  public void remove_all_tags( int start, int end ) {
    for( int i=0; i<FormatTag.LENGTH-3; i++ ) {
      _formats[i].remove_tag( start, end );
    }
    changed();
  }

  /* Returns true if the given tag is applied at the given index */
  public bool is_tag_applied_at_index( FormatTag tag, int index ) {
    return( _formats[tag].is_applied_at_index( index ) );
  }

  /* Returns true if the given tag is applied within the given range */
  public bool is_tag_applied_in_range( FormatTag tag, int start, int end ) {
    return( _formats[tag].is_applied_in_range( start, end ) );
  }

  /* Returns true if at least one tag is applied to the text */
  public bool tags_exist() {
    foreach( TagInfo f in _formats ) {
      if( !f.is_empty() ) {
        return( true );
      }
    }
    return( false );
  }

  /*
   Returns true if the given tag and extra information is found within this
   text.
  */
  public bool contains_tag( FormatTag tag, string extra = "" ) {
    return( _formats[tag].contains_tag( extra ) );
  }

  /* Retrieves the extra values for all items marked with tag */
  public HashMap<string,bool> get_extras_for_tag( FormatTag tag ) {
    var extras = new HashMap<string,bool>();
    _formats[tag].get_extras_for_tag( ref extras );
    return( extras );
  }

  /* Returns the tag information of the given tag in the specified range */
  public Array<UndoTagInfo> get_full_tags_in_range( FormatTag tag, int start, int end ) {
    var tags = new Array<UndoTagInfo>();
    for( int i=0; i<FormatTag.LENGTH-4; i++ ) {
      _formats[i].get_full_tags_in_range( i, start, end, ref tags );
    }
    return( tags );
  }

  /* Returns an array containing all tags that are within the specified range */
  public Array<UndoTagInfo> get_tags_in_range( int start, int end ) {
    var tags = new Array<UndoTagInfo>();
    for( int i=0; i<FormatTag.LENGTH-4; i++ ) {
      _formats[i].get_tags_in_range( i, start, end, ref tags );
    }
    return( tags );
  }

  /* Reapplies tags that were previously removed */
  public void apply_tags( Array<UndoTagInfo> tags, int start = 0 ) {
    for( int i=((int)tags.length - 1); i>=0; i-- ) {
      var info = tags.index( i );
      _formats[info.tag].add_tag( (info.start + start), (info.end + start), info.extra, info.parsed );
    }
    changed();
  }

  /*
   Returns the Pango attribute list to apply to the Pango layout.  This
   method should only be called if tags_exist returns true.
  */
  public AttrList get_attributes() {
    var attrs = new AttrList();
    for( int i=0; i<FormatTag.LENGTH; i++ ) {
      _formats[i].get_attributes( _attr_tags[i], ref attrs );
    }
    return( attrs );
  }

  /*
   Same as the above method; however, it applies the given theme colors to the
   returns tags immediately without updating the main components.  This is useful
   for changing the theme for a temporary context.
  */
  public AttrList get_attributes_from_theme( Theme theme ) {
    var attrs = new AttrList();
    for( int i=0; i<(FormatTag.LENGTH-5); i++ ) {
      _formats[i].get_attributes( _attr_tags[i], ref attrs );
    }
    _formats[FormatTag.URL].get_attributes( new UrlInfo( theme.get_color( "url_foreground" ) ), ref attrs );
    _formats[FormatTag.SYNTAX].get_attributes( new SyntaxInfo( theme.get_color( "syntax" ), true ), ref attrs );
    return( attrs );
  }

  /* Populate the given text buffer with the text and formatting tags */
  public void to_buffer( TextBuffer buf, int start, int end ) {
    buf.text = text;
    var tags = get_tags_in_range( start, end );
    TextIter ti_start, ti_end;
    for( int i=0; i<tags.length; i++ ) {
      var tag  = tags.index( i );
      var ttag = _attr_tags[tag.tag].text_tag( tag.extra );
      if( buf.tag_table.lookup( ttag.name ) == null ) {
        buf.tag_table.add( ttag );
      }
      buf.get_iter_at_offset( out ti_start, tag.start );
      buf.get_iter_at_offset( out ti_end,   tag.end );
      buf.apply_tag_by_name( ttag.name, ti_start, ti_end );
    }
  }

  /*
   Returns the extra data stored at the given index location, if one exists.
   If nothing is found, returns null.
  */
  public string? get_extra( FormatTag tag, int index ) {
    return( _formats[tag].get_extra( index ) );
  }

  /*
   Returns the parsed data stored at the gven index location.
  */
  public void get_extra_parsed( FormatTag tag, int index, out string? extra, out bool parsed ) {
    _formats[tag].get_extra_parsed( index, out extra, out parsed );
  }

  /*
   Returns the first extra data stored in the given range, if any exist.  If nothing
   is found, returns null.
  */
  public string? get_first_extra_in_range( FormatTag tag, int start, int end ) {
    return( _formats[tag].get_first_extra_in_range( start, end ) );
  }

  /*
   Performs search of the given string within the text.  If any occurrences
   are found, highlight them with the match color.
  */
  public bool do_search( string pattern ) {
    remove_tag_all( FormatTag.MATCH );
    if( (pattern != "") && text.contains( pattern ) ) {
      var tags  = new Array<UndoTagInfo>();
      var start = 0;
      while( (start = text.index_of( pattern, start )) != -1 ) {
        var end = start + pattern.index_of_nth_char( pattern.length );
        tags.append_val( new UndoTagInfo( FormatTag.MATCH, start++, end, null, true ) );
      }
      apply_tags( tags );
      return( true );
    }
    return( false );
  }

  /* If there are text parsers associated with this text, run them */
  private void parse( bool force_clear = false ) {
    if( (_parsers.length > 0) || force_clear ) {
      for( int i=0; i<FormatTag.LENGTH-2; i++ ) {
        _formats[i].remove_parsed_tags();
      }
    }
    for( int i=0; i<_parsers.length; i++ ) {
      _parsers.index( i ).parse( this );
    }
  }

  /* Saves the text as the given XML node */
  public Xml.Node* save() {
    Xml.Node* n = new Xml.Node( null, "text" );
    n->new_prop( "data", text );
    for( int i=0; i<(FormatTag.LENGTH-4); i++ ) {
      if( _formats[i].save_needed() ) {
        var tag = (FormatTag)i;
        n->add_child( _formats[i].save( tag.to_string() ) );
      }
    }
    return( n );
  }

  /* Returns the plain text string stored in the XML node */
  public static string xml_text( Xml.Node* n ) {
    string? t = n->get_prop( "data" );
    return( (t != null) ? t : _( "No text found" ) );
  }

  /* Loads the given XML information */
  public void load( Xml.Node* n ) {
    string? t = n->get_prop( "data" );
    if( t != null ) {
      _text = t;
    }
    string? pa = n->get_prop( "parse-as" );
    if( pa != null ) {
      var str = _text;
      _text = "";  // Clear the text
      /* TBD
      switch( pa ) {
        case "html"     :  ExportHTML.to_text( "<div>" + str + "</div>", this );              break;
        case "markdown" :  ExportHTML.to_text( Utils.markdown_to_html( str, "div" ), this );  break;
      }
      */
    }
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        var tag = FormatTag.from_string( it->name );
        if( tag != FormatTag.LENGTH ) {
          _formats[tag].load( it );
        }
      }
    }
    parse();
    changed();
  }

}

