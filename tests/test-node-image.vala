/*
* Copyright (c) 2018-2026 (https://github.com/phase1geo/Minder)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*/

using Cairo;
using Gdk;

namespace MinderTest {

  public class NodeImageTest : TestSuite {

    private string _temp_dir;

    public NodeImageTest() {
      this.add_test( "svg-vector-output", test_svg_vector_output );
      this.add_test( "svgz-vector-output", test_svgz_vector_output );
      this.add_test( "svg-content-detection", test_svg_content_detection );
      this.add_test( "svg-large-intrinsic-size", test_svg_large_intrinsic_size );
      this.add_test( "svg-crop", test_svg_crop );
      this.add_test( "svg-transparency", test_svg_transparency );
      this.add_test( "svg-color-scheme", test_svg_color_scheme );
      this.add_test( "resizable-xml", test_resizable_xml );
      this.add_test( "png-raster-output", test_png_raster_output );
    }

    public override void setup() {
      Minder.settings = new Settings( "io.github.phase1geo.minder" );
      Minder.settings.set_int( "image-id", 1 );
      try {
        _temp_dir = DirUtils.make_tmp( "minder-node-image-test-XXXXXX" );
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

    private string draw_to_svg( NodeImage image, string basename, double opacity = 1.0,
                                bool dark = false ) {
      var filename = GLib.Path.build_filename( _temp_dir, basename );
      var surface  = new SvgSurface( filename, 240, 240 );
      var context  = new Context( surface );
      image.draw( context, 20, 20, opacity, dark );
      context.show_page();
      surface.finish();
      string contents;
      FileUtils.get_contents( filename, out contents );
      return( contents );
    }

    private Pixbuf draw_to_pixbuf( NodeImage image, string basename, double opacity = 1.0,
                                   bool dark = false ) {
      var filename = GLib.Path.build_filename( _temp_dir, basename );
      var surface  = new ImageSurface( Format.ARGB32, 240, 240 );
      var context  = new Context( surface );
      image.draw( context, 20, 20, opacity, dark );
      surface.write_to_png( filename );
      return( new Pixbuf.from_file( filename ) );
    }

    private uint8 pixel_channel( Pixbuf pixbuf, int x, int y, int channel ) {
      unowned uint8[] pixels = pixbuf.get_pixels();
      return( pixels[(y * pixbuf.rowstride) + (x * pixbuf.n_channels) + channel] );
    }

    private NodeImage load_image( string filename, int width ) {
      var manager = new ImageManager();
      manager.set_image_dir( _temp_dir );
      var id = manager.add_image( File.new_for_path( filename ).get_uri() );
      return( new NodeImage( manager, id, width ) );
    }

    private void test_svg_vector_output() {
      var filename = GLib.Path.build_filename( _temp_dir, "source.svg" );
      FileUtils.set_contents(
        filename,
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\">" +
        "<rect x=\"1\" y=\"1\" width=\"22\" height=\"22\" fill=\"red\"/>" +
        "</svg>"
      );
      var image = load_image( filename, 200 );
      var svg   = draw_to_svg( image, "vector-output.svg" );
      Assert.true( image.vector );
      Assert.true( svg.contains( "<path" ) );
      Assert.false( svg.contains( "<image" ) );
      var copied = image.get_orig_pixbuf();
      Assert.int_compare( 1024, copied.width );
      Assert.int_compare( 1024, copied.height );
    }

    private void test_svgz_vector_output() {
      var filename   = GLib.Path.build_filename( _temp_dir, "source.svgz" );
      var file       = File.new_for_path( filename );
      var output     = file.replace( null, false, FileCreateFlags.NONE );
      var compressor = new ZlibCompressor( ZlibCompressorFormat.GZIP, -1 );
      var stream     = new ConverterOutputStream( output, compressor );
      var source     =
        "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 24 12\">" +
        "<rect width=\"24\" height=\"12\" fill=\"blue\"/>" +
        "</svg>";
      size_t bytes_written;
      stream.write_all( source.data, out bytes_written );
      stream.close();
      var image = load_image( filename, 200 );
      var svg   = draw_to_svg( image, "svgz-output.svg" );
      Assert.true( image.valid );
      Assert.true( image.vector );
      Assert.true( svg.contains( "<path" ) );
      Assert.false( svg.contains( "<image" ) );
    }

    private void test_svg_content_detection() {
      var filename = GLib.Path.build_filename( _temp_dir, "extensionless" );
      FileUtils.set_contents(
        filename,
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"40\" height=\"20\">" +
        "<rect width=\"40\" height=\"20\" fill=\"green\"/>" +
        "</svg>"
      );
      var image = load_image( filename, 200 );
      Assert.true( image.valid );
      Assert.true( image.vector );
      Assert.int_compare( 40, image.orig_width );
      Assert.int_compare( 20, image.orig_height );
    }

    private void test_svg_large_intrinsic_size() {
      var filename = GLib.Path.build_filename( _temp_dir, "large.svg" );
      FileUtils.set_contents(
        filename,
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"50000\" height=\"25000\">" +
        "<rect width=\"50000\" height=\"25000\" fill=\"green\"/>" +
        "</svg>"
      );
      var image = load_image( filename, 200 );
      Assert.true( image.valid );
      Assert.true( image.vector );
      Assert.int_compare( 50000, image.orig_width );
      Assert.int_compare( 25000, image.orig_height );
      Assert.int_compare( 200, image.width );
      Assert.int_compare( 100, image.height );
    }

    private void test_svg_crop() {
      var filename = GLib.Path.build_filename( _temp_dir, "crop.svg" );
      FileUtils.set_contents(
        filename,
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\">" +
        "<rect width=\"12\" height=\"24\" fill=\"red\"/>" +
        "<rect x=\"12\" width=\"12\" height=\"24\" fill=\"blue\"/>" +
        "</svg>"
      );
      var image = load_image( filename, 200 );
      image.crop_x = 12;
      image.crop_w = 12;
      image.set_width( 100 );
      var pixbuf = draw_to_pixbuf( image, "crop-output.png" );
      Assert.int_compare( 0, pixel_channel( pixbuf, 70, 70, 0 ) );
      Assert.int_compare( 0, pixel_channel( pixbuf, 70, 70, 1 ) );
      Assert.int_compare( 255, pixel_channel( pixbuf, 70, 70, 2 ) );
      var svg = draw_to_svg( image, "crop-output.svg" );
      Assert.true( svg.contains( "<path" ) );
      Assert.false( svg.contains( "<image" ) );
      var exported = new Pixbuf.from_file(
        GLib.Path.build_filename( _temp_dir, "crop-output.svg" )
      );
      Assert.int_compare( 0, pixel_channel( exported, 70, 70, 0 ) );
      Assert.int_compare( 0, pixel_channel( exported, 70, 70, 1 ) );
      Assert.int_compare( 255, pixel_channel( exported, 70, 70, 2 ) );
    }

    private void test_svg_transparency() {
      var filename = GLib.Path.build_filename( _temp_dir, "transparency.svg" );
      FileUtils.set_contents(
        filename,
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\">" +
        "<rect width=\"24\" height=\"24\" fill=\"red\"/>" +
        "</svg>"
      );
      var image  = load_image( filename, 100 );
      var pixbuf = draw_to_pixbuf( image, "transparency-output.png", 0.5 );
      var alpha  = pixel_channel( pixbuf, 70, 70, 3 );
      Assert.true( (alpha >= 126) && (alpha <= 129) );
      var svg = draw_to_svg( image, "transparency-output.svg", 0.5 );
      Assert.true( svg.contains( "<path" ) );
      Assert.false( svg.contains( "<image" ) );
      var exported = new Pixbuf.from_file(
        GLib.Path.build_filename( _temp_dir, "transparency-output.svg" )
      );
      var exported_alpha = pixel_channel( exported, 70, 70, 3 );
      Assert.true( (exported_alpha >= 126) && (exported_alpha <= 129) );
    }

    private void test_svg_color_scheme() {
      var filename = GLib.Path.build_filename( _temp_dir, "color-scheme.svg" );
      var source =
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\">" +
        "<style>.shape { fill: #000; }" +
        "@media (prefers-color-scheme: dark) { .shape { fill: #fff; } }</style>" +
        "<rect class=\"shape\" width=\"24\" height=\"24\"/>" +
        "</svg>";
      FileUtils.set_contents( filename, source );
      var image = load_image( filename, 100 );
      var light = draw_to_pixbuf( image, "color-scheme-light.png" );
      var dark  = draw_to_pixbuf( image, "color-scheme-dark.png", 1.0, true );
      Assert.int_compare( 0, pixel_channel( light, 70, 70, 0 ) );
      Assert.int_compare( 255, pixel_channel( dark, 70, 70, 0 ) );

      draw_to_svg( image, "color-scheme-dark.svg", 1.0, true );
      var exported = new Pixbuf.from_file(
        GLib.Path.build_filename( _temp_dir, "color-scheme-dark.svg" )
      );
      Assert.int_compare( 255, pixel_channel( exported, 70, 70, 0 ) );

      var svgz_file  = File.new_for_path(
        GLib.Path.build_filename( _temp_dir, "color-scheme.svgz" )
      );
      var output     = svgz_file.replace( null, false, FileCreateFlags.NONE );
      var compressor = new ZlibCompressor( ZlibCompressorFormat.GZIP, -1 );
      var stream     = new ConverterOutputStream( output, compressor );
      size_t bytes_written;
      stream.write_all( source.data, out bytes_written );
      stream.close();
      var compressed = load_image( svgz_file.get_path(), 100 );
      var svgz_dark  = draw_to_pixbuf(
        compressed, "color-scheme-svgz-dark.png", 1.0, true
      );
      Assert.int_compare( 255, pixel_channel( svgz_dark, 70, 70, 0 ) );
    }

    private void test_resizable_xml() {
      var filename = GLib.Path.build_filename( _temp_dir, "resizable.svg" );
      FileUtils.set_contents(
        filename,
        "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\"/>"
      );
      var manager = new ImageManager();
      manager.set_image_dir( _temp_dir );
      var id = manager.add_image( File.new_for_path( filename ).get_uri() );
      var fixed_xml = "<nodeimage id=\"%d\" x=\"0\" y=\"0\" w=\"24\" h=\"24\" size=\"80\"/>".printf( id );
      Xml.Doc* fixed_doc = Xml.Parser.parse_memory( fixed_xml, fixed_xml.length );
      var fixed_image = new NodeImage.from_xml(
        manager, fixed_doc->get_root_element(), 200
      );
      Assert.false( fixed_image.resizable );
      Assert.int_compare( 80, fixed_image.width );
      delete fixed_doc;

      var flexible_xml = "<nodeimage id=\"%d\" x=\"0\" y=\"0\" w=\"24\" h=\"24\"/>".printf( id );
      Xml.Doc* flexible_doc = Xml.Parser.parse_memory( flexible_xml, flexible_xml.length );
      var flexible_image = new NodeImage.from_xml(
        manager, flexible_doc->get_root_element(), 200
      );
      Assert.true( flexible_image.resizable );
      Assert.int_compare( 200, flexible_image.width );
      delete flexible_doc;
    }

    private void test_png_raster_output() {
      var filename = GLib.Path.build_filename( _temp_dir, "source.png" );
      var pixbuf   = new Pixbuf( Colorspace.RGB, true, 8, 24, 24 );
      pixbuf.fill( (uint32)0xff0000ff );
      pixbuf.save( filename, "png" );
      var image = load_image( filename, 200 );
      var svg   = draw_to_svg( image, "raster-output.svg" );
      Assert.false( image.vector );
      Assert.true( svg.contains( "<image" ) );
    }

  }

}
