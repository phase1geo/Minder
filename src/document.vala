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

using Cairo;
using Gtk;

public class Document : Object {

  private DrawArea _da;

  /* Properties */
  public string filename    { set; get; default = ""; }
  public bool   save_needed { private set; get; default = false; }

  /* Default constructor */
  public Document( DrawArea da ) {
    _da = da;
    _da.changed.connect( canvas_changed );
  }

  /* Called whenever the canvas changes such that a save will be needed */
  private void canvas_changed() {
    save_needed = true;
  }

  /* Returns true if this document has been previously saved */
  public bool saved() {
    return( filename != "" );
  }

  /* Opens the given filename */
  public bool load() {
    if( filename == "" ) {
      return( false );
    }
    Xml.Doc* doc = Xml.Parser.parse_file( filename );
    if( doc == null ) {
      return( false );
    }
    _da.load( doc->get_root_element() );
    delete doc;
    return( true );
  }

  /* Called on application launch to see if we can load an auto-saved application */
  public void auto_load() {
    string fname = (filename == "") ? ".minder.bak" : "." + filename + ".bak";
    // FOOBAR
  }

  /* Saves the given node information to the specified file */
  private bool save_with_filename( string fname ) {
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "minder" );
    doc->set_root_element( root );
    _da.save( root );
    doc->save_format_file( fname, 1 );
    delete doc;
    return( true );
  }

  /* Saves the state of the document */
  public bool save() {
    if( filename == "" ) {
      return( false );
    }
    return( save_with_filename( filename ) );
  }

  /* Auto-saves the document using either a temporary name or a backup file */
  public void auto_save() {
    if( save_needed ) {
      if( filename == "" ) {
        save_with_filename( ".minder.bak" );
      } else {
        save_with_filename( "." + filename + ".bak" );
      }
    }
  }

  /* Draws the page to the printer */
  public void draw_page( PrintOperation op, PrintContext context, int nr ) {

    Context ctx = context.get_cairo_context();
    double  w   = context.get_width();
    double  h   = context.get_height();

    ctx.set_source_rgb( 0.5, 0.5, 1 );
    ctx.rectangle( (w * 0.1), (h * 0.1), (w * 0.8), (h * 0.8) );
    ctx.stroke();

  }

}
