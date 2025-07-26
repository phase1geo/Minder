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

using Gee;

public delegate void KeyCommandFunc( MindMap map );

public enum KeyCommand {
  DO_NOTHING,
  MISCELLANEOUS_START,
  CONTROL_PRESSED,
  SHOW_CONTEXTUAL_MENU,
  ZOOM_IN,
  ZOOM_OUT,
  UNDO_ACTION,
  REDO_ACTION,
  EDIT_NOTE,
  SHOW_CURRENT_SIDEBAR,
  EDIT_SELECTED,
  SHOW_SELECTED,
  MISCELLANEOUS_END,
  NODE_START,
  NODE_ALIGN_TOP,
  NODE_ALIGN_VCENTER,
  NODE_ALIGN_BOTTOM,
  NODE_ALIGN_LEFT,
  NODE_ALIGN_HCENTER,
  NODE_ALIGN_RIGHT,
  NODE_SELECT_ROOT,
  NODE_SELECT_PARENT,
  NODE_SELECT_CHILDREN,
  NODE_SELECT_CHILD,
  NODE_SELECT_TREE,
  NODE_SELECT_SIBLING_NEXT,
  NODE_SELECT_SIBLING_PREV,
  NODE_SELECT_LEFT,
  NODE_SELECT_RIGHT,
  NODE_SELECT_UP,
  NODE_SELECT_DOWN,
  NODE_SELECT_LINKED,
  NODE_SELECT_CONNECTION,
  NODE_SELECT_CALLOUT,
  NODE_CHANGE_LINK_COLOR,
  NODE_CHANGE_TASK,
  NODE_ADD_IMAGE,
  NODE_ADD_CALLOUT,
  NODE_ADD_GROUP,
  NODE_ADD_CONNECTION,
  NODE_TOGGLE_FOLDS_SHALLOW,
  NODE_TOGGLE_FOLDS_DEEP,
  NODE_TOGGLE_SEQUENCE,
  NODE_TOGGLE_LINKS,
  NODE_CENTER,
  NODE_SORT_ALPHABETICALLY,
  NODE_QUICK_ENTRY_INSERT,
  NODE_QUICK_ENTRY_REPLACE,
  NODE_PASTE_NODE_LINK,
  NODE_END,
  CONNECTION_START,
  CONNECTION_SELECT_FROM,
  CONNECTION_SELECT_TO,
  CONNECTION_SELECT_NEXT,
  CONNECTION_SELECT_PREV,
  CONNECTION_END,
  CALLOUT_START,
  CALLOUT_SELECT_NODE,
  CALLOUT_END,
  EDIT_START,
  EDIT_INSERT_NEWLINE,
  EDIT_INSERT_TAB,
  EDIT_INSERT_EMOJI,
  EDIT_REMOVE_WORD_NEXT,
  EDIT_REMOVE_WORD_PREV,
  EDIT_CURSOR_CHAR_NEXT,
  EDIT_CURSOR_CHAR_PREV,
  EDIT_CURSOR_UP,
  EDIT_CURSOR_DOWN,
  EDIT_CURSOR_WORD_NEXT,
  EDIT_CURSOR_WORD_PREV,
  EDIT_CURSOR_START,
  EDIT_CURSOR_END,
  EDIT_CURSOR_LINESTART,
  EDIT_CURSOR_LINEEND,
  EDIT_SELECT_CHAR_NEXT,
  EDIT_SELECT_CHAR_PREV,
  EDIT_SELECT_UP,
  EDIT_SELECT_DOWN,
  EDIT_SELECT_WORD_NEXT,
  EDIT_SELECT_WORD_PREV,
  EDIT_SELECT_START_UP,
  EDIT_SELECT_START_HOME,
  EDIT_SELECT_END_DOWN,
  EDIT_SELECT_END_END,
  EDIT_SELECT_LINESTART,
  EDIT_SELECT_LINEEND,
  EDIT_SELECT_ALL,
  EDIT_SELECT_NONE,
  EDIT_END;

