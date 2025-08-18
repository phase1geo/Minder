/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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

using GLib;
using Gdk;
using Gee;

public class ExportXMind2021 : Export {

  private int ids = 10000000;

  public enum IdObjectType {
    NODE = 0,
    CONNECTION,
    BOUNDARY
  }

  public class IdObject {
    public IdObjectType typ   { get; set; default = IdObjectType.NODE; }
    public Node?        node  { get; set; default = null; }
    public Connection?  conn  { get; set; default = null; }
    public NodeGroup?   group { get; set; default = null; }
    public IdObject.for_node( Node n ) {
      typ  = IdObjectType.NODE;
      node = n;
    }
    public IdObject.for_connection( Connection c ) {
      typ  = IdObjectType.CONNECTION;
      conn = c;
    }
    public IdObject.for_boundary( NodeGroup g ) {
      typ   = IdObjectType.BOUNDARY;
      group = g;
    }
  }

  public class FileItem {
    public string name;
    public string type;
    public FileItem( string n, string t ) {
      name = n;
      type = t;
    }
  }

  public class FileItems {
    public Array<FileItem> items;
    public FileItems() {
      items = new Array<FileItem>();
    }
    public void add( string name, string type ) {
      for( int i=0; i<items.length; i++ ) {
        if( items.index( i ).name == name ) return;
      }
      items.append_val( new FileItem( name, type ) );
    }
  }

  /* Constructor */
  public ExportXMind2021() {
    base( "xmind-2021", _( "XMind 2021" ), { ".xmind" }, false, true, false, false );
  }

  /* Exports the given drawing area to the file of the given name */
  public override bool export( string fname, MindMap map ) {

    /* Create temporary directory to place contents in */
    var dir = DirUtils.mkdtemp( "minderXXXXXX" );

    var file_list = new FileItems();

    /* Export the meta file */
    export_meta( map, dir, file_list );

    /* Export the content file */
    export_content( map, dir, file_list );

    /* Export manifest file */
    export_manifest( dir, file_list );

    /* Archive the contents */
    archive_contents( dir, fname, file_list );

    return( true );

  }

  /* Generates the manifest file */
  private bool export_manifest( string dir, FileItems file_list ) {

    var root    = new Json.Node( Json.NodeType.OBJECT );
    var top     = new Json.Object();
    var entries = new Json.Object();

    root.set_object( top );
    top.set_object_member( "file-entries", entries );

    for( int i=0; i<file_list.items.length; i++ ) {
      var obj = new Json.Object();
      entries.set_object_member( file_list.items.index( i ).name, obj );
    }

    var generator = new Json.Generator();
    generator.root   = root;
    generator.pretty = true;

    try {
      generator.to_file( Path.build_filename( dir, "manifest.json" ) );
    } catch( GLib.Error e ) {
      return( false );
    }

    file_list.add( "manifest.json", "text/json" );

    return( true );

  }

  /* Generate the main content file from  */
  private bool export_content( MindMap map, string dir, FileItems file_list ) {

    var root  = new Json.Node( Json.NodeType.ARRAY );
    var top   = new Json.Array();
    var sheet = new Json.Object();

    root.set_array( top );

    sheet.set_string_member( "class", "sheet" );
    sheet.set_string_member( "title", "Map" );
    sheet.set_object_member( "rootTopic", export_node( map, map.get_nodes().index( 0 ), true, dir, file_list ) );
    sheet.set_object_member( "theme", export_theme( map ) );
    sheet.set_array_member( "extensions", export_extensions( map ) );
    sheet.set_string_member( "topicPositioning", "fixed" );
    sheet.set_array_member( "relationships", export_relationships( map ) );
    // sheet.set_member( "style", export_style( map ) );

    top.add_object_element( sheet );

    var generator = new Json.Generator();
    generator.root   = root;
    generator.pretty = true;

    try {
      generator.to_file( Path.build_filename( dir, "content.json" ) );
    } catch( GLib.Error e ) {
      return( false );
    }

    file_list.add( "content.json", "text/json" );

    return( true );

  }

