/*
* Copyright (c) 2018 (https://github.com/phase1geo/Minder)
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

  public static int list_depth = -1;

  /* Resets to the namespace for parsing */
  public static void reset() {
    list_depth = -1;
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
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "body") ) {
        return( parse_item( it ) );
      }
    }
    return( "" );
  }

  /* Parses the item */
  public static string parse_item( Xml.Node* n ) {
    string text = "";
    stdout.printf( "In parse_item, name: %s\n", n->name );
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      switch( it->type ) {
        case Xml.ElementType.ELEMENT_NODE :
          switch( it->name ) {
            case "p"          :  text += "\n\n" + parse_item( it );  break;
            case "blockquote" :  text += "\n\n> " + parse_item( it );  break;
            case "div"        :  text += "\n\n" + parse_item( it );  break;
            case "strong"     :
            case "b"          :  text += "**" + parse_item( it ) + "**";  break;
            case "em"         :
            case "i"          :  text += "_" + parse_item( it ) + "_";  break;
            case "ul"         :  text += parse_list( it, true );  break;
            case "ol"         :  text += parse_list( it, false );  break;
            case "del"        :  text += "~~" + parse_item( it ) + "~~";  break;
            case "h1"         :  text += "\n\n# " + parse_item( it );  break;
            case "h2"         :  text += "\n\n## " + parse_item( it );  break;
            case "h3"         :  text += "\n\n### " + parse_item( it );  break;
            case "h4"         :  text += "\n\n#### " + parse_item( it );  break;
            case "h5"         :  text += "\n\n##### " + parse_item( it );  break;
            case "h6"         :  text += "\n\n###### " + parse_item( it );  break;
            case "hr"         :  text += "\n\n---\n\n";  break;
            case "br"         :  text += "\n";  break;
            case "a"          :  text += parse_link( it );  break;
            default           :  text += parse_node( it );  break;
          }
          break;
        case Xml.ElementType.TEXT_NODE :
          text += it->content.strip();
          break;
      }
    }
    return( text );
  }

  /* Returns the text for the given list */
  public static string parse_list( Xml.Node* n, bool unordered, int depth = 0 ) {
    var text  = "";
    var index = 1;
    list_depth++;
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      if( (it->type == Xml.ElementType.ELEMENT_NODE) && (it->name == "li") ) {
        if( unordered ) {
          text += "\n" + string.nfill( (list_depth * 4), ' ' ) + "* " + parse_item( it );
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
    string? h = n->get_prop( "href" );
    if( h != null ) {
      return( "[" + parse_item( n ) + "](" + h + ")" );
    }
    return( parse_item( n ) );
  }

  /* Parses a non-Markdown node and output it as HTML */
  public static string parse_node( Xml.Node* n ) {
    string text = "<" + n->name + ">";
    for( Xml.Node* it = n->children; it != null; it = it->next ) {
      stdout.printf( it->type.to_string() );
    }
    return( text + "</" + n->name + ">" );
  }

}
