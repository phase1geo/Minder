/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
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

using Gdk;
using Gtk;

private delegate void TableEditorAction();
private delegate void TableEditorToggleAction( bool active );

private class TableEditorUndoState : Object {

  public NodeTable? table { get; private set; default = null; }
  public int row { get; private set; default = -1; }
  public int column { get; private set; default = -1; }
  public string text { get; private set; default = ""; }

  //-------------------------------------------------------------
  // Stores a complete table snapshot for a structural or style change.
  public TableEditorUndoState.for_table( NodeTable table ) {
    this.table = table;
  }

  //-------------------------------------------------------------
  // Stores the previous text for a single edited cell.
  public TableEditorUndoState.for_text( NodeTableCell cell ) {
    row = cell.row;
    column = cell.column;
    text = cell.text;
  }

}

private class TableCellEntry : Grid {

  private const int MIN_WIDTH = 120;
  private const int MAX_WIDTH = 360;
  private const int MIN_HEIGHT = 34;
  private const int MAX_HEIGHT = 220;
  private const int HORIZONTAL_PADDING = 16;
  private const int VERTICAL_PADDING = 12;
  private TextView _editor;
  private TextTag _format_tag;

  public NodeTableCell table_cell { get; private set; }
  public TextBuffer buffer { get { return( _editor.buffer ); } }

  public signal void focused();

  //-------------------------------------------------------------
  // Creates an entry bound to a table cell.
  public TableCellEntry( NodeTableCell cell ) {
    table_cell = cell;
    hexpand = true;
    vexpand = true;
    add_css_class( "table-cell-editor" );
    _editor = new TextView() {
      wrap_mode = Gtk.WrapMode.WORD_CHAR,
      accepts_tab = false,
      left_margin = 6,
      right_margin = 6,
      top_margin = 4,
      bottom_margin = 4,
      hexpand = true,
      vexpand = true,
      valign = Align.FILL
    };
    _editor.add_css_class( "table-cell-text" );
    _editor.buffer.text = cell.text;
    _editor.notify["has-focus"].connect(() => {
      if( _editor.has_focus ) focused();
    });
    attach( _editor, 0, 0 );
    _format_tag = new TextTag( "cell-format" );
    _editor.buffer.tag_table.add( _format_tag );
    update_format();
  }

  //-------------------------------------------------------------
  // Returns all text currently displayed in the cell editor.
  public string get_text() {
    Gtk.TextIter start, end;
    _editor.buffer.get_bounds( out start, out end );
    return( _editor.buffer.get_text( start, end, true ) );
  }

  //-------------------------------------------------------------
  // Moves keyboard focus into the text editor.
  public void focus_text() {
    _editor.grab_focus();
  }

  //-------------------------------------------------------------
  // Resizes the editor to reveal wrapped text without dominating the table.
  public void update_size() {
    var layout = _editor.create_pango_layout( get_text() );
    int text_width, text_height;
    layout.get_pixel_size( out text_width, out text_height );
    var editor_width = int.min( MAX_WIDTH, int.max( MIN_WIDTH, text_width + HORIZONTAL_PADDING ) );
    layout.set_width( (editor_width - HORIZONTAL_PADDING) * Pango.SCALE );
    layout.set_wrap( Pango.WrapMode.WORD_CHAR );
    layout.get_pixel_size( out text_width, out text_height );
    width_request = editor_width;
    height_request = int.min( MAX_HEIGHT, int.max( MIN_HEIGHT, text_height + VERTICAL_PADDING ) );
    _editor.scroll_mark_onscreen( _editor.buffer.get_insert() );
  }

  //-------------------------------------------------------------
  // Mirrors the cell alignment and formatting in the editor.
  public void update_format() {
    switch( table_cell.alignment ) {
      case Pango.Alignment.CENTER :  _editor.justification = Gtk.Justification.CENTER;  break;
      case Pango.Alignment.RIGHT  :  _editor.justification = Gtk.Justification.RIGHT;   break;
      default                     :  _editor.justification = Gtk.Justification.LEFT;    break;
    }
    _format_tag.weight = table_cell.format_enabled( NodeTableFormat.BOLD ) ?
      (int)Pango.Weight.BOLD : (int)Pango.Weight.NORMAL;
    _format_tag.style = table_cell.format_enabled( NodeTableFormat.ITALIC ) ?
      Pango.Style.ITALIC : Pango.Style.NORMAL;
    _format_tag.underline = table_cell.format_enabled( NodeTableFormat.UNDERLINE ) ?
      Pango.Underline.SINGLE : Pango.Underline.NONE;
    _format_tag.strikethrough = table_cell.format_enabled( NodeTableFormat.STRIKETHROUGH );
    Gtk.TextIter start, end;
    _editor.buffer.get_bounds( out start, out end );
    _editor.buffer.remove_tag( _format_tag, start, end );
    _editor.buffer.apply_tag( _format_tag, start, end );
    if( table_cell.highlighted ) {
      add_css_class( "table-cell-highlighted" );
    } else {
      remove_css_class( "table-cell-highlighted" );
    }
    update_size();
  }

}

public class TableEditor {

