using Gdk;

public class ColorPalette : Object {

  // private int  _index = 0;
  private RGBA _color;

  public ColorPalette() {
    _color.red   = 0;
    _color.green = 0;
    _color.blue  = 0;
    _color.alpha = 1;
  }

  /* Returns the next color to use */
  public RGBA next() {
    _color.red = 255.0;
    return( _color );
  }

}
