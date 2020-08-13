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

public class ExportXMind : Object {

  public static int ids = 10000000;

  public enum IdObjectType {
    NODE = 0,
    CONNECTION,
    BOUNDARY
  }

  public class IdObject {
    public IdObjectType typ   { get; set; default = IdObjectType.NODE; }
    public Node?        node  { get; set; default = null; }
    public Connection?  conn  { get; set; default = null; }
    // public NodeGroup?   group { get; set; default = null; }
    public IdObject.for_node( Node n ) {
      typ  = IdObjectType.NODE;
      node = n;
    }
    public IdObject.for_connection( Connection c ) {
      typ  = IdObjectType.CONNECTION;
      conn = c;
    }
    /*
    public IdObject.for_boundary( NodeGroup g ) {
      typ   = IdObjectType.BOUNDARY;
      group = g;
    }
    */
  }

  /* Exports the given drawing area to the file of the given name */
  public static bool export( string fname, DrawArea da ) {

    /* Create temporary directory to place contents in */
    var dir = DirUtils.mkdtemp( "minderXXXXXX" );

    /* Create manifest director */
    DirUtils.create( Path.build_filename( dir, "META-INF" ), 0755 );

    /* Export manifest file */
    var manifest = Path.build_filename( dir, "META-INF", "manifest.xml" );
    export_manifest( manifest );

    /* Export the content file */
    var content = Path.build_filename( dir, "content.xml" );
    var styles  = new Array<Xml.Node*>();
    export_content( da, content, styles );

    if( styles.length > 0 ) {
      var path = Path.build_filename( dir, "styles.xml" );
      export_styles( path, styles );
    }

    /* Zip the contents of the temporary directory */
    archive_contents( dir, fname, {manifest, content} );

    return( true );

  }

  /* Generates the manifest file */
  private static bool export_manifest( string fname ) {
    Xml.Doc* doc = new Xml.Doc( "1.0" );
    Xml.Node* manifest = new Xml.Node( null, "manifest" );
    manifest->set_prop( "xmlns", "urn:xmind:xmap:xmlns:manifest:1.0" );
    manifest->set_prop( "password-hint", "" );
    manifest->add_child( manifest_file_entry( "META-INF", "" ) );
    manifest->add_child( manifest_file_entry( "META-INF/manifest.xml", "text/xml" ) );
    manifest->add_child( manifest_file_entry( "meta.xml", "text/xml" ) );
    manifest->add_child( manifest_file_entry( "content.xml", "text/xml" ) );
    doc->set_root_element( manifest );
    doc->save_format_file( fname, 1 );
    delete doc;
    return( false );
  }

  /* Creates the file-entry node within the manifest */
  private static Xml.Node* manifest_file_entry( string path, string type ) {
    Xml.Node* n = new Xml.Node( null, "file-entry" );
    n->set_prop( "full-path", path );
    n->set_prop( "media-type", type );
    return( n );
  }

  /* Generate the main content file from  */
  private static bool export_content( DrawArea da, string fname, Array<Xml.Node*> styles ) {
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

    export_map( da, sheet, timestamp, styles );

    title->add_content( "Sheet 1" );
    sheet->add_child( title );
    xmap->add_child( sheet );
    doc->set_root_element( xmap );
    doc->save_format_file( fname, 1 );
    delete doc;
    return( false );
  }

  private static void export_map( DrawArea da, Xml.Node* sheet, string timestamp, Array<Xml.Node*> styles ) {
    var nodes = da.get_nodes();
    var conns = da.get_connections().connections;
    for( int i=0; i<nodes.length; i++ ) {
      sheet->add_child( export_node( da, nodes.index( i ), timestamp, true, styles ) );
    }
    export_connections( da, sheet, timestamp, styles );
  }

