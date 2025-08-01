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
  GENERAL_START,
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
  REMOVE_STICKER_SELECTED,
  ESCAPE,
  GENERAL_END,
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
  NODE_RANDOMIZE_LINK_COLOR,
  NODE_REPARENT_LINK_COLOR,
  NODE_CHANGE_TASK,
  NODE_ADD_ROOT,
  NODE_ADD_SIBLING_AFTER,
  NODE_ADD_SIBLING_BEFORE,
  NODE_ADD_CHILD,
  NODE_ADD_PARENT,
  NODE_CHANGE_IMAGE,
  NODE_REMOVE_IMAGE,
  NODE_TOGGLE_CALLOUT,
  NODE_ADD_GROUP,
  NODE_ADD_CONNECTION,
  NODE_TOGGLE_FOLDS_SHALLOW,
  NODE_TOGGLE_FOLDS_DEEP,
  NODE_TOGGLE_SEQUENCE,
  NODE_TOGGLE_LINKS,
  NODE_CENTER,
  NODE_SORT_ALPHABETICALLY,
  NODE_SORT_RANDOMLY,
  NODE_QUICK_ENTRY_INSERT,
  NODE_QUICK_ENTRY_REPLACE,
  NODE_PASTE_NODE_LINK,
  NODE_PASTE_REPLACE,
  NODE_REMOVE,
  NODE_REMOVE_ONLY,
  NODE_DETACH,
  NODE_SWAP_LEFT,
  NODE_SWAP_RIGHT,
  NODE_SWAP_UP,
  NODE_SWAP_DOWN,
  NODE_END,
  CONNECTION_START,
  CONNECTION_SELECT_FROM,
  CONNECTION_SELECT_TO,
  CONNECTION_SELECT_NEXT,
  CONNECTION_SELECT_PREV,
  CONNECTION_REMOVE,
  CONNECTION_END,
  CALLOUT_START,
  CALLOUT_SELECT_NODE,
  CALLOUT_REMOVE,
  CALLOUT_END,
  STICKER_START,
  STICKER_REMOVE,
  STICKER_END,
  GROUP_START,
  GROUP_REMOVE,
  GROUP_END,
  EDIT_START,
  EDIT_ESCAPE,
  EDIT_INSERT_NEWLINE,
  EDIT_INSERT_TAB,
  EDIT_INSERT_EMOJI,
  EDIT_BACKSPACE,
  EDIT_DELETE,
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
  EDIT_OPEN_URL,
  EDIT_ADD_URL,
  EDIT_EDIT_URL,
  EDIT_REMOVE_URL,
  EDIT_COPY,
  EDIT_CUT,
  EDIT_PASTE,
  EDIT_RETURN,
  EDIT_SHIFT_RETURN,
  EDIT_TAB,
  EDIT_SHIFT_TAB,
  EDIT_END,
  NUM;

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
      case REMOVE_STICKER_SELECTED   :  return( "remove-sticker-selected" );
      case ESCAPE                    :  return( "escape" );
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
      case NODE_RANDOMIZE_LINK_COLOR :  return( "node-randomize-link-color" );
      case NODE_REPARENT_LINK_COLOR  :  return( "node-reparent-link-color" );
      case NODE_CHANGE_TASK          :  return( "node-change-task" );
      case NODE_ADD_ROOT             :  return( "node-add-root" );
      case NODE_ADD_SIBLING_AFTER    :  return( "node-return" );
      case NODE_ADD_SIBLING_BEFORE   :  return( "node-shift-return" );
      case NODE_ADD_CHILD            :  return( "node-tab" );
      case NODE_ADD_PARENT           :  return( "node-shift-tab" );
      case NODE_CHANGE_IMAGE         :  return( "node-change-image" );
      case NODE_REMOVE_IMAGE         :  return( "node-remove-image" );
      case NODE_TOGGLE_CALLOUT       :  return( "node-toggle-callout" );
      case NODE_ADD_GROUP            :  return( "node-add-group" );
      case NODE_ADD_CONNECTION       :  return( "node-add-connection" );
      case NODE_TOGGLE_FOLDS_SHALLOW :  return( "node-toggle-folds-shallow" );
      case NODE_TOGGLE_FOLDS_DEEP    :  return( "node-toggle-folds-deep" );
      case NODE_TOGGLE_SEQUENCE      :  return( "node-toggle-sequence" );
      case NODE_TOGGLE_LINKS         :  return( "node-toggle-links" );
      case NODE_CENTER               :  return( "node-center" );
      case NODE_SORT_ALPHABETICALLY  :  return( "node-sort-alphabetically" );
      case NODE_SORT_RANDOMLY        :  return( "node-sort-randomly" );
      case NODE_QUICK_ENTRY_INSERT   :  return( "node-quick-entry-insert" );
      case NODE_QUICK_ENTRY_REPLACE  :  return( "node-quick-entry-replace" );
      case NODE_PASTE_NODE_LINK      :  return( "node-paste-node-link" );
      case NODE_PASTE_REPLACE        :  return( "node-paste-replace" );
      case NODE_REMOVE               :  return( "node-remove" );
      case NODE_REMOVE_ONLY          :  return( "node-remove-only" );
      case NODE_DETACH               :  return( "node-detach" );
      case NODE_SWAP_LEFT            :  return( "node-swap-left" );
      case NODE_SWAP_RIGHT           :  return( "node-swap-right" );
      case NODE_SWAP_UP              :  return( "node-swap-up" );
      case NODE_SWAP_DOWN            :  return( "node-swap-down" );
      case CONNECTION_SELECT_FROM    :  return( "connection-select-from" );
      case CONNECTION_SELECT_TO      :  return( "connection-select-to" );
      case CONNECTION_SELECT_NEXT    :  return( "connection-select-next" );
      case CONNECTION_SELECT_PREV    :  return( "connection-select-prev" );
      case CONNECTION_REMOVE         :  return( "connection-remove" );
      case CALLOUT_SELECT_NODE       :  return( "callout-select-node" );
      case CALLOUT_REMOVE            :  return( "callout-remove" );
      case STICKER_REMOVE            :  return( "sticker-remove" );
      case GROUP_REMOVE              :  return( "group-remove" );
      case EDIT_ESCAPE               :  return( "edit-escape" );
      case EDIT_INSERT_NEWLINE       :  return( "edit-insert-newline" );
      case EDIT_INSERT_TAB           :  return( "edit-insert-tab" );
      case EDIT_INSERT_EMOJI         :  return( "edit-insert-emoji" );
      case EDIT_BACKSPACE            :  return( "edit-backspace" );
      case EDIT_DELETE               :  return( "edit-delete" );
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
      case EDIT_OPEN_URL             :  return( "edit-open-url" );
      case EDIT_ADD_URL              :  return( "edit-add-url" );
      case EDIT_EDIT_URL             :  return( "edit-edit-url" );
      case EDIT_REMOVE_URL           :  return( "edit-remove-url" );
      case EDIT_COPY                 :  return( "edit-copy" );
      case EDIT_CUT                  :  return( "edit-cut" );
      case EDIT_PASTE                :  return( "edit-paste" );
      case EDIT_RETURN               :  return( "edit-return" );
      case EDIT_SHIFT_RETURN         :  return( "edit-shift-return" );
      case EDIT_TAB                  :  return( "edit-tab" );
      case EDIT_SHIFT_TAB            :  return( "edit-shift-tab" );
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
      case "remove-sticker-selected"   :  return( REMOVE_STICKER_SELECTED );
      case "escape"                    :  return( ESCAPE );
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
      case "node-randomize-link-color" :  return( NODE_RANDOMIZE_LINK_COLOR );
      case "node-reparent-link-color"  :  return( NODE_REPARENT_LINK_COLOR );
      case "node-change-task"          :  return( NODE_CHANGE_TASK );
      case "node-add-root"             :  return( NODE_ADD_ROOT );
      case "node-return"               :  return( NODE_ADD_SIBLING_AFTER );
      case "node-shift-return"         :  return( NODE_ADD_SIBLING_BEFORE );
      case "node-tab"                  :  return( NODE_ADD_CHILD );
      case "node-shift-tab"            :  return( NODE_ADD_PARENT );
      case "node-change-image"         :  return( NODE_CHANGE_IMAGE );
      case "node-remove-image"         :  return( NODE_REMOVE_IMAGE );
      case "node-toggle-callout"       :  return( NODE_TOGGLE_CALLOUT );
      case "node-add-group"            :  return( NODE_ADD_GROUP );
      case "node-add-connection"       :  return( NODE_ADD_CONNECTION );
      case "node-toggle-folds-shallow" :  return( NODE_TOGGLE_FOLDS_SHALLOW );
      case "node-toggle-folds-deep"    :  return( NODE_TOGGLE_FOLDS_DEEP );
      case "node-toggle-sequence"      :  return( NODE_TOGGLE_SEQUENCE );
      case "node-toggle-links"         :  return( NODE_TOGGLE_LINKS );
      case "node-center"               :  return( NODE_CENTER );
      case "node-sort-alphabetically"  :  return( NODE_SORT_ALPHABETICALLY );
      case "node-sort-randomly"        :  return( NODE_SORT_RANDOMLY );
      case "node-quick-entry-insert"   :  return( NODE_QUICK_ENTRY_INSERT );
      case "node-quick-entry-replace"  :  return( NODE_QUICK_ENTRY_REPLACE );
      case "node-paste-node-link"      :  return( NODE_PASTE_NODE_LINK );
      case "node-paste-replace"        :  return( NODE_PASTE_REPLACE );
      case "node-remove"               :  return( NODE_REMOVE );
      case "node-remove-only"          :  return( NODE_REMOVE_ONLY );
      case "node-detach"               :  return( NODE_DETACH );
      case "node-swap-left"            :  return( NODE_SWAP_LEFT );
      case "node-swap-right"           :  return( NODE_SWAP_RIGHT );
      case "node-swap-up"              :  return( NODE_SWAP_UP );
      case "node-swap-down"            :  return( NODE_SWAP_DOWN );
      case "connection-select-from"    :  return( CONNECTION_SELECT_FROM );
      case "connection-select-to"      :  return( CONNECTION_SELECT_TO );
      case "connection-select-next"    :  return( CONNECTION_SELECT_NEXT );
      case "connection-select-prev"    :  return( CONNECTION_SELECT_PREV );
      case "connection-remove"         :  return( CONNECTION_REMOVE );
      case "callout-select-node"       :  return( CALLOUT_SELECT_NODE );
      case "callout-remove"            :  return( CALLOUT_REMOVE );
      case "sticker-remove"            :  return( STICKER_REMOVE );
      case "group-remove"              :  return( GROUP_REMOVE );
      case "edit-escape"               :  return( EDIT_ESCAPE );
      case "edit-insert-newline"       :  return( EDIT_INSERT_NEWLINE );
      case "edit-insert-tab"           :  return( EDIT_INSERT_TAB );
      case "edit-insert-emoji"         :  return( EDIT_INSERT_EMOJI );
      case "edit-backspace"            :  return( EDIT_BACKSPACE );
      case "edit-delete"               :  return( EDIT_DELETE );
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
      case "edit-open-url"             :  return( EDIT_OPEN_URL );
      case "edit-add-url"              :  return( EDIT_ADD_URL );
      case "edit-edit-url"             :  return( EDIT_EDIT_URL );
      case "edit-remove-url"           :  return( EDIT_REMOVE_URL );
      case "edit-copy"                 :  return( EDIT_COPY );
      case "edit-cut"                  :  return( EDIT_CUT );
      case "edit-paste"                :  return( EDIT_PASTE );
      case "edit-return"               :  return( EDIT_RETURN );
      case "edit-shift-return"         :  return( EDIT_SHIFT_RETURN );
      case "edit-tab"                  :  return( EDIT_TAB );
      case "edit-shift-tab"            :  return( EDIT_SHIFT_TAB );
      default                          :  return( DO_NOTHING );
    }
  }

  //-------------------------------------------------------------
  // Returns the label to display in the shortcut preferences for
  // this key command.
  public string shortcut_label() {
    switch( this ) {
      case GENERAL_START             :  return( _( "General Commands" ) );
      case SHOW_CONTEXTUAL_MENU      :  return( _( "Show contextual menu" ) );
      case ZOOM_IN                   :  return( _( "Zoom in" ) );
      case ZOOM_OUT                  :  return( _( "Zoom out" ) );
      case UNDO_ACTION               :  return( _( "Undo last action" ) );
      case REDO_ACTION               :  return( _( "Redo last undone action" ) );
      case EDIT_NOTE                 :  return( _( "Edit note of current item" ) );
      case SHOW_CURRENT_SIDEBAR      :  return( _( "Show current tab in sidebar" ) );
      case EDIT_SELECTED             :  return( _( "Edit currently selected item" ) );
      case SHOW_SELECTED             :  return( _( "Show currently selected item" ) );
      case REMOVE_STICKER_SELECTED   :  return( _( "Remove sticker from current node or connection" ) );
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
      case NODE_RANDOMIZE_LINK_COLOR :  return( _( "Randomize the current node link color" ) );
      case NODE_REPARENT_LINK_COLOR  :  return( _( "Set current node link color to match parent node" ) );
      case NODE_CHANGE_TASK          :  return( _( "Change task status of current node" ) );
      case NODE_ADD_ROOT             :  return( _( "Add root node" ) );
      case NODE_ADD_SIBLING_AFTER    :  return( _( "Add sibling node after current node" ) );
      case NODE_ADD_SIBLING_BEFORE   :  return( _( "Add sibling node before current node" ) );
      case NODE_ADD_CHILD            :  return( _( "Add child node to current node" ) );
      case NODE_ADD_PARENT           :  return( _( "Add parent node to current node" ) );
      case NODE_CHANGE_IMAGE         :  return( _( "Add/Edit image of current node" ) );
      case NODE_REMOVE_IMAGE         :  return( _( "Remove image from current node" ) );
      case NODE_TOGGLE_CALLOUT       :  return( _( "Add/Remove callout for current node" ) );
      case NODE_ADD_GROUP            :  return( _( "Add group for current node and its subtree" ) );
      case NODE_ADD_CONNECTION       :  return( _( "Start creation of connection from current node" ) );
      case NODE_TOGGLE_FOLDS_SHALLOW :  return( _( "Toggle folding of current node" ) );
      case NODE_TOGGLE_FOLDS_DEEP    :  return( _( "Toggle folding of current node subtree" ) );
      case NODE_TOGGLE_SEQUENCE      :  return( _( "Toggle sequence state of children of current node" ) );
      case NODE_TOGGLE_LINKS         :  return( _( "Toggle the node link state" ) );
      case NODE_CENTER               :  return( _( "Center current node in map canvas" ) );
      case NODE_SORT_ALPHABETICALLY  :  return( _( "Sort child nodes of current node alphabetically" ) );
      case NODE_SORT_RANDOMLY        :  return( _( "Sort child nodes of current node randomly" ) );
      case NODE_QUICK_ENTRY_INSERT   :  return( _( "Use quick entry to insert nodes" ) );
      case NODE_QUICK_ENTRY_REPLACE  :  return( _( "Use quick entry to replace current node" ) );
      case NODE_PASTE_NODE_LINK      :  return( _( "Paste node link from clipboard into current node" ) );
      case NODE_PASTE_REPLACE        :  return( _( "Replace current node with clipboard content") );
      case NODE_REMOVE_ONLY          :  return( _( "Remove selected node only (leave subtree)" ) );
      case NODE_DETACH               :  return( _( "Detaches current node and its subtree" ) );
      case NODE_SWAP_LEFT            :  return( _( "Swap current node with left node" ) );
      case NODE_SWAP_RIGHT           :  return( _( "Swap current node with right node" ) );
      case NODE_SWAP_UP              :  return( _( "Swap current node with above node" ) );
      case NODE_SWAP_DOWN            :  return( _( "Swap current node with below node" ) );
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
      case EDIT_OPEN_URL             :  return( _( "Open URL link at current cursor position" ) );
      case EDIT_ADD_URL              :  return( _( "Add URL link at current cursor position" ) );
      case EDIT_EDIT_URL             :  return( _( "Change URL link at current cursor position" ) );
      case EDIT_REMOVE_URL           :  return( _( "Remove URL link at current cursor position" ) );
      case EDIT_PASTE                :  return( _( "Paste nodes or text from clipboard" ) );
      default                        :  stdout.printf( "label: %d\n", this );  assert_not_reached();
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
      case REMOVE_STICKER_SELECTED   :  return( remove_sticker_selected );
      case ESCAPE                    :  return( escape );
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
      case NODE_RANDOMIZE_LINK_COLOR :  return( node_randomize_link_color );
      case NODE_REPARENT_LINK_COLOR  :  return( node_reparent_link_color );
      case NODE_CHANGE_TASK          :  return( node_change_task );
      case NODE_ADD_ROOT             :  return( node_add_root );
      case NODE_ADD_SIBLING_AFTER    :  return( node_return );
      case NODE_ADD_SIBLING_BEFORE   :  return( node_shift_return );
      case NODE_ADD_CHILD            :  return( node_tab );
      case NODE_ADD_PARENT           :  return( node_shift_tab );
      case NODE_CHANGE_IMAGE         :  return( node_change_image );
      case NODE_REMOVE_IMAGE         :  return( node_remove_image );
      case NODE_TOGGLE_CALLOUT       :  return( node_toggle_callout );
      case NODE_ADD_GROUP            :  return( node_add_group );
      case NODE_ADD_CONNECTION       :  return( node_add_connection );
      case NODE_TOGGLE_FOLDS_SHALLOW :  return( node_toggle_folds_shallow );
      case NODE_TOGGLE_FOLDS_DEEP    :  return( node_toggle_folds_deep );
      case NODE_TOGGLE_SEQUENCE      :  return( node_toggle_sequence );
      case NODE_TOGGLE_LINKS         :  return( node_toggle_links );
      case NODE_CENTER               :  return( node_center );
      case NODE_SORT_ALPHABETICALLY  :  return( node_sort_alphabetically );
      case NODE_SORT_RANDOMLY        :  return( node_sort_randomly );
      case NODE_QUICK_ENTRY_INSERT   :  return( node_quick_entry_insert );
      case NODE_QUICK_ENTRY_REPLACE  :  return( node_quick_entry_replace );
      case NODE_PASTE_NODE_LINK      :  return( node_paste_node_link );
      case NODE_PASTE_REPLACE        :  return( node_paste_replace );
      case NODE_REMOVE               :  return( node_remove );
      case NODE_REMOVE_ONLY          :  return( node_remove_only_selected );
      case NODE_DETACH               :  return( node_detach );
      case NODE_SWAP_LEFT            :  return( node_swap_left );
      case NODE_SWAP_RIGHT           :  return( node_swap_right );
      case NODE_SWAP_UP              :  return( node_swap_up );
      case NODE_SWAP_DOWN            :  return( node_swap_down );
      case CONNECTION_SELECT_FROM    :  return( connection_select_from_node );
      case CONNECTION_SELECT_TO      :  return( connection_select_to_node );
      case CONNECTION_SELECT_NEXT    :  return( connection_select_next );
      case CONNECTION_SELECT_PREV    :  return( connection_select_previous );
      case CONNECTION_REMOVE         :  return( connection_remove );
      case CALLOUT_SELECT_NODE       :  return( callout_select_node );
      case CALLOUT_REMOVE            :  return( callout_remove );
      case STICKER_REMOVE            :  return( sticker_remove );
      case GROUP_REMOVE              :  return( group_remove );
      case EDIT_ESCAPE               :  return( edit_escape );
      case EDIT_INSERT_NEWLINE       :  return( edit_insert_newline );
      case EDIT_INSERT_TAB           :  return( edit_insert_tab );
      case EDIT_INSERT_EMOJI         :  return( edit_insert_emoji );
      case EDIT_BACKSPACE            :  return( edit_backspace );
      case EDIT_DELETE               :  return( edit_delete );
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
      case EDIT_OPEN_URL             :  return( edit_open_url );
      case EDIT_ADD_URL              :  return( edit_add_url );
      case EDIT_EDIT_URL             :  return( edit_edit_url );
      case EDIT_REMOVE_URL           :  return( edit_remove_url );
      case EDIT_COPY                 :  return( edit_copy );
      case EDIT_CUT                  :  return( edit_cut );
      case EDIT_PASTE                :  return( edit_paste );
      case EDIT_RETURN               :  return( edit_return );
      case EDIT_SHIFT_RETURN         :  return( edit_shift_return );
      case EDIT_TAB                  :  return( edit_tab );
      case EDIT_SHIFT_TAB            :  return( edit_shift_tab );
      default                        :  stdout.printf( "Missed %d\n", this );  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for a node.
  public bool for_node() {
    return(
      ((NODE_START < this) && (this < NODE_END)) ||
      (this == EDIT_NOTE) ||
      (this == SHOW_CURRENT_SIDEBAR) ||
      (this == EDIT_SELECTED) ||
      (this == SHOW_SELECTED) ||
      (this == REMOVE_STICKER_SELECTED) ||
      (this == EDIT_COPY) ||
      (this == EDIT_CUT)  ||
      (this == EDIT_PASTE) ||
      (this == ESCAPE)
    );
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for a connection.
  public bool for_connection() {
    return(
      ((CONNECTION_START < this) && (this < CONNECTION_END)) ||
      (this == EDIT_NOTE) ||
      (this == SHOW_CURRENT_SIDEBAR) ||
      (this == EDIT_SELECTED) ||
      (this == SHOW_SELECTED) ||
      (this == REMOVE_STICKER_SELECTED) ||
      (this == ESCAPE) ||
      (this == NODE_ADD_SIBLING_AFTER) ||
      (this == NODE_ADD_SIBLING_BEFORE)
    );
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for a callout.
  public bool for_callout() {
    return(
      ((CALLOUT_START < this) && (this < CALLOUT_END)) ||
      (this == SHOW_CURRENT_SIDEBAR) ||
      (this == EDIT_SELECTED) ||
      (this == SHOW_SELECTED) ||
      (this == ESCAPE)
    );
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for a selected sticker.
  public bool for_sticker() {
    return( ((STICKER_START < this) && (this < STICKER_END)) );
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid for a selected group.
  public bool for_group() {
    return(
      ((GROUP_START < this) && (this < GROUP_END)) ||
      (this == EDIT_NOTE) ||
      (this == SHOW_CURRENT_SIDEBAR)
    );
  }

  //-------------------------------------------------------------
  // Returns true if this command is valid when nothing is selected
  // in the map.
  public bool for_none() {
    switch( this ) {
      case NODE_QUICK_ENTRY_INSERT :
      case NODE_ADD_SIBLING_AFTER  :
      case NODE_ADD_SIBLING_BEFORE :
      case EDIT_PASTE              :
        return( true );
      default :
        return( false );
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
    return(
      (this != DO_NOTHING) &&
      (this != CONTROL_PRESSED) &&
      (this != ESCAPE) &&
      (this != EDIT_ESCAPE) &&
      (this != EDIT_BACKSPACE) &&
      (this != EDIT_DELETE) &&
      (this != EDIT_COPY) &&
      (this != EDIT_CUT) &&
      (this != EDIT_PASTE) &&
      (this != EDIT_RETURN) &&
      (this != EDIT_SHIFT_RETURN) &&
      (this != EDIT_TAB) &&
      (this != EDIT_SHIFT_TAB) &&
      (this != NODE_REMOVE) &&
      (this != CONNECTION_REMOVE) &&
      (this != CALLOUT_REMOVE) &&
      ((this < STICKER_START) || (STICKER_END < this)) &&
      ((this < GROUP_START) || (GROUP_END < this))
    );
  }

  //-------------------------------------------------------------
  // Returns true if this command can have its shortcut be edited.
  public bool editable() {
    if( viewable() ) {
      switch( this ) {
        case ESCAPE            :
        case NODE_REMOVE       :
        case EDIT_BACKSPACE    :
        case EDIT_DELETE       :
        case EDIT_ESCAPE       :
        case EDIT_RETURN       :
        case EDIT_SHIFT_RETURN :
        case EDIT_TAB          :
        case EDIT_SHIFT_TAB    :
        case NODE_ADD_SIBLING_AFTER  :
        case NODE_ADD_SIBLING_BEFORE :
        case NODE_ADD_CHILD    :
        case NODE_ADD_PARENT   :
          return( false );
        default :
          return( true );
      }
    }
    return( false );
  }

  //-------------------------------------------------------------
  // Returns true if this key command is a start of command block.
  public bool is_start() {
    switch( this ) {
      case GENERAL_START    :
      case NODE_START       :
      case CONNECTION_START :
      case CALLOUT_START    :
      case STICKER_START    :
      case GROUP_START      :
      case EDIT_START       :  return( true );
      default               :  return( false );
    }
  }

  //-------------------------------------------------------------
  // Returns true if this key command is an end of command block.
  public bool is_end() {
    switch( this ) {
      case GENERAL_END    :
      case NODE_END       :
      case CONNECTION_END :
      case CALLOUT_END    :
      case STICKER_END    :
      case GROUP_END      :
      case EDIT_END       :  return( true );
      default             :  return( false );
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

  public static void remove_sticker_selected( MindMap map ) {
    map.model.remove_sticker();
  }

  public static void escape( MindMap map ) {
    if( map.is_connection_connecting() ) {
      var current = map.get_current_connection();
      map.connections.remove_connection( current, true );
      map.selected.remove_connection( current );
      map.model.set_attach_node( null );
      map.selected.set_current_node( map.model.last_node );
      map.canvas.last_connection = null;
      map.queue_draw();
    } else {
      map.canvas.hide_properties();
    }
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

  //-------------------------------------------------------------
  // Returns the node relative to the current node for the given
  // direction.
  private static Node? get_node_by_direction( MindMap map, Node current, string dir ) {
    switch( dir ) {
      case "root"          :  return( current.get_root() );
      case "parent"        :  return( current.parent ?? current );
      case "child"         :  return( current.last_selected_child ?? current.children().index( 0 ) );
      case "sibling-next"  :  return( map.model.sibling_node( current, "next",  true ) );
      case "sibling-prev"  :  return( map.model.sibling_node( current, "prev",  true ) );
      case "sibling-first" :  return( map.model.sibling_node( current, "first", true ) );
      case "sibling-last"  :  return( map.model.sibling_node( current, "last",  true ) );
      case "left"          :  return( map.model.get_node_left( current ) );
      case "right"         :  return( map.model.get_node_right( current ) );
      case "up"            :  return( map.model.get_node_up( current ) );
      case "down"          :  return( map.model.get_node_down( current ) );
      default              :  return( null );
    }
  }

  //-------------------------------------------------------------
  // Changes the selected node based on the given direction.  If we
  // are connecting a connection, move the attach node based on the
  // given direction instead.
  private static void node_select( MindMap map, string dir ) {
    if( map.is_connection_connecting() && (map.model.attach_node != null) ) {
      map.model.update_connection_by_node( get_node_by_direction( map, map.model.attach_node, dir ) );
    } else if( map.is_node_selected() ) {
      if( map.select_node( get_node_by_direction( map, map.get_current_node(), dir ) ) ) {
        map.queue_draw();
      }
    } else {
      map.select_root_node();
    }
  }

  public static void node_select_root( MindMap map ) {
    node_select( map, "root" );
  }

  public static void node_select_parent( MindMap map ) {
    node_select( map, "parent" );
  }

  public static void node_select_children( MindMap map ) {
    map.select_child_nodes();
  }

  public static void node_select_child( MindMap map ) {
    node_select( map, "child" );
  }

  public static void node_select_tree( MindMap map ) {
    map.select_node_tree();
  }

  public static void node_select_sibling_next( MindMap map ) {
    node_select( map, "sibling-next" );
  }

  public static void node_select_sibling_previous( MindMap map ) {
    node_select( map, "sibling-prev" );
  }

  public static void node_select_left( MindMap map ) {
    node_select( map, "left" );
  }

  public static void node_select_right( MindMap map ) {
    node_select( map, "right" );
  }

  public static void node_select_up( MindMap map ) {
    node_select( map, "up" );
  }

  public static void node_select_down( MindMap map ) {
    node_select( map, "down" );
  }

  private static void node_select_first_sibling( MindMap map ) {
    node_select( map, "sibling-first" );
  }

  private static void node_select_last_sibling( MindMap map ) {
    node_select( map, "sibling-last" );
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

  public static void node_randomize_link_color( MindMap map ) {
    map.model.randomize_current_link_color();
  }

  public static void node_reparent_link_color( MindMap map ) {
    map.model.reparent_current_link_color();
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

  public static void node_add_root( MindMap map ) {
    map.model.add_root_node();
  }

  //-------------------------------------------------------------
  // Helper function that handles a press of the return key when
  // a node is selected (or is attached to a connecting connection).
  private static void node_return_helper( MindMap map, bool shift ) {
    if( map.is_connection_connecting() && (map.model.attach_node != null) ) {
      map.model.end_connection( map.model.attach_node );
    } else if( map.is_node_selected() ) {
      if( !map.get_current_node().is_root() ) {
        map.model.add_sibling_node( shift );
      } else if( shift ) {
        map.model.add_connected_node();
      } else {
        map.model.add_root_node();
      }
    } else if( map.selected.num_nodes() == 0 ) {
      map.model.add_root_node();
    }
  }

  public static void node_return( MindMap map ) {
    node_return_helper( map, false );
  }

  public static void node_shift_return( MindMap map ) {
    node_return_helper( map, true );
  }

  private static void node_tab_helper( MindMap map, bool shift ) {
    if( map.is_node_selected() ) {
      if( shift ) {
        map.model.add_parent_node();
      } else {
        map.model.add_child_node();
      }
    } else if( map.selected.num_nodes() > 1 ) {
      // map.model.add_summary_node_from_selected();
    }
  }

  public static void node_tab( MindMap map ) {
    node_tab_helper( map, false );
  }

  public static void node_shift_tab( MindMap map ) {
    node_tab_helper( map, true );
  }

  public static void node_change_image( MindMap map ) {
    var current = map.get_current_node();
    if( (current != null) && (current.image != null) ) {
      map.model.edit_current_image();
    } else {
      map.model.add_current_image();
    }
  }

  public static void node_remove_image( MindMap map ) {
    map.model.delete_current_image();
  }

  public static void node_toggle_callout( MindMap map ) {
    if (map.model.node_has_callout() ) {
      map.model.remove_callout();
    } else {
      map.model.add_callout();
    }
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

  public static void node_sort_randomly( MindMap map ) {
    map.model.sort_randomly();
  }

  public static void node_quick_entry_insert( MindMap map ) {
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

  public static void node_paste_replace( MindMap map ) {
    map.canvas.do_paste( true );
  }

  public static void node_remove( MindMap map ) {
    if( map.selected.num_nodes() > 1 ) {
      map.model.delete_nodes();
    } else {
      Node? next;
      var   current = map.get_current_node();
      if( ((next = map.sibling_node( 1 )) == null) && ((next = map.sibling_node( -1 )) == null) && current.is_root() ) {
        map.model.delete_node();
      } else {
        if( next == null ) {
          next = current.parent;
        }
        map.model.delete_node();
        if( map.select_node( next ) ) {
          map.queue_draw();
        }
      }
    }
  }

  public static void node_remove_only_selected( MindMap map ) {
    map.model.delete_nodes();
  }

  public static void node_detach( MindMap map ) {
    map.model.detach();
  }

  //-------------------------------------------------------------
  // Swaps the current node with the one in the specified direction.
  private static void node_swap( MindMap map, string dir ) {
    var current = map.get_current_node();
    if( current != null ) {
      Node? other = null;
      switch( dir ) {
        case "left"  :  other = map.model.get_node_left( current );   break;
        case "right" :  other = map.model.get_node_right( current );  break;
        case "up"    :  other = map.model.get_node_up( current );     break;
        case "down"  :  other = map.model.get_node_down( current );   break;
        default      :  return;
      }
      if( current.swap_with_sibling( other )   ||
          current.make_parent_sibling( other ) ||
          current.make_children_siblings( other ) ) {
        map.queue_draw();
        map.auto_save();
      }
    }
  }

  public static void node_swap_left( MindMap map ) {
    node_swap( map, "left" );
  }

  public static void node_swap_right( MindMap map ) {
    node_swap( map, "right" );
  }

  public static void node_swap_up( MindMap map ) {
    node_swap( map, "up" );
  }

  public static void node_swap_down( MindMap map ) {
    node_swap( map, "down" );
  }

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

  public static void connection_remove( MindMap map ) {
    if( map.get_current_connection() != null ) {
      map.model.delete_connection();
    } else {
      map.model.delete_connections();
    }
  }

  //-------------------------------------------------------------
  // CALLOUT FUNCTIONS

  public static void callout_select_node( MindMap map ) {
    map.select_callout_node();
  }

  public static void callout_remove( MindMap map ) {
    map.model.remove_callout();
  }

  //-------------------------------------------------------------
  // STICKER FUNCTIONS

  public static void sticker_remove( MindMap map ) {
    map.model.remove_sticker();
  }

  //-------------------------------------------------------------
  // GROUP FUNCTIONS

  public static void group_remove( MindMap map ) {
    map.model.remove_groups();
  }

  //-------------------------------------------------------------
  // EDITING FUNCTIONS

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
    var text = map.get_current_text();
    if( text != null ) {
      text.insert( str, map.undo_text );
      text_changed( map );
    }
  }

  //-------------------------------------------------------------
  // Helper function that moves the cursor in a given direction.
  private static void edit_cursor( MindMap map, string dir ) {
    var text = map.get_current_text();
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
    var text = map.get_current_text();
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

  public static void edit_escape( MindMap map ) {
    var text = map.get_current_text();
    if( text != null ) {
      if( map.canvas.completion.shown ) {
        map.canvas.completion.hide();
      } else {
        var current_node = map.get_current_node();
        var current_conn = map.get_current_connection();
        var current_call = map.get_current_callout();
        map.canvas.im_context.reset();
        if( current_node != null ) {
          map.model.set_node_mode( current_node, NodeMode.CURRENT );
          text_changed( map );
          map.auto_save();
        } else if( current_conn != null ) {
          current_conn.edit_title_end();
          map.model.set_connection_mode( current_conn, ConnMode.SELECTED );
          text_changed( map );
          map.auto_save();
        } else if( current_conn != null ) {
          map.model.set_callout_mode( current_call, CalloutMode.SELECTED );
          text_changed( map );
          map.auto_save();
        } else {
          map.canvas.hide_properties();
        }
      }
    }
  }

  public static void edit_insert_newline( MindMap map ) {
    insert_text( map, "\n" );
  }

  public static void edit_insert_tab( MindMap map ) {
    insert_text( map, "\t" );
  }

  public static void edit_insert_emoji( MindMap map ) {
    var text = map.get_current_text();
    if( text != null ) {
      map.canvas.insert_emoji( text );
    }
  }

  public static void edit_backspace( MindMap map ) {
    var text = map.get_current_text();
    if( text != null ) {
      text.backspace( map.undo_text );
      text_changed( map );
    }
  }

  public static void edit_delete( MindMap map ) {
    var text = map.get_current_text();
    if( text != null ) {
      text.delete( map.undo_text );
      text_changed( map );
    }
  }

  public static void edit_remove_word_previous( MindMap map ) {
    var text = map.get_current_text();
    if( text != null ) {
      text.backspace_word( map.undo_text );
      text_changed( map );
    }
  }

  public static void edit_remove_word_next( MindMap map ) {
    var text = map.get_current_text();
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

  public static void edit_open_url( MindMap map ) {
    var text = map.get_current_text();
    if( text != null ) {
      int cursor, selstart, selend;
      text.get_cursor_info( out cursor, out selstart, out selend );
      var links = text.text.get_full_tags_in_range( FormatTag.URL, cursor, cursor );
      Utils.open_url( links.index( 0 ).extra );
    }
  }

  public static void edit_add_url( MindMap map ) {
    map.canvas.url_editor.add_url();
  }

  public static void edit_edit_url( MindMap map ) {
    map.canvas.url_editor.edit_url();
  }

  public static void edit_remove_url( MindMap map ) {
    map.canvas.url_editor.remove_url();
  }

  public static void edit_copy( MindMap map ) {
    map.model.do_copy();
  }

  public static void edit_cut( MindMap map ) {
    map.model.do_cut();
  }

  public static void edit_paste( MindMap map ) {
    map.canvas.do_paste( false );
  }

  private static void edit_return_helper( MindMap map, bool shift ) {
    if( map.canvas.completion.shown ) {
      map.canvas.completion.select();
      map.queue_draw();
    }
    var current_node = map.get_current_node();
    if( current_node != null ) {
      map.model.set_node_mode( current_node, NodeMode.CURRENT );
      if( map.settings.get_boolean( "new-node-from-edit" ) ) {
        if( !current_node.is_root() ) {
          map.model.add_sibling_node( shift );
        } else {
          map.model.add_root_node();
        }
      } else {
        text_changed( map );
        map.auto_save();
      }
      return;
    }
    var current_conn = map.get_current_connection();
    if( current_conn != null ) {
      current_conn.edit_title_end();
      map.model.set_connection_mode( current_conn, ConnMode.SELECTED );
      text_changed( map );
      map.auto_save();
      return;
    }
    var current_call = map.get_current_callout();
    if( current_call != null ) {
      map.model.set_callout_mode( current_call, CalloutMode.SELECTED );
      text_changed( map );
      return;
    }
  }

  public static void edit_return( MindMap map ) {
    edit_return_helper( map, false );
  }

  public static void edit_shift_return( MindMap map ) {
    edit_return_helper( map, true );
  }

  private static void edit_tab_helper( MindMap map, bool shift ) {
    if( map.is_node_editable() ) {
      var current = map.get_current_node();
      map.model.set_node_mode( current, NodeMode.CURRENT );
      if( map.settings.get_boolean( "new-node-from-edit" ) ) {
        if( shift ) {
          map.model.add_parent_node();
        } else {
          map.model.add_child_node();
        }
      } else {
        text_changed( map );
      }
    }
  }

  public static void edit_tab( MindMap map ) {
    edit_tab_helper( map, false );
  }

  public static void edit_shift_tab( MindMap map ) {
    edit_tab_helper( map, true );
  }

}