  private const int MAX_UNDO_STATES = 50;
  private const int POPOVER_PAD = 20;   // Room for the popover arrow and shadow

  private DrawArea _draw_area;
  private Popover _popover;
  private Grid _grid;
  private Button _undo_button;
  private ModeButtons _alignment_buttons;
  private ToggleButton _highlight_button;
  private ToggleButton _bold_button;
  private ToggleButton _italic_button;
  private ToggleButton _underline_button;
  private ToggleButton _strikethrough_button;
  private Node? _node = null;
  private NodeTable? _table = null;
  private Array<TableCellEntry> _entries;
  private Array<TableEditorUndoState> _undo_states;
  private TableCellEntry? _active_entry = null;
  private int _anchor_row = -1;
  private int _anchor_column = -1;
  private int _last_row = -1;
  private int _last_column = -1;
  private bool _extend_selection = false;
  private double _drag_start_x = 0.0;
  private double _drag_start_y = 0.0;
  private EventControllerLegacy? _blocker = null;
  private Gtk.Window? _win = null;
  private ulong _active_id = 0;
  private uint _deactivate_id     = 0;
  private bool _popover_has_focus = false;

  public signal void changed( Node node, NodeTable? original_table );

  //-------------------------------------------------------------
  // Creates the table editor for the given canvas.
  public TableEditor( DrawArea draw_area ) {
    _draw_area = draw_area;
    _entries = new Array<TableCellEntry>();
    _undo_states = new Array<TableEditorUndoState>();
    create_ui();
  }

  //-------------------------------------------------------------
  // Returns true if the table editor is currently displayed.
  public bool is_shown() {
    return( _popover.visible );
  }

  //-------------------------------------------------------------
  // Blocks window from losing keyboard input.
  private void block_window_input() {
    var win = (Widget)_draw_area.get_root();
    _blocker = new EventControllerLegacy() {
      propagation_phase = PropagationPhase.CAPTURE
    };
    _blocker.event.connect((ev) => {
      switch( ev.get_event_type() ) {
        case Gdk.EventType.BUTTON_PRESS   :
        case Gdk.EventType.BUTTON_RELEASE :
        case Gdk.EventType.SCROLL         :
        case Gdk.EventType.KEY_PRESS      :
        case Gdk.EventType.KEY_RELEASE    :
        case Gdk.EventType.TOUCH_BEGIN    :
        case Gdk.EventType.TOUCH_END      :  return( true );   // swallow
        default                           :  return( false );
      }
    });
    win.add_controller( _blocker );
  }

  //-------------------------------------------------------------
  // Undoes block_window_input.
  private void unblock_window_input() {
    if( _blocker != null ) {
      ((Widget)_draw_area.get_root()).remove_controller( _blocker );
      _blocker = null;
    }
  }

  //-------------------------------------------------------------
  // Watches to see if the main window ever loses focus.
  private void watch_focus() {
    _win = _draw_area.get_root() as Gtk.Window;
    if( _win == null ) return;
    _active_id = _win.notify["is-active"].connect(() => {
      if( (_win == null) || _win.is_active || (_deactivate_id != 0) ) return;
      _deactivate_id = Timeout.add( 150, () => {
        _deactivate_id = 0;
        if( (_win != null) && !_win.is_active && !_popover_has_focus && _popover.visible ) {
          close_editor();
        }
        return( Source.REMOVE );
      });
    });
  }

  //-------------------------------------------------------------
  // Undoes the affects of watch_focus.
  private void unwatch_focus() {
    if( _deactivate_id != 0 ) {
      Source.remove( _deactivate_id );
      _deactivate_id = 0;
    }
    if( (_win != null) && (_active_id != 0) ) {
      _win.disconnect( _active_id );
    }
    _active_id = 0;
    _win       = null;
    _popover_has_focus = false;
  }

  //-------------------------------------------------------------
  // Sizes and positions the popover so that it always fits within
  // the window.  (x, y) is the anchor point in the canvas's
  // coordinates.
  private void place_popover( double x, double y ) {

    var win = (Widget)_draw_area.get_root();

    // Convert the anchor point into window coordinates
    Graphene.Point pt  = {(float)x, (float)y};
    Graphene.Point wpt;
    if( !_draw_area.compute_point( win, pt, out wpt ) ) {
      wpt = pt;
    }

    var win_w = win.get_width();
    var win_h = win.get_height();

    // Figure out how much of the popover is not the editing area
    int pw, ph;
    _popover.child.measure( Orientation.HORIZONTAL, -1, null, out pw, null, null );
    _popover.child.measure( Orientation.VERTICAL,   pw, null, out ph, null, null );

    // Keep the popover horizontally within the window
    var cx = double.max( (pw / 2.0), double.min( (win_w - (pw / 2.0)), wpt.x ) );
    var dx = cx - wpt.x;
    var dy = 0.0;

    var pos       = PositionType.BOTTOM;
    var has_arrow = true;

    if( (win_h - wpt.y) >= (ph + POPOVER_PAD) ) {
      pos = PositionType.BOTTOM;
    } else if( wpt.y >= (ph + POPOVER_PAD) ) {
      pos = PositionType.TOP;
    } else {
      // There is room neither above nor below the anchor point, so
      // center the popover vertically in the window without an arrow
      has_arrow = false;
      dy = ((win_h - ph) / 2.0) - wpt.y;
    }

    Gdk.Rectangle rect = {(int)(x + dx), (int)(y + dy), 1, 1};

    _popover.position     = pos;
    _popover.has_arrow    = has_arrow;
    _popover.pointing_to  = rect;

  }

