#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <error.h>
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <arpa/inet.h>
using namespace std;

void ERR(char *p)
{
	perror(p);
	exit(-1);
}

char user[64];
char passwd[64];
char a_buf[16];


struct sockaddr_in sa;

void init()
{

hostent *hptr = gethostbyname("smtp.sina.com");
if(hptr == NULL )ERR("gethostbyname");
inet_ntop(AF_INET,hptr->h_addr_list[0],a_buf,16);

printf("a_buf = %sq\n",a_buf);
sa.sin_family=AF_INET;
sa.sin_port=htons(25);
sa.sin_addr.s_addr=inet_addr("202.108.6.242");
}
	

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


class TCP_client
{
	public:
		TCP_client(struct sockaddr *addr);
		~TCP_client();
		ssize_t Send( int flags);
		ssize_t Recv(int flags);
		void set_buf(char *buf);
		void set_rbuf(char *rbuf);
		void print_rbuf();
	private:
		int sockid;
		struct sockaddr *m_addr;
		int len;
		char m_buf[1200];
		char m_rbuf[1200];
};

TCP_client::TCP_client(struct sockaddr *addr):m_addr(addr)
{
			printf("%p  %p\n",m_addr,addr);
			sockid=socket(AF_INET,SOCK_STREAM,0);
			if(sockid == -1)ERR("create sock error");
			int ret=connect(sockid,m_addr,sizeof(*m_addr));
			if(ret == -1) ERR("connect failed !");
			len = sizeof(m_buf);
}

ssize_t TCP_client::Send(int flags)
{
	return send(sockid,m_buf, len, flags);
}

ssize_t TCP_client::Recv(int flags)
{
	return recv(sockid,m_rbuf,len,flags);
}

void TCP_client::set_buf(char *buf)
{
	memset(m_buf,0,1200);
	strcpy(m_buf,buf);
}
void TCP_client::set_rbuf(char *rbuf)
{
	memset(m_rbuf,0,1200);
	strcpy(m_rbuf,rbuf);
}
void TCP_client::print_rbuf()
{
	printf("%s\n",m_rbuf);
}

TCP_client::~TCP_client(){ close(sockid);}




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

int e_send()
{
	TCP_client Tc = TCP_client((struct sockaddr*)&sa);;
	printf("%p\n",&sa);
	Tc.set_buf("EHLO HYL-PC\n");
	Tc.Send(0);
	Tc.Recv(0);
	Tc.print_rbuf();
	
	Tc.set_buf("AUTH LOGIN\n");
	Tc.Send(0);
	Tc.Recv(0);
	Tc.print_rbuf();
	
	char buf[32]={0};
	sprintf(buf,"%s","zh_wenxing@sina.com");
	base64 b;
	b.ch_to_base64(buf);
	printf("user = %su\n",buf);
	sprintf(user,"%s\r\n",buf);
	Tc.set_buf((char *)user);
	Tc.Send(0);
	Tc.Recv(0);
	Tc.print_rbuf();
	
	memset(buf,0,32);
	sprintf(buf,"%s","zwx123..");
	b.ch_to_base64(buf);
	printf("passwd = %sp\n",buf);
	sprintf(passwd,"%s\r\n",buf);
		
	Tc.set_buf(passwd);
	Tc.Send(0);
	Tc.Recv(0);
	Tc.print_rbuf();
	
	Tc.set_buf("MAIL FROM:<zh_wenxing@sina.com>\r\n");
	Tc.Send(0);
	Tc.Recv(0);
	Tc.print_rbuf();
	
	Tc.set_buf("RCPT TO:<827464124@qq.com>\r\n");
	Tc.Send(0);
	Tc.Recv(0);
	Tc.print_rbuf();
	
	Tc.set_buf("DATA\r\n");
	Tc.Send(0);
	Tc.Recv(0);
	Tc.print_rbuf();
	
	Tc.set_buf("haha\r\n.\r\n");
	Tc.Send(0);
	Tc.Recv(0);
	Tc.print_rbuf();
	
	Tc.set_buf("QUIT\r\n");
	Tc.Send(0);
	Tc.Recv(0);
	Tc.print_rbuf();
}
int main()
{
	init();
	e_send();
}
