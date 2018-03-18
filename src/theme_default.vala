using Gdk;

public class ThemeDefault : Theme {

  /* Create the theme colors */
  public ThemeDefault() {

    name = "Default";

    /* Generate the non-link colors */
    background         = get_color( "Grey" );
    foreground         = get_color( "White" );
    root_background    = get_color( "White" );
    root_foreground    = get_color( "Black" );
    nodesel_background = get_color( "Light Blue" );
    nodesel_foreground = get_color( "Black" );
    textsel_background = get_color( "Blue" );
    textsel_foreground = get_color( "White" );
    text_cursor        = get_color( "Green" );

    /* Generate the link colors */
    link_colors = new RGBA[8];
    link_colors[0] = get_color( "Red" );
    link_colors[1] = get_color( "Orange" );
    link_colors[2] = get_color( "Yellow" );
    link_colors[3] = get_color( "Green" );
    link_colors[4] = get_color( "Blue" );
    link_colors[5] = get_color( "Purple" );
    link_colors[6] = get_color( "Brown" );
    link_colors[7] = get_color( "Black" );

  }

}
