/*\
 * tidy-tree.cxx
 *
 * Copyright (c) 2015 - Geoff R. McLane
 * Licence: GNU GPL version 2
 *
\*/

#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h>
#include <string.h> // for strdup(), ...
#include "tidy.h"
#include "tidybuffio.h"
#include "sprtf.h"

#ifndef SPRTF
#define SPRTF printf
#endif

static const char *module = "tidy-tree";
static const char *def_log = "temptree.txt";
static const char *usr_input = 0;
static int ind_step = 2;
static const char *def_test = "F:\\Projects\\tidy-html5\\test\\input5\\in_273-3.html";
static bool debug_on = false;
static TidyDoc tdoc = 0;
static TidyBuffer txtbuf;
static size_t total_txt = 0;
static int txt_nodes = 0;
void give_help( char *name )
{
    SPRTF("%s: usage: [options] usr_input\n", module);
    SPRTF("Options:\n");
    SPRTF(" --help  (-h or -?) = This help and exit(2)\n");
    // TODO: More help
}

void dumpNode( TidyNode tnod, int indent, int *pcnt )
{
    TidyNode child;
    for ( child = tidyGetChild(tnod); child; child = tidyGetNext(child) )
    {
        ctmbstr name = NULL;
        *pcnt += 1;
        TidyNodeType nt = tidyNodeGetType(child);
        tidyBufClear( &txtbuf );

        if (tidyNodeHasText(tdoc, child)) {
            if (!tidyNodeGetText(tdoc, child, &txtbuf)) {
                SPRTF("Warning: tidyNodeGetText failed?!?\n");
            }
        }
        switch (nt)
        {
        case TidyNode_Root:
            name = "Root";
            break;
        case TidyNode_DocType:
            name = "DOCTYPE";
            break;
        case TidyNode_Comment:
            name = "Comment";
            break;
        case TidyNode_ProcIns:
            name = "Processing Instruction";
            break;
        case TidyNode_Text:
            name = "Text";
            break;
        case TidyNode_CDATA:
            name = "CDATA";
            break;
        case TidyNode_Section:
            name = "XML Section";
            break;
        case TidyNode_Asp:
            name = "ASP";
            break;
        case TidyNode_Jste:
            name = "JSTE";
            break;
        case TidyNode_Php:
            name = "PHP";
            break;
        case TidyNode_XmlDecl:
            name = "XML Declaration";
            break;

        case TidyNode_Start:
        case TidyNode_End:
        case TidyNode_StartEnd:
        default:
            name = tidyNodeGetName( child );
            break;
        }
        if ( name == NULL ) {
            SPRTF("Internal Error: Failed to get node name/type!!! *** FIX ME ***\n");
            exit(1);
        }
        SPRTF( "%*.*sNode:%d: %s ", indent, indent, " ", *pcnt, name );
        if (txtbuf.bp && txtbuf.size) {
            total_txt += txtbuf.size;
            SPRTF("(%d) ", txtbuf.size);
            txt_nodes++;

        }
        SPRTF("\n");
        dumpNode( child, indent + ind_step, pcnt );
    }
}

void countNodes( TidyNode tnod, int *pcnt )
{
    TidyNode child;
    for ( child = tidyGetChild(tnod); child; child = tidyGetNext(child) )
    {
        *pcnt += 1;
        countNodes( child, pcnt );
    }
}


void dumpDoc( TidyDoc doc )
{
    TidyNode node = tidyGetRoot(doc);
    int count = 0;
    countNodes( node, &count );
    SPRTF("Dump of %d nodes...\n", count );
    count = 0;
    tidyBufInit( &txtbuf );
    dumpNode( node, 0, &count );
    SPRTF("Found %ld text bytes on %d nodes...\n", total_txt, txt_nodes );
}


int parse_args( int argc, char **argv )
{
    int i,i2,c;
    char *arg, *sarg;
    for (i = 1; i < argc; i++) {
        arg = argv[i];
        i2 = i + 1;
        if (*arg == '-') {
            sarg = &arg[1];
            while (*sarg == '-')
                sarg++;
            c = *sarg;
            switch (c) {
            case 'h':
            case '?':
                give_help(argv[0]);
                return 2;
                break;
            // TODO: Other arguments
            default:
                SPRTF("%s: Unknown argument '%s'. Try -? for help...\n", module, arg);
                return 1;
            }
        } else {
            // bear argument
            if (usr_input) {
                SPRTF("%s: Already have input '%s'! What is this '%s'?\n", module, usr_input, arg );
                return 1;
            }
            usr_input = strdup(arg);
        }
    }

    if (debug_on && !usr_input) {
         usr_input = strdup(def_test);
        SPRTF("%s: Debug ON: Using DEFAULT input %s!\n", module, usr_input);

    }

    if (!usr_input) {
        SPRTF("%s: No user input found in command!\n", module);
        return 1;
    }
    return 0;
}

#ifdef _MSC_VER
#define M_IS_DIR _S_IFDIR
#else // !_MSC_VER
#define M_IS_DIR S_IFDIR
#endif

static struct stat buf;
enum DiskType {
    MDT_NONE,
    MDT_FILE,
    MDT_DIR
};

DiskType is_file_or_directory( const char * path )
{
    if (!path)
        return MDT_NONE;
	if (stat(path,&buf) == 0)
	{
		if (buf.st_mode & M_IS_DIR)
			return MDT_DIR;
		else
			return MDT_FILE;
	}
	return MDT_NONE;
}
size_t get_last_file_size() { return buf.st_size; }

int show_tidy_nodes()
{
    int iret = 0;
    int status = 0;
    const char *htmlfil = usr_input;
    if (is_file_or_directory(htmlfil) != MDT_FILE) {
        SPRTF("Error: Unable to stat file '%s'!\n", htmlfil);
        return 1;
    }
    size_t sz = get_last_file_size();
    SPRTF("Processing file '%s', %ld bytes...\n", htmlfil, sz );

    tdoc = tidyCreate();
    tidyOptSetBool( tdoc, TidySkipNested, yes );
    status = tidyParseFile( tdoc, htmlfil );
    if ( status >= 0 )
        status = tidyCleanAndRepair( tdoc );

    if ( status >= 0 ) {
        status = tidyRunDiagnostics( tdoc );
        if ( !tidyOptGetBool(tdoc, TidyQuiet) ) {
            /* NOT quiet, show DOCTYPE, if not already shown */
            if (!tidyOptGetBool(tdoc, TidyShowInfo)) {
                tidyOptSetBool( tdoc, TidyShowInfo, yes );
                tidyReportDoctype( tdoc );  /* FIX20140913: like warnings, errors, ALWAYS report DOCTYPE */
                tidyOptSetBool( tdoc, TidyShowInfo, no );
            }
        }
    }
    if ( status > 1 ) /* If errors, do we want to force output? */
            status = ( tidyOptGetBool(tdoc, TidyForceOutput) ? status : -1 );

    dumpDoc(tdoc);

    tidyRelease( tdoc ); /* called to free hash tables etc. */
    iret = ((status < 0) && (status > 1)) ? 1 : 0;
    return iret;
}

// main() OS entry
int main( int argc, char **argv )
{
    int iret = 0;
    set_log_file((char *)def_log, 0);
    iret = parse_args(argc,argv);
    if (iret)
        return iret;

    iret = show_tidy_nodes();    // actions of app

    return iret;
}


// eof = tidy-tree.cxx