  //-------------------------------------------------------------
  // Creates an icon-only action button with a tooltip.
  private Button make_icon_button( string icon, KeyCommand? key_command, string tooltip, owned TableEditorAction callback ) {
    var button = new Button.from_icon_name( icon ) {
      tooltip_markup = tooltip
    };
    if( key_command != null ) {
      _draw_area.win.register_widget_for_tooltip( button, key_command, tooltip );
    }
    button.clicked.connect( () => callback() );
    return( button );
  }

  //-------------------------------------------------------------
  // Creates a worded action button.
  private Button make_button( string label, owned TableEditorAction callback ) {
    var button = new Button.with_label( label );
    button.clicked.connect( () => callback() );
    return( button );
  }

  //-------------------------------------------------------------
  // Creates an icon-only toggle button with a tooltip.
  private ToggleButton make_toggle_button( string icon, string tooltip, owned TableEditorToggleAction callback ) {
    var button = new ToggleButton() {
      child = new Image.from_icon_name( icon ),
      tooltip_text = tooltip
    };
    button.clicked.connect(() => callback( button.active ));
    return( button );
  }

  //-------------------------------------------------------------
  // Creates the row-editing menu.
  private MenuButton make_rows_menu() {
    var win = _draw_area.win;
    var add_menu = new GLib.Menu();
    win.append_menu_item( add_menu, KeyCommand.TABLE_ADD_ROW_ABOVE, _( "Add Row Above" ) );
    win.append_menu_item( add_menu, KeyCommand.TABLE_ADD_ROW_BELOW, _( "Add Row Below" ) );
    var move_menu = new GLib.Menu();
    win.append_menu_item( move_menu, KeyCommand.TABLE_MOVE_ROW_UP,   _( "Move Row Up" ) );
    win.append_menu_item( move_menu, KeyCommand.TABLE_MOVE_ROW_DOWN, _( "Move Row Down" ) );
    var del_menu = new GLib.Menu();
    win.append_menu_item( del_menu, KeyCommand.TABLE_DELETE_ROWS, _( "Delete Selected Rows" ) );
    var menu = new GLib.Menu();
    menu.append_section( null, add_menu );
    menu.append_section( null, move_menu );
    menu.append_section( null, del_menu );
    var button = new MenuButton() {
      icon_name = "minder-table-row-symbolic",
      tooltip_text = _( "Row Actions" ),
      menu_model = menu
    };
    button.notify["active"].connect(() => {
      win.set_menu_item_enable( KeyCommand.TABLE_MOVE_ROW_UP,   can_move_selected_rows( -1 ) );
      win.set_menu_item_enable( KeyCommand.TABLE_MOVE_ROW_DOWN, can_move_selected_rows( 1 ) );
    });
    return( button );
  }

  //-------------------------------------------------------------
  // Creates the column-editing menu.
  private MenuButton make_columns_menu() {
    var win = _draw_area.win;
    var add_menu = new GLib.Menu();
    win.append_menu_item( add_menu, KeyCommand.TABLE_ADD_COL_LEFT,  _( "Add Column Left" ) );
    win.append_menu_item( add_menu, KeyCommand.TABLE_ADD_COL_RIGHT, _( "Add Column Right" ) );
    var move_menu = new GLib.Menu();
    win.append_menu_item( move_menu, KeyCommand.TABLE_MOVE_COL_LEFT,  _( "Move Column Left" ) );
    win.append_menu_item( move_menu, KeyCommand.TABLE_MOVE_COL_RIGHT, _( "Move Column Right" ) );
    var del_menu = new GLib.Menu();
    win.append_menu_item( del_menu, KeyCommand.TABLE_DELETE_COLS, _( "Delete Selected Columns" ) );
    var menu = new GLib.Menu();
    menu.append_section( null, add_menu );
    menu.append_section( null, move_menu );
    menu.append_section( null, del_menu );
    var button = new MenuButton() {
      icon_name = "minder-table-column-symbolic",
      tooltip_text = _( "Column Actions" ),
      menu_model = menu
    };
    button.notify["active"].connect(() => {
      win.set_menu_item_enable( KeyCommand.TABLE_MOVE_COL_LEFT,  can_move_selected_columns( -1 ) );
      win.set_menu_item_enable( KeyCommand.TABLE_MOVE_COL_RIGHT, can_move_selected_columns( 1 ) );
    });
    return( button );
  }

