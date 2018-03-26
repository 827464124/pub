#include <stdio.h>
#include <stdlib.h>
#include <time.h>
void bubble(int* src,int len)
{
		int i = 0;
		int j;
		for(j = 1;j<len-1;j++)
		for (i=0; i<len-1;i++){
				if(src[i] > src[i+1] ){
						int tmp = src[i];
						src[i] = src[i+1];
						src[i+1] = tmp;
				}
		}
}

void quick(int *src,int pos ,int len){


		if (pos >= len ) return ;
		int mid = (len-pos)/2;
		int j = len;
		int i = pos;
		int m = src[pos];
		while(i<j){
		while(i<j && m <= src[j] ) j--;
		src[i] = src[j]; 
		while(j>i && src[i] <= m ) i++;
		src[j] = src[i];
		}
		src[i] = m;
		quick(src,pos,i - 1);
		quick(src,i+1,len);
}

void print_a(int *src, int len){
		int i =0;
		for(i=0;i<len-1;i++){
				printf("%d  ",src[i]);
		}
		printf("\n");
}
int main()
{
		srand(time(NULL));
		int arr[10]={};
		int i = 0;
		for(i=0;i<10;i++){
				arr[i] = rand()%100;
				}
//	bubble(arr,sizeof(arr)/4);
		print_a(arr,sizeof(arr)/4);
		quick(arr,0,sizeof(arr)/4 - 1 );
		print_a(arr,sizeof(arr)/4);
}
