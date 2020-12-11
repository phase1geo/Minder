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
using Xml;

public class ExportXMind : Export {

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
  public ExportXMind() {
    base( "xmind-8", _( "XMind 8" ), { "*.xmind" }, true, true );
  }

  /* Exports the given drawing area to the file of the given name */
  public override bool export( string fname, DrawArea da ) {

    /* Create temporary directory to place contents in */
    var dir = DirUtils.mkdtemp( "minderXXXXXX" );

    var styles    = new Array<Xml.Node*>();
    var file_list = new FileItems();

    /* Export the meta file */
    export_meta( da, dir, file_list );

    /* Export the content file */
    export_content( da, dir, file_list, styles );

    if( styles.length > 0 ) {
      export_styles( dir, file_list, styles );
    }

    /* Export manifest file */
    export_manifest( dir, file_list );

    /* Archive the contents */
    archive_contents( dir, fname, file_list );

    return( true );

  }

  /* Generates the manifest file */
  private bool export_manifest( string dir, FileItems file_list ) {

    Xml.Doc* doc = new Xml.Doc( "1.0" );
    Xml.Node* manifest = new Xml.Node( null, "manifest" );

    manifest->set_prop( "xmlns", "urn:xmind:xmap:xmlns:manifest:1.0" );
    manifest->set_prop( "password-hint", "" );

    manifest->add_child( manifest_file_entry( "META-INF", "" ) );
    manifest->add_child( manifest_file_entry( "META-INF/manifest.xml", "text/xml" ) );

    for( int i=0; i<file_list.items.length; i++ ) {
      var mfile = file_list.items.index( i );
      manifest->add_child( manifest_file_entry( mfile.name, mfile.type ) );
    }

    doc->set_root_element( manifest );

    var meta_dir = Path.build_filename( dir, "META-INF" );
    DirUtils.create( meta_dir, 0755 );
    doc->save_format_file( Path.build_filename( meta_dir, "manifest.xml" ), 1 );

    file_list.add( "META-INF", "" );
    file_list.add( Path.build_filename( "META-INF", "manifest.xml" ), "text/xml" );

    delete doc;

    return( false );

  }

  /* Creates the file-entry node within the manifest */
  private Xml.Node* manifest_file_entry( string path, string type ) {
    Xml.Node* n = new Xml.Node( null, "file-entry" );
    n->set_prop( "full-path", path );
    n->set_prop( "media-type", type );
    return( n );
  }

  /* Generate the main content file from  */
  private bool export_content( DrawArea da, string dir, FileItems file_list, Array<Xml.Node*> styles ) {

    Xml.Doc*  doc       = new Xml.Doc( "1.0" );
    Xml.Node* xmap      = new Xml.Node( null, "xmap-content" );
    Xml.Node* sheet     = new Xml.Node( null, "sheet" );
    Xml.Node* title     = new Xml.Node( null, "title" );
    var       timestamp = new DateTime.now().to_unix().to_string();

    xmap->set_prop( "xmlns", "urn:xmind:xmap:xmlns:content:2.0" );
    xmap->set_prop( "xmlns:fo", "http://www.w3.org/1999/XSL/Format" );
    xmap->set_prop( "xmlns:svg", "http://www.w3.org/2000/svg" );
    xmap->set_prop( "xmlns:xhtml", "http://www.w3.org/1999/xhtml" );
    xmap->set_prop( "xmlns:xlink", "http://www.w3.org/1999/xlink" );
    xmap->set_prop( "timestamp", timestamp );
    xmap->set_prop( "version", "2.0" );
    sheet->set_prop( "id", "1" );
    sheet->set_prop( "timestamp", timestamp );

    export_map( da, sheet, timestamp, dir, file_list, styles );

    title->add_content( "Sheet 1" );
    sheet->add_child( title );
    xmap->add_child( sheet );

    doc->set_root_element( xmap );
    doc->save_format_file( Path.build_filename( dir, "content.xml" ), 1 );

    file_list.add( "content.xml", "text/xml" );

    delete doc;

    return( false );

  }

