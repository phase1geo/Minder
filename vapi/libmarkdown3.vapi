[CCode (cprefix = "mkd")]
namespace Markdown3 {

    public enum mkd_flags {
        MKD_NOLINKS,          // don't do link processing, block <a> tags
        MKD_NOIMAGE,          // don't do image processing, block <img>
        MKD_NOPANTS,          // don't run smartypants()
        MKD_NOHTML,           // don't allow raw html through AT ALL
        MKD_NORMAL_LISTITEM,  // disable github-style checkbox lists
        MKD_TAGTEXT,          // process text inside an html tag
        MKD_NO_EXT,           // don't allow pseudo-protocols
        MKD_EXPLICITLIST,     // don't combine numbered/bulletted lists
        MKD_CDATA,            // generate code for xml ![CDATA[...]]
        MKD_NOSUPERSCRIPT,    // no A^B
        MKD_STRICT,           // conform to Markdown standard as implemented in Markdown.pl
        MKD_NOTABLES,         // disallow tables
        MKD_NOSTRIKETHROUGH,  // forbid ~~strikethrough~~
        MKD_1_COMPAT,         // compatibility with MarkdownTest_1.0
        MKD_TOC,              // do table-of-contents processing
        MKD_AUTOLINK,         // make http://foo.com link even without <>s
        MKD_NOHEADER,         // don't process header blocks
        MKD_TABSTOP,          // expand tabs to 4 spaces
        MKD_SAFELINK,         // paranoid check for link protocol
        MKD_NODIVQUOTE,       // forbid >%class% blocks
        MKD_NOALPHALIST,      // forbid alphabetic lists
        MKD_EXTRA_FOOTNOTE,   // enable markdown extra-style footnotes
        MKD_NOSTYLE,          // don't extract <style> blocks
        MKD_DLDISCOUNT,       // enable discount-style definition lists
        MKD_DLEXTRA,          // enable extra-style definition lists
        MKD_FENCEDCODE,       // enabled fenced code blocks
        MKD_IDANCHOR,         // use id= anchors for TOC links
        MKD_GITHUBTAGS,       // allow dash and underscore in element names
        MKD_URLENCODEDANCHOR, // urlencode non-identifier chars instead of replacing with dots
        MKD_LATEX,            // handle embedded LaTeX escapes
        MKD_ALT_AS_TITLE,     // use alt text as the title if no title is listed
        MKD_NR_FLAGS
    }

    [CCode (cheader_filename = "mkdio3.h", cname = "MMIOT", free_function = "mkd_cleanup")]
    public struct mkd_flags_t {
        uint8[MKD_NR_FLAGS] bits;
    }

    [Compact]
    [CCode (cheader_filename = "mkdio3.h", cname = "MMIOT", free_function = "mkd_cleanup")]
    public class Document {

        [CCode (cname = "mkd_string")]
        public Document.format (uint8[] data, mkd_flags_t flag);

        [CCode (cname = "gfm_string")]
        public Document.gfm_format (uint8[] data, mkd_flags_t flag);

        [CCode (cname = "mkd_compile")]
        public void compile (mkd_flags_t flag);

        [CCode (cname = "mkd_document")]
        public int get_document (out unowned string result);
    }
}
