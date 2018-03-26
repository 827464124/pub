#include <iostream>
using namespace std;

template <class T>
class calculater
{
	T& operator (const T& t1,const T& t2){ return (T&) t2 + t1;}
	T& operator+ (const T& t1,const T& t2){ return (T&) t2 + t1;}
	T& operator+ (const T& t1,const T& t2){ return (T&) t2 + t1;}
	T& operator+ (const T& t1,const T& t2){ return (T&) t2 + t1;}
	T& operator+ (const T& t1,const T& t2){ return (T&) t2 + t1;}
