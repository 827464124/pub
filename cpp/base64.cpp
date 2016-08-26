#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
using namespace std;

class base64
{
public:
	base64();
	~base64();
void ch_to_base64(char src[]);
void base64_to_ch(char src[]);
private:
	char Base[65];
};


base64::base64()
{
		strcpy(Base,"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/");
}

base64::~base64()
{
}

void base64::ch_to_base64(char src[])
{
		char dest[64]={};
		int s_len=strlen(src);
		int remainder = s_len%3;
		int times = (s_len-remainder)/3;
		int pos = 0;
		int i = 0,j = 0;
		int parr[5];
		while(times){
				int tmp1 = (int) src[pos++];
				int tmp2 = (int) src[pos++];
				int tmp3 = (int) src[pos++];

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
				int re1 = (int)src[pos];
				if((re1&3) == 0) {
					parr[0] = re1>>2;
					dest[i++]=Base[parr[0]];
					dest[i++]=Base[0];
					printf("base[0] = %d \n",Base[0]);
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
				int re1 = (int)src[pos++];
				int re2 = (int)src[pos];
				if((re2&15) == 0){
						parr[0] = re1>>2;
						parr[1] = ((re1 - (re1>>2<<2))<<4) + re2>>4;
						dest[i++]=Base[parr[0]];
						dest[i++]=Base[parr[1]];
						dest[i++]=Base[0];
						dest[i++]='=';
				}else{
						parr[0] = re1>>2;
						parr[1] = ((re1 - (re1>>2<<2))<<4) + re2>>4;
						parr[2] = (re2-(re2>>4<<4))<<2 ;
						dest[i++] = Base[parr[0]];
						dest[i++] = Base[parr[1]];
						dest[i++] = Base[parr[2]];
						dest[i++]='=';
				}
		}
		strcpy(src,dest);
}






void b_print(int val)
{
	char arr[32]={'0'};
	char r_a[32]={};
	int i=0;
	int len=0;
	while(val >=1)
	{
		r_a[i]=(char)(val%2+48);
		i++;
		printf("val = %d\n",val);
		val=val/2;
	}
	len=strlen(r_a);
	for(i=0;i<len;i++)
	{
		arr[i]=r_a[len-i-1];	
	}
	printf("%s\n",arr);
}

int main()
{
	char src[64]="aaa";
	char dest[64]={};
	b_print(1);
	b_print(4198440);
	base64 ba;
	ba.ch_to_base64(src);
	printf("%s   strlen = %d\n",src,strlen(src));
}
