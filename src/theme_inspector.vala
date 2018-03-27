using Gtk;

public class ThemeInspector : Grid {

  private DrawArea? _da = null;

  public ThemeInspector( DrawArea da ) {

    _da = da;

    Label lbl = new Label( "THEMES" );

    attach( lbl, 0, 0, 1, 1 );

  }

}