  private Json.Object export_node( MindMap map, Node node, bool top, string dir, FileItems file_list ) {

    var topic  = new Json.Object();
    var groups = new Array<int>();

    topic.set_string_member( "class", "topic" );
    topic.set_string_member( "title", node.name.text.text );
    topic.set_boolean_member( "titleUnedited", false );

    if( top ) {
      topic.set_string_member( "structureClass", "org.xmind.ui.map.unbalanced" );
    }

    /* Add note, if needed */
    if( node.note != "" ) {
      topic.set_object_member( "notes", export_node_note( node ) );
    }

    if( node.image != null ) {
      var image = export_node_image( map, node, dir, file_list );
      if( image != null ) {
        topic.set_object_member( "image", image );
      }
    }

    if( node.children().length > 0 ) {

      var attached = new Json.Array();

      for( int i=0; i<node.children().length; i++ ) {
        var child = node.children().index( i );
        attached.add_object_element( export_node( map, child, false, dir, file_list ) );
        if( child.group ) {
          groups.append_val( i );
        }
      }

      topic.set_array_member( "children", attached );

    }

    /* Add boundaries, if found */
    if( groups.length > 0 ) {

      var boundaries = new Json.Array();

      for( int i=0; i<groups.length; i++ ) {

        var boundary = new Json.Object();

        /* Create boundary */
        boundary.set_string_member( "range", "(%d,%d)".printf( groups.index( i ), groups.index( i ) ) );
        boundary.set_string_member( "title", "" );
        boundary.set_boolean_member( "titleUnedited", true );

        boundaries.add_object_element( boundary );

      }

      topic.set_array_member( "boundaries", boundaries );

    }

    return( topic );

  }

  /* Exports the given node's image */
  private Json.Object? export_node_image( MindMap map, Node node, string dir, FileItems file_list ) {

    var image     = new Json.Object();
    var img_name  = map.image_manager.get_file( node.image.id );
    var mime_type = map.image_manager.get_mime_type( node.image.id );
    var src       = Path.build_filename( "resources", Filename.display_basename( img_name ) );
    var parts     = src.split( "." );

    /* Copy the image file to the XMind bundle */
    DirUtils.create( Path.build_filename( dir, "resources" ), 0755 );
    var lfile = File.new_for_path( Path.build_filename( dir, src ) );
    var rfile = File.new_for_path( img_name );
    try {
      rfile.copy( lfile, FileCopyFlags.OVERWRITE );
    } catch( GLib.Error e ) {
      return( null );
    }

    image.set_string_member( "src", "xap:%s".printf( src ) );
    /*
    image.set_int_member( "svg:height", (int)node.image.height );
    image.set_int_member( "svg:width",  (int)node.image.width );
    */

    file_list.add( "resources", "" );
    file_list.add( src, mime_type );

    return( image );

  }

  /* Exports a node note */
  private Json.Object export_node_note( Node node ) {

    var note = new Json.Object();

    note.set_string_member( "realHTML", Utils.markdown_to_html( node.note, "html" ) );
    note.set_string_member( "plain", node.note );

    return( note );

  }

  private Json.Object export_node_content_note( string str ) {
    var content = new Json.Object();
    content.set_string_member( "content", str );
    return( content );
  }

  private Json.Object export_theme( MindMap map ) {

    var theme = new Json.Object();

    theme.set_object_member( "centralTopic", export_node_style( 0 ) );
    theme.set_object_member( "mainTopic",    export_node_style( 1 ) );
    theme.set_object_member( "subTopic",     export_node_style( 2 ) );
    theme.set_object_member( "boundary",     export_boundary_style( map ) );
    theme.set_object_member( "relationship", export_relationship_style( map ) );
    theme.set_object_member( "map",          export_map_style( map ) );

    return( theme );

  }

  /* Exports node styling information */
  private Json.Object export_node_style( int level ) {

    var style = StyleInspector.styles.get_style_for_level( level, null );
    var topic = new Json.Object();
    var props = new Json.Object();

    topic.set_object_member( "properties", props );

    /* Node border shape */
    switch( style.node_border.name() ) {
      case "rounded"    :  props.set_string_member( "shape-class", "org.xmind.topicShape.roundedRect" );  break;
      case "underlined" :  props.set_string_member( "shape-class", "org.xmind.topicShape.underline" );    break;
      default           :  props.set_string_member( "shape-class", "org.xmind.topicShape.rect" );         break;
    }

    props.set_string_member( "border-line-width", "%dpt".printf( style.node_borderwidth ) );
    props.set_string_member( "line-width",        "%dpt".printf( style.link_width ) );

    if( style.node_fill ) {
      props.set_string_member( "svg:fill", "#888888" );
    }

    switch( style.link_type.name() ) {
      case "curved"   :  props.set_string_member( "line-class", "org.xmind.branchConnection.%s".printf( style.link_arrow ? "arrowedCurve" : "curve" ) );  break;
      case "straight" :  props.set_string_member( "line-class", "org.xmind.branchConnection.straight" );      break;
      case "squared"  :  props.set_string_member( "line-class", "org.xmind.branchConnection.elbow" );         break;
      case "rounded"  :  props.set_string_member( "line-class", "org.xmind.branchConnection.roundedElbow" );  break;
    }

    return( topic );

  }

