using Gtk;

public class LayoutInspector : Grid {

  private DrawArea? _da = null;

  public LayoutInspector( DrawArea da ) {

    _da = da;

    Label lbl = new Label( "LAYOUTS" );

    attach( lbl, 0, 0, 1, 1 );

  }

}
