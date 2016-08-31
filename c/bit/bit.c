#include <stdio.h>
#include <stdlib.h>
#include <string.h>

 struct base64{
		unsigned  d1:6;
		unsigned  d2:6;
		unsigned  d3:6;
		unsigned  d4:6;
};

int main()
{
	char buf[10]="qwertyui";
	struct base64 *bs=(struct base64 *)buf;
	printf("d1=%u ,d2=%u, d3=%u, d4=%u\n",bs->d1,bs->d2,bs->d3,bs->d4);
	printf("buf1=%p ,buf2=%p, buf3=%p\n",buf,buf+1,buf+2);
}



