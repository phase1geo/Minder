/*
* Copyright (c) 2020 (https://github.com/Messius58/Minder)
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
* Authored by: Branciat Jérôme
*/

using Gtk;
using GLib;
using Granite.Widgets;

public class FileInspector : Box {
    
    private Gtk.TreeView    _view;
    private TreeStore       _tree;
    private string          files_path = "";
    private ScrolledWindow  _sw;
    public MainWindow      _win;

    public string directory {
        get {
            return files_path;
        }
        set {
            files_path = value;
        }
    }

    public FileInspector( MainWindow win, GLib.Settings settings ) {
        Object( orientation:Orientation.VERTICAL, spacing:10 );
        _win = win;
        _view  = new TreeView();
        _sw = new ScrolledWindow( null, null );
        _sw.min_content_width  = 300;
        _sw.min_content_height = 100;
        _sw.add( _view );
        pack_start( _sw,  true,  true );
        directory = "/tmp/minder";

        init_tree();
        pack_start(_view);

        show_all();
    }

    private void init_tree() {
        _tree = new TreeStore(1, typeof(string));
        _view.set_model(_tree);
        _view.insert_column_with_attributes(-1,_("Files"), new CellRendererText(), "text", 0, null);
        _view.activate_on_single_click = true;
        _view.headers_visible = true;
        _view.enable_search = true;
        _view.row_activated.connect( on_row_activated );
        TreeIter root;
        _tree.append(out root, null);
        _tree.set(root, 0, directory, -1);
        load_files(null, directory);
    }

    private void load_files( TreeIter? root, string dir_name ) {
        try {
            GLib.Dir dir = GLib.Dir.open(dir_name);
            string? name = null;
            TreeIter child_folder;

            while ((name = dir.read_name ()) != null) {
                string path = Path.build_filename (dir_name, name);
                if (FileUtils.test (path, FileTest.IS_REGULAR)) {
                    _tree.append(out child_folder, root);
                    _tree.set(child_folder, 0, name, -1);
                }
    
                if (FileUtils.test (path, FileTest.IS_DIR)) {
                    _tree.prepend(out child_folder, root);
                    _tree.set(child_folder, 0, name, -1);
                    load_files(child_folder, path);
                }
            }            
        } catch (GLib.FileError fe) {
            printerr("FileInspector Load files : " + fe.message);
        }
    }

    private void on_row_activated( TreePath path, TreeViewColumn col ) {
        TreeIter iter;
        TreeIter parent;
        string select_name = "";
        string concat = "";
        _tree.get_iter(out iter, path);
        _tree.get(iter, 0, &concat);
        while (_tree.iter_parent(out parent, iter)) {
            _tree.get(parent, 0, &select_name);
             concat = Path.build_filename(select_name, concat);
            iter = parent;
        };
        concat = directory + GLib.Path.DIR_SEPARATOR.to_string() + concat;
        if (FileUtils.test (concat, FileTest.IS_REGULAR)) {
            _win.open_file(concat);
        }
    }
}