#include <stdio.h>
#include <stdlib.h>

int re()
{
		int i =99;
		int *ii=(int *) malloc(4);
		 *ii=i;
		return ii;
}

int main ()
{
	int *a=re();
	printf("%d \n",*a);
}
