#include <stdlib.h>

int main(int argc, char *argv[])
{
	unsigned long long int i;
	unsigned long long int max = strtoul(argv[1], NULL, 0);
	
	for(i=0; i<max; i++);
	
	return 0;
}

