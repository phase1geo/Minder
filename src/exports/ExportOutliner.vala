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

public class ExportOutliner : Object {

  /* Exports the given drawing area to the file of the given name */
  public static bool export( string fname, DrawArea da ) {
    Xml.Doc*  doc      = new Xml.Doc( "1.0" );
    Xml.Node* outliner = new Xml.Node( null, "outliner" );
    outliner->new_prop( "condensed", "false" );
    outliner->new_prop( "show-tasks", "true" );
    outliner->add_child( export_theme( da ) );
    outliner->add_child( export_top_nodes( da ) );
    doc->set_root_element( outliner );
    doc->save_format_file( fname, 1 );
    delete doc;
    return( true );
  }

  /* Outputs the theme to use */
  private static Xml.Node* export_theme( DrawArea da ) {
    Xml.Node* node = new Xml.Node( null, "theme" );
    var theme = da.get_theme();
    node->set_prop( "name", theme.custom ? "default" : theme.name );
    return( node );
  }

  /* Outputs the top-level nodes */
  private static Xml.Node* export_top_nodes( DrawArea da ) {
    Xml.Node* n = new Xml.Node( null, "nodes" );
    var nodes = da.get_nodes();
    for( int i=0; i<nodes.length; i++ ) {
      n->add_child( export_node( nodes.index( i ) ) );
    }
    return( n );
  }

  /* Outputs a single node */
  private static Xml.Node* export_node( Node node ) {
    Xml.Node* n = new Xml.Node( null, "node" );
    n->set_prop( "expanded", (!node.folded).to_string() );
    n->set_prop( "hidenote", "true" );
    if( node.task_count > 0 ) {
      n->set_prop( "task", ((node.task_count == node.done_count) ? "done" :
                            (node.done_count == 0) ? "open" : "doing") );
    }
    n->add_child( export_name( node, node.name ) );
    if( node.note != "" ) {
      n->add_child( export_note( node.note ) );
    }
    n->add_child( export_nodes( node ) );
    return( n );
  }

  /* Outputs all of the children nodes of the given node */
  private static Xml.Node* export_nodes( Node node ) {
    Xml.Node* n = new Xml.Node( null, "nodes" );
    for( int i=0; i<node.children().length; i++ ) {
      n->add_child( export_node( node.children().index( i ) ) );
    }
    return( n );
  }

  /* Exports the name of the given node */
  private static Xml.Node* export_name( Node node, CanvasText ct ) {
    Xml.Node* n     = new Xml.Node( null, "name" );
    Xml.Node* t     = new Xml.Node( null, "text" );
    var       links = node.urls.links;
    t->set_prop( "data",     ct.text );
    t->set_prop( "parse-as", "html" );
    n->add_child( t );
    if( links.length > 0 ) {
      t->add_child( export_urls( links ) );
    }
    return( n );
  }

  /* Exports any embedded links */
  private static Xml.Node* export_urls( Array<UrlLink> links ) {
    Xml.Node* n = new Xml.Node( null, "url" );
    for( int i=0; i<links.length; i++ ) {
      Xml.Node* r    = new Xml.Node( null, "range" );
      var       link = links.index( i );
      r->set_prop( "start", link.spos.to_string() );
      r->set_prop( "end",   link.epos.to_string() );
      r->set_prop( "extra", link.url );
      n->add_child( r );
    }
    return( n );
  }

  /* Exports the note of the given node */
  private static Xml.Node* export_note( string note ) {
    Xml.Node* n = new Xml.Node( null, "note" );
    Xml.Node* t = new Xml.Node( null, "text" );
    t->set_prop( "data",     note );
    t->set_prop( "parse-as", "markdown" );
    n->add_child( t );
    return( n );
  }

  //----------------------------------------------------------------------------

  /*
   Reads the contents of an Outliner file and creates a new document based on
   the stored information.
  */
  public static bool import( string fname, DrawArea da ) {

    /* Read in the contents of the OPML file */
    var doc = Xml.Parser.read_file( fname, null, Xml.ParserOption.HUGE );
    if( doc == null ) {
      return( false );
    }

    /* Get the dimensions of the window */
    int width, height;
    da.get_dimensions( out width, out height );

    /* Create the root node */
    var root = new Node.with_name( da, da.get_doc().label, da.layouts.get_default() );
    root.style.copy( StyleInspector.styles.get_global_style() );
    root.posx = (width  / 2) - 30;
    root.posy = (height / 2) - 10;

    /* Add the root node */
    da.get_nodes().append_val( root );

    /* Load the contents of the file */
    for( Xml.Node* it = doc->get_root_element()->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "theme" :  import_theme( it, da );        break;
          case "nodes" :  import_nodes( it, da, root );  break;
        }
      }
    }

    /* Delete the OPML document */
    delete doc;

    return( true );

  }

  private static void import_theme( Xml.Node* n, DrawArea da ) {
    var m = n->get_prop( "name" );
    if( m != null ) {
      da.set_theme( da.win.themes.get_theme( m ), false );
    }
  }

  private static void import_nodes( Xml.Node* n, DrawArea da, Node? parent ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "node") ) {
        import_node( it, da, parent );
      }
    }
  }

  private static void import_node( Xml.Node* n, DrawArea da, Node? parent ) {
    var node = new Node( da, null );
    var e = n->get_prop( "expanded" );
    if( e != null ) {
      node.folded = !bool.parse( e );
    }
    node.layout = da.layouts.get_default();
    node.style.copy( StyleInspector.styles.get_global_style() );
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name ) {
          case "name"  :  import_name( it, node );  break;
          case "note"  :  import_note( it, node );  break;
          case "nodes" :  import_nodes( it, da, node );  break;
        }
      }
    }
    if( (node.name.text.strip() != "") || (node.children().length > 0) ) {
      node.attach( parent, -1, da.get_theme() );
      var t = n->get_prop( "task" );
      if( (t != null) && node.is_leaf() ) {
        node.enable_task( true );
        node.set_task_done( t == "done" );
      }
    }
  }

  private static void import_name( Xml.Node* n, Node node ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "text") ) {
        var text = it->get_prop( "data" );
        if( text != null ) {
          node.name.text = text;
        }
        for( Xml.Node* it2 = it->children; it2 != null; it2 = it2->next ) {
          if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "url") ) {
            import_url( it2, node );
          }
        }
      }
    }
  }

  private static void import_note( Xml.Node* n, Node node ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "text") ) {
        var text = it->get_prop( "data" );
        if( text != null ) {
          node.note = text;
        }
      }
    }
  }

  private static void import_url( Xml.Node* n, Node node ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "range") ) {
        var start = it->get_prop( "start" );
        var end   = it->get_prop( "end" );
        var url   = it->get_prop( "extra" );
        if( (start != null) && (end != null) && (url != null) ) {
          node.urls.add_link( int.parse( start ), int.parse( end ), url );
        }
      }
    }

  }

}
