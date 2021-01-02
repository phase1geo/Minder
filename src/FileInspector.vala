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
using Gee;
using Granite.Widgets;

public class NodeData {
    public string id;
    public string pathfile;
    public string node_text;
    public string node_note;
}

public class FileData {
    public string id;
    public string name;
    public string path;
    public bool loaded;
    public bool showed;// In the actual context not useful maybe latter.
}

public class FileInspector : Box {
    
    private Gtk.TreeView                _view;
    private TreeStore                   _tree;
    private string                      default_path = "";
    private ScrolledWindow              _sw;
    public  MainWindow                  _win;
    private HashTable<string, FileData> _files;
    private string                      _cur_selected;

    public string directory {
        get {
            return default_path;
        }
        set {
            default_path = value;
        }
    }

    public FileInspector( MainWindow win, GLib.Settings settings ) {
        Object( orientation:Orientation.VERTICAL, spacing:10 );
        _win = win;
        _win.file_loaded.connect(file_loaded);
        _win.tab_event.connect(highlight_tree);
        directory = settings.get_string( "last-directory" );
        _files = new HashTable<string, FileData>(str_hash, str_equal);

        init_tree();

        show_all();
    }

    private void init_tree() {
        _tree = new TreeStore(2, typeof(string), typeof(string));
        _view  = new TreeView();
        _sw = new ScrolledWindow( null, null );
        _sw.min_content_width  = 300;
        _sw.min_content_height = 100;
        _sw.add( _view );
        pack_start( _sw,  true,  true );

        Gtk.TreeViewColumn col  = new Gtk.TreeViewColumn();
        CellRendererText renderer = new CellRendererText();
        renderer.set_property("foreground-set",true);
        col.pack_start (renderer, true);
        col.set_title(_("Files"));
        col.add_attribute(renderer, "text", 0);
        col.add_attribute(renderer, "foreground", 1);
//        col.set_clickable(true);
//        col.set_sort_indicator(true);
        col.set_sort_column_id(0);
        
        _view.set_model(_tree);
        _view.append_column(col);
        _view.activate_on_single_click = true;
        _view.headers_visible = true;
        _view.enable_search = true;
        _view.row_activated.connect( on_row_activated );

        load_files(null, directory);
    }

    private void load_files( TreeIter? root, string dir_name ) {
        try {
            GLib.Dir dir = GLib.Dir.open(dir_name);
            string? name = null;
            TreeIter child_folder;

            while ((name = dir.read_name ()) != null) {
                string path = Path.build_filename (dir_name, name);
                if (FileUtils.test (path, FileTest.IS_REGULAR) && name.has_suffix(".minder")) {
                    _tree.append(out child_folder, root);
                    _tree.set(child_folder, 0, name, -1);
                    FileData ft = new FileData();
                    ft.name = name;
                    ft.path = dir_name;
                    ft.id = _tree.get_string_from_iter(child_folder);
                    ft.showed = false;
                    ft.loaded = false;
                    _files.insert(name, ft);
                }
    
               /*if (FileUtils.test (path, FileTest.IS_DIR)) {
                    _tree.prepend(out child_folder, root);
                    _tree.set(child_folder, 0, name, -1);
                    load_files(child_folder, Path.build_filename (path, name));
                }*/
            }            
        } catch (GLib.FileError fe) {
            printerr("FileInspector Load files : " + fe.message);
        }
    }

    private void on_row_activated( TreePath path, TreeViewColumn col ) {
        TreeIter iter;
        string select_name = "";
        _tree.get_iter(out iter, path);
        _tree.get(iter, 0, &select_name);
        if(select_name != null) {
            FileData ft = _files.get(select_name);
            if(!ft.loaded) {
                string complete_name = Path.build_filename(ft.path, ft.name);
                _win.open_file(complete_name);
            }else{
                _win.action_change_tab(select_name);
            }
        }
    }

    public GLib.List<NodeData> search(string pattern) {
        try {
            GLib.List<NodeData> list = new GLib.List<NodeData>();
            foreach (var file in _files.get_values()) {
                string complete_name = Path.build_filename(file.path, file.name);
                Xml.Doc* doc = Xml.Parser.parse_file( complete_name );
                if (doc != null) {
                    Xml.XPath.Context cntx = new Xml.XPath.Context(doc);
                    Xml.XPath.Object* res  = cntx.eval_expression("//node[@id]");
                    for (int i = 0; i < res->nodesetval->length (); i++) {
                        Xml.Node* node = res->nodesetval->item (i);
                        string id = node->get_prop("id");
                        string text = "";
                        string note = "";
                        for( Xml.Node* node_child = node->children; node_child != null; node_child = node_child->next ) {
                            if(node_child->name == "nodename") {
                                text = Utils.match_string(pattern, node_child->first_element_child()->get_prop("data"));
                            }
                            if(node_child->name == "nodenote") {
                                note = Utils.match_string(pattern, node_child->get_content());
                            }
                        }
                        if(text != "" || note != "") {
                            list.append(new NodeData() {
                                id        = id,
                                pathfile  = complete_name,
                                node_text = text,
                                node_note = note
                            });
                        }
                        //print ("%s\n", node->get_prop("data"));
                    }
                    delete res;
                    delete doc;        
                }
            }
            return list;
        }catch (Error e) {
            printerr("error in function search / inspector" + e.message);
        }
    }

  /* Grabs input focus on the first UI element */
  public void grab_first() {
    _view.grab_focus();
  }

  /* On file loaded : */
  private void file_loaded(string fname) {
      highlight_tree(fname, TabReason.LOAD);
  }

  public bool file_is_loading(string pathfile) {
      string filename = Path.get_basename(pathfile);
      if(_files.contains(filename)) {
          return _files.get(filename).loaded;
      }
      return false;
  }

  /* 
  on tab event : update the text color of the file in the treebox 
  TODO on treeview sort recreate the file index list.
  */
  private void highlight_tree(string fname, TabReason reason) {
    string basename = Path.get_basename(fname);
    if(_files.contains(basename)) {
        TreeIter it;
        FileData ft = _files.get(basename);
        TreeViewColumn col = _view.get_column(0);
        _tree.get_iter_from_string(out it, ft.id);
        switch (reason) {
            case TabReason.LOAD:
            case TabReason.SHOW:
                ft.loaded = true;
                ft.showed = true;
                _tree.set_value(it, 1, "#ff5733");
                if(ft.id != _cur_selected) {
                    _cur_selected = ft.id;
                    _view.set_cursor(_tree.get_path(it), col, true);
                }
            break;
            case TabReason.CLOSE:
                ft.loaded = false;
                ft.showed = false;
                _tree.set_value(it, 1, "#FFFFFF");
            break;
            default:
            break;
        }
    }
  }
}