  /* Exports the map contents */
  private void export_map( DrawArea da, Xml.Node* sheet, string timestamp, string dir, FileItems file_list, Array<Xml.Node*> styles ) {
    var nodes = da.get_nodes();
    var conns = da.get_connections().connections;
    Xml.Node* top = export_node( da, nodes.index( 0 ), timestamp, true, dir, file_list, styles );
    if( nodes.length > 1 ) {
      for( Xml.Node* it=top->children; it!=null; it=it->next ) {
        if( (it->type == ElementType.ELEMENT_NODE) && (it->name == "children") ) {
          Xml.Node* topics = new Xml.Node( null, "topics" );
          topics->set_prop( "type", "detached" );
          for( int i=1; i<nodes.length; i++ ) {
            Xml.Node* topic = export_node( da, nodes.index( i ), timestamp, false, dir, file_list, styles );
            Xml.Node* pos   = new Xml.Node( null, "position" );
            var       x     = (int)(nodes.index( i ).posx - nodes.index( 0 ).posx);
            var       y     = (int)(nodes.index( i ).posy - nodes.index( 0 ).posy);
            pos->set_prop( "svg:x", x.to_string() );
            pos->set_prop( "svg:y", y.to_string() );
            topic->add_child( pos );
            topics->add_child( topic );
          }
          it->add_child( topics );
        }
      }
    }
    sheet->add_child( top );
    export_connections( da, sheet, timestamp, styles );
  }

  private Xml.Node* export_node( DrawArea da, Node node, string timestamp, bool top, string dir, FileItems file_list, Array<Xml.Node*> styles ) {

    Xml.Node* topic = new Xml.Node( null, "topic" );
    Xml.Node* title = new Xml.Node( null, "title" );
    var       sid   = ids++;

    topic->set_prop( "id", node.id().to_string() );
    topic->set_prop( "style-id", sid.to_string() );
    // topic->set_prop( "modified-by", TBD );
    topic->set_prop( "timestamp", timestamp );
    if( top ) {
      topic->set_prop( "structure-class", "org.xmind.ui.map.unbalanced" );
    }

    title->add_content( node.name.text.text );
    topic->add_child( title );

    /* Add note, if needed */
    if( node.note != "" ) {
      topic->add_child( export_node_note( node, styles ) );
    }

    /* Add styling information */
    Xml.Node* nstyle = new Xml.Node( null, "style" );
    Xml.Node* nprops = new Xml.Node( null, "topic-properties" );
    nstyle->set_prop( "id", sid.to_string() );
    nstyle->set_prop( "type", "topic" );
    export_node_style( node, nprops );
    nstyle->add_child( nprops );
    styles.append_val( nstyle );

    /* Add image, if needed */
    if( node.image != null ) {
      export_image( da, node, dir, file_list, topic );
    }

    if( node.children().length > 0 ) {

      var groups = new Array<int>();

      Xml.Node* children = new Xml.Node( null, "children" );
      Xml.Node* topics   = new Xml.Node( null, "topics" );
      topics->set_prop( "type", "attached" );

      for( int i=0; i<node.children().length; i++ ) {
        var child = node.children().index( i );
        topics->add_child( export_node( da, child, timestamp, false, dir, file_list, styles ) );
        if( child.group ) {
          groups.append_val( i );
        }
      }

      children->add_child( topics );
      topic->add_child( children );

      /* Add boundaries, if found */
      if( groups.length > 0 ) {
        Xml.Node* boundaries = new Xml.Node( null, "boundaries" );
        for( int i=0; i<groups.length; i++ ) {

          Xml.Node* boundary = new Xml.Node( null, "boundary" );
          Xml.Node* style    = new Xml.Node( null, "style" );
          Xml.Node* props    = new Xml.Node( null, "boundary-properties" );
          int       id       = ids++;
          int       stid     = ids++;

          /* Create boundary */
          boundary->set_prop( "id", id.to_string() );
          boundary->set_prop( "style-id", stid.to_string() );
          boundary->set_prop( "range", "(%d,%d)".printf( groups.index( i ), groups.index( i ) ) );
          boundary->set_prop( "timestamp", timestamp );
          boundaries->add_child( boundary );

          /* Create styling node */
          style->set_prop( "id", stid.to_string() );
          style->set_prop( "type", "boundary" );
          props->set_prop( "svg:fill", Utils.color_from_rgba( node.children().index( groups.index( i ) ).link_color ) );
          style->add_child( props );
          styles.append_val( style );

        }
        topic->add_child( boundaries );
      }

    }

    return( topic );

  }