  private static Xml.Node* export_node( DrawArea da, Node node, string timestamp, bool top, Array<Xml.Node*> styles ) {

    Xml.Node* topic = new Xml.Node( null, "topic" );
    Xml.Node* title = new Xml.Node( null, "title" );

    topic->set_prop( "id", node.id().to_string() );
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

    /* Add image, if needed */
    if( node.image != null ) {
      var img_name = da.image_manager.get_file( node.image.id );
      Xml.Node* img = new Xml.Node( "xhtml", "img" );
      img->set_prop( "style-id", (ids++).to_string() );  /* TBD - We need to store this for later use */
      img->set_prop( "svg:height", node.image.height.to_string() );
      img->set_prop( "svg:width",  node.image.width.to_string() );
      img->set_prop( "xhtml:src",  Path.build_filename( "attachments", Filename.display_basename( img_name ) ) );
      topic->add_child( img );
      /* TBD - We need to copy over the file to the attachments directory */
    }

    if( node.children().length > 0 ) {

      var groups = new Array<int>();

      Xml.Node* children = new Xml.Node( null, "children" );
      Xml.Node* topics   = new Xml.Node( null, "topics" );
      topics->set_prop( "type", "attached" );

      for( int i=0; i<node.children().length; i++ ) {
        var child = node.children().index( i );
        topics->add_child( export_node( da, child, timestamp, false, styles ) );
        /*
        if( child.group ) {
          groups.append_val( i );
        }
        */
      }

      /* Add boundaries, if found */
      if( groups.length > 0 ) {
        Xml.Node* boundaries = new Xml.Node( null, "boundaries" );
        for( int i=0; i<groups.length; i++ ) {

          Xml.Node* boundary = new Xml.Node( null, "boundary" );
          Xml.Node* style    = new Xml.Node( null, "style" );
          Xml.Node* props    = new Xml.Node( null, "boundary-properties" );
          int       id       = ids++;

          /* Create boundary */
          boundary->set_prop( "id", id.to_string() );
          boundary->set_prop( "range", "(%d,%d)".printf( groups.index( i ), groups.index( i ) ) );
          boundary->set_prop( "timestamp", timestamp );
          boundaries->add_child( boundary );

          /* Create styling node */
          style->set_prop( "id", id.to_string() );
          style->set_prop( "type", "boundary" );
          props->set_prop( "svg:fill", Utils.color_from_rgba( node.children().index( groups.index( i ) ).link_color ) );
          style->add_child( props );
          styles.append_val( style );

        }
        topics->add_child( boundaries );
      }

      children->add_child( topics );
      topic->add_child( children );

    }

    return( topic );

  }

  /* Exports a node note */
  private static Xml.Node* export_node_note( Node node, Array<Xml.Node*> styles ) {

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
  private static string replace_formatting( string str, Array<Xml.Node*> styles ) {

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

  private static void export_connections( DrawArea da, Xml.Node* sheet, string timestamp, Array<Xml.Node*> styles ) {

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
  private static void export_styles( string fname, Array<Xml.Node*> nodes ) {

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
    doc->save_format_file( fname, 1 );
    delete doc;

  }

  /* Write the contents as a zip file */
  private static void archive_contents( string dir, string outname, string[] files ) {

    GLib.File pwd = GLib.File.new_for_path( dir );

    // Create the tar.gz archive named according the the first argument.
    Archive.Write archive = new Archive.Write();
    archive.add_filter_none();
    archive.set_format_zip();
    archive.open_filename( outname );

    // Add all the other arguments into the archive
    foreach( string ifile in files ) {
      GLib.File file = GLib.File.new_for_path( ifile );
      try {
        GLib.FileInfo file_info = file.query_info( GLib.FileAttribute.STANDARD_SIZE, GLib.FileQueryInfoFlags.NONE );
        FileInputStream input_stream = file.read();
        DataInputStream data_input_stream = new DataInputStream( input_stream );

        // Add an entry to the archive
        Archive.Entry entry = new Archive.Entry();
        entry.set_pathname( pwd.get_relative_path( file ) );
        entry.set_size( file_info.get_size() );
        entry.set_filetype( (uint)Posix.S_IFREG );
        entry.set_perm( 0644 );
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
          archive.write_data( buffer, bytes_read );
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
  public static void import( string fname, DrawArea da ) {

    /* Create temporary directory to place contents in */
    var dir = DirUtils.mkdtemp( "minderXXXXXX" );

    /* Unarchive the files */
    unarchive_contents( fname, dir );

    var content = Path.build_filename( dir, "content.xml" );
    var id_map  = new HashMap<string,IdObject>();
    import_content( da, content, id_map );

    var styles = Path.build_filename( dir, "styles.xml" );
    import_styles( da, styles, id_map );

    /* Update the drawing area and save the result */
    da.queue_draw();
    da.changed();

  }

  /* Import the content file */
  private static bool import_content( DrawArea da, string fname, HashMap<string,IdObject> id_map ) {

    /* Read in the contents of the Freemind file */
    var doc = Xml.Parser.read_file( fname, null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return( false );
    }

    /* Load the contents of the file */
    import_map( da, doc->get_root_element(), id_map );

    /* Delete the OPML document */
    delete doc;

    return( true );

  }

  /* Import the xmind map */
  private static void import_map( DrawArea da, Xml.Node* n, HashMap<string,IdObject> id_map ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( (it->type == ElementType.ELEMENT_NODE) && (it->name == "sheet") ) {
        import_sheet( da, it, id_map );
        return;
      }
    }
  }

  /* Import a sheet */
  private static void import_sheet( DrawArea da, Xml.Node* n, HashMap<string,IdObject> id_map ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( it->type == ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "topic"         :  import_topic( da, null, it, id_map );  break;
          case "relationships" :  import_relationships( da, it, id_map );  break;
        }
      }
    }

  }

  /* Imports an XMind topic (this is a node in Minder) */
  private static void import_topic( DrawArea da, Node? parent, Xml.Node* n, HashMap<string,IdObject> id_map ) {

    Node node;

    string? sclass = n->get_prop( "structure-class" );
    if( sclass != null ) {
      node = da.create_root_node();
      if( sclass == "org.xmind.ui.map.unbalanced" ) {
        node.layout = da.layouts.get_layout( _( "Horizontal" ) );
      } else {
        node.layout = da.layouts.get_layout( _( "To right" ) );
      }
    } else {
      node = da.create_child_node( parent );
    }

    /* Handle the ID */
    string? id = n->get_prop( "id" );
    if( id != null ) {
      id_map.set( id, new IdObject.for_node( node ) );
    }

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( it->type == ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "title"    :  import_node_name( node, it );   break;
          case "notes"    :  import_node_notes( node, it );  break;
          case "img"      :  import_image( da, node, it, id_map );     break;
          case "children" :  import_children( da, node, it, id_map );  break;
        }
      }
    }

  }

  /* Returns the string stored in a <title> node */
  private static string get_title( Xml.Node* n ) {
    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( it->type == ElementType.TEXT_NODE ) {
        return( it->content );
      }
    }
    return( "" );
  }

