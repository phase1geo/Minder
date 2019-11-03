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

public class UrlLink {

  public string url  { get; set; default = ""; }  /* URL */
  public int    spos { get; set; default = -1; }  /* Starting position of label text within string */
  public int    epos { get; set; default = -1; }  /* Ending position of label text within string */

  /* Default constructor */
  public UrlLink( string u, int s, int e ) {
    url  = u;
    spos = s;
    epos = e;
  }

  /* Copy constructor */
  public UrlLink.from_url_link( UrlLink ul ) {
    url  = ul.url;
    spos = ul.spos;
    epos = ul.epos;
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
  }

}

public class UrlLinks {

  private Array<UrlLink> _links;
  private string         _url_pattern = "\\b[a-zA-Z0-9]+://[a-z0-9-]+\\.[a-z0-9.-]+(?:/|(?:/[][a-zA-Z0-9!#$%&'*+,.:;=?@_~-]+)*)\\b";

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

    var len     = epos - spos;
    var indices = new Array<int>();

    for( int i=0; i<_links.length; i++ ) {
      var link = _links.index( i );
      if( epos < link.spos ) {
        link.spos -= len;
        link.epos -= len;
      } else if( spos < link.spos ) {
        if( epos < link.epos ) {
          link.spos = epos;
        } else {
          indices.append_val( i );
        }
      } else if( spos < link.epos ) {
        if( epos < link.epos ) {
          link.epos -= len;
        } else {
          link.epos = spos;
        }
      }
    }

    for( int i=((int)indices.length - 1); i>=0; i-- ) {
      _links.remove_index( indices.index( i ) );
    }

  }

  /* Adds a new link to this list */
  public void add_link( int spos, int epos, string url ) {
    var link = new UrlLink( url, spos, epos );
    for( int i=0; i<_links.length; i++ ) {
      if( spos < link.spos ) {
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
      } else {
        var spos = new Array<int>();
        var epos = new Array<int>();
        var txt  = ct.text;
        if( ct.search_text( _url_pattern, ref spos, ref epos ) ) {
          for( int i=0; i<spos.length; i++ ) {
            int s = txt.index_of_nth_char( spos.index( i ) );
            int e = txt.index_of_nth_char( epos.index( i ) );
            if( (s <= pos) && (pos < e) ) {
              double top;
              url = txt.substring( s, (e - s) );
              ct.get_char_pos( s, out left, out top );
              return( true );
            }
          }
        }
      }
    }
    return( false );
  }

  /*
   Generate the URL pos values such that both URLs and user-created links are included and
   URLs do not overlap with user-created links.
  */
  private void get_url_pos( CanvasText ct, ref Array<int> spos, ref Array<int> epos ) {
    var url_spos = new Array<int>();
    var url_epos = new Array<int>();
    if( ct.search_text( _url_pattern, ref url_spos, ref url_epos ) ) {
      int link_index = 0;
      int url_index  = 0;
      while( (link_index < _links.length) || (url_index < url_spos.length) ) {
        if( link_index == _links.length ) {
          spos.append_val( url_spos.index( url_index ) );
          epos.append_val( url_epos.index( url_index ) );
          url_index++;
        } else if( url_index == url_spos.length ) {
          spos.append_val( _links.index( link_index ).spos );
          epos.append_val( _links.index( link_index ).epos );
          link_index++;
        } else {
          var ls = _links.index( link_index ).spos;
          var le = _links.index( link_index ).epos;
          var us = url_spos.index( url_index );
          var ue = url_epos.index( url_index );
          if( ue < ls ) {
            spos.append_val( us );
            epos.append_val( ue );
            url_index++;
          } else if( ls < ue ) {
            spos.append_val( ls );
            epos.append_val( le );
            link_index++;
            if( le >= us ) {
              url_index++;
            }
          }
        }
      }
    }
  }

  /* Parses the given string for URLs and adds their markup to the string */
  public string markup_urls( CanvasText ct ) {
    var markup = ct.text;
    var spos = new Array<int>();
    var epos = new Array<int>();
    get_url_pos( ct, ref spos, ref epos );
    for( int i=((int)spos.length - 1); i>=0; i-- ) {
      int s = ct.text.index_of_nth_char( spos.index( i ) );
      int e = ct.text.index_of_nth_char( epos.index( i ) );
      markup = markup.splice( e, markup.char_count(), "</span>" + markup.substring( e, (markup.char_count() - e) ) );
      markup = markup.splice( s, markup.char_count(), "<span foreground=\"blue\" underline=\"single\">"  + markup.substring( s, (markup.char_count() - s) ) );
    }
    return( markup );
  }

}