  /* Exports the given node's image */
  private void export_image( DrawArea da, Node node, string dir, FileItems file_list, Xml.Node* topic ) {

    var img_name  = da.image_manager.get_file( node.image.id );
    var mime_type = da.image_manager.get_mime_type( node.image.id );
    var src       = Path.build_filename( "attachments", Filename.display_basename( img_name ) );
    var parts     = src.split( "." );
    Xml.Node* img = new Xml.Node( null, "xhtml:img" );

    /* XMind doesn't support SVG images so cut short if we have this type of image */
    if( mime_type == "image/svg" ) return;

    /* Copy the image file to the XMind bundle */
    DirUtils.create( Path.build_filename( dir, "attachments" ), 0755 );
    var lfile = File.new_for_path( Path.build_filename( dir, src ) );
    var rfile = File.new_for_path( img_name );
    try {
      rfile.copy( lfile, FileCopyFlags.OVERWRITE );
    } catch( GLib.Error e ) {
      return;
    }

    img->set_prop( "style-id", (ids++).to_string() );  /* TBD - We need to store this for later use */
    img->set_prop( "svg:height", node.image.height.to_string() );
    img->set_prop( "svg:width",  node.image.width.to_string() );
    img->set_prop( "xhtml:src",  "xap:%s".printf( src ) );
    topic->add_child( img );

    file_list.add( "attachments", "" );
    file_list.add( src, mime_type );

  }

  /* Exports node styling information */
  private void export_node_style( Node node, Xml.Node* n ) {

    /* Node border shape */
    switch( node.style.node_border.name() ) {
      case "rounded"    :  n->set_prop( "shape-class", "org.xmind.topicShape.roundedRect" );  break;
      case "underlined" :  n->set_prop( "shape-class", "org.xmind.topicShape.underline" );    break;
      default           :  n->set_prop( "shape-class", "org.xmind.topicShape.rect" );         break;
    }

    n->set_prop( "border-line-color", Utils.color_from_rgba( node.link_color ) );
    n->set_prop( "border-line-width", "%dpt".printf( node.style.node_borderwidth ) );
    n->set_prop( "line-color",        Utils.color_from_rgba( node.link_color ) );
    n->set_prop( "line-width",        "%dpt".printf( node.style.link_width ) );

    if( node.style.node_fill ) {
      n->set_prop( "svg:fill", Utils.color_from_rgba( node.link_color ) );
    }

    switch( node.style.link_type.name() ) {
      case "curved"   :  n->set_prop( "line-class", "org.xmind.branchConnection.%s".printf( node.style.link_arrow ? "arrowedCurve" : "curve" ) );  break;
      case "straight" :  n->set_prop( "line-class", "org.xmind.branchConnection.straight" );  break;
      case "squared"  :  n->set_prop( "line-class", "org.xmind.branchConnection.elbow" );     break;
    }

  }

  /* Exports a node note */
  private Xml.Node* export_node_note( Node node, Array<Xml.Node*> styles ) {

    Xml.Node* note  = new Xml.Node( null, "notes" );
    Xml.Node* plain = new Xml.Node( null, "plain" );

    plain->add_content( node.note );

    var note_html = replace_formatting( Utils.markdown_to_html( node.note, "html" ), styles );
    var note_doc  = Xml.Parser.parse_memory( note_html, note_html.length );
    var html      = note_doc->get_root_element()->copy( 1 );

    note->add_child( plain );
    note->add_child( html );

    return( note );

  }

