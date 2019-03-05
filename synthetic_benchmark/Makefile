all:
	gcc -g -I. -Icrypto/include -Iinclude -fPIC -pthread -m64 -Wa,--noexecstack -DDEBUG_UNUSED -DPEDANTIC -pedantic -Wno-long-long -Wall -Wextra -Wno-unused-parameter -Wno-missing-field-initializers -Wswitch -Wsign-compare -Wmissing-prototypes -Wstrict-prototypes -Wshadow -Wformat -Wtype-limits -Wundef -Werror -Wall -O2 -g -DOPENSSL_USE_NODELETE -DL_ENDIAN -DOPENSSL_PIC -DOPENSSL_CPUID_OBJ -DOPENSSL_IA32_SSE2 -DOPENSSL_BN_ASM_MONT -DOPENSSL_BN_ASM_MONT5 -DOPENSSL_BN_ASM_GF2m -DSHA1_ASM -DSHA256_ASM -DSHA512_ASM -DKECCAK1600_ASM -DRC4_ASM -DMD5_ASM -DVPAES_ASM -DBSAES_ASM -DGHASH_ASM -DECP_NISTZ256_ASM -DX25519_ASM -DPADLOCK_ASM -DPOLY1305_ASM -DOPENSSLDIR="/usr/local/ssl" -DENGINESDIR="/usr/local/lib/engines-1.1" -MMD -MF aes_core.d.tmp -MT aes_core.o -c -o aes_core.o aes_core.c
	gcc -Wall -g -DMASK_PROTECT -static -O2 -Iinclude -o specBench_mask specBench.c aes_core.o
	gcc -Wall -g -DWB_ON_RETIRE -static -O2 -Iinclude -o specBench_wbor specBench.c aes_core.o
	gcc -Wall -g -static -O2 -Iinclude -o specBench_base specBench.c aes_core.o
	gcc -Wall -g -static -o stack_test stack_test.c
