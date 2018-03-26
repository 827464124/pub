#include <iostream>
#include <new>
using namespace std;

class A
{
	public :
		int m_a;
		A(int a):m_a(a){}
};

int main ()
{
	A *p;
	new(p) A(11);
	cout << p <<endl;
}
