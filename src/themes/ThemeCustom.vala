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

using Gdk;
using Gtk;

public class ThemeCustom : Theme {

  /* Create the theme colors */
  public ThemeCustom() {

    name = _( "Custom" );

    /* Generate the non-link colors */
    background         = get_color( "#000000" );
    foreground         = get_color( "White" );
    root_background    = get_color( "#d4d4d4" );
    root_foreground    = get_color( "Black" );
    nodesel_background = get_color( "#64baff" );
    nodesel_foreground = get_color( "Black" );
    textsel_background = get_color( "#0d52bf" );
    textsel_foreground = get_color( "White" );
    text_cursor        = get_color( "White" );
    attachable_color   = get_color( "#9bdb4d" );
    connection_color   = get_color( "#404040" );
    prefer_dark        = true;

    /* Generate the link colors */
    add_link_color( get_color( "#c6262e" ) );
    add_link_color( get_color( "#f37329" ) );
    add_link_color( get_color( "#f9c440" ) );
    add_link_color( get_color( "#68b723" ) );
    add_link_color( get_color( "#3689e6" ) );
    add_link_color( get_color( "#7a36b1" ) );
    add_link_color( get_color( "#715344" ) );
    add_link_color( get_color( "#333333" ) );

  }

  /* Parses the specified XML node for theme coloring information */
  public void load( Xml.Node* n ) {

    string? nn = n->get_prop( "name" );
    if( nn != null ) {
      name = nn;
    }

    string? b = n->get_prop( "background" );
    if( b != null ) {
      background = get_color( b );
    }

    string? f = n->get_prop( "foreground" );
    if( f != null ) {
      foreground = get_color( f );
    }

    string? rb = n->get_prop( "root_background" );
    if( rb != null ) {
      root_background = get_color( rb );
    }

    string? rf = n->get_prop( "root_foreground" );
    if( rf != null ) {
      root_foreground = get_color( rb );
    }

    string? nb = n->get_prop( "nodesel_background" );
    if( nb != null ) {
      nodesel_background = get_color( nb );
    }

    string? nf = n->get_prop( "nodesel_foreground" );
    if( nf != null ) {
      nodesel_foreground = get_color( nf );
    }

    string? tb = n->get_prop( "textsel_background" );
    if( tb != null ) {
      textsel_background = get_color( tb );
    }

    string? tf = n->get_prop( "textsel_foreground" );
    if( tf != null ) {
      textsel_foreground = get_color( tf );
    }

    string? tc = n->get_prop( "text_cursor" );
    if( tc != null ) {
      text_cursor = get_color( tc );
    }

    string? a = n->get_prop( "attachable" );
    if( a != null ) {
      attachable_color = get_color( a );
    }

    string? c = n->get_prop( "connection" );
    if( c != null ) {
      connection_color = get_color( c );
    }

    string? d = n->get_prop( "prefer_dark" );
    if( d != null ) {
      prefer_dark = bool.parse( d );
    }

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "linkcolor") ) {
        string? color = it->get_prop( "color" );
        if( color != null ) {
          add_link_color( get_color( color ) );
        }
      }
    }

  }

  /* Returns an XML node containing the contents of this theme color scheme */
  public Xml.Node* save() {

    Xml.Node* n = new Xml.Node( null, "theme" );

    n->new_prop( "background",         Utils.color_from_rgba( background ) );
    n->new_prop( "foreground",         Utils.color_from_rgba( foreground ) );
    n->new_prop( "root_background",    Utils.color_from_rgba( root_background ) );
    n->new_prop( "root_foreground",    Utils.color_from_rgba( root_foreground ) );
    n->new_prop( "nodesel_background", Utils.color_from_rgba( nodesel_background ) );
    n->new_prop( "nodesel_foreground", Utils.color_from_rgba( nodesel_foreground ) );
    n->new_prop( "textsel_background", Utils.color_from_rgba( textsel_background ) );
    n->new_prop( "textsel_foreground", Utils.color_from_rgba( textsel_foreground ) );
    n->new_prop( "text_cursor",        Utils.color_from_rgba( text_cursor ) );
    n->new_prop( "attachable",         Utils.color_from_rgba( attachable_color ) );
    n->new_prop( "connection",         Utils.color_from_rgba( connection_color ) );
    n->new_prop( "connection",         prefer_dark.to_string() );

    for( int i=0; i<num_link_colors(); i++ ) {
      Xml.Node* color = new Xml.Node( null, "linkcolor" );
      color->new_prop( "color", Utils.color_from_rgba( link_color( i ) ) );
      n->add_child( color );
    }

    return( n );

  }

}

