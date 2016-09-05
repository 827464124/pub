#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>


int main()
{
		int i=0;
		while(i<5){
				pid_t pid = fork();
				if(pid == 0){
						printf("this is child proc ,"
						"pid is %d,parent pid is %d i=%d\n",getpid(),getppid(),i);
						sleep(i);
						exit(0);
				}else {
						i++;
						printf("this is parent proc,pid is %d\n",getpid());
				}
		}
		wait();
		printf("all child proc is over!\n");
		while(10);
}