  //-------------------------------------------------------------
  // Builds the editor controls and popover.
  private void create_ui() {
    _grid = new Grid() {
      column_spacing = 2,
      row_spacing = 2,
      column_homogeneous = false
    };

    var drag = new GestureDrag() {
      button = Gdk.BUTTON_PRIMARY,
      propagation_phase = PropagationPhase.CAPTURE
    };
    _grid.add_controller( drag );
    drag.drag_begin.connect( (start_x, start_y) => {
      _drag_start_x = start_x;
      _drag_start_y = start_y;
      var cell = cell_at_position( start_x, start_y );
      if( cell != null ) {
        var state = drag.get_current_event_state();
        select_cell( cell, _extend_selection || ((state & ModifierType.SHIFT_MASK) != 0) );
      }
    });
    drag.drag_update.connect( (offset_x, offset_y) => {
      var cell = cell_at_position( _drag_start_x + offset_x, _drag_start_y + offset_y );
      if( cell != null ) {
        select_cell( cell, true );
      }
    });

    var scroller = new ScrolledWindow() {
      child = _grid,
      min_content_width = 520,
      min_content_height = 260,
      max_content_width = 850,
      max_content_height = 520,
      propagate_natural_width = true,
      propagate_natural_height = true
    };

    var edit_buttons = new Box( Orientation.HORIZONTAL, 5 );
    _undo_button = make_icon_button( "edit-undo-symbolic", null, _( "Undo Table Edit (Ctrl+Z)" ), undo_edit );
    _undo_button.sensitive = false;
    edit_buttons.append( _undo_button );
    edit_buttons.append( make_icon_button( "edit-paste-symbolic", null, _( "Paste Table" ), paste_table ) );
    edit_buttons.append( make_rows_menu() );
    edit_buttons.append( make_columns_menu() );
    edit_buttons.append( make_icon_button( "object-group-symbolic", KeyCommand.TABLE_MERGE_CELLS, _( "Merge Selection" ), merge_selection ) );
    edit_buttons.append( make_icon_button( "object-ungroup-symbolic", KeyCommand.TABLE_SPLIT_CELL, _( "Split Cell" ), split_cell ) );
    edit_buttons.append( make_icon_button( "edit-clear-symbolic", KeyCommand.TABLE_CLEAR_CELLS, _( "Clear Cells" ), clear_cells ) );
    edit_buttons.append( make_icon_button( "face-smile-symbolic", null, _( "Insert Emoji" ), insert_emoji ) );

    _alignment_buttons = new ModeButtons();
    _alignment_buttons.add_button( "format-justify-left-symbolic", null, _( "Align Left" ) );
    _alignment_buttons.add_button( "format-justify-center-symbolic", null, _( "Align Center" ) );
    _alignment_buttons.add_button( "format-justify-right-symbolic", null, _( "Align Right" ) );
    _alignment_buttons.changed.connect( set_selected_alignment );

    _highlight_button = make_toggle_button(
      "minder-table-highlight-symbolic", _( "Highlight Cells" ),
      set_selected_highlight
    );
    _bold_button = make_toggle_button(
      "format-text-bold-symbolic", _( "Bold" ),
      (active) => set_selected_format( NodeTableFormat.BOLD, active )
    );
    _italic_button = make_toggle_button(
      "format-text-italic-symbolic", _( "Italic" ),
      (active) => set_selected_format( NodeTableFormat.ITALIC, active )
    );
    _underline_button = make_toggle_button(
      "format-text-underline-symbolic", _( "Underline" ),
      (active) => set_selected_format( NodeTableFormat.UNDERLINE, active )
    );
    _strikethrough_button = make_toggle_button(
      "format-text-strikethrough-symbolic", _( "Strikethrough" ),
      (active) => set_selected_format( NodeTableFormat.STRIKETHROUGH, active )
    );

    var format_buttons = new Granite.Box( Orientation.HORIZONTAL, 0 ) {
      child_spacing = Granite.Box.Spacing.LINKED
    };
    format_buttons.append( _highlight_button );
    format_buttons.append( _bold_button );
    format_buttons.append( _italic_button );
    format_buttons.append( _underline_button );
    format_buttons.append( _strikethrough_button );

    var format_row = new Box( Orientation.HORIZONTAL, 8 );
    format_row.append( new Label( _( "Selected cells:" ) ) );
    format_row.append( _alignment_buttons );
    format_row.append( new Separator( Orientation.VERTICAL ) );
    format_row.append( format_buttons );

    var action_buttons = new Box( Orientation.HORIZONTAL, 5 );
    var delete_table = make_button( _( "Delete Table" ), remove_table );
    delete_table.add_css_class( "destructive-action" );
    action_buttons.append( delete_table );
    action_buttons.append( new Box( Orientation.HORIZONTAL, 0 ) { hexpand = true } );
    action_buttons.append( make_button( _( "Cancel" ), cancel ) );
    var apply = make_button( _( "Apply" ), apply_changes );
    apply.add_css_class( "suggested-action" );
    action_buttons.append( apply );

    var content = new Box( Orientation.VERTICAL, 8 ) {
      margin_start = 10,
      margin_end = 10,
      margin_top = 10,
      margin_bottom = 10
    };
    content.append( edit_buttons );
    content.append( format_row );
    content.append( scroller );
    content.append( action_buttons );

    var focus = new EventControllerFocus();
    content.add_controller( focus );
    focus.notify["contains-focus"].connect(() => {
      _popover_has_focus = focus.contains_focus;
    });

    _popover = new Popover() {
      child = content,
      autohide = false,
      position = PositionType.RIGHT
    };
    _popover.set_parent( _draw_area );
    _popover.closed.connect(() => {
      unblock_window_input();
      unwatch_focus();
    });

    var key = new EventControllerKey() {
      propagation_phase = PropagationPhase.CAPTURE
    };
    content.add_controller( key );
    key.key_pressed.connect( (keyval, keycode, state) => {
      if( (keyval == Gdk.Key.Shift_L) || (keyval == Gdk.Key.Shift_R) ) {
        _extend_selection = true;
      }
      if( _draw_area.win.shortcuts.execute( _draw_area.mmap, keyval, keycode, state ) ) {
        return( true );
      }
      if( ((state & ModifierType.CONTROL_MASK) != 0) &&
          ((state & ModifierType.SHIFT_MASK) == 0) &&
          ((keyval == Gdk.Key.z) || (keyval == Gdk.Key.Z)) ) {
        undo_edit();
        return( true );
      }
      return( false );
    });
    key.key_released.connect( (keyval, keycode, state) => {
      if( (keyval == Gdk.Key.Shift_L) || (keyval == Gdk.Key.Shift_R) ) {
        _extend_selection = false;
      }
    });

    var escape_key = new EventControllerKey() {
      propagation_phase = PropagationPhase.BUBBLE
    };
    content.add_controller( escape_key );
    escape_key.key_pressed.connect( (keyval, keycode, state) => {
      if( keyval == Gdk.Key.Escape ) {
        cancel();
        return( true );
      }
      return( false );
    });
  }

