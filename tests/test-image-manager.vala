/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*/

using Gdk;

public class Minder {
  public static Settings settings;
}

public class Utils {
  public static Gtk.FileDialog make_file_chooser( string title, string accept_label ) {
    return( new Gtk.FileDialog() );
  }
}

namespace MinderTest {

  public class ImageManagerTest : TestSuite {

    private string _temp_dir;

    public ImageManagerTest() {
      this.add_test( "unique-image-ids", test_unique_image_ids );
    }

    public override void setup() {
      Minder.settings = new Settings( "com.github.phase1geo.minder" );
      Minder.settings.set_int( "image-id", 11 );
      try {
        _temp_dir = DirUtils.make_tmp( "minder-image-manager-test-XXXXXX" );
      } catch( FileError error ) {
        assert_not_reached();
      }
    }

    public override void teardown() {
      try {
        var directory = File.new_for_path( _temp_dir );
        var enumerator = directory.enumerate_children( FileAttribute.STANDARD_NAME, 0 );
        FileInfo? info;
        while( (info = enumerator.next_file()) != null ) {
          directory.get_child( info.get_name() ).delete();
        }
        directory.delete();
      } catch( Error error ) {
        assert_not_reached();
      }
    }

    private void test_unique_image_ids() {
      var manager = new ImageManager();
      manager.set_image_dir( _temp_dir );

      var images_xml =
        "<images>" +
        "<image id=\"11\" uri=\"\" ext=\".png\"/>" +
        "<image id=\"11\" uri=\"file:///duplicate.svg\" ext=\".svg\"/>" +
        "<image id=\"20\" uri=\"\" ext=\".png\"/>" +
        "</images>";
      Xml.Doc* images_doc = Xml.Parser.parse_memory( images_xml, images_xml.length );
      manager.load( images_doc->get_root_element() );
      delete images_doc;

      Assert.int_compare( 2, (int)manager.get_ids().length );
      Assert.int_compare( 21, Minder.settings.get_int( "image-id" ) );

      var first_svg = GLib.Path.build_filename( _temp_dir, "first.svg" );
      FileUtils.set_contents(
        first_svg,
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\"/>"
      );
      var first_id = manager.add_image( File.new_for_path( first_svg ).get_uri() );
      Assert.int_compare( 21, first_id );
      Assert.true( manager.get_file( first_id ).has_suffix( ".svg" ) );

      Minder.settings.set_int( "image-id", 11 );
      var second_svg = GLib.Path.build_filename( _temp_dir, "second.svg" );
      FileUtils.set_contents(
        second_svg,
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\"/>"
      );
      var second_id = manager.add_image( File.new_for_path( second_svg ).get_uri() );
      Assert.int_compare( 12, second_id );
      Assert.true( manager.get_file( second_id ).has_suffix( ".svg" ) );
    }

  }

}
