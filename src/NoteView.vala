/*
* Copyright (c) 2017 Lains
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*/

using Gtk;
using Gdk;
using Gee;

public class CompletionItem : GtkSource.CompletionProposal, Object {

  public string label { get; private set; default = ""; }
  public string text  { get; private set; default = ""; }

  //-------------------------------------------------------------
  // Constructor
  public CompletionItem( string label, string text ) {
    this.label = label;
    this.text  = text;
  }

}

public class CompletionItemFilter : Filter {

  private string _match_str = "";

  //-------------------------------------------------------------
  // Constructor
  public CompletionItemFilter() {}

  //-------------------------------------------------------------
  // Provide functionality for get_strictness() virtual method.
  public override FilterMatch get_strictness() {
    return( FilterMatch.SOME );
  }

  //-------------------------------------------------------------
  // Called to set the match string.
  public void set_search( string match_str ) {
    if( _match_str != match_str ) {
      _match_str = match_str;
      changed( FilterChange.DIFFERENT );
    }
  }

  //-------------------------------------------------------------
  // Returns true if the specified item matches the match_str.
  public override bool match( Object? item ) {
    if( item != null ) {
      var comp_item = (item as CompletionItem);
      if( comp_item != null ) {
        return( comp_item.label.has_prefix( _match_str ) );
      }
    }
    return( false );
  }

}

public class CompletionProvider : GtkSource.CompletionProvider, Object {

  private MainWindow                _win;
  private string                    _name;
  private GLib.List<CompletionItem> _proposals;
  private GtkSource.Buffer          _buffer;

  //-------------------------------------------------------------
  // Constructor
  public CompletionProvider( MainWindow win, GtkSource.Buffer buffer, string name, GLib.List<CompletionItem> proposals ) {
    _win       = win;
    _buffer    = buffer;
    _name      = name;
    _proposals = new GLib.List<CompletionItem>();
    foreach( var item in proposals ) {
      _proposals.append( item );
    }
  }

  //-------------------------------------------------------------
  // Returns the title of the completion provider.
  public override string? get_title() {
    return( _name );
  }

  //-------------------------------------------------------------
  // Returns the priority of the completion provider.
  public override int get_priority( GtkSource.CompletionContext context ) {
    return( 1 );
  }

  //-------------------------------------------------------------
  // We will only trigger the completion if unicode input completion
  // is enabled and we see the backslash character.
  public override bool is_trigger( TextIter iter, unichar ch ) {
    stdout.printf( "In is_trigger, ch: %s\n", ch.to_string() );
    return( _win.settings.get_boolean( "enable-unicode-input" ) && (ch == '\\') );
  }

  //-------------------------------------------------------------
  // Hitting the return key will activate the completion (if a
  // proposal is selected).
  public override bool key_activates( GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal, uint keyval, ModifierType state ) {
    return( keyval == Gdk.Key.Return );
  }

  //-------------------------------------------------------------
  // I don't know what this is supposed to do, but we will just
  // return null.
  public GenericArray<GtkSource.CompletionProposal>? list_alternatives( GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal ) {
    return( null );
  }

  //-------------------------------------------------------------
  // Populate the list of potential matches.
  public async ListModel populate_async( GtkSource.CompletionContext context, Cancellable? cancellable ) throws Error {
    TextIter start_iter, end_iter;
    var proposals = new GLib.ListStore( typeof(CompletionItem) );
    foreach( var item in _proposals ) {
      proposals.append( item );
    }
    var filter = new CompletionItemFilter();
    filter.set_search( "\\" + context.get_word() );
    var filter_model = new Gtk.FilterListModel( proposals, filter );
    return( filter_model );
  }

  //-------------------------------------------------------------
  // Called whenever the user changes the current word.  We will
  // update the filter with the current word to change the list
  // of displayed proposals.
  public void refilter( GtkSource.CompletionContext context, ListModel model ) {
    var list = (model as Gtk.FilterListModel);
    if( list != null ) {
      var filter = (list.filter as CompletionItemFilter);
      if( filter != null ) {
        filter.set_search( "\\" + context.get_word() );
      }
    }
  }

