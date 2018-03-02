using Gdk;

public class ThemeDefault : Theme {

  /* Create the theme colors */
  public ThemeDefault() {

    name = "Default";

    /* Generate the non-link colors */
    background.parse( "grey" );
    foreground.parse( "white" );
    root_background.parse( "white" );
    root_foreground.parse( "black" );
    nodesel_background.parse( "light blue" );
    nodesel_foreground.parse( "black" );
    textsel_background.parse( "blue" );
    textsel_foreground.parse( "white" );
    text_cursor.parse( "green" );

    /* Generate the link colors */
    link_colors = new RGBA[8];
    link_colors[0].parse( "red" );
    link_colors[1].parse( "orange" );
    link_colors[2].parse( "yellow" );
    link_colors[3].parse( "green" );
    link_colors[4].parse( "blue" );
    link_colors[5].parse( "purple" );
    link_colors[6].parse( "brown" );
    link_colors[7].parse( "black" );

  }

}
