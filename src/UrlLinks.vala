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

  public string lbl  { get; set; default = ""; }
  public string link { get; set; default = ""; }
  public int    spos { get; set; default = -1; }
  public int    epos { get; set; default = -1; }

  /* Default constructor */
  public UrlLink( string l, int s, int e ) {
    lbl  = l;
    link = l;
    spos = s;
    epos = e;
  }

  /* Default constructor */
  public UrlLink.from_xml( Xml.Node* node ) {
    load( node );
  }

  /* Saves this URL link to a save file */
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "urllink" );
    node->set_prop( "label", lbl );
    node->set_prop( "link",  link );
    node->set_prop( "spos",  spos.to_string() );
    node->set_prop( "epos",  epos.to_string() );
    return( node );
  }

  /* Loads the given URL node link into this class */
  private void load( Xml.Node* node ) {
    string? lb = node->get_prop( "label" );
    if( lb != null ) {
      lbl = lb;
    }
    string? li = node->get_prop( "link" );
    if( li != null ) {
      link = li;
    }
    string? sp = node->get_prop( "spos" );
    if( sp != null ) {
      spos = int.parse( sp );
    }
    string? ep = node->get_prop( "epos" );
    if( ep != null ) {
      epos = int.parse( ep );
    }
  }

}

public class UrlLinks : Array<UrlLink> {

  /* Default constructor */
  public UrlLinks() {}

  /* Constructor */
  public UrlLinks.from_xml( Xml.Node* node ) {
    load( node );
  }

  /* Called when the URL link needs to be saved */
  public Xml.Node* save() {
    Xml.Node* node = new Xml.Node( null, "urllinks" );
    for( int i=0; i<length; i++ ) {
      node->add_child( this.index( i ).save() );
    }
    return( node );
  }

  /* Loads the given URL link information from the XML source */
  private void load( Xml.Node* node ) {
    for( Xml.Node* it = node->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "urllink") ) {
        var ul = new UrlLink.from_xml( it );
        append_val( ul );
      }
    }
  }

}