  //-------------------------------------------------------------
  // Called whe the user hits the return key.  We will replace the
  // current word (including the previous backslash character) with
  // the proposal text.
  public void activate( GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal ) {

    var item = (proposal as CompletionItem);

    if( item != null ) {

      TextIter start_iter, end_iter;
      context.get_bounds( out start_iter, out end_iter );
      start_iter.backward_char();

      var buffer = start_iter.get_buffer();
      buffer.begin_user_action();
      buffer.delete( ref start_iter, ref end_iter );
      buffer.insert_text( ref start_iter, item.text, item.text.length );
      buffer.end_user_action();

    }

  }

  //-------------------------------------------------------------
  // Displays the proposals in a dropdown list.
  public void display( GtkSource.CompletionContext context, GtkSource.CompletionProposal proposal, GtkSource.CompletionCell cell ) {
    var item = (proposal as CompletionItem);
    if( item != null ) {
      switch( cell.get_column() ) {
        case GtkSource.CompletionColumn.TYPED_TEXT:  cell.text = item.text;  break;
        default                                   :  cell.text = null;  break;
      }
    }
  }

}

//-------------------------------------------------------------
// This class is a slightly modified version of Lains Quilter
// SourceView.vala file.  The above header was kept in tact to
// indicate this.
public class NoteView : GtkSource.View {

  private class UrlPos {
    public string url;
    public int    start;
    public int    end;
    public UrlPos( string u, int s, int e ) {
      url   = u;
      start = s;
      end   = e;
    }
  }

  private class LinkPos {
    public int id;
    public int start;
    public int end;
    public LinkPos( int i, int s, int e ) {
      id    = i;
      start = s;
      end   = e;
    }
  }

  private static bool      _path_init = false;
  private int              _last_lnum = -1;
  private string?          _last_url  = null;
  private int?             _last_link = null;
  private Array<UrlPos>    _last_urls;
  private Array<LinkPos>   _last_links;
  private int              _last_x;
  private int              _last_y;
  private Regex?           _url_re;
  private Regex?           _link_re;
  private Tooltip          _tooltip;
  private bool             _control   = false;
  public  GtkSource.Style  _srcstyle  = null;
  public  GtkSource.Buffer _buffer;

  public string text {
    set {
      buffer.text = value;
    }
    owned get {
      return( buffer.text );
    }
  }

  public bool modified {
    set {
      buffer.set_modified( value );
      clear();
    }
    get {
      return( buffer.get_modified() );
    }
  }

  public signal int node_link_added( NodeLink link, out string text );
  public signal void node_link_clicked( int id );
  public signal void node_link_hover( int id );

