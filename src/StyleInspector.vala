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

public enum StyleAffects {
  CURRENT = 0,
  LEVEL0,
  LEVEL1,
  LEVEL2,
  LEVEL3,
  LEVEL4,
  LEVEL5,
  LEVEL6,
  LEVEL7,
  LEVEL8,
  LEVEL9,
  ALL
}

public class StyleInspector : Box {

  private DrawArea                   _da;
  private GLib.Settings              _settings;
  private Granite.Widgets.ModeButton _link_types;
  private Granite.Widgets.ModeButton _node_borders;
  private Style                      _current_style;
  private StyleAffects               _affects;

  public static Styles styles = new Styles();

  public StyleInspector( DrawArea da, GLib.Settings settings ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _da            = da;
    _settings      = settings;
    _current_style = new Style();

    /* Load the current style with values from settings */
    _affects                        = (StyleAffects)settings.get_int( "style-affects" );
    _current_style.link_type        = styles.get_link_type( settings.get_string( "style-link-type" ) );
    _current_style.link_width       = settings.get_int( "style-link-width" );
    _current_style.node_border      = styles.get_node_border( settings.get_string( "style-node-border" ) );
    _current_style.node_width       = settings.get_int( "style-node-width" );
    _current_style.node_borderwidth = settings.get_int( "style-node-borderwidth" );

    /* Create the UI */
    add_link_ui();
    add_node_ui();
    add_button_bar();

  }

  /* Adds the options to manipulate line options */
  private void add_link_ui() {

    var box = new Box( Orientation.VERTICAL, 0 );
    var lbl = new Label( _( "<b>Link Options</b>" ) );
    lbl.use_markup = true;

    lbl.xalign = (float)0;

    var ltbox  = new Box( Orientation.HORIZONTAL, 0 );
    ltbox.border_width = 10;

    var link_types_lbl = new Label( _( "Line Type" ) );

    /* Create the line types mode button */
    _link_types = new Granite.Widgets.ModeButton();
    _link_types.has_tooltip = true;
    var link_types = styles.get_link_types();
    for( int i=0; i<link_types.length; i++ ) {
      _link_types.append_icon( link_types.index( i ).icon_name(), IconSize.SMALL_TOOLBAR );
    }
    _link_types.button_release_event.connect( link_type_changed );
    _link_types.query_tooltip.connect( link_type_show_tooltip );

    ltbox.pack_start( link_types_lbl, false, false );
    ltbox.pack_end(   _link_types,    false, false );

    box.pack_start( lbl,   false, true, 0 );
    box.pack_start( ltbox, false, true, 0 );

    pack_start( box, false, true );

  }

  /* Called whenever the user changes the current layout */
  private bool link_type_changed( Gdk.EventButton e ) {
    var link_types = styles.get_link_types();
    if( _link_types.selected < link_types.length ) {
      _current_style.link_type = link_types.index( _link_types.selected );
    }
    return( false );
  }

  /* Called whenever the tooltip needs to be displayed for the layout selector */
  private bool link_type_show_tooltip( int x, int y, bool keyboard, Tooltip tooltip ) {
    if( keyboard ) {
      return( false );
    }
    var link_types = styles.get_link_types();
    int button_width = (int)(_link_types.get_allocated_width() / link_types.length);
    if( (x / button_width) < link_types.length ) {
      tooltip.set_text( link_types.index( x / button_width ).display_name() );
      return( true );
    }
    return( false );
  }

  /* Adds the options to manipulate line options */
  private void add_node_ui() {

    var box = new Box( Orientation.VERTICAL, 0 );
    var lbl = new Label( _( "<b>Node Options</b>" ) );
    lbl.use_markup = true;

    lbl.xalign = (float)0;

    var nbbox  = new Box( Orientation.HORIZONTAL, 0 );
    nbbox.border_width = 10;

    var node_border_lbl = new Label( _( "Node Border" ) );

    /* Create the line types mode button */
    _node_borders = new Granite.Widgets.ModeButton();
    _node_borders.has_tooltip = true;
    var node_borders = styles.get_node_borders();
    for( int i=0; i<node_borders.length; i++ ) {
      _node_borders.append_icon( node_borders.index( i ).icon_name(), IconSize.SMALL_TOOLBAR );
    }
    _node_borders.button_release_event.connect( node_border_changed );
    _node_borders.query_tooltip.connect( node_border_show_tooltip );

    nbbox.pack_start( node_border_lbl, false, false );
    nbbox.pack_end(   _node_borders,   false, false );

    box.pack_start( lbl,   false, true, 0 );
    box.pack_start( nbbox, false, true, 0 );

    pack_start( box, false, true );

  }

  /* Called whenever the user changes the current layout */
  private bool node_border_changed( Gdk.EventButton e ) {
    var node_borders = styles.get_node_borders();
    if( _node_borders.selected < node_borders.length ) {
      _current_style.node_border = node_borders.index( _node_borders.selected );
    }
    return( false );
  }

  /* Called whenever the tooltip needs to be displayed for the layout selector */
  private bool node_border_show_tooltip( int x, int y, bool keyboard, Tooltip tooltip ) {
    if( keyboard ) {
      return( false );
    }
    var node_borders = styles.get_node_borders();
    int button_width = (int)(_node_borders.get_allocated_width() / node_borders.length);
    if( (x / button_width) < node_borders.length ) {
      tooltip.set_text( node_borders.index( x / button_width ).display_name() );
      return( true );
    }
    return( false );
  }