  //-------------------------------------------------------------
  // Opens an editable copy of the given node's table.
  public void edit_table( Node node ) {
    _node = node;
    _table = (node.table == null) ?
      new NodeTable( _draw_area.mmap, 2, 2 ) :
      new NodeTable.copy( _draw_area.mmap, node.table );
    _table.set_font(
      node.style.node_font.get_family(),
      node.style.node_font.get_size() / Pango.SCALE
    );
    _anchor_row = 0;
    _anchor_column = 0;
    _last_row = 0;
    _last_column = 0;
    _extend_selection = false;
    _undo_states.remove_range( 0, _undo_states.length );
    _undo_button.sensitive = false;
    rebuild_grid();
    place_popover( node.posx, node.posy );
    block_window_input();
    _popover.popup();
    watch_focus();
    _undo_button.grab_focus();
  }

  //-------------------------------------------------------------
  // Removes all widgets from the editable grid.
  private void clear_grid() {
    _active_entry = null;
    Widget? child = _grid.get_first_child();
    while( child != null ) {
      Widget? next = child.get_next_sibling();
      _grid.remove( child );
      child = next;
    }
    _entries.remove_range( 0, _entries.length );
  }

  //-------------------------------------------------------------
  // Rebuilds the entry widgets from the table model.
  private void rebuild_grid() {
    clear_grid();
    if( _table == null ) return;
    var cells = _table.cells();
    for( int index=0; index<cells.length; index++ ) {
      var cell = cells.index( index );
      var entry = new TableCellEntry( cell );
      entry.buffer.changed.connect( () => {
        save_text_undo_state( entry.table_cell );
        entry.table_cell.text = entry.get_text();
        entry.update_format();
        _table.update_layout();
      });
      entry.focused.connect(() => {
        _active_entry = entry;
      });
      var click = new GestureClick() {
        button = Gdk.BUTTON_PRIMARY,
        propagation_phase = PropagationPhase.CAPTURE
      };
      entry.add_controller( click );
      click.pressed.connect( (press_count, x, y) => {
        _active_entry = entry;
        var state = click.get_current_event_state();
        select_cell( entry.table_cell, _extend_selection || ((state & ModifierType.SHIFT_MASK) != 0) );
        entry.focus_text();
      });
      _grid.attach( entry, cell.column, cell.row, cell.col_span, cell.row_span );
      _entries.append_val( entry );
      if( (_active_entry == null) && cell.covers( _anchor_row, _anchor_column ) ) {
        _active_entry = entry;
      }
    }
    update_selection_style();
  }

  //-------------------------------------------------------------
  // Adds an undo state and keeps the local history bounded.
  private void append_undo_state( TableEditorUndoState state ) {
    _undo_states.append_val( state );
    if( _undo_states.length > MAX_UNDO_STATES ) {
      _undo_states.remove_index( 0 );
    }
    _undo_button.sensitive = true;
  }

  //-------------------------------------------------------------
  // Stores the current table before a structural or style change.
  private void save_table_undo_state() {
    if( _table == null ) return;
    append_undo_state( new TableEditorUndoState.for_table(
      new NodeTable.copy( _draw_area.mmap, _table )
    ) );
  }

  //-------------------------------------------------------------
  // Stores the current text before a cell edit.
  private void save_text_undo_state( NodeTableCell cell ) {
    if( _undo_states.length > 0 ) {
      var previous = _undo_states.index( _undo_states.length - 1 );
      if( (previous.table == null) &&
          (previous.row == cell.row) && (previous.column == cell.column) ) return;
    }
    append_undo_state( new TableEditorUndoState.for_text( cell ) );
  }

