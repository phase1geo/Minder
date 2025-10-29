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
    FILE_START,
      FILE_NEW,
      FILE_OPEN,
      FILE_OPEN_DIR,
      FILE_SAVE,
      FILE_SAVE_AS,
      FILE_PRINT,
    FILE_END,
    TAB_START,  // 10
      TAB_GOTO_NEXT,
      TAB_GOTO_PREV,
      TAB_CLOSE_CURRENT,
    TAB_END,
    UNDO_START,
      UNDO_ACTION,
      REDO_ACTION,
    UNDO_END,
    ZOOM_START,
      ZOOM_IN,  // 20
      ZOOM_OUT,
      ZOOM_FIT,
      ZOOM_SELECTED,
      ZOOM_ACTUAL,
    ZOOM_END,
    SIDEBAR_START,
      SHOW_CURRENT_SIDEBAR,
      SHOW_STYLE_SIDEBAR,
      SHOW_TAG_SIDEBAR,
      SHOW_STICKER_SIDEBAR,
      SHOW_MAP_SIDEBAR,  // 30
      SHOW_CURRENT_INFO,
    SIDEBAR_END,
    MAP_START,
      TOGGLE_CONNECTIONS,
      TOGGLE_CALLOUTS,
      BALANCE_NODES,
      FOLD_COMPLETED_TASKS,
      UNFOLD_ALL_NODES,
    MAP_END,
    MISCELLANEOUS_START,
      SHOW_PREFERENCES,  // 40
      SHOW_SHORTCUTS,
      SHOW_CONTEXTUAL_MENU,
      SHOW_FIND,
      SHOW_ABOUT,
      TOGGLE_BRAINDUMP,
      TOGGLE_FOCUS_MODE,
      EDIT_NOTE,
      EDIT_SELECTED,
      SHOW_SELECTED,
      REMOVE_STICKER_SELECTED,  // 50
      QUIT,
    MISCELLANEOUS_END,
    CONTROL_PRESSED,
    ESCAPE,
  GENERAL_END,
  NODE_START,
    NODE_EXIST_START,
      NODE_ADD_ROOT,
      NODE_ADD_SIBLING_AFTER,
      NODE_ADD_SIBLING_BEFORE,  // 60
      NODE_ADD_CHILD,
      NODE_ADD_PARENT,
      NODE_QUICK_ENTRY_INSERT,
      NODE_QUICK_ENTRY_REPLACE,
      NODE_REMOVE,
      NODE_REMOVE_ONLY,
    NODE_EXIST_END,
    NODE_CLIPBOARD_START,
      NODE_PASTE_NODE_LINK,
      NODE_PASTE_REPLACE,  // 70
    NODE_CLIPBOARD_END,
    NODE_VIEW_START,
      NODE_CENTER,
    NODE_VIEW_END,
    NODE_CHANGE_START,
      NODE_CHANGE_TASK,
      NODE_CHANGE_IMAGE,
      NODE_REMOVE_IMAGE,
      NODE_CHANGE_LINK_COLOR,
      NODE_RANDOMIZE_LINK_COLOR,  // 80
      NODE_REPARENT_LINK_COLOR,
      NODE_TOGGLE_FOLDS_SHALLOW,
      NODE_TOGGLE_FOLDS_DEEP,
      NODE_TOGGLE_LINKS,
      NODE_ADD_GROUP,
      NODE_ADD_CONNECTION,
      NODE_TOGGLE_CALLOUT,
      NODE_TOGGLE_SEQUENCE,
    NODE_CHANGE_END,
    NODE_SELECT_START,  // 90
      NODE_SELECT_ROOT,
      NODE_SELECT_PARENT,
      NODE_SELECT_SIBLING_NEXT,
      NODE_SELECT_SIBLING_PREV,
      NODE_SELECT_CHILD,
      NODE_SELECT_CHILDREN,
      NODE_SELECT_TREE,
      NODE_SELECT_DOWN,
      NODE_SELECT_UP,
      NODE_SELECT_RIGHT,  // 100
      NODE_SELECT_LEFT,
      NODE_SELECT_LINKED,
      NODE_SELECT_CALLOUT,
      NODE_SELECT_CONNECTION,
    NODE_SELECT_END,
    NODE_MOVE_START,
      NODE_SWAP_RIGHT,
      NODE_SWAP_LEFT,
      NODE_SWAP_UP,
      NODE_SWAP_DOWN,  // 110
      NODE_SORT_ALPHABETICALLY,
      NODE_SORT_RANDOMLY,
      NODE_DETACH,
    NODE_MOVE_END,
    NODE_ALIGN_START,
      NODE_ALIGN_TOP,
      NODE_ALIGN_VCENTER,
      NODE_ALIGN_BOTTOM,
      NODE_ALIGN_LEFT,
      NODE_ALIGN_HCENTER,  // 120
      NODE_ALIGN_RIGHT,
    NODE_ALIGN_END,
  NODE_END,
  CALLOUT_START,
    CALLOUT_SELECT_NODE,
    CALLOUT_REMOVE,
  CALLOUT_END,
  CONNECTION_START,
    CONNECTION_EXIST_START,
      CONNECTION_REMOVE,  // 130
    CONNECTION_EXIST_END,
    CONNECTION_SELECT_START,
      CONNECTION_SELECT_FROM,
      CONNECTION_SELECT_TO,
      CONNECTION_SELECT_NEXT,
      CONNECTION_SELECT_PREV,
    CONNECTION_SELECT_END,
  CONNECTION_END,
  STICKER_START,
    STICKER_REMOVE,  // 140
  STICKER_END,
  GROUP_START,
    GROUP_CHANGE_START,
      GROUP_CHANGE_COLOR,
      GROUP_MERGE,
      GROUP_REMOVE,
    GROUP_CHANGE_END,
    GROUP_SELECT_START,
      GROUP_SELECT_MAIN,
      GROUP_SELECT_ALL,  // 150
    GROUP_SELECT_END,
  GROUP_END,
  EDIT_START,
    EDIT_TEXT_START,
      EDIT_INSERT_NEWLINE,
      EDIT_INSERT_TAB,
      EDIT_INSERT_EMOJI,
      EDIT_ESCAPE,
      EDIT_BACKSPACE,
      EDIT_DELETE,  // 160
      EDIT_REMOVE_WORD_NEXT,
      EDIT_REMOVE_WORD_PREV,
    EDIT_TEXT_END,
    EDIT_CLIPBOARD_START,
      EDIT_COPY,
      EDIT_CUT,
      EDIT_PASTE,
    EDIT_CLIPBOARD_END,
    EDIT_URL_START,
      EDIT_OPEN_URL,  // 170
      EDIT_ADD_URL,
      EDIT_EDIT_URL,
      EDIT_REMOVE_URL,
    EDIT_URL_END,
    EDIT_CURSOR_START,
      EDIT_CURSOR_CHAR_NEXT,
      EDIT_CURSOR_CHAR_PREV,
      EDIT_CURSOR_UP,
      EDIT_CURSOR_DOWN,  // 150
      EDIT_CURSOR_WORD_NEXT,
      EDIT_CURSOR_WORD_PREV,
      EDIT_CURSOR_FIRST,
      EDIT_CURSOR_LAST,
      EDIT_CURSOR_LINESTART,
      EDIT_CURSOR_LINEEND,
    EDIT_CURSOR_END,
    EDIT_SELECT_START,
      EDIT_SELECT_CHAR_NEXT,
      EDIT_SELECT_CHAR_PREV,  // 160
      EDIT_SELECT_UP,
      EDIT_SELECT_DOWN,
      EDIT_SELECT_WORD_NEXT,
      EDIT_SELECT_WORD_PREV,
      EDIT_SELECT_START_UP,
      EDIT_SELECT_START_HOME,
      EDIT_SELECT_END_DOWN,
      EDIT_SELECT_END_END,
      EDIT_SELECT_LINESTART,
      EDIT_SELECT_LINEEND,  // 170
      EDIT_SELECT_ALL,
      EDIT_SELECT_NONE,
    EDIT_SELECT_END,
    EDIT_MISC_START,
      EDIT_RETURN,
      EDIT_SHIFT_RETURN,
      EDIT_TAB,
      EDIT_SHIFT_TAB,
    EDIT_MISC_END,
  EDIT_END,  // 180
  NUM;

  //-------------------------------------------------------------
  // Returns the string version of this key command.
  public string to_string() {
    switch( this ) {
      case DO_NOTHING                :  return( "none" );
      case GENERAL_START             :  return( "general" );
      case FILE_NEW                  :  return( "file-new" );
      case FILE_OPEN                 :  return( "file-open" );
      case FILE_OPEN_DIR             :  return( "file-open-dir" );
      case FILE_SAVE                 :  return( "file-save" );
      case FILE_SAVE_AS              :  return( "file-save-as" );
      case FILE_PRINT                :  return( "file-print" );
      case TAB_GOTO_NEXT             :  return( "tab-goto-next" );
      case TAB_GOTO_PREV             :  return( "tab-goto-prev" );
      case TAB_CLOSE_CURRENT         :  return( "tab-close-current" );
      case UNDO_ACTION               :  return( "undo-action" );
      case REDO_ACTION               :  return( "redo-action" );
      case ZOOM_IN                   :  return( "zoom-in" );
      case ZOOM_OUT                  :  return( "zoom-out" );
      case ZOOM_FIT                  :  return( "zoom-fit" );
      case ZOOM_SELECTED             :  return( "zoom-selected" );
      case ZOOM_ACTUAL               :  return( "zoom-actual" );
      case SHOW_CURRENT_SIDEBAR      :  return( "show-current-sidebar" );
      case SHOW_STYLE_SIDEBAR        :  return( "show-style-sidebar" );
      case SHOW_TAG_SIDEBAR          :  return( "show-tag-sidebar" );
      case SHOW_STICKER_SIDEBAR      :  return( "show-sticker-sidebar" );
      case SHOW_MAP_SIDEBAR          :  return( "show-map-sidebar" );
      case SHOW_CURRENT_INFO         :  return( "show-current-info" );
      case TOGGLE_CONNECTIONS        :  return( "toggle-connections" );
      case TOGGLE_CALLOUTS           :  return( "toggle-callouts" );
      case BALANCE_NODES             :  return( "balance-nodes" );
      case FOLD_COMPLETED_TASKS      :  return( "fold-completed-tasks" );
      case UNFOLD_ALL_NODES          :  return( "unfold-all-nodes" );
      case SHOW_PREFERENCES          :  return( "show-preferences" );
      case SHOW_SHORTCUTS            :  return( "show-shortcuts" );
      case SHOW_CONTEXTUAL_MENU      :  return( "show-contextual_menu" );
      case SHOW_FIND                 :  return( "show-find" );
      case SHOW_ABOUT                :  return( "show-about" );
      case TOGGLE_BRAINDUMP          :  return( "toggle-braindump" );
      case TOGGLE_FOCUS_MODE         :  return( "toggle-focus-mode" );
      case EDIT_NOTE                 :  return( "edit-note" );
      case EDIT_SELECTED             :  return( "edit-selected" );
      case SHOW_SELECTED             :  return( "show-selected" );
      case REMOVE_STICKER_SELECTED   :  return( "remove-sticker-selected" );
      case QUIT                      :  return( "quit" );
      case CONTROL_PRESSED           :  return( "control" );
      case ESCAPE                    :  return( "escape" );
      case NODE_START                :  return( "node" );
      case NODE_ADD_ROOT             :  return( "node-add-root" );
      case NODE_ADD_SIBLING_AFTER    :  return( "node-return" );
      case NODE_ADD_SIBLING_BEFORE   :  return( "node-shift-return" );
      case NODE_ADD_CHILD            :  return( "node-tab" );
      case NODE_ADD_PARENT           :  return( "node-shift-tab" );
      case NODE_QUICK_ENTRY_INSERT   :  return( "node-quick-entry-insert" );
      case NODE_QUICK_ENTRY_REPLACE  :  return( "node-quick-entry-replace" );
      case NODE_REMOVE               :  return( "node-remove" );
      case NODE_REMOVE_ONLY          :  return( "node-remove-only" );
      case NODE_PASTE_NODE_LINK      :  return( "node-paste-node-link" );
      case NODE_PASTE_REPLACE        :  return( "node-paste-replace" );
      case NODE_CENTER               :  return( "node-center" );
      case NODE_CHANGE_TASK          :  return( "node-change-task" );
      case NODE_CHANGE_IMAGE         :  return( "node-change-image" );
      case NODE_REMOVE_IMAGE         :  return( "node-remove-image" );
      case NODE_CHANGE_LINK_COLOR    :  return( "node-change-link-color" );
      case NODE_RANDOMIZE_LINK_COLOR :  return( "node-randomize-link-color" );
      case NODE_REPARENT_LINK_COLOR  :  return( "node-reparent-link-color" );
      case NODE_TOGGLE_FOLDS_SHALLOW :  return( "node-toggle-folds-shallow" );
      case NODE_TOGGLE_FOLDS_DEEP    :  return( "node-toggle-folds-deep" );
      case NODE_TOGGLE_LINKS         :  return( "node-toggle-links" );
      case NODE_ADD_GROUP            :  return( "node-add-group" );
      case NODE_ADD_CONNECTION       :  return( "node-add-connection" );
      case NODE_TOGGLE_CALLOUT       :  return( "node-toggle-callout" );
      case NODE_TOGGLE_SEQUENCE      :  return( "node-toggle-sequence" );
      case NODE_SELECT_ROOT          :  return( "node-select-root" );
      case NODE_SELECT_PARENT        :  return( "node-select-parent" );
      case NODE_SELECT_SIBLING_NEXT  :  return( "node-select-sibling-next" );
      case NODE_SELECT_SIBLING_PREV  :  return( "node-select-sibling-prev" );
      case NODE_SELECT_CHILD         :  return( "node-select-child" );
      case NODE_SELECT_CHILDREN      :  return( "node-select-children" );
      case NODE_SELECT_TREE          :  return( "node-select-tree" );
      case NODE_SELECT_DOWN          :  return( "node-select-down" );
      case NODE_SELECT_UP            :  return( "node-select-up" );
      case NODE_SELECT_RIGHT         :  return( "node-select-right" );
      case NODE_SELECT_LEFT          :  return( "node-select-left" );
      case NODE_SELECT_LINKED        :  return( "node-select-linked" );
      case NODE_SELECT_CALLOUT       :  return( "node-select-callout" );
      case NODE_SELECT_CONNECTION    :  return( "node-select-connection" );
      case NODE_SWAP_RIGHT           :  return( "node-swap-right" );
      case NODE_SWAP_LEFT            :  return( "node-swap-left" );
      case NODE_SWAP_UP              :  return( "node-swap-up" );
      case NODE_SWAP_DOWN            :  return( "node-swap-down" );
      case NODE_SORT_ALPHABETICALLY  :  return( "node-sort-alphabetically" );
      case NODE_SORT_RANDOMLY        :  return( "node-sort-randomly" );
      case NODE_DETACH               :  return( "node-detach" );
      case NODE_ALIGN_TOP            :  return( "node-align-top" );
      case NODE_ALIGN_VCENTER        :  return( "node-align-vcenter" );
      case NODE_ALIGN_BOTTOM         :  return( "node-align-bottom" );
      case NODE_ALIGN_LEFT           :  return( "node-align-left" );
      case NODE_ALIGN_HCENTER        :  return( "node-align-hcenter" );
      case NODE_ALIGN_RIGHT          :  return( "node-align-right" );
      case CALLOUT_START             :  return( "callout" );
      case CALLOUT_SELECT_NODE       :  return( "callout-select-node" );
      case CALLOUT_REMOVE            :  return( "callout-remove" );
      case CONNECTION_START          :  return( "connection" );
      case CONNECTION_REMOVE         :  return( "connection-remove" );
      case CONNECTION_SELECT_FROM    :  return( "connection-select-from" );
      case CONNECTION_SELECT_TO      :  return( "connection-select-to" );
      case CONNECTION_SELECT_NEXT    :  return( "connection-select-next" );
      case CONNECTION_SELECT_PREV    :  return( "connection-select-prev" );
      case STICKER_START             :  return( "sticker" );
      case STICKER_REMOVE            :  return( "sticker-remove" );
      case GROUP_START               :  return( "group" );
      case GROUP_CHANGE_COLOR        :  return( "group-change-color" );
      case GROUP_MERGE               :  return( "group-merge" );
      case GROUP_REMOVE              :  return( "group-remove" );
      case GROUP_SELECT_MAIN         :  return( "group-select-main" );
      case GROUP_SELECT_ALL          :  return( "group-select-all" );
      case EDIT_START                :  return( "editing" );
      case EDIT_INSERT_NEWLINE       :  return( "edit-insert-newline" );
      case EDIT_INSERT_TAB           :  return( "edit-insert-tab" );
      case EDIT_INSERT_EMOJI         :  return( "edit-insert-emoji" );
      case EDIT_ESCAPE               :  return( "edit-escape" );
      case EDIT_BACKSPACE            :  return( "edit-backspace" );
      case EDIT_DELETE               :  return( "edit-delete" );
      case EDIT_REMOVE_WORD_NEXT     :  return( "edit-remove-word-next" );
      case EDIT_REMOVE_WORD_PREV     :  return( "edit-remove-word-prev" );
      case EDIT_COPY                 :  return( "edit-copy" );
      case EDIT_CUT                  :  return( "edit-cut" );
      case EDIT_PASTE                :  return( "edit-paste" );
      case EDIT_OPEN_URL             :  return( "edit-open-url" );
      case EDIT_ADD_URL              :  return( "edit-add-url" );
      case EDIT_EDIT_URL             :  return( "edit-edit-url" );
      case EDIT_REMOVE_URL           :  return( "edit-remove-url" );
      case EDIT_CURSOR_CHAR_NEXT     :  return( "edit-cursor-char-next" );
      case EDIT_CURSOR_CHAR_PREV     :  return( "edit-cursor-char-prev" );
      case EDIT_CURSOR_UP            :  return( "edit-cursor-up" );
      case EDIT_CURSOR_DOWN          :  return( "edit-cursor-down" );
      case EDIT_CURSOR_WORD_NEXT     :  return( "edit-cursor-word-next" );
      case EDIT_CURSOR_WORD_PREV     :  return( "edit-cursor-word-prev" );
      case EDIT_CURSOR_FIRST         :  return( "edit-cursor-first" );
      case EDIT_CURSOR_LAST          :  return( "edit-cursor-last" );
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
      case "file-new"                  :  return( FILE_NEW );
      case "file-open"                 :  return( FILE_OPEN );
      case "file-open-dir"             :  return( FILE_OPEN_DIR );
      case "file-save"                 :  return( FILE_SAVE );
      case "file-save-as"              :  return( FILE_SAVE_AS );
      case "file-print"                :  return( FILE_PRINT );
      case "tab-goto-next"             :  return( TAB_GOTO_NEXT );
      case "tab-goto-prev"             :  return( TAB_GOTO_PREV );
      case "tab-close-current"         :  return( TAB_CLOSE_CURRENT );
      case "undo-action"               :  return( UNDO_ACTION );
      case "redo-action"               :  return( REDO_ACTION );
      case "zoom-in"                   :  return( ZOOM_IN );
      case "zoom-out"                  :  return( ZOOM_OUT );
      case "zoom-fit"                  :  return( ZOOM_FIT );
      case "zoom-selected"             :  return( ZOOM_SELECTED );
      case "zoom-actual"               :  return( ZOOM_ACTUAL );
      case "show-current-sidebar"      :  return( SHOW_CURRENT_SIDEBAR );
      case "show-style-sidebar"        :  return( SHOW_STYLE_SIDEBAR );
      case "show-tag-sidebar"          :  return( SHOW_TAG_SIDEBAR );
      case "show-sticker-sidebar"      :  return( SHOW_STICKER_SIDEBAR );
      case "show-map-sidebar"          :  return( SHOW_MAP_SIDEBAR );
      case "show-current-info"         :  return( SHOW_CURRENT_INFO );
      case "toggle-connections"        :  return( TOGGLE_CONNECTIONS );
      case "toggle-callouts"           :  return( TOGGLE_CALLOUTS );
      case "balance-nodes"             :  return( BALANCE_NODES );
      case "fold-completed-tasks"      :  return( FOLD_COMPLETED_TASKS );
      case "unfold-all-nodes"          :  return( UNFOLD_ALL_NODES );
      case "show-preferences"          :  return( SHOW_PREFERENCES );
      case "show-shortcuts"            :  return( SHOW_SHORTCUTS );
      case "show-contextual-menu"      :  return( SHOW_CONTEXTUAL_MENU );
      case "show-find"                 :  return( SHOW_FIND );
      case "show-about"                :  return( SHOW_ABOUT );
      case "toggle-braindump"          :  return( TOGGLE_BRAINDUMP );
      case "toggle-focus-mode"         :  return( TOGGLE_FOCUS_MODE );
      case "edit-note"                 :  return( EDIT_NOTE );
      case "edit-selected"             :  return( EDIT_SELECTED );
      case "show-selected"             :  return( SHOW_SELECTED );
      case "remove-sticker-selected"   :  return( REMOVE_STICKER_SELECTED );
      case "quit"                      :  return( QUIT );
      case "control"                   :  return( CONTROL_PRESSED );
      case "escape"                    :  return( ESCAPE );
      case "node-add-root"             :  return( NODE_ADD_ROOT );
      case "node-return"               :  return( NODE_ADD_SIBLING_AFTER );
      case "node-shift-return"         :  return( NODE_ADD_SIBLING_BEFORE );
      case "node-tab"                  :  return( NODE_ADD_CHILD );
      case "node-shift-tab"            :  return( NODE_ADD_PARENT );
      case "node-quick-entry-insert"   :  return( NODE_QUICK_ENTRY_INSERT );
      case "node-quick-entry-replace"  :  return( NODE_QUICK_ENTRY_REPLACE );
      case "node-remove"               :  return( NODE_REMOVE );
      case "node-remove-only"          :  return( NODE_REMOVE_ONLY );
      case "node-paste-node-link"      :  return( NODE_PASTE_NODE_LINK );
      case "node-paste-replace"        :  return( NODE_PASTE_REPLACE );
      case "node-center"               :  return( NODE_CENTER );
      case "node-change-task"          :  return( NODE_CHANGE_TASK );
      case "node-change-image"         :  return( NODE_CHANGE_IMAGE );
      case "node-remove-image"         :  return( NODE_REMOVE_IMAGE );
      case "node-change-link-color"    :  return( NODE_CHANGE_LINK_COLOR );
      case "node-randomize-link-color" :  return( NODE_RANDOMIZE_LINK_COLOR );
      case "node-reparent-link-color"  :  return( NODE_REPARENT_LINK_COLOR );
      case "node-toggle-folds-shallow" :  return( NODE_TOGGLE_FOLDS_SHALLOW );
      case "node-toggle-folds-deep"    :  return( NODE_TOGGLE_FOLDS_DEEP );
      case "node-toggle-links"         :  return( NODE_TOGGLE_LINKS );
      case "node-add-group"            :  return( NODE_ADD_GROUP );
      case "node-add-connection"       :  return( NODE_ADD_CONNECTION );
      case "node-toggle-callout"       :  return( NODE_TOGGLE_CALLOUT );
      case "node-toggle-sequence"      :  return( NODE_TOGGLE_SEQUENCE );
      case "node-select-root"          :  return( NODE_SELECT_ROOT );
      case "node-select-parent"        :  return( NODE_SELECT_PARENT );
      case "node-select-sibling-next"  :  return( NODE_SELECT_SIBLING_NEXT );
      case "node-select-sibling-prev"  :  return( NODE_SELECT_SIBLING_PREV );
      case "node-select-child"         :  return( NODE_SELECT_CHILD );
      case "node-select-children"      :  return( NODE_SELECT_CHILDREN );
      case "node-select-tree"          :  return( NODE_SELECT_TREE );
      case "node-select-down"          :  return( NODE_SELECT_DOWN );
      case "node-select-up"            :  return( NODE_SELECT_UP );
      case "node-select-right"         :  return( NODE_SELECT_RIGHT );
      case "node-select-left"          :  return( NODE_SELECT_LEFT );
      case "node-select-linked"        :  return( NODE_SELECT_LINKED );
      case "node-select-callout"       :  return( NODE_SELECT_CALLOUT );
      case "node-select-connection"    :  return( NODE_SELECT_CONNECTION );
      case "node-swap-right"           :  return( NODE_SWAP_RIGHT );
      case "node-swap-left"            :  return( NODE_SWAP_LEFT );
      case "node-swap-up"              :  return( NODE_SWAP_UP );
      case "node-swap-down"            :  return( NODE_SWAP_DOWN );
      case "node-sort-alphabetically"  :  return( NODE_SORT_ALPHABETICALLY );
      case "node-sort-randomly"        :  return( NODE_SORT_RANDOMLY );
      case "node-detach"               :  return( NODE_DETACH );
      case "node-align-top"            :  return( NODE_ALIGN_TOP );
      case "node-align-vcenter"        :  return( NODE_ALIGN_VCENTER );
      case "node-align-bottom"         :  return( NODE_ALIGN_BOTTOM );
      case "node-align-left"           :  return( NODE_ALIGN_LEFT );
      case "node-align-hcenter"        :  return( NODE_ALIGN_HCENTER );
      case "node-align-right"          :  return( NODE_ALIGN_RIGHT );
      case "callout-select-node"       :  return( CALLOUT_SELECT_NODE );
      case "callout-remove"            :  return( CALLOUT_REMOVE );
      case "connection-remove"         :  return( CONNECTION_REMOVE );
      case "connection-select-from"    :  return( CONNECTION_SELECT_FROM );
      case "connection-select-to"      :  return( CONNECTION_SELECT_TO );
      case "connection-select-next"    :  return( CONNECTION_SELECT_NEXT );
      case "connection-select-prev"    :  return( CONNECTION_SELECT_PREV );
      case "sticker-remove"            :  return( STICKER_REMOVE );
      case "group-change-color"        :  return( GROUP_CHANGE_COLOR );
      case "group-merge"               :  return( GROUP_MERGE );
      case "group-remove"              :  return( GROUP_REMOVE );
      case "group-select-main"         :  return( GROUP_SELECT_MAIN );
      case "group-select-all"          :  return( GROUP_SELECT_ALL );
      case "edit-insert-newline"       :  return( EDIT_INSERT_NEWLINE );
      case "edit-insert-tab"           :  return( EDIT_INSERT_TAB );
      case "edit-insert-emoji"         :  return( EDIT_INSERT_EMOJI );
      case "edit-escape"               :  return( EDIT_ESCAPE );
      case "edit-backspace"            :  return( EDIT_BACKSPACE );
      case "edit-delete"               :  return( EDIT_DELETE );
      case "edit-remove-word-next"     :  return( EDIT_REMOVE_WORD_NEXT );
      case "edit-remove-word-prev"     :  return( EDIT_REMOVE_WORD_PREV );
      case "edit-copy"                 :  return( EDIT_COPY );
      case "edit-cut"                  :  return( EDIT_CUT );
      case "edit-paste"                :  return( EDIT_PASTE );
      case "edit-open-url"             :  return( EDIT_OPEN_URL );
      case "edit-add-url"              :  return( EDIT_ADD_URL );
      case "edit-edit-url"             :  return( EDIT_EDIT_URL );
      case "edit-remove-url"           :  return( EDIT_REMOVE_URL );
      case "edit-cursor-char-next"     :  return( EDIT_CURSOR_CHAR_NEXT );
      case "edit-cursor-char-prev"     :  return( EDIT_CURSOR_CHAR_PREV );
      case "edit-cursor-up"            :  return( EDIT_CURSOR_UP );
      case "edit-cursor-down"          :  return( EDIT_CURSOR_DOWN );
      case "edit-cursor-word-next"     :  return( EDIT_CURSOR_WORD_NEXT );
      case "edit-cursor-word-prev"     :  return( EDIT_CURSOR_WORD_PREV );
      case "edit-cursor-first"         :  return( EDIT_CURSOR_FIRST );
      case "edit-cursor-last"          :  return( EDIT_CURSOR_LAST );
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
      case GENERAL_START             :  return( _( "General" ) );
      case FILE_START                :  return( _( "File Commands" ) );
      case FILE_NEW                  :  return( _( "Create new mindmap" ) );
      case FILE_OPEN                 :  return( _( "Open saved mindmap" ) );
      case FILE_OPEN_DIR             :  return( _( "Create mindmap from directory structure" ) );
      case FILE_SAVE                 :  return( _( "Save mindmap to current file" ) );
      case FILE_SAVE_AS              :  return( _( "Save mindmap to new file" ) );
      case FILE_PRINT                :  return( _( "Show print dialog for current mindmap" ) );
      case TAB_START                 :  return( _( "Tab Commands" ) );
      case TAB_GOTO_NEXT             :  return( _( "Select next tab" ) );
      case TAB_GOTO_PREV             :  return( _( "Select previous tab" ) );
      case TAB_CLOSE_CURRENT         :  return( _( "Close the current mindmap" ) );
      case UNDO_START                :  return( _( "Undo/Redo Commands" ) );
      case UNDO_ACTION               :  return( _( "Undo last action" ) );
      case REDO_ACTION               :  return( _( "Redo last undone action" ) );
      case ZOOM_START                :  return( _( "Zoom Commands" ) );
      case ZOOM_IN                   :  return( _( "Zoom in" ) );
      case ZOOM_OUT                  :  return( _( "Zoom out" ) );
      case ZOOM_FIT                  :  return( _( "Zoom to fit entire mindmap in viewer" ) );
      case ZOOM_SELECTED             :  return( _( "Zoom selected node subtree in viewer" ) );
      case ZOOM_ACTUAL               :  return( _( "Zoom to 100%" ) );
      case SIDEBAR_START             :  return( _( "Sidebar Commands" ) );
      case SHOW_CURRENT_SIDEBAR      :  return( _( "Show current tab in sidebar" ) );
      case SHOW_STYLE_SIDEBAR        :  return( _( "Show style tab in sidebar" ) );
      case SHOW_TAG_SIDEBAR          :  return( _( "Show tag tab in sidebar" ) );
      case SHOW_STICKER_SIDEBAR      :  return( _( "Show sticker tab in sidebar" ) );
      case SHOW_MAP_SIDEBAR          :  return( _( "Show map tab in sidebar" ) );
      case SHOW_CURRENT_INFO         :  return( _( "Show currently select node/connection/group information in sidebar" ) );
      case MAP_START                 :  return( _( "Map Commands" ) );
      case TOGGLE_CONNECTIONS        :  return( _( "Show/Hide Connections" ) );
      case TOGGLE_CALLOUTS           :  return( _( "Show/Hide Callouts" ) );
      case BALANCE_NODES             :  return( _( "Balance nodes in vertical/horizontal layouts" ) );
      case FOLD_COMPLETED_TASKS      :  return( _( "Fold all completed tasks" ) );
      case UNFOLD_ALL_NODES          :  return( _( "Unfold all folded nodes" ) );
      case MISCELLANEOUS_START       :  return( _( "Miscellaneous Commands" ) );
      case SHOW_PREFERENCES          :  return( _( "Show preferences window" ) );
      case SHOW_SHORTCUTS            :  return( _( "Show shortcuts cheatsheet" ) );
      case SHOW_CONTEXTUAL_MENU      :  return( _( "Show contextual menu" ) );
      case SHOW_FIND                 :  return( _( "Show find popup" ) );
      case SHOW_ABOUT                :  return( _( "Show About window" ) );
      case TOGGLE_BRAINDUMP          :  return( _( "Toggle braindump input mode" ) );
      case TOGGLE_FOCUS_MODE         :  return( _( "Toggle focus mode" ) );
      case EDIT_NOTE                 :  return( _( "Edit note of current item" ) );
      case EDIT_SELECTED             :  return( _( "Edit currently selected item" ) );
      case SHOW_SELECTED             :  return( _( "Show currently selected item" ) );
      case REMOVE_STICKER_SELECTED   :  return( _( "Remove sticker from current node or connection" ) );
      case QUIT                      :  return( _( "Quit the application" ) );
      case NODE_START                :  return( _( "Node" ) );
      case NODE_EXIST_START          :  return( _( "Creation/Deletion Commands" ) );
      case NODE_ADD_ROOT             :  return( _( "Add root node" ) );
      case NODE_ADD_SIBLING_AFTER    :  return( _( "Add sibling node after current node" ) );
      case NODE_ADD_SIBLING_BEFORE   :  return( _( "Add sibling node before current node" ) );
      case NODE_ADD_CHILD            :  return( _( "Add child node to current node" ) );
      case NODE_ADD_PARENT           :  return( _( "Add parent node to current node" ) );
      case NODE_QUICK_ENTRY_INSERT   :  return( _( "Use quick entry to insert nodes" ) );
      case NODE_QUICK_ENTRY_REPLACE  :  return( _( "Use quick entry to replace current node" ) );
      case NODE_REMOVE_ONLY          :  return( _( "Remove selected node only (leave subtree)" ) );
      case NODE_CLIPBOARD_START      :  return( _( "Clipboard Commands" ) );
      case NODE_PASTE_NODE_LINK      :  return( _( "Paste node link from clipboard into current node" ) );
      case NODE_PASTE_REPLACE        :  return( _( "Replace current node with clipboard content") );
      case NODE_VIEW_START           :  return( _( "View Commands" ) );
      case NODE_CENTER               :  return( _( "Center current node in map canvas" ) );
      case NODE_CHANGE_START         :  return( _( "Change Commands" ) );
      case NODE_CHANGE_TASK          :  return( _( "Change task status of current node" ) );
      case NODE_CHANGE_IMAGE         :  return( _( "Add/Edit image of current node" ) );
      case NODE_REMOVE_IMAGE         :  return( _( "Remove image from current node" ) );
      case NODE_CHANGE_LINK_COLOR    :  return( _( "Change link color of current node" ) );
      case NODE_RANDOMIZE_LINK_COLOR :  return( _( "Randomize the current node link color" ) );
      case NODE_REPARENT_LINK_COLOR  :  return( _( "Set current node link color to match parent node" ) );
      case NODE_TOGGLE_FOLDS_SHALLOW :  return( _( "Toggle folding of current node" ) );
      case NODE_TOGGLE_FOLDS_DEEP    :  return( _( "Toggle folding of current node subtree" ) );
      case NODE_TOGGLE_LINKS         :  return( _( "Toggle the node link state" ) );
      case NODE_ADD_GROUP            :  return( _( "Add group for current node and its subtree" ) );
      case NODE_ADD_CONNECTION       :  return( _( "Start creation of connection from current node" ) );
      case NODE_TOGGLE_CALLOUT       :  return( _( "Add/Remove callout for current node" ) );
      case NODE_TOGGLE_SEQUENCE      :  return( _( "Toggle sequence state of children of current node" ) );
      case NODE_SELECT_START         :  return( _( "Selection Commands" ) );
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
      case NODE_MOVE_START           :  return( _( "Move Commands" ) );
      case NODE_SWAP_RIGHT           :  return( _( "Swap current node with right node" ) );
      case NODE_SWAP_LEFT            :  return( _( "Swap current node with left node" ) );
      case NODE_SWAP_UP              :  return( _( "Swap current node with above node" ) );
      case NODE_SWAP_DOWN            :  return( _( "Swap current node with below node" ) );
      case NODE_SORT_ALPHABETICALLY  :  return( _( "Sort child nodes of current node alphabetically" ) );
      case NODE_SORT_RANDOMLY        :  return( _( "Sort child nodes of current node randomly" ) );
      case NODE_DETACH               :  return( _( "Detaches current node and its subtree" ) );
      case NODE_ALIGN_START          :  return( _( "Alignment Commands" ) );
      case NODE_ALIGN_TOP            :  return( _( "Align selected node top edges" ) );
      case NODE_ALIGN_VCENTER        :  return( _( "Align selected node vertical centers" ) );
      case NODE_ALIGN_BOTTOM         :  return( _( "Align selected node bottom edges" ) );
      case NODE_ALIGN_LEFT           :  return( _( "Align selected node left edges" ) );
      case NODE_ALIGN_HCENTER        :  return( _( "Align selected node horizontal centers" ) );
      case NODE_ALIGN_RIGHT          :  return( _( "Align selected node right edges" ) );
      case CALLOUT_START             :  return( _( "Callout" ) );
      case CALLOUT_SELECT_NODE       :  return( _( "Select callout node" ) );
      case CONNECTION_START          :  return( _( "Connection" ) );
      case CONNECTION_SELECT_START   :  return( _( "Selection Commands" ) );
      case CONNECTION_SELECT_FROM    :  return( _( "Select connection source node" ) );
      case CONNECTION_SELECT_TO      :  return( _( "Select connection target node" ) );
      case CONNECTION_SELECT_NEXT    :  return( _( "Select next connection in map" ) );
      case CONNECTION_SELECT_PREV    :  return( _( "Select previous connection in map" ) );
      case GROUP_START               :  return( _( "Group" ) );
      case GROUP_CHANGE_START        :  return( _( "Change Commands" ) );
      case GROUP_CHANGE_COLOR        :  return( _( "Change the color of the current group" ) );
      case GROUP_MERGE               :  return( _( "Merge current groups into single group" ) );
      case GROUP_SELECT_START        :  return( _( "Selection Commands" ) );
      case GROUP_SELECT_MAIN         :  return( _( "Select main node(s) of current group(s)" ) );
      case GROUP_SELECT_ALL          :  return( _( "Selects all nodes within current group(s)" ) );
      case EDIT_START                :  return( _( "Text Editing" ) );
      case EDIT_TEXT_START           :  return( _( "Insertion/Deletion Commands" ) );
      case EDIT_INSERT_NEWLINE       :  return( _( "Insert newline character" ) );
      case EDIT_INSERT_TAB           :  return( _( "Insert TAB character" ) );
      case EDIT_INSERT_EMOJI         :  return( _( "Insert emoji" ) );
      case EDIT_REMOVE_WORD_NEXT     :  return( _( "Remove next word" ) );
      case EDIT_REMOVE_WORD_PREV     :  return( _( "Remove previous word" ) );
      case EDIT_CLIPBOARD_START      :  return( _( "Clipboard Commands" ) );
      case EDIT_COPY                 :  return( _( "Copy selected nodes or text" ) );
      case EDIT_CUT                  :  return( _( "Cut selected nodes or text" ) );
      case EDIT_PASTE                :  return( _( "Paste nodes or text from clipboard" ) );
      case EDIT_URL_START            :  return( _( "URL Commands" ) );
      case EDIT_OPEN_URL             :  return( _( "Open URL link at current cursor position" ) );
      case EDIT_ADD_URL              :  return( _( "Add URL link at current cursor position" ) );
      case EDIT_EDIT_URL             :  return( _( "Change URL link at current cursor position" ) );
      case EDIT_REMOVE_URL           :  return( _( "Remove URL link at current cursor position" ) );
      case EDIT_CURSOR_START         :  return( _( "Cursor Commands" ) );
      case EDIT_CURSOR_CHAR_NEXT     :  return( _( "Move cursor to next character" ) );
      case EDIT_CURSOR_CHAR_PREV     :  return( _( "Move cursor to previous character" ) );
      case EDIT_CURSOR_UP            :  return( _( "Move cursor up one line" ) );
      case EDIT_CURSOR_DOWN          :  return( _( "Move cursor down one line" ) );
      case EDIT_CURSOR_WORD_NEXT     :  return( _( "Move cursor to beginning of next word" ) );
      case EDIT_CURSOR_WORD_PREV     :  return( _( "Move cursor to beginning of previous word" ) );
      case EDIT_CURSOR_FIRST         :  return( _( "Move cursor to start of text" ) );
      case EDIT_CURSOR_LAST          :  return( _( "Move cursor to end of text" ) );
      case EDIT_CURSOR_LINESTART     :  return( _( "Move cursor to start of current line" ) );
      case EDIT_CURSOR_LINEEND       :  return( _( "Move cursor to end of current line" ) );
      case EDIT_SELECT_START         :  return( _( "Selection Commands" ) );
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
      default                        :  stdout.printf( "label: %d\n", this );  assert_not_reached();
    }
  }

  //-------------------------------------------------------------
  // Returns function to execute for this key command.
  public KeyCommandFunc get_func() {
    switch( this ) {
      case DO_NOTHING                :  return( do_nothing );
      case FILE_NEW                  :  return( file_new );
      case FILE_OPEN                 :  return( file_open );
      case FILE_OPEN_DIR             :  return( file_open_dir );
      case FILE_SAVE                 :  return( file_save );
      case FILE_SAVE_AS              :  return( file_save_as );
      case FILE_PRINT                :  return( file_print );
      case TAB_GOTO_NEXT             :  return( tab_goto_next );
      case TAB_GOTO_PREV             :  return( tab_goto_prev );
      case TAB_CLOSE_CURRENT         :  return( tab_close_current );
      case UNDO_ACTION               :  return( undo_action );
      case REDO_ACTION               :  return( redo_action );
      case ZOOM_IN                   :  return( zoom_in );
      case ZOOM_OUT                  :  return( zoom_out );
      case ZOOM_FIT                  :  return( zoom_fit );
      case ZOOM_SELECTED             :  return( zoom_selected );
      case ZOOM_ACTUAL               :  return( zoom_actual );
      case SHOW_CURRENT_SIDEBAR      :  return( show_current_sidebar );
      case SHOW_STYLE_SIDEBAR        :  return( show_style_sidebar );
      case SHOW_TAG_SIDEBAR          :  return( show_tag_sidebar );
      case SHOW_STICKER_SIDEBAR      :  return( show_sticker_sidebar );
      case SHOW_MAP_SIDEBAR          :  return( show_map_sidebar );
      case SHOW_CURRENT_INFO         :  return( show_current_sidebar );
      case TOGGLE_CONNECTIONS        :  return( toggle_connections );
      case TOGGLE_CALLOUTS           :  return( toggle_callouts );
      case BALANCE_NODES             :  return( balance_nodes );
      case FOLD_COMPLETED_TASKS      :  return( fold_completed_tasks );
      case UNFOLD_ALL_NODES          :  return( unfold_all_nodes );
      case SHOW_PREFERENCES          :  return( show_preferences );
      case SHOW_SHORTCUTS            :  return( show_shortcuts );
      case SHOW_CONTEXTUAL_MENU      :  return( show_contextual_menu );
      case SHOW_FIND                 :  return( show_find );
      case SHOW_ABOUT                :  return( show_about );
      case TOGGLE_BRAINDUMP          :  return( toggle_braindump );
      case TOGGLE_FOCUS_MODE         :  return( toggle_focus_mode );
      case EDIT_NOTE                 :  return( edit_note );
      case EDIT_SELECTED             :  return( edit_selected );
      case SHOW_SELECTED             :  return( show_selected );
      case REMOVE_STICKER_SELECTED   :  return( remove_sticker_selected );
      case QUIT                      :  return( quit_application );
      case CONTROL_PRESSED           :  return( control_pressed );
      case ESCAPE                    :  return( escape );
      case NODE_ADD_ROOT             :  return( node_add_root );
      case NODE_ADD_SIBLING_AFTER    :  return( node_return );
      case NODE_ADD_SIBLING_BEFORE   :  return( node_shift_return );
      case NODE_ADD_CHILD            :  return( node_tab );
      case NODE_ADD_PARENT           :  return( node_shift_tab );
      case NODE_QUICK_ENTRY_INSERT   :  return( node_quick_entry_insert );
      case NODE_QUICK_ENTRY_REPLACE  :  return( node_quick_entry_replace );
      case NODE_REMOVE               :  return( node_remove );
      case NODE_REMOVE_ONLY          :  return( node_remove_only_selected );
      case NODE_PASTE_NODE_LINK      :  return( node_paste_node_link );
      case NODE_PASTE_REPLACE        :  return( node_paste_replace );
      case NODE_CENTER               :  return( node_center );
      case NODE_CHANGE_TASK          :  return( node_change_task );
      case NODE_CHANGE_IMAGE         :  return( node_change_image );
      case NODE_REMOVE_IMAGE         :  return( node_remove_image );
      case NODE_CHANGE_LINK_COLOR    :  return( node_change_link_color );
      case NODE_RANDOMIZE_LINK_COLOR :  return( node_randomize_link_color );
      case NODE_REPARENT_LINK_COLOR  :  return( node_reparent_link_color );
      case NODE_TOGGLE_FOLDS_SHALLOW :  return( node_toggle_folds_shallow );
      case NODE_TOGGLE_FOLDS_DEEP    :  return( node_toggle_folds_deep );
      case NODE_TOGGLE_LINKS         :  return( node_toggle_links );
      case NODE_ADD_GROUP            :  return( node_add_group );
      case NODE_ADD_CONNECTION       :  return( node_add_connection );
      case NODE_TOGGLE_CALLOUT       :  return( node_toggle_callout );
      case NODE_TOGGLE_SEQUENCE      :  return( node_toggle_sequence );
      case NODE_SELECT_ROOT          :  return( node_select_root );
      case NODE_SELECT_PARENT        :  return( node_select_parent );
      case NODE_SELECT_SIBLING_NEXT  :  return( node_select_sibling_next );
      case NODE_SELECT_SIBLING_PREV  :  return( node_select_sibling_previous );
      case NODE_SELECT_CHILD         :  return( node_select_child );
      case NODE_SELECT_CHILDREN      :  return( node_select_children );
      case NODE_SELECT_TREE          :  return( node_select_tree );
      case NODE_SELECT_DOWN          :  return( node_select_down );
      case NODE_SELECT_UP            :  return( node_select_up );
      case NODE_SELECT_RIGHT         :  return( node_select_right );
      case NODE_SELECT_LEFT          :  return( node_select_left );
      case NODE_SELECT_LINKED        :  return( node_select_linked );
      case NODE_SELECT_CALLOUT       :  return( node_select_callout );
      case NODE_SELECT_CONNECTION    :  return( node_select_connection );
      case NODE_SWAP_RIGHT           :  return( node_swap_right );
      case NODE_SWAP_LEFT            :  return( node_swap_left );
      case NODE_SWAP_UP              :  return( node_swap_up );
      case NODE_SWAP_DOWN            :  return( node_swap_down );
      case NODE_SORT_ALPHABETICALLY  :  return( node_sort_alphabetically );
      case NODE_SORT_RANDOMLY        :  return( node_sort_randomly );
      case NODE_DETACH               :  return( node_detach );
      case NODE_ALIGN_TOP            :  return( node_align_top );
      case NODE_ALIGN_VCENTER        :  return( node_align_vcenter );
      case NODE_ALIGN_BOTTOM         :  return( node_align_bottom );
      case NODE_ALIGN_LEFT           :  return( node_align_left );
      case NODE_ALIGN_HCENTER        :  return( node_align_hcenter );
      case NODE_ALIGN_RIGHT          :  return( node_align_right );
      case CALLOUT_SELECT_NODE       :  return( callout_select_node );
      case CALLOUT_REMOVE            :  return( callout_remove );
      case CONNECTION_REMOVE         :  return( connection_remove );
      case CONNECTION_SELECT_FROM    :  return( connection_select_from_node );
      case CONNECTION_SELECT_TO      :  return( connection_select_to_node );
      case CONNECTION_SELECT_NEXT    :  return( connection_select_next );
      case CONNECTION_SELECT_PREV    :  return( connection_select_previous );
      case STICKER_REMOVE            :  return( sticker_remove );
      case GROUP_CHANGE_COLOR        :  return( group_change_color );
      case GROUP_MERGE               :  return( group_merge );
      case GROUP_REMOVE              :  return( group_remove );
      case GROUP_SELECT_MAIN         :  return( group_select_main );
      case GROUP_SELECT_ALL          :  return( group_select_all );
      case EDIT_INSERT_NEWLINE       :  return( edit_insert_newline );
      case EDIT_INSERT_TAB           :  return( edit_insert_tab );
      case EDIT_INSERT_EMOJI         :  return( edit_insert_emoji );
      case EDIT_ESCAPE               :  return( edit_escape );
      case EDIT_BACKSPACE            :  return( edit_backspace );
      case EDIT_DELETE               :  return( edit_delete );
      case EDIT_REMOVE_WORD_NEXT     :  return( edit_remove_word_next );
      case EDIT_REMOVE_WORD_PREV     :  return( edit_remove_word_previous );
      case EDIT_COPY                 :  return( edit_copy );
      case EDIT_CUT                  :  return( edit_cut );
      case EDIT_PASTE                :  return( edit_paste );
      case EDIT_OPEN_URL             :  return( edit_open_url );
      case EDIT_ADD_URL              :  return( edit_add_url );
      case EDIT_EDIT_URL             :  return( edit_edit_url );
      case EDIT_REMOVE_URL           :  return( edit_remove_url );
      case EDIT_CURSOR_CHAR_NEXT     :  return( edit_cursor_char_next );
      case EDIT_CURSOR_CHAR_PREV     :  return( edit_cursor_char_previous );
      case EDIT_CURSOR_UP            :  return( edit_cursor_up );
      case EDIT_CURSOR_DOWN          :  return( edit_cursor_down );
      case EDIT_CURSOR_WORD_NEXT     :  return( edit_cursor_word_next );
      case EDIT_CURSOR_WORD_PREV     :  return( edit_cursor_word_previous );
      case EDIT_CURSOR_FIRST         :  return( edit_cursor_to_start );
      case EDIT_CURSOR_LAST          :  return( edit_cursor_to_end );
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
      (this == ZOOM_SELECTED) ||
      (this == EDIT_NOTE) ||
      (this == SHOW_CURRENT_INFO) ||
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
      (this == SHOW_CURRENT_INFO) ||
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
      (this == SHOW_CURRENT_INFO) ||
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
      (this == SHOW_CURRENT_INFO)
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
  // Returns a string ID for the map state this this command
  // targets.
  private string target_id() {
    if( for_node() ) {
      return( "0" );
    } else if( for_connection() ) {
      return( "1" );
    } else if( for_callout() ) {
      return( "2" );
    } else if( for_group() ) {
      return( "3" );
    } else if( for_sticker() ) {
      return( "4" );
    } else if( for_editing() ) {
      return( "5" );
    } else if( for_none() ) {
      return( "6" );
    } else {
      return( "0123456" );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the this command and the other command
  // are targetting the same map state.
  public bool target_matches( KeyCommand command ) {
    var mine   = target_id();
    var theirs = command.target_id();
    return( mine.contains( theirs ) || theirs.contains( mine ) );
  }

  //-------------------------------------------------------------
  // Returns true if this key command is able to have a shortcut
  // associated with it.  These should have built-in shortcuts
  // associated with each of them.
  public bool viewable() {
    return(
      (this != DO_NOTHING) &&
      (this != CONTROL_PRESSED) &&
      (this != ESCAPE) &&
      (this != EDIT_ESCAPE) &&
      (this != EDIT_BACKSPACE) &&
      (this != NODE_REMOVE) &&
      (this != NODE_REMOVE_ONLY) &&
      (this != CALLOUT_REMOVE) &&
      (this != GROUP_REMOVE) &&
      (this != EDIT_DELETE) &&
      (this != NODE_ADD_SIBLING_AFTER) &&
      (this != NODE_ADD_SIBLING_BEFORE) &&
      (this != NODE_ADD_CHILD) &&
      (this != NODE_ADD_PARENT) &&
      (this != EDIT_CURSOR_CHAR_NEXT) &&
      (this != EDIT_CURSOR_CHAR_PREV) &&
      (this != EDIT_CURSOR_UP) &&
      (this != EDIT_CURSOR_DOWN) &&
      (this != EDIT_SELECT_CHAR_NEXT) &&
      (this != EDIT_SELECT_CHAR_PREV) &&
      (this != NODE_SELECT_RIGHT) &&
      (this != NODE_SELECT_LEFT) &&
      (this != NODE_SELECT_UP) &&
      (this != NODE_SELECT_DOWN) &&
      (this != NODE_SELECT_SIBLING_PREV) &&
      (this != NODE_SELECT_SIBLING_NEXT) &&
      (this != NODE_SWAP_UP) &&
      (this != NODE_SWAP_DOWN) &&
      ((this < CONNECTION_EXIST_START) || (CONNECTION_EXIST_END < this)) &&
      ((this < STICKER_START) || (STICKER_END < this)) &&
      ((this < EDIT_MISC_START) || (EDIT_MISC_END < this))
    );
  }

  //-------------------------------------------------------------
  // Returns true if this command can have its shortcut be edited.
  public bool editable() {
    if( viewable() ) {
      switch( this ) {
        case ESCAPE            :
        case NODE_REMOVE       :
        case NODE_REMOVE_ONLY  :
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
  public bool is_section_start() {
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
  public bool is_section_end() {
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
  // Returns true if the given key command is a section group
  // start indicator.
  public bool is_group_start() {
    switch( this ) {
      case FILE_START              :
      case TAB_START               :
      case UNDO_START              :
      case ZOOM_START              :
      case SIDEBAR_START           :
      case MAP_START               :
      case MISCELLANEOUS_START     :
      case NODE_EXIST_START        :
      case NODE_CLIPBOARD_START    :
      case NODE_VIEW_START         :
      case NODE_CHANGE_START       :
      case NODE_SELECT_START       :
      case NODE_MOVE_START         :
      case NODE_ALIGN_START        :
      case CONNECTION_EXIST_START  :
      case CONNECTION_SELECT_START :
      case GROUP_CHANGE_START      :
      case GROUP_SELECT_START      :
      case EDIT_TEXT_START         :
      case EDIT_CLIPBOARD_START    :
      case EDIT_URL_START          :
      case EDIT_CURSOR_START       :
      case EDIT_SELECT_START       :
      case EDIT_MISC_START         :
        return( true );
      default :
        return( false );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the given key command is a section group
  // end indicator.
  public bool is_group_end() {
    switch( this ) {
      case FILE_END              :
      case TAB_END               :
      case UNDO_END              :
      case ZOOM_END              :
      case SIDEBAR_END           :
      case MISCELLANEOUS_END     :
      case MAP_END               :
      case NODE_EXIST_END        :
      case NODE_CLIPBOARD_END    :
      case NODE_VIEW_END         :
      case NODE_CHANGE_END       :
      case NODE_SELECT_END       :
      case NODE_MOVE_END         :
      case NODE_ALIGN_END        :
      case CONNECTION_EXIST_END  :
      case CONNECTION_SELECT_END :
      case GROUP_CHANGE_END      :
      case GROUP_SELECT_END      :
      case EDIT_TEXT_END         :
      case EDIT_CLIPBOARD_END    :
      case EDIT_URL_END          :
      case EDIT_CURSOR_END       :
      case EDIT_SELECT_END       :
      case EDIT_MISC_END         :
        return( true );
      default :
        return( false );
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

  public static void file_new( MindMap map ) {
    map.win.do_new_file();
  }

  public static void file_open( MindMap map ) {
    map.win.do_open_file();
  }

  public static void file_open_dir( MindMap map ) {
    map.win.do_open_directory();
  }

  public static void file_save( MindMap map ) {
    if( map.doc.is_saved() && map.editable ) {
      map.doc.save();
    } else {
      map.win.save_file( map, false );
    }
  }

  public static void file_save_as( MindMap map ) {
    map.win.do_save_as_file();
  }

  public static void file_print( MindMap map ) {
    var print = new ExportPrint();
    print.print( map, map.win );
  }

  public static void tab_goto_next( MindMap map ) {
    map.win.next_tab();
  }

  public static void tab_goto_prev( MindMap map ) {
    map.win.previous_tab();
  }

  public static void tab_close_current( MindMap map ) {
    map.win.close_current_tab();
  }

  public static void undo_action( MindMap map ) {
    if( !map.editable ) return;
    if( map.undo_buffer.undoable() ) {
      map.undo_buffer.undo();
    }
  }

  public static void redo_action( MindMap map ) {
    if( !map.editable ) return;
    if( map.undo_buffer.redoable() ) {
      map.undo_buffer.redo();
    }
  }

  public static void zoom_in( MindMap map ) {
    map.canvas.zoom_in();
  }

  public static void zoom_out( MindMap map ) {
    map.canvas.zoom_out();
  }

  public static void zoom_fit( MindMap map ) {
    map.canvas.zoom_to_fit();
  }

  public static void zoom_selected( MindMap map ) {
    map.canvas.zoom_to_selected();
  }

  public static void zoom_actual( MindMap map ) {
    map.canvas.zoom_actual();
  }

  public static void show_current_sidebar( MindMap map ) {
    map.show_properties( "current", PropertyGrab.FIRST );
  }

  public static void show_style_sidebar( MindMap map ) {
    map.show_properties( "style", PropertyGrab.FIRST );
  }

  public static void show_tag_sidebar( MindMap map ) {
    map.show_properties( "tag", PropertyGrab.FIRST );
  }

  public static void show_sticker_sidebar( MindMap map ) {
    map.show_properties( "sticker", PropertyGrab.FIRST );
  }

  public static void show_map_sidebar( MindMap map ) {
    map.show_properties( "map", PropertyGrab.FIRST );
  }

  public static void toggle_connections( MindMap map ) {
    map.model.connections.hide = !map.model.connections.hide;
    map.queue_draw();
  }

  public static void toggle_callouts( MindMap map ) {
    map.model.hide_callouts = !map.model.hide_callouts;
    map.queue_draw();
  }

  public static void balance_nodes( MindMap map ) {
    if( !map.editable ) return;
    map.model.balance_nodes( true, true );
  }

  public static void fold_completed_tasks( MindMap map ) {
    map.model.fold_completed_tasks();
  }

  public static void unfold_all_nodes( MindMap map ) {
    map.model.unfold_all_nodes();
  }

  public static void show_preferences( MindMap map ) {
    var prefs = new Preferences( map.win );
    prefs.present();
  }

  public static void show_shortcuts( MindMap map ) {

    var ui_str  = map.win.shortcuts.get_ui_string();
    var builder = new Gtk.Builder.from_string( ui_str, ui_str.length );
    var win     = builder.get_object( "shortcuts" ) as Gtk.ShortcutsWindow;

    win.transient_for = map.win;
    win.view_name     = null;

    /* Display the most relevant information based on the current state */
    if( map.is_node_editable() || map.is_connection_editable() ) {
      win.section_name = "editing";
    } else if( map.is_node_selected() ) {
      win.section_name = "node";
    } else if( map.is_connection_selected() ) {
      win.section_name = "connection";
    } else if( map.is_callout_selected() ) {
      win.section_name = "callout";
    } else if( map.is_group_selected() ) {
      win.section_name = "group";
    } else {
      win.section_name = "general";
    }

    win.show();

  }

  public static void show_contextual_menu( MindMap map ) {
    map.canvas.show_contextual_menu( map.canvas.scaled_x, map.canvas.scaled_y );
  }

  public static void show_find( MindMap map ) {
    map.win.show_find();
  }

  public static void show_about( MindMap map ) {
    var about = new About( map.win );
    about.show();
  }

  public static void toggle_braindump( MindMap map ) {
    if( !map.editable ) return;
    map.win.toggle_braindump();
  }

  public static void toggle_focus_mode( MindMap map ) {
    map.win.toggle_focus_mode();
  }

  public static void edit_note( MindMap map ) {
    if( !map.editable ) return;
    map.show_properties( "current", PropertyGrab.NOTE ); 
  }

  public static void edit_selected( MindMap map ) {
    if( !map.editable ) return;
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
    if( !map.editable ) return;
    map.model.remove_sticker();
  }

  public static void quit_application( MindMap map ) {
    map.win.close_request();
    map.win.destroy();
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
      map.hide_properties();
    }
  }

  //-------------------------------------------------------------
  // NODE FUNCTIONS

  public static void node_align_top( MindMap map ) {
    if( !map.editable ) return;
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_top( map, map.selected.nodes() );
    }
  }

  public static void node_align_vcenter( MindMap map ) {
    if( !map.editable ) return;
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_vcenter( map, map.selected.nodes() );
    }
  }

  public static void node_align_bottom( MindMap map ) {
    if( !map.editable ) return;
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_bottom( map, map.selected.nodes() );
    }
  }

  public static void node_align_left( MindMap map ) {
    if( !map.editable ) return;
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_left( map, map.selected.nodes() );
    }
  }

  public static void node_align_hcenter( MindMap map ) {
    if( !map.editable ) return;
    if( map.model.nodes_alignable() ) {
      NodeAlign.align_hcenter( map, map.selected.nodes() );
    }
  }

  public static void node_align_right( MindMap map ) {
    if( !map.editable ) return;
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
    if( !map.editable ) return;
    map.change_current_link_color();
  }

  public static void node_randomize_link_color( MindMap map ) {
    if( !map.editable ) return;
    map.model.randomize_current_link_color();
  }

  public static void node_reparent_link_color( MindMap map ) {
    if( !map.editable ) return;
    map.model.reparent_current_link_color();
  }

  public static void node_change_task( MindMap map ) {
    if( !map.editable ) return;
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
    if( !map.editable ) return;
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
    if( !map.editable ) return;
    node_return_helper( map, false );
  }

  public static void node_shift_return( MindMap map ) {
    if( !map.editable ) return;
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
    if( !map.editable ) return;
    node_tab_helper( map, false );
  }

  public static void node_shift_tab( MindMap map ) {
    if( !map.editable ) return;
    node_tab_helper( map, true );
  }

  public static void node_change_image( MindMap map ) {
    if( !map.editable ) return;
    var current = map.get_current_node();
    if( (current != null) && (current.image != null) ) {
      map.model.edit_current_image();
    } else {
      map.model.add_current_image();
    }
  }

  public static void node_remove_image( MindMap map ) {
    if( !map.editable ) return;
    map.model.delete_current_image();
  }

  public static void node_toggle_callout( MindMap map ) {
    if( !map.editable ) return;
    if (map.model.node_has_callout() ) {
      map.model.remove_callout();
    } else {
      map.model.add_callout();
    }
  }

  public static void node_add_group( MindMap map ) {
    if( !map.editable ) return;
    map.model.add_group();
  }

  public static void node_add_connection( MindMap map ) {
    if( !map.editable ) return;
    if( map.selected.num_nodes() == 2 ) {
      map.model.create_connection();
    } else {
      map.model.start_connection( true, false );
    }
  }

  public static void node_toggle_folds_shallow( MindMap map ) {
    if( !map.editable ) return;
    map.model.toggle_folds( false );
  }

  public static void node_toggle_folds_deep( MindMap map ) {
    if( !map.editable ) return;
    map.model.toggle_folds( true );
  }

  public static void node_toggle_sequence( MindMap map ) {
    if( !map.editable ) return;
    map.model.toggle_sequence();
  }

  public static void node_toggle_links( MindMap map ) {
    if( !map.editable ) return;
    map.model.toggle_links();
  }

  public static void node_center( MindMap map ) {
    map.canvas.center_current_node();
  }

  public static void node_sort_alphabetically( MindMap map ) {
    if( !map.editable ) return;
    map.model.sort_alphabetically();
  }

  public static void node_sort_randomly( MindMap map ) {
    if( !map.editable ) return;
    map.model.sort_randomly();
  }

  public static void node_quick_entry_insert( MindMap map ) {
    if( !map.editable ) return;
    var quick_entry = new QuickEntry( map, false, map.settings );
    quick_entry.preload( "- " );
  }

  public static void node_quick_entry_replace( MindMap map ) {
    if( !map.editable ) return;
    var quick_entry = new QuickEntry( map, true, map.settings );
    var export      = (ExportText)map.win.exports.get_by_name( "text" );
    quick_entry.preload( export.export_node( map, map.get_current_node(), "" ) );
  }

  public static void node_paste_node_link( MindMap map ) {
    if( !map.editable ) return;
    map.do_paste_node_link();
  }

  public static void node_paste_replace( MindMap map ) {
    if( !map.editable ) return;
    map.do_paste( true );
  }

  public static void node_remove( MindMap map ) {
    if( !map.editable ) return;
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
    if( !map.editable ) return;
    map.model.delete_nodes();
  }

  public static void node_detach( MindMap map ) {
    if( !map.editable ) return;
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
      if( other != null ) {
        map.swap_nodes( current, other );
      }
    }
  }

  public static void node_swap_left( MindMap map ) {
    if( !map.editable ) return;
    node_swap( map, "left" );
  }

  public static void node_swap_right( MindMap map ) {
    if( !map.editable ) return;
    node_swap( map, "right" );
  }

  public static void node_swap_up( MindMap map ) {
    if( !map.editable ) return;
    node_swap( map, "up" );
  }

  public static void node_swap_down( MindMap map ) {
    if( !map.editable ) return;
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
    if( !map.editable ) return;
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
    if( !map.editable ) return;
    map.model.remove_callout();
  }

  //-------------------------------------------------------------
  // STICKER FUNCTIONS

  public static void sticker_remove( MindMap map ) {
    if( !map.editable ) return;
    map.model.remove_sticker();
  }

  //-------------------------------------------------------------
  // GROUP FUNCTIONS

  public static void group_change_color( MindMap map ) {
    if( !map.editable ) return;
    var color_picker = new Gtk.ColorChooserDialog( _( "Select a group color" ), map.win );
    color_picker.color_activated.connect((color) => {
      map.model.change_group_color( color );
    });
    color_picker.present();
  }

  public static void group_merge( MindMap map ) {
    if( !map.editable ) return;
    map.model.add_group();
  }

  public static void group_remove( MindMap map ) {
    if( !map.editable ) return;
    map.model.remove_groups();
  }

  public static void group_select_main( MindMap map ) {
    map.group_select_main();
  }

  public static void group_select_all( MindMap map ) {
    map.group_select_all();
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
    if( !map.editable ) return;
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
          map.hide_properties();
        }
      }
    }
  }

  public static void edit_insert_newline( MindMap map ) {
    if( !map.editable ) return;
    insert_text( map, "\n" );
  }

  public static void edit_insert_tab( MindMap map ) {
    if( !map.editable ) return;
    insert_text( map, "\t" );
  }

  public static void edit_insert_emoji( MindMap map ) {
    if( !map.editable ) return;
    var text = map.get_current_text();
    if( text != null ) {
      map.canvas.insert_emoji( text );
    }
  }

  public static void edit_backspace( MindMap map ) {
    if( !map.editable ) return;
    var text = map.get_current_text();
    if( text != null ) {
      text.backspace( map.undo_text );
      text_changed( map );
    }
  }

  public static void edit_delete( MindMap map ) {
    if( !map.editable ) return;
    var text = map.get_current_text();
    if( text != null ) {
      text.delete( map.undo_text );
      text_changed( map );
    }
  }

  public static void edit_remove_word_previous( MindMap map ) {
    if( !map.editable ) return;
    var text = map.get_current_text();
    if( text != null ) {
      text.backspace_word( map.undo_text );
      text_changed( map );
    }
  }

  public static void edit_remove_word_next( MindMap map ) {
    if( !map.editable ) return;
    var text = map.get_current_text();
    if( text != null ) {
      text.delete_word( map.undo_text );
      text_changed( map );
    }
  }

  public static void edit_cursor_char_next( MindMap map ) {
    if( !map.editable ) return;
    edit_cursor( map, "char-next" );
  }

  public static void edit_cursor_char_previous( MindMap map ) {
    if( !map.editable ) return;
    edit_cursor( map, "char-prev" );
  }

  public static void edit_cursor_up( MindMap map ) {
    if( !map.editable ) return;
    edit_cursor( map, "up" );
  }

  public static void edit_cursor_down( MindMap map ) {
    if( !map.editable ) return;
    edit_cursor( map, "down" );
  }

  public static void edit_cursor_word_next( MindMap map ) {
    if( !map.editable ) return;
    edit_cursor( map, "word-next" );
  }

  public static void edit_cursor_word_previous( MindMap map ) {
    if( !map.editable ) return;
    edit_cursor( map, "word-prev" );
  }

  public static void edit_cursor_to_start( MindMap map ) {
    if( !map.editable ) return;
    edit_cursor( map, "start" );
  }

  public static void edit_cursor_to_end( MindMap map ) {
    if( !map.editable ) return;
    edit_cursor( map, "end" );
  }

  public static void edit_cursor_to_linestart( MindMap map ) {
    if( !map.editable ) return;
    edit_cursor( map, "linestart" );
  }

  public static void edit_cursor_to_lineend( MindMap map ) {
    if( !map.editable ) return;
    edit_cursor( map, "lineend" );
  }

  public static void edit_select_char_next( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "char-next" );
  }

  public static void edit_select_char_previous( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "char-prev" );
  }

  public static void edit_select_up( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "up" );
  }

  public static void edit_select_down( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "down" );
  }

  public static void edit_select_word_next( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "word-next" );
  }

  public static void edit_select_word_previous( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "word-prev" );
  }

  public static void edit_select_start_up( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "start-up" );
  }

  public static void edit_select_start_home( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "start-home" );
  }

  public static void edit_select_end_down( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "end-down" );
  }

  public static void edit_select_end_end( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "end-end" );
  }

  public static void edit_select_linestart( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "linestart" );
  }

  public static void edit_select_lineend( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "lineend" );
  }

  public static void edit_select_all( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "all" );
  }

  public static void edit_deselect_all( MindMap map ) {
    if( !map.editable ) return;
    edit_selection( map, "none" );
  }

  public static void edit_open_url( MindMap map ) {
    if( !map.editable ) return;
    var text = map.get_current_text();
    if( text != null ) {
      int cursor, selstart, selend;
      text.get_cursor_info( out cursor, out selstart, out selend );
      var links = text.text.get_full_tags_in_range( FormatTag.URL, cursor, cursor );
      Utils.open_url( links.index( 0 ).extra );
    }
  }

  public static void edit_add_url( MindMap map ) {
    if( !map.editable ) return;
    map.canvas.url_editor.add_url();
  }

  public static void edit_edit_url( MindMap map ) {
    if( !map.editable ) return;
    map.canvas.url_editor.edit_url();
  }

  public static void edit_remove_url( MindMap map ) {
    if( !map.editable ) return;
    map.canvas.url_editor.remove_url();
  }

  public static void edit_copy( MindMap map ) {
    if( !map.editable ) return;
    map.model.do_copy();
  }

  public static void edit_cut( MindMap map ) {
    if( !map.editable ) return;
    map.model.do_cut();
  }

  public static void edit_paste( MindMap map ) {
    if( !map.editable ) return;
    map.do_paste( false );
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
    if( !map.editable ) return;
    edit_return_helper( map, false );
  }

  public static void edit_shift_return( MindMap map ) {
    if( !map.editable ) return;
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
    if( !map.editable ) return;
    edit_tab_helper( map, false );
  }

  public static void edit_shift_tab( MindMap map ) {
    if( !map.editable ) return;
    edit_tab_helper( map, true );
  }

}
