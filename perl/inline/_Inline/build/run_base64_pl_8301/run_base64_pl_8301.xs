#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"

string   main_()  
{  
			char buf[1024] = "qwe";
			ch_to_base64(buf);
                    printf("buf = %s\n",buf);  
					return buf;
} 

MODULE = run_base64_pl_8301  PACKAGE = main  

PROTOTYPES: DISABLE


