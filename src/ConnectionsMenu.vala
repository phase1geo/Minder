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

public class ConnectionsMenu {

  private DrawArea    _da;
  private PopoverMenu _popover;

  private const GLib.ActionEntry action_entries[] = {
    { "action_delete", action_delete },
  };

  /* Default constructor */
  public ConnectionsMenu( Gtk.Application app, DrawArea da ) {

    _da = da;

    var del_menu = new GLib.Menu();
    del_menu.append( _( "Delete" ), "conns.action_delete" );

    var menu = new GLib.Menu();
    menu.append_section( null, del_menu );

    _popover = new PopoverMenu.from_model( menu );

    // Add the menu actions
    var actions = new SimpleActionGroup();
    actions.add_action_entries( action_entries, this );
    _da.insert_action_group( "conns", actions );

    // Add keyboard shortcuts
    app.set_accels_for_action( "conns.action_delete", { "Delete" } );

  }

  //-------------------------------------------------------------
  // Shows the callout popup menu at the given location.
  public void show( double x, double y ) {

    /* Display the popover at the given location */
    Gdk.Rectangle rect = {(int)x, (int)y, 1, 1};
    _popover.pointing_to = rect;
    _popover.popup();

  }

  /* Deletes the current node */
  private void action_delete() {
    _da.delete_connections();
  }

}