  /* Default constructor */
  public NoteView() {

    var sourceview_path = GLib.Path.build_filename( Environment.get_user_data_dir(), "minder", "gtksourceview-4" );

    foreach( var data_dir in Environment.get_system_data_dirs() ) {
      sourceview_path = GLib.Path.build_filename( data_dir, "minder", "gtksourceview-4" );
      if( FileUtils.test( sourceview_path, FileTest.EXISTS ) ) {
        break;
      }
    }

    var lang_path  = GLib.Path.build_filename( sourceview_path, "language-specs" );
    var style_path = GLib.Path.build_filename( sourceview_path, "styles" );

    string[] lang_paths = {};

    get_style_context().add_class( "textfield" );

    var manager = GtkSource.LanguageManager.get_default();
    if( !_path_init ) {
      lang_paths = manager.get_search_path();
      lang_paths += lang_path;
      manager.set_search_path( lang_paths );
    }

    var style_manager = GtkSource.StyleSchemeManager.get_default();
    if( !_path_init ) {
      style_manager.prepend_search_path( style_path );
    }

    _path_init = true;

    var language = manager.get_language( get_default_language() );
    var style    = style_manager.get_scheme( get_default_scheme() );

    _buffer = new GtkSource.Buffer.with_language( language ) {
      highlight_syntax = true,
      enable_undo      = true
    };
    _buffer.set_style_scheme( style );
    set_buffer( _buffer );

    modified = false;

    _buffer.changed.connect (() => {
      modified = true;
    });

    var focus = new EventControllerFocus();
    add_controller( focus );
    focus.enter.connect( on_focus );

    var motion = new EventControllerMotion();
    add_controller( motion );
    motion.motion.connect( on_motion );

    var click = new GestureClick();
    add_controller( click );
    click.pressed.connect( on_press );

    var key = new EventControllerKey();
    add_controller( key );
    key.key_pressed.connect( on_keypress );
    key.key_released.connect( on_keyrelease );

    auto_indent = true;
    set_wrap_mode( Gtk.WrapMode.WORD );
    set_tab_width( 4 );
    set_insert_spaces_instead_of_tabs( true );

    try {
      _url_re  = new Regex( Utils.url_re() );
      _link_re = new Regex( "@Node-(\\d+)" );
    } catch( RegexError e ) {
      _url_re  = null;
      _link_re = null;
    }

    _last_urls  = new Array<UrlPos>();
    _last_links = new Array<LinkPos>();

    // Handle any changes to the colorize-notes preference option
    Minder.settings.changed["colorize-notes"].connect(() => {
      var s = style_manager.get_scheme( get_default_scheme() );
      _buffer.set_style_scheme( s );
    });

  }

  /* Returns the Markdown language parser used to highlight the text */
  private string get_default_language() {
    return( "markdown-minder" );
  }

  /* Returns the coloring scheme to use to highlight the text */
  private string get_default_scheme () {
    return( Minder.settings.get_boolean( "colorize-notes" ) ? "minder.color" : "minder.none" );
  }

  /* Clears the URL handler code to force it reparse the current line for URLs */
  private void clear() {
    _last_lnum = -1;
    _last_url  = null;
    _last_link = null;
  }

  /* Returns the string of text for the current line */
  private string current_line( TextIter cursor ) {
    var start = cursor;
    var end   = cursor;
    start.set_line( start.get_line() );
    end.forward_line();
    return( start.get_text( end ).chomp() );
  }

  /*
   Parses all of the URLs in the given line and stores their positions within
   the _last_match_pos private member array.
  */
  private void parse_line_for_urls( string line ) {
    if( _url_re == null ) return;
    MatchInfo match_info;
    var       start = 0;
    _last_urls.remove_range( 0, _last_urls.length );
    try {
      while( _url_re.match_all_full( line, -1, start, 0, out match_info ) ) {
        int s, e;
        match_info.fetch_pos( 0, out s, out e );
        _last_urls.append_val( new UrlPos( line.substring( s, (e - s) ), s, e ) );
        start = e;
      }
    } catch( RegexError e ) {}
  }

  /*
   Parses all of the URLs in the given line and stores their positions within
   the _last_match_pos private member array.
  */
  private void parse_line_for_node_links( string line ) {
    if( _link_re == null ) return;
    MatchInfo match_info;
    var       start = 0;
    _last_links.remove_range( 0, _last_links.length );
    try {
      while( _link_re.match_full( line, -1, start, 0, out match_info ) ) {
        int s, e;
        match_info.fetch_pos( 0, out s, out e );
        var id = match_info.fetch( 1 );
        _last_links.append_val( new LinkPos( int.parse( id ), s, e ) );
        start = e;
      }
    } catch( RegexError e ) {}
  }

