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
using Gdk;
using Granite.Widgets;

public class TagInspector : Box {

  private MindMap?  _map = null;
  private TagEditor _editor;
  private Tags      _selected_tags;

  public signal void editable_changed();

  //-------------------------------------------------------------
  // Constructor
  public TagInspector( MainWindow win ) {

    Object( orientation: Orientation.VERTICAL, spacing: 10, valign: Align.FILL );

    _selected_tags = new Tags();

    var note = new Label( _( "Create tag by entering tag name in entry field.  Click on tag color to change.  Double-click tag name to rename.  Add/remove tags to node by selecting node and clicking on tags or drag/drop tags on nodes to add." ) ) {
      wrap_mode = Pango.WrapMode.WORD,
      wrap = true
    };

    _editor = new TagEditor( win, true );
    _editor.tag_changed.connect( tag_changed );
    _editor.tag_added.connect( tag_added );
    _editor.tag_removed.connect( tag_removed );
    _editor.select_changed.connect( tag_select_changed );
    _editor.visible_changed.connect( tag_visible_changed );

    win.canvas_changed.connect( tab_changed );

    editable_changed.connect(() => {
      _editor.editable = (_map != null) && _map.editable;
    });

    append( note );
    append( _editor );

  }

  //-------------------------------------------------------------
  // Connected signal will provide us whenever the current tab
  // changes in the main window.
  private void tab_changed( MindMap? map ) {
    if( _map != null ) {
      _map.current_changed.disconnect( current_changed );
      _map.reload_tags.disconnect( reload_tags );
    }
    _map = map;
    _editor.set_tags( map.model.tags );
    if( map != null ) {
      map.current_changed.connect( current_changed );
      map.reload_tags.connect( reload_tags );
      current_changed();
    }
  }

  //-------------------------------------------------------------
  // Reloads the tags from the current map.  This is needed when
  // the map tag changes due to undo.
  private void reload_tags() {
    _editor.set_tags( _map.model.tags );
    current_changed();
  }

  //-------------------------------------------------------------
  // Called when a tag changes color or name.
  private void tag_changed( Tag tag, Tag orig_tag ) {
    if( _map != null ) {
      _map.add_undo( new UndoTagChange( tag, orig_tag ) );
      _map.queue_draw();
      _map.auto_save();
    }
  }

  //-------------------------------------------------------------
  // Called when a new tag is added to the map tag list.
  private void tag_added( Tag tag ) {
    if( _map != null ) {
      var nodes = _map.get_selected_nodes();
      for( int i=0; i<nodes.length; i++ ) {
        var node = nodes.index( i );
        node.add_tag( tag );
      }
      _map.add_undo( new UndoTagsAdd( tag, (_map.model.tags.size() - 1), nodes ) );
      if( nodes.length > 0 ) {
        current_changed();
        _map.queue_draw();
      }
      _map.auto_save();
    }
  }

  //-------------------------------------------------------------
  // When a tag is removed from the tag editor, this tag might be
  // used by a node within the map, so let's traverse the map,
  // remove the tag, and keep track of that list.
  private void tag_removed( Tag tag, int index ) {
    if( _map != null ) {
      var nodes = new Array<Node>();
      _map.remove_tag( tag, nodes );
      _map.add_undo( new UndoTagsRemove( tag, index, nodes ) );
      if( nodes.length > 0 ) {
        _map.queue_draw();
      }
      _map.auto_save();
    }
  }

  //-------------------------------------------------------------
  // Updates the currently selected node by adding or removing
  // the given tag from its tag list.
  private void tag_select_changed( Tag tag, bool selected ) {

    var nodes = _map.get_selected_nodes();

    if( nodes.length > 0 ) {

      var changed_nodes = new Array<Node>();

      if( selected ) {
        for( int i=0; i<nodes.length; i++ ) {
          var node = nodes.index( i );
          if( node.add_tag( tag ) ) {
            changed_nodes.append_val( node );
          }
        }
        _map.add_undo( new UndoNodesTagAdd( nodes, tag ) );
      } else {
        for( int i=0; i<nodes.length; i++ ) {
          var node = nodes.index( i );
          if( node.remove_tag( tag ) ) {
            changed_nodes.append_val( node );
          }
        }
        _map.add_undo( new UndoNodesTagRemove( nodes, tag ) );
      }

      _map.auto_save();
      _map.queue_draw();

    }

  }

  //-------------------------------------------------------------
  // Updates the current tag visibility in the mindmap.
  private void tag_visible_changed( Tag tag, bool visible ) {

    if( visible ) {
      _selected_tags.add_tag( tag );
    } else {
      var index = _selected_tags.get_tag_index( tag );
      _selected_tags.remove_tag( index );
    }

    _map.model.highlight_tags( _selected_tags, Minder.settings.get_double( "focus-mode-alpha" ) );

  }

  //-------------------------------------------------------------
  // Called whenever the user changes the current node in the
  // canvas.
  private void current_changed() {

    if( _map != null ) {

      var nodes = _map.get_selected_nodes();

      if( nodes.length == 0 ) {
        _editor.show_selected_tags( null );
      } else if( nodes.length == 1 ) {
        _editor.show_selected_tags( nodes.index( 0 ).tags );
      } else {
        var tags = nodes.index( 0 ).tags;
        for( int i=1; i<nodes.length; i++ ) {
          tags = Tags.intersect( tags, nodes.index( 1 ).tags );
        }
        _editor.show_selected_tags( tags );
      }

      _map.model.highlight_tags( _selected_tags, Minder.settings.get_double( "focus-mode-alpha" ) );

    }

  }

  //-------------------------------------------------------------
  // Grabs the focus on the first field of the displayed pane
  public void grab_first() {
    _editor.grab_focus();
    current_changed();
  }

} 