  private Json.Object export_boundary_style( MindMap map ) {

    var theme = map.get_theme();
    var node  = new Json.Object();
    var props = new Json.Object();

    node.set_object_member( "properties", props );

    props.set_string_member( "shape-class", "org.xmind.boundaryShape.roundedRect" );
    props.set_int_member( "line-width", 2 );
    props.set_string_member( "line-pattern", "dash" );
    props.set_string_member( "svg:fill",   "#00897B" );
    props.set_string_member( "line-color", "#00897B" );
    props.set_string_member( "fo:color",   "#ffffff" );

    return( node );

  }

  private Json.Object export_relationship_style( MindMap map ) {

    var theme = map.get_theme();
    var style = StyleInspector.styles.get_global_style();
    var node  = new Json.Object();
    var props = new Json.Object();

    node.set_object_member( "properties", props );

    props.set_string_member( "shape-class", "org.xmind.relationshipShape.curved" );
    props.set_int_member( "line-width", style.connection_line_width );
    props.set_string_member( "arrow-begin-class", "org.xmind.arrowShape.none" );
    props.set_string_member( "arrow-end-class",   "org.xmind.arrowShape.triangle" );

    if( style.connection_dash.name == "solid" ) {
      props.set_string_member( "line-pattern", "solid" );
    } else {
      props.set_string_member( "line-pattern", "dash" );
    }

    props.set_string_member( "fo:text-align", "center" );
    props.set_string_member( "fo:font-family", "'%s',sans-serif".printf( style.connection_font.get_family() ) );
    props.set_string_member( "fo:font-size",   "%dpt".printf( style.connection_font.get_size() ) );
    props.set_string_member( "line-color",     Utils.color_from_rgba( theme.get_color( "connection_background" ) ) );
    props.set_string_member( "fo:color",       Utils.color_from_rgba( theme.get_color( "connection_foreground" ) ) );

    return( node );

  }

  private Json.Object export_map_style( MindMap map ) {

    var theme = map.get_theme();
    var node  = new Json.Object();
    var props = new Json.Object();

    node.set_object_member( "properties", props );

    props.set_string_member( "line-tapered", "none" );
    props.set_string_member( "svg:fill", Utils.color_from_rgba( theme.get_color( "background" ) ) );
    props.set_string_member( "multi-line-colors", "" );  // TBD

    return( node );

  }

  private Json.Array export_extensions( MindMap map ) {

    var root    = map.get_nodes().index( 0 );
    var layout  = root.layout;
    var exts    = new Json.Array();
    var node    = new Json.Object();
    var content = new Json.Object();
    var side    = "right";

    exts.add_object_element( node );

    node.set_string_member( "provider", "org.xmind.ui.skeleton.structure.style" );
    node.set_object_member( "content", content );

    content.set_string_member( "centralTopic", (layout.balanceable ? "org.xmind.ui.map.balanced" :
                                                                     "org.xmind.ui.map_unbalanced") );

    if( root.children().length > 0 ) {
      side = root.children().index( 0 ).side.to_string();
    }
    content.set_string_member( "mainTopic", "org.xmind.ui.logic.%s".printf( side ) );

    return( exts );

  }

