/*
* Copyright (c) 2026 (https://github.com/phase1geo/Minder)
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

using Gtk;

public class ReleaseNotes : Granite.Dialog {

  private WebKit.WebView _viewer;
  private Array<string>  _notes;
  private bool           _show_current = false;

  //-------------------------------------------------------------
  // Displays the release notes window.
  public ReleaseNotes( MainWindow win ) {

    Object(
      title:          _( "Release Notes" ),
      transient_for:  win,
      modal:          true,
      default_width:  800,
      default_height: 600
    );

    _notes = new Array<string>();

    var settings = new WebKit.Settings() {
      enable_javascript                     = false,
      allow_file_access_from_file_urls      = true,
      allow_universal_access_from_file_urls = true,
      enable_developer_extras               = false
    };

    _viewer = new WebKit.WebView() {
      halign   = Align.FILL,
      valign   = Align.FILL,
      hexpand  = true,
      vexpand  = true,
      settings = settings
    };

    // Suppress displaying the contextual menu to avoid issues
    _viewer.context_menu.connect( (menu, hit) => {
      return( true );
    });

    var box = new Box( Orientation.VERTICAL, 0 );
    box.append( _viewer );

    get_content_area().append( box );

    var close_button = (Gtk.Button)add_button( _("Close"), Gtk.ResponseType.CLOSE );
    close_button.clicked.connect(() => {
      destroy();
    });

    load_xml();

  }

  //-------------------------------------------------------------
  // Opens the appdata file and extract the release notes so that
  // we can output it to the web view.
  private void load_xml() {

    var file = File.new_for_uri( "resource:///io/github/phase1geo/minder/appdata.xml" );

    file.load_contents_async.begin( null, (obj, res) => {
      try {
        uint8[] contents;
        string  etag_out;
        if( file.load_contents_async.end( res, out contents, out etag_out ) ) {
          parse_xml( (string)contents );
          _viewer.load_html( make_html(), null );
        } else {
          stdout.printf( "ERROR: Unable to load resource file contents\n" );
        }
      } catch( Error e ) {
        stdout.printf( "ERROR: %s\n", e.message );
      }
    });

  }

  //-------------------------------------------------------------
  // Parses the release notes contents, extracting release information
  // as it finds it.
  private bool parse_xml( string contents ) {

    Xml.Doc* doc = Xml.Parser.read_memory( contents, contents.length, null, null, (Xml.ParserOption.HUGE | Xml.ParserOption.NOWARNING) );
    if( doc == null ) {
      return( false );
    }

    Xml.Node* root = doc->get_root_element();

    for( Xml.Node* it1 = root->children; it1 != null; it1 = it1->next ) {
      if( (it1->type == Xml.ElementType.ELEMENT_NODE) && (it1->name == "releases") ) {
        for( Xml.Node* it2 = it1->children; it2 != null; it2 = it2->next ) {
          if( (it2->type == Xml.ElementType.ELEMENT_NODE) && (it2->name == "release") ) {
            var version = it2->get_prop( "version" );
            var date    = it2->get_prop( "date" );
            for( Xml.Node* it3 = it2->children; it3 != null; it3 = it3->next ) {
              if( (it3->type == Xml.ElementType.ELEMENT_NODE) && (it3->name == "description") ) {
                var html = make_release_html( it3, version, date );
                _notes.append_val( html );
              }
            }
          }
        }
      }
    }

    delete doc;

    return( true );

  }

  //-------------------------------------------------------------
  // Create the HTML document
  private string make_html() {

    string[] body = {};

    if( _notes.length > 0 ) {
      if( _show_current ) {
        body += _notes.index( 0 );
      } else {
        for( int i=0; i<_notes.length; i++ ) {
          body += _notes.index( i );
        }
      }
    }

    return( "<html><head/><body>%s</body></html>".printf( string.joinv( "<br/><hr/><br/>", body ) ) );

  }

  //-------------------------------------------------------------
  // Create the HTML document
  private string make_release_html( Xml.Node* description, string version, string date ) {

    Xml.Doc*  doc   = new Xml.Doc( "1.0" );
    Xml.Node* body  = new Xml.Node( null, "body" );

    doc->set_root_element( body );

    add_release( body, description, true, version, date );

    string html = "";
    doc->dump_memory_format( out html );
    delete doc;

    var lines = html.split( "\n" );

    return( string.joinv( "\n", lines[2:lines.length-1] ) );

  }

  //-------------------------------------------------------------
  // Appends the description information to the body.
  private void add_release( Xml.Node* body, Xml.Node* description, bool first, string version, string date ) {

    Xml.Node* h1 = new Xml.Node( null, "h1" ); 
    Xml.Node* p  = new Xml.Node( null, "p" );
    Xml.Node* i  = new Xml.Node( null, "i" );
    Xml.Node* br = new Xml.Node( null, "br" );

    h1->set_content( _( "Release %s" ).printf( version ) );
    body->add_child( h1 );

    i->set_content( date );
    p->add_child( i );
    body->add_child( p );

    body->add_child( br );

    for( Xml.Node* it = description->children; it != null; it = it->next ) {
      Xml.Node* node = it->copy( 1 );
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "p") ) {
        node->set_name( "h3" );
      }
      body->add_child( node );
    }

  }

}