  /* Converts the given HTML string into the XHTML equivalent */
  private string replace_formatting( string str, Array<Xml.Node*> styles ) {

    var bold_id = ids++;
    var em_id   = ids++;

    Xml.Node* bold_style = new Xml.Node( null, "style" );
    Xml.Node* em_style   = new Xml.Node( null, "style" );
    Xml.Node* bold_props = new Xml.Node( null, "text-properties" );
    Xml.Node* em_props   = new Xml.Node( null, "text-properties" );

    bold_props->set_prop( "id", bold_id.to_string() );
    bold_props->set_prop( "fo:font-weight", "bold" );
    bold_style->add_child( bold_props );

    em_props->set_prop( "id", em_id.to_string() );
    em_props->set_prop( "fo:font-style", "italic" );
    em_style->add_child( em_props );

    styles.append_val( bold_style );
    styles.append_val( em_style );

    /* Perform simple one-for-one replacements */
    return( str.replace( "<p>",       "<xhtml:p>" )
               .replace( "</p>",      "</xhtml:p>" )
               .replace( "<a href",   "<xhtml:a xlink:href" )
               .replace( "</a>",      "</xhtml:a>" )
               .replace( "<strong>",  "<xhtml:span style-id=\"%d\">".printf( bold_id ) )
               .replace( "</strong>", "</xhtml:span>" )
               .replace( "<em>",      "<xhtml:span style-id=\"%d\">".printf( em_id ) )
               .replace( "</em>",     "</xhtml:span>" ) );

  }

  private void export_connections( DrawArea da, Xml.Node* sheet, string timestamp, Array<Xml.Node*> styles ) {

    var conns = da.get_connections().connections;

    if( conns.length > 0 ) {

      Xml.Node* relations = new Xml.Node( null, "relationships" );

      for( int i=0; i<conns.length; i++ ) {
        var conn     = conns.index( i );
        var conn_id  = ids++;
        var style_id = ids++;
        var color    = (conn.color == null) ? da.get_theme().get_color( "connection_background" ) : conn.color;
        var dash     = "dash";

        switch( conn.style.connection_dash.name ) {
          case "solid"  :  dash = "solid";  break;
          case "dotted" :  dash = "dot";    break;
        }

        Xml.Node* relation = new Xml.Node( null, "relationship" );
        relation->set_prop( "end1", conn.from_node.id().to_string() );
        relation->set_prop( "end2", conn.to_node.id().to_string() );
        relation->set_prop( "id", conn_id.to_string() );
        relation->set_prop( "style-id", style_id.to_string() );
        // relation->set_prop( "modified-by", TBD );
        relation->set_prop( "timestamp", timestamp );

        if( conn.title != null ) {
          Xml.Node* title = new Xml.Node( null, "title" );
          title->add_content( conn.title.text.text );
          relation->add_child( title );
        }

        relations->add_child( relation );

        /* Create style */
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

      }

      sheet->add_child( relations );

    }

  }

  /* Creates the styles.xml file in the main directory */
  private void export_styles( string dir, FileItems file_list, Array<Xml.Node*> nodes ) {

    Xml.Doc*  doc    = new Xml.Doc( "1.0" );
    Xml.Node* xmap   = new Xml.Node( null, "xmap-styles" );
    Xml.Node* styles = new Xml.Node( null, "styles" );

    xmap->set_prop( "xmlns", "urn:xmind:xmap:xmlns:content:2.0" );
    xmap->set_prop( "xmlns:fo", "http://www.w3.org/1999/XSL/Format" );
    xmap->set_prop( "xmlns:svg", "http://www.w3.org/2000/svg" );
    xmap->set_prop( "version", "2.0" );

    for( int i=0; i<nodes.length; i++ ) {
      styles->add_child( nodes.index( i ) );
    }

    xmap->add_child( styles );

    doc->set_root_element( xmap );
    doc->save_format_file( Path.build_filename( dir, "styles.xml" ), 1 );

    file_list.add( "styles.xml", "text/xml" );

    delete doc;

  }

