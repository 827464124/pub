#include<stdio.h>

int main()
{
	char * m_arr[10];
	char * a[10] = {"asdf","a2","a3","a4","a5","a6","a7","a8","a9"};
	int i,k;
	for ( i = 0; i < 10 ;i++){
		char *p = a[i];
		m_arr[i] = p;
	}
	for ( k = 0; k < 10 ; k++){
		printf ("%d  =  %s \n",k,m_arr[k]);
	}
}