  //-------------------------------------------------------------
  // Returns the string version of this key command.
  public string to_string() {
    switch( this ) {
      case DO_NOTHING                :  return( "none" );
      case CONTROL_PRESSED           :  return( "control" );
      case SHOW_CONTEXTUAL_MENU      :  return( "show-contextual_menu" );
      case ZOOM_IN                   :  return( "zoom-in" );
      case ZOOM_OUT                  :  return( "zoom-out" );
      case UNDO_ACTION               :  return( "undo-action" );
      case REDO_ACTION               :  return( "redo-action" );
      case EDIT_NOTE                 :  return( "edit-note" );
      case SHOW_CURRENT_SIDEBAR      :  return( "show-current-sidebar" );
      case EDIT_SELECTED             :  return( "edit-selected" );
      case SHOW_SELECTED             :  return( "show-selected" );
      case NODE_ALIGN_TOP            :  return( "node-align-top" );
      case NODE_ALIGN_VCENTER        :  return( "node-align-vcenter" );
      case NODE_ALIGN_BOTTOM         :  return( "node-align-bottom" );
      case NODE_ALIGN_LEFT           :  return( "node-align-left" );
      case NODE_ALIGN_HCENTER        :  return( "node-align-hcenter" );
      case NODE_ALIGN_RIGHT          :  return( "node-align-right" );
      case NODE_SELECT_ROOT          :  return( "node-select-root" );
      case NODE_SELECT_PARENT        :  return( "node-select-parent" );
      case NODE_SELECT_CHILDREN      :  return( "node-select-children" );
      case NODE_SELECT_CHILD         :  return( "node-select-child" );
      case NODE_SELECT_TREE          :  return( "node-select-tree" );
      case NODE_SELECT_SIBLING_NEXT  :  return( "node-select-sibling-next" );
      case NODE_SELECT_SIBLING_PREV  :  return( "node-select-sibling-prev" );
      case NODE_SELECT_LEFT          :  return( "node-select-left" );
      case NODE_SELECT_RIGHT         :  return( "node-select-right" );
      case NODE_SELECT_UP            :  return( "node-select-up" );
      case NODE_SELECT_DOWN          :  return( "node-select-down" );
      case NODE_SELECT_LINKED        :  return( "node-select-linked" );
      case NODE_SELECT_CONNECTION    :  return( "node-select-connection" );
      case NODE_SELECT_CALLOUT       :  return( "node-select-callout" );
      case NODE_CHANGE_LINK_COLOR    :  return( "node-change-link-color" );
      case NODE_CHANGE_TASK          :  return( "node-change-task" );
      case NODE_ADD_IMAGE            :  return( "node-add-image" );
      case NODE_ADD_CALLOUT          :  return( "node-add-callout" );
      case NODE_ADD_GROUP            :  return( "node-add-group" );
      case NODE_ADD_CONNECTION       :  return( "node-add-connection" );
      case NODE_TOGGLE_FOLDS_SHALLOW :  return( "node-toggle-folds-shallow" );
      case NODE_TOGGLE_FOLDS_DEEP    :  return( "node-toggle-folds-deep" );
      case NODE_TOGGLE_SEQUENCE      :  return( "node-toggle-sequence" );
      case NODE_TOGGLE_LINKS         :  return( "node-toggle-links" );
      case NODE_CENTER               :  return( "node-center" );
      case NODE_SORT_ALPHABETICALLY  :  return( "node-sort-alphabetically" );
      case NODE_QUICK_ENTRY_INSERT   :  return( "node-quick-entry-insert" );
      case NODE_QUICK_ENTRY_REPLACE  :  return( "node-quick-entry-replace" );
      case NODE_PASTE_NODE_LINK      :  return( "node-paste-node-link" );
      case CONNECTION_SELECT_FROM    :  return( "connection-select-from" );
      case CONNECTION_SELECT_TO      :  return( "connection-select-to" );
      case CONNECTION_SELECT_NEXT    :  return( "connection-select-next" );
      case CONNECTION_SELECT_PREV    :  return( "connection-select-prev" );
      case CALLOUT_SELECT_NODE       :  return( "callout-select-node" );
      case EDIT_INSERT_NEWLINE       :  return( "edit-insert-newline" );
      case EDIT_INSERT_TAB           :  return( "edit-insert-tab" );
      case EDIT_INSERT_EMOJI         :  return( "edit-insert-emoji" );
      case EDIT_REMOVE_WORD_NEXT     :  return( "edit-remove-word-next" );
      case EDIT_REMOVE_WORD_PREV     :  return( "edit-remove-word-prev" );
      case EDIT_CURSOR_CHAR_NEXT     :  return( "edit-cursor-char-next" );
      case EDIT_CURSOR_CHAR_PREV     :  return( "edit-cursor-char-prev" );
      case EDIT_CURSOR_UP            :  return( "edit-cursor-up" );
      case EDIT_CURSOR_DOWN          :  return( "edit-cursor-down" );
      case EDIT_CURSOR_WORD_NEXT     :  return( "edit-cursor-word-next" );
      case EDIT_CURSOR_WORD_PREV     :  return( "edit-cursor-word-prev" );
      case EDIT_CURSOR_START         :  return( "edit-cursor-start" );
      case EDIT_CURSOR_END           :  return( "edit-cursor-end" );
      case EDIT_CURSOR_LINESTART     :  return( "edit-cursor-linestart" );
      case EDIT_CURSOR_LINEEND       :  return( "edit-cursor-lineend" );
      case EDIT_SELECT_CHAR_NEXT     :  return( "edit-select-char-next" );
      case EDIT_SELECT_CHAR_PREV     :  return( "edit-select-char-prev" );
      case EDIT_SELECT_UP            :  return( "edit-select-up" );
      case EDIT_SELECT_DOWN          :  return( "edit-select-down" );
      case EDIT_SELECT_WORD_NEXT     :  return( "edit-select-word-next" );
      case EDIT_SELECT_WORD_PREV     :  return( "edit-select-word-prev" );
      case EDIT_SELECT_START_UP      :  return( "edit-select-start_up" );
      case EDIT_SELECT_START_HOME    :  return( "edit-select-start_home" );
      case EDIT_SELECT_END_DOWN      :  return( "edit-select-end_down" );
      case EDIT_SELECT_END_END       :  return( "edit-select-end_end" );
      case EDIT_SELECT_LINESTART     :  return( "edit-select-linestart" );
      case EDIT_SELECT_LINEEND       :  return( "edit-select-lineend" );
      case EDIT_SELECT_ALL           :  return( "edit-select-all" );
      case EDIT_SELECT_NONE          :  return( "edit-select-none" );
      default                        :  stdout.printf( "unhandled: %d\n", this );  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Parses the given string and returns the associated key command
  // enumerated value.
  public static KeyCommand parse( string str ) {
    switch( str ) {
      case "control"                   :  return( CONTROL_PRESSED );
      case "show-contextual-menu"      :  return( SHOW_CONTEXTUAL_MENU );
      case "zoom-in"                   :  return( ZOOM_IN );
      case "zoom-out"                  :  return( ZOOM_OUT );
      case "undo-action"               :  return( UNDO_ACTION );
      case "redo-action"               :  return( REDO_ACTION );
      case "edit-note"                 :  return( EDIT_NOTE );
      case "show-current-sidebar"      :  return( SHOW_CURRENT_SIDEBAR );
      case "edit-selected"             :  return( EDIT_SELECTED );
      case "show-selected"             :  return( SHOW_SELECTED );
      case "node-align-top"            :  return( NODE_ALIGN_TOP );
      case "node-align-vcenter"        :  return( NODE_ALIGN_VCENTER );
      case "node-align-bottom"         :  return( NODE_ALIGN_BOTTOM );
      case "node-align-left"           :  return( NODE_ALIGN_LEFT );
      case "node-align-hcenter"        :  return( NODE_ALIGN_HCENTER );
      case "node-align-right"          :  return( NODE_ALIGN_RIGHT );
      case "node-select-root"          :  return( NODE_SELECT_ROOT );
      case "node-select-parent"        :  return( NODE_SELECT_PARENT );
      case "node-select-children"      :  return( NODE_SELECT_CHILDREN );
      case "node-select-child"         :  return( NODE_SELECT_CHILD );
      case "node-select-tree"          :  return( NODE_SELECT_TREE );
      case "node-select-sibling-next"  :  return( NODE_SELECT_SIBLING_NEXT );
      case "node-select-sibling-prev"  :  return( NODE_SELECT_SIBLING_PREV );
      case "node-select-left"          :  return( NODE_SELECT_LEFT );
      case "node-select-right"         :  return( NODE_SELECT_RIGHT );
      case "node-select-up"            :  return( NODE_SELECT_UP );
      case "node-select-down"          :  return( NODE_SELECT_DOWN );
      case "node-select-linked"        :  return( NODE_SELECT_LINKED );
      case "node-select-connection"    :  return( NODE_SELECT_CONNECTION );
      case "node-select-callout"       :  return( NODE_SELECT_CALLOUT );
      case "node-change-link-color"    :  return( NODE_CHANGE_LINK_COLOR );
      case "node-change-task"          :  return( NODE_CHANGE_TASK );
      case "node-add-image"            :  return( NODE_ADD_IMAGE );
      case "node-add-callout"          :  return( NODE_ADD_CALLOUT );
      case "node-add-group"            :  return( NODE_ADD_GROUP );
      case "node-add-connection"       :  return( NODE_ADD_CONNECTION );
      case "node-toggle-folds-shallow" :  return( NODE_TOGGLE_FOLDS_SHALLOW );
      case "node-toggle-folds-deep"    :  return( NODE_TOGGLE_FOLDS_DEEP );
      case "node-toggle-sequence"      :  return( NODE_TOGGLE_SEQUENCE );
      case "node-toggle-links"         :  return( NODE_TOGGLE_LINKS );
      case "node-center"               :  return( NODE_CENTER );
      case "node-sort-alphabetically"  :  return( NODE_SORT_ALPHABETICALLY );
      case "node-quick-entry-insert"   :  return( NODE_QUICK_ENTRY_INSERT );
      case "node-quick-entry-replace"  :  return( NODE_QUICK_ENTRY_REPLACE );
      case "node-paste-node-link"      :  return( NODE_PASTE_NODE_LINK );
      case "connection-select-from"    :  return( CONNECTION_SELECT_FROM );
      case "connection-select-to"      :  return( CONNECTION_SELECT_TO );
      case "connection-select-next"    :  return( CONNECTION_SELECT_NEXT );
      case "connection-select-prev"    :  return( CONNECTION_SELECT_PREV );
      case "callout-select-node"       :  return( CALLOUT_SELECT_NODE );
      case "edit-insert-newline"       :  return( EDIT_INSERT_NEWLINE );
      case "edit-insert-tab"           :  return( EDIT_INSERT_TAB );
      case "edit-insert-emoji"         :  return( EDIT_INSERT_EMOJI );
      case "edit-remove-word-next"     :  return( EDIT_REMOVE_WORD_NEXT );
      case "edit-remove-word-prev"     :  return( EDIT_REMOVE_WORD_PREV );
      case "edit-cursor-char-next"     :  return( EDIT_CURSOR_CHAR_NEXT );
      case "edit-cursor-char-prev"     :  return( EDIT_CURSOR_CHAR_PREV );
      case "edit-cursor-up"            :  return( EDIT_CURSOR_UP );
      case "edit-cursor-down"          :  return( EDIT_CURSOR_DOWN );
      case "edit-cursor-word-next"     :  return( EDIT_CURSOR_WORD_NEXT );
      case "edit-cursor-word-prev"     :  return( EDIT_CURSOR_WORD_PREV );
      case "edit-cursor-start"         :  return( EDIT_CURSOR_START );
      case "edit-cursor-end"           :  return( EDIT_CURSOR_END );
      case "edit-cursor-linestart"     :  return( EDIT_CURSOR_LINESTART );
      case "edit-cursor-lineend"       :  return( EDIT_CURSOR_LINEEND );
      case "edit-select-char-next"     :  return( EDIT_SELECT_CHAR_NEXT );
      case "edit-select-char-prev"     :  return( EDIT_SELECT_CHAR_PREV );
      case "edit-select-up"            :  return( EDIT_SELECT_UP );
      case "edit-select-down"          :  return( EDIT_SELECT_DOWN );
      case "edit-select-word-next"     :  return( EDIT_SELECT_WORD_NEXT );
      case "edit-select-word-prev"     :  return( EDIT_SELECT_WORD_PREV );
      case "edit-select-start-up"      :  return( EDIT_SELECT_START_UP );
      case "edit-select-start-home"    :  return( EDIT_SELECT_START_HOME );
      case "edit-select-end-down"      :  return( EDIT_SELECT_END_DOWN );
      case "edit-select-end-end"       :  return( EDIT_SELECT_END_END );
      case "edit-select-linestart"     :  return( EDIT_SELECT_LINESTART );
      case "edit-select-lineend"       :  return( EDIT_SELECT_LINEEND );
      case "edit-select_all"           :  return( EDIT_SELECT_ALL );
      case "edit-select-none"          :  return( EDIT_SELECT_NONE );
      default                          :  return( DO_NOTHING );
    }
  }

  //-------------------------------------------------------------
  // Returns the label to display in the shortcut preferences for
  // this key command.
  public string shortcut_label() {
    switch( this ) {
      case MISCELLANEOUS_START       :  return( _( "Miscellaneous Commands" ) );
      case SHOW_CONTEXTUAL_MENU      :  return( _( "Show contextual menu" ) );
      case ZOOM_IN                   :  return( _( "Zoom in" ) );
      case ZOOM_OUT                  :  return( _( "Zoom out" ) );
      case UNDO_ACTION               :  return( _( "Undo last action" ) );
      case REDO_ACTION               :  return( _( "Redo last undone action" ) );
      case EDIT_NOTE                 :  return( _( "Edit note of current item" ) );
      case SHOW_CURRENT_SIDEBAR      :  return( _( "Show current tab in sidebar" ) );
      case EDIT_SELECTED             :  return( _( "Edit currently selected item" ) );
      case SHOW_SELECTED             :  return( _( "Show currently selected item" ) );
      case NODE_START                :  return( _( "Node Commands" ) );
      case NODE_ALIGN_TOP            :  return( _( "Align selected node top edges" ) );
      case NODE_ALIGN_VCENTER        :  return( _( "Align selected node vertical centers" ) );
      case NODE_ALIGN_BOTTOM         :  return( _( "Align selected node bottom edges" ) );
      case NODE_ALIGN_LEFT           :  return( _( "Align selected node left edges" ) );
      case NODE_ALIGN_HCENTER        :  return( _( "Align selected node horizontal centers" ) );
      case NODE_ALIGN_RIGHT          :  return( _( "Align selected node right edges" ) );
      case NODE_SELECT_ROOT          :  return( _( "Select root node of current node" ) );
      case NODE_SELECT_PARENT        :  return( _( "Select parent node of current node" ) );
      case NODE_SELECT_CHILDREN      :  return( _( "Select all child nodes of current node" ) );
      case NODE_SELECT_CHILD         :  return( _( "Select single child node of current node" ) );
      case NODE_SELECT_TREE          :  return( _( "Select all nodes in subtree of current node" ) );
      case NODE_SELECT_SIBLING_NEXT  :  return( _( "Select next sibling node of current node" ) );
      case NODE_SELECT_SIBLING_PREV  :  return( _( "Select previous sibling node of current node" ) );
      case NODE_SELECT_LEFT          :  return( _( "Select node to the left of current node" ) );
      case NODE_SELECT_RIGHT         :  return( _( "Select node to the right of current node" ) );
      case NODE_SELECT_UP            :  return( _( "Select node above current node" ) );
      case NODE_SELECT_DOWN          :  return( _( "Select node below current node" ) );
      case NODE_SELECT_LINKED        :  return( _( "Select linked node of current node" ) );
      case NODE_SELECT_CONNECTION    :  return( _( "Select connection of current node" ) );
      case NODE_SELECT_CALLOUT       :  return( _( "Select callout of current node" ) );
      case NODE_CHANGE_LINK_COLOR    :  return( _( "Change link color of current node" ) );
      case NODE_CHANGE_TASK          :  return( _( "Change task status of current node" ) );
      case NODE_ADD_IMAGE            :  return( _( "Add/Change image of current node" ) );
      case NODE_ADD_CALLOUT          :  return( _( "Add callout to current node" ) );
      case NODE_ADD_GROUP            :  return( _( "Add group for current node and its subtree" ) );
      case NODE_ADD_CONNECTION       :  return( _( "Start creation of connection from current node" ) );
      case NODE_TOGGLE_FOLDS_SHALLOW :  return( _( "Toggle folding of current node" ) );
      case NODE_TOGGLE_FOLDS_DEEP    :  return( _( "Toggle folding of current node subtree" ) );
      case NODE_TOGGLE_SEQUENCE      :  return( _( "Toggle sequence state of children of current node" ) );
      case NODE_TOGGLE_LINKS         :  return( _( "Toggle the node link state" ) );
      case NODE_CENTER               :  return( _( "Center current node in map canvas" ) );
      case NODE_SORT_ALPHABETICALLY  :  return( _( "Sort child nodes of current node alphabetically" ) );
      case NODE_QUICK_ENTRY_INSERT   :  return( _( "Use quick entry to insert nodes" ) );
      case NODE_QUICK_ENTRY_REPLACE  :  return( _( "Use quick entry to replace current node" ) );
      case NODE_PASTE_NODE_LINK      :  return( _( "Paste node link from clipboard into current node" ) );
      case CONNECTION_START          :  return( _( "Connection Commands" ) );
      case CONNECTION_SELECT_FROM    :  return( _( "Select connection source node" ) );
      case CONNECTION_SELECT_TO      :  return( _( "Select connection target node" ) );
      case CONNECTION_SELECT_NEXT    :  return( _( "Select next connection in map" ) );
      case CONNECTION_SELECT_PREV    :  return( _( "Select previous connection in map" ) );
      case CALLOUT_START             :  return( _( "Callout Commands" ) );
      case CALLOUT_SELECT_NODE       :  return( _( "Select callout node" ) );
      case EDIT_START                :  return( _( "Text Editing Commands" ) );
      case EDIT_INSERT_NEWLINE       :  return( _( "Insert newline character" ) );
      case EDIT_INSERT_TAB           :  return( _( "Insert TAB character" ) );
      case EDIT_INSERT_EMOJI         :  return( _( "Insert emoji" ) );
      case EDIT_REMOVE_WORD_NEXT     :  return( _( "Remove next word" ) );
      case EDIT_REMOVE_WORD_PREV     :  return( _( "Remove previous word" ) );
      case EDIT_CURSOR_CHAR_NEXT     :  return( _( "Move cursor to next character" ) );
      case EDIT_CURSOR_CHAR_PREV     :  return( _( "Move cursor to previous character" ) );
      case EDIT_CURSOR_UP            :  return( _( "Move cursor up one line" ) );
      case EDIT_CURSOR_DOWN          :  return( _( "Move cursor down one line" ) );
      case EDIT_CURSOR_WORD_NEXT     :  return( _( "Move cursor to beginning of next word" ) );
      case EDIT_CURSOR_WORD_PREV     :  return( _( "Move cursor to beginning of previous word" ) );
      case EDIT_CURSOR_START         :  return( _( "Move cursor to start of text" ) );
      case EDIT_CURSOR_END           :  return( _( "Move cursor to end of text" ) );
      case EDIT_CURSOR_LINESTART     :  return( _( "Move cursor to start of current line" ) );
      case EDIT_CURSOR_LINEEND       :  return( _( "Move cursor to end of current line" ) );
      case EDIT_SELECT_CHAR_NEXT     :  return( _( "Add next character to current selection" ) );
      case EDIT_SELECT_CHAR_PREV     :  return( _( "Add previous character to current selection" ) );
      case EDIT_SELECT_UP            :  return( _( "Add line up to current selection" ) );
      case EDIT_SELECT_DOWN          :  return( _( "Add line down to current selection" ) );
      case EDIT_SELECT_WORD_NEXT     :  return( _( "Add next word to current selection" ) );
      case EDIT_SELECT_WORD_PREV     :  return( _( "Add previous word to current selection" ) );
      case EDIT_SELECT_START_UP      :  return( _( "Add start of text to current selection (Control-Up)" ) );
      case EDIT_SELECT_START_HOME    :  return( _( "Add start of text to current selection (Control-Home)" ) );
      case EDIT_SELECT_END_DOWN      :  return( _( "Add end of text to current selection (Control-Down)" ) );
      case EDIT_SELECT_END_END       :  return( _( "Add end of text to current selection (Control-End)" ) );
      case EDIT_SELECT_LINESTART     :  return( _( "Add start of current line to current selection" ) );
      case EDIT_SELECT_LINEEND       :  return( _( "Add end of current line to current selection" ) );
      case EDIT_SELECT_ALL           :  return( _( "Select all text" ) );
      case EDIT_SELECT_NONE          :  return( _( "Deselect all text" ) );
      default                        :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Returns function to execute for this key command.
  public KeyCommandFunc get_func() {
    switch( this ) {
      case DO_NOTHING                :  return( do_nothing );
      case CONTROL_PRESSED           :  return( control_pressed );
      case SHOW_CONTEXTUAL_MENU      :  return( show_contextual_menu );
      case ZOOM_IN                   :  return( zoom_in );
      case ZOOM_OUT                  :  return( zoom_out );
      case UNDO_ACTION               :  return( undo_action );
      case REDO_ACTION               :  return( redo_action );
      case EDIT_NOTE                 :  return( edit_note );
      case SHOW_CURRENT_SIDEBAR      :  return( show_current_sidebar );
      case EDIT_SELECTED             :  return( edit_selected );
      case SHOW_SELECTED             :  return( show_selected );
      case NODE_ALIGN_TOP            :  return( node_align_top );
      case NODE_ALIGN_VCENTER        :  return( node_align_vcenter );
      case NODE_ALIGN_BOTTOM         :  return( node_align_bottom );
      case NODE_ALIGN_LEFT           :  return( node_align_left );
      case NODE_ALIGN_HCENTER        :  return( node_align_hcenter );
      case NODE_ALIGN_RIGHT          :  return( node_align_right );
      case NODE_SELECT_ROOT          :  return( node_select_root );
      case NODE_SELECT_PARENT        :  return( node_select_parent );
      case NODE_SELECT_CHILDREN      :  return( node_select_children );
      case NODE_SELECT_CHILD         :  return( node_select_child );
      case NODE_SELECT_TREE          :  return( node_select_tree );
      case NODE_SELECT_SIBLING_NEXT  :  return( node_select_sibling_next );
      case NODE_SELECT_SIBLING_PREV  :  return( node_select_sibling_previous );
      case NODE_SELECT_LEFT          :  return( node_select_left );
      case NODE_SELECT_RIGHT         :  return( node_select_right );
      case NODE_SELECT_UP            :  return( node_select_up );
      case NODE_SELECT_DOWN          :  return( node_select_down );
      case NODE_SELECT_LINKED        :  return( node_select_linked );
      case NODE_SELECT_CONNECTION    :  return( node_select_connection );
      case NODE_SELECT_CALLOUT       :  return( node_select_callout );
      case NODE_CHANGE_LINK_COLOR    :  return( node_change_link_color );
      case NODE_CHANGE_TASK          :  return( node_change_task );
      case NODE_ADD_IMAGE            :  return( node_add_image );
      case NODE_ADD_CALLOUT          :  return( node_add_callout );
      case NODE_ADD_GROUP            :  return( node_add_group );
      case NODE_ADD_CONNECTION       :  return( node_add_connection );
      case NODE_TOGGLE_FOLDS_SHALLOW :  return( node_toggle_folds_shallow );
      case NODE_TOGGLE_FOLDS_DEEP    :  return( node_toggle_folds_deep );
      case NODE_TOGGLE_SEQUENCE      :  return( node_toggle_sequence );
      case NODE_TOGGLE_LINKS         :  return( node_toggle_links );
      case NODE_CENTER               :  return( node_center );
      case NODE_SORT_ALPHABETICALLY  :  return( node_sort_alphabetically );
      case NODE_QUICK_ENTRY_INSERT   :  return( node_quick_entry_insert );
      case NODE_QUICK_ENTRY_REPLACE  :  return( node_quick_entry_replace );
      case NODE_PASTE_NODE_LINK      :  return( node_paste_node_link );
      case CONNECTION_SELECT_FROM    :  return( connection_select_from_node );
      case CONNECTION_SELECT_TO      :  return( connection_select_to_node );
      case CONNECTION_SELECT_NEXT    :  return( connection_select_next );
      case CONNECTION_SELECT_PREV    :  return( connection_select_previous );
      case CALLOUT_SELECT_NODE       :  return( callout_select_node );
      case EDIT_INSERT_NEWLINE       :  return( edit_insert_newline );
      case EDIT_INSERT_TAB           :  return( edit_insert_tab );
      case EDIT_INSERT_EMOJI         :  return( edit_insert_emoji );
      case EDIT_REMOVE_WORD_NEXT     :  return( edit_remove_word_next );
      case EDIT_REMOVE_WORD_PREV     :  return( edit_remove_word_previous );
      case EDIT_CURSOR_CHAR_NEXT     :  return( edit_cursor_char_next );
      case EDIT_CURSOR_CHAR_PREV     :  return( edit_cursor_char_previous );
      case EDIT_CURSOR_UP            :  return( edit_cursor_up );
      case EDIT_CURSOR_DOWN          :  return( edit_cursor_down );
      case EDIT_CURSOR_WORD_NEXT     :  return( edit_cursor_word_next );
      case EDIT_CURSOR_WORD_PREV     :  return( edit_cursor_word_previous );
      case EDIT_CURSOR_START         :  return( edit_cursor_to_start );
      case EDIT_CURSOR_END           :  return( edit_cursor_to_end );
      case EDIT_CURSOR_LINESTART     :  return( edit_cursor_to_linestart );
      case EDIT_CURSOR_LINEEND       :  return( edit_cursor_to_lineend );
      case EDIT_SELECT_CHAR_NEXT     :  return( edit_select_char_next );
      case EDIT_SELECT_CHAR_PREV     :  return( edit_select_char_previous );
      case EDIT_SELECT_UP            :  return( edit_select_up );
      case EDIT_SELECT_DOWN          :  return( edit_select_down );
      case EDIT_SELECT_WORD_NEXT     :  return( edit_select_word_next );
      case EDIT_SELECT_WORD_PREV     :  return( edit_select_word_previous );
      case EDIT_SELECT_START_UP      :  return( edit_select_start_up );
      case EDIT_SELECT_START_HOME    :  return( edit_select_start_home );
      case EDIT_SELECT_END_DOWN      :  return( edit_select_end_down );
      case EDIT_SELECT_END_END       :  return( edit_select_end_end );
      case EDIT_SELECT_LINESTART     :  return( edit_select_linestart );
      case EDIT_SELECT_LINEEND       :  return( edit_select_lineend );
      case EDIT_SELECT_ALL           :  return( edit_select_all );
      case EDIT_SELECT_NONE          :  return( edit_deselect_all );
      default                        :  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for a node.
  public bool for_node() {
    return( ((NODE_START < this) && (this < NODE_END)) || for_any() );
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for a connection.
  public bool for_connection() {
    return( ((CONNECTION_START < this) && (this < CONNECTION_END)) || for_any() );
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for a callout.
  public bool for_callout() {
    return( ((CALLOUT_START < this) && (this < CALLOUT_END)) || for_any() );
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for any node, connection
  // or callout selected in the map.
  public bool for_any() {
    switch( this ) {
      case EDIT_NOTE            :
      case SHOW_CURRENT_SIDEBAR :
      case EDIT_SELECTED        :
      case SHOW_SELECTED        :  return( true );
      default                   :  return( false );
    }
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid when nothing is selected
  // in the map.
  public bool for_none() {
    switch( this ) {
      case NODE_QUICK_ENTRY_INSERT :  return( true );
      default                      :  return( false );
    }
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for editing.
  public bool for_editing() {
    return( (EDIT_START < this) && (this < EDIT_END) );
  }

  //-------------------------------------------------------------
  // Returns true if this key command is able to have a shortcut
  // associated with it.
  public bool viewable() {
    return( (this != DO_NOTHING) && (this != CONTROL_PRESSED) && !is_start() && !is_end() );
  }

  //-------------------------------------------------------------
  // Returns true if this command can have its shortcut be edited.
  public bool editable() {
    if( viewable() ) {
      switch( this ) {
        default :  return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if this key command is a start of command block.
  public bool is_start() {
    switch( this ) {
      case MISCELLANEOUS_START :
      case NODE_START          :
      case CONNECTION_START    :
      case CALLOUT_START       :
      case EDIT_START          :  return( true );
      default                  :  return( false );
    }
  }

  //-------------------------------------------------------------
  // Returns true if this key command is an end of command block.
  public bool is_end() {
    switch( this ) {
      case MISCELLANEOUS_END :
      case NODE_END          :
      case CONNECTION_END    :
      case CALLOUT_END       :
      case EDIT_END          :  return( true );
      default                :  return( false );
    }
  }

  //-------------------------------------------------------------
  // COMMANDS
  //-------------------------------------------------------------

  //-------------------------------------------------------------
  // ADMINISTRATIVE FUNCTIONS

  public static void do_nothing( MindMap map ) {}

  public static void control_pressed( MindMap map ) {
    // TODO - map.set_control( true );
  }

  //-------------------------------------------------------------
  // GENERAL FUNCTIONS

  public static void show_contextual_menu( MindMap map ) {
    map.canvas.show_contextual_menu( map.canvas.scaled_x, map.canvas.scaled_y );
  }

  public static void zoom_in( MindMap map ) {
    map.canvas.zoom_in();
  }

  public static void zoom_out( MindMap map ) {
    map.canvas.zoom_out();
  }

  public static void undo_action( MindMap map ) {
    if( map.undo_buffer.undoable() ) {
      map.undo_buffer.undo();
    }
  }

  public static void redo_action( MindMap map ) {
    if( map.undo_buffer.redoable() ) {
      map.undo_buffer.redo();
    }
  }

  public static void edit_note( MindMap map ) {
    map.canvas.show_properties( "current", PropertyGrab.NOTE ); 
  }

  public static void show_current_sidebar( MindMap map ) {
    map.canvas.show_properties( "current", PropertyGrab.FIRST );
  }

  public static void edit_selected( MindMap map ) {
    var current_node = map.get_current_node();
    if( current_node != null ) {
      map.model.set_node_mode( current_node, NodeMode.EDITABLE );
      map.queue_draw();
      return;
    }
    var current_conn = map.get_current_connection();
    if( current_conn != null ) {
      current_conn.edit_title_begin( map );
      map.model.set_connection_mode( current_conn, ConnMode.EDITABLE );
      map.queue_draw();
      return;
    }
    var current_call = map.get_current_callout();
    if( current_call != null ) {
      map.model.set_callout_mode( current_call, CalloutMode.EDITABLE );
      map.queue_draw();
      return;
    }
  }

  public static void show_selected( MindMap map ) {
    map.canvas.see();
  }

  //-------------------------------------------------------------
  // NODE FUNCTIONS

  public static void node_align_top( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_top( map, map.selected.nodes() );
    }
  }

  public static void node_align_vcenter( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_vcenter( map, map.selected.nodes() );
    }
  }

  public static void node_align_bottom( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_bottom( map, map.selected.nodes() );
    }
  }

  public static void node_align_left( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_left( map, map.selected.nodes() );
    }
  }

  public static void node_align_hcenter( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_hcenter( map, map.selected.nodes() );
    }
  }

  public static void node_align_right( MindMap map ) {
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_right( map, map.selected.nodes() );
    }
  }

  public static void node_select_root( MindMap map ) {
    map.select_root_node();
  }

  public static void node_select_parent( MindMap map ) {
    map.select_parent_nodes();
  }

  public static void node_select_children( MindMap map ) {
    map.select_child_nodes();
  }

  public static void node_select_child( MindMap map ) {
    map.select_child_node();
  }

  public static void node_select_tree( MindMap map ) {
    map.select_node_tree();
  }

  public static void node_select_sibling_next( MindMap map ) {
    map.select_sibling_node( 1 );
  }

  public static void node_select_sibling_previous( MindMap map ) {
    map.select_sibling_node( -1 );
  }

  public static void node_select_left( MindMap map ) {
    var current   = map.get_current_node();
    var left_node = map.model.get_node_left( current );
    if( map.select_node( left_node ) ) {
      map.queue_draw();
    }
  }

  public static void node_select_right( MindMap map ) {
    var current    = map.get_current_node();
    var right_node = map.model.get_node_right( current );
    if( map.select_node( right_node ) ) {
      map.queue_draw();
    }
  }

  public static void node_select_up( MindMap map ) {
    var current = map.get_current_node();
    var up_node = map.model.get_node_up( current );
    if( map.select_node( up_node ) ) {
      map.queue_draw();
    }
  }

  public static void node_select_down( MindMap map ) {
    var current   = map.get_current_node();
    var down_node = map.model.get_node_down( current );
    if( map.select_node( down_node ) ) {
      map.queue_draw();
    }
  }

  public static void node_select_linked( MindMap map ) {
    map.select_linked_node();
  }

  public static void node_select_connection( MindMap map ) {
    map.select_attached_connection();
  }

  public static void node_select_callout( MindMap map ) {
    map.select_callout();
  }

  public static void node_change_link_color( MindMap map ) {
    map.change_current_link_color();
  }

  public static void node_change_task( MindMap map ) {
    var current = map.get_current_node();
    if( current != null ) {
      if( current.task_enabled() ) {
        if( current.task_done() ) {
          map.model.change_current_task( false, false );
        } else {
          map.model.change_current_task( true, true );
        }
      } else {
        map.model.change_current_task( true, false );
      }
    }
  }

  public static void node_add_image( MindMap map ) {
    map.model.add_current_image();
  }

  public static void node_add_callout( MindMap map ) {
    map.model.add_callout();
  }

  public static void node_add_group( MindMap map ) {
    map.model.add_group();
  }

  public static void node_add_connection( MindMap map ) {
    map.model.start_connection( true, false );
  }

  public static void node_toggle_folds_shallow( MindMap map ) {
    var current = map.get_current_node();
    if( current != null ) {
      map.model.toggle_fold( current, false );
    }
  }

  public static void node_toggle_folds_deep( MindMap map ) {
    var current = map.get_current_node();
    if( current != null ) {
      map.model.toggle_fold( current, true );
    }
  }

  public static void node_toggle_sequence( MindMap map ) {
    map.model.toggle_sequence();
  }

  public static void node_toggle_links( MindMap map ) {
    map.model.toggle_links();
  }

  public static void node_center( MindMap map ) {
    map.canvas.center_current_node();
  }

  public static void node_sort_alphabetically( MindMap map ) {
    map.model.sort_alphabetically();
  }

  public static void node_quick_entry_insert( MindMap map ) {
    stdout.printf( "HERE!\n" );
    var quick_entry = new QuickEntry( map, false, map.settings );
    quick_entry.preload( "- " );
  }

  public static void node_quick_entry_replace( MindMap map ) {
    var quick_entry = new QuickEntry( map, true, map.settings );
    var export      = (ExportText)map.win.exports.get_by_name( "text" );
    quick_entry.preload( export.export_node( map, map.get_current_node(), "" ) );
  }

  public static void node_paste_node_link( MindMap map ) {
    map.canvas.do_paste_node_link();
  }

  /*
    add_shortcut( Key.k,            true, false, false, "add-url" );
    add_shortcut( Key.k,            true, true,  false, "remove-url" );

    add_shortcut( Key.w,            true, false, false, "close-map" );
*/

  //-------------------------------------------------------------
  // CONNECTION FUNCTIONS

  public static void connection_select_from_node( MindMap map ) {
    map.select_connection_node( true );
  }

  public static void connection_select_to_node( MindMap map ) {
    map.select_connection_node( false );
  }

  public static void connection_select_next( MindMap map ) {
    map.select_connection( 1 );
  }

  public static void connection_select_previous( MindMap map ) {
    map.select_connection( -1 );
  }

  //-------------------------------------------------------------
  // CALLOUT FUNCTIONS

  public static void callout_select_node( MindMap map ) {
    map.select_callout_node();
  }

  //-------------------------------------------------------------
  // EDITING FUNCTIONS

  //-------------------------------------------------------------
  // Private method that returns the canvas text of the current
  // item being edited.  If nothing is being edited, returns null.
  private static CanvasText? get_canvas_text( MindMap map ) {
    if( map.is_node_editable() ) {
      return( map.get_current_node().name );
    } else if( map.is_connection_editable() ) {
      return( map.get_current_connection().title );
    } else if( map.is_callout_editable() ) {
      return( map.get_current_callout().text );
    }
    return( null );
  }

  //-------------------------------------------------------------
  // Helper function that should be called whenever text changes
  // while editing.
  private static void text_changed( MindMap map ) {
    map.current_changed( map );
    map.queue_draw();
  }

  //-------------------------------------------------------------
  // Helper function that will insert a given string into the
  // current text context.
  private static void insert_text( MindMap map, string str ) {
    var text = get_canvas_text( map );
    if( text != null ) {
      text.insert( str, map.undo_text );
      text_changed( map );
    }
  }

  //-------------------------------------------------------------
  // Helper function that moves the cursor in a given direction.
  private static void edit_cursor( MindMap map, string dir ) {
    var text = get_canvas_text( map );
    if( text != null ) {
      switch( dir ) {
        case "char-next" :  text.move_cursor( 1 );                break;
        case "char-prev" :  text.move_cursor( -1 );               break;
        case "up"        :  text.move_cursor_vertically( -1 );    break;
        case "down"      :  text.move_cursor_vertically( 1 );     break;
        case "word-next" :  text.move_cursor_by_word( 1 );        break;
        case "word-prev" :  text.move_cursor_by_word( -1 );       break;
        case "start"     :  text.move_cursor_to_start();          break;
        case "end"       :  text.move_cursor_to_end();            break;
        case "linestart" :  text.move_cursor_to_start_of_line();  break;
        case "lineend"   :  text.move_cursor_to_end_of_line();    break;
        default          :  return;
      }
      map.queue_draw();
    }
  }

  //-------------------------------------------------------------
  // Helper function that changes the selection in a given direction.
  private static void edit_selection( MindMap map, string dir ) {
    var text = get_canvas_text( map );
    if( text != null ) {
      switch( dir ) {
        case "char-next"  :  text.selection_by_char( 1 );              break;
        case "char-prev"  :  text.selection_by_char( -1 );             break;
        case "up"         :  text.selection_vertically( -1 );          break;
        case "down"       :  text.selection_vertically( 1 );           break;
        case "word-next"  :  text.selection_by_word( 1 );              break;
        case "word-prev"  :  text.selection_by_word( -1 );             break;
        case "start-up"   :  text.selection_to_start( false );         break;
        case "start-home" :  text.selection_to_start( true );          break;
        case "end-down"   :  text.selection_to_end( false );           break;
        case "end-end"    :  text.selection_to_end( true );            break;
        case "linestart"  :  text.selection_to_start_of_line( true );  break;
        case "lineend"    :  text.selection_to_end_of_line( true );    break;
        case "all"        :  text.set_cursor_all( false );             break;
        case "none"       :  text.clear_selection();                   break;
        default           :  return;
      }
      map.queue_draw();
    }
  }

  public static void edit_insert_newline( MindMap map ) {
    insert_text( map, "\n" );
  }

  public static void edit_insert_tab( MindMap map ) {
    insert_text( map, "\t" );
  }

  public static void edit_insert_emoji( MindMap map ) {
    var text = get_canvas_text( map );
    if( text != null ) {
      map.canvas.insert_emoji( text );
    }
  }

  public static void edit_remove_word_previous( MindMap map ) {
    var text = get_canvas_text( map );
    if( text != null ) {
      text.backspace_word( map.undo_text );
      text_changed( map );
    }
  }

  public static void edit_remove_word_next( MindMap map ) {
    var text = get_canvas_text( map );
    if( text != null ) {
      text.delete_word( map.undo_text );
      text_changed( map );
    }
  }

  public static void edit_cursor_char_next( MindMap map ) {
    edit_cursor( map, "char-next" );
  }

  public static void edit_cursor_char_previous( MindMap map ) {
    edit_cursor( map, "char-prev" );
  }

  public static void edit_cursor_up( MindMap map ) {
    edit_cursor( map, "up" );
  }

  public static void edit_cursor_down( MindMap map ) {
    edit_cursor( map, "down" );
  }

  public static void edit_cursor_word_next( MindMap map ) {
    edit_cursor( map, "word-next" );
  }

  public static void edit_cursor_word_previous( MindMap map ) {
    edit_cursor( map, "word-prev" );
  }

  public static void edit_cursor_to_start( MindMap map ) {
    edit_cursor( map, "start" );
  }

  public static void edit_cursor_to_end( MindMap map ) {
    edit_cursor( map, "end" );
  }

  public static void edit_cursor_to_linestart( MindMap map ) {
    edit_cursor( map, "linestart" );
  }

  public static void edit_cursor_to_lineend( MindMap map ) {
    edit_cursor( map, "lineend" );
  }

  public static void edit_select_char_next( MindMap map ) {
    edit_selection( map, "char-next" );
  }

  public static void edit_select_char_previous( MindMap map ) {
    edit_selection( map, "char-prev" );
  }

  public static void edit_select_up( MindMap map ) {
    edit_selection( map, "up" );
  }

  public static void edit_select_down( MindMap map ) {
    edit_selection( map, "down" );
  }

  public static void edit_select_word_next( MindMap map ) {
    edit_selection( map, "word-next" );
  }

  public static void edit_select_word_previous( MindMap map ) {
    edit_selection( map, "word-prev" );
  }

  public static void edit_select_start_up( MindMap map ) {
    edit_selection( map, "start-up" );
  }

  public static void edit_select_start_home( MindMap map ) {
    edit_selection( map, "start-home" );
  }

  public static void edit_select_end_down( MindMap map ) {
    edit_selection( map, "end-down" );
  }

  public static void edit_select_end_end( MindMap map ) {
    edit_selection( map, "end-end" );
  }

  public static void edit_select_linestart( MindMap map ) {
    edit_selection( map, "linestart" );
  }

  public static void edit_select_lineend( MindMap map ) {
    edit_selection( map, "lineend" );
  }

  public static void edit_select_all( MindMap map ) {
    edit_selection( map, "all" );
  }

  public static void edit_deselect_all( MindMap map ) {
    edit_selection( map, "none" );
  }

  /*
    add_shortcut( Key.c,            true, false, false, "copy" );
    add_shortcut( Key.x,            true, false, false, "cut" );
    add_shortcut( Key.v,            true, false, false, "paste-insert" );
    add_shortcut( Key.v,            true, true,  false, "paste-replace" );

    add_shortcut( Key.e,            true, true,  false, "quick-entry-insert" );
    add_shortcut( Key.r,            true, true,  false, "quick-entry-replace" );
    add_shortcut( Key.k,            true, false, false, "add-url" );
    add_shortcut( Key.k,            true, true,  false, "remove-url" );

    add_shortcut( Key.w,            true, false, false, "close-map" );

    add_shortcut( Key.y,            true, false, false, "paste-node-link" );
  */

}
