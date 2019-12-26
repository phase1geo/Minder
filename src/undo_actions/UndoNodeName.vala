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

public class UndoNodeName : UndoItem {

  Node     _node;
  string   _old_name;
  UrlLinks _old_urls;
  string   _new_name;
  UrlLinks _new_urls;

  /* Constructor for a node name change */
  public UndoNodeName( Node n, string old_name, UrlLinks old_urls ) {
    base( _( "node name change" ) );
    _node     = n;
    _old_name = old_name;
    _old_urls = old_urls;
    _new_name = n.name.text;
    _new_urls = new UrlLinks( n.da );
    _new_urls.copy( n.urls );
  }

  /* Undoes a node name change */
  public override void undo( DrawArea da ) {
    _node.name.text = _old_name;
    _node.urls.copy( _old_urls );
    da.queue_draw();
    da.current_changed( da );
    da.changed();
  }

  /* Redoes a node name change */
  public override void redo( DrawArea da ) {
    _node.name.text = _new_name;
    _node.urls.copy( _new_urls );
    da.queue_draw();
    da.current_changed( da );
    da.changed();
  }

}
