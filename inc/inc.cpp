#include <cstdlib>

//#include <boost/multiprecision/cpp_int.hpp>
//#include <iostream>
//using namespace std;
//using namespace boost::multiprecision;

int main(int argc, char *argv[])
{
	unsigned long long int i;
	unsigned long long int max = strtoul(argv[1], NULL, 0);
//    uint256_t i;
//    uint256_t max(argv[1]);
//    uint128_t i;
//    uint128_t max(argv[1]);


//cout << "Uint" << __SIZEOF_INT128__ <<".\n";
//	  cout << "I   = " << i << ".\n";
//	  cout << "argv= " << argv[1] << ".\n";
//	  cout << "str = " << strtoul(argv[1], NULL, 0) << ".\n";
//	  cout << "Max = " << max << ".\n";

	for(i=0; i<max; i++);
	
	return 0;
}

