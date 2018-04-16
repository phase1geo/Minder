public class Themes : Object {

  private Array<Theme> _themes;
  
  /* Default constructor */
  public Themes() {
    _themes = new Array<Theme>();
    _themes.append_val( new ThemeDefault() );
  }
  
  /* Returns a list of theme names */
  public void names( out Array<string> names ) {
    for( int i=0; i<_themes.length; i++ ) {
      names.append_val( _themes.index( i ).name );
    }
  }
  
  /* Returns a list of icons associated with each of the loaded themes */
  public void icons( out Array<Image> icons ) {
    for( int i=0; i<_themes.length; i++ ) {
      icons.append_val( _themes.index( i ).icon );
    }
  }
  
  /* Returns the theme associated with the given name */
  public Theme get_theme( string name ) {
    for( int i=0; i<_themes.length; i++ ) {
      if( name == _themes.index( i ).name ) {
        return( _themes.index( i ) );
      }
    }
    return( _themes.index( 0 ) );
  }
  
}