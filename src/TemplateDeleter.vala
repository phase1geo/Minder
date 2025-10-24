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

public class TemplateDeleter : Box {

  private TemplateGroup   _templates;
  private HashSet<string> _names_to_delete;
  private ListBox         _lb;
  private Button          _del_btn;

  public signal void close();

  //-------------------------------------------------------------
  // Constructor
  public TemplateDeleter( TemplateGroup templates ) {

    Object( orientation: Orientation.VERTICAL, spacing: 5 );

    _templates       = templates;
    _names_to_delete = new HashSet<string>();

    _lb = new ListBox() {
      valign = Align.START
    };

    var scrolled = new ScrolledWindow() {
      hscrollbar_policy = PolicyType.NEVER,
      vscrollbar_policy = PolicyType.AUTOMATIC,
      child = _lb
    };
    scrolled.set_size_request( -1, 200 );

    _del_btn = new Button.with_label( _( "Delete" ) ) {
      halign    = Align.END,
      hexpand   = true,
      sensitive = false
    };

    var btn_box = new Box( Orientation.HORIZONTAL, 5 );
    btn_box.append( _del_btn );

    var box = new Box( Orientation.VERTICAL, 5 );
    box.append( scrolled );
    box.append( btn_box );

    var box_rev = new Revealer() {
      child = box
    };

    var exp_label = new Label( _( "Delete Saved Style" ) ) {
      halign = Align.START,
      margin_start  = 17,
      margin_top    = 5,
      margin_bottom = 5
    };

    var exp_arrow = new Image.from_icon_name( _( "pan-end-symbolic" ) ) {
      halign     = Align.END,
      hexpand    = true,
      margin_end = 14
    };

    var expander = new Box( Orientation.HORIZONTAL, 0 );
    expander.append( exp_label );
    expander.append( exp_arrow );

    var exp_click = new GestureClick();
    expander.add_controller( exp_click );

    var exp_focus = new EventControllerFocus();
    expander.add_controller( exp_focus );

    var exp_motion = new EventControllerMotion();
    expander.add_controller( exp_motion );

    var exp_key = new EventControllerKey();
    expander.add_controller( exp_key );

    exp_click.released.connect((n_press, x, y) => {
      box_rev.reveal_child = !box_rev.reveal_child;
      exp_arrow.icon_name  = box_rev.reveal_child ? "pan-down-symbolic" : "pan-end-symbolic";
      /*
      if( box.reveal_child ) {
        _lb.grab_focus();
      }
      */
    });

    exp_focus.enter.connect(() => {
      expander.add_css_class( "widget-selected" );
      expander.add_css_class( "focused" );
    });
    exp_focus.leave.connect(() => {
      expander.remove_css_class( "widget-selected" );
      expander.remove_css_class( "focused" );
    });

    exp_motion.enter.connect((x, y) => {
      expander.add_css_class( "widget-selected" );
    });
    exp_motion.leave.connect(() => {
      if( !expander.has_css_class( "focused" ) ) {
        expander.remove_css_class( "widget-selected" );
      }
    });

    exp_key.key_pressed.connect((keyval, keymod, state) => {
      switch( keyval ) {
        case Gdk.Key.Right :
          if( !box_rev.reveal_child ) {
            exp_click.released( 1, 0, 0 );
          }
          return( true );
        case Gdk.Key.Left :
          if( box_rev.reveal_child ) {
            exp_click.released( 1, 0, 0 );
          }
          return( true );
        case Gdk.Key.Down :
          _lb.grab_focus();
          return( true );
        case Gdk.Key.space :
          exp_click.released( 1, 0, 0 );
          return( true );
      }
      return( false );
    });

    append( new Separator( Orientation.HORIZONTAL ) );
    append( expander );
    append( box_rev );

    _del_btn.clicked.connect(() => {
      box_rev.reveal_child = false;
      close();
      _names_to_delete.foreach((name) => {
        _templates.delete_template( name );
        return( true );
      });
    });

  }

  //-------------------------------------------------------------
  // Creates a single item in the listbox.
  private void create_item( string name ) {
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
    _lb.append( check );
  }

  //-------------------------------------------------------------
  // Called when the contents of template_group changes.
  public void update_list() {
    _names_to_delete.clear();
    _lb.remove_all();
    var names = _templates.get_names();
    for( int i=0; i<names.length; i++ ) {
      create_item( names.index( i ) );
    }
  }

}
