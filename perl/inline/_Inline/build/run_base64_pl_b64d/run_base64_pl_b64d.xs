#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"

char *   main_(char  *buf )  
{  
			//char buf[1024] = "qwe";
			ch_to_base64( (char [])buf);
                    printf("buf = %s\n",buf);  
					return buf;
} 

MODULE = run_base64_pl_b64d  PACKAGE = main  

PROTOTYPES: DISABLE


char *
main_ (buf)
	char *	buf