  private Json.Array export_relationships( MindMap map ) {

    var rels  = new Json.Array();
    var conns = map.connections.connections;

    for( int i=0; i<conns.length; i++ ) {

      var node     = new Json.Object();
      var conn     = conns.index( i );
      var conn_id  = ids++;
      var style_id = ids++;
      var color    = (conn.color == null) ? map.get_theme().get_color( "connection_background" ) : conn.color;
      var dash     = "dash";

      node.set_string_member( "id", conn_id.to_string() );
      node.set_string_member( "end1", conn.from_node.id().to_string() );
      node.set_string_member( "end2", conn.to_node.id().to_string() );

      if( conn.title != null ) {
        node.set_string_member( "title", conn.title.text.text );
      }

      /* Create style */
      /*
      Xml.Node* style = new Xml.Node( null, "style" );
      Xml.Node* props = new Xml.Node( null, "relationship-properties" );
      var from_arrow = (conn.style.connection_arrow == "tofrom") || (conn.style.connection_arrow == "both");
      var to_arrow   = (conn.style.connection_arrow == "fromto") || (conn.style.connection_arrow == "both");
      props->set_prop( "arrow-begin-class", "org.xmind.arrowShape.%s".printf( from_arrow ? "triangle" : "none" ) );
      props->set_prop( "arrow-end-class",   "org.xmind.arrowShape.%s".printf( to_arrow   ? "triangle" : "none" ) );
      props->set_prop( "line-color", Utils.color_from_rgba( color ) );
      props->set_prop( "line-pattern", dash );
      props->set_prop( "line-width", "%dpt".printf( conn.style.connection_line_width ) );
      props->set_prop( "shape-class", "org.xmind.relationshipShape.curved" );
      style->add_child( props );
      styles.append_val( style );
      */

      rels.add_object_element( node );

    }

    return( rels );

  }

  /* Exports the contents of the meta file */
  private bool export_meta( MindMap map, string dir, FileItems file_list ) {

    var root    = new Json.Node( Json.NodeType.OBJECT );
    var top     = new Json.Object();
    var creator = new Json.Object();

    root.set_object( top );

    top.set_object_member( "creator", creator );

    creator.set_string_member( "name", "Minder" );
    creator.set_string_member( "version", Minder.version );

    var generator = new Json.Generator();
    generator.root   = root;
    generator.pretty = true;

    try {
      generator.to_file( Path.build_filename( dir, "metadata.json" ) );
    } catch( GLib.Error e ) {
      return( false );
    }

    file_list.add( "metadata.json", "text/json" );

    return( true );

  }

  /* Write the contents as a zip file */
  private void archive_contents( string dir, string outname, FileItems files ) {

    GLib.File pwd = GLib.File.new_for_path( dir );

    // Create the tar.gz archive named according the the first argument.
    Archive.Write archive = new Archive.Write();
    archive.add_filter_none();
    archive.set_format_zip();
    archive.open_filename( outname );

    // Add all the other arguments into the archive
    for( int i=0; i<files.items.length; i++ ) {
      if( files.items.index( i ).type == "" ) continue;
      GLib.File file = GLib.File.new_for_path( Path.build_filename( dir, files.items.index( i ).name ) );
      try {
        GLib.FileInfo file_info = file.query_info( GLib.FileAttribute.STANDARD_SIZE, GLib.FileQueryInfoFlags.NONE );
        FileInputStream input_stream = file.read();
        DataInputStream data_input_stream = new DataInputStream( input_stream );

        // Add an entry to the archive
        Archive.Entry entry = new Archive.Entry();
        entry.set_pathname( pwd.get_relative_path( file ) );
        entry.set_size( (Archive.int64_t)file_info.get_size() );
        entry.set_filetype( Archive.FileType.IFREG );
        entry.set_perm( (Archive.FileMode)0644 );
        if( archive.write_header( entry ) != Archive.Result.OK ) {
          critical( "Error writing '%s': %s (%d)", file.get_path(), archive.error_string(), archive.errno() );
          continue;
        }

        // Add the actual content of the file
        size_t bytes_read;
        uint8[] buffer = new uint8[64];
        while( data_input_stream.read_all( buffer, out bytes_read ) ) {
          if( bytes_read <= 0 ) {
            break;
          }
          archive.write_data( buffer );
        }
      } catch( GLib.Error e ) {
        critical( e.message );
      }
    }

    if( archive.close() != Archive.Result.OK ) {
      error( "Error : %s (%d)", archive.error_string(), archive.errno() );
    }

  }

  // --------------------------------------------------------------------------------------

  /* Main method used to import an XMind mind-map into Minder */
  public override bool import( string fname, MindMap map ) {

    stdout.printf( "In XMind 2021 import\n" );

    /* Create temporary directory to place contents in */
    var dir = DirUtils.mkdtemp( "minderXXXXXX" );

    stdout.printf( "In XMind2021 import, dir: %s\n", dir );

    /* Unarchive the files */
    unarchive_contents( fname, dir );

    stdout.printf( "After unarchiving contents, dir: %s\n", dir );

    var content = Path.build_filename( dir, "content.json" );
    var id_map  = new HashMap<string,IdObject>();

    if( !FileUtils.test( content, FileTest.EXISTS ) ) {
      return( false );
    }

    import_content( map, content, dir, id_map );

    /* Update the drawing area and save the result */
    map.queue_draw();
    map.auto_save();

    return( true );

  }