  //-------------------------------------------------------------
  // Drops a snapshot when its requested operation made no change.
  private void discard_last_undo_state() {
    if( _undo_states.length > 0 ) {
      _undo_states.remove_index( _undo_states.length - 1 );
    }
    _undo_button.sensitive = (_undo_states.length > 0);
  }

  //-------------------------------------------------------------
  // Restores the most recent in-editor change.
  private void undo_edit() {
    if( (_table == null) || (_undo_states.length == 0) ) return;
    var index = _undo_states.length - 1;
    var state = _undo_states.index( index );
    if( state.table != null ) {
      _table = new NodeTable.copy( _draw_area.mmap, state.table );
    } else {
      var cell = _table.cell_at( state.row, state.column );
      if( cell != null ) cell.text = state.text;
      _anchor_row = state.row;
      _anchor_column = state.column;
      _last_row = state.row;
      _last_column = state.column;
    }
    _undo_states.remove_index( index );
    _anchor_row = int.min( int.max( _anchor_row, 0 ), _table.rows - 1 );
    _last_row = int.min( int.max( _last_row, 0 ), _table.rows - 1 );
    _anchor_column = int.min( int.max( _anchor_column, 0 ), _table.columns - 1 );
    _last_column = int.min( int.max( _last_column, 0 ), _table.columns - 1 );
    rebuild_grid();
    _undo_button.sensitive = (_undo_states.length > 0);
    if( _active_entry != null ) {
      Gtk.TextIter end;
      _active_entry.buffer.get_end_iter( out end );
      _active_entry.buffer.place_cursor( end );
      _active_entry.focus_text();
    }
  }

