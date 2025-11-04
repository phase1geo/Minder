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
  private ListBox         _apply_lb;
  private ListBox         _edit_lb;
  private Button          _del_btn;
  private Button          _edit_btn;

  public signal void close();

  //-------------------------------------------------------------
  // Constructor
  public TemplateEditor( TemplateGroup templates, TemplateAddLoadFunc load_func ) {

    Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _templates       = templates;
    _names_to_delete = new HashSet<string>();

    _apply_lb = new ListBox() {
      valign = Align.START
    };

    var apply_scrolled = new ScrolledWindow() {
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = _apply_lb
    };
    apply_scrolled.set_size_request( -1, 300 );

    _apply_lb.row_selected.connect((row) => {
      close();
      var index = row.get_index();
      var names = templates.get_names();
      var template = _templates.get_template( names.index( index ) );
      if( template != null ) {
        load_func( template );
      }
    });

    _edit_lb = new ListBox() {
      valign = Align.START
    };

    var edit_scrolled = new ScrolledWindow() {
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = _edit_lb
    };

    var stack = new Stack();
    stack.add_named( apply_scrolled, "apply" );
    stack.add_named( edit_scrolled,  "edit" );

    var cancel_btn = new Button.with_label( _( "Cancel" ) ) {
      halign    = Align.END,
      hexpand   = true,
      visible   = false
    };

    cancel_btn.clicked.connect(() => {
      stack.visible_child_name = "apply";
      _del_btn.visible   = false;
      cancel_btn.visible = false;
      _edit_btn.visible  = true;
      close();
    });

    _del_btn = new Button.with_label( _( "Delete" ) ) {
      halign    = Align.START,
      hexpand   = true,
      visible   = false,
      sensitive = false
    };

    _del_btn.clicked.connect(() => {
      stack.visible_child_name = "apply";
      _del_btn.visible   = false;
      cancel_btn.visible = false;
      _edit_btn.visible  = true;
      close();
      _names_to_delete.foreach((name) => {
        _templates.delete_template( name );
        return( true );
      });
    });

    _edit_btn = new Button.with_label( _( "Edit" ) ) {
      halign    = Align.END,
      hexpand   = true,
      sensitive = false
    };

    _edit_btn.clicked.connect(() => {
      stack.visible_child_name = "edit";
      _del_btn.visible   = true;
      cancel_btn.visible = true;
      _edit_btn.visible  = false;
    });

    var btn_box = new Box( Orientation.HORIZONTAL, 5 );
    btn_box.append( _del_btn );
    btn_box.append( _edit_btn );
    btn_box.append( cancel_btn );

    append( stack );
    append( btn_box );

  }

  //-------------------------------------------------------------
  // Creates a single item in the listbox.
  private void create_item( string name ) {

    var lbl = new Label( name ) {
      halign = Align.START
    };

    _apply_lb.append( lbl );

    var check = new CheckButton.with_label( "  " + name ) {
      halign = Align.START
    };

    check.toggled.connect(() => {
      if( check.active ) {
        _names_to_delete.add( name );
      } else {
        _names_to_delete.remove( name );
      }
      _del_btn.sensitive = (_names_to_delete.size > 0);
    });

    _edit_lb.append( check );

    _edit_btn.sensitive = true;

  }

  //-------------------------------------------------------------
  // Called when the contents of template_group changes.
  public void update_list() {
    _names_to_delete.clear();
    _apply_lb.remove_all();
    _edit_lb.remove_all();
    var names = _templates.get_names();
    for( int i=0; i<names.length; i++ ) {
      create_item( names.index( i ) );
    }
  }

}