  private bool import_content( MindMap map, string fname, string dir, HashMap<string,IdObject> id_map ) {

    var parser = new Json.Parser();

    /* Read in the contents of the XMind 2021 file */
    try {
      parser.load_from_file( fname );
    } catch( GLib.Error e ) {
      return( false );
    }

    import_map( map, parser.get_root(), dir, id_map );

    return( true );

  }

  private string get_json_string( unowned Json.Object obj, string prop ) {
    unowned var node = obj.get_member( prop );
    if( (node != null) && (node.get_node_type() == Json.NodeType.VALUE) ) {
      return( node.get_string() );
    }
    return( "" );
  }

  private unowned Json.Object? get_json_object( unowned Json.Object obj, string prop ) {
    unowned var node = obj.get_member( prop );
    if( (node != null) && (node.get_node_type() == Json.NodeType.OBJECT) ) {
      return( node.get_object() );
    }
    return( null );
  }

  private unowned Json.Array? get_json_array( unowned Json.Object obj, string prop ) {
    unowned var node = obj.get_member( prop );
    if( (node != null) && (node.get_node_type() == Json.NodeType.ARRAY) ) {
      return( node.get_array() );
    }
    return( null );
  }

  private void import_map( MindMap map, Json.Node n, string dir, HashMap<string,IdObject> id_map ) {
    if( n.get_node_type() == Json.NodeType.ARRAY ) {
      foreach( unowned Json.Node node in n.get_array().get_elements() ) {
        unowned var obj = node.get_object();
        if( get_json_string( obj, "class" ) == "sheet" ) {
          import_sheet( map, obj, dir, id_map );
        }
      }
    }
  }

  /* Import a sheet */
  private void import_sheet( MindMap map, Json.Object obj, string dir, HashMap<string,IdObject> id_map ) {

    unowned var theme = get_json_object( obj, "theme" );
    unowned var root  = get_json_object( obj, "rootTopic" );
    unowned var rels  = get_json_array( obj, "relationships" );

    if( theme != null ) {
      import_theme( map, theme, id_map );
    }

    if( root != null ) {
      import_topic( map, null, root, false, dir, id_map );
    }

    if( rels != null ) {
      import_relationships( map, rels, id_map );
    }

  }

  private void import_topic( MindMap map, Node? parent, Json.Object obj, bool attached, string dir, HashMap<string,IdObject> id_map ) {

    Node node;

    var sclass = get_json_string( obj, "structureClass" );
    if( sclass != "" ) {
      node = map.model.create_root_node();
      if( sclass == "org.xmind.ui.map.unbalanced" ) {
        node.layout = map.layouts.get_layout( _( "Horizontal" ) );
      } else {
        node.layout = map.layouts.get_layout( _( "To right" ) );
      }
    } else if( !attached ) {
      node = map.model.create_root_node();
    } else {
      node = map.model.create_child_node( parent );
    }

    /* Handle the ID */
    var id = get_json_string( obj, "id" );
    if( id != "" ) {
      id_map.set( id, new IdObject.for_node( node ) );
    }

    var sid = get_json_string( obj, "styleId" );
    if( sid != "" ) {
      id_map.set( sid, new IdObject.for_node( node ) );
    }

    var title = get_json_string( obj, "title" );
    if( title != "" ) {
      node.name.text.insert_text( 0, title );
    }

    unowned var notes = get_json_object( obj, "notes" );
    if( notes != null ) {
      import_node_notes( node, notes );
    }

    var href = get_json_string( obj, "href" );
    if( href != "" ) {
      if( node.note != "" ) {
        node.note += "\n";
      }
      node.note += href;
    }

    unowned var img = get_json_object( obj, "image" );
    if( img != null ) {
      import_image( map, node, img, dir, id_map );
    }

    unowned var children = get_json_object( obj, "children" );
    if( children != null ) {
      import_children( map, node, children, dir, id_map );
    }

    unowned var bound = get_json_array( obj, "boundaries" );
    if( bound != null ) {
      import_boundaries( map, node, bound, id_map );
    }

  }

