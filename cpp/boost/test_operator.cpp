#include <iostream>
#include <typeinfo>
using namespace std;

	int  operator"" _D( unsigned long long    n ){
		return  n;
	}
int main ()
{
	 auto  a= 11_D;
	cout << typeid(a).name()   << endl;
}