  /* Exports the contents of the meta file */
  private void export_meta( DrawArea da, string dir, FileItems file_list ) {

    Xml.Doc*  doc       = new Xml.Doc( "1.0" );
    Xml.Node* meta      = new Xml.Node( null, "meta" );
    Xml.Node* create    = new Xml.Node( null, "Create" );
    Xml.Node* time      = new Xml.Node( null, "Time" );
    Xml.Node* creator   = new Xml.Node( null, "Creator" );
    Xml.Node* name      = new Xml.Node( null, "Name" );
    Xml.Node* version   = new Xml.Node( null, "Version" );
    var       timestamp = new DateTime.now().to_string();

    meta->set_prop( "xmlns", "urn:xmind:xmap:xmlns:meta:2.0" );
    meta->set_prop( "version", "2.0" );

    time->set_content( timestamp );
    name->set_content( "Minder" );
    version->set_content( Minder.version );

    create->add_child( time );
    meta->add_child( create );

    creator->add_child( name );
    creator->add_child( version );
    meta->add_child( creator );

    doc->set_root_element( meta );
    doc->save_format_file( Path.build_filename( dir, "meta.xml" ), 1 );

    file_list.add( "meta.xml", "text/xml" );

    delete doc;

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
#if VALAC048
        entry.set_size( (Archive.int64_t)file_info.get_size() );
        entry.set_filetype( Archive.FileType.IFREG );
        entry.set_perm( (Archive.FileMode)0644 );
#else
        entry.set_size( file_info.get_size() );
        entry.set_filetype( (uint)Posix.S_IFREG );
        entry.set_perm( 0644 );
#endif
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
#if VALAC048
          archive.write_data( buffer );
#else
          archive.write_data( buffer, bytes_read );
#endif
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
  public override bool import( string fname, DrawArea da ) {

    /* Create temporary directory to place contents in */
    var dir = DirUtils.mkdtemp( "minderXXXXXX" );

    /* Unarchive the files */
    unarchive_contents( fname, dir );

    var content = Path.build_filename( dir, "content.xml" );
    var id_map  = new HashMap<string,IdObject>();
    import_content( da, content, dir, id_map );

    var styles = Path.build_filename( dir, "styles.xml" );
    import_styles( da, styles, id_map );

    /* Update the drawing area and save the result */
    da.queue_draw();
    da.changed();

    return( true );

  }

  /* Import the content file */
  private bool import_content( DrawArea da, string fname, string dir, HashMap<string,IdObject> id_map ) {

    /* Read in the contents of the Freemind file */
    var doc = Xml.Parser.read_file( fname, null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return( false );
    }

    /* Load the contents of the file */
    import_map( da, doc->get_root_element(), dir, id_map );

    /* Delete the OPML document */
    delete doc;

    return( true );

  }

  /* Import the xmind map */
  private void import_map( DrawArea da, Xml.Node* n, string dir, HashMap<string,IdObject> id_map ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( (it->type == ElementType.ELEMENT_NODE) && (it->name == "sheet") ) {
        import_sheet( da, it, dir, id_map );
        return;
      }
    }
  }