  //-------------------------------------------------------------
  // Returns the table cell beneath a grid coordinate.
  private NodeTableCell? cell_at_position( double x, double y ) {
    Widget? widget = _grid.pick( x, y, PickFlags.DEFAULT );
    while( (widget != null) && (widget != _grid) ) {
      var entry = widget as TableCellEntry;
      if( entry != null ) return( entry.table_cell );
      widget = widget.parent;
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Selects a cell or extends the current rectangular selection.
  private void select_cell( NodeTableCell cell, bool extend ) {
    if( extend ) {
      _last_row = cell.row + cell.row_span - 1;
      _last_column = cell.column + cell.col_span - 1;
    } else {
      _anchor_row = cell.row;
      _anchor_column = cell.column;
      _last_row = cell.row + cell.row_span - 1;
      _last_column = cell.column + cell.col_span - 1;
    }
    update_selection_style();
  }

  //-------------------------------------------------------------
  // Returns the normalized bounds of the current selection.
  private void selection_bounds( out int first_row, out int first_column, out int last_row, out int last_column ) {
    first_row = int.min( _anchor_row, _last_row );
    first_column = int.min( _anchor_column, _last_column );
    last_row = int.max( _anchor_row, _last_row );
    last_column = int.max( _anchor_column, _last_column );
  }

  //-------------------------------------------------------------
  // Updates entry highlighting and formatting controls.
  private void update_selection_style() {
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    for( int index=0; index<_entries.length; index++ ) {
      var entry = _entries.index( index );
      var cell = entry.table_cell;
      var selected = cell.intersects( first_row, first_column, last_row, last_column );
      if( selected ) {
        entry.add_css_class( "table-cell-selected" );
      } else {
        entry.remove_css_class( "table-cell-selected" );
      }
    }
    update_format_controls();
  }

  //-------------------------------------------------------------
  // Returns true if a cell intersects the current selection.
  private bool cell_is_selected( NodeTableCell cell ) {
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    return( cell.intersects( first_row, first_column, last_row, last_column ) );
  }

  //-------------------------------------------------------------
  // Returns true if the given cell is located any of the selected rows.
  private bool cell_in_selected_rows( NodeTableCell cell ) {
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    return( cell.intersects( first_row, 0, last_row, (_table.columns - 1) ) ); 
  }

  //-------------------------------------------------------------
  // Returns true if the given cell is located any of the selected columns.
  private bool cell_in_selected_cols( NodeTableCell cell ) {
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    return( cell.intersects( 0, first_column, (_table.rows - 1), last_column ) ); 
  }

  //-------------------------------------------------------------
  // Reflects the active cell's style in the toolbar controls.
  private void update_format_controls() {
    if( _table == null ) return;
    var cell = _table.cell_at( _anchor_row, _anchor_column );
    if( cell == null ) return;
    switch( cell.alignment ) {
      case Pango.Alignment.CENTER :  _alignment_buttons.selected = 1;  break;
      case Pango.Alignment.RIGHT  :  _alignment_buttons.selected = 2;  break;
      default                     :  _alignment_buttons.selected = 0;  break;
    }
    _highlight_button.active = cell.highlighted;
    _bold_button.active = cell.format_enabled( NodeTableFormat.BOLD );
    _italic_button.active = cell.format_enabled( NodeTableFormat.ITALIC );
    _underline_button.active = cell.format_enabled( NodeTableFormat.UNDERLINE );
    _strikethrough_button.active = cell.format_enabled( NodeTableFormat.STRIKETHROUGH );
  }

  //-------------------------------------------------------------
  // Refreshes formatting on every visible entry.
  private void refresh_entry_formats() {
    for( int index=0; index<_entries.length; index++ ) {
      _entries.index( index ).update_format();
    }
  }

  //-------------------------------------------------------------
  // Applies text alignment to the selected cells.
  private void set_selected_alignment( int index ) {
    if( _table == null ) return;
    save_table_undo_state();
    var alignment = Pango.Alignment.LEFT;
    if( index == 1 ) alignment = Pango.Alignment.CENTER;
    if( index == 2 ) alignment = Pango.Alignment.RIGHT;
    var cells = _table.cells();
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    for( int cell_index=0; cell_index<cells.length; cell_index++ ) {
      var cell = cells.index( cell_index );
      if( cell_in_selected_cols( cell ) ) cell.set_text_alignment( alignment );
    }
    _table.update_layout();
    refresh_entry_formats();
  }

  //-------------------------------------------------------------
  // Applies highlighting to the selected cells.
  private void set_selected_highlight( bool enabled ) {
    if( _table == null ) return;
    save_table_undo_state();
    var cells = _table.cells();
    for( int cell_index=0; cell_index<cells.length; cell_index++ ) {
      var cell = cells.index( cell_index );
      if( cell_is_selected( cell ) ) cell.highlighted = enabled;
    }
    refresh_entry_formats();
  }

  //-------------------------------------------------------------
  // Applies a text format to the selected cells.
  private void set_selected_format( NodeTableFormat format, bool enabled ) {
    if( _table == null ) return;
    save_table_undo_state();
    var cells = _table.cells();
    for( int cell_index=0; cell_index<cells.length; cell_index++ ) {
      var cell = cells.index( cell_index );
      if( cell_is_selected( cell ) ) cell.set_format( format, enabled );
    }
    _table.update_layout();
    refresh_entry_formats();
  }

  //-------------------------------------------------------------
  // Merges the current selection.
  public void merge_selection() {
    if( _table == null ) return;
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    save_table_undo_state();
    if( _table.merge( first_row, first_column, last_row, last_column ) ) {
      _anchor_row = first_row;
      _anchor_column = first_column;
      _last_row = first_row;
      _last_column = first_column;
      rebuild_grid();
    } else {
      discard_last_undo_state();
    }
  }

  //-------------------------------------------------------------
  // Splits the merged cell at the selection anchor.
  public void split_cell() {
    if( _table == null ) return;
    save_table_undo_state();
    if( _table.split( _anchor_row, _anchor_column ) ) {
      _last_row = _anchor_row;
      _last_column = _anchor_column;
      rebuild_grid();
    } else {
      discard_last_undo_state();
    }
  }

  //-------------------------------------------------------------
  // Inserts a row above the current selection.
  public void add_row_above() {
    if( _table == null ) return;
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    save_table_undo_state();
    if( _table.insert_row( first_row ) ) {
      _anchor_row = first_row;
      _last_row = first_row;
      rebuild_grid();
    } else {
      discard_last_undo_state();
    }
  }

  //-------------------------------------------------------------
  // Inserts a row below the current selection.
  public void add_row_below() {
    if( _table == null ) return;
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    var inserted_row = last_row + 1;
    save_table_undo_state();
    if( _table.insert_row( inserted_row ) ) {
      _anchor_row = inserted_row;
      _last_row = inserted_row;
      rebuild_grid();
    } else {
      discard_last_undo_state();
    }
  }

  //-------------------------------------------------------------
  // Deletes all rows touched by the current selection.
  public void delete_rows() {
    if( _table == null ) return;
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    save_table_undo_state();
    _table.delete_rows( first_row, last_row );
    _anchor_row = int.min( first_row, _table.rows - 1 );
    _last_row = _anchor_row;
    _anchor_column = int.min( first_column, _table.columns - 1 );
    _last_column = _anchor_column;
    rebuild_grid();
  }

  //-------------------------------------------------------------
  // Inserts a column to the left of the current selection.
  public void add_column_left() {
    if( _table == null ) return;
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    save_table_undo_state();
    if( _table.insert_column( first_column ) ) {
      _anchor_column = first_column;
      _last_column = first_column;
      rebuild_grid();
    } else {
      discard_last_undo_state();
    }
  }

  //-------------------------------------------------------------
  // Inserts a column to the right of the current selection.
  public void add_column_right() {
    if( _table == null ) return;
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    var inserted_column = last_column + 1;
    save_table_undo_state();
    if( _table.insert_column( inserted_column ) ) {
      _anchor_column = inserted_column;
      _last_column = inserted_column;
      rebuild_grid();
    } else {
      discard_last_undo_state();
    }
  }

  //-------------------------------------------------------------
  // Deletes all columns touched by the current selection.
  public void delete_columns() {
    if( _table == null ) return;
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    save_table_undo_state();
    _table.delete_columns( first_column, last_column );
    _anchor_column = int.min( first_column, _table.columns - 1 );
    _last_column = _anchor_column;
    _anchor_row = int.min( first_row, _table.rows - 1 );
    _last_row = _anchor_row;
    rebuild_grid();
  }

  //-------------------------------------------------------------
  // Moves the selected rows up by one row.
  public void move_row_up() {
    move_selected_rows( -1 );
  }

  //-------------------------------------------------------------
  // Moves the selected rows down by one row.
  public void move_row_down() {
    move_selected_rows( 1 );
  }

  //-------------------------------------------------------------
  // Moves the selected columns left by one column.
  public void move_column_left() {
    move_selected_columns( -1 );
  }

  //-------------------------------------------------------------
  // Moves the selected columns right by one column.
  public void move_column_right() {
    move_selected_columns( 1 );
  }

  //-------------------------------------------------------------
  // Returns true only if the selected rows can be moved by the given
  // delta.
  private bool can_move_selected_rows( int delta ) {
    if( _table == null ) return( false );
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    return( _table.can_move_rows( first_row, last_row, delta ) );
  }

  //-------------------------------------------------------------
  // Shifts all rows touched by the selection and keeps them selected.
  private void move_selected_rows( int delta ) {
    if( _table == null ) return;
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    save_table_undo_state();
    if( _table.move_rows( ref first_row, ref last_row, delta ) ) {
      _anchor_row = first_row;
      _last_row   = last_row;
      rebuild_grid();
    } else {
      discard_last_undo_state();
    }
  }

  //-------------------------------------------------------------
  // Returns true only if the selected columns can be moved by the given
  // delta.
  private bool can_move_selected_columns( int delta ) {
    if( _table == null ) return( false );
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    save_table_undo_state();
    return( _table.can_move_columns( first_column, last_column, delta ) );
  }

  //-------------------------------------------------------------
  // Shifts all columns touched by the selection and keeps them selected.
  private void move_selected_columns( int delta ) {
    if( _table == null ) return;
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    save_table_undo_state();
    if( _table.move_columns( ref first_column, ref last_column, delta ) ) {
      _anchor_column = first_column;
      _last_column   = last_column;
      rebuild_grid();
    } else {
      discard_last_undo_state();
    }
  }

  //-------------------------------------------------------------
  // Clears all cells touched by the current selection.
  public void clear_cells() {
    if( _table == null ) return;
    int first_row, first_column, last_row, last_column;
    selection_bounds( out first_row, out first_column, out last_row, out last_column );
    save_table_undo_state();
    _table.clear_cells( first_row, first_column, last_row, last_column );
    rebuild_grid();
  }

  //-------------------------------------------------------------
  // Opens an emoji chooser for the active cell.
  private void insert_emoji() {
    var entry = _active_entry;
    if( entry == null ) return;
    var chooser = new EmojiChooser();
    chooser.set_parent( entry );
    chooser.emoji_picked.connect((emoji) => {
      Gtk.TextIter position;
      entry.buffer.get_iter_at_mark( out position, entry.buffer.get_insert() );
      entry.buffer.insert( ref position, emoji, emoji.length );
      entry.buffer.place_cursor( position );
      entry.focus_text();
    });
    chooser.closed.connect(() => chooser.unparent());
    chooser.popup();
  }

  //-------------------------------------------------------------
  // Replaces the editable table with tab-separated clipboard text.
  private void paste_table() {
    var clipboard = Display.get_default().get_clipboard();
    clipboard.read_text_async.begin( null, (object, result) => {
      try {
        var text = clipboard.read_text_async.end( result );
        if( (text != null) && (text.strip() != "") ) {
          save_table_undo_state();
          if( NodeTableTextParser.is_markdown_row( text ) ) {
            var lines = new Array<string>();
            foreach( var line in text.split( "\n" ) ) {
              lines.append_val( line );
            }
            _table = NodeTable.from_markdown( _draw_area.mmap, lines );
          }
          if( _table == null ) {
            _table = NodeTable.from_tsv( _draw_area.mmap, text );
          }
          if( _node != null ) {
            _table.set_font(
              _node.style.node_font.get_family(),
              _node.style.node_font.get_size() / Pango.SCALE
            );
          }
          _anchor_row = 0;
          _anchor_column = 0;
          _last_row = 0;
          _last_column = 0;
          rebuild_grid();
        }
      } catch( Error error ) {}
    });
  }

  //-------------------------------------------------------------
  // Commits the edited table and emits its original snapshot.
  private void apply_changes() {
    if( (_node == null) || (_table == null) ) return;
    var original = _node.table;
    _node.set_table( new NodeTable.copy( _draw_area.mmap, _table ) );
    changed( _node, original );
    close_editor();
  }

  //-------------------------------------------------------------
  // Removes the node's table and records its original snapshot.
  private void remove_table() {
    if( _node == null ) return;
    var original = _node.table;
    if( original != null ) {
      _node.set_table( null );
      changed( _node, original );
    }
    close_editor();
  }

  //-------------------------------------------------------------
  // Discards the editable copy and closes the popover.
  private void cancel() {
    close_editor();
  }

  //-------------------------------------------------------------
  // Closes the popover and restores clean canvas input state.
  private void close_editor() {
    _extend_selection = false;
    _draw_area.reset_modifier_keys();
    _popover.popdown();
    unblock_window_input();
    unwatch_focus();
    _draw_area.grab_focus();
  }

}
