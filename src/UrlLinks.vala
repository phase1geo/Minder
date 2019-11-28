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

using Pango;
using Gtk;

public class UrlLink {

  public string url      { get; set; default = ""; }
  public int    spos     { get; set; default = -1; }
  public int    epos     { get; set; default = -1; }
  public bool   embedded { get; set; default = false; }

  /* Default constructor */
  public UrlLink( string u, int s, int e, bool b ) {
    url      = u;
    spos     = s;
    epos     = e;
    embedded = b;
  }

  /* Copy constructor */
  public UrlLink.from_url_link( UrlLink ul ) {
    url      = ul.url;
    spos     = ul.spos;
    epos     = ul.epos;
    embedded = ul.embedded;
  }

  /* Default constructor */
  public UrlLink.from_xml( Xml.Node* node ) {
    load( node );
  }

  /* Saves this URL link to a save file */
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "urllink" );
    node->set_prop( "url",  url );
    node->set_prop( "spos", spos.to_string() );
    node->set_prop( "epos", epos.to_string() );
    node->set_prop( "embeded", embedded.to_string() );
    return( node );
  }

  /* Loads the given URL node link into this class */
  private void load( Xml.Node* node ) {
    string? u = node->get_prop( "url" );
    if( u != null ) {
      url = u;
    }
    string? s = node->get_prop( "spos" );
    if( s != null ) {
      spos = int.parse( s );
    }
    string? e = node->get_prop( "epos" );
    if( e != null ) {
      epos = int.parse( e );
    }
    string? em = node->get_prop( "embedded" );
    if( em != null ) {
      embedded = bool.parse( em );
    }
  }

}

public class UrlLinks {

  private Array<UrlLink> _links;
  private string         _url_pattern = "\\b(mailto:.+@[a-z0-9-]+\\.[a-z0-9.-]+|[a-zA-Z0-9]+://[a-z0-9-]+\\.[a-z0-9.-]+(?:/|(?:/[][a-zA-Z0-9!#$%&'*+,.:;=?@_~-]+)*))\\b";

  /* Default constructor */
  public UrlLinks() {
    _links = new Array<UrlLink>();
  }

  /* Constructor */
  public UrlLinks.from_xml( Xml.Node* node ) {
    _links = new Array<UrlLink>();
    load( node );
  }

