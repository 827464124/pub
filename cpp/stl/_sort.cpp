#include <iostream>
#include <time.h>
using namespace std;


template <typename T >
class sort
{
	public:
		
	sort(){};
	~sort(){};

	void quick(T* arr,int left, int right){
		if (left  >= right) return ;
		int i = left;
		int j = right;
		T key = arr[left];
		while (i < j){
			while (i < j && arr[j] > key) j--;
			arr[i] = arr[j];
			while(i<j && arr[i] < key) i++;
			arr[j] = arr[i];
			}
		arr[i] = key;
			quick(arr,left,i - 1);
			quick(arr,i + 1,right);
	}
};

template <typename T>
void print_a(T *src, int len){
        int i =0;
        for(i=0;i<len-1;i++){
                printf("%d  ",src[i].m);
        }
        printf("\n");
}

class N
{
	public:
		N(int a_m):m(a_m){};
		N(){};
		~N(){};
		bool operator> ( N& n1){
			if (this->m> n1.m)
				return true;
			else
				return false;
		}
		bool operator>= ( N& n1){
			if (this->m >= n1.m)
				return true;
			else
				return false;
		}
		bool operator< ( N& n1){
			if (this->m < n1.m)
				return true;
			else
				return false;
		}
		bool operator<= ( N& n1){
			if (this->m <= n1.m)
				return true;
			else
				return false;
		}

	int m ;
};
int main(){
	srand(time(NULL));
	int i;
	int arr[10] ={};
	N *N_arr = new N[10];
	sort<N> st;
	for(i=0;i<10;i++){
                arr[i] = rand()%100;
				N_arr[i].m = rand()%100;
                }
        st.quick((N *)N_arr,0,9 );
        print_a(N_arr,10);


}







