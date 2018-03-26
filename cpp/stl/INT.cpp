#include <iostream>
using namespace std;

class INT
{
	friend ostream& operator<< (ostream& os,const INT& i);
public:
	INT(int i):m_i(i){}
	INT& operator++ ()
	{
		++(this->m_i);
		return *this;
	}
	const INT operator++ (int)
	{
		INT tmp = *this;
		this->m_i++;
		return tmp;
	}
	INT& operator-- ()
	{
		--(this->m_i);
		return *this;
	}
	const INT operator-- (int )
	{
		INT tmp = *this;
		this->m_i--;
		return tmp;
	}
	int & operator* ()
	{
		return this->m_i;
	}
private:
	int m_i = 0;
};

ostream & operator<< (ostream& os,const INT& i){
	os<< '[' <<i.m_i <<']'<<endl;
	return os;
}


int main () {
	INT I(8);
	cout << I++;
	cout << ++I;
	cout << I--;
	cout << --I;
	cout << *I;
}