  /* Called when the URL link needs to be saved */
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "urllinks" );
    for( int i=0; i<_links.length; i++ ) {
      node->add_child( _links.index( i ).save() );
    }
    return( node );
  }

  /* Loads the given URL link information from the XML source */
  public void load( Xml.Node* node ) {
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "urllink") ) {
        var ul = new UrlLink.from_xml( it );
        _links.append_val( ul );
      }
    }
  }

  /* Modifies this class to match the given UrlLinks instance */
  public void copy( UrlLinks uls ) {
    if( _links.length > 0 ) {
      _links.remove_range( 0, _links.length );
    }
    for( int i=0; i<uls._links.length; i++ ) {
      _links.append_val( new UrlLink.from_url_link( uls._links.index( i ) ) );
    }
  }

  /* Called whenever a string is inserted in the text */
  public void insert_text( int spos, string str ) {

    int del_index = -1;
    int len       = str.length;

    for( int i=0; i<_links.length; i++ ) {

      var link = _links.index( i );

      /* If the inserted text is before this link text, adjust the position of the link text */
      if( spos <= link.spos ) {
        link.spos += len;
        link.epos += len;

      /* Otherwise, if the string is inserted at the start, at the end of within the link text, change the label.
         If the label previously matched the link, reparse the link to verify it is a valid URL.  If it is not*/
      } else if( spos <= link.epos ) {
        link.epos += len;
      }

    }

    /* If we need to delete an item, do it now */
    if( del_index != -1 ) {
      _links.remove_index( del_index );
    }

  }

  /* Adjusts the stored links based on the given text deletion */
  public void delete_text( int spos, int epos ) {

    var len = epos - spos;

    for( int i=(int)(_links.length - 1); i>=0; i-- ) {
      var link = _links.index( i );
      if( epos < link.spos ) {
        link.spos -= len;
        link.epos -= len;
      } else if( spos < link.spos ) {
        if( epos < link.epos ) {
          link.spos = epos;
        } else {
          _links.remove_index( i );
        }
      } else if( spos < link.epos ) {
        if( epos < link.epos ) {
          link.epos -= len;
        } else {
          link.epos = spos;
        }
      }
    }

  }

  /* Adds a new link to this list */
  public void add_link( int spos, int epos, string url ) {
    var link = new UrlLink( url, spos, epos, false );
    for( int i=0; i<_links.length; i++ ) {
      if( spos < _links.index( i ).spos ) {
        _links.insert_val( i, link );
        return;
      }
    }
    _links.append_val( link );
  }

  /* Removes the link that exists at the given character position */
  public void remove_link( int pos ) {
    var index = find_link( pos );
    if( index != -1 ) {
      _links.remove_index( index );
    }
  }

  /* Changes the stored URL to the given value */
  public void change_link( int pos, string url ) {
    var index = find_link( pos );
    if( index != -1 ) {
      _links.index( index ).url = url;
    }
  }

  /*
   Returns the index of the link that exists at the given character position.
   If no link exists at the given position, return -1.
  */
  public int find_link( int pos ) {
    for( int i=0; i<_links.length; i++ ) {
      var link = _links.index( i );
      if( (link.spos <= pos) && (pos < link.epos) ) {
        return( i );
      }
    }
    return( -1 );
  }

  /* Returns true if the given range overlaps with one or more link ranges */
  public bool overlaps_with( int spos, int epos, ref Array<int> indices ) {
    for( int i=0; i<_links.length; i++ ) {
      var link = _links.index( i );
      if( (link.spos < epos) && (link.epos > spos) ) {
        indices.append_val( i );
      }
    }
    return( indices.length > 0 );
  }

  /* Returns the URL associated with the given text position */
  public string? get_url( int pos ) {
    var index = find_link( pos );
    if( index != -1 ) {
      return( _links.index( index ).url );
    }
    return( null );
  }

  /* Returns the starting character position with the given text position */
  public int get_spos( int pos ) {
    var index = find_link( pos );
    if( index != -1 ) {
      return( _links.index( index ).spos );
    }
    return( -1 );
  }

  /* Returns true if the given string is a URL pattern */
  public bool is_url( string str ) {
    return( Regex.match_simple( _url_pattern, str ) );
  }

  /* Returns the URL at the given string position */
  public bool get_url_at_pos( CanvasText ct, double x, double y, out string url, out double left ) {
    var pos = ct.get_pos( x, y );
    url  = "";
    left = 0;
    if( pos != -1 ) {
      var link = find_link( pos );
      if( link != -1 ) {
        double top;
        url = _links.index( link ).url;
        ct.get_char_pos( _links.index( link ).spos, out left, out top );
        return( true );
      }
    }
    return( false );
  }

  /* Removes all URLs that were parsed as embedded URLs within the text */
  private void clear_embedded_urls() {
    for( int i=((int)_links.length - 1); i>=0; i-- ) {
      if( _links.index( i ).embedded ) {
        _links.remove_index( i );
      }
    }
  }

  /* Returns true if at least one stored link overlaps with the given range */
  private bool overlaps( int us, int ue ) {
    for( int i=0; i<_links.length; i++ ) {
      var ls = _links.index( i ).spos;
      var le = _links.index( i ).epos;
      if( (ls < ue) && (le > us) ) {
        return( true );
      }
    }
    return( false );
  }

  /*
   Called when the user ends the editing portion of the given text.  Adds all
   found embedded URLs in the text to the list of URLs.
  */
  public void parse_embedded_urls( CanvasText ct ) {
    var spos = new Array<int>();
    var epos = new Array<int>();
    ct.search_text( _url_pattern, ref spos, ref epos );
    clear_embedded_urls();
    for( int i=0; i<spos.length; i++ ) {
      var s = spos.index( i );
      var e = epos.index( i );
      if( !overlaps( s, e ) ) {
        _links.append_val( new UrlLink( ct.text.substring( s, (e - s) ), s, e, true ) );
      }
    }
  }

  /*
   Adds all of the URL attributes for the URL specified with the
   given start and end character index.
  */
  private void add_attributes( ref AttrList attrs, int start, int end ) {

    var color = attr_foreground_new( 0, 0, 65535 );
    color.start_index = start;
    color.end_index   = end;
    attrs.change( color.copy() );

    var uline = attr_underline_new( Underline.SINGLE );
    uline.start_index = start;
    uline.end_index   = end;
    attrs.change( uline.copy() );

  }

  /* Parses the given string for URLs and adds their markup to the string */
  public void markup_canvas_text( CanvasText ct ) {
    var attrs = ct.pango_layout.get_attributes();
    for( int i=0; i<_links.length; i++ ) {
      var s = ct.text.index_of_nth_char( _links.index( i ).spos );
      var e = ct.text.index_of_nth_char( _links.index( i ).epos );
      add_attributes( ref attrs, s, e );
    }
    ct.pango_layout.set_attributes( attrs );
  }

  /* Applies the URL markup to the given text buffer */
  public void markup_text_buffer( TextBuffer buf, string tag ) {
    TextIter s, e;
    buf.get_start_iter( out s );
    buf.get_end_iter( out e );
    buf.remove_tag_by_name( tag, s, e );
    for( int i=0; i<_links.length; i++ ) {
      buf.get_iter_at_offset( out s, _links.index( i ).spos );
      buf.get_iter_at_offset( out e, _links.index( i ).epos );
      buf.apply_tag_by_name( tag, s, e );
    }
  }

}
