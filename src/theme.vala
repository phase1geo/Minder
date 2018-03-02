using Gdk;

public class Theme : Object {

  private int _index;

  public    string name               { protected set; get; }
  public    RGBA   background         { protected set; get; }
  public    RGBA   foreground         { protected set; get; }
  public    RGBA   root_background    { protected set; get; }
  public    RGBA   root_foreground    { protected set; get; }
  public    RGBA   nodesel_background { protected set; get; }
  public    RGBA   nodesel_foreground { protected set; get; }
  public    RGBA   textsel_background { protected set; get; }
  public    RGBA   textsel_foreground { protected set; get; }
  public    RGBA   text_cursor        { protected set; get; }
  protected RGBA[] link_colors        { set; get; }

  /* Default constructor */
  public Theme() {
    _index = 0;
  }

  /* Returns the next available link color index */
  public int next_color_index() {
    return( _index++ );
  }

  /* Returns the color associated with the given index */
  public RGBA link_color( int index ) {
    return( link_colors[index % link_colors.length] );
  }

}
