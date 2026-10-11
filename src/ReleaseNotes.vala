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

  public class ReleaseNote {
    public string version { get; private set; default = ""; }
    public string date    { get; private set; default = ""; }
    public string html    { get; private set; default = ""; }
    public ReleaseNote( string v, string d, string h ) {
      version = v;
      date    = d;
      html    = h;
    }
  }

  private WebKit.WebView     _viewer;
  private Array<ReleaseNote> _releases;

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

    _releases = new Array<ReleaseNote>();

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
          if( _releases.length > 0 ) {
            _viewer.load_html( _releases.index( 0 ).html, null );
          }
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
                var html = make_html( it3, version, date );
                var release = new ReleaseNote( version, date, html );
                _releases.append_val( release );
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
  private string make_html( Xml.Node* description, string version, string date ) {

    Xml.Doc*  doc   = new Xml.Doc( "1.0" );
    Xml.Node* root  = new Xml.Node( null, "html" );
    Xml.Node* head  = new Xml.Node( null, "head" );
    Xml.Node* body  = new Xml.Node( null, "body" );
    Xml.Node* title = new Xml.Node( null, "h1" ); 
    Xml.Node* hr    = new Xml.Node( null, "hr" );

    doc->set_root_element( root );
    root->add_child( head );
    root->add_child( body );

    title->set_content( _( "Release %s (%s)" ).printf( version, date ) );
    body->add_child( title );
    body->add_child( hr );

    for( Xml.Node* it = description->children; it != null; it = it->next ) {
      Xml.Node* node = it->copy( 1 );
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "p") ) {
        node->set_name( "h3" );
      }
      body->add_child( node );
    }

    string html = "";
    doc->dump_memory_format( out html );

    delete doc;

    return( html );

  }

}
