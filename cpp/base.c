#include <stdio.h>
#include <stdlib.h>
#include <string.h>


void ch_to_base64(char src[])
{
		
		char Base[65]={};
		strcpy(Base,"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/");
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
						dest[i++] = Base[parr[0]];
						dest[i++] = Base[parr[1]];
						dest[i++] = Base[parr[2]];
						dest[i++]='=';
				}
		}
		strcpy(src,dest);
}

