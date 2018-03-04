using Gdk;

public class ThemeDefault : Theme {

  /* Create the theme colors */
  public ThemeDefault() {

    name = "Default";

    /* Generate the non-link colors */
    background.parse( "Gray" );
    foreground.parse( "White" );
    root_background.parse( "White" );
    root_foreground.parse( "Black" );
    nodesel_background.parse( "Light Blue" );
    nodesel_foreground.parse( "Black" );
    textsel_background.parse( "Blue" );
    textsel_foreground.parse( "White" );
    text_cursor.parse( "Green" );

    /* Generate the link colors */
    link_colors = new RGBA[8];
    link_colors[0].parse( "Red" );
    link_colors[1].parse( "Orange" );
    link_colors[2].parse( "Yellow" );
    link_colors[3].parse( "Green" );
    link_colors[4].parse( "Blue" );
    link_colors[5].parse( "Purple" );
    link_colors[6].parse( "Brown" );
    link_colors[7].parse( "Black" );

    stdout.printf( "HERE root_background, red: %g, green: %g, blue: %g, alpha: %g\n",
      root_background.red, root_background.green, root_background.blue, root_background.alpha );

  }

}
