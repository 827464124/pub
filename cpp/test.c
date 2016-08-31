#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netdb.h>
#include <sys/socket.h>
#include <sys/types.h>
int main()
{

	char buf[32]={0};
	struct sockaddr_in sa;
sa.sin_family=AF_INET;
sa.sin_port=htons(25);
	struct hostent *hptr = gethostbyname("smtp.sina.com");
	printf("dada\n");
	memcpy(&sa.sin_addr.s_addr,hptr->h_addr_list[0],hptr->h_length);
	printf("aaa\n");
	
	inet_ntop(AF_INET,hptr->h_addr_list[0],buf,16);
	printf("%s\n",buf);
	printf("192=%c\n",192);
}
