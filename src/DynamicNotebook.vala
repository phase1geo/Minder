/*
 *  Copyright (C) 2011-2013 Tom Beckmann <tom@elementaryos.org>
 *
 *  This program or library is free software; you can redistribute it
 *  and/or modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General
 *  Public License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301 USA.
 */

    // a mask to ignore modifiers like num lock or caps lock that are irrelevant to keyboard shortcuts
    internal const Gdk.ModifierType MODIFIER_MASK = (Gdk.ModifierType.SHIFT_MASK |
                                                     Gdk.ModifierType.SUPER_MASK |
                                                     Gdk.ModifierType.CONTROL_MASK |
                                                     Gdk.ModifierType.MOD1_MASK);

    private class TabPageContainer : Gtk.EventBox {
        private unowned Tab _tab = null;

        public unowned Tab tab {
            get { return _tab; }
            set { _tab = value; }
        }

        public TabPageContainer (Tab tab) {
            Object (tab: tab);
        }

        construct {
            add (new Gtk.Grid ());
        }
    }

    /**
     * This is a standard tab which can be used in a notebook to form a tabbed UI.
     */
    public class Tab : Gtk.EventBox {
        Gtk.Label _label;
        public string label {
            get { return _label.label;  }

            set {
                _label.label = value;
            }
        }
        public string tooltip {
            owned get { return _label.get_tooltip_text (); }
            set { _label.set_tooltip_text (value); }
        }

        private bool _pinned = false;
        public bool pinned {
            get { return _pinned; }

            set {
                if (pinnable) {
                    if (value != _pinned) {
                        if (value) {
                            _label.visible = false;
                            _icon.margin_start = 1;
                            _working.margin_start = 1;
                        } else {
                            _label.visible = true;
                            _icon.margin_start = 0;
                            _working.margin_start = 0;
                        }

                        _pinned = value;
                        update_close_button_visibility ();
                        this.pin_switch ();
                    }
                }
            }
        }

        private bool _pinnable = true;
        public bool pinnable {
            get { return _pinnable; }
            set {
                if (!value) {
                    pinned = false;
                }

                _pinnable = value;
            }
        }

        /**
         * Data which will be kept once the tab is deleted, and which will be used by
         * the application to restore the data into the restored tab. Let it empty if
         * the tab should not be restored.
         **/
        public string restore_data { get; set; default=""; }

        /**
         * An optional delegate that is called when the tab is dropped from the set
         * of restorable tabs in DynamicNotebook.
         * A tab is dropped either when Clear All is pressed, or when
         * the tab is the oldest tab in the set of restorable tabs and
         * the number of restorable tabs has exceeded the upper limit.
         */
        public Granite.WidgetsDroppedDelegate dropped_callback = null;

        internal TabPageContainer page_container;
        public Gtk.Widget page {
            get {
                return page_container.get_child ();
            }
            set {
                weak Gtk.Widget container_child = page_container.get_child ();
                if (container_child != null) {
                    page_container.remove (container_child);
                }

                weak Gtk.Container? value_parent = value.get_parent ();
                if (value_parent != null) {
                    value_parent.remove (value);
                    page_container.add (value);
                } else {
                    page_container.add (value);
                }

                page_container.show_all ();
            }
        }

        internal Gtk.Image _icon;
        public GLib.Icon? icon {
            owned get { return _icon.gicon;  }
            set { _icon.gicon = value; }
        }

        Gtk.Spinner _working;
        bool __working;
        public bool working {
            get { return __working; }

            set {
                __working = _working.visible = value;
                _icon.visible = !value;
            }
        }

        public Pango.EllipsizeMode ellipsize_mode {
            get { return _label.ellipsize; }
            set { _label.ellipsize = value; }
        }

        bool _fixed;
        [Version (deprecated = true, deprecated_since = "0.3", replacement = "")]
        public bool fixed {
            get { return _fixed; }
            set {
                if (value != _fixed) {
                    _fixed = value;
                    _label.visible = value;
                }
            }
        }

        public Gtk.Menu menu { get; set; }

        private bool _closable = true;
        internal bool closable {
            set {
                if (value == _closable)
                    return;

                _closable = value;
                update_close_button_visibility ();
            }
        }

        //We need to be able to toggle these from the notebook.
        internal Gtk.MenuItem new_window_m;
        internal Gtk.MenuItem duplicate_m;
        internal Gtk.MenuItem pin_m;

        private bool _is_current_tab = false;
        internal bool is_current_tab {
            set {
                _is_current_tab = value;
                update_close_button_visibility ();
            }
        }

        private bool cursor_over_tab = false;
        private bool cursor_over_close_button = false;
        private Gtk.Revealer close_button_revealer;

        internal signal void closed ();
        internal signal void close_others ();
        internal signal void new_window ();
        internal signal void duplicate ();
        internal signal void pin_switch ();

        /**
         * With this you can construct a Tab. It is linked to the page that is shown on focus.
         * A Tab can have a icon on the right side. You can pass null on the constructor to
         * create a tab without a icon.
         **/
        public Tab (string? label = null, GLib.Icon? icon = null, Gtk.Widget? page = null) {
            Object (label: label, icon: icon);
            if (page != null) {
                this.page = page;
            }
        }

        construct {
            _label = new Gtk.Label (null);
            _label.hexpand = true;
            _label.tooltip_text = label;
            _label.ellipsize = Pango.EllipsizeMode.END;

            _icon = new Gtk.Image ();
            _icon.icon_size = Gtk.IconSize.MENU;
            _icon.visible = true;
            _icon.set_size_request (16, 16);

            _working = new Gtk.Spinner ();
            _working.set_size_request (16, 16);
            _working.start();

            var close_button = new Gtk.Button.from_icon_name ("window-close-symbolic", Gtk.IconSize.MENU);
            close_button.tooltip_text = _("Close Tab");
            close_button.valign = Gtk.Align.CENTER;
            close_button.relief = Gtk.ReliefStyle.NONE;

            close_button_revealer = new Gtk.Revealer ();
            close_button_revealer.transition_type = Gtk.RevealerTransitionType.CROSSFADE;
            close_button_revealer.add (close_button);

            var tab_layout = new Gtk.Grid ();
            tab_layout.hexpand = false;
            tab_layout.orientation = Gtk.Orientation.HORIZONTAL;
            tab_layout.add (close_button_revealer);
            tab_layout.add (_label);
            tab_layout.add (_icon);
            tab_layout.add (_working);

            visible_window = true;

            add (tab_layout);
            show_all ();

            page_container = new TabPageContainer (this);

            menu = new Gtk.Menu ();
            var close_m = new Gtk.MenuItem.with_label (_("Close Tab"));
            var close_other_m = new Gtk.MenuItem.with_label ("");
            pin_m = new Gtk.MenuItem.with_label ("");
            new_window_m = new Gtk.MenuItem.with_label (_("Open in a New Window"));
            duplicate_m = new Gtk.MenuItem.with_label (_("Duplicate"));
            menu.append (close_other_m);
            menu.append (close_m);
            menu.append (new_window_m);
            menu.append (duplicate_m);
            menu.append (pin_m);
            menu.show_all ();

            close_m.activate.connect (() => closed () );
            close_other_m.activate.connect (() => close_others () );
            new_window_m.activate.connect (() => new_window () );
            duplicate_m.activate.connect (() => duplicate () );
            pin_m.activate.connect (() => pinned = !pinned);

            this.scroll_event.connect ((e) => {
                var notebook = (this.get_parent () as Gtk.Notebook);
                switch (e.direction) {
                    case Gdk.ScrollDirection.UP:
                    case Gdk.ScrollDirection.LEFT:
                        if (notebook.page > 0) {
                            notebook.page--;
                            return true;
                        }
                        break;

                    case Gdk.ScrollDirection.DOWN:
                    case Gdk.ScrollDirection.RIGHT:
                        if (notebook.page < notebook.get_n_pages ()) {
                            notebook.page++;
                            return true;
                        }
                        break;
                }

                return false;
            });

            this.button_press_event.connect ((e) => {
                if (e.button == 2 && close_button_is_visible ()) {
                    e.state &= MODIFIER_MASK;

                    if  (e.state == 0) {
                        this.closed ();
                    } else if (e.state == Gdk.ModifierType.SHIFT_MASK) {
                        this.close_others ();
                    }
                } else if (e.button == 1 && e.type == Gdk.EventType.2BUTTON_PRESS && duplicate_m.visible) {
                    this.duplicate ();
                } else if (e.button == 3) {
                    menu.popup_at_pointer (e);
                    var cont = (this.get_parent() as Gtk.Container);
                    uint num_tabs = (cont == null) ? 0 : cont.get_children ().length ();
                    close_other_m.label = ngettext (_("Close Other Tab"), _("Close Other Tabs"), num_tabs - 1);
                    close_other_m.sensitive = (num_tabs != 1);
                    new_window_m.sensitive = (num_tabs != 1);
                    pin_m.label = "Pin";
                    if (this.pinned) {
                        pin_m.label = "Unpin";
                    }
                } else {
                    return false;
                }

                return true;
            });

            this.enter_notify_event.connect ((e) => {
                cursor_over_tab = true;
                update_close_button_visibility ();
                return false;
            });

            this.leave_notify_event.connect ((e) => {
                // We don't want to handle leave_notify events without a prior enter_notify
                // for event parity reasons.
                if (!cursor_over_tab)
                    return false;

                cursor_over_tab = false;
                update_close_button_visibility ();
                return false;
            });

            // Hovering the close button area causes a leave_notify_event on the tab EventBox.
            // Because of that we need to watch the events from those widgets independently
            // to avoid misbehavior. While setting "above_child" to "true" on the tab might
            // appear to be a more proper solution, that wouldn't let us capture any event
            // (e.g. button_press) on the button.
            close_button.enter_notify_event.connect ((e) => {
                cursor_over_close_button = true;
                update_close_button_visibility ();
                return false;
            });

            close_button.leave_notify_event.connect ((e) => {
                // We don't want to handle leave_notify events without a prior enter_notify
                // for event parity reasons.
                if (!cursor_over_close_button)
                    return false;

                cursor_over_close_button = false;
                update_close_button_visibility ();
                return false;
            });

            page_container.button_press_event.connect (() => { return true; }); //dont let clicks pass through
            close_button.clicked.connect (() => this.closed ());
            working = false;

            update_close_button_visibility ();
        }

        public void close () {
            closed ();
        }

        private void update_close_button_visibility () {
            // If the tab is pinned, we don't want the revealer to keep
            // the size allocation of the close button.
            close_button_revealer.no_show_all = _pinned;
            close_button_revealer.visible = !_pinned;

            close_button_revealer.reveal_child = _closable && !_pinned
                && (cursor_over_tab || cursor_over_close_button || _is_current_tab);
        }

        private bool close_button_is_visible () {
            return close_button_revealer.visible && close_button_revealer.child_revealed;
        }
    }

    private class ClosedTabs : GLib.Object {

        public signal void restored (string label, string restore_data, GLib.Icon? icon);
        public signal void cleared ();

        private int _max_restorable_tabs = 10;
        public int max_restorable_tabs {
            get { return _max_restorable_tabs; }
            set {
                assert (value > 0);
                _max_restorable_tabs = value;
            }
        }

        internal struct Entry {
            string label;
            string restore_data;
            GLib.Icon? icon;
            weak Granite.WidgetsDroppedDelegate? dropped_callback;
        }

        private Gee.LinkedList<Entry?> closed_tabs;

        public ClosedTabs () {

        }

        construct {
            closed_tabs = new Gee.LinkedList<Entry?> ();
        }

        public bool empty {
            get {
                return closed_tabs.size == 0;
            }
        }

        public void push (Tab tab) {
            foreach (var entry in closed_tabs)
                if (tab.restore_data == entry.restore_data)
                    return;

            // Insert the element at the end of the list.
            Entry e = { tab.label, tab.restore_data, tab.icon, tab.dropped_callback };
            closed_tabs.add (e);

            // If the maximum size is exceeded, remove from the beginning of the list.
            if (closed_tabs.size > max_restorable_tabs) {
                var elem = closed_tabs.poll_head ();
                unowned Granite.WidgetsDroppedDelegate? dropped_callback = elem.dropped_callback;

                if (dropped_callback != null)
                    dropped_callback ();
            }
        }

        public Entry pop () {
            assert (closed_tabs.size > 0);
            return closed_tabs.poll_tail ();
        }

        public Entry pick (string search) {
            Entry picked = {null, null, null};

            for (int i = 0; i < closed_tabs.size; i++) {
                var entry = closed_tabs[i];

                if (entry.restore_data == search) {
                    picked = closed_tabs.remove_at (i);
                    break;
                 }
             }

            return picked;
        }

        public Gtk.Menu menu {
            owned get {
                var _menu = new Gtk.Menu ();

                foreach (var entry in closed_tabs) {
                    var item = new Gtk.MenuItem.with_label (entry.label);
                    _menu.prepend (item);

                    item.activate.connect (() => {
                        var e = pick (entry.restore_data);
                        this.restored (e.label, e.restore_data, e.icon);
                    });
                }

                if (!empty) {
                    var separator = new Gtk.SeparatorMenuItem ();
                    var item = new Gtk.MenuItem.with_label (_("Clear All"));

                    _menu.append (separator);
                    _menu.append (item);

                    item.activate.connect (() => {
                        foreach (var entry in closed_tabs) {
                            if (entry.dropped_callback != null) {
                                entry.dropped_callback ();
                            }
                        }

                        closed_tabs.clear ();
                        cleared ();
                    });
                }

                return _menu;
            }
        }
    }

    /**
    * Tab bar widget designed for a variable number of tabs.
    * Supports showing a "New tab" button, restoring closed tabs, "pinning" tabs, and more.
    *
    * {{../doc/images/DynamicNotebook.png}}
    */
    public class DynamicNotebook : Gtk.EventBox {
        /**
         * number of pages
         */
        public int n_tabs {
            get { return notebook.get_n_pages (); }
        }

        /**
         * Hide the tab bar and only show the pages
         */
        public bool show_tabs {
            get { return notebook.show_tabs;  }
            set { notebook.show_tabs = value; }
        }

        /**
         * Toggle icon display
         */
        bool _show_icons;
        [Version (deprecated = true, deprecated_since = "0.3.1", replacement = "")]
        public bool show_icons {
            get { return _show_icons; }
            set {
                _show_icons = value;
            }
        }

        /**
         * Hide the close buttons and disable closing of tabs
         */
        bool _tabs_closable = true;
        public bool tabs_closable {
            get { return _tabs_closable; }
            set {
                if (value != _tabs_closable)
                    tabs.foreach ((t) => {
                            t.closable = value;
                        });
                _tabs_closable = value;
            }
        }

        /**
         * Make tabs reorderable
         */
        bool _allow_drag = true;
        public bool allow_drag {
            get { return _allow_drag; }
            set {
                _allow_drag = value;
                this.tabs.foreach ((t) => {
                    notebook.set_tab_reorderable (t.page_container, value);
                });
            }
        }

        /**
         * Allow creating new windows by dragging a tab out
         */
        bool _allow_new_window = false;
        public bool allow_new_window {
            get { return _allow_new_window; }
            set {
                _allow_new_window = value;
                this.tabs.foreach ((t) => {
                    notebook.set_tab_detachable (t.page_container, value);
                });
            }
        }

        /**
         * Allow duplicating tabs
         */
        bool _allow_duplication = false;
        public bool allow_duplication {
            get { return _allow_duplication; }
            set {
                _allow_duplication = value;

                foreach (var tab in tabs) {
                    tab.duplicate_m.visible = value;
                }
            }
        }

        /**
         * Allow restoring tabs
         */
        bool _allow_restoring = false;
        public bool allow_restoring {
            get { return _allow_restoring; }
            set {
                _allow_restoring = value;
                restore_tab_m.visible = value;
                restore_button.visible = value;
            }
        }

        /**
         * Set or get the upper limit of the size of the set
         * of restorable tabs.
         */
        public int max_restorable_tabs {
            get { return closed_tabs.max_restorable_tabs; }
            set { closed_tabs.max_restorable_tabs = value; }
        }

        /**
         * Controls the '+' add button visibility
         */
        bool _add_button_visible = true;
        public bool add_button_visible {
            get { return _add_button_visible; }
            set {
                if (value != _add_button_visible) {
                    if (_add_button_visible) {
                        notebook.remove (add_button);
                    } else {
                        notebook.set_action_widget (add_button, Gtk.PackType.START);
                    }

                    _add_button_visible = value;
                    new_tab_m.visible   = value;
                }
            }
        }

        bool _allow_pinning = false;
        public bool allow_pinning {
            get { return _allow_pinning; }
            set {
                _allow_pinning = value;

                foreach (var tab in tabs) {
                    tab.pinnable = value;
                }
            }
        }

        bool _force_left = true;
        public bool force_left {
            get { return _force_left; }
            set { _force_left = value; }
        }

       /**
        * The text shown in the add button tooltip
        */
        public string add_button_tooltip {
            get { _add_button_tooltip = add_button.tooltip_text; return _add_button_tooltip; }
            set { add_button.tooltip_text = value; }
        }
        // Use temporary field to avoid breaking API this can be dropped while preparing for 0.4
        string _add_button_tooltip;

        public Tab current {
            get { return tabs.nth_data (notebook.get_current_page ()); }
            set { notebook.set_current_page (tabs.index (value)); }
        }

        GLib.List<Tab> _tabs;
        public GLib.List<Tab> tabs {
            get {
                _tabs = new GLib.List<Tab> ();
                for (var i = 0; i < n_tabs; i++) {
                    _tabs.append (notebook.get_tab_label (notebook.get_nth_page (i)) as Tab);
                }
                return _tabs;
            }
        }

        public string group_name {
            get { return notebook.group_name; }
            set { notebook.group_name = value; }
        }

        public enum TabBarBehavior {
            ALWAYS = 0,
            SINGLE = 1,
            NEVER = 2
        }

        /**
         * The behavior of the tab bar and its visibility
        */
        public TabBarBehavior tab_bar_behavior {
            set {
                _tab_bar_behavior = value;
                update_tabs_visibility ();
            }

            get { return _tab_bar_behavior; }
        }

        private TabBarBehavior _tab_bar_behavior;

        /**
         * The menu appearing when the notebook is clicked on a blank space
         */
        public Gtk.Menu menu { get; private set; }

        private ClosedTabs closed_tabs;

        Gtk.Notebook notebook;

        private int tab_width = 150;
        private const int MAX_TAB_WIDTH = 174;
        private const int TAB_WIDTH_PINNED = 18;

        public signal void tab_added (Tab tab);
        public signal void tab_removed (Tab tab);
        private Tab? old_tab; //stores a reference for tab_switched
        public signal void tab_switched (Tab? old_tab, Tab new_tab);
        public signal void tab_reordered (Tab tab, int new_pos);
        public signal void tab_moved (Tab tab, int x, int y);
        public signal void tab_duplicated (Tab duplicated_tab);
        public signal void tab_restored (string label, string data, GLib.Icon? icon);
        public signal void new_tab_requested ();
        public signal bool close_tab_requested (Tab tab);

        private Gtk.MenuItem new_tab_m;
        private Gtk.MenuItem restore_tab_m;

        private Gtk.Button add_button;
        private Gtk.Button restore_button; // should be a Gtk.MenuButton when we have Gtk+ 3.6

        private const int ADD_BUTTON_PADDING = 5; // Padding around the new tab button

        /**
         * Create a new dynamic notebook
         */
        public DynamicNotebook () {

        }

        construct {
            notebook = new Gtk.Notebook ();
            notebook.can_focus = false;
            visible_window = false;
            get_style_context ().add_class ("dynamic-notebook");

            notebook.scrollable = true;
            notebook.show_border = false;
            _tab_bar_behavior = TabBarBehavior.ALWAYS;

            draw.connect ( (ctx) => {
                get_style_context ().render_activity (ctx, 0, 0, get_allocated_width (), 27);
                return false;
            });

            add (notebook);

            menu = new Gtk.Menu ();
            new_tab_m = new Gtk.MenuItem.with_label (_("New Tab"));
            restore_tab_m = new Gtk.MenuItem.with_label (_("Undo Close Tab"));
            restore_tab_m.sensitive = false;
            menu.append (new_tab_m);
            menu.append (restore_tab_m);
            menu.show_all ();

            new_tab_m.activate.connect (() => {
                new_tab_requested ();
            });

            restore_tab_m.activate.connect (() => {
                restore_last_tab ();
            });

            closed_tabs = new ClosedTabs ();
            closed_tabs.restored.connect ((label, restore_data, icon) => {
                if (!allow_restoring)
                    return;
                restore_button.sensitive = !closed_tabs.empty;
                restore_tab_m.sensitive = !closed_tabs.empty;
                tab_restored (label, restore_data, icon);
            });

            closed_tabs.cleared.connect (() => {
                restore_button.sensitive = false;
                restore_tab_m.sensitive = false;
            });

            add_button = new Gtk.Button.from_icon_name ("list-add-symbolic", Gtk.IconSize.MENU);
            add_button.relief = Gtk.ReliefStyle.NONE;
            add_button.tooltip_text = _("New Tab");

            //FIXME: Used to prevent an issue with widget overlap in Gtk+ < 3.20
            /*
            var add_button_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
            add_button_box.add (add_button);
            add_button_box.show_all ();
            */

            restore_button = new Gtk.Button.from_icon_name ("document-open-recent-symbolic", Gtk.IconSize.MENU);
            restore_button.margin_end = 3;
            restore_button.relief = Gtk.ReliefStyle.NONE;
            restore_button.tooltip_text = _("Closed Tabs");
            restore_button.sensitive = false;
            restore_button.show ();

            notebook.set_action_widget (add_button, Gtk.PackType.START);
            notebook.set_action_widget (restore_button, Gtk.PackType.END);


            add_button.clicked.connect (() => {
                new_tab_requested ();
            });

            add_button.button_press_event.connect ((e) => {
                // Consume double-clicks
                return e.type == Gdk.EventType.2BUTTON_PRESS && e.button == 1;
            });

            restore_button.clicked.connect (() => {
                var menu = closed_tabs.menu;
                menu.attach_widget = restore_button;
                menu.show_all ();
                menu.popup_at_widget (restore_button, Gdk.Gravity.SOUTH_EAST, Gdk.Gravity.NORTH_EAST, null);
            });

            restore_tab_m.visible = allow_restoring;
            restore_button.visible = allow_restoring;

            size_allocate.connect (() => {
                recalc_size ();
            });

            button_press_event.connect ((e) => {
                if (e.type == Gdk.EventType.2BUTTON_PRESS && e.button == 1) {
                    new_tab_requested ();
                } else if (e.button == 2 && allow_restoring) {
                    restore_last_tab ();
                    return true;
                } else if (e.button == 3 && (allow_restoring || add_button_visible)) {
                    menu.popup_at_pointer (e);
                }

                return false;
            });

            key_press_event.connect ((e) => {
                e.state &= MODIFIER_MASK;

                switch (e.keyval) {
                    case Gdk.Key.@w:
                    case Gdk.Key.@W:
                        if (e.state == Gdk.ModifierType.CONTROL_MASK) {
                            if (!tabs_closable) {
                                break;
                            }

                            current.close ();
                            return true;
                        }

                        break;

                    case Gdk.Key.@t:
                    case Gdk.Key.@T:
                        if (e.state == Gdk.ModifierType.CONTROL_MASK) {
                            new_tab_requested ();
                            return true;
                        } else if (e.state == (Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK) && allow_restoring) {
                            restore_last_tab ();
                            return true;
                        }

                        break;

                    case Gdk.Key.Page_Up:
                        if (e.state == Gdk.ModifierType.CONTROL_MASK) {
                            next_page ();
                            return true;
                        }

                        break;

                    case Gdk.Key.Page_Down:
                        if (e.state == Gdk.ModifierType.CONTROL_MASK) {
                            previous_page ();
                            return true;
                        }

                        break;

                    case Gdk.Key.@1:
                    case Gdk.Key.@2:
                    case Gdk.Key.@3:
                    case Gdk.Key.@4:
                    case Gdk.Key.@5:
                    case Gdk.Key.@6:
                    case Gdk.Key.@7:
                    case Gdk.Key.@8:
                        if ((e.state & Gdk.ModifierType.MOD1_MASK) == Gdk.ModifierType.MOD1_MASK) {
                            var i = e.keyval - 49;
                            var n_pages = notebook.get_n_pages ();
                            notebook.page = (int) ((i >= n_pages) ? n_pages - 1 : i);
                            return true;
                        }

                        break;

                    case Gdk.Key.@9:
                        if ((e.state & Gdk.ModifierType.MOD1_MASK) == Gdk.ModifierType.MOD1_MASK) {
                            notebook.page = notebook.get_n_pages () - 1;
                            return true;
                        }

                        break;
                }

                return false;
            });

            destroy.connect (() => {
		        notebook.switch_page.disconnect (on_switch_page);
		        notebook.page_added.disconnect (on_page_added);
		        notebook.page_removed.disconnect (on_page_removed);
		        notebook.page_reordered.disconnect (on_page_reordered);
		        notebook.create_window.disconnect (on_create_window);
            });

            notebook.switch_page.connect (on_switch_page);
            notebook.page_added.connect (on_page_added);
            notebook.page_removed.connect (on_page_removed);
            notebook.page_reordered.connect (on_page_reordered);
            notebook.create_window.connect (on_create_window);
        }

        void on_switch_page (Gtk.Widget page, uint pagenum) {
            var cont = (page as TabPageContainer);
            if( cont == null ) return;

            var new_tab = cont.tab;

            // update property accordingly for previous selected tab
            if (old_tab != null)
                old_tab.is_current_tab = false;

            // now set the new tab as current
            new_tab.is_current_tab = true;

            tab_switched (old_tab, new_tab);

            old_tab = new_tab;
        }

        void on_page_added (Gtk.Widget page, uint pagenum) {
            var cont = page as TabPageContainer;
            if( cont == null ) return;
            var t = cont.tab;

            insert_callbacks (t);
            tab_added (t);
            update_tabs_visibility ();
        }

        void on_page_removed (Gtk.Widget page, uint pagenum) {
            var cont = page as TabPageContainer;
            if( cont == null ) return;
            var t = cont.tab;

            remove_callbacks (t);
            tab_removed (t);
            update_tabs_visibility ();
        }

        void on_page_reordered (Gtk.Widget page, uint pagenum) {
            tab_reordered ((page as TabPageContainer).tab, (int) pagenum);
            recalc_order ();
        }

        unowned Gtk.Notebook on_create_window (Gtk.Widget page, int x, int y) {
            var tab = notebook.get_tab_label (page) as Tab;
            tab_moved (tab, x, y);
            recalc_order ();
            return (Gtk.Notebook) null;
        }

        private void recalc_order () {
            if (n_tabs == 0 || !force_left)
                return;

            var pinned_tabs = 0;
            for (var i = 0; i < this.notebook.get_n_pages (); i++) {
                var tab = this.notebook.get_tab_label (this.notebook.get_nth_page (i)) as Tab;
                if ((tab != null) && tab.pinned) {
                    pinned_tabs++;
                }
            }

            for (var p = 0; p < pinned_tabs; p++) {
                int sel = p;
                for (var i = p; i < this.notebook.get_n_pages (); i++) {
                    var tab = this.notebook.get_tab_label (this.notebook.get_nth_page (i)) as Tab;
                    if ((tab != null) && tab.pinned) {
                        sel = i;
                        break;
                    }
                }

                if (sel != p) {
                    this.notebook.reorder_child (this.notebook.get_nth_page (sel), p);
                }
            }
        }

        private void recalc_size () {
            if (n_tabs == 0)
                return;

            var pinned_tabs = 0;
            var unpinned_tabs = 0;
            for (var i = 0; i < this.notebook.get_n_pages (); i++) {
                if ((this.notebook.get_tab_label (this.notebook.get_nth_page (i)) as Tab).pinned) {
                    pinned_tabs++;
                } else {
                    unpinned_tabs++;
                }
            }

            if (unpinned_tabs == 0) {
                unpinned_tabs = 1;
            }

            var offset = 130;
            this.tab_width = (this.get_allocated_width () - offset - pinned_tabs * TAB_WIDTH_PINNED) / unpinned_tabs;
            if (tab_width > MAX_TAB_WIDTH)
                tab_width = MAX_TAB_WIDTH;

            if (tab_width < 0)
                tab_width = 0;

            for (var i = 0; i < this.notebook.get_n_pages (); i++) {
                this.notebook.get_tab_label (this.notebook.get_nth_page (i)).width_request = tab_width;

                if ((this.notebook.get_tab_label (this.notebook.get_nth_page (i)) as Tab).pinned) {
                    this.notebook.get_tab_label (this.notebook.get_nth_page (i)).width_request = TAB_WIDTH_PINNED;
                }
            }

            // this.notebook.resize_children ();
        }

        private void restore_last_tab () {
            if (!allow_restoring || closed_tabs.empty)
                return;

            var restored = closed_tabs.pop ();
            restore_button.sensitive = !closed_tabs.empty;
            restore_tab_m.sensitive = !closed_tabs.empty;
            this.tab_restored (restored.label, restored.restore_data, restored.icon);
        }

        private void switch_pin_tab (Tab tab) {
            if (!allow_pinning) {
                return;
            }

            recalc_order ();
            recalc_size ();
        }

        public void remove_tab (Tab tab) {
            var pos = get_tab_position (tab);

            if (pos != -1)
                notebook.remove_page (pos);
        }

        public void next_page () {
            this.notebook.page = this.notebook.page + 1 >= this.notebook.get_n_pages () ? this.notebook.page = 0 : this.notebook.page + 1;
        }

        public void previous_page () {
            this.notebook.page = this.notebook.page - 1 < 0 ?
                                 this.notebook.page = this.notebook.get_n_pages () - 1 : this.notebook.page - 1;
        }

        public override void show () {
            base.show ();
            notebook.show ();
        }

        public new List<Gtk.Widget> get_children () {
            var list = new List<Gtk.Widget> ();

            foreach (var child in notebook.get_children ()) {
                var cont = child as Gtk.Container;
                if( cont != null ) {
                    list.append (cont.get_children ().nth_data (0));
                }
            }

            return list;
        }

        public int get_tab_position (Tab tab) {
            return this.notebook.page_num (tab.page_container);
        }

        public void set_tab_position (Tab tab, int position) {
            notebook.reorder_child (tab.page_container, position);
            tab_reordered (tab, position);
            recalc_order ();
        }

        public Tab? get_tab_by_index (int index) {
            return notebook.get_tab_label (notebook.get_nth_page (index)) as Tab;
        }

        public Tab? get_tab_by_widget (Gtk.Widget widget) {
            return notebook.get_tab_label (widget.get_parent ()) as Tab;
        }

        public Gtk.Widget get_nth_page (int index) {
            return notebook.get_nth_page (index);
        }

        public uint insert_tab (Tab tab, int index) {
            return_val_if_fail (tabs.index (tab) < 0, 0);

            var i = 0;
            if (index <= -1)
                i = this.notebook.insert_page (tab.page_container, tab, this.notebook.get_n_pages ());
            else
                i = this.notebook.insert_page (tab.page_container, tab, index);

            this.notebook.set_tab_reorderable (tab.page_container, this.allow_drag);
            this.notebook.set_tab_detachable  (tab.page_container, this.allow_new_window);

            tab.duplicate_m.visible = allow_duplication;
            tab.new_window_m.visible = allow_new_window;
            tab.pin_m.visible = allow_pinning;
            tab.pinnable = allow_pinning;
            tab.pinned = false;

            tab.width_request = tab_width;
            this.recalc_size ();
            this.recalc_order ();

            if (!tabs_closable)
                tab.closable = false;

            return i;
        }

        private void insert_callbacks (Tab tab) {
            tab.closed.connect (on_tab_closed);
            tab.close_others.connect (on_close_others);
            tab.new_window.connect (on_new_window);
            tab.duplicate.connect (on_duplicate);
            tab.pin_switch.connect (on_pin_switch);
        }

        private void remove_callbacks (Tab tab) {
            tab.closed.disconnect (on_tab_closed);
            tab.close_others.disconnect (on_close_others);
            tab.new_window.disconnect (on_new_window);
            tab.duplicate.disconnect (on_duplicate);
            tab.pin_switch.disconnect (on_pin_switch);
        }

        private void on_tab_closed (Tab tab) {
            if (Signal.has_handler_pending (this, Signal.lookup ("close-tab-requested", typeof (DynamicNotebook)), 0, true)) {
                var sure = close_tab_requested (tab);

                if (!sure)
                    return;
            }

            var pos = get_tab_position (tab);

            remove_tab (tab);

            if (pos != -1 && tab.page.get_parent () != null)
                tab.page.unparent ();

            if (tab.label != "" && tab.restore_data != "") {
                closed_tabs.push (tab);
                restore_button.sensitive = !closed_tabs.empty;
                restore_tab_m.sensitive = !closed_tabs.empty;
            }
        }

        private void on_close_others (Tab tab) {
            var num = 0; //save num, in case a tab refused to close so we don't end up in an infinite loop

            for (var j = 0; j < tabs.length (); j++) {
                if (tab != tabs.nth_data (j)) {
                    tabs.nth_data (j).closed ();
                    if (num == n_tabs) break;
                    j--;
                }

                num = n_tabs;
            }
        }

        private void on_new_window (Tab tab) {
            notebook.create_window (tab.page_container, 0, 0);
        }

        private void on_duplicate (Tab tab) {
            tab_duplicated (tab);
        }

        private void on_pin_switch (Tab tab) {
            switch_pin_tab (tab);
        }

        private void update_tabs_visibility () {
            if (_tab_bar_behavior == TabBarBehavior.SINGLE)
                notebook.show_tabs = n_tabs > 1;
            else if (_tab_bar_behavior == TabBarBehavior.NEVER)
                notebook.show_tabs = false;
            else if (_tab_bar_behavior == TabBarBehavior.ALWAYS)
                notebook.show_tabs = true;
        }
    }
