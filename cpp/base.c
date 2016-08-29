#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char Base[65]={};

void ch_to_base64(char src[])
{
	
		char dest[64]={};
		int s_len=strlen(src);
		int remainder = s_len%3;
		int times = (s_len-remainder)/3;
		int pos = 0;
		int i = 0,j = 0;
		int parr[5];
		while(times){
				unsigned int tmp1 = (unsigned int) src[pos++];
				unsigned int tmp2 = (unsigned int) src[pos++];
				unsigned int tmp3 = (unsigned int) src[pos++];
				printf("%u   %u   %u\n",tmp1,tmp2,tmp3);
				parr[0] = tmp1>>2;
				parr[1] = ((tmp1-(tmp1>>2<<2))<<4) + (tmp2>>4);
				parr[2] = ((tmp2-(tmp2>>4<<4))<<2) +(tmp3>>6);
				parr[3] = tmp3-(tmp3>>6<<6);

				for(i,j=0;j<4;i++,j++){
						dest[i] = Base[parr[j]];
				}
				times--;
		}
		if(remainder == 1){
				unsigned int re1 = (unsigned int)src[pos];
				printf("%u \n",re1);
				if((re1&3) == 0) {
					parr[0] = re1>>2;
					dest[i++]=Base[parr[0]];
					dest[i++]=Base[0];
					dest[i++]='=';
					dest[i++]='=';

				}else{
					parr[0] = re1>>2;
					parr[1] = (re1&3)<<4;
					dest[i++]=Base[parr[0]];
					dest[i++]=Base[parr[1]];
					dest[i++]='=';
					dest[i++]='=';
				}
		}
		if(remainder == 2){
				unsigned int re1 = (unsigned int)src[pos++];
				unsigned int re2 = (unsigned int)src[pos];
				printf ("%u  %u\n",re1,re2);
				if((re2&15) == 0){
						parr[0] = re1>>2;
						parr[1] = ((re1 - (re1>>2<<2))<<4) + (re2>>4);
						dest[i++]=Base[parr[0]];
						dest[i++]=Base[parr[1]];
						dest[i++]=Base[0];
						dest[i++]='=';
				}else{
						parr[0] = re1>>2;
						parr[1] = ((re1 - (re1>>2<<2))<<4) + (re2>>4);
						parr[2] = (re2-(re2>>4<<4))<<2 ;
						printf("p1=%d   p2=%d  p3=%d\n",parr[0],parr[1],parr[2]);
						dest[i++] = Base[parr[0]];
						dest[i++] = Base[parr[1]];
						dest[i++] = Base[parr[2]];
						dest[i++]='=';
				}
		}
		strcpy(src,dest);
}

int main(int argc,char **argv)
{
	strcpy(Base,"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/");
	if(argc !=2) {
		printf("error: param num is wrong!\n");
		return -1;
	}
	ch_to_base64(argv[1]);
	printf("buf = %sa\n",argv[1]);
}