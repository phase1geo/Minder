/*
* Copyright (c) 2025 (https://github.com/phase1geo/Minder)
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
using Gee;

public class TemplateEditor : Box {

  private TemplateGroup   _templates;
  private HashSet<string> _names_to_delete;
  private ListBox         _lb;
  private Label           _add_label;
  private Button          _del_btn;
  private Button          _edit_btn;

  public signal void close();

  private signal void edit_mode_changed( bool edit_mode );

  //-------------------------------------------------------------
  // Constructor
  public TemplateEditor( MainWindow win, TemplateGroup templates, TemplateAddLoadFunc add_func, TemplateAddLoadFunc load_func ) {

    Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _templates       = templates;
    _names_to_delete = new HashSet<string>();

    var search_add = new SearchEntry() {
      halign           = Align.FILL,
      margin_start     = 5,
      margin_end       = 5,
      placeholder_text = _( "Create or search templates" ),
      width_chars      = 40
    };

    search_add.search_changed.connect(() => {
      var text  = search_add.text;
      var names = _templates.get_names();
      for( int i=0; i<names.length; i++ ) {
        var row  = _lb.get_row_at_index( i );
        var name = names.index( i );
        row.visible = (text == "") || name.contains( text ) || _names_to_delete.contains( name );
      }
      _add_label.visible = (text != "") && _edit_btn.visible;
      _add_label.label   = _( "Create '%s' template" ).printf( text );
    });

    search_add.activate.connect(() => {
      _templates.save_as_template( search_add.text, add_func );
      search_add.text = "";
    });

    _lb = new ListBox() {
      valign = Align.START
    };

    var scrolled = new ScrolledWindow() {
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = _lb
    };
    scrolled.set_size_request( -1, 300 );

    _lb.row_selected.connect((row) => {
      if( row == null ) return;
      close();
      if( _edit_btn.visible ) {
        var index = row.get_index();
        var names = templates.get_names();
        if( index == names.length ) {
          _templates.save_as_template( search_add.text, add_func );
        } else {
          var template = _templates.get_template( names.index( index ) );
          if( template != null ) {
            load_func( template );
          }
        }
      }
    });

    var cancel_btn = new Button.with_label( _( "Cancel" ) ) {
      halign    = Align.END,
      hexpand   = true,
      visible   = false
    };

    cancel_btn.clicked.connect(() => {
      edit_mode_changed( false );
    });

    _del_btn = new Button.with_label( _( "Delete" ) ) {
      halign    = Align.START,
      hexpand   = true,
      visible   = false,
      sensitive = false
    };
    _del_btn.add_css_class( "destructive-action" );

    _del_btn.clicked.connect(() => {
      close();
      _names_to_delete.foreach((name) => {
        _templates.delete_template( name );
        return( true );
      });
      _names_to_delete.clear();
      edit_mode_changed( false );
    });

    _edit_btn = new Button.with_label( _( "Edit" ) ) {
      halign    = Align.END,
      hexpand   = true,
      sensitive = false
    };

    _edit_btn.clicked.connect(() => {
      edit_mode_changed( true );
    });

    edit_mode_changed.connect((edit_mode) => {
      search_add.placeholder_text = edit_mode ? _( "Search Templates" ) : _( "Create or Search Templates" );
      _del_btn.visible   = edit_mode;
      cancel_btn.visible = edit_mode;
      _edit_btn.visible  = !edit_mode;
    });

    var btn_box = new Box( Orientation.HORIZONTAL, 5 ) {
      margin_start = 5,
      margin_end   = 5
    };

    btn_box.append( _del_btn );
    btn_box.append( _edit_btn );
    btn_box.append( cancel_btn );

    append( search_add );
    append( scrolled );
    append( btn_box );

  }

  //-------------------------------------------------------------
  // Creates a single item in the listbox.
  private void create_item( string name ) {

    var check = new CheckButton() {
      halign  = Align.START,
      visible = false
    };

    check.toggled.connect(() => {
      if( check.active ) {
        _names_to_delete.add( name );
      } else {
        _names_to_delete.remove( name );
      }
      _del_btn.sensitive = (_names_to_delete.size > 0);
    });

    edit_mode_changed.connect((edit_mode) => {
      check.visible = edit_mode;
      if( !edit_mode ) {
        check.active = false;
      }
    });

    var lbl = new Label( name ) {
      halign = Align.START
    };

    var box = new Box( Orientation.HORIZONTAL, 5 );
    box.append( check );
    box.append( lbl );

    _lb.append( box );

    _edit_btn.sensitive = true;

  }

  //-------------------------------------------------------------
  // Called when the contents of template_group changes.
  public void update_list() {

    _lb.remove_all();

    var names = _templates.get_names();
    for( int i=0; i<names.length; i++ ) {
      create_item( names.index( i ) );
    }

    _add_label = new Label( "" ) {
      halign  = Align.START,
      visible = false
    };

    edit_mode_changed.connect((edit_mode) => {
      _add_label.visible = !edit_mode;
    });
    _lb.append( _add_label );

  }

}
