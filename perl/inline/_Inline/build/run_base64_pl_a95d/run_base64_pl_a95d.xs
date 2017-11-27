#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"

int main_()  
{  
			char buf[1024] = $str;
			ch_to_base64(buf);
                    printf("buf = %s\n",buf);  
} 

MODULE = run_base64_pl_a95d  PACKAGE = main  

PROTOTYPES: DISABLE


int
main_ ()

