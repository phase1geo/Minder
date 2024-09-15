#ifndef _MKDIO_D
#define _MKDIO_D

#include <stdio.h>

#include <inttypes.h>

typedef void MMIOT;

/* special flags for markdown() and mkd_text()
 */
enum {  MKD_NOLINKS=0,		/* don't do link processing, block <a> tags  */
	MKD_NOIMAGE,		/* don't do image processing, block <img> */
	MKD_NOPANTS,		/* don't run smartypants() */
	MKD_NOHTML,		/* don't allow raw html through AT ALL */
	MKD_NORMAL_LISTITEM,	/* disable github-style checkbox lists */
	MKD_TAGTEXT,		/* process text inside an html tag */
	MKD_NO_EXT,		/* don't allow pseudo-protocols */
#define MKD_NOEXT MKD_NO_EXT
	MKD_EXPLICITLIST,	/* don't combine numbered/bulletted lists */
	MKD_CDATA,		/* generate code for xml ![CDATA[...]] */
	MKD_NOSUPERSCRIPT,	/* no A^B */
	MKD_STRICT,		/* conform to Markdown standard as implemented in Markdown.pl */
	MKD_NOTABLES,		/* disallow tables */
	MKD_NOSTRIKETHROUGH,	/* forbid ~~strikethrough~~ */
	MKD_1_COMPAT,		/* compatibility with MarkdownTest_1.0 */
	MKD_TOC,		/* do table-of-contents processing */
	MKD_AUTOLINK,		/* make http://foo.com link even without <>s */
	MKD_NOHEADER,		/* don't process header blocks */
	MKD_TABSTOP,		/* expand tabs to 4 spaces */
	MKD_SAFELINK,		/* paranoid check for link protocol */
	MKD_NODIVQUOTE,		/* forbid >%class% blocks */
	MKD_NOALPHALIST,	/* forbid alphabetic lists */
	MKD_EXTRA_FOOTNOTE,	/* enable markdown extra-style footnotes */
	MKD_NOSTYLE,		/* don't extract <style> blocks */
	MKD_DLDISCOUNT,		/* enable discount-style definition lists */
	MKD_DLEXTRA,		/* enable extra-style definition lists */
	MKD_FENCEDCODE,		/* enabled fenced code blocks */
	MKD_IDANCHOR,		/* use id= anchors for TOC links */
	MKD_GITHUBTAGS,		/* allow dash and underscore in element names */
	MKD_URLENCODEDANCHOR,	/* urlencode non-identifier chars instead of replacing with dots */
	MKD_LATEX,		/* handle embedded LaTeX escapes */
	MKD_ALT_AS_TITLE,	/* use alt text as the title if no title is listed */
	MKD_NR_FLAGS };

/* abstract flag type */
typedef void mkd_flag_t;

int mkd_flag_isset(mkd_flag_t*, int);		/* check a flag status */

mkd_flag_t *mkd_flags(void);			/* create a flag blob */
mkd_flag_t *mkd_copy_flags(mkd_flag_t*);	/* copy a flag blob */
void mkd_free_flags(mkd_flag_t*);		/* delete a flag blob */
char *mkd_set_flag_string(mkd_flag_t*, char*);	/* set named flags */
void mkd_set_flag_num(mkd_flag_t*, unsigned long);/* set a specific flag */
void mkd_clr_flag_num(mkd_flag_t*, unsigned long);/* clear a specific flag */
void mkd_set_flag_bitmap(mkd_flag_t*,long);	/* set a bunch of flags */

/*
 * sneakily back-define the published interface (leaving the old functions for v2 compatibility)
 */

#define mkd_in mkd3_in
#define mkd_string mkd3_string
#define gfm_in gfm3_in
#define gfm_string gfm3_string
#define mkd_compile mkd3_compile
#define mkd_dump mkd3_dump
#define markdown markdown3
#define mkd_line mkd3_line
#define mkd_xhtmlpage mkd3_xhtmlpage
#define mkd_generateline mkd3_generateline
#define mkd_flags_are mkd3_flags_are

/* line builder for markdown()
 */
MMIOT *mkd_in(FILE*,mkd_flag_t*);		/* assemble input from a file */
MMIOT *mkd_string(const char*,int,mkd_flag_t*);	/* assemble input from a buffer */

/* line builder for github flavoured markdown
 */
MMIOT *gfm_in(FILE*,mkd_flag_t*);		/* assemble input from a file */
MMIOT *gfm_string(const char*,int,mkd_flag_t*);	/* assemble input from a buffer */

void mkd_basename(MMIOT*,char*);

void mkd_initialize(void);
void mkd_with_html5_tags(void);
void mkd_shlib_destructor(void);

/* compilation, debugging, cleanup
 */
int mkd_compile(MMIOT*, mkd_flag_t*);
void mkd_cleanup(MMIOT*);

/* markup functions
 */
int mkd_dump(MMIOT*, FILE*, mkd_flag_t*, char*);
int markdown(MMIOT*, FILE*, mkd_flag_t*);
int mkd_line(char *, int, char **, mkd_flag_t*);
int mkd_xhtmlpage(MMIOT*,mkd_flag_t*,FILE*);

/* header block access
 */
char* mkd_doc_title(MMIOT*);
char* mkd_doc_author(MMIOT*);
char* mkd_doc_date(MMIOT*);

/* compiled data access
 */
int mkd_document(MMIOT*, char**);
int mkd_toc(MMIOT*, char**);
int mkd_css(MMIOT*, char **);
int mkd_xml(char *, int, char **);

/* write-to-file functions
 */
int mkd_generatehtml(MMIOT*,FILE*);
int mkd_generatetoc(MMIOT*,FILE*);
int mkd_generatexml(char *, int,FILE*);
int mkd_generatecss(MMIOT*,FILE*);
#define mkd_style mkd_generatecss
int mkd_generateline(char *, int, FILE*, mkd_flag_t*);
#define mkd_text mkd_generateline

/* url generator callbacks
 */
typedef char * (*mkd_callback_t)(const char*, const int, void*);
typedef void   (*mkd_free_t)(char*, int, void*);

void mkd_e_url(void *, mkd_callback_t, mkd_free_t, void *);
void mkd_e_flags(void *, mkd_callback_t, mkd_free_t, void *);
void mkd_e_anchor(void *, mkd_callback_t, mkd_free_t, void *);
void mkd_e_code_format(void*, mkd_callback_t, mkd_free_t, void *);

/* version#.
 */
extern char markdown_version[];
void mkd_mmiot_flags(FILE *, MMIOT *, int);
void mkd_flags_are(FILE*, mkd_flag_t*, int);

void mkd_ref_prefix(MMIOT*, char*);


#endif/*_MKDIO_D*/