  private void import_node_notes( Node node, unowned Json.Object obj ) {
    unowned var plain = get_json_object( obj, "plain" );
    if( plain != null ) {
      node.note = get_json_string( plain, "content" );
    }
  }

  private void import_image( MindMap map, Node node, unowned Json.Object obj, string dir, HashMap<string,IdObject> id_map ) {

    int height = 100;
    int width  = 100;

    var sid = get_json_string( obj, "styleId" );
    if( sid != null ) {
      // TBD - We need to associate styles to things that are not just nodes
    }

    var h = get_json_string( obj, "height" );
    if( h != "" ) {
      height = int.parse( h );
    }

    var w = get_json_string( obj, "width" );
    if( w != "" ) {
      width = int.parse( w );
    }

    var src = get_json_string( obj, "src" );
    if( src != "" ) {
      var img_file = File.new_for_path( Path.build_filename( dir, src.substring( 4 ) ) );
      node.set_image( map.image_manager, new NodeImage.from_uri( map.image_manager, img_file.get_uri(), width ) );
    }

  }

  private void import_children( MindMap map, Node node, unowned Json.Object obj, string dir, HashMap<string,IdObject> id_map ) {
    unowned var attached = get_json_array( obj, "attached" );
    if( attached != null ) {
      foreach( unowned Json.Node n in attached.get_elements() ) {
        unowned var o = n.get_object();
        import_topic( map, node, o, true, dir, id_map );
      }
    }
  }

  private void import_boundaries( MindMap map, Node node, unowned Json.Array arr, HashMap<string,IdObject> id_map ) {
    foreach( unowned Json.Node n in arr.get_elements() ) {
      unowned var obj = n.get_object();
      var sid = get_json_string( obj, "styleId" );
      var r   = get_json_string( obj, "range" );
      if( r != "" ) {
        int start = -1;
        int end   = -1;
        if( r.scanf( "(%d,%d)", &start, &end ) == 2 ) {
          var nodes = new Array<Node>();
          for( int i=start; i<=end; i++ ) {
            var child = node.children().index( i );
            nodes.append_val( child );
          }
          var group = new NodeGroup.array( map, nodes );
          map.groups.add_group( group );
          if( sid != null ) {
            id_map.set( sid, new IdObject.for_boundary( group ) );
          }
        }
      }
    }
  }

  private void import_relationships( MindMap map, unowned Json.Array arr, HashMap<string,IdObject> id_map ) {

    foreach( unowned Json.Node node in arr.get_elements() ) {

      unowned var o = node.get_object();

      Node? from_node = null;
      Node? to_node   = null;

      var sid   = get_json_string( o, "styleId" );
      var sp    = get_json_string( o, "end1Id" );
      var ep    = get_json_string( o, "end2Id" );
      var title = get_json_string( o, "title" );
      if( sp != "" ) {
        var obj = id_map.get( sp );
        if( obj.typ == IdObjectType.NODE ) {
          from_node = obj.node;
        }
      }
      if( ep != "" ) {
        var obj = id_map.get( ep );
        if( obj.typ == IdObjectType.NODE ) {
          to_node = obj.node;
        }
      }
      if( (from_node != null) && (to_node != null) ) {

        var conn = new Connection( map, from_node );
        conn.change_title( map, title );
        conn.connect_to( to_node );
        map.connections.add_connection( conn );

        if( sid != null ) {
          id_map.set( sid, new IdObject.for_connection( conn ) );
        }

      }

    }

  }

  private void import_theme( MindMap map, unowned Json.Object obj, HashMap<string,IdObject> id_map ) {

    unowned var root     = get_json_object( obj, "centralTopic" );
    unowned var main     = get_json_object( obj, "mainTopic" );
    unowned var sub      = get_json_object( obj, "subTopic" );
    unowned var boundary = get_json_object( obj, "boundary" );
    unowned var rel      = get_json_object( obj, "relationship" );

    if( root != null ) {
      import_theme_node( map, root, 0, id_map );
    }

    if( main != null ) {
      import_theme_node( map, main, 1, id_map );
    }

    if( sub != null ) {
      import_theme_node( map, sub, 10, id_map );
    }

    if( boundary != null ) {
      // import_theme_boundary_json( map, boundary, id_map );
    }

    if( rel != null ) {
      // import_theme_connection_json( map, rel, id_map );
    }

  }

