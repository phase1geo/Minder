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

public class Styles {

  private class StyleLevel {
    public Style style { set; get; default = new Style(); }
    public bool  isset { set; get; default = false; }
    public StyleLevel() {}
  }

  private static Array<LinkType>   _link_types;
  private static Array<LinkDash>   _link_dashes;
  private static Array<NodeBorder> _node_borders;
  private        Array<StyleLevel> _styles;

  /* Default constructor */
  public Styles() {

    var rtl        = (Gtk.get_locale_direction() == Gtk.TextDirection.RTL);
    var text_align = rtl ? Pango.Alignment.RIGHT : Pango.Alignment.LEFT;

    /* Create the link types */
    var lt_straight = new LinkTypeStraight();
    var lt_squared  = new LinkTypeSquared();
    var lt_rounded  = new LinkTypeRounded();
    var lt_curved   = new LinkTypeCurved();

    /* Add the link types to the list */
    _link_types = new Array<LinkType>();
    _link_types.append_val( lt_straight );
    _link_types.append_val( lt_squared );
    _link_types.append_val( lt_rounded );
    _link_types.append_val( lt_curved );

    /* Create the link dashes */
    var ld_solid  = new LinkDash( "solid",     _( "Solid" ),      {} );
    var ld_dotted = new LinkDash( "dotted",    _( "Dotted" ),     {2, 6} );
    var ld_sdash  = new LinkDash( "shortdash", _( "Short Dash" ), {6, 6} );
    var ld_ldash  = new LinkDash( "longdash",  _( "Long Dash" ),  {20, 6} );

    /* Add the link dashes to the list */
    _link_dashes = new Array<LinkDash>();
    _link_dashes.append_val( ld_solid );
    _link_dashes.append_val( ld_dotted );
    _link_dashes.append_val( ld_sdash );
    _link_dashes.append_val( ld_ldash );

    /* Create the node borders */
    var nb_none       = new NodeBorderNone();
    var nb_underlined = new NodeBorderUnderlined();
    var nb_bracketed  = new NodeBorderBracket();
    var nb_squared    = new NodeBorderSquared();
    var nb_rounded    = new NodeBorderRounded();
    var nb_pilled     = new NodeBorderPill();

    /* Add the node borders to the list */
    _node_borders = new Array<NodeBorder>();
    _node_borders.append_val( nb_none );
    _node_borders.append_val( nb_underlined );
    _node_borders.append_val( nb_bracketed );
    _node_borders.append_val( nb_squared );
    _node_borders.append_val( nb_rounded );
    _node_borders.append_val( nb_pilled );

    /* Allocate styles for each level */
    _styles = new Array<StyleLevel>();
    for( int i=0; i<=10; i++ ) {
      var level = new StyleLevel();
      level.style.branch_margin   = 100;
      level.style.branch_radius   = 25;
      level.style.link_type       = lt_straight;
      level.style.link_width      = 4;
      level.style.link_arrow      = false;
      level.style.link_arrow_size = 2;
      level.style.link_dash       = ld_solid;
      if( i == 0 ) {
        level.style.node_border  = nb_rounded;
        level.style.node_margin  = 10;
        level.style.node_padding = 10;
      } else {
        level.style.node_border  = nb_underlined;
        level.style.node_margin  = 8;
        level.style.node_padding = 6;
      }
      level.style.node_text_align        = text_align;
      level.style.node_width             = 200;
      level.style.node_borderwidth       = 4;
      level.style.node_fill              = false;
      level.style.node_markup            = true;
      level.style.connection_dash        = ld_dotted;
      level.style.connection_line_width  = 2;
      level.style.connection_arrow       = "fromto";
      level.style.connection_arrow_size  = 0;
      level.style.connection_padding     = 3;
      level.style.connection_title_width = 100;
      level.style.connection_text_align  = text_align;
      level.style.callout_padding        = 5;
      level.style.callout_ptr_width      = 20;
      level.style.callout_ptr_length     = 20;
      level.style.callout_text_align     = text_align;
      _styles.append_val( level );
    }

  }

  /* Loads the contents of the style templates */
  public void load( Xml.Node* n ) {

    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        if( it->name == "style" ) {
          string? l = it->get_prop( "level" );
          string? s = it->get_prop( "isset" );
          if( l != null ) {
            int level = int.parse( l );
            _styles.index( level ).style.load_node( it );
            _styles.index( level ).style.load_connection( it );
            _styles.index( level ).style.load_callout( it );
            _styles.index( level ).isset = (s != null) ? bool.parse( s ) : false;
          }
        }
      }
    }

  }

  /* Saves the style template information */
  public void save( Xml.Node* parent ) {

    Xml.Node* node = new Xml.Node( null, "styles" );
    for( int i=0; i<_styles.length; i++ ) {
      Xml.Node* n = new Xml.Node( null, "style" );
      n->set_prop( "level", i.to_string() );
      n->set_prop( "isset", _styles.index( i ).isset.to_string() );
      _styles.index( i ).style.save_node_in_node( n );
      _styles.index( i ).style.save_connection_in_node( n );
      _styles.index( i ).style.save_callout_in_node( n );
      node->add_child( n );
    }

    parent->add_child( node );

  }

  /* Sets all nodes in the mind-map to the given link style */
  public void set_all_to_style( Style style ) {
    for( int i=0; i<=10; i++ ) {
      _styles.index( i ).style.copy( style );
      _styles.index( i ).isset = true;
    }
  }

  /* Sets all nodes at the specified levels to the given link style */
  public void set_levels_to_style( int levels, Style style ) {
    for( int i=0; i<10; i++ ) {
      if( (levels & (1 << i)) != 0 ) {
        _styles.index( i ).style.copy( style );
        _styles.index( i ).isset = true;
      }
    }
  }

  /* Returns the link type with the given name */
  public LinkType? get_link_type( string name ) {
    for( int i=0; i<_link_types.length; i++ ) {
      var link_type = _link_types.index( i );
      if( link_type.name() == name ) {
        return( link_type );
      }
    }
    return( null );
  }

  /* Returns the list of available link types */
  public Array<LinkType> get_link_types() {
    return( _link_types );
  }

  /* Returns the link dash with the given name */
  public LinkDash? get_link_dash( string name ) {
    for( int i=0; i<_link_dashes.length; i++ ) {
      var link_dash = _link_dashes.index( i );
      if( link_dash.name == name ) {
        return( link_dash );
      }
    }
    return( null );
  }

  /* Returns the list of available link dashes */
  public Array<LinkDash> get_link_dashes() {
    return( _link_dashes );
  }

  /* Returns the node border with the given name */
  public NodeBorder? get_node_border( string name ) {
    for( int i=0; i<_node_borders.length; i++ ) {
      var node_border = _node_borders.index( i );
      if( node_border.name() == name ) {
        return( node_border );
      }
    }
    return( null );
  }

  /* Return the list of available node borders */
  public Array<NodeBorder> get_node_borders() {
    return( _node_borders );
  }

  /* Returns the style for the given level */
  public Style get_style_for_level( uint level, Style? alternative ) {
    var slevel = _styles.index( (level > 9) ? 9 : level );
    return( (slevel.isset || (alternative == null)) ? slevel.style : alternative  );
  }

  /* Returns the global style */
  public Style get_global_style() {
    return( _styles.index( 10 ).style );
  }

}
