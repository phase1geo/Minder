/*
* Copyright (c) 2020 (https://github.com/phase1geo/Outliner)
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

public class TextCompletionItem {

  public string label { get; private set; default = ""; }
  public string alt   { get; private set; default = ""; }

  // Constructor
  public TextCompletionItem( string label ) {
    this.label = label;
  }

  // Constructor
  public TextCompletionItem.with_alt( string label, string alt ) {
    this.label = label;
    this.alt   = alt;
  }

  // Creates the row for the listbox
  public Box create_row() {
    var box = new Box( Orientation.HORIZONTAL, 0 );
    var lbl = new Label( label );
    lbl.xalign       = 0;
    lbl.margin       = 5;
    lbl.margin_start = 10;
    lbl.margin_end   = 10;
    box.pack_start( lbl, false, true );
    if( alt != "" ) {
      var albl = new Label( alt );
      albl.xalign       = 0;
      albl.margin       = 5;
      albl.margin_start = 10;
      albl.margin_end   = 10;
      box.pack_start( albl, false, true );
    }
    return( box );
  }

  public static string get_text( Box box ) {
    var children = box.get_children();
    var lbl      = (Label)children.nth_data( children.length() - 1 );
    return( lbl.get_text() );
  }

  public static int compare( TextCompletionItem a, TextCompletionItem b ) {
    return( GLib.strcmp( a.label, b.label ) );
  }

}

public class TextCompletion {

  private DrawArea     _da;
  private CanvasText   _ct;
  private ListBox      _list;
  private bool         _shown     = false;
  private int          _size      = 0;
  private int          _start_pos = 0;
  private int          _end_pos   = 0;

  public bool shown {
    get {
      return( _shown );
    }
  }

  /* Default constructor */
  public TextCompletion( DrawArea da ) {
    _da   = da;
    _list = new ListBox();
    _list.selection_mode = SelectionMode.BROWSE;
    _list.halign         = Align.START;
    _list.valign         = Align.START;
    _list.row_activated.connect( activate_row );
  }

  /* Displays the auto-completion text with the given list */
  public void show( CanvasText ct, List<TextCompletionItem> list, int start, int end ) {

    /* If there is nothing to show, hide the contents */
    if( list.length() == 0 ) {
      hide();
      return;
    }

    /* Get the maximum number of items that we will display */
    var max_items = _da.win.settings.get_int( "max-auto-completion-items" );

    /* Remember the text positions that will be replaced */
    _ct        = ct;
    _start_pos = start;
    _end_pos   = end;
    _size      = (max_items < (int)list.length()) ? max_items : (int)list.length();

    /* Get the position of the cursor so that we know where to place the box */
    int x, ytop, ybot;
    ct.get_cursor_pos( out x, out ytop, out ybot );

    /* Calculate the position of the widget */
    var lbl_height = _da.win.get_label_height();
    var height     = _size * (lbl_height + 10);
    int win_top, win_bottom;
    _da.get_window_ys( out win_top, out win_bottom );
    var below = (ybot + (max_items * (lbl_height + 10))) <= win_bottom;

    /* Set the position */
    _list.margin_start = x;
    if( below ) {
      _list.margin_top = ybot + 5;
    } else {
      list.reverse();
      _list.margin_top = (ytop - 5) - height;
    }

    /* Populate the list */
    _list.foreach( (w) => {
      _list.remove( w );
    });
    foreach( TextCompletionItem item in list ) {
      _list.add( item.create_row() );
      if( --max_items <= 0 ) {
        break;
      }
    }

    /* Select the first row */
    _list.select_row( _list.get_row_at_index( below ? 0 : (_size - 1) ) );

    /* Make sure that everything is seen */
    _list.show_all();

    /* If the list isn't being shown, show it */
    if( !_shown ) {
      var overlay = (Overlay)_da.get_parent();
      overlay.add_overlay( _list );
    }

    _shown = true;

  }

  /* Hides the auto-completion box */
  public void hide() {
    if( !_shown ) return;
    _list.unparent();
    _shown = false;
  }

  /* Moves the selection down by one row */
  public void down() {
    if( !_shown ) return;
    var row = _list.get_selected_row();
    if( (row.get_index() + 1) < _size ) {
      _list.select_row( _list.get_row_at_index ( row.get_index() + 1 ) );
    }
  }

  /* Moves the selection up by one row */
  public void up() {
    if( !_shown ) return;
    var row = _list.get_selected_row();
    if( row.get_index() > 0 ) {
      _list.select_row( _list.get_row_at_index ( row.get_index() - 1 ) );
    }
  }

  /* Substitutes the currently selected entry */
  public void select() {
    if( !_shown ) return;
    activate_row( _list.get_selected_row() );
  }

  /* Handle a mouse event on the listbox */
  private void activate_row( ListBoxRow row ) {
    var box   = (Box)row.get_child();
    var value = TextCompletionItem.get_text( box );
    if( _start_pos == _end_pos ) {
      _ct.insert( value, _da.undo_text );
    } else {
      _ct.replace( _start_pos, _end_pos, value, _da.undo_text );
    }
    hide();
  }

}
