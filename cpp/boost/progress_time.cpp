#include <boost/progress.hpp>
#include <iostream>
using namespace boost;
using namespace std;

int main ()
{
	{
		boost::progress_timer t;
		//sleep(1);
		int i = 0;
		while(i < 10000000) i++;
	}
	{
		boost::progress_timer t;
		sleep(2);
	}
}
