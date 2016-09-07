#include <stdio.h>
#include <stdlib.h>
#include <string.h>
int main(int argc,char **argv)
{
		if(argc !=2) {
				printf("error: param num is wrong!\n");
				return -1;
					}
					ch_to_base64(argv[1]);
					printf("buf = %s\n",argv[1]);
}
