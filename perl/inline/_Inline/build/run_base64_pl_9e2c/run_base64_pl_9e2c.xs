#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"

int main_()  
{  
        if(argc !=2) {  
                printf("error: param num is wrong!\n");  
                return -1;  
                    }  
			char * buf = "qwe";
                    ch_to_base64(buf);  
                    printf("buf = %s\n",buf);  
} 

MODULE = run_base64_pl_9e2c  PACKAGE = main  

PROTOTYPES: DISABLE


int
main_ ()

