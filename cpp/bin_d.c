#include <stdio.h>
#include <stdlib.h>
#include <math.h>


int bin_d(int src){
		int r=0;
		int d=0;
		int i=0;
		while(src){

			r = (src %10)*pow(2,i);
			d += r;
			src= (src - (src%10)) / 10;
			i++;
		}
	return d;
}


int main(int argc,char **argv)
{
		if(argc !=2 ){
				printf("param num is wrong!\n");
				return -1;
		}
		printf("%d \n",bin_d(atoi(argv[1])));
		return 0;
}
