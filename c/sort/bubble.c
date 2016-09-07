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
		int mid = (len-pos)/2;
		int j = len;
		int i = pos;
		int m = src[mid];
		if(mid > i && mid < len ){
		while(j > i){
		while(j>i && src[i] < src[mid] ) i++;
		while(j>i && src[j] > src[mid] ) j--;
		if(i < j ){
				int tmp = src[i];
				src[i] = src[j];
				src[j] = tmp;
				i++; j--;
			}
		}
		quick(src,pos,mid);
		quick(src,mid+1,len);
	}
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
		bubble(arr,sizeof(arr)/4);
		print_a(arr,sizeof(arr)/4);
		quick(arr,0,sizeof(arr)/4 - 1);
		print_a(arr,sizeof(arr)/4);
}
