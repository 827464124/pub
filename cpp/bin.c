#include <stdio.h>
#include <stdlib.h>
#include <string.h>



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

int main(int argc,char **argv)
{
	if(argc != 2){
		printf("the param is too little\n");
		return -1;
	}
	b_print(atoi(argv[1]));
}