  /* Returns true if the specified cursor is within a parsed URL pattern */
  private bool cursor_in_url( TextIter cursor ) {
    var offset = cursor.get_line_offset();
    for( int i=0; i<_last_urls.length; i++ ) {
      var link = _last_urls.index( i );
      if( (link.start <= offset) && (offset < link.end) ) {
        _last_url = link.url;
        return( true );
      }
    }
    _last_url = null;
    return( false );
  }

  /* Returns true if the specified cursor is within a parsed URL pattern */
  private bool cursor_in_node_link( TextIter cursor ) {
    var offset = cursor.get_line_offset();
    for( int i=0; i<_last_links.length; i++ ) {
      var link = _last_links.index( i );
      if( (link.start <= offset) && (offset < link.end) ) {
        _last_link = link.id;
        return( true );
      }
    }
    _last_link = null;
    return( false );
  }

  /* Called when URL checking should be performed on the current line (if necessary) */
  private void enable_url_checking( int x, int y ) {
    TextIter cursor;
    get_iter_at_location( out cursor, x, y );
    if( _last_lnum != cursor.get_line() ) {
      var line = current_line( cursor );
      parse_line_for_urls( line );
      parse_line_for_node_links( line );
      _last_lnum = cursor.get_line();
    }
    var in_node_link = cursor_in_node_link( cursor );
    if( in_node_link ) {
      node_link_hover( _last_link );
    } else {
      tooltip_text = "";
    }
    if( cursor_in_url( cursor ) || in_node_link ) {
      set_cursor( new Gdk.Cursor.from_name( "pointer", null ) );
    } else {
      set_cursor( null );
    }
  }

  /* Called when URL checking should no longer be performed on the current line */
  private void disable_url_checking() {
    set_cursor( null );
    _last_lnum = -1;
    tooltip_text = "";
  }

  /* Adds the unicoder text completion service */
  public void add_unicode_completion( MainWindow win, UnicodeInsert unicoder ) {
    var provider = new CompletionProvider( win, _buffer, "Unicode", unicoder.create_proposals() );
    completion.add_provider( provider );
  }

  /*
   If the cursor is moved in the text viewer when the control key is held down,
   check to see if the cursor is over a URL.
  */
  private void on_motion( double x, double y ) {
    _last_x = (int)x;
    _last_y = (int)y;
    if( _control ) {
      enable_url_checking( _last_x, _last_y );
    } else {
      disable_url_checking();
    }
  }

  /*
   Called when the user clicks with the mouse.  If the cursor is over a URL,
   open the URL in an external application.
  */
  private void on_press( int n_press, double x, double y ) {
    if( _control ) {
      var int_x = (int)x;
      var int_y = (int)y;
      enable_url_checking( int_x, int_y );
      if( _last_url != null ) {
        Utils.open_url( _last_url );
      } else if( _last_link != null ) {
        node_link_clicked( _last_link );
      }
    }
  }

  private bool on_keypress( uint keyval, uint keycode, ModifierType state ) {
    if( keyval == 65507 ) {
      _control = true;
      enable_url_checking( _last_x, _last_y );
    }
    return( false );
  }

  private void on_keyrelease( uint keyval, uint keycode, ModifierType state ) {
    if( keyval == 65507 ) {
      _control = false;
      disable_url_checking();
    }
  }

  /* Clears the stored URL information */
  private void on_focus() {
    clear();
  }

  /* Override the built-int paste operation */
  public override void paste_clipboard() {
    MinderClipboard.paste_into_note( this );
  }

  /* Inserts the given string into the text buffer at the current insertion point */
  public void paste_text( string str ) {
    buffer.insert_at_cursor( str, str.length );
  }

  /* Inserts the given node link at the current insertion point */
  public void paste_node_link( NodeLink link ) {
    string text = "";
    var id  = node_link_added( link, out text );
    var str = "[%s](@Node-%d)".printf( text, id );
    buffer.insert_at_cursor( str, str.length );
  }

  /* Displays the tooltip at the current cursor location */
  public void show_tooltip( string tooltip ) {
    tooltip_text = tooltip;
  }

}
