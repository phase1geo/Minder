using Gdk;

public class ColorPalette : Object {

  // private int  _index = 0;
  private RGBA   _color;
  private RGBA[] _colors;
  private int    _index = 0;

  public ColorPalette() {
    /*
    _color.red   = 0;
    _color.green = 0;
    _color.blue  = 0;
    _color.alpha = 1;
    */
    RGBA color = {0.0, 0.0, 0.0, 1.0};
    color.parse( "red" );     _colors += color;
    color.parse( "orange" );  _colors += color;
    color.parse( "yellow" );  _colors += color;
    color.parse( "green" );   _colors += color;
    color.parse( "blue" );    _colors += color;
    color.parse( "purple" );  _colors += color;
  }

  /* Returns the next color to use */
  public RGBA next() {
    RGBA color = _colors[_index];
    _index = (_index + 1) % _colors.length;
    return( color );
  }

}
