#include <boost/date_time/gregorian/gregorian.hpp>
#include <iostream>
#include <typeinfo>
using namespace boost::gregorian;
using namespace std;


days operator"" _D(unsigned long long n){
	return days(n);
}


int main()
{
	date d1(2018,01,01),d2(2017,01,01);
	d1 += days(20);
	cout << d1-d2 << endl;

	d1 += months(2);
	cout << d1-d2 << endl;


	date_period dp (d2,d1);
	cout << dp.length().days() << endl;


	auto d = 10_D;
	cout << d.days() << endl;
	cout << typeid(d).name()<< endl;
	return 0;
}
