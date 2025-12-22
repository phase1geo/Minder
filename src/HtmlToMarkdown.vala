/*
* Copyright (c) 2018-2025 (https://github.com/phase1geo/Minder)
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
*
* Authored by: Trevor Williams <phase1geo@gmail.com>
*/

public class HtmlToMarkdown {

  public static int  list_depth = -1;
  public static bool extensions = true;

  /* Resets to the namespace for parsing */
  public static void reset( bool ext = true ) {
    list_depth = -1;
    extensions = ext;
  }

  public static string parse_file( string fname ) {
    var doc  = Xml.Parser.read_file( fname, null, Xml.ParserOption.HUGE );
    var text = "";
    if( doc != null ) {
      text = parse_xml( doc->get_root_element() );
      delete doc;
    }
    return( text );
  }

  /* Expects the entire HTML XML tree and returns the supported Markdown version */
  public static string parse_xml( Xml.Node* n ) {
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name.down() == "body") ) {
        return( parse_item( it ) );
      }
    }
    return( "" );
  }

  /* Parses the item */
  public static string parse_item( Xml.Node* n ) {
    string text = "";
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      switch( it->type ) {
        case Xml.ElementType.ELEMENT_NODE :
          switch( it->name.down() ) {
            case "p"          :  text += "\n\n" + parse_item( it );  break;
            case "blockquote" :  text += "\n\n> " + parse_item( it );  break;
            case "div"        :  text += "\n\n" + parse_item( it );  break;
            case "span"       :  text += parse_item( it );  break;
            case "strong"     :
            case "b"          :  text += "**" + parse_item( it ) + "**";  break;
            case "em"         :
            case "i"          :  text += "_" + parse_item( it ) + "_";  break;
            case "ul"         :  text += parse_list( it, true );  break;
            case "ol"         :  text += parse_list( it, false );  break;
            case "h1"         :  text += "\n\n# " + parse_item( it );  break;
            case "h2"         :  text += "\n\n## " + parse_item( it );  break;
            case "h3"         :  text += "\n\n### " + parse_item( it );  break;
            case "h4"         :  text += "\n\n#### " + parse_item( it );  break;
            case "h5"         :  text += "\n\n##### " + parse_item( it );  break;
            case "h6"         :  text += "\n\n###### " + parse_item( it );  break;
            case "hr"         :  text += "\n\n---\n\n";  break;
            case "br"         :  text += "\n";  break;
            case "a"          :  text += parse_link( it );  break;
            case "code"       :  text += "`" + parse_item( it ) + "`";  break;
            case "img"        :  text += parse_image( it );  break;
            case "pre"        :  text += "\n\n```\n" + parse_item( it ) + "\n```";  break;
            default           :
              if( extensions ) {
                switch( it->name.down() ) {
                  case "del"   :  text += "~~" + parse_item( it ) + "~~";  break;
                  case "table" :  text += "\n\n" + parse_table( it );  break;
                  default      :  text += parse_node( it );  break;
                }
              } else {
                text += parse_node( it );
              }
              break;
          }
          break;
        case Xml.ElementType.TEXT_NODE :
          if( it->content.strip() != "" ) {
            text += it->content;
          }
          break;
        case Xml.ElementType.CDATA_SECTION_NODE :
          text += "\n\n```\n" + it->content + "\n```";
          break;
      }
    }
    return( text.strip() );
  }

  /* Returns the text for the given list */
  public static string parse_list( Xml.Node* n, bool unordered, int depth = 0 ) {
    var text  = "";
    var index = 1;
    list_depth++;
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name.down() == "li") ) {
        if( unordered ) {
          text += "\n" + string.nfill( (list_depth * 4), ' ' ) + "- " + parse_item( it );
        } else {
          text += "\n" + string.nfill( (list_depth * 4), ' ' ) + index.to_string() + ". " + parse_item( it );
        }
        index++;
      }
    }
    list_depth--;
    return( text );
  }

  /* Returns the link text */
  public static string parse_link( Xml.Node* n ) {
    var item = parse_item( n );
    string? h = n->get_prop( "href" );
    if( (h != null) && (h != item) ) {
      return( "[" + item + "](" + h + ")" );
    }
    return( item );
  }

  /* Returns the image text */
  public static string parse_image( Xml.Node* n ) {
    var text  = "";
    string? s = n->get_prop( "src" );
    if( s != null ) {
      string? a = n->get_prop( "alt" );
      if( a != null ) {
        text = "![" + a + "](" + s + ")";
      } else {
        text = "![](" + s + ")";
      }
    }
    return( text );
  }

  public static string parse_table( Xml.Node* n ) {
    var text = "";
    var row  = 0;
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name.down() == "tr") ) {
        int cols;
        text += "|" + parse_table_row( it, out cols ) + "\n";
        if( (row == 0) && (cols > 0) ) {
          text += "|";
          for( int col=0; col<cols; col++ ) {
            text += " - |";
          }
          text += "\n";
        }
        row++;
      }
    }
    return( text.strip() );
  }

  public static string parse_table_row( Xml.Node* n, out int cols ) {
    var text = "";
    cols = 0;
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( it->type == Xml.ElementType.ELEMENT_NODE ) {
        switch( it->name.down() ) {
          case "th" :
          case "td" :
            text += " " + parse_item( it ) + " |";
            cols++;
            break;
        }
      }
    }
    return( text );
  }

  /* Parses a non-Markdown node and output it as HTML */
  public static string parse_node( Xml.Node* n ) {
    return( "<" + n->name + ">" + parse_item( n ) + "</" + n->name + ">" );
  }

}