  private void import_theme_node( MindMap map, unowned Json.Object obj, int level, HashMap<string,IdObject> id_map ) {

    unowned var props = get_json_object( obj, "properties" );

    if( props != null ) {

      var styles = new SList<Style>();
      if( level == 10 ) {
        for( int i=2; i<10; i++ ) {
          styles.append( StyleInspector.styles.get_style_for_level( i, null ) );
        }
      } else {
        styles.append( StyleInspector.styles.get_style_for_level( level, null ) );
      }

      var shape  = get_json_string( props, "shape-class" );
      var bwidth = get_json_string( props, "border-line-width" );
      var line   = get_json_string( props, "line-class" );
      var lwidth = get_json_string( props, "line-width" );
      var fill   = get_json_string( props, "svg:file" );

      /* Node shape */
      if( shape != "" ) {
        var border = "squared";
        switch( shape ) {
          case "org.xmind.topicShape.roundedRect" :  border = "rounded";     break;
          case "org.xmind.topicShape.rect"        :  border = "squared";     break;
          case "org.xmind.topicShape.underline"   :  border = "underlined";  break;
        }
        foreach( Style style in styles ) {
          style.node_border = StyleInspector.styles.get_node_border( border );
        }
      }

      /* Border width */
      if( bwidth != "" ) {
        int width = 1;
        if( bwidth.scanf( "%dpt", &width ) == 1 ) {
          foreach( Style style in styles ) {
            style.node_borderwidth = (width < 2) ? 2 : width;
          }
        }
      }

      /* Link type */
      if( line != "" ) {
        var type = "straight";
        switch( line ) {
          case "org.xmind.branchConnection.curve"        :  type = "curved";    break;
          case "org.xmind.branchConnection.straight"     :  type = "straight";  break;
          case "org.xmind.branchConnection.elbow"        :  type = "squared";   break;
          case "org.xmind.branchConnection.roundedElbow" :  type = "rounded";   break;
          case "org.xmind.branchConnection.arrowedCurve" :
            type = "curved";
            foreach( Style style in styles ) {
              style.link_arrow = true;
            }
            break;
        }
        foreach( Style style in styles ) {
          style.link_type = StyleInspector.styles.get_link_type( type );
        }
      }

      /* Link width */
      if( lwidth != "" ) {
        int width = 1;
        if( lwidth.scanf( "%dpt", &width ) == 1 ) {
          foreach( Style style in styles ) {
            style.link_width = (width < 2) ? 2 : width;
          }
        }
      }

      /* Fill color */
      if( fill != "" ) {
        foreach( Style style in styles ) {
          style.node_fill = true;
        }
      }

    }

  }

  /* Unarchives all of the files within the given XMind 8 file */
  private void unarchive_contents( string fname, string dir ) {

    Archive.Read archive = new Archive.Read();
    archive.support_filter_none();
    archive.support_format_zip();

    Archive.ExtractFlags flags;
    flags  = Archive.ExtractFlags.TIME;
    flags |= Archive.ExtractFlags.PERM;
    flags |= Archive.ExtractFlags.ACL;
    flags |= Archive.ExtractFlags.FFLAGS;

    Archive.WriteDisk extractor = new Archive.WriteDisk();
    extractor.set_options( flags );
    extractor.set_standard_lookup();

    /* Open the file for reading */
    if( archive.open_filename( fname, 16384 ) != Archive.Result.OK ) {
      error( "Error: %s (%d)", archive.error_string(), archive.errno() );
    }

    unowned Archive.Entry entry;

    while( archive.next_header( out entry ) == Archive.Result.OK ) {

      var file = File.new_for_path( Path.build_filename( dir, entry.pathname() ) );
      entry.set_pathname( file.get_path() );

      /* Read from the archive and write the files to disk */
      if( extractor.write_header( entry ) != Archive.Result.OK ) {
        continue;
      }

      uint8[]         buffer;
      Archive.int64_t offset;

      while( archive.read_data_block( out buffer, out offset ) == Archive.Result.OK ) {
        if( extractor.write_data_block( buffer, offset ) != Archive.Result.OK ) {
          break;
        }
      }

    }

    /* Close the archive */
    if( archive.close () != Archive.Result.OK) {
      error( "Error: %s (%d)", archive.error_string(), archive.errno() );
    }

  }

}
