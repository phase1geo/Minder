/*
* Copyright (c) 2020-2025 (https://github.com/phase1geo/Minder)
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

public class Exports {

  private Array<Export> _exports;

  /* Constructor */
  public Exports( bool save_settings = true ) {

    _exports = new Array<Export>();

    /* Add the exports */
    add( new ExportCSV(), save_settings );
    add( new ExportFileSystem(), save_settings );
    add( new ExportFreemind(), save_settings );
    add( new ExportFreeplane(), save_settings );
    add( new ExportImage( "jpeg", _( "JPEG" ), { ".jpg", ".jpeg" } ), save_settings );
    add( new ExportMarkdown(), save_settings );
    add( new ExportMermaid(), save_settings );
    add( new ExportOPML(), save_settings );
    add( new ExportOrgMode(), save_settings );
    add( new ExportOutliner(), save_settings );
    add( new ExportPDF(), save_settings );
    add( new ExportPNG(), save_settings );
    add( new ExportPlantUML(), save_settings );
    add( new ExportPortableMinder(), save_settings );
    add( new ExportSVG(), save_settings );
    add( new ExportText(), save_settings );
    add( new ExportWebP(), save_settings );
    add( new ExportXMind8(), save_settings );
    add( new ExportXMind2021(), save_settings );
    add( new ExportYed(), save_settings );

  }

  private void add( Export export, bool save_settings ) {
    if( save_settings ) {
      export.settings_changed.connect(() => {
        save();
      });
    }
    _exports.append_val( export );
  }

  /* Returns the number of stored exports */
  public int length() {
    return( (int)_exports.length );
  }

  /* Returns the export at the given index */
  public Export index( int idx ) {
    return( _exports.index( idx ) );
  }

  /*
   Returns the export as determined by the given name; otherwise, returns null
   if name does not refer to a valid export type.
  */
  public Export? get_by_name( string name ) {
    for( int i=0; i<_exports.length; i++ ) {
      if( _exports.index( i ).name == name ) {
        return( _exports.index( i ) );
      }
    }
    return( null );
  }

  /*
   Returns the index of the export with the given name.
  */
  public int get_index_by_name( string name ) {
    for( int i=0; i<_exports.length; i++ ) {
      if (_exports.index( i ).name == name ) {
        return( i );
      }
    }
    return( -1 );
  }

  /* Gets the save filename and creates the parent directory if it doesn't exist */
  private string? settings_file( bool make_dir ) {
    var dir = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder" );
    if( make_dir && DirUtils.create_with_parents( dir, 0775 ) != 0 ) {
      return( null );
    }
    return( GLib.Path.build_filename( dir, "exports.xml" ) );
  }

  /* Saves the settings to the save file */
  public void save() {
    var sfile = settings_file( true );
    if( sfile == null ) {
      return;
    }
    Xml.Doc*  doc  = new Xml.Doc( "1.0" );
    Xml.Node* root = new Xml.Node( null, "exports" );
    root->set_prop( "version", Minder.version );
    doc->set_root_element( root );
    for( int i=0; i<_exports.length; i++ ) {
      root->add_child( _exports.index( i ).save() );
    }
    doc->save_format_file( sfile, 1 );
    delete doc;
  }

  /* Loads the settings from the save file */
  public void load() {
    var sfile = settings_file( false );
    if( (sfile == null) || !FileUtils.test( sfile, FileTest.EXISTS ) ) return;
    Xml.Doc* doc = Xml.Parser.read_file( sfile, null, Xml.ParserOption.HUGE );
    if( doc == null ) return;
    for( Xml.Node* it=doc->get_root_element()->children; it!=null; it=it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "export") ) {
        var export_name = it->get_prop( "name" );
        for( int i=0; i<_exports.length; i++ ) {
          if( _exports.index( i ).name == export_name ) {
            _exports.index( i ).load( it );
            break;
          }
        }
      }
    }
    delete doc;
  }

}