  /* Imports the node name information */
  private static void import_node_name( Node node, Xml.Node* n ) {
    node.name.text.insert_text( 0, get_title( n ) );
  }

  /* Imports the node note */
  private static void import_node_notes( Node node, Xml.Node* n ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( it->type == ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "plain" :  import_note_plain( node, it );  break;
        }
      }
    }

  }

  /* Imports the node note as plain text */
  private static void import_note_plain( Node node, Xml.Node* n ) {
    node.note = get_title( n );
  }

  /* Imports an image from a file */
  private static void import_image( DrawArea da, Node node, Xml.Node* n, HashMap<string,IdObject> id_map ) {

    int height = 1;
    int width  = 1;

    string? sid = n->get_prop( "style-id" );
    if( sid != null ) {
      // TBD - We need to associate styles to things that are not just nodes
    }

    string? h = n->get_prop( "svg:height" );
    if( h != null ) {
      height = int.parse( h );
    }

    string? w = n->get_prop( "svg:width" );
    if( w != null ) {
      width = int.parse( w );
    }

    string? src = n->get_prop( "xhtml:src" );
    if( src != null ) {
      node.set_image( da.image_manager, new NodeImage.from_uri( da.image_manager, src, width ) );
    }

  }

  /* Importa child nodes */
  private static void import_children( DrawArea da, Node node, Xml.Node* n, HashMap<string,IdObject> id_map ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( (it->type == ElementType.ELEMENT_NODE) && (it->name == "topics") ) {
        for( Xml.Node* it2=it->children; it2!=null; it2=it2->next ) {
          if( it2->type == ElementType.ELEMENT_NODE ) {
            switch( it2->name ) {
              case "topic"      :  import_topic( da, node, it2, id_map );       break;
              case "boundaries" :  import_boundaries( da, node, it2, id_map );  break;
            }
          }
        }
      }
    }

  }

  /* Imports boundary information */
  private static void import_boundaries( DrawArea da, Node node, Xml.Node* n, HashMap<string,IdObject> id_map ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( (it->type == ElementType.ELEMENT_NODE) && (it->name == "boundary") ) {
        string? id = it->get_prop( "id" );
        string? r  = it->get_prop( "range" );
        if( r != null ) {
          int start   = -1;
          int end     = -1;
          if( r.scanf( "(%d,%d)", &start, &end ) == 2 ) {
            var nodes = new Array<Node>();
            for( int i=start; i<=end; i++ ) {
              nodes.append_val( node.children().index( i ) );
            }
            // da.groups.FOOBAR
          }
        }
      }
    }

  }

  /* Import connections */
  private static void import_relationships( DrawArea da, Xml.Node* n, HashMap<string,IdObject> id_map ) {

    for( Xml.Node* it=n->children; it!=null; it=it->next ) {
      if( (it->type == ElementType.ELEMENT_NODE) && (it->name == "relationship") ) {

        Node? from_node = null;
        Node? to_node   = null;

        string? id = it->get_prop( "id" );

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

          if( id != null ) {
            id_map.set( id, new IdObject.for_connection( conn ) );
          }

        }

      }
    }

  }

  /* Imports and applies styling information */
  private static bool import_styles( DrawArea da, string fname, HashMap<string,IdObject> id_map ) {

    /* Read in the contents of the Freemind file */
    var doc = Xml.Parser.read_file( fname, null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return( false );
    }

    /* Load the contents of the file */
    import_styles_content( da, doc->get_root_element() );

    /* Update the drawing area */
    da.queue_draw();

    /* Delete the OPML document */
    delete doc;

    return( true );

  }

  /* Imports tha main styles XML node */
  private static void import_styles_content( DrawArea da, Xml.Node* n ) {

    /* TBD */

  }

  /* Unarchives all of the files within the given XMind 8 file */
  private static void unarchive_contents( string fname, string dir ) {

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