  /* Import a sheet */
  private void import_sheet( DrawArea da, Xml.Node* n, string dir, HashMap<string,IdObject> id_map ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( it->type == ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "topic"         :  import_topic( da, null, it, false, dir, id_map );  break;
          case "relationships" :  import_relationships( da, it, id_map );  break;
        }
      }
    }

  }

  /* Imports an XMind topic (this is a node in Minder) */
  private void import_topic( DrawArea da, Node? parent, Xml.Node* n, bool attached, string dir, HashMap<string,IdObject> id_map ) {

    Node node;

    string? sclass = n->get_prop( "structure-class" );
    if( sclass != null ) {
      node = da.create_root_node();
      if( sclass == "org.xmind.ui.map.unbalanced" ) {
        node.layout = da.layouts.get_layout( _( "Horizontal" ) );
      } else {
        node.layout = da.layouts.get_layout( _( "To right" ) );
      }
    } else if( !attached ) {
      node = da.create_root_node();
    } else {
      node = da.create_child_node( parent );
    }

    /* Handle the ID */
    string? id = n->get_prop( "id" );
    if( id != null ) {
      id_map.set( id, new IdObject.for_node( node ) );
    }

    string? sid = n->get_prop( "style-id" );
    if( sid != null ) {
      id_map.set( sid, new IdObject.for_node( node ) );
    }

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( it->type == ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "title"      :  import_node_name( node, it );               break;
          case "notes"      :  import_node_notes( node, it );              break;
          case "img"        :  import_image( da, node, it, dir, id_map );     break;
          case "children"   :  import_children( da, node, it, dir, id_map );  break;
          case "boundaries" :  import_boundaries( da, node, it, id_map );  break;
        }
      }
    }

  }

  /* Returns the string stored in a <title> node */
  private string get_title( Xml.Node* n ) {
    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( it->type == ElementType.TEXT_NODE ) {
        return( it->content );
      }
    }
    return( "" );
  }

  /* Imports the node name information */
  private void import_node_name( Node node, Xml.Node* n ) {
    node.name.text.insert_text( 0, get_title( n ) );
  }

  /* Imports the node note */
  private void import_node_notes( Node node, Xml.Node* n ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( it->type == ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "plain" :  import_note_plain( node, it );  break;
        }
      }
    }

  }

  /* Imports the node note as plain text */
  private void import_note_plain( Node node, Xml.Node* n ) {
    node.note = get_title( n );
  }

  /* Imports an image from a file */
  private void import_image( DrawArea da, Node node, Xml.Node* n, string dir, HashMap<string,IdObject> id_map ) {

    int height = 1;
    int width  = 1;

    string? sid = n->get_prop( "style-id" );
    if( sid != null ) {
      // TBD - We need to associate styles to things that are not just nodes
    }

    string? h = n->get_prop( "height" );
    if( h != null ) {
      height = int.parse( h );
    }

    string? w = n->get_prop( "width" );
    if( w != null ) {
      width = int.parse( w );
    }

    string? src = n->get_prop( "src" );
    if( src != null ) {
      var img_file = File.new_for_path( Path.build_filename( dir, src.substring( 4 ) ) );
      node.set_image( da.image_manager, new NodeImage.from_uri( da.image_manager, img_file.get_uri(), width ) );
    }

  }

  /* Importa child nodes */
  private void import_children( DrawArea da, Node node, Xml.Node* n, string dir, HashMap<string,IdObject> id_map ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( (it->type == ElementType.ELEMENT_NODE) && (it->name == "topics") ) {
        string? t = it->get_prop( "type" );
        var     attached = (t != null) && (t == "attached");
        for( Xml.Node* it2=it->children; it2!=null; it2=it2->next ) {
          if( (it2->type == ElementType.ELEMENT_NODE) && (it2->name == "topic") ) {
            import_topic( da, node, it2, attached, dir, id_map );
          }
        }
      }
    }

  }

  /* Imports boundary information */
  private void import_boundaries( DrawArea da, Node node, Xml.Node* n, HashMap<string,IdObject> id_map ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( (it->type == ElementType.ELEMENT_NODE) && (it->name == "boundary") ) {
        string? sid = it->get_prop( "style-id" );
        string? r   = it->get_prop( "range" );
        if( r != null ) {
          int start   = -1;
          int end     = -1;
          if( r.scanf( "(%d,%d)", &start, &end ) == 2 ) {
            var nodes = new Array<Node>();
            for( int i=start; i<=end; i++ ) {
              var child = node.children().index( i );
              nodes.append_val( child );
            }
            var group = new NodeGroup.array( da, nodes );
            da.groups.add_group( group );
            if( sid != null ) {
              id_map.set( sid, new IdObject.for_boundary( group ) );
            }
          }
        }
      }
    }

  }

  /* Import connections */
  private void import_relationships( DrawArea da, Xml.Node* n, HashMap<string,IdObject> id_map ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( (it->type == ElementType.ELEMENT_NODE) && (it->name == "relationship") ) {

        Node? from_node = null;
        Node? to_node   = null;

        string? sid = it->get_prop( "style-id" );

        string? sp = it->get_prop( "end1" );
        if( sp != null ) {
          var obj = id_map.get( sp );
          if( obj.typ == IdObjectType.NODE ) {
            from_node = obj.node;
          }
        }

        string? ep = it->get_prop( "end2" );
        if( ep != null ) {
          var obj = id_map.get( ep );
          if( obj.typ == IdObjectType.NODE ) {
            to_node = obj.node;
          }
        }

        string title = "";
        for( Xml.Node* it2=it->children; it2!=null; it2=it2->next ) {
          if( (it2->type == ElementType.ELEMENT_NODE) && (it2->name == "title") ) {
            title = get_title( it2 );
          }
        }

        if( (from_node != null) && (to_node != null) ) {

          var conn = new Connection( da, from_node );
          conn.change_title( da, title );
          conn.connect_to( to_node );
          da.get_connections().add_connection( conn );

          if( sid != null ) {
            id_map.set( sid, new IdObject.for_connection( conn ) );
          }

        }

      }
    }

  }

  /* Imports and applies styling information */
  private bool import_styles( DrawArea da, string fname, HashMap<string,IdObject> id_map ) {

    /* Read in the contents of the Freemind file */
    var doc = Xml.Parser.read_file( fname, null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return( false );
    }

    /* Load the contents of the file */
    import_styles_content( da, doc->get_root_element(), id_map );

    /* Update the drawing area */
    da.queue_draw();

    /* Delete the OPML document */
    delete doc;

    return( true );

  }

  /* Imports tha main styles XML node */
  private void import_styles_content( DrawArea da, Xml.Node* n, HashMap<string,IdObject> id_map ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( (it->type == ElementType.ELEMENT_NODE) && (it->name == "styles") ) {
        for( Xml.Node* it2=it->children; it2!=null; it2=it2->next ) {
          if( (it->type == ElementType.ELEMENT_NODE) && (it2->name == "style") ) {
            import_styles_style( da, it2, id_map );
          }
        }
      }
    }

  }

  /* Imports the style information for one of the supported objects */
  private void import_styles_style( DrawArea da, Xml.Node* n, HashMap<string,IdObject> id_map ) {

    string? id = n->get_prop( "id" );
    if( (id == null) || !id_map.has_key( id ) ) return;

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( it->type == ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "topic-properties"        :   import_styles_topic( da, it, id_map.get( id ).node );       break;
          case "relationship-properties" :   import_styles_connection( da, it, id_map.get( id ).conn );  break;
          case "boundary-properties"     :   import_styles_boundary( da, it, id_map.get( id ).group );   break;
        }
      }
    }

  }

  /* Imports the style information for a given node */
  private void import_styles_topic( DrawArea da, Xml.Node* n, Node node ) {

    string? sc = n->get_prop( "shape-class" );
    if( sc != null ) {
      var border = "squared";
      switch( sc ) {
        case "org.xmind.topicShape.roundedRect" :  border = "rounded";     break;
        case "org.xmind.topicShape.rect"        :  border = "squared";     break;
        case "org.xmind.topicShape.underline"   :  border = "underlined";  break;
      }
      node.style.node_border = StyleInspector.styles.get_node_border( border );
    }

    string? blc = n->get_prop( "border-line-color" );
    if( blc != null ) {
      RGBA c = {1.0, 1.0, 1.0, 1.0};
      c.parse( blc );
      node.link_color = c;
    }

    string? blw = n->get_prop( "border-line-width" );
    if( blw != null ) {
      int width = 1;
      if( blw.scanf( "%dpt", &width ) == 1 ) {
        node.style.node_borderwidth = width;
      }
    }

    string? f = n->get_prop( "fill" );
    if( f != null ) {
      RGBA c = {1.0, 1.0, 1.0, 1.0};
      c.parse( f );
      node.link_color = c;
      node.style.node_fill = true;
    }

    string? lc = n->get_prop( "line-color" );
    if( lc != null ) {
      RGBA c = {1.0, 1.0, 1.0, 1.0};
      c.parse( lc );
      node.link_color = c;
    }

    string? lw = n->get_prop( "line-width" );
    if( lw != null ) {
      int width = 1;
      if( lw.scanf( "^dpt", &width ) == 1 ) {
        node.style.link_width = width;
      }
    }

    string? lcl = n->get_prop( "line-class" );
    if( lcl != null ) {
      var type = "straight";
      switch( lcl ) {
        case "org.xmind.branchConnection.curve"        :  type = "curved";    break;
        case "org.xmind.branchConnection.straight"     :  type = "straight";  break;
        case "org.xmind.branchConnection.elbow"        :
        case "org.xmind.branchConnection.roundedElbow" :  type = "squared";   break;
        case "org.xmind.branchConnection.arrowedCurve" :
          type = "curved";
          node.style.link_arrow = true;
          break;
      }
      node.style.link_type = StyleInspector.styles.get_link_type( type );
    }

  }

  /* Imports connection styling information */
  private void import_styles_connection( DrawArea da, Xml.Node* n, Connection conn ) {

    string? arrow_start = n->get_prop( "arrow-begin-class" );
    if( arrow_start != null ) {
      switch( arrow_start ) {
        case "org.xmind.arrowShape.triangle"  :
        case "org.xmind.arrowShape.spearhead" :  conn.style.connection_arrow = "tofrom";  break;
        default                               :  conn.style.connection_arrow = "none";    break;
      }
    }

    string? arrow_end = n->get_prop( "arrow-end-class" );
    if( arrow_end != null ) {
      switch( arrow_end ) {
        case "org.xmind.arrowShape.triangle"  :
        case "org.xmind.arrowShape.spearhead" :
          conn.style.connection_arrow = (conn.style.connection_arrow == "tofrom") ? "both" : "fromto";
          break;
      }
    }

    string? lc = n->get_prop( "line-color" );
    if( lc != null ) {
      RGBA c = {1.0, 1.0, 1.0, 1.0};
      c.parse( lc );
      conn.color = c;
    }

    string? lp = n->get_prop( "line-pattern" );
    if( lp != null ) {
      switch( lp ) {
        case "solid" :  conn.style.connection_dash = StyleInspector.styles.get_link_dash( "solid" );   break;
        case "dot"   :  conn.style.connection_dash = StyleInspector.styles.get_link_dash( "dotted" );  break;
        default      :  conn.style.connection_dash = StyleInspector.styles.get_link_dash( "dash" );    break;
      }
    }

    string? lw = n->get_prop( "line-width" );
    if( lw != null ) {
      int width = 1;
      if( lw.scanf( "%dpt", &width ) == 1 ) {
        conn.style.connection_line_width = width;
      }
    }

  }

  /* Imports styling information for a node group */
  private void import_styles_boundary( DrawArea da, Xml.Node* n, NodeGroup group ) {

    string? f = n->get_prop( "fill" );
    if( f != null ) {
      RGBA c = {1.0, 1.0, 1.0, 1.0};
      c.parse( f );
      group.color = c;
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

#if VALAC048
      uint8[]         buffer;
      Archive.int64_t offset;

      while( archive.read_data_block( out buffer, out offset ) == Archive.Result.OK ) {
        if( extractor.write_data_block( buffer, offset ) != Archive.Result.OK ) {
          break;
        }
      }
#else
      void*       buffer = null;
      size_t      buffer_length;
      Posix.off_t offset;

      while( archive.read_data_block( out buffer, out buffer_length, out offset ) == Archive.Result.OK ) {
        if( extractor.write_data_block( buffer, buffer_length, offset ) != Archive.Result.OK ) {
          break;
        }
      }
#endif

    }

    /* Close the archive */
    if( archive.close () != Archive.Result.OK) {
      error( "Error: %s (%d)", archive.error_string(), archive.errno() );
    }

  }

}
