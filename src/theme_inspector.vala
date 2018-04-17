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

public class ThemeInspector : Box {

  private DrawArea? _da     = null;
  private Themes?   _themes = null;

  public ThemeInspector( DrawArea da ) {

    Object( orientation:Orientation.VERTICAL, spacing:10 );

    _da     = da;
    _themes = new Themes();

    var lbl       = new Label( _( "Themes" ) );
    var list      = new ListStore( 1, typeof(string), typeof(Image) );

    /* Create the tree view */
    var list_view = new TreeView.with_model( list );
    list.insert_column_with_attributes( -1, null, new CellRendererPixbuf(), "markup", 0 );
    list.headers_visible = false;
    list.activate_on_single_click = true;
    list.row_activated.connect( on_theme_clicked );

    pack_start( lbl,       false, true );
    pack_start( list_view, true,  true );

  }

  /* Called whenever a theme is selected in the treeview */
  private void on_theme_clicked( TreePath path, TreeViewColumn col ) {
    TreeIter it;
    Node?    node = null;
    _search_items.get_iter( out it, path );
    _search_items.get( it, 1, &node, -1 );
    if( node != null ) {
      _canvas.set_current_node( node );
    }
    stdout.printf( "Theme clicked!\n" );
  }

}