  /* Creates the button bar at the bottom of the Styles inspector */
  private void add_button_bar() {

    var box      = new Box( Orientation.HORIZONTAL, 5 );
    var lbl      = new Label( _( "Apply Style To:" ) );
    var mb       = new MenuButton();
    var apply    = new Button.with_label( _( "Apply Style" ) );
    var menu     = new Gtk.Menu();
    var menu_lbl = new Label( "" );

    box.border_width = 5;
    mb.add( menu_lbl );
    mb.popup = menu;

    var all  = new Gtk.MenuItem.with_label( _( "All Nodes" ) );
    var root = new Gtk.MenuItem.with_label( _( "Root Nodes" ) );
    var lvl1 = new Gtk.MenuItem.with_label( _( "Level 1 Nodes" ) );
    var lvl2 = new Gtk.MenuItem.with_label( _( "Level 2 Nodes" ) );
    var lvl3 = new Gtk.MenuItem.with_label( _( "Level 3 Nodes" ) );
    var lvl4 = new Gtk.MenuItem.with_label( _( "Level 4 Nodes" ) );
    var lvl5 = new Gtk.MenuItem.with_label( _( "Level 5 Nodes" ) );
    var lvl6 = new Gtk.MenuItem.with_label( _( "Level 6 Nodes" ) );
    var lvl7 = new Gtk.MenuItem.with_label( _( "Level 7 Nodes" ) );
    var lvl8 = new Gtk.MenuItem.with_label( _( "Level 8 Nodes" ) );
    var lvl9 = new Gtk.MenuItem.with_label( _( "Level 9 Nodes" ) );
    var curr = new Gtk.MenuItem.with_label( _( "Current Node" ) );

    menu.add( all );
    menu.add( new Gtk.SeparatorMenuItem() );
    menu.add( root );
    menu.add( lvl1 );
    menu.add( lvl2 );
    menu.add( lvl3 );
    menu.add( lvl4 );
    menu.add( lvl5 );
    menu.add( lvl6 );
    menu.add( lvl7 );
    menu.add( lvl8 );
    menu.add( lvl9 );
    menu.add( new Gtk.SeparatorMenuItem() );
    menu.add( curr );
    menu.show_all();

    all.activate.connect(()  => { set_affects( StyleAffects.ALL );     menu_lbl.label = all.label; });
    root.activate.connect(() => { set_affects( StyleAffects.LEVEL0 );  menu_lbl.label = root.label; });
    lvl1.activate.connect(() => { set_affects( StyleAffects.LEVEL1 );  menu_lbl.label = lvl1.label; });
    lvl2.activate.connect(() => { set_affects( StyleAffects.LEVEL2 );  menu_lbl.label = lvl2.label; });
    lvl3.activate.connect(() => { set_affects( StyleAffects.LEVEL3 );  menu_lbl.label = lvl3.label; });
    lvl4.activate.connect(() => { set_affects( StyleAffects.LEVEL4 );  menu_lbl.label = lvl4.label; });
    lvl5.activate.connect(() => { set_affects( StyleAffects.LEVEL5 );  menu_lbl.label = lvl5.label; });
    lvl6.activate.connect(() => { set_affects( StyleAffects.LEVEL6 );  menu_lbl.label = lvl6.label; });
    lvl7.activate.connect(() => { set_affects( StyleAffects.LEVEL7 );  menu_lbl.label = lvl7.label; });
    lvl8.activate.connect(() => { set_affects( StyleAffects.LEVEL8 );  menu_lbl.label = lvl8.label; });
    lvl9.activate.connect(() => { set_affects( StyleAffects.LEVEL9 );  menu_lbl.label = lvl9.label; });
    curr.activate.connect(() => { set_affects( StyleAffects.CURRENT ); menu_lbl.label = curr.label; });

    /* Initialize the menubutton label */
    switch( _affects ) {
      case StyleAffects.ALL     :  menu_lbl.label = all.label;   break;
      case StyleAffects.LEVEL0  :  menu_lbl.label = root.label;  break;
      case StyleAffects.LEVEL1  :  menu_lbl.label = lvl1.label;  break;
      case StyleAffects.LEVEL2  :  menu_lbl.label = lvl2.label;  break;
      case StyleAffects.LEVEL3  :  menu_lbl.label = lvl3.label;  break;
      case StyleAffects.LEVEL4  :  menu_lbl.label = lvl4.label;  break;
      case StyleAffects.LEVEL5  :  menu_lbl.label = lvl5.label;  break;
      case StyleAffects.LEVEL6  :  menu_lbl.label = lvl6.label;  break;
      case StyleAffects.LEVEL7  :  menu_lbl.label = lvl7.label;  break;
      case StyleAffects.LEVEL8  :  menu_lbl.label = lvl8.label;  break;
      case StyleAffects.LEVEL9  :  menu_lbl.label = lvl9.label;  break;
      case StyleAffects.CURRENT :  menu_lbl.label = curr.label;  break;
    }

    apply.activate.connect( apply_changes );

    box.pack_start( lbl,   false, false );
    box.pack_start( mb,    false, false );
    box.pack_end(   apply, false, false );

    pack_end( box, false, true );

  }

  /* Sets the affects value and save the change to the settings */
  private void set_affects( StyleAffects affects ) {
    _affects = affects;
    _settings.set_int( "style-affects", affects );
  }

  /* Apply the changes */
  private void apply_changes() {
    if( _affects == StyleAffects.CURRENT ) {
      styles.set_node_to_style( _da.get_current_node(), _current_style );
    } else if( _affects == StyleAffects.ALL ) {
      styles.set_all_to_style( _da.get_nodes(), _current_style );
    } else {
      styles.set_levels_to_style( _da.get_nodes(), (1 << _affects), _current_style );
    }
    _da.changed();
    _da.queue_draw();
  }